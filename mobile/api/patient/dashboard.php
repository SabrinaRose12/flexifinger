<?php
// mobile/api/patient/dashboard.php
require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

// Get patient basic info
$stmt = $conn->prepare("
    SELECT
        p.full_name,
        COALESCE(p.streak, 0) as streak,
        COALESCE(p.compliance_rate, 0) as compliance_rate,
        COALESCE(p.pain_score, 0) as pain_score,
        p.status,
        p.daily_status,
        p.finger_condition,
        p.therapist_id,
        t.full_name as therapist_name,
        t.whatsapp as therapist_whatsapp,
        p.program_start_date,
        es.set_name as exercise_set_name
    FROM patients p
    LEFT JOIN therapists t ON p.therapist_id = t.therapist_id
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE p.patient_id = ?
");
$stmt->bind_param("i", $patientId);
$stmt->execute();
$result = $stmt->get_result();
$patient = $result->fetch_assoc();

if (!$patient) {
    jsonResponse(false, 'Patient not found');
    exit();
}

$hasFullAccess = ($patient['status'] === 'active' && $patient['therapist_id'] !== null);
$canViewExercise = ($hasFullAccess && $patient['exercise_set_name'] !== null);

// Get today's exercises
$todayExercises = [];
if ($canViewExercise) {
    $stmt2 = $conn->prepare("
        SELECT
            e.exercise_id,
            e.exercise_name,
            e.description,
            e.reps_default,
            e.sets_default,
            e.difficulty,
            e.video_path,
            e.thumbnail_path,
            COALESCE(det.status, 'Pending') as today_status
        FROM exercise_schedules sch
        JOIN set_exercises se ON sch.exercise_set_id = se.set_id
        JOIN exercises e ON se.exercise_id = e.exercise_id
        LEFT JOIN daily_exercise_tracking det ON det.patient_id = ?
            AND det.schedule_id = sch.schedule_id
            AND det.exercise_date = CURDATE()
        WHERE sch.patient_id = ? AND sch.status = 'active'
        ORDER BY se.order_in_set
    ");
    $stmt2->bind_param("ii", $patientId, $patientId);
    $stmt2->execute();
    $result2 = $stmt2->get_result();

    while ($row = $result2->fetch_assoc()) {
        $todayExercises[] = [
            'id' => (int)$row['exercise_id'],
            'title' => $row['exercise_name'],
            'subtitle' => $row['reps_default'] . ' reps x ' . $row['sets_default'] . ' sets',
            'description' => $row['description'],
            'reps' => (int)$row['reps_default'],
            'sets' => (int)$row['sets_default'],
            'difficulty' => $row['difficulty'],
            'status' => $row['today_status'] ?? 'Pending',
            'video_url' => $row['video_path'] ? BASE_URL . $row['video_path'] : null,
            'thumbnail_url' => $row['thumbnail_path'] ? BASE_URL . $row['thumbnail_path'] : null
        ];
    }
}

// Stats
$stats = [
    'today_exercises' => count($todayExercises),
    'completed_today' => 0,
    'streak' => (int)($patient['streak'] ?? 0),
    'compliance_rate' => (float)($patient['compliance_rate'] ?? 0),
    'pain_score' => (int)($patient['pain_score'] ?? 0)
];

foreach ($todayExercises as $ex) {
    if ($ex['status'] === 'completed') {
        $stats['completed_today']++;
    }
}

// Weekly compliance
$weeklyCompliance = array_fill(0, 7, 0);

$tableCheck = $conn->query("SHOW TABLES LIKE 'daily_exercise_tracking'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    $stmt3 = $conn->prepare("
        SELECT
            DAYOFWEEK(exercise_date) as day_of_week,
            CASE WHEN status = 'completed' THEN 100 ELSE 0 END as completed
        FROM daily_exercise_tracking
        WHERE patient_id = ?
        AND exercise_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ");
    $stmt3->bind_param("i", $patientId);
    $stmt3->execute();
    $result3 = $stmt3->get_result();

    while ($row = $result3->fetch_assoc()) {
        $dayIndex = ($row['day_of_week'] + 5) % 7;
        $weeklyCompliance[$dayIndex] = max($weeklyCompliance[$dayIndex], $row['completed']);
    }
}

// Recent activity
$recentActivity = [];
$stmt4 = $conn->prepare("
    SELECT
        e.exercise_name,
        det.exercise_date,
        det.status,
        det.pain_score_after,
        det.completed_at
    FROM daily_exercise_tracking det
    JOIN exercise_schedules sch ON det.schedule_id = sch.schedule_id
    JOIN set_exercises se ON sch.exercise_set_id = se.set_id AND se.order_in_set = 1
    JOIN exercises e ON se.exercise_id = e.exercise_id
    WHERE det.patient_id = ? AND det.status = 'completed'
    ORDER BY det.exercise_date DESC, det.completed_at DESC
    LIMIT 5
");
$stmt4->bind_param("i", $patientId);
$stmt4->execute();
$result4 = $stmt4->get_result();
while ($row = $result4->fetch_assoc()) {
    $recentActivity[] = $row;
}

// Tips
$tips = [
    ['title' => 'Finger Stretching Tips', 'subtitle' => 'Simple daily finger care routine', 'url' => 'https://www.youtube.com/watch?v=E7vibxI3yZY'],
    ['title' => 'Hand Exercise for Stiff Fingers', 'subtitle' => 'Easy rehab movements for beginners', 'url' => 'https://www.youtube.com/watch?v=TSrfB7JIzxY'],
    ['title' => 'Reduce Finger Pain and Tension', 'subtitle' => 'Learn basic finger pain prevention', 'url' => 'https://www.youtube.com/watch?v=8lDcjM0w0GQ']
];

$response = [
    'user' => [
        'full_name' => $patient['full_name'] ?? 'Patient',
        'finger_condition' => $patient['finger_condition'] ?? '',
        'has_full_access' => $hasFullAccess,
        'can_view_exercise' => $canViewExercise,
        'assigned_therapist' => $patient['therapist_name'] ?? null,
        'therapist_whatsapp' => $patient['therapist_whatsapp'] ?? null,
        'program_start_date' => $patient['program_start_date'] ?? null
    ],
    'stats' => $stats,
    'today_exercises' => $todayExercises,
    'weekly_compliance' => $weeklyCompliance,
    'recent_activity' => $recentActivity,
    'tips' => $tips
];

jsonResponse(true, 'Dashboard data retrieved', $response);
?>