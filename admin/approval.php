<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';
require_once 'includes/email-config.php';  // 🔴 PASTIKAN ADA

$auth->requireLogin();

$conn = getDBConnection();
$functions = new Functions();

// Get pending data
$pendingPatients = $conn->query("
    SELECT * FROM patients WHERE status = 'pending' ORDER BY created_at DESC
")->fetch_all(MYSQLI_ASSOC);

$pendingTherapists = $conn->query("
    SELECT * FROM therapists WHERE status = 'pending' ORDER BY created_at DESC
")->fetch_all(MYSQLI_ASSOC);

// Get active therapists for dropdown
$therapists = $conn->query("
    SELECT therapist_id, full_name, staff_id, centre_name 
    FROM therapists WHERE status = 'active' ORDER BY full_name
")->fetch_all(MYSQLI_ASSOC);

// Handle patient approval/rejection
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save_approval'])) {
    $patient_id = $_POST['patient_id'] ?? '';
    $status = $_POST['status'] ?? '';
    $therapist_id = $_POST['therapist_id'] ?? '';
    
    if ($patient_id && $status) {
        if ($status === 'active') {
            $stmt = $conn->prepare("UPDATE patients SET status = 'active', validated_at = NOW(), validated_by = ? WHERE patient_id = ?");
            $stmt->bind_param("ii", $_SESSION['admin_id'], $patient_id);
            $stmt->execute();
            
            if (!empty($therapist_id)) {
                $stmt2 = $conn->prepare("UPDATE patients SET therapist_id = ?, program_start_date = CURDATE() WHERE patient_id = ?");
                $stmt2->bind_param("ii", $therapist_id, $patient_id);
                $stmt2->execute();
                $conn->query("UPDATE therapists SET patient_count = (SELECT COUNT(*) FROM patients WHERE therapist_id = $therapist_id) WHERE therapist_id = $therapist_id");
            }
            
            // 🔴 SEND EMAIL TO PATIENT (from a.flexifinger@gmail.com)
            $patientData = $conn->query("SELECT full_name, email FROM patients WHERE patient_id = $patient_id")->fetch_assoc();
            $subject = "FlexiFinger - Your Account Has Been Approved!";
            $message = "
            <!DOCTYPE html>
            <html>
            <head><meta charset='UTF-8'></head>
            <body style='font-family: Arial, sans-serif;'>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px; background: #f8fafc;'>
                    <div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 12px 12px 0 0;'>
                        <h2>Account Approved! 🎉</h2>
                    </div>
                    <div style='background: white; padding: 30px; border-radius: 0 0 12px 12px;'>
                        <p>Dear <strong>{$patientData['full_name']}</strong>,</p>
                        <p>Your FlexiFinger patient account has been <strong>approved</strong>!</p>
                        <p>You can now log in to the app and start your finger exercise program.</p>
                        <p>If you have been assigned a therapist, they will contact you soon.</p>
                        <a href='https://bijakmahir.com/flexi/flexifinger/mobile' style='display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px;'>Open App</a>
                        <p style='margin-top: 20px;'>Best regards,<br><strong>FlexiFinger Team</strong></p>
                    </div>
                </div>
            </body>
            </html>
            ";
            sendEmail($patientData['email'], $subject, $message);
            
            $_SESSION['success'] = "Patient approved successfully!";
        } elseif ($status === 'rejected') {
            $stmt = $conn->prepare("UPDATE patients SET status = 'inactive', validated_at = NOW(), validated_by = ? WHERE patient_id = ?");
            $stmt->bind_param("ii", $_SESSION['admin_id'], $patient_id);
            $stmt->execute();
            $_SESSION['success'] = "Patient rejected successfully!";
        }
        header("Location: approval.php");
        exit();
    }
}

// Handle therapist approval/rejection
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'] ?? '';
    $type = $_POST['type'] ?? '';
    $id = $_POST['id'] ?? '';
    
    if ($type === 'therapist') {
        if ($action === 'approve') {
            $stmt = $conn->prepare("UPDATE therapists SET status = 'active', validated_at = NOW(), validated_by = ? WHERE therapist_id = ?");
            $stmt->bind_param("ii", $_SESSION['admin_id'], $id);
            $stmt->execute();
            
            // 🔴 Send email to therapist (from a.flexifinger@gmail.com)
            $therapistData = $conn->query("SELECT full_name, email FROM therapists WHERE therapist_id = $id")->fetch_assoc();
            $subject = "FlexiFinger - Your Therapist Account Has Been Approved!";
            $message = "
            <!DOCTYPE html>
            <html>
            <head><meta charset='UTF-8'></head>
            <body style='font-family: Arial, sans-serif;'>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px; background: #f8fafc;'>
                    <div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 12px 12px 0 0;'>
                        <h2>Therapist Account Approved! 🎉</h2>
                    </div>
                    <div style='background: white; padding: 30px; border-radius: 0 0 12px 12px;'>
                        <p>Dear <strong>{$therapistData['full_name']}</strong>,</p>
                        <p>Your FlexiFinger therapist account has been <strong>approved</strong>!</p>
                        <p>You can now log in to the therapist app and start managing patients.</p>
                        <a href='https://bijakmahir.com/flexi/flexifinger/mobile' style='display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px;'>Open App</a>
                        <p style='margin-top: 20px;'>Best regards,<br><strong>FlexiFinger Team</strong></p>
                    </div>
                </div>
            </body>
            </html>
            ";
            sendEmail($therapistData['email'], $subject, $message);
            
            $_SESSION['success'] = "Therapist approved successfully!";
        } elseif ($action === 'reject') {
            $stmt = $conn->prepare("UPDATE therapists SET status = 'inactive', validated_at = NOW(), validated_by = ? WHERE therapist_id = ?");
            $stmt->bind_param("ii", $_SESSION['admin_id'], $id);
            $stmt->execute();
            $_SESSION['success'] = "Therapist rejected successfully!";
        }
        header("Location: approval.php");
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
    <title>Approval - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/admin.css">
    <style>
        .badge-pending { background: #fef3c7; color: #92400e; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-active { background: #d1fae5; color: #065f46; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-inactive { background: #e5e7eb; color: #374151; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-info { background: #dbeafe; color: #1e40af; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-secondary { background: #f3e8ff; color: #6b21a8; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-warning { background: #fef3c7; color: #92400e; }
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
            <a href="approval.php" class="nav-link active"><i class="fas fa-user-check"></i> Approval</a>
            <a href="patient-management.php" class="nav-link"><i class="fas fa-users"></i> Patient Management</a>
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
                <h4>User Approval</h4>
                <p>Validate and approve pending registrations</p>
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

        <!-- Pending Patients -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="fas fa-users me-2"></i> Pending Patients (<?php echo count($pendingPatients); ?>)</span>
                <span class="badge bg-warning">Require Validation</span>
            </div>
            <div class="card-body">
                <?php if (empty($pendingPatients)): ?>
                    <div class="text-center py-4">
                        <i class="fas fa-user-check fa-3x text-muted mb-3"></i>
                        <h5>No Pending Patients</h5>
                        <p class="text-muted">All patient registrations have been processed.</p>
                    </div>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr><th>Full Name</th><th>IC Number</th><th>Email</th><th>Phone</th><th>Condition</th><th>Registered</th><th>Actions</th></tr>
                            </thead>
                            <tbody>
                                <?php foreach ($pendingPatients as $patient): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($patient['full_name']); ?></td>
                                    <td><code><?php echo htmlspecialchars($patient['patient_ic']); ?></code></td>
                                    <td><?php echo htmlspecialchars($patient['email']); ?></td>
                                    <td><?php echo htmlspecialchars($patient['phone']); ?></td>
                                    <td><span class="badge-info"><?php echo htmlspecialchars($patient['finger_condition'] ?? 'Not specified'); ?></span></td>
                                    <td><?php echo date('M d, Y', strtotime($patient['created_at'])); ?></td>
                                    <td>
                                        <button class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#approvalModal"
                                                data-patient-id="<?php echo $patient['patient_id']; ?>"
                                                data-patient-name="<?php echo htmlspecialchars($patient['full_name']); ?>"
                                                data-patient-ic="<?php echo htmlspecialchars($patient['patient_ic']); ?>"
                                                data-patient-email="<?php echo htmlspecialchars($patient['email']); ?>"
                                                data-patient-condition="<?php echo htmlspecialchars($patient['finger_condition'] ?? 'Not specified'); ?>"
                                                onclick="setApprovalModal(this)">
                                            <i class="fas fa-check-circle"></i> Approval
                                        </button>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>

        <!-- Pending Therapists -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <span><i class="fas fa-user-md me-2"></i> Pending Therapists (<?php echo count($pendingTherapists); ?>)</span>
                <span class="badge bg-warning">Require Validation</span>
            </div>
            <div class="card-body">
                <?php if (empty($pendingTherapists)): ?>
                    <div class="text-center py-4">
                        <i class="fas fa-user-md fa-3x text-muted mb-3"></i>
                        <h5>No Pending Therapists</h5>
                        <p class="text-muted">All therapist registrations have been processed.</p>
                    </div>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr><th>Full Name</th><th>Staff ID</th><th>Email</th><th>Phone</th><th>Centre</th><th>Type</th><th>Registered</th><th>Actions</th></tr>
                            </thead>
                            <tbody>
                                <?php foreach ($pendingTherapists as $therapist): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($therapist['full_name']); ?></td>
                                    <td><code><?php echo htmlspecialchars($therapist['staff_id']); ?></code></td>
                                    <td><?php echo htmlspecialchars($therapist['email']); ?></td>
                                    <td><?php echo htmlspecialchars($therapist['phone']); ?></td>
                                    <td><?php echo htmlspecialchars($therapist['centre_name']); ?></td>
                                    <td><span class="badge-secondary"><?php echo htmlspecialchars(ucfirst($therapist['centre_type'])); ?></span></td>
                                    <td><?php echo date('M d, Y', strtotime($therapist['created_at'])); ?></td>
                                    <td>
                                        <form method="POST" style="display: inline;">
                                            <input type="hidden" name="type" value="therapist">
                                            <input type="hidden" name="id" value="<?php echo $therapist['therapist_id']; ?>">
                                            <button type="submit" name="action" value="approve" class="btn btn-success btn-sm" onclick="return confirm('Approve this therapist?')"><i class="fas fa-check"></i> Approve</button>
                                            <button type="submit" name="action" value="reject" class="btn btn-danger btn-sm" onclick="return confirm('Reject this therapist?')"><i class="fas fa-times"></i> Reject</button>
                                        </form>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <!-- Approval Modal for Patient -->
    <div class="modal fade" id="approvalModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-user-check me-2"></i>Patient Approval</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form method="POST">
                    <input type="hidden" name="save_approval" value="1">
                    <input type="hidden" name="patient_id" id="modalPatientId">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label class="form-label fw-bold">Full Name</label>
                            <input type="text" class="form-control" id="modalPatientName" readonly>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">IC Number</label>
                            <input type="text" class="form-control" id="modalPatientIc" readonly>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">Email</label>
                            <input type="text" class="form-control" id="modalPatientEmail" readonly>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">Condition</label>
                            <input type="text" class="form-control" id="modalPatientCondition" readonly>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">Status</label>
                            <select class="form-select" name="status" required>
                                <option value="">-- Select Status --</option>
                                <option value="active">Approve</option>
                                <option value="rejected">Reject</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">Assign Therapist (Optional)</label>
                            <select class="form-select" name="therapist_id">
                                <option value="">-- Select Therapist --</option>
                                <?php foreach ($therapists as $therapist): ?>
                                    <option value="<?php echo $therapist['therapist_id']; ?>">
                                        <?php echo htmlspecialchars($therapist['full_name']); ?> 
                                        (<?php echo htmlspecialchars($therapist['staff_id']); ?>) - 
                                        <?php echo htmlspecialchars($therapist['centre_name']); ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function setApprovalModal(button) {
            document.getElementById('modalPatientId').value = button.getAttribute('data-patient-id');
            document.getElementById('modalPatientName').value = button.getAttribute('data-patient-name');
            document.getElementById('modalPatientIc').value = button.getAttribute('data-patient-ic');
            document.getElementById('modalPatientEmail').value = button.getAttribute('data-patient-email');
            document.getElementById('modalPatientCondition').value = button.getAttribute('data-patient-condition');
        }
    </script>
</body>
</html>