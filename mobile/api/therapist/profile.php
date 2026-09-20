<?php
// mobile/api/therapist/profile.php
require_once '../auth.php';

$user = requireAuth('therapist');
$therapistId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $conn->prepare("
        SELECT
            therapist_id, staff_id, full_name, email, phone, whatsapp,
            centre_name, centre_type, status, patient_count, created_at,
            (SELECT COUNT(*) FROM patients WHERE therapist_id = ?) as actual_patients,
            (SELECT COUNT(*) FROM patients WHERE therapist_id = ? AND status = 'active') as active_patients,
            (SELECT COALESCE(AVG(compliance_rate), 0) FROM patients WHERE therapist_id = ?) as avg_compliance
        FROM therapists
        WHERE therapist_id = ?
    ");
    $stmt->bind_param("iiii", $therapistId, $therapistId, $therapistId, $therapistId);
    $stmt->execute();
    $profile = $stmt->get_result()->fetch_assoc();

    if (!$profile) {
        jsonResponse(false, 'Profile not found');
    }

    jsonResponse(true, 'Profile retrieved', [
        'profile' => [
            'therapist_id' => (int)$profile['therapist_id'],
            'staff_id' => $profile['staff_id'],
            'full_name' => $profile['full_name'],
            'email' => $profile['email'],
            'phone' => $profile['phone'],
            'whatsapp' => $profile['whatsapp'],
            'centre_name' => $profile['centre_name'],
            'centre_type' => $profile['centre_type'],
            'status' => $profile['status'],
            'is_approved' => ($profile['status'] === 'active'),
            'patient_count' => (int)$profile['actual_patients'],
            'active_patients' => (int)$profile['active_patients'],
            'average_compliance' => round((float)$profile['avg_compliance'], 1),
            'created_at' => $profile['created_at']
        ]
    ]);

} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);

    $fullName = $input['full_name'] ?? '';
    $phone = $input['phone'] ?? '';
    $whatsapp = $input['whatsapp'] ?? '';
    $centreName = $input['centre_name'] ?? '';

    if (empty($fullName) || empty($phone)) {
        jsonResponse(false, 'Full name and phone are required');
    }

    $stmt = $conn->prepare("
        UPDATE therapists
        SET full_name = ?, phone = ?, whatsapp = ?, centre_name = ?
        WHERE therapist_id = ?
    ");
    $stmt->bind_param("ssssi", $fullName, $phone, $whatsapp, $centreName, $therapistId);

    if ($stmt->execute()) {
        jsonResponse(true, 'Profile updated successfully');
    } else {
        jsonResponse(false, 'Failed to update profile');
    }

} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? '';

    if ($action === 'change_password') {
        $currentPassword = $input['current_password'] ?? '';
        $newPassword = $input['new_password'] ?? '';

        if (strlen($newPassword) < 6) {
            jsonResponse(false, 'Password must be at least 6 characters');
        }

        $stmt = $conn->prepare("SELECT password_hash FROM therapists WHERE therapist_id = ?");
        $stmt->bind_param("i", $therapistId);
        $stmt->execute();
        $result = $stmt->get_result()->fetch_assoc();

        if ($result['password_hash'] !== $currentPassword) {
            jsonResponse(false, 'Current password is incorrect');
        }

        $stmt2 = $conn->prepare("UPDATE therapists SET password_hash = ? WHERE therapist_id = ?");
        $stmt2->bind_param("si", $newPassword, $therapistId);
        
        if ($stmt2->execute()) {
            jsonResponse(true, 'Password changed successfully');
        } else {
            jsonResponse(false, 'Failed to change password');
        }
    } else {
        jsonResponse(false, 'Invalid action');
    }
    
} else {
    jsonResponse(false, 'Method not allowed');
}
?>