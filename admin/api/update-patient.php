<?php
require_once '../includes/config.php';
require_once '../includes/auth.php';
$auth->requireLogin();

$conn = getDBConnection();
$input = json_decode(file_get_contents('php://input'), true);

$stmt = $conn->prepare("UPDATE patients SET full_name=?, email=?, phone=?, status=? WHERE patient_id=?");
$stmt->bind_param("ssssi", $input['full_name'], $input['email'], $input['phone'], $input['status'], $input['patient_id']);

echo json_encode(['success' => $stmt->execute()]);
?>