<?php
// api/get-exercise-media.php
// Returns exercise data with media URLs for mobile app

require_once '../includes/config.php';
require_once '../includes/functions.php';

header('Content-Type: application/json');

$exercise_id = $_GET['exercise_id'] ?? 0;
$base_url = 'https://your-server.com/flexifinger/'; // Change to your actual domain

$conn = getDBConnection();

if ($exercise_id) {
    // Get specific exercise
    $stmt = $conn->prepare("
        SELECT 
            e.*,
            CONCAT(?, e.video_path) as video_url,
            CONCAT(?, e.thumbnail_path) as thumbnail_url
        FROM exercises e
        WHERE e.exercise_id = ?
    ");
    $stmt->bind_param("ssi", $base_url, $base_url, $exercise_id);
} else {
    // Get all exercises
    $stmt = $conn->prepare("
        SELECT 
            e.*,
            CONCAT(?, e.video_path) as video_url,
            CONCAT(?, e.thumbnail_path) as thumbnail_url
        FROM exercises e
        ORDER BY e.exercise_name
    ");
    $stmt->bind_param("ss", $base_url, $base_url);
}

$stmt->execute();
$result = $stmt->get_result();

$exercises = [];
while ($row = $result->fetch_assoc()) {
    $exercises[] = $row;
}

echo json_encode([
    'success' => true,
    'base_url' => $base_url,
    'data' => $exercises
]);
?>