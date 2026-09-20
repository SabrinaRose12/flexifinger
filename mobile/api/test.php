<?php
// mobile/api/test.php
require_once 'config.php';

$conn = getDBConnection();

$tests = [
    'database' => 'bijakmah_flexi',
    'connection' => $conn ? 'Connected' : 'Failed',
    'patients_count' => $conn->query("SELECT COUNT(*) as count FROM patients")->fetch_assoc()['count'],
    'therapists_count' => $conn->query("SELECT COUNT(*) as count FROM therapists")->fetch_assoc()['count'],
    'exercises_count' => $conn->query("SELECT COUNT(*) as count FROM exercises")->fetch_assoc()['count'],
    'timestamp' => date('Y-m-d H:i:s')
];

echo json_encode([
    'success' => true,
    'message' => 'API is working!',
    'tests' => $tests
]);
?>