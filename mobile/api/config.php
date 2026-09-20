<?php
// mobile/api/config.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function getDBConnection() {
    $host = 'localhost';
    $user = 'flexiadmin';           // 👈 TUKAR
    $password = 'flexiadmin7890';   // 👈 TUKAR
    $database = 'bijakmah_flexi';   // 👈 TUKAR

    $conn = new mysqli($host, $user, $password, $database);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }

    return $conn;
}

define('BASE_URL', 'http://your-server.com/flexifinger/'); // 👈 TUKAR ke URL server
define('JWT_SECRET', 'flexifinger_secret_key_2024');
?>