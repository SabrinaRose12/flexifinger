<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

$auth->requireLogin();

$conn = getDBConnection();

// Get all patients with details
$patients = $conn->query("
    SELECT 
        p.*, 
        t.full_name as therapist_name, 
        t.staff_id as therapist_staff_id,
        t.centre_name as therapist_centre,
        es.set_name as exercise_set_name,
        sch.start_date as schedule_start,
        sch.end_date as schedule_end,
        sch.frequency,
        (SELECT COUNT(*) FROM daily_exercise_tracking WHERE patient_id = p.patient_id AND status = 'completed') as total_completed_sessions
    FROM patients p
    LEFT JOIN therapists t ON p.therapist_id = t.therapist_id
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    ORDER BY p.created_at DESC
")->fetch_all(MYSQLI_ASSOC);

// Get all active therapists for dropdown
$therapists = $conn->query("
    SELECT therapist_id, full_name, staff_id, centre_name 
    FROM therapists 
    WHERE status = 'active' 
    ORDER BY full_name
")->fetch_all(MYSQLI_ASSOC);

// Handle search
$search = $_GET['search'] ?? '';
if ($search) {
    $patients = array_filter($patients, function($patient) use ($search) {
        return stripos($patient['full_name'], $search) !== false || 
               stripos($patient['patient_ic'], $search) !== false ||
               stripos($patient['email'], $search) !== false;
    });
}

// Handle status filter
$status_filter = $_GET['status'] ?? '';
if ($status_filter && $status_filter !== 'all') {
    $patients = array_filter($patients, function($patient) use ($status_filter) {
        return $patient['status'] === $status_filter;
    });
}

// Handle Add/Edit Patient
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'add_patient') {
        $full_name = $_POST['full_name'] ?? '';
        $patient_ic = $_POST['patient_ic'] ?? '';
        $email = $_POST['email'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $finger_condition = $_POST['finger_condition'] ?? '';
        $status = $_POST['status'] ?? 'pending';
        $therapist_id = $_POST['therapist_id'] ?? null;
        $password = $_POST['password'] ?? '123456';
        
        if ($full_name && $patient_ic && $email) {
            // Generate patient ID
            $result = $conn->query("SELECT MAX(CAST(SUBSTRING(patient_id, 2) AS UNSIGNED)) as max_id FROM patients");
            $row = $result->fetch_assoc();
            $nextId = ($row['max_id'] ?? 0) + 1;
            $patientId = 'P' . str_pad($nextId, 3, '0', STR_PAD_LEFT);
            
            $stmt = $conn->prepare("
                INSERT INTO patients (patient_id, patient_ic, full_name, email, phone, finger_condition, status, therapist_id, password_hash, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
            ");
            $stmt->bind_param("sssssssis", $patientId, $patient_ic, $full_name, $email, $phone, $finger_condition, $status, $therapist_id, $password);
            
            if ($stmt->execute()) {
                if (!empty($therapist_id)) {
                    $conn->query("UPDATE therapists SET patient_count = (SELECT COUNT(*) FROM patients WHERE therapist_id = $therapist_id) WHERE therapist_id = $therapist_id");
                }
                $_SESSION['success'] = "Patient added successfully!";
            } else {
                $_SESSION['error'] = "Failed to add patient.";
            }
        }
        header("Location: patient-management.php");
        exit();
    }
    
    elseif ($action === 'edit_patient') {
        $patient_id = $_POST['patient_id'] ?? '';
        $full_name = $_POST['full_name'] ?? '';
        $patient_ic = $_POST['patient_ic'] ?? '';
        $email = $_POST['email'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $finger_condition = $_POST['finger_condition'] ?? '';
        $status = $_POST['status'] ?? '';
        $therapist_id = $_POST['therapist_id'] ?? null;
        $pain_score = $_POST['pain_score'] ?? 0;
        
        if ($patient_id && $full_name) {
            $old_therapist = $conn->query("SELECT therapist_id FROM patients WHERE patient_id = $patient_id")->fetch_assoc();
            
            $stmt = $conn->prepare("
                UPDATE patients SET 
                    full_name = ?, patient_ic = ?, email = ?, phone = ?, 
                    finger_condition = ?, status = ?, therapist_id = ?, pain_score = ?
                WHERE patient_id = ?
            ");
            $stmt->bind_param("ssssssiii", $full_name, $patient_ic, $email, $phone, $finger_condition, $status, $therapist_id, $pain_score, $patient_id);
            
            if ($stmt->execute()) {
                // Update therapist counts
                if ($old_therapist['therapist_id'] != $therapist_id) {
                    if ($old_therapist['therapist_id']) {
                        $conn->query("UPDATE therapists SET patient_count = (SELECT COUNT(*) FROM patients WHERE therapist_id = {$old_therapist['therapist_id']}) WHERE therapist_id = {$old_therapist['therapist_id']}");
                    }
                    if ($therapist_id) {
                        $conn->query("UPDATE therapists SET patient_count = (SELECT COUNT(*) FROM patients WHERE therapist_id = $therapist_id) WHERE therapist_id = $therapist_id");
                    }
                }
                $_SESSION['success'] = "Patient updated successfully!";
            } else {
                $_SESSION['error'] = "Failed to update patient.";
            }
        }
        header("Location: patient-management.php");
        exit();
    }
    
    elseif ($action === 'delete_patient') {
        $patient_id = $_POST['patient_id'] ?? '';
        if ($patient_id) {
            // Get therapist_id to update count
            $therapist = $conn->query("SELECT therapist_id FROM patients WHERE patient_id = $patient_id")->fetch_assoc();
            $stmt = $conn->prepare("DELETE FROM patients WHERE patient_id = ?");
            $stmt->bind_param("i", $patient_id);
            if ($stmt->execute()) {
                if ($therapist['therapist_id']) {
                    $conn->query("UPDATE therapists SET patient_count = (SELECT COUNT(*) FROM patients WHERE therapist_id = {$therapist['therapist_id']}) WHERE therapist_id = {$therapist['therapist_id']}");
                }
                $_SESSION['success'] = "Patient deleted successfully!";
            } else {
                $_SESSION['error'] = "Failed to delete patient.";
            }
        }
        header("Location: patient-management.php");
        exit();
    }
}

$success = $_SESSION['success'] ?? '';
$error = $_SESSION['error'] ?? '';
unset($_SESSION['success'], $_SESSION['error']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Patient Management - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/admin.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
<style>
        /* Additional style for sidebar logo */
        .sidebar-header {
            text-align: center;
        }
        .sidebar-logo {
            width: 50px;
            height: 50px;
            object-fit: contain;
            margin-bottom: 12px;
            border-radius: 12px;
            padding: 5px;
        }
        .sidebar-header h3 i {
            display: none;
        }
    </style>
</head>
<body>
    <div class="sidebar">
    <div class="sidebar-header">
        <img src="images/logowhite.png" alt="FlexiFinger Logo" class="sidebar-logo" style="width:80px;height:80px;" onerror="this.src='https://placehold.co/32x32?text=FF'">
        <h5>Admin Panel</h5>
    </div>
        <nav class="nav flex-column mt-4">
            <a href="dashboard.php" class="nav-link"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="approval.php" class="nav-link"><i class="fas fa-user-check"></i> Approval</a>
            <a href="patient-management.php" class="nav-link active"><i class="fas fa-users"></i> Patient Management</a>
            <a href="therapist-management.php" class="nav-link"><i class="fas fa-user-md"></i> Therapist Management</a>
            <a href="exercise-management.php" class="nav-link"><i class="fas fa-dumbbell"></i> Exercise Management</a>
            <a href="reporting.php" class="nav-link"><i class="fas fa-chart-bar"></i> Reports</a>
            <a href="profile.php" class="nav-link"><i class="fas fa-user-cog"></i> Settings</a>
            <a href="logout.php" class="nav-link mt-4"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </nav>
    </div>

    <div class="main-content">
        <div class="navbar-top">
            <div class="welcome-text">
                <h4>Patient Management</h4>
                <p>Manage and monitor patient records</p>
            </div>
            <div class="admin-badge"><i class="fas fa-user-shield"></i> Administrator</div>
        </div>

        <?php if ($success): ?>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i><?php echo htmlspecialchars($success); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>
        
        <?php if ($error): ?>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><?php echo htmlspecialchars($error); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>

        <!-- Search and Filters -->
        <div class="card">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <form method="GET" class="d-flex">
                            <div class="input-group">
                                <span class="input-group-text"><i class="fas fa-search"></i></span>
                                <input type="text" class="form-control" name="search" placeholder="Search by name, IC, or email..." value="<?php echo htmlspecialchars($search); ?>">
                                <button class="btn btn-primary" type="submit">Search</button>
                                <?php if ($search): ?>
                                    <a href="patient-management.php" class="btn btn-outline-secondary">Clear</a>
                                <?php endif; ?>
                            </div>
                        </form>
                    </div>
                    <div class="col-md-6 text-end">
                        <div class="btn-group me-2">
                            <a href="patient-management.php" class="btn btn-outline-primary <?php echo !$status_filter ? 'active' : ''; ?>">All</a>
                            <a href="patient-management.php?status=active" class="btn btn-outline-success <?php echo $status_filter === 'active' ? 'active' : ''; ?>">Active</a>
                            <a href="patient-management.php?status=pending" class="btn btn-outline-warning <?php echo $status_filter === 'pending' ? 'active' : ''; ?>">Pending</a>
                            <a href="patient-management.php?status=inactive" class="btn btn-outline-secondary <?php echo $status_filter === 'inactive' ? 'active' : ''; ?>">Inactive</a>
                        </div>
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addPatientModal"><i class="fas fa-user-plus"></i> Add Patient</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Patients Table -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="fas fa-users me-2"></i> Patient Records (<?php echo count($patients); ?>)</span>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Full Name</th>
                                <th>IC Number</th>
                                <th>Condition</th>
                                <th>Therapist</th>
                                <th>Status</th>
                                <th>Compliance</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($patients as $patient): ?>
                            <tr>
                                <td><code><?php echo htmlspecialchars($patient['patient_id']); ?></code></td>
                                <td>
                                    <strong><?php echo htmlspecialchars($patient['full_name']); ?></strong>
                                    <br><small class="text-muted"><?php echo htmlspecialchars($patient['email']); ?></small>
                                </td>
                                <td><code><?php echo htmlspecialchars($patient['patient_ic']); ?></code></td>
                                <td><span class="badge bg-info"><?php echo htmlspecialchars(substr($patient['finger_condition'] ?? '-', 0, 25)); ?></span></td>
                                <td><?php echo htmlspecialchars($patient['therapist_name'] ?? 'Not assigned'); ?></td>
                                <td><span class="badge badge-<?php echo $patient['status']; ?>"><?php echo ucfirst($patient['status']); ?></span></td>
                                <td><?php echo round($patient['compliance_rate'], 1); ?>%</td>
                                <td>
                                    <button class="btn btn-view btn-sm" onclick="viewPatient(<?php echo htmlspecialchars(json_encode($patient)); ?>)"><i class="fas fa-eye"></i> View</button>
                                    <button class="btn btn-edit btn-sm" onclick="editPatient(<?php echo htmlspecialchars(json_encode($patient)); ?>)"><i class="fas fa-edit"></i> Edit</button>
                                    <button class="btn btn-report btn-sm" onclick="generateReport(<?php echo htmlspecialchars(json_encode($patient)); ?>)"><i class="fas fa-file-pdf"></i> Report</button>
                                    <button class="btn btn-danger btn-sm" onclick="deletePatient(<?php echo $patient['patient_id']; ?>, '<?php echo htmlspecialchars($patient['full_name']); ?>')"><i class="fas fa-trash"></i> Delete</button>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                            <?php if (empty($patients)): ?>
                            <tr><td colspan="8" class="text-center py-4">No patients found</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Add Patient Modal -->
    <div class="modal fade" id="addPatientModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-user-plus me-2"></i>Add New Patient</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="action" value="add_patient">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6 mb-3"><label class="form-label">Full Name *</label><input type="text" class="form-control" name="full_name" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">IC Number *</label><input type="text" class="form-control" name="patient_ic" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Email *</label><input type="email" class="form-control" name="email" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Phone</label><input type="tel" class="form-control" name="phone"></div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Finger Condition</label>
                                <select class="form-select" name="finger_condition">
                                    <option value="">Select condition...</option>
                                    <option value="Thumb fatigue and stiffness">Thumb fatigue and stiffness</option>
                                    <option value="Weak grip, reduced hand strength">Weak grip, reduced hand strength</option>
                                    <option value="Stiff joints, limited range of motion">Stiff joints, limited range of motion</option>
                                    <option value="Hand fatigue, muscle tiredness">Hand fatigue, muscle tiredness</option>
                                    <option value="Finger stiffness, reduced flexibility">Finger stiffness, reduced flexibility</option>
                                    <option value="Gaming-related strain">Gaming-related strain</option>
                                    <option value="Thumb strain, excessive phone use">Thumb strain, excessive phone use</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Status</label>
                                <select class="form-select" name="status">
                                    <option value="pending">Pending</option>
                                    <option value="active" selected>Active</option>
                                    <option value="inactive">Inactive</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Assign Therapist</label>
                                <select class="form-select" name="therapist_id">
                                    <option value="">-- Select Therapist --</option>
                                    <?php foreach ($therapists as $therapist): ?>
                                        <option value="<?php echo $therapist['therapist_id']; ?>"><?php echo htmlspecialchars($therapist['full_name']); ?> (<?php echo htmlspecialchars($therapist['staff_id']); ?>)</option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Password</label>
                                <input type="text" class="form-control" name="password" value="123456">
                                <small class="text-muted">Default: 123456</small>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Patient</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- View Patient Modal -->
    <div class="modal fade" id="viewPatientModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-user me-2"></i>Patient Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="viewPatientContent"></div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Edit Patient Modal -->
    <div class="modal fade" id="editPatientModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-edit me-2"></i>Edit Patient</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST" id="editPatientForm">
                    <input type="hidden" name="action" value="edit_patient">
                    <input type="hidden" name="patient_id" id="edit_patient_id">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6 mb-3"><label class="form-label">Full Name *</label><input type="text" class="form-control" name="full_name" id="edit_full_name" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">IC Number *</label><input type="text" class="form-control" name="patient_ic" id="edit_patient_ic" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Email *</label><input type="email" class="form-control" name="email" id="edit_email" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Phone</label><input type="tel" class="form-control" name="phone" id="edit_phone"></div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Finger Condition</label>
                                <select class="form-select" name="finger_condition" id="edit_finger_condition">
                                    <option value="">Select condition...</option>
                                    <option value="Thumb fatigue and stiffness">Thumb fatigue and stiffness</option>
                                    <option value="Weak grip, reduced hand strength">Weak grip, reduced hand strength</option>
                                    <option value="Stiff joints, limited range of motion">Stiff joints, limited range of motion</option>
                                    <option value="Hand fatigue, muscle tiredness">Hand fatigue, muscle tiredness</option>
                                    <option value="Finger stiffness, reduced flexibility">Finger stiffness, reduced flexibility</option>
                                    <option value="Gaming-related strain">Gaming-related strain</option>
                                    <option value="Thumb strain, excessive phone use">Thumb strain, excessive phone use</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Status</label>
                                <select class="form-select" name="status" id="edit_status">
                                    <option value="pending">Pending</option>
                                    <option value="active">Active</option>
                                    <option value="inactive">Inactive</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3"><label class="form-label">Pain Score (1-10)</label><input type="number" class="form-control" name="pain_score" id="edit_pain_score" min="0" max="10"></div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Assign Therapist</label>
                                <select class="form-select" name="therapist_id" id="edit_therapist_id">
                                    <option value="">-- Select Therapist --</option>
                                    <?php foreach ($therapists as $therapist): ?>
                                        <option value="<?php echo $therapist['therapist_id']; ?>"><?php echo htmlspecialchars($therapist['full_name']); ?> (<?php echo htmlspecialchars($therapist['staff_id']); ?>)</option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Save Changes</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Report Modal -->
    <div class="modal fade" id="reportModal" tabindex="-1">
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-file-alt me-2"></i>Patient Report</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="reportContent"></div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="button" class="btn btn-primary" onclick="printReportAsPDF()"><i class="fas fa-print"></i> Print / Save as PDF</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function viewPatient(patient) {
            let content = `
                <div style="padding: 20px;">
                    <div style="text-align: center; margin-bottom: 30px; border-bottom: 2px solid #667eea; padding-bottom: 20px;">
                        <h2>${patient.full_name}</h2>
                        <p>Patient ID: ${patient.patient_id} | Patient IC: ${patient.patient_ic}</p>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Personal Information</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Full Name:</strong> ${patient.full_name}</div>
                            <div class="col-md-6"><strong>IC Number:</strong> ${patient.patient_ic}</div>
                            <div class="col-md-6"><strong>Email:</strong> ${patient.email}</div>
                            <div class="col-md-6"><strong>Phone:</strong> ${patient.phone || '-'}</div>
                            <div class="col-md-6"><strong>Finger Condition:</strong> ${patient.finger_condition || '-'}</div>
                            <div class="col-md-6"><strong>Status:</strong> <span class="badge badge-${patient.status}">${patient.status.toUpperCase()}</span></div>
                        </div>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Therapist Information</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Assigned Therapist:</strong> ${patient.therapist_name || 'Not assigned'}</div>
                            <div class="col-md-6"><strong>Therapist Centre:</strong> ${patient.therapist_centre || '-'}</div>
                        </div>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Exercise Program</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Exercise Set:</strong> ${patient.exercise_set_name || 'Not assigned'}</div>
                            <div class="col-md-6"><strong>Schedule:</strong> ${patient.schedule_start || '-'} to ${patient.schedule_end || '-'}</div>
                            <div class="col-md-6"><strong>Frequency:</strong> ${patient.frequency || '-'}</div>
                        </div>
                    </div>
                    <div>
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Performance Metrics</h4>
                        <div class="row">
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.streak || 0}</div><div>Day Streak</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.compliance_rate || 0}%</div><div>Compliance Rate</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.pain_score || 0}/10</div><div>Pain Score</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.total_completed_sessions || 0}</div><div>Completed Sessions</div></div></div>
                        </div>
                    </div>
                </div>
            `;
            document.getElementById('viewPatientContent').innerHTML = content;
            new bootstrap.Modal(document.getElementById('viewPatientModal')).show();
        }

        function editPatient(patient) {
            document.getElementById('edit_patient_id').value = patient.patient_id;
            document.getElementById('edit_full_name').value = patient.full_name;
            document.getElementById('edit_patient_ic').value = patient.patient_ic;
            document.getElementById('edit_email').value = patient.email;
            document.getElementById('edit_phone').value = patient.phone || '';
            document.getElementById('edit_finger_condition').value = patient.finger_condition || '';
            document.getElementById('edit_status').value = patient.status;
            document.getElementById('edit_pain_score').value = patient.pain_score || 0;
            document.getElementById('edit_therapist_id').value = patient.therapist_id || '';
            new bootstrap.Modal(document.getElementById('editPatientModal')).show();
        }

        function generateReport(patient) {
            let content = `
                <div id="patientReport" style="padding: 30px; font-family: 'Inter', sans-serif;">
                    <div style="text-align: center; margin-bottom: 30px; border-bottom: 2px solid #667eea; padding-bottom: 20px;">
                        <h2>FLEXIFINGER PATIENT REPORT</h2>
                        <p>Generated on: ${new Date().toLocaleString()}</p>
                        <h3>${patient.full_name}</h3>
                        <p>Patient ID: ${patient.patient_id} | IC: ${patient.patient_ic}</p>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Personal Information</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Full Name:</strong> ${patient.full_name}</div>
                            <div class="col-md-6"><strong>IC Number:</strong> ${patient.patient_ic}</div>
                            <div class="col-md-6"><strong>Email:</strong> ${patient.email}</div>
                            <div class="col-md-6"><strong>Phone:</strong> ${patient.phone || '-'}</div>
                            <div class="col-md-6"><strong>Finger Condition:</strong> ${patient.finger_condition || '-'}</div>
                            <div class="col-md-6"><strong>Status:</strong> ${patient.status.toUpperCase()}</div>
                        </div>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Therapist Information</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Assigned Therapist:</strong> ${patient.therapist_name || 'Not assigned'}</div>
                            <div class="col-md-6"><strong>Therapist Centre:</strong> ${patient.therapist_centre || '-'}</div>
                        </div>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Exercise Program Details</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Exercise Set:</strong> ${patient.exercise_set_name || 'Not assigned'}</div>
                            <div class="col-md-6"><strong>Schedule Period:</strong> ${patient.schedule_start || '-'} to ${patient.schedule_end || '-'}</div>
                            <div class="col-md-6"><strong>Frequency:</strong> ${patient.frequency || '-'}</div>
                            <div class="col-md-6"><strong>Program Start Date:</strong> ${patient.program_start_date || 'Not started'}</div>
                        </div>
                    </div>
                    <div>
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Performance Summary</h4>
                        <div class="row">
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.streak || 0}</div><div>Current Streak</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.compliance_rate || 0}%</div><div>Compliance Rate</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.pain_score || 0}/10</div><div>Current Pain Score</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${patient.total_completed_sessions || 0}</div><div>Completed Sessions</div></div></div>
                        </div>
                        <div class="row mt-3">
                            <div class="col-md-6"><strong>Daily Status:</strong> ${patient.daily_status || 'Pending'}</div>
                            <div class="col-md-6"><strong>Registered Date:</strong> ${patient.created_at || '-'}</div>
                        </div>
                    </div>
                    <div style="text-align: center; margin-top: 30px; color: #94a3b8; font-size: 12px;">
                        FlexiFinger - Finger Exercise Monitoring System<br>
                        This is an official report generated by the system.
                    </div>
                </div>
            `;
            document.getElementById('reportContent').innerHTML = content;
            window.reportElement = document.getElementById('patientReport');
            new bootstrap.Modal(document.getElementById('reportModal')).show();
        }

        function printReportAsPDF() {
            const element = window.reportElement;
            const opt = {
                margin: [0.5, 0.5, 0.5, 0.5],
                filename: 'patient_report.pdf',
                image: { type: 'jpeg', quality: 0.98 },
                html2canvas: { scale: 2, letterRendering: true },
                jsPDF: { unit: 'in', format: 'a4', orientation: 'portrait' }
            };
            html2pdf().set(opt).from(element).save();
        }

        function deletePatient(id, name) {
            if (confirm('Delete patient "' + name + '"?')) {
                var form = document.createElement('form');
                form.method = 'POST';
                form.innerHTML = '<input type="hidden" name="action" value="delete_patient"><input type="hidden" name="patient_id" value="' + id + '">';
                document.body.appendChild(form);
                form.submit();
            }
        }
    </script>
    <style>
        .stat-box { background: #f8fafc; padding: 15px; border-radius: 12px; text-align: center; margin-bottom: 10px; }
        .stat-number { font-size: 28px; font-weight: 800; color: #667eea; }
        .btn-report { background: #10b981; color: white; border: none; padding: 5px 12px; border-radius: 8px; margin: 2px; }
        .btn-view { background: #667eea; color: white; border: none; padding: 5px 12px; border-radius: 8px; margin: 2px; }
        .btn-edit { background: #f59e0b; color: white; border: none; padding: 5px 12px; border-radius: 8px; margin: 2px; }
    </style>
</body>
</html>