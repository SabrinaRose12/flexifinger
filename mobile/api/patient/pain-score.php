<?php
// api/patient/pain-score.php - Update Pain Score

require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $painScore = $input['pain_score'] ?? 0;
    $notes = $input['notes'] ?? '';
    $sessionType = $input['session_type'] ?? 'daily-check';
    
    if ($painScore < 1 || $painScore > 10) {
        jsonResponse(false, 'Pain score must be between 1 and 10');
    }
    
    // Update patient current pain score
    $stmt = $conn->prepare("
        UPDATE patients SET pain_score = ? WHERE patient_id = ?
    ");
    $stmt->bind_param("ii", $painScore, $patientId);
    $stmt->execute();
    
    // Add to pain score history
    $stmt2 = $conn->prepare("
        INSERT INTO pain_score_history (patient_id, pain_score, recorded_date, recorded_time, notes, session_type)
        VALUES (?, ?, CURDATE(), CURTIME(), ?, ?)
    ");
    $stmt2->bind_param("iiss", $patientId, $painScore, $notes, $sessionType);
    $stmt2->execute();
    
    jsonResponse(true, 'Pain score updated', [
        'pain_score' => $painScore,
        'recorded_at' => date('Y-m-d H:i:s')
    ]);
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get pain score history
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 30;
    
    $stmt = $conn->prepare("
        SELECT pain_score, recorded_date, recorded_time, notes, session_type
        FROM pain_score_history
        WHERE patient_id = ?
        ORDER BY recorded_date DESC, recorded_time DESC
        LIMIT ?
    ");
    $stmt->bind_param("ii", $patientId, $limit);
    $stmt->execute();
    $history = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    
    // Get current pain score
    $stmt2 = $conn->prepare("SELECT pain_score FROM patients WHERE patient_id = ?");
    $stmt2->bind_param("i", $patientId);
    $stmt2->execute();
    $current = $stmt2->get_result()->fetch_assoc();
    
    jsonResponse(true, 'Pain score history retrieved', [
        'current' => (int)$current['pain_score'],
        'history' => $history
    ]);
    
} else {
    jsonResponse(false, 'Method not allowed');
}
?>