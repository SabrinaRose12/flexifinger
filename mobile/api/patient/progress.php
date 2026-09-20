<?php
// mobile/api/patient/progress.php
require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

// Get patient stats
$stmt = $conn->prepare("
    SELECT
        p.streak,
        COALESCE(p.compliance_rate, 0) as compliance_rate,
        COALESCE(p.pain_score, 0) as pain_score,
        p.status,
        p.daily_status,
        (SELECT COUNT(*) FROM daily_exercise_tracking WHERE patient_id = ? AND status = 'completed') as total_completed,
        (SELECT COUNT(*) FROM daily_exercise_tracking WHERE patient_id = ? AND exercise_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)) as total_scheduled_30d,
        (SELECT COUNT(*) FROM daily_exercise_tracking WHERE patient_id = ? AND status = 'completed' AND exercise_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)) as completed_30d
    FROM patients p
    WHERE p.patient_id = ?
");
$stmt->bind_param("iiii", $patientId, $patientId, $patientId, $patientId);
$stmt->execute();
$stats = $stmt->get_result()->fetch_assoc();

// Get weekly overview (last 7 days)
$weeklyCompletion = [];
$stmt2 = $conn->prepare("
    SELECT
        DAYNAME(exercise_date) as day_name,
        CASE WHEN status = 'completed' THEN 100 ELSE 0 END as completed
    FROM daily_exercise_tracking
    WHERE patient_id = ?
    AND exercise_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ORDER BY exercise_date
");
$stmt2->bind_param("i", $patientId);
$stmt2->execute();
$result2 = $stmt2->get_result();

while ($row = $result2->fetch_assoc()) {
    $dayShort = substr($row['day_name'], 0, 3);
    $weeklyCompletion[$dayShort] = [
        'completed' => (int)$row['completed']
    ];
}

// Get recent logs
$recentLogs = [];
$stmt3 = $conn->prepare("
    SELECT
        e.exercise_name as exercise,
        CONCAT(
            DATE_FORMAT(det.exercise_date, '%M %d'),
            ', ',
            DATE_FORMAT(det.completed_at, '%l:%i %p')
        ) as date,
        det.status,
        det.pain_score_after as pain_score
    FROM daily_exercise_tracking det
    JOIN exercise_schedules sch ON det.schedule_id = sch.schedule_id
    JOIN set_exercises se ON sch.exercise_set_id = se.set_id AND se.order_in_set = 1
    JOIN exercises e ON se.exercise_id = e.exercise_id
    WHERE det.patient_id = ? AND det.status = 'completed'
    ORDER BY det.exercise_date DESC, det.completed_at DESC
    LIMIT 5
");
$stmt3->bind_param("i", $patientId);
$stmt3->execute();
$recentLogs = $stmt3->get_result()->fetch_all(MYSQLI_ASSOC);

jsonResponse(true, 'Progress data retrieved', [
    'stats' => [
        'streak' => (int)$stats['streak'],
        'compliance_rate' => (float)$stats['compliance_rate'],
        'current_pain_score' => (int)$stats['pain_score'],
        'total_completed' => (int)$stats['total_completed'],
        'completed_30d' => (int)$stats['completed_30d'],
        'total_scheduled_30d' => (int)$stats['total_scheduled_30d']
    ],
    'weekly_completion' => $weeklyCompletion,
    'recent_logs' => $recentLogs,
    'insights' => [
        ['title' => 'Keep Going!', 'description' => 'Every session brings you closer to recovery.']
    ]
]);
?>