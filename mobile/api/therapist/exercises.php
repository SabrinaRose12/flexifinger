<?php
// api/therapist/exercises.php - Get Available Exercises

require_once '../auth.php';

$user = requireAuth('therapist');
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $condition = $_GET['condition'] ?? '';
    $setId = $_GET['set_id'] ?? 0;
    
    if ($setId) {
        // Get exercises in a specific set
        $stmt = $conn->prepare("
            SELECT 
                e.exercise_id, e.exercise_name, e.description,
                e.instructions, e.difficulty, e.reps_default, e.sets_default,
                e.hold_duration_sec, e.video_path, e.thumbnail_path,
                se.order_in_set
            FROM set_exercises se
            JOIN exercises e ON se.exercise_id = e.exercise_id
            WHERE se.set_id = ?
            ORDER BY se.order_in_set
        ");
        $stmt->bind_param("i", $setId);
        $stmt->execute();
        $exercises = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        
    } else {
        // Get all exercises, optionally filtered by condition
        $query = "
            SELECT 
                e.exercise_id, e.exercise_name, e.description,
                e.instructions, e.difficulty, e.reps_default, e.sets_default,
                e.hold_duration_sec, e.video_path, e.thumbnail_path,
                es.set_name, es.condition_target
            FROM exercises e
            LEFT JOIN set_exercises se ON e.exercise_id = se.exercise_id
            LEFT JOIN exercise_sets es ON se.set_id = es.set_id
        ";
        
        if (!empty($condition)) {
            $query .= " WHERE es.condition_target LIKE ?";
            $stmt = $conn->prepare($query . " ORDER BY e.exercise_name");
            $searchTerm = "%$condition%";
            $stmt->bind_param("s", $searchTerm);
        } else {
            $stmt = $conn->prepare($query . " ORDER BY e.exercise_name");
        }
        
        $stmt->execute();
        $exercises = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    }
    
    $formattedExercises = array_map(function($ex) {
        return [
            'id' => $ex['exercise_id'],
            'name' => $ex['exercise_name'],
            'description' => $ex['description'],
            'instructions' => $ex['instructions'],
            'difficulty' => $ex['difficulty'],
            'reps' => (int)$ex['reps_default'],
            'sets' => (int)$ex['sets_default'],
            'hold_duration_sec' => (int)$ex['hold_duration_sec'],
            'video_url' => $ex['video_path'] ? BASE_URL . $ex['video_path'] : null,
            'thumbnail_url' => $ex['thumbnail_path'] ? BASE_URL . $ex['thumbnail_path'] : null,
            'set_name' => $ex['set_name'] ?? null,
            'condition' => $ex['condition_target'] ?? null,
            'order' => isset($ex['order_in_set']) ? (int)$ex['order_in_set'] : null
        ];
    }, $exercises);
    
    // Also return available exercise sets
    $stmt2 = $conn->prepare("
        SELECT 
            set_id, set_name, condition_target, description,
            (SELECT COUNT(*) FROM set_exercises WHERE set_id = es.set_id) as exercise_count
        FROM exercise_sets es
        ORDER BY set_name
    ");
    $stmt2->execute();
    $sets = $stmt2->get_result()->fetch_all(MYSQLI_ASSOC);
    
    jsonResponse(true, 'Exercises retrieved', [
        'exercises' => $formattedExercises,
        'sets' => $sets
    ]);
    
} else {
    jsonResponse(false, 'Method not allowed');
}
?>