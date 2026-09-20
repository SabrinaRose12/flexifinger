<?php
// mobile/api/test-schedule.php
require_once 'config.php';

echo json_encode([
    'success' => true,
    'message' => 'Schedule API is accessible',
    'method' => $_SERVER['REQUEST_METHOD'],
    'input' => json_decode(file_get_contents('php://input'), true)
]);
?>