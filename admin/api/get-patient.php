<?php
require_once '../includes/config.php';
require_once '../includes/auth.php';
$auth->requireLogin();

$conn = getDBConnection();
$id = $_GET['id'] ?? 0;

$stmt = $conn->prepare("SELECT * FROM patients WHERE patient_id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$patient = $stmt->get_result()->fetch_assoc();

echo json_encode(['success' => true, 'data' => $patient]);
?>