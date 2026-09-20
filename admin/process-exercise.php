<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';

// Check authentication
$auth->requireLogin();

$action = $_GET['action'] ?? $_POST['action'] ?? '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $conn = getDBConnection();
    
    if ($action === 'add_exercise') {
        $exercise_name = $_POST['exercise_name'] ?? '';
        $description = $_POST['description'] ?? '';
        $instructions = $_POST['instructions'] ?? '';
        $difficulty = $_POST['difficulty'] ?? 'beginner';
        $reps_default = $_POST['reps_default'] ?? 10;
        $sets_default = $_POST['sets_default'] ?? 3;
        $hold_duration_sec = $_POST['hold_duration_sec'] ?? 5;
        
        $stmt = $conn->prepare("INSERT INTO exercises (exercise_name, description, instructions, difficulty, reps_default, sets_default, hold_duration_sec) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("ssssiii", $exercise_name, $description, $instructions, $difficulty, $reps_default, $sets_default, $hold_duration_sec);
        
        if ($stmt->execute()) {
            $_SESSION['success'] = "Exercise added successfully!";
        } else {
            $_SESSION['error'] = "Failed to add exercise: " . $conn->error;
        }
        
        header("Location: exercise-management.php");
        exit();
        
    } elseif ($action === 'update') {
        $exercise_id = $_POST['exercise_id'] ?? '';
        $exercise_name = $_POST['exercise_name'] ?? '';
        $description = $_POST['description'] ?? '';
        $instructions = $_POST['instructions'] ?? '';
        $difficulty = $_POST['difficulty'] ?? 'beginner';
        $reps_default = $_POST['reps_default'] ?? 10;
        $sets_default = $_POST['sets_default'] ?? 3;
        $hold_duration_sec = $_POST['hold_duration_sec'] ?? 5;
        
        $stmt = $conn->prepare("UPDATE exercises SET exercise_name = ?, description = ?, instructions = ?, difficulty = ?, reps_default = ?, sets_default = ?, hold_duration_sec = ? WHERE exercise_id = ?");
        $stmt->bind_param("ssssiiii", $exercise_name, $description, $instructions, $difficulty, $reps_default, $sets_default, $hold_duration_sec, $exercise_id);
        
        if ($stmt->execute()) {
            $_SESSION['success'] = "Exercise updated successfully!";
        } else {
            $_SESSION['error'] = "Failed to update exercise: " . $conn->error;
        }
        
        header("Location: exercise-management.php");
        exit();
    }
}

header("Location: exercise-management.php");
exit();
?>