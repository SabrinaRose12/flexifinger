<?php
$host = 'localhost';
$user = 'bijakmah_flexiadmin';
$password = 'flexiadmin7890';
$database = 'bijakmah_flexi';

$conn = new mysqli($host, $user, $password, $database);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "Connected successfully!";
echo "<br>Patients: " . $conn->query("SELECT COUNT(*) as c FROM patients")->fetch_assoc()['c'];
?>