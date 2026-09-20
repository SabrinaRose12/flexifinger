<?php
// mobile/api/therapist/login.php
require_once '../auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed');
}

$input = json_decode(file_get_contents('php://input'), true);
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$deviceToken = $input['device_token'] ?? null;
$deviceType = $input['device_type'] ?? 'android';

if (empty($email) || empty($password)) {
    jsonResponse(false, 'Email and password are required');
}

$conn = getDBConnection();

$stmt = $conn->prepare("
    SELECT
        t.therapist_id,
        t.staff_id,
        t.full_name,
        t.email,
        t.phone,
        t.whatsapp,
        t.centre_name,
        t.centre_type,
        t.status,
        t.password_hash,
        t.patient_count,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id) as actual_patient_count,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id AND status = 'active') as active_patients,
        (SELECT AVG(compliance_rate) FROM patients WHERE therapist_id = t.therapist_id AND compliance_rate > 0) as avg_compliance
    FROM therapists t
    WHERE t.email = ?
");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();
$therapist = $result->fetch_assoc();

if (!$therapist) {
    jsonResponse(false, 'Invalid email or password');
}

// Check password (plain text for demo - use password_verify in production)
if ($therapist['password_hash'] !== $password) {
    jsonResponse(false, 'Invalid email or password');
}

// Create session record if table exists
$tableCheck = $conn->query("SHOW TABLES LIKE 'therapist_sessions'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    $stmt2 = $conn->prepare("
        INSERT INTO therapist_sessions (therapist_id, device_token, device_type, login_time)
        VALUES (?, ?, ?, NOW())
    ");
    $stmt2->bind_param("iss", $therapist['therapist_id'], $deviceToken, $deviceType);
    $stmt2->execute();
}

// Generate token
$token = generateToken($therapist['therapist_id'], 'therapist');

$isApproved = ($therapist['status'] === 'active');
$hasFullAccess = $isApproved;

$response = [
    'token' => $token,
    'user' => [
        'therapist_id' => (int)$therapist['therapist_id'],
        'staff_id' => $therapist['staff_id'],
        'full_name' => $therapist['full_name'],
        'email' => $therapist['email'],
        'phone' => $therapist['phone'],
        'whatsapp' => $therapist['whatsapp'],
        'centre_name' => $therapist['centre_name'],
        'centre_type' => $therapist['centre_type'],
        'status' => $therapist['status'],
        'is_approved' => $isApproved,
        'has_full_access' => $hasFullAccess,
        'total_patients' => (int)($therapist['actual_patient_count'] ?? 0),
        'active_patients' => (int)($therapist['active_patients'] ?? 0),
        'average_compliance' => round((float)($therapist['avg_compliance'] ?? 0), 1)
    ]
];

jsonResponse(true, 'Login successful', $response);
?>