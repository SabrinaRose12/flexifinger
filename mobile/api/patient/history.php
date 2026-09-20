<?php
// api/patient/history.php - Get Exercise History

require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$offset = ($page - 1) * $limit;

// Get total count
$stmt = $conn->prepare("
    SELECT COUNT(*) as total
    FROM daily_exercise_tracking det
    WHERE det.patient_id = ? AND det.status = 'completed'
");
$stmt->bind_param("i", $patientId);
$stmt->execute();
$total = $stmt->get_result()->fetch_assoc()['total'];

// Get history with pagination
$stmt2 = $conn->prepare("
    SELECT 
        det.tracking_id,
        det.exercise_date,
        det.completed_at,
        det.pain_score_before,
        det.pain_score_after,
        det.notes,
        e.exercise_name,
        e.reps_default,
        e.sets_default,
        es.set_name
    FROM daily_exercise_tracking det
    JOIN exercise_schedules sch ON det.schedule_id = sch.schedule_id
    JOIN set_exercises se ON sch.exercise_set_id = se.set_id AND se.order_in_set = 1
    JOIN exercises e ON se.exercise_id = e.exercise_id
    JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE det.patient_id = ? AND det.status = 'completed'
    ORDER BY det.exercise_date DESC, det.completed_at DESC
    LIMIT ? OFFSET ?
");
$stmt2->bind_param("iii", $patientId, $limit, $offset);
$stmt2->execute();
$history = $stmt2->get_result()->fetch_all(MYSQLI_ASSOC);

$formattedHistory = array_map(function($item) {
    return [
        'id' => $item['tracking_id'],
        'date' => $item['exercise_date'],
        'completed_at' => $item['completed_at'],
        'exercise_name' => $item['exercise_name'],
        'set_name' => $item['set_name'],
        'reps' => (int)$item['reps_default'],
        'sets' => (int)$item['sets_default'],
        'pain_before' => (int)$item['pain_score_before'],
        'pain_after' => (int)$item['pain_score_after'],
        'pain_reduction' => (int)$item['pain_score_before'] - (int)$item['pain_score_after'],
        'notes' => $item['notes'],
        'summary' => "{$item['exercise_name']} | {$item['reps_default']} reps x {$item['sets_default']} sets | Pain: {$item['pain_score_after']} | " . date('d/m/Y', strtotime($item['exercise_date']))
    ];
}, $history);

$response = [
    'total' => (int)$total,
    'page' => $page,
    'limit' => $limit,
    'total_pages' => ceil($total / $limit),
    'history' => $formattedHistory
];

jsonResponse(true, 'History retrieved', $response);
?>