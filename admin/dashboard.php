<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

$auth->requireLogin();

$stats = $functions->getDashboardStats();
$activities = $functions->getSystemActivity();
$recentValidations = $functions->getRecentValidations(5);

$activityLabels = [];
$activityData = [];
for ($i = 14; $i >= 0; $i--) {
    $date = date('Y-m-d', strtotime("-$i days"));
    $activityLabels[] = date('d M', strtotime($date));
    $activityData[] = $activities[$date] ?? 0;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/admin.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        <a href="dashboard.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'dashboard.php' ? 'active' : ''; ?>"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
        <a href="approval.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'approval.php' ? 'active' : ''; ?>"><i class="fas fa-user-check"></i> Approval</a>
        <a href="patient-management.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'patient-management.php' ? 'active' : ''; ?>"><i class="fas fa-users"></i> Patient Management</a>
        <a href="therapist-management.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'therapist-management.php' ? 'active' : ''; ?>"><i class="fas fa-user-md"></i> Therapist Management</a>
        <a href="exercise-management.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'exercise-management.php' ? 'active' : ''; ?>"><i class="fas fa-dumbbell"></i> Exercise Management</a>
        <a href="reporting.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'reporting.php' ? 'active' : ''; ?>"><i class="fas fa-chart-bar"></i> Reports</a>
        <a href="profile.php" class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'profile.php' ? 'active' : ''; ?>"><i class="fas fa-user-cog"></i> Settings</a>
        <a href="logout.php" class="nav-link mt-4" onclick="return confirmLogout();"><i class="fas fa-sign-out-alt"></i> Logout</a>
    </nav>
</div>
    <div class="main-content">
        <div class="navbar-top">
            <div class="welcome-text">
                <h4>Welcome back, <?php echo htmlspecialchars($_SESSION['admin_name']); ?>!</h4>
                <p><?php echo date('l, F j, Y'); ?></p>
            </div>
            <div class="admin-badge"><i class="fas fa-user-shield"></i> Administrator</div>
        </div>

        <div class="stats-grid">
            <div class="stat-card pending">
                <div class="stat-icon"><i class="fas fa-clock"></i></div>
                <div class="stat-number"><?php echo $stats['pending_patients']; ?></div>
                <div class="stat-label">Pending Patients</div>
            </div>
            <div class="stat-card pending">
                <div class="stat-icon"><i class="fas fa-user-clock"></i></div>
                <div class="stat-number"><?php echo $stats['pending_therapists']; ?></div>
                <div class="stat-label">Pending Therapists</div>
            </div>
            <div class="stat-card patients">
                <div class="stat-icon"><i class="fas fa-users"></i></div>
                <div class="stat-number"><?php echo $stats['total_patients']; ?></div>
                <div class="stat-label">Total Patients</div>
            </div>
            <div class="stat-card therapists">
                <div class="stat-icon"><i class="fas fa-user-md"></i></div>
                <div class="stat-number"><?php echo $stats['total_therapists']; ?></div>
                <div class="stat-label">Active Therapists</div>
            </div>
            <div class="stat-card active">
                <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
                <div class="stat-number"><?php echo $stats['active_patients']; ?></div>
                <div class="stat-label">Active Patients</div>
            </div>
            <div class="stat-card inactive">
                <div class="stat-icon"><i class="fas fa-user-slash"></i></div>
                <div class="stat-number"><?php echo $stats['inactive_patients']; ?></div>
                <div class="stat-label">Inactive</div>
            </div>
        </div>

        <div class="row">
            <div class="col-lg-8">
                <div class="chart-container">
                    <div class="chart-title"><i class="fas fa-chart-line"></i> System Activity - Last 15 Days</div>
                    <canvas id="activityChart" style="height: 250px;"></canvas>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="chart-container">
                    <div class="chart-title"><i class="fas fa-history"></i> Recent Validations</div>
                    <ul class="activity-list" style="list-style: none; padding: 0;">
                        <?php if (empty($recentValidations)): ?>
                            <li class="activity-item" style="display: flex; align-items: center; gap: 12px; padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
                                <div class="activity-icon" style="width: 36px; height: 36px; background: #f1f5f9; border-radius: 10px; display: flex; align-items: center; justify-content: center;"><i class="fas fa-info-circle"></i></div>
                                <div class="activity-detail"><div class="activity-title">No recent validations</div><div class="activity-time">No data available</div></div>
                            </li>
                        <?php else: ?>
                            <?php foreach ($recentValidations as $validation): ?>
                            <li class="activity-item" style="display: flex; align-items: center; gap: 12px; padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
                                <div class="activity-icon" style="width: 36px; height: 36px; background: #f1f5f9; border-radius: 10px; display: flex; align-items: center; justify-content: center;"><i class="fas fa-<?php echo $validation['type'] === 'Patient' ? 'user' : 'user-md'; ?>"></i></div>
                                <div class="activity-detail">
                                    <div class="activity-title"><?php echo htmlspecialchars($validation['full_name']); ?></div>
                                    <div class="activity-time"><?php echo $validation['type']; ?> validated on <?php echo date('M d, Y', strtotime($validation['validated_at'])); ?></div>
                                </div>
                            </li>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </ul>
                </div>
            </div>
        </div>

        <div class="chart-container">
            <div class="chart-title"><i class="fas fa-bolt"></i> Quick Actions</div>
            <div class="row g-3">
                <div class="col-md-3 col-6"><a href="approval.php" class="btn btn-outline-warning d-block text-center py-3"><i class="fas fa-user-check fa-lg mb-2 d-block"></i> Approve Users</a></div>
                <div class="col-md-3 col-6"><a href="patient-management.php" class="btn btn-outline-primary d-block text-center py-3"><i class="fas fa-users fa-lg mb-2 d-block"></i> Manage Patients</a></div>
                <div class="col-md-3 col-6"><a href="therapist-management.php" class="btn btn-outline-success d-block text-center py-3"><i class="fas fa-user-md fa-lg mb-2 d-block"></i> Manage Therapists</a></div>
                <div class="col-md-3 col-6"><a href="exercise-management.php" class="btn btn-outline-info d-block text-center py-3"><i class="fas fa-dumbbell fa-lg mb-2 d-block"></i> Manage Exercises</a></div>
            </div>
        </div>
    </div>

    <script>
        const ctx = document.getElementById('activityChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: <?php echo json_encode($activityLabels); ?>,
                datasets: [{
                    label: 'Activities',
                    data: <?php echo json_encode($activityData); ?>,
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102,126,234,0.05)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.3,
                    pointRadius: 4,
                    pointBackgroundColor: '#667eea',
                    pointBorderColor: 'white',
                    pointBorderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: { legend: { display: false }, tooltip: { backgroundColor: '#1e293b' } },
                scales: { y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: '#e2e8f0' } }, x: { grid: { display: false } } }
            }
        });
        
        function confirmLogout() {
            return confirm('Are you sure you want to logout?');
        }
    </script>
</body>
</html>