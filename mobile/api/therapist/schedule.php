<?php
// mobile/api/therapist/schedule.php
require_once '../auth.php';

$user = requireAuth('therapist');
$therapistId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed');
}

$input = json_decode(file_get_contents('php://input'), true);

$patientId = intval($input['patient_id'] ?? 0);
$setId = intval($input['set_id'] ?? 0);
$frequency = $input['frequency'] ?? 'Daily';
$startDate = $input['start_date'] ?? date('Y-m-d');
$endDate = $input['end_date'] ?? date('Y-m-d', strtotime('+30 days'));
$reminderTime = $input['reminder_time'] ?? '21:00:00';
$sendReminder = isset($input['send_reminder']) ? ($input['send_reminder'] ? 1 : 0) : 1;
$alertOnMissed = isset($input['alert_on_missed']) ? ($input['alert_on_missed'] ? 1 : 0) : 1;

if (!$patientId || !$setId) {
    jsonResponse(false, 'Patient ID and Set ID are required');
}

// Verify patient belongs to this therapist
$verifyStmt = $conn->prepare("SELECT patient_id FROM patients WHERE patient_id = ? AND therapist_id = ?");
$verifyStmt->bind_param("ii", $patientId, $therapistId);
$verifyStmt->execute();
if ($verifyStmt->get_result()->num_rows === 0) {
    jsonResponse(false, 'Patient not found or not assigned to you');
}

// Check if schedule exists
$checkStmt = $conn->prepare("SELECT schedule_id FROM exercise_schedules WHERE patient_id = ? AND status = 'active'");
$checkStmt->bind_param("i", $patientId);
$checkStmt->execute();
$checkResult = $checkStmt->get_result();

if ($checkResult->num_rows > 0) {
    $existing = $checkResult->fetch_assoc();
    $scheduleId = $existing['schedule_id'];

    $updateStmt = $conn->prepare("
        UPDATE exercise_schedules SET
            exercise_set_id = ?,
            frequency = ?,
            start_date = ?,
            end_date = ?,
            reminder_time = ?,
            send_reminder = ?,
            alert_on_missed = ?,
            status = 'active'
        WHERE schedule_id = ?
    ");
    $updateStmt->bind_param("issssiii", $setId, $frequency, $startDate, $endDate, $reminderTime, $sendReminder, $alertOnMissed, $scheduleId);

    if ($updateStmt->execute()) {
        jsonResponse(true, 'Exercise schedule updated successfully', ['schedule_id' => $scheduleId]);
    } else {
        jsonResponse(false, 'Failed to update schedule: ' . $conn->error);
    }
} else {
    $insertStmt = $conn->prepare("
        INSERT INTO exercise_schedules (
            patient_id, exercise_set_id, therapist_id, frequency,
            start_date, end_date, reminder_time, send_reminder,
            alert_on_missed, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
    ");
    $insertStmt->bind_param("iiissssii", $patientId, $setId, $therapistId, $frequency, $startDate, $endDate, $reminderTime, $sendReminder, $alertOnMissed);

    if ($insertStmt->execute()) {
        $scheduleId = $conn->insert_id;

        // Update patient program_start_date
        $updatePatientStmt = $conn->prepare("UPDATE patients SET program_start_date = ? WHERE patient_id = ?");
        $updatePatientStmt->bind_param("si", $startDate, $patientId);
        $updatePatientStmt->execute();

        jsonResponse(true, 'Exercise scheduled successfully', ['schedule_id' => $scheduleId]);
    } else {
        jsonResponse(false, 'Failed to create schedule: ' . $conn->error);
    }
}
?>