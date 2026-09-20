<?php
require_once 'includes/config.php';

echo "Testing database connection...<br>";

$conn = getDBConnection();
echo "Connected successfully!<br>";

$result = $conn->query("SELECT COUNT(*) as count FROM patients");
$count = $result->fetch_assoc()['count'];
echo "Patients count: $count<br>";

echo "All OK!";
?>