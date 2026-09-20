<?php
// mobile/api/therapist/register.php
require_once '../auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed');
}

$input = json_decode(file_get_contents('php://input'), true);

$centreName = trim($input['centre_name'] ?? '');
$fullName = trim($input['full_name'] ?? '');
$phone = trim($input['phone'] ?? '');
$staffId = trim($input['staff_id'] ?? '');
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$centreType = trim($input['centre_type'] ?? 'clinic');
$whatsapp = trim($input['whatsapp'] ?? '');

// Validation
if (empty($centreName) || empty($fullName) || empty($phone) ||
    empty($staffId) || empty($email) || empty($password)) {
    jsonResponse(false, 'All fields are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(false, 'Invalid email format');
}

if (strlen($password) < 6) {
    jsonResponse(false, 'Password must be at least 6 characters');
}

$conn = getDBConnection();

// Check if email or staff ID already exists
$stmt = $conn->prepare("SELECT therapist_id FROM therapists WHERE email = ? OR staff_id = ?");
$stmt->bind_param("ss", $email, $staffId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    jsonResponse(false, 'Email or Staff ID already registered');
}

// Insert new therapist
$stmt2 = $conn->prepare("
    INSERT INTO therapists (
        staff_id, full_name, email, phone, whatsapp, password_hash,
        centre_name, centre_type, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
");
$stmt2->bind_param(
    "ssssssss",
    $staffId, $fullName, $email, $phone, $whatsapp, $password,
    $centreName, $centreType
);

if (!$stmt2->execute()) {
    jsonResponse(false, 'Registration failed. Please try again. Error: ' . $conn->error);
}

$therapistId = $conn->insert_id;

// Generate token
$token = generateToken($therapistId, 'therapist');

$response = [
    'token' => $token,
    'user' => [
        'therapist_id' => $therapistId,
        'staff_id' => $staffId,
        'full_name' => $fullName,
        'email' => $email,
        'phone' => $phone,
        'whatsapp' => $whatsapp,
        'centre_name' => $centreName,
        'centre_type' => $centreType,
        'status' => 'pending',
        'is_approved' => false,
        'has_full_access' => false,
        'total_patients' => 0,
        'active_patients' => 0,
        'average_compliance' => 0.0
    ]
];

jsonResponse(true, 'Registration successful. Waiting for admin approval.', $response);
?>