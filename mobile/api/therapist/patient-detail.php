<?php
// api/therapist/patient-detail.php - Get Specific Patient Details

require_once '../auth.php';

$user = requireAuth('therapist');
$therapistId = $user['user_id'];
$conn = getDBConnection();

$patientId = $_GET['patient_id'] ?? 0;

if (!$patientId) {
    jsonResponse(false, 'Patient ID is required');
}

// Verify patient belongs to this therapist
$stmt = $conn->prepare("
    SELECT therapist_id FROM patients WHERE patient_id = ?
");
$stmt->bind_param("i", $patientId);
$stmt->execute();
$result = $stmt->get_result()->fetch_assoc();

if (!$result || $result['therapist_id'] != $therapistId) {
    jsonResponse(false, 'Patient not found or not assigned to you');
}

// Get patient details
$stmt2 = $conn->prepare("
    SELECT 
        p.patient_id, p.patient_ic, p.full_name, p.email, p.phone,
        p.finger_condition, p.pain_score, p.streak, p.compliance_rate,
        p.status, p.daily_status, p.program_start_date, p.created_at,
        es.set_id, es.set_name, es.description as set_description,
        sch.schedule_id, sch.frequency, sch.start_date, sch.end_date,
        sch.reminder_time, sch.send_reminder, sch.alert_on_missed,
        sch.total_sessions, sch.completed_sessions, sch.status as schedule_status
    FROM patients p
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE p.patient_id = ?
");
$stmt2->bind_param("i", $patientId);
$stmt2->execute();
$patient = $stmt2->get_result()->fetch_assoc();

// Get weekly compliance
$weeklyCompliance = [];
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

$weeklyData = array_fill(0, 7, 0);
while ($row = $result3->fetch_assoc()) {
    $dayIndex = ($row['day_of_week'] + 5) % 7;
    $weeklyData[$dayIndex] = max($weeklyData[$dayIndex], $row['completed']);
}

// Get exercise history
$exerciseHistory = [];
$stmt4 = $conn->prepare("
    SELECT 
        e.exercise_name,
        det.exercise_date,
        det.status,
        det.pain_score_before,
        det.pain_score_after,
        det.completed_at,
        det.notes
    FROM daily_exercise_tracking det
    JOIN exercise_schedules sch ON det.schedule_id = sch.schedule_id
    JOIN set_exercises se ON sch.exercise_set_id = se.set_id AND se.order_in_set = 1
    JOIN exercises e ON se.exercise_id = e.exercise_id
    WHERE det.patient_id = ?
    ORDER BY det.exercise_date DESC, det.completed_at DESC
    LIMIT 20
");
$stmt4->bind_param("i", $patientId);
$stmt4->execute();
$exerciseHistory = $stmt4->get_result()->fetch_all(MYSQLI_ASSOC);

// Get pain score history
$painHistory = [];
$stmt5 = $conn->prepare("
    SELECT pain_score, recorded_date, session_type
    FROM pain_score_history
    WHERE patient_id = ?
    ORDER BY recorded_date DESC
    LIMIT 30
");
$stmt5->bind_param("i", $patientId);
$stmt5->execute();
$painHistory = $stmt5->get_result()->fetch_all(MYSQLI_ASSOC);

$response = [
    'patient' => [
        'patient_id' => $patient['patient_id'],
        'patient_ic' => $patient['patient_ic'],
        'full_name' => $patient['full_name'],
        'email' => $patient['email'],
        'phone' => $patient['phone'],
        'finger_condition' => $patient['finger_condition'],
        'pain_score' => (int)$patient['pain_score'],
        'streak' => (int)$patient['streak'],
        'compliance_rate' => (float)$patient['compliance_rate'],
        'status' => $patient['status'],
        'is_active' => ($patient['status'] === 'active'),
        'daily_status' => $patient['daily_status'],
        'program_start_date' => $patient['program_start_date'],
        'created_at' => $patient['created_at']
    ],
    'schedule' => $patient['schedule_id'] ? [
        'schedule_id' => $patient['schedule_id'],
        'set_id' => $patient['set_id'],
        'set_name' => $patient['set_name'],
        'set_description' => $patient['set_description'],
        'frequency' => $patient['frequency'],
        'start_date' => $patient['start_date'],
        'end_date' => $patient['end_date'],
        'reminder_time' => $patient['reminder_time'],
        'send_reminder' => (bool)$patient['send_reminder'],
        'alert_on_missed' => (bool)$patient['alert_on_missed'],
        'total_sessions' => (int)$patient['total_sessions'],
        'completed_sessions' => (int)$patient['completed_sessions'],
        'status' => $patient['schedule_status']
    ] : null,
    'weekly_compliance' => $weeklyData,
    'exercise_history' => array_map(function($h) {
        return [
            'exercise' => $h['exercise_name'],
            'date' => $h['exercise_date'],
            'status' => $h['status'],
            'pain_before' => (int)$h['pain_score_before'],
            'pain_after' => (int)$h['pain_score_after'],
            'completed_at' => $h['completed_at'],
            'notes' => $h['notes'],
            'summary' => "{$h['exercise_name']} | Pain: {$h['pain_score_after']} | " . date('d/m/Y', strtotime($h['exercise_date']))
        ];
    }, $exerciseHistory),
    'pain_history' => $painHistory
];

jsonResponse(true, 'Patient details retrieved', $response);
?>