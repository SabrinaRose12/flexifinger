<?php
require_once '../includes/config.php';
require_once '../includes/auth.php';
$auth->requireLogin();

$conn = getDBConnection();
$id = $_GET['id'] ?? 0;

$stmt = $conn->prepare("DELETE FROM patients WHERE patient_id = ?");
$stmt->bind_param("i", $id);

echo json_encode(['success' => $stmt->execute()]);
?>