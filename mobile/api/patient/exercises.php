<?php
// api/patient/exercises.php - Get Assigned Exercises

require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

// Check if patient can view exercises
$stmt = $conn->prepare("
    SELECT p.status, p.therapist_id, sch.exercise_set_id
    FROM patients p
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    WHERE p.patient_id = ?
");
$stmt->bind_param("i", $patientId);
$stmt->execute();
$patient = $stmt->get_result()->fetch_assoc();

$hasFullAccess = ($patient['status'] === 'active' && $patient['therapist_id'] !== null);
$canViewExercise = ($hasFullAccess && $patient['exercise_set_id'] !== null);

if (!$canViewExercise) {
    jsonResponse(true, 'No exercises assigned yet', [
        'can_view' => false,
        'has_full_access' => $hasFullAccess,
        'exercises' => []
    ]);
}

// Get all exercises in the assigned set
$stmt2 = $conn->prepare("
    SELECT 
        e.exercise_id,
        e.exercise_name,
        e.description,
        e.instructions,
        e.reps_default,
        e.sets_default,
        e.hold_duration_sec,
        e.difficulty,
        e.video_path,
        e.thumbnail_path,
        se.order_in_set,
        det.status as today_status,
        det.completed_at
    FROM exercise_schedules sch
    JOIN set_exercises se ON sch.exercise_set_id = se.set_id
    JOIN exercises e ON se.exercise_id = e.exercise_id
    LEFT JOIN daily_exercise_tracking det ON det.patient_id = sch.patient_id 
        AND det.exercise_date = CURDATE()
        AND det.schedule_id = sch.schedule_id
    WHERE sch.patient_id = ? AND sch.status = 'active'
    ORDER BY se.order_in_set
");
$stmt2->bind_param("i", $patientId);
$stmt2->execute();
$exercises = $stmt2->get_result()->fetch_all(MYSQLI_ASSOC);

// Parse instructions into steps
$formattedExercises = array_map(function($ex) {
    $steps = $ex['instructions'] ? explode("\n", trim($ex['instructions'])) : [];
    $steps = array_filter($steps, fn($s) => !empty(trim($s)));
    $steps = array_map('trim', $steps);
    
    return [
        'id' => $ex['exercise_id'],
        'name' => $ex['exercise_name'],
        'description' => $ex['description'],
        'steps' => $steps,
        'reps' => (int)$ex['reps_default'],
        'sets' => (int)$ex['sets_default'],
        'hold_duration_sec' => (int)$ex['hold_duration_sec'],
        'difficulty' => $ex['difficulty'],
        'order' => (int)$ex['order_in_set'],
        'video_url' => $ex['video_path'] ? BASE_URL . $ex['video_path'] : null,
        'thumbnail_url' => $ex['thumbnail_path'] ? BASE_URL . $ex['thumbnail_path'] : null,
        'today_status' => $ex['today_status'] ?? 'pending',
        'completed_at' => $ex['completed_at']
    ];
}, $exercises);

// Get schedule info
$stmt3 = $conn->prepare("
    SELECT 
        es.set_name,
        es.description as set_description,
        sch.frequency,
        sch.start_date,
        sch.end_date,
        sch.reminder_time,
        sch.total_sessions,
        sch.completed_sessions
    FROM exercise_schedules sch
    JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE sch.patient_id = ? AND sch.status = 'active'
");
$stmt3->bind_param("i", $patientId);
$stmt3->execute();
$schedule = $stmt3->get_result()->fetch_assoc();

$response = [
    'can_view' => true,
    'has_full_access' => $hasFullAccess,
    'schedule' => $schedule ? [
        'set_name' => $schedule['set_name'],
        'description' => $schedule['set_description'],
        'frequency' => $schedule['frequency'],
        'start_date' => $schedule['start_date'],
        'end_date' => $schedule['end_date'],
        'reminder_time' => $schedule['reminder_time'],
        'progress' => [
            'total' => (int)$schedule['total_sessions'],
            'completed' => (int)$schedule['completed_sessions']
        ]
    ] : null,
    'exercises' => $formattedExercises
];

jsonResponse(true, 'Exercises retrieved', $response);
?>