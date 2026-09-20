<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

$auth->requireLogin();
$adminDetails = $auth->getAdminDetails($_SESSION['admin_id']);
$message = '';
$message_type = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['update_profile'])) {
        $fullName = $_POST['full_name'];
        $phone = $_POST['phone'];
        $centreName = $_POST['centre_name'];
        $centreAddress = $_POST['centre_address'];
        if ($auth->updateAdminProfile($_SESSION['admin_id'], $fullName, $phone, $centreName, $centreAddress)) {
            $_SESSION['admin_name'] = $fullName;
            $message = "Profile updated successfully!";
            $message_type = "success";
            $adminDetails = $auth->getAdminDetails($_SESSION['admin_id']);
        } else {
            $message = "Failed to update profile.";
            $message_type = "error";
        }
    } elseif (isset($_POST['change_password'])) {
        $currentPassword = $_POST['current_password'];
        $newPassword = $_POST['new_password'];
        $confirmPassword = $_POST['confirm_password'];
        if ($newPassword !== $confirmPassword) {
            $message = "New passwords do not match!";
            $message_type = "error";
        } elseif (strlen($newPassword) < 6) {
            $message = "Password must be at least 6 characters!";
            $message_type = "error";
        } else {
            if ($auth->changePassword($_SESSION['admin_id'], $currentPassword, $newPassword)) {
                $message = "Password changed successfully!";
                $message_type = "success";
            } else {
                $message = "Current password is incorrect!";
                $message_type = "error";
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profile & Settings - FlexiFinger Admin</title>
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
            <a href="therapist-management.php" class="nav-link"><i class="fas fa-user-md"></i> Therapist Management</a>
            <a href="exercise-management.php" class="nav-link"><i class="fas fa-dumbbell"></i> Exercise Management</a>
            <a href="reporting.php" class="nav-link"><i class="fas fa-chart-bar"></i> Reports</a>
            <a href="profile.php" class="nav-link active"><i class="fas fa-user-cog"></i> Settings</a>
            <a href="logout.php" class="nav-link mt-4"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </nav>
    </div>

    <div class="main-content">
        <div class="navbar-top">
            <div class="welcome-text"><h4>Profile & Settings</h4><p>Manage your account and system preferences</p></div>
            <div class="admin-badge"><i class="fas fa-user-shield"></i> Administrator</div>
        </div>

        <?php if ($message): ?>
            <div class="alert alert-<?php echo $message_type === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
                <i class="fas fa-<?php echo $message_type === 'success' ? 'check-circle' : 'exclamation-circle'; ?>"></i> <?php echo htmlspecialchars($message); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>

        <div class="card">
            <div class="card-header"><i class="fas fa-user me-2"></i> Personal Information</div>
            <div class="card-body">
                <div class="text-center mb-4"><div class="profile-avatar" style="width:100px;height:100px;background:linear-gradient(135deg,#667eea,#764ba2);border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 20px;"><i class="fas fa-user-shield fa-3x text-white"></i></div><h4><?php echo htmlspecialchars($adminDetails['full_name']); ?></h4></div>
                <form method="POST">
                    <div class="row">
                        <div class="col-md-6 mb-3"><label class="form-label">Full Name</label><input type="text" class="form-control" name="full_name" value="<?php echo htmlspecialchars($adminDetails['full_name']); ?>" required></div>
                        <div class="col-md-6 mb-3"><label class="form-label">Admin ID</label><input type="text" class="form-control" value="<?php echo htmlspecialchars($adminDetails['admin_id']); ?>" readonly></div>
                        <div class="col-md-6 mb-3"><label class="form-label">Email Address</label><input type="email" class="form-control" value="<?php echo htmlspecialchars($adminDetails['email']); ?>" readonly></div>
                        <div class="col-md-6 mb-3"><label class="form-label">Phone Number</label><input type="tel" class="form-control" name="phone" value="<?php echo htmlspecialchars($adminDetails['phone'] ?? ''); ?>"></div>
                        <div class="col-md-6 mb-3"><label class="form-label">Centre Name</label><input type="text" class="form-control" name="centre_name" value="<?php echo htmlspecialchars($adminDetails['centre_name'] ?? ''); ?>"></div>
                        <div class="col-md-6 mb-3"><label class="form-label">Centre Address</label><textarea class="form-control" name="centre_address" rows="1"><?php echo htmlspecialchars($adminDetails['centre_address'] ?? ''); ?></textarea></div>
                    </div>
                    <div class="text-center mt-4"><button type="submit" name="update_profile" class="btn btn-primary"><i class="fas fa-save me-2"></i> Save Changes</button></div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-header"><i class="fas fa-lock me-2"></i> Change Password</div>
            <div class="card-body">
                <form method="POST">
                    <div class="row">
                        <div class="col-md-4 mb-3"><label class="form-label">Current Password</label><input type="password" class="form-control" name="current_password" required></div>
                        <div class="col-md-4 mb-3"><label class="form-label">New Password</label><input type="password" class="form-control" name="new_password" required></div>
                        <div class="col-md-4 mb-3"><label class="form-label">Confirm New Password</label><input type="password" class="form-control" name="confirm_password" required></div>
                    </div>
                    <div class="text-center mt-2"><button type="submit" name="change_password" class="btn btn-primary"><i class="fas fa-key me-2"></i> Change Password</button></div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-header"><i class="fas fa-cog me-2"></i> System Configuration</div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6 mb-3"><label class="form-label">System Version</label><input type="text" class="form-control" value="FlexiFinger v1.0" readonly></div>
                    <div class="col-md-6 mb-3"><label class="form-label">Last Updated</label><input type="text" class="form-control" value="<?php echo date('F d, Y H:i:s'); ?>" readonly></div>
                    <div class="col-md-6 mb-3"><label class="form-label">Total Users</label><input type="text" class="form-control" value="<?php echo $functions->getDashboardStats()['total_patients'] + $functions->getDashboardStats()['total_therapists']; ?>" readonly></div>
                    <div class="col-md-6 mb-3"><label class="form-label">Database Size</label><input type="text" class="form-control" value="Approx. 5.2 MB" readonly></div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>