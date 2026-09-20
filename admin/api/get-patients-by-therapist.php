<?php
require_once '../includes/config.php';
require_once '../includes/auth.php';

$auth->requireLogin();

$conn = getDBConnection();
$therapistId = $_GET['id'] ?? 0;

$result = $conn->query("
    SELECT patient_id, full_name, status, compliance_rate, pain_score, daily_status
    FROM patients 
    WHERE therapist_id = $therapistId
    ORDER BY full_name
");

$patients = [];
while ($row = $result->fetch_assoc()) {
    $patients[] = $row;
}

header('Content-Type: application/json');
echo json_encode($patients);
?>