<?php
// api/therapist/assign-exercise.php - Assign Exercise to Patient

require_once '../auth.php';

$user = requireAuth('therapist');
$therapistId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get available exercise sets
    $condition = $_GET['condition'] ?? '';
    
    $query = "
        SELECT 
            es.set_id, es.set_name, es.condition_target, es.description,
            COUNT(se.exercise_id) as exercise_count
        FROM exercise_sets es
        LEFT JOIN set_exercises se ON es.set_id = se.set_id
    ";
    
    if (!empty($condition)) {
        $query .= " WHERE es.condition_target LIKE ?";
        $stmt = $conn->prepare($query . " GROUP BY es.set_id ORDER BY es.set_name");
        $searchTerm = "%$condition%";
        $stmt->bind_param("s", $searchTerm);
    } else {
        $stmt = $conn->prepare($query . " GROUP BY es.set_id ORDER BY es.set_name");
    }
    
    $stmt->execute();
    $sets = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    
    jsonResponse(true, 'Exercise sets retrieved', [
        'sets' => $sets
    ]);
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Assign exercise set to patient
    $input = json_decode(file_get_contents('php://input'), true);
    
    $patientId = $input['patient_id'] ?? 0;
    $setId = $input['set_id'] ?? 0;
    
    if (!$patientId || !$setId) {
        jsonResponse(false, 'Patient ID and Set ID are required');
    }
    
    // Verify patient belongs to this therapist
    $stmt = $conn->prepare("
        SELECT patient_id, full_name FROM patients WHERE patient_id = ? AND therapist_id = ?
    ");
    $stmt->bind_param("ii", $patientId, $therapistId);
    $stmt->execute();
    $patient = $stmt->get_result()->fetch_assoc();
    
    if (!$patient) {
        jsonResponse(false, 'Patient not found or not assigned to you');
    }
    
    // Check if patient already has active schedule
    $stmt2 = $conn->prepare("
        SELECT schedule_id FROM exercise_schedules 
        WHERE patient_id = ? AND status = 'active'
    ");
    $stmt2->bind_param("i", $patientId);
    $stmt2->execute();
    $existing = $stmt2->get_result()->fetch_assoc();
    
    if ($existing) {
        jsonResponse(false, 'Patient already has an active exercise schedule');
    }
    
    // Create assignment record (schedule will be created later)
    $stmt3 = $conn->prepare("
        INSERT INTO patient_exercises (patient_id, set_id, therapist_id, assigned_date)
        VALUES (?, ?, ?, NOW())
    ");
    $stmt3->bind_param("iii", $patientId, $setId, $therapistId);
    $stmt3->execute();
    
    $assignmentId = $conn->insert_id;
    
    // Create notification for patient
    $stmt4 = $conn->prepare("
        INSERT INTO notifications (user_type, user_id, title, message, type)
        VALUES ('patient', ?, 'Exercise Assigned', 'Your therapist has assigned you a new exercise set.', 'info')
    ");
    $stmt4->bind_param("i", $patientId);
    $stmt4->execute();
    
    jsonResponse(true, 'Exercise set assigned successfully', [
        'assignment_id' => $assignmentId
    ]);
    
} else {
    jsonResponse(false, 'Method not allowed');
}
?>