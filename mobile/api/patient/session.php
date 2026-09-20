<?php
// mobile/api/patient/session.php
require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? '';

    if ($action === 'start') {
        $exerciseId = $input['exercise_id'] ?? 0;

        // Get active schedule
        $stmt = $conn->prepare("
            SELECT sch.schedule_id, sch.exercise_set_id
            FROM exercise_schedules sch
            WHERE sch.patient_id = ? AND sch.status = 'active'
            LIMIT 1
        ");
        $stmt->bind_param("i", $patientId);
        $stmt->execute();
        $schedule = $stmt->get_result()->fetch_assoc();

        if (!$schedule) {
            jsonResponse(false, 'No active exercise schedule found');
        }

        // Get pain before (from patient current pain score)
        $painStmt = $conn->prepare("SELECT pain_score FROM patients WHERE patient_id = ?");
        $painStmt->bind_param("i", $patientId);
        $painStmt->execute();
        $painBefore = $painStmt->get_result()->fetch_assoc()['pain_score'] ?? 0;

        jsonResponse(true, 'Session started', [
            'schedule_id' => $schedule['schedule_id'],
            'pain_before' => $painBefore
        ]);

    } elseif ($action === 'complete') {
        $scheduleId = $input['schedule_id'] ?? 0;
        $painAfter = $input['pain_score_after'] ?? 0;
        $notes = $input['notes'] ?? '';
        $exerciseId = $input['exercise_id'] ?? 0;

        if (!$scheduleId) {
            // Try to get active schedule
            $schStmt = $conn->prepare("
                SELECT schedule_id FROM exercise_schedules
                WHERE patient_id = ? AND status = 'active'
                LIMIT 1
            ");
            $schStmt->bind_param("i", $patientId);
            $schStmt->execute();
            $schResult = $schStmt->get_result()->fetch_assoc();
            $scheduleId = $schResult['schedule_id'] ?? 0;
        }

        if (!$scheduleId) {
            jsonResponse(false, 'No active schedule found');
        }

        // 🔴 Insert tracking for SPECIFIC exercise
        $trackStmt = $conn->prepare("
            INSERT INTO daily_exercise_tracking
                (patient_id, schedule_id, exercise_id, exercise_date, status, pain_score_after, notes, completed_at)
            VALUES (?, ?, ?, CURDATE(), 'completed', ?, ?, NOW())
        ");
        $trackStmt->bind_param("iiiis", $patientId, $scheduleId, $exerciseId, $painAfter, $notes);

        if (!$trackStmt->execute()) {
            jsonResponse(false, 'Failed to save: ' . $conn->error);
        }

        // Update patient pain score
        $conn->query("UPDATE patients SET pain_score = $painAfter WHERE patient_id = $patientId");

        // Update streak (simplified - tambah 1)
        $conn->query("UPDATE patients SET streak = streak + 1 WHERE patient_id = $patientId");

        // Get updated streak
        $streakResult = $conn->query("SELECT streak FROM patients WHERE patient_id = $patientId");
        $streak = $streakResult->fetch_assoc()['streak'];

        jsonResponse(true, 'Session completed', [
            'summary' => 'Exercise completed on ' . date('d/m/Y'),
            'streak' => (int)$streak,
            'pain_score' => $painAfter
        ]);
    } else {
        jsonResponse(false, 'Invalid action');
    }
} else {
    jsonResponse(false, 'Method not allowed');
}
?>