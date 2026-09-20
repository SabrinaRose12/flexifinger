<?php
// mobile/api/patient/login.php
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
        p.patient_id, p.patient_ic, p.full_name, p.email, p.phone,
        p.finger_condition, p.pain_score, p.streak, p.compliance_rate,
        p.status, p.daily_status, p.program_start_date, p.profile_picture,
        p.password_hash, p.therapist_id,
        t.full_name as therapist_name, t.whatsapp as therapist_whatsapp,
        es.set_name as exercise_set_name, es.set_id as exercise_set_id
    FROM patients p
    LEFT JOIN therapists t ON p.therapist_id = t.therapist_id
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE p.email = ?
");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();
$patient = $result->fetch_assoc();

// 🔴 Check if patient exists and password matches
if (!$patient || $patient['password_hash'] !== $password) {
    jsonResponse(false, 'Invalid email or password');
}

// 🔴 CHECK IF ACCOUNT IS INACTIVE
if ($patient['status'] === 'inactive') {
    jsonResponse(false, 'You are not allowed to open this app');
}

// 🔴 Check if account is pending (optional - boleh login tapi limited)
$isApproved = ($patient['status'] === 'active');
$hasFullAccess = ($isApproved && $patient['therapist_id'] !== null);
$canViewExercise = ($hasFullAccess && $patient['exercise_set_id'] !== null);

// Create session record
$tableCheck = $conn->query("SHOW TABLES LIKE 'patient_sessions'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    $stmt3 = $conn->prepare("
        INSERT INTO patient_sessions (patient_id, device_token, device_type, login_time)
        VALUES (?, ?, ?, NOW())
    ");
    $stmt3->bind_param("iss", $patient['patient_id'], $deviceToken, $deviceType);
    $stmt3->execute();
}

// Generate token
$token = generateToken($patient['patient_id'], 'patient');

jsonResponse(true, 'Login successful', [
    'token' => $token,
    'user' => [
        'patient_id' => $patient['patient_id'],
        'patient_ic' => $patient['patient_ic'],
        'full_name' => $patient['full_name'],
        'email' => $patient['email'],
        'phone' => $patient['phone'],
        'finger_condition' => $patient['finger_condition'],
        'pain_score' => (int)$patient['pain_score'],
        'streak' => (int)$patient['streak'],
        'compliance_rate' => (float)$patient['compliance_rate'],
        'status' => $patient['status'],
        'daily_status' => $patient['daily_status'],
        'program_start_date' => $patient['program_start_date'],
        'profile_picture' => $patient['profile_picture'] ? BASE_URL . $patient['profile_picture'] : null,
        'has_full_access' => $hasFullAccess,
        'can_view_exercise' => $canViewExercise,
        'is_assigned' => ($patient['therapist_id'] !== null),
        'is_approved' => $isApproved,
        'has_exercise_assigned' => ($patient['exercise_set_id'] !== null),
        'assigned_therapist' => $patient['therapist_name'],
        'therapist_whatsapp' => $patient['therapist_whatsapp'],
        'exercise_set_name' => $patient['exercise_set_name']
    ]
]);
?>