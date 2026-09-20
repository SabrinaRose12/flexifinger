<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

$auth->requireLogin();

$functions = new Functions();

$stats = $functions->getDashboardStats();
$registrationTrends = $functions->getRegistrationTrends();
$patientConditions = $functions->getPatientConditions();
$patientStatus = $functions->getPatientStatusStats();
$topTherapists = $functions->getTopTherapists();
$weeklyCompliance = $functions->getWeeklyCompliance();
$exerciseUsage = $functions->getExerciseUsage();
$difficultyDist = $functions->getDifficultyDistribution();
$topPatients = $functions->getTopPatients();

$conn = getDBConnection();
$avgCompliance = $stats['active_patients'] > 0 ? round($conn->query("SELECT AVG(compliance_rate) as avg FROM patients WHERE status = 'active'")->fetch_assoc()['avg'], 1) : 0;
$avgPain = $conn->query("SELECT AVG(pain_score) as avg FROM patients")->fetch_assoc()['avg'] ?? 0;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporting & Analytics - FlexiFinger Admin</title>
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
            <a href="dashboard.php" class="nav-link"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="approval.php" class="nav-link"><i class="fas fa-user-check"></i> Approval</a>
            <a href="patient-management.php" class="nav-link"><i class="fas fa-users"></i> Patient Management</a>
            <a href="therapist-management.php" class="nav-link"><i class="fas fa-user-md"></i> Therapist Management</a>
            <a href="exercise-management.php" class="nav-link"><i class="fas fa-dumbbell"></i> Exercise Management</a>
            <a href="reporting.php" class="nav-link active"><i class="fas fa-chart-bar"></i> Reports</a>
            <a href="profile.php" class="nav-link"><i class="fas fa-user-cog"></i> Settings</a>
            <a href="logout.php" class="nav-link mt-4"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </nav>
    </div>

    <div class="main-content">
        <div class="navbar-top d-flex justify-content-between align-items-center">
            <div><h4>Reporting & Analytics</h4><p>Real-time insights from your data</p></div>
            <div class="admin-badge"><i class="fas fa-chart-line"></i> Live Data</div>
        </div>

        <div class="row g-3 mb-4">
            <div class="col-md-3"><div class="stat-card" style="border-left-color:#667eea"><div class="stat-number"><?php echo $stats['total_patients']; ?></div><div class="stat-label">Total Patients</div><small class="text-success"><?php echo $stats['active_patients']; ?> active</small></div></div>
            <div class="col-md-3"><div class="stat-card" style="border-left-color:#10b981"><div class="stat-number"><?php echo $stats['total_therapists']; ?></div><div class="stat-label">Active Therapists</div><small><?php echo $stats['pending_therapists']; ?> pending</small></div></div>
            <div class="col-md-3"><div class="stat-card" style="border-left-color:#f59e0b"><div class="stat-number"><?php echo $avgCompliance; ?>%</div><div class="stat-label">Avg Compliance</div><small>Across all active patients</small></div></div>
            <div class="col-md-3"><div class="stat-card" style="border-left-color:#ef4444"><div class="stat-number"><?php echo round($avgPain, 1); ?>/10</div><div class="stat-label">Avg Pain Score</div><small><?php echo $stats['active_patients']; ?> reporting</small></div></div>
        </div>

        <div class="row">
            <div class="col-md-8"><div class="chart-container"><div class="chart-title"><i class="fas fa-chart-line"></i> Registration Trends (Last 6 Months)</div><canvas id="registrationChart" style="height: 200px;"></canvas></div></div>
            <div class="col-md-4"><div class="chart-container"><div class="chart-title"><i class="fas fa-chart-pie"></i> Patient Status</div><canvas id="patientStatusChart" style="height: 200px;"></canvas></div></div>
        </div>

        <div class="row">
            <div class="col-md-7"><div class="chart-container"><div class="chart-title"><i class="fas fa-chart-bar"></i> Top Patient Conditions</div><canvas id="conditionsChart" style="height: 200px;"></canvas></div></div>
            <div class="col-md-5"><div class="chart-container"><div class="chart-title"><i class="fas fa-trophy"></i> Top Therapists by Patient Load</div>
                <div class="table-responsive"><table class="table table-sm"><thead><tr><th>Therapist</th><th>Patients</th><th>Compliance</th></tr></thead><tbody>
                <?php foreach ($topTherapists as $t): ?><tr><td><?php echo htmlspecialchars($t['full_name']); ?></td><td><?php echo $t['patient_count']; ?></td><td><?php echo round($t['avg_compliance'], 1); ?>%</td></tr><?php endforeach; ?>
                <?php if(empty($topTherapists)): ?><tr><td colspan="3" class="text-center">No data</td></tr><?php endif; ?>
                </tbody></table></div>
            </div></div>
        </div>

        <div class="row">
            <div class="col-md-6"><div class="chart-container"><div class="chart-title"><i class="fas fa-calendar-week"></i> Weekly Compliance Trends</div><canvas id="complianceTrendChart" style="height: 200px;"></canvas></div></div>
            <div class="col-md-6"><div class="chart-container"><div class="chart-title"><i class="fas fa-dumbbell"></i> Most Used Exercises</div><canvas id="exerciseUsageChart" style="height: 200px;"></canvas></div></div>
        </div>

        <div class="row">
            <div class="col-md-4"><div class="chart-container"><div class="chart-title"><i class="fas fa-chart-donut"></i> Exercise Difficulty</div><canvas id="difficultyChart" style="height: 200px;"></canvas></div></div>
            <div class="col-md-8"><div class="chart-container"><div class="chart-title"><i class="fas fa-medal"></i> Top Performing Patients</div>
                <div class="table-responsive"><table class="table table-sm"><thead><tr><th>Patient</th><th>Condition</th><th>Therapist</th><th>Compliance</th><th>Streak</th></tr></thead><tbody>
                <?php foreach ($topPatients as $p): ?><tr><td><?php echo htmlspecialchars($p['full_name']); ?></td><td><small><?php echo htmlspecialchars(substr($p['finger_condition'] ?? '-', 0, 20)); ?></small></td><td><?php echo htmlspecialchars($p['therapist_name'] ?? '-'); ?></td><td><span class="badge-success"><?php echo round($p['compliance_rate'], 1); ?>%</span></td><td><?php echo $p['streak']; ?> days</td></tr><?php endforeach; ?>
                <?php if(empty($topPatients)): ?><tr><td colspan="5" class="text-center">No data</td></tr><?php endif; ?>
                </tbody></table></div>
            </div></div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        const colors = { primary: '#667eea', secondary: '#764ba2', success: '#10b981', warning: '#f59e0b', danger: '#ef4444' };
        new Chart(document.getElementById('registrationChart'), { type: 'line', data: { labels: <?php echo json_encode($registrationTrends['labels']); ?>, datasets: [{ label: 'Patients', data: <?php echo json_encode($registrationTrends['patients']); ?>, borderColor: colors.primary, backgroundColor: colors.primary+'20', fill: true, tension: 0.3 }, { label: 'Therapists', data: <?php echo json_encode($registrationTrends['therapists']); ?>, borderColor: colors.success, backgroundColor: colors.success+'20', fill: true, tension: 0.3 }] }, options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'top', labels: { boxWidth: 10, font: { size: 10 } } } }, scales: { y: { beginAtZero: true } } } });
        new Chart(document.getElementById('patientStatusChart'), { type: 'doughnut', data: { labels: ['Active', 'Pending', 'Inactive'], datasets: [{ data: [<?php echo $patientStatus['active']; ?>, <?php echo $patientStatus['pending']; ?>, <?php echo $patientStatus['inactive']; ?>], backgroundColor: [colors.success, colors.warning, colors.danger] }] }, options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 } } } } } });
        new Chart(document.getElementById('conditionsChart'), { type: 'bar', data: { labels: <?php echo json_encode(array_column($patientConditions, 'condition')); ?>, datasets: [{ data: <?php echo json_encode(array_column($patientConditions, 'count')); ?>, backgroundColor: <?php echo json_encode(array_column($patientConditions, 'color')); ?>, borderRadius: 6 }] }, options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } } });
        new Chart(document.getElementById('complianceTrendChart'), { type: 'line', data: { labels: <?php echo json_encode($weeklyCompliance['labels']); ?>, datasets: [{ label: 'Compliance Rate (%)', data: <?php echo json_encode($weeklyCompliance['data']); ?>, borderColor: colors.warning, backgroundColor: colors.warning+'20', fill: true, tension: 0.3 }] }, options: { responsive: true, maintainAspectRatio: true, scales: { y: { beginAtZero: true, max: 100 } } } });
        new Chart(document.getElementById('exerciseUsageChart'), { type: 'bar', data: { labels: <?php echo json_encode($exerciseUsage['labels']); ?>, datasets: [{ data: <?php echo json_encode($exerciseUsage['data']); ?>, backgroundColor: colors.primary, borderRadius: 6 }] }, options: { indexAxis: 'y', responsive: true, maintainAspectRatio: true, plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true } } } });
        new Chart(document.getElementById('difficultyChart'), { type: 'doughnut', data: { labels: ['Beginner', 'Intermediate', 'Advanced'], datasets: [{ data: [<?php echo $difficultyDist['beginner']; ?>, <?php echo $difficultyDist['intermediate']; ?>, <?php echo $difficultyDist['advanced']; ?>], backgroundColor: [colors.success, colors.warning, colors.danger] }] }, options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 } } } } } });
    </script>
</body>
</html>