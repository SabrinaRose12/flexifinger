<?php
// mobile/api/therapist/patients.php
require_once '../auth.php';

$user = requireAuth('therapist');
$therapistId = $user['user_id'];
$conn = getDBConnection();

$filter = $_GET['filter'] ?? 'all';
$search = $_GET['search'] ?? '';

error_log("Therapist ID: $therapistId fetching patients. Filter: $filter, Search: $search");

$query = "
    SELECT
        p.patient_id,
        p.patient_ic,
        p.full_name,
        p.email,
        p.phone,
        p.finger_condition,
        COALESCE(p.pain_score, 0) as pain_score,
        COALESCE(p.streak, 0) as streak,
        COALESCE(p.compliance_rate, 0) as compliance_rate,
        p.status,
        p.daily_status,
        p.program_start_date,
        p.created_at,
        CASE WHEN p.status = 'active' THEN 1 ELSE 0 END as is_active,
        es.set_name as exercise_set_name,
        sch.frequency,
        sch.start_date,
        sch.end_date
    FROM patients p
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE p.therapist_id = ?
";

$params = [$therapistId];
$types = "i";

if ($filter === 'active') {
    $query .= " AND p.status = 'active'";
} elseif ($filter === 'inactive') {
    $query .= " AND p.status IN ('inactive', 'pending')";
}

if (!empty($search)) {
    $query .= " AND (p.full_name LIKE ? OR p.patient_ic LIKE ? OR p.email LIKE ?)";
    $searchTerm = "%$search%";
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $types .= "sss";
}

$query .= " ORDER BY p.full_name";

$stmt = $conn->prepare($query);
if (!$stmt) {
    error_log("Query error: " . $conn->error);
    jsonResponse(false, 'Database error');
    exit();
}

$stmt->bind_param($types, ...$params);
$stmt->execute();
$result = $stmt->get_result();

$patients = [];
while ($row = $result->fetch_assoc()) {
    $patients[] = [
        'patient_id' => (int)$row['patient_id'],
        'patient_ic' => $row['patient_ic'],
        'full_name' => $row['full_name'],
        'email' => $row['email'],
        'phone' => $row['phone'],
        'finger_condition' => $row['finger_condition'],
        'pain_score' => (int)$row['pain_score'],
        'streak' => (int)$row['streak'],
        'compliance_rate' => (float)$row['compliance_rate'],
        'status' => $row['status'],
        'is_active' => (bool)$row['is_active'],
        'daily_status' => $row['daily_status'] ?? 'Pending',
        'program_start_date' => $row['program_start_date'],
        'created_at' => $row['created_at'],
        'exercise_set_name' => $row['exercise_set_name'],
        'frequency' => $row['frequency'],
        'schedule_start' => $row['start_date'],
        'schedule_end' => $row['end_date']
    ];
}

error_log("Found " . count($patients) . " patients for therapist $therapistId");

jsonResponse(true, 'Patients retrieved', [
    'total' => count($patients),
    'filter' => $filter,
    'patients' => $patients
]);
?>