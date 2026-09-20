<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';

// Check authentication
$auth->requireLogin();

$action = $_GET['action'] ?? $_POST['action'] ?? '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $conn = getDBConnection();
    
    if ($action === 'add') {
        $staff_id = $_POST['staff_id'] ?? '';
        $full_name = $_POST['full_name'] ?? '';
        $email = $_POST['email'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $centre_name = $_POST['centre_name'] ?? '';
        $centre_type = $_POST['centre_type'] ?? '';
        $status = $_POST['status'] ?? 'pending';
        $password = $_POST['password'] ?? 'Therapist123';
        
        // Hash password
        $password_hash = password_hash($password, PASSWORD_DEFAULT);
        
        // Check if staff ID already exists
        $checkStmt = $conn->prepare("SELECT therapist_id FROM therapists WHERE staff_id = ? OR email = ?");
        $checkStmt->bind_param("ss", $staff_id, $email);
        $checkStmt->execute();
        $result = $checkStmt->get_result();
        
        if ($result->num_rows > 0) {
            $_SESSION['error'] = "Staff ID or email already exists!";
            header("Location: therapist-management.php");
            exit();
        }
        
        // Insert new therapist
        $stmt = $conn->prepare("INSERT INTO therapists (staff_id, full_name, email, phone, password_hash, centre_name, centre_type, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("ssssssss", $staff_id, $full_name, $email, $phone, $password_hash, $centre_name, $centre_type, $status);
        
        if ($stmt->execute()) {
            $_SESSION['success'] = "Therapist added successfully!";
            
            // If status is active, auto-validate
            if ($status === 'active') {
                $therapist_id = $conn->insert_id;
                $validateStmt = $conn->prepare("UPDATE therapists SET validated_at = NOW(), validated_by = ? WHERE therapist_id = ?");
                $validateStmt->bind_param("ii", $_SESSION['admin_id'], $therapist_id);
                $validateStmt->execute();
            }
        } else {
            $_SESSION['error'] = "Failed to add therapist: " . $conn->error;
        }
        
        header("Location: therapist-management.php");
        exit();
        
    } elseif ($action === 'update') {
        $therapist_id = $_POST['therapist_id'] ?? '';
        $full_name = $_POST['full_name'] ?? '';
        $email = $_POST['email'] ?? '';
        $phone = $_POST['phone'] ?? '';
        $centre_name = $_POST['centre_name'] ?? '';
        $centre_type = $_POST['centre_type'] ?? '';
        $status = $_POST['status'] ?? '';
        
        $stmt = $conn->prepare("UPDATE therapists SET full_name = ?, email = ?, phone = ?, centre_name = ?, centre_type = ?, status = ? WHERE therapist_id = ?");
        $stmt->bind_param("ssssssi", $full_name, $email, $phone, $centre_name, $centre_type, $status, $therapist_id);
        
        if ($stmt->execute()) {
            $_SESSION['success'] = "Therapist updated successfully!";
        } else {
            $_SESSION['error'] = "Failed to update therapist: " . $conn->error;
        }
        
        header("Location: therapist-management.php");
        exit();
    }
}

header("Location: therapist-management.php");
exit();
?>