<?php
// api/patient/profile.php - Get/Update Patient Profile

require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get profile
    $stmt = $conn->prepare("
        SELECT 
            p.patient_id, p.patient_ic, p.full_name, p.email, p.phone,
            p.finger_condition, p.pain_score, p.streak, p.compliance_rate,
            p.status, p.daily_status, p.program_start_date, p.profile_picture,
            p.created_at,
            t.full_name as therapist_name, t.email as therapist_email,
            t.phone as therapist_phone, t.whatsapp as therapist_whatsapp,
            t.centre_name
        FROM patients p
        LEFT JOIN therapists t ON p.therapist_id = t.therapist_id
        WHERE p.patient_id = ?
    ");
    $stmt->bind_param("i", $patientId);
    $stmt->execute();
    $result = $stmt->get_result();
    $profile = $result->fetch_assoc();
    
    if (!$profile) {
        jsonResponse(false, 'Profile not found');
    }
    
    $response = [
        'profile' => [
            'patient_id' => $profile['patient_id'],
            'patient_ic' => $profile['patient_ic'],
            'full_name' => $profile['full_name'],
            'email' => $profile['email'],
            'phone' => $profile['phone'],
            'finger_condition' => $profile['finger_condition'],
            'pain_score' => (int)$profile['pain_score'],
            'streak' => (int)$profile['streak'],
            'compliance_rate' => (float)$profile['compliance_rate'],
            'status' => $profile['status'],
            'daily_status' => $profile['daily_status'],
            'program_start_date' => $profile['program_start_date'],
            'profile_picture' => $profile['profile_picture'] ? BASE_URL . $profile['profile_picture'] : null,
            'created_at' => $profile['created_at']
        ],
        'therapist' => $profile['therapist_name'] ? [
            'name' => $profile['therapist_name'],
            'email' => $profile['therapist_email'],
            'phone' => $profile['therapist_phone'],
            'whatsapp' => $profile['therapist_whatsapp'],
            'centre_name' => $profile['centre_name']
        ] : null
    ];
    
    jsonResponse(true, 'Profile retrieved', $response);
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    // Update profile
    $input = json_decode(file_get_contents('php://input'), true);
    
    $fullName = $input['full_name'] ?? '';
    $phone = $input['phone'] ?? '';
    
    if (empty($fullName) || empty($phone)) {
        jsonResponse(false, 'Full name and phone are required');
    }
    
    $stmt = $conn->prepare("
        UPDATE patients 
        SET full_name = ?, phone = ?
        WHERE patient_id = ?
    ");
    $stmt->bind_param("ssi", $fullName, $phone, $patientId);
    
    if ($stmt->execute()) {
        jsonResponse(true, 'Profile updated successfully');
    } else {
        jsonResponse(false, 'Failed to update profile');
    }
    
} else {
    jsonResponse(false, 'Method not allowed');
}
?>