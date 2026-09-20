<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

$auth->requireLogin();

$conn = getDBConnection();

// Get all therapists with detailed stats
$therapists = $conn->query("
    SELECT 
        t.*,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id) as patient_count,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id AND status = 'active') as active_patient_count,
        (SELECT COALESCE(AVG(compliance_rate), 0) FROM patients WHERE therapist_id = t.therapist_id) as avg_compliance,
        (SELECT COALESCE(AVG(pain_score), 0) FROM patients WHERE therapist_id = t.therapist_id) as avg_pain_score,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id AND daily_status = 'Completed today') as completed_today
    FROM therapists t
    ORDER BY t.created_at DESC
")->fetch_all(MYSQLI_ASSOC);

// Get all patients for assignment display
$allPatients = $conn->query("
    SELECT patient_id, full_name, therapist_id, status, compliance_rate, pain_score
    FROM patients ORDER BY full_name
")->fetch_all(MYSQLI_ASSOC);

// Handle search
$search = $_GET['search'] ?? '';
if ($search) {
    $therapists = array_filter($therapists, function($therapist) use ($search) {
        return stripos($therapist['full_name'], $search) !== false || 
               stripos($therapist['staff_id'], $search) !== false ||
               stripos($therapist['email'], $search) !== false ||
               stripos($therapist['centre_name'], $search) !== false;
    });
}

// Handle status filter
$status_filter = $_GET['status'] ?? '';
if ($status_filter && $status_filter !== 'all') {
    $therapists = array_filter($therapists, function($therapist) use ($status_filter) {
        return $therapist['status'] === $status_filter;
    });
}

// Handle Add/Edit/Delete Therapist
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'add_therapist') {
        $staff_id = $_POST['staff_id'] ?? '';
        $full_name = $_POST['full_name'] ?? '';
        $email = $_POST['email'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $whatsapp = $_POST['whatsapp'] ?? '';
        $centre_name = $_POST['centre_name'] ?? '';
        $centre_type = $_POST['centre_type'] ?? 'clinic';
        $status = $_POST['status'] ?? 'pending';
        $password = $_POST['password'] ?? 'Therapist123';
        
        if ($staff_id && $full_name && $email) {
            $check = $conn->query("SELECT therapist_id FROM therapists WHERE staff_id = '$staff_id' OR email = '$email'");
            if ($check->num_rows > 0) {
                $_SESSION['error'] = "Staff ID or Email already exists!";
            } else {
                $stmt = $conn->prepare("
                    INSERT INTO therapists (staff_id, full_name, email, phone, whatsapp, centre_name, centre_type, status, password_hash, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                ");
                $stmt->bind_param("sssssssss", $staff_id, $full_name, $email, $phone, $whatsapp, $centre_name, $centre_type, $status, $password);
                if ($stmt->execute()) {
                    $_SESSION['success'] = "Therapist added successfully!";
                    if ($status === 'active') {
                        $therapist_id = $conn->insert_id;
                        $conn->query("UPDATE therapists SET validated_at = NOW(), validated_by = {$_SESSION['admin_id']} WHERE therapist_id = $therapist_id");
                    }
                } else {
                    $_SESSION['error'] = "Failed to add therapist.";
                }
            }
        }
        header("Location: therapist-management.php");
        exit();
    }
    
    elseif ($action === 'edit_therapist') {
        $therapist_id = $_POST['therapist_id'] ?? '';
        $staff_id = $_POST['staff_id'] ?? '';
        $full_name = $_POST['full_name'] ?? '';
        $email = $_POST['email'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $whatsapp = $_POST['whatsapp'] ?? '';
        $centre_name = $_POST['centre_name'] ?? '';
        $centre_type = $_POST['centre_type'] ?? '';
        $status = $_POST['status'] ?? '';
        
        if ($therapist_id && $full_name) {
            $stmt = $conn->prepare("
                UPDATE therapists SET 
                    staff_id = ?, full_name = ?, email = ?, phone = ?, 
                    whatsapp = ?, centre_name = ?, centre_type = ?, status = ?
                WHERE therapist_id = ?
            ");
            $stmt->bind_param("ssssssssi", $staff_id, $full_name, $email, $phone, $whatsapp, $centre_name, $centre_type, $status, $therapist_id);
            if ($stmt->execute()) {
                $_SESSION['success'] = "Therapist updated successfully!";
            } else {
                $_SESSION['error'] = "Failed to update therapist.";
            }
        }
        header("Location: therapist-management.php");
        exit();
    }
    
    elseif ($action === 'delete_therapist') {
        $therapist_id = $_POST['therapist_id'] ?? '';
        if ($therapist_id) {
            // Check if has patients
            $check = $conn->query("SELECT COUNT(*) as cnt FROM patients WHERE therapist_id = $therapist_id");
            if ($check->fetch_assoc()['cnt'] > 0) {
                $_SESSION['error'] = "Cannot delete therapist with assigned patients. Reassign patients first.";
            } else {
                $stmt = $conn->prepare("DELETE FROM therapists WHERE therapist_id = ?");
                $stmt->bind_param("i", $therapist_id);
                if ($stmt->execute()) {
                    $_SESSION['success'] = "Therapist deleted successfully!";
                } else {
                    $_SESSION['error'] = "Failed to delete therapist.";
                }
            }
        }
        header("Location: therapist-management.php");
        exit();
    }
    
    elseif ($action === 'update_status') {
        $therapist_id = $_POST['therapist_id'] ?? '';
        $status = $_POST['status'] ?? '';
        if ($therapist_id && $status) {
            $stmt = $conn->prepare("UPDATE therapists SET status = ? WHERE therapist_id = ?");
            $stmt->bind_param("si", $status, $therapist_id);
            if ($stmt->execute()) {
                $_SESSION['success'] = "Therapist status updated!";
            }
        }
        header("Location: therapist-management.php");
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
    <title>Therapist Management - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/admin.css">
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
            <a href="patient-management.php" class="nav-link"><i class="fas fa-users"></i> Patient Management</a>
            <a href="therapist-management.php" class="nav-link active"><i class="fas fa-user-md"></i> Therapist Management</a>
            <a href="exercise-management.php" class="nav-link"><i class="fas fa-dumbbell"></i> Exercise Management</a>
            <a href="reporting.php" class="nav-link"><i class="fas fa-chart-bar"></i> Reports</a>
            <a href="profile.php" class="nav-link"><i class="fas fa-user-cog"></i> Settings</a>
            <a href="logout.php" class="nav-link mt-4"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </nav>
    </div>

    <div class="main-content">
        <div class="navbar-top">
            <div class="welcome-text">
                <h4>Therapist Management</h4>
                <p>Manage therapist accounts and assignments</p>
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
                                <input type="text" class="form-control" name="search" placeholder="Search by name, staff ID, email, or centre..." value="<?php echo htmlspecialchars($search); ?>">
                                <button class="btn btn-primary" type="submit">Search</button>
                                <?php if ($search): ?>
                                    <a href="therapist-management.php" class="btn btn-outline-secondary">Clear</a>
                                <?php endif; ?>
                            </div>
                        </form>
                    </div>
                    <div class="col-md-6 text-end">
                        <div class="btn-group me-2">
                            <a href="therapist-management.php" class="btn btn-outline-primary <?php echo !$status_filter ? 'active' : ''; ?>">All</a>
                            <a href="therapist-management.php?status=active" class="btn btn-outline-success <?php echo $status_filter === 'active' ? 'active' : ''; ?>">Active</a>
                            <a href="therapist-management.php?status=pending" class="btn btn-outline-warning <?php echo $status_filter === 'pending' ? 'active' : ''; ?>">Pending</a>
                            <a href="therapist-management.php?status=inactive" class="btn btn-outline-secondary <?php echo $status_filter === 'inactive' ? 'active' : ''; ?>">Inactive</a>
                        </div>
                        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addTherapistModal"><i class="fas fa-user-plus"></i> Add Therapist</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Therapists Table -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="fas fa-user-md me-2"></i> Therapist Records (<?php echo count($therapists); ?>)</span>
                <span class="badge bg-info">Total Patients Assigned: <?php echo array_sum(array_column($therapists, 'patient_count')); ?></span>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Staff ID</th>
                                <th>Full Name</th>
                                <th>Contact</th>
                                <th>Centre</th>
                                <th>Patients</th>
                                <th>Avg Compliance</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($therapists as $therapist): ?>
                            <tr>
                                <td><code><?php echo htmlspecialchars($therapist['staff_id']); ?></code></td>
                                <td>
                                    <strong><?php echo htmlspecialchars($therapist['full_name']); ?></strong>
                                    <br><small class="text-muted"><?php echo htmlspecialchars($therapist['email']); ?></small>
                                </td>
                                <td>
                                    <?php if ($therapist['phone']): ?>
                                        <i class="fas fa-phone"></i> <?php echo htmlspecialchars($therapist['phone']); ?><br>
                                    <?php endif; ?>
                                    <?php if ($therapist['whatsapp']): ?>
                                        <i class="fab fa-whatsapp text-success"></i> <?php echo htmlspecialchars($therapist['whatsapp']); ?>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <span class="badge bg-secondary"><?php echo ucfirst($therapist['centre_type']); ?></span>
                                    <br><small><?php echo htmlspecialchars($therapist['centre_name']); ?></small>
                                </td>
                                <td>
                                    <span class="badge bg-primary"><?php echo $therapist['patient_count']; ?> patients</span>
                                    <br><small class="text-muted">Active: <?php echo $therapist['active_patient_count']; ?></small>
                                </td>
                                <td>
                                    <span class="badge bg-success"><?php echo round($therapist['avg_compliance'], 1); ?>%</span>
                                    <br><small>Pain: <?php echo round($therapist['avg_pain_score'], 1); ?>/10</small>
                                </td>
                                <td>
                                    <span class="badge badge-<?php echo $therapist['status']; ?>"><?php echo ucfirst($therapist['status']); ?></span>
                                    <br><small>Today: <?php echo $therapist['completed_today']; ?> completed</small>
                                </td>
                                <td>
                                    <button class="btn btn-view btn-sm" onclick="viewTherapist(<?php echo htmlspecialchars(json_encode($therapist)); ?>)"><i class="fas fa-eye"></i> View</button>
                                    <button class="btn btn-edit btn-sm" onclick="editTherapist(<?php echo htmlspecialchars(json_encode($therapist)); ?>)"><i class="fas fa-edit"></i> Edit</button>
                                    <form method="POST" style="display:inline;" onsubmit="return confirm('Change therapist status?')">
                                        <input type="hidden" name="action" value="update_status">
                                        <input type="hidden" name="therapist_id" value="<?php echo $therapist['therapist_id']; ?>">
                                        <select name="status" class="form-select form-select-sm d-inline-block w-auto" onchange="this.form.submit()">
                                            <option value="pending" <?php echo $therapist['status'] === 'pending' ? 'selected' : ''; ?>>Pending</option>
                                            <option value="active" <?php echo $therapist['status'] === 'active' ? 'selected' : ''; ?>>Active</option>
                                            <option value="inactive" <?php echo $therapist['status'] === 'inactive' ? 'selected' : ''; ?>>Inactive</option>
                                        </select>
                                    </form>
                                    <button class="btn btn-danger btn-sm" onclick="deleteTherapist(<?php echo $therapist['therapist_id']; ?>, '<?php echo htmlspecialchars($therapist['full_name']); ?>')"><i class="fas fa-trash"></i></button>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                            <?php if (empty($therapists)): ?>
                            <tr><td colspan="8" class="text-center py-4">No therapists found</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Add Therapist Modal -->
    <div class="modal fade" id="addTherapistModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-user-plus me-2"></i>Add New Therapist</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="action" value="add_therapist">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6 mb-3"><label class="form-label">Staff ID *</label><input type="text" class="form-control" name="staff_id" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Full Name *</label><input type="text" class="form-control" name="full_name" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Email *</label><input type="email" class="form-control" name="email" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Phone</label><input type="tel" class="form-control" name="phone"></div>
                            <div class="col-md-6 mb-3"><label class="form-label">WhatsApp</label><input type="tel" class="form-control" name="whatsapp"></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Centre Name *</label><input type="text" class="form-control" name="centre_name" required></div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Centre Type</label>
                                <select class="form-select" name="centre_type">
                                    <option value="hospital">Hospital</option>
                                    <option value="clinic" selected>Clinic</option>
                                    <option value="centre">Centre</option>
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
                            <div class="col-md-12 mb-3">
                                <label class="form-label">Password</label>
                                <input type="text" class="form-control" name="password" value="Therapist123">
                                <small class="text-muted">Default: Therapist123</small>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Therapist</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- View Therapist Modal -->
    <div class="modal fade" id="viewTherapistModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-user-md me-2"></i>Therapist Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="viewTherapistContent"></div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Edit Therapist Modal -->
    <div class="modal fade" id="editTherapistModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-edit me-2"></i>Edit Therapist</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST" id="editTherapistForm">
                    <input type="hidden" name="action" value="edit_therapist">
                    <input type="hidden" name="therapist_id" id="edit_therapist_id">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6 mb-3"><label class="form-label">Staff ID *</label><input type="text" class="form-control" name="staff_id" id="edit_staff_id" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Full Name *</label><input type="text" class="form-control" name="full_name" id="edit_full_name" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Email *</label><input type="email" class="form-control" name="email" id="edit_email" required></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Phone</label><input type="tel" class="form-control" name="phone" id="edit_phone"></div>
                            <div class="col-md-6 mb-3"><label class="form-label">WhatsApp</label><input type="tel" class="form-control" name="whatsapp" id="edit_whatsapp"></div>
                            <div class="col-md-6 mb-3"><label class="form-label">Centre Name *</label><input type="text" class="form-control" name="centre_name" id="edit_centre_name" required></div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Centre Type</label>
                                <select class="form-select" name="centre_type" id="edit_centre_type">
                                    <option value="hospital">Hospital</option>
                                    <option value="clinic">Clinic</option>
                                    <option value="centre">Centre</option>
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

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function viewTherapist(therapist) {
            let content = `
                <div style="padding: 20px;">
                    <div style="text-align: center; margin-bottom: 30px; border-bottom: 2px solid #667eea; padding-bottom: 20px;">
                        <h2>${therapist.full_name}</h2>
                        <p>Staff ID: ${therapist.staff_id}</p>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Personal Information</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Staff ID:</strong> ${therapist.staff_id}</div>
                            <div class="col-md-6"><strong>Full Name:</strong> ${therapist.full_name}</div>
                            <div class="col-md-6"><strong>Email:</strong> ${therapist.email}</div>
                            <div class="col-md-6"><strong>Phone:</strong> ${therapist.phone || '-'}</div>
                            <div class="col-md-6"><strong>WhatsApp:</strong> ${therapist.whatsapp || '-'}</div>
                            <div class="col-md-6"><strong>Status:</strong> <span class="badge badge-${therapist.status}">${therapist.status.toUpperCase()}</span></div>
                        </div>
                    </div>
                    <div style="margin-bottom: 25px;">
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Centre Information</h4>
                        <div class="row">
                            <div class="col-md-6"><strong>Centre Name:</strong> ${therapist.centre_name}</div>
                            <div class="col-md-6"><strong>Centre Type:</strong> ${therapist.centre_type}</div>
                            <div class="col-md-6"><strong>Registered:</strong> ${therapist.created_at || '-'}</div>
                            <div class="col-md-6"><strong>Validated:</strong> ${therapist.validated_at || 'Not yet'}</div>
                        </div>
                    </div>
                    <div>
                        <h4 style="color: #667eea; border-left: 4px solid #667eea; padding-left: 15px; margin-bottom: 15px;">Performance Summary</h4>
                        <div class="row">
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${therapist.patient_count}</div><div>Total Patients</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${therapist.active_patient_count}</div><div>Active Patients</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${Math.round(therapist.avg_compliance)}%</div><div>Avg Compliance</div></div></div>
                            <div class="col-md-3"><div class="stat-box"><div class="stat-number">${Math.round(therapist.avg_pain_score)}/10</div><div>Avg Pain Score</div></div></div>
                        </div>
                        <div class="row mt-3">
                            <div class="col-md-6"><strong>Today's Completions:</strong> ${therapist.completed_today}</div>
                        </div>
                    </div>
                </div>
            `;
            document.getElementById('viewTherapistContent').innerHTML = content;
            new bootstrap.Modal(document.getElementById('viewTherapistModal')).show();
        }

        function editTherapist(therapist) {
            document.getElementById('edit_therapist_id').value = therapist.therapist_id;
            document.getElementById('edit_staff_id').value = therapist.staff_id;
            document.getElementById('edit_full_name').value = therapist.full_name;
            document.getElementById('edit_email').value = therapist.email;
            document.getElementById('edit_phone').value = therapist.phone || '';
            document.getElementById('edit_whatsapp').value = therapist.whatsapp || '';
            document.getElementById('edit_centre_name').value = therapist.centre_name;
            document.getElementById('edit_centre_type').value = therapist.centre_type;
            document.getElementById('edit_status').value = therapist.status;
            new bootstrap.Modal(document.getElementById('editTherapistModal')).show();
        }

        function deleteTherapist(id, name) {
            if (confirm(`Delete therapist "${name}"? This will NOT delete assigned patients.`)) {
                let form = document.createElement('form');
                form.method = 'POST';
                form.innerHTML = `<input type="hidden" name="action" value="delete_therapist"><input type="hidden" name="therapist_id" value="${id}">`;
                document.body.appendChild(form);
                form.submit();
            }
        }
    </script>
    <style>
        .stat-box { background: #f8fafc; padding: 15px; border-radius: 12px; text-align: center; margin-bottom: 10px; }
        .stat-number { font-size: 28px; font-weight: 800; color: #667eea; }
        .btn-view { background: #667eea; color: white; border: none; padding: 5px 12px; border-radius: 8px; margin: 2px; }
        .btn-edit { background: #f59e0b; color: white; border: none; padding: 5px 12px; border-radius: 8px; margin: 2px; }
    </style>
</body>
</html>