<?php
function getDBConnection() {
    $host = 'localhost';
    $user = 'bijakmah_flexiadmin';        // 👈 NI YANG BETUL
    $password = 'flexiadmin7890';
    $database = 'bijakmah_flexi';          // 👈 NI YANG BETUL

    $conn = new mysqli($host, $user, $password, $database);

    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    return $conn;
}

define('BASE_URL', 'https://bijakmahir.com/flexi/flexifinger/');
session_start();
?>