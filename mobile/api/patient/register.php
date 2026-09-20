<?php
// mobile/api/patient/register.php
require_once '../auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed');
}

$input = json_decode(file_get_contents('php://input'), true);

$fullName = trim($input['full_name'] ?? '');
$icNumber = trim($input['ic_number'] ?? '');
$email = trim($input['email'] ?? '');
$phone = trim($input['phone'] ?? '');
$password = $input['password'] ?? '';
$fingerCondition = trim($input['finger_condition'] ?? '');

// Validation
if (empty($fullName) || empty($icNumber) || empty($email) || empty($phone) || empty($password)) {
    jsonResponse(false, 'All fields are required');
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(false, 'Invalid email format');
}

if (strlen($password) < 6) {
    jsonResponse(false, 'Password must be at least 6 characters');
}

$conn = getDBConnection();

// 🔴 CHECK IF EMAIL OR IC ALREADY EXISTS
$stmt = $conn->prepare("SELECT patient_id FROM patients WHERE email = ? OR patient_ic = ?");
$stmt->bind_param("ss", $email, $icNumber);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    // 🔴 EMAIL/IC ALREADY EXISTS - RETURN ERROR
    jsonResponse(false, 'Email or IC number already registered');
    exit(); // 👈 STOP HERE, DON'T INSERT
}

// 🔴 GENERATE PATIENT ID
$result2 = $conn->query("SELECT MAX(CAST(SUBSTRING(patient_id, 2) AS UNSIGNED)) as max_id FROM patients");
$row = $result2->fetch_assoc();
$nextId = ($row['max_id'] ?? 0) + 1;
$patientId = 'P' . str_pad($nextId, 3, '0', STR_PAD_LEFT);

// 🔴 INSERT NEW PATIENT
$stmt3 = $conn->prepare("
    INSERT INTO patients (
        patient_id, patient_ic, full_name, email, phone,
        password_hash, finger_condition, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
");

$stmt3->bind_param(
    "sssssss",
    $patientId, $icNumber, $fullName, $email, $phone,
    $password, $fingerCondition
);

if ($stmt3->execute()) {
    // 🔴 GENERATE TOKEN FOR IMMEDIATE LOGIN
    $token = generateToken($conn->insert_id, 'patient');

    jsonResponse(true, 'Registration successful', [
        'token' => $token,
        'user' => [
            'patient_id' => $patientId,
            'full_name' => $fullName,
            'email' => $email,
            'phone' => $phone,
            'finger_condition' => $fingerCondition,
            'status' => 'pending',
            'has_full_access' => false,
            'can_view_exercise' => false,
            'is_assigned' => false,
            'is_approved' => false,
            'has_exercise_assigned' => false
        ]
    ]);
} else {
    jsonResponse(false, 'Registration failed. Database error: ' . $conn->error);
}
?>