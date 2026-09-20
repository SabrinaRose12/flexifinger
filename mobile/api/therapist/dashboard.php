<?php
// mobile/api/therapist/dashboard.php
require_once '../auth.php';

$user = requireAuth('therapist');
$therapistId = $user['user_id'];
$conn = getDBConnection();

error_log("Therapist ID: $therapistId accessing dashboard");

// Get therapist info
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
        t.patient_count,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id) as actual_patient_count,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id AND status = 'active') as active_patients,
        (SELECT COUNT(*) FROM patients WHERE therapist_id = t.therapist_id AND status = 'inactive') as inactive_patients,
        (SELECT COALESCE(AVG(compliance_rate), 0) FROM patients WHERE therapist_id = t.therapist_id) as avg_compliance
    FROM therapists t
    WHERE t.therapist_id = ?
");
$stmt->bind_param("i", $therapistId);
$stmt->execute();
$therapist = $stmt->get_result()->fetch_assoc();

if (!$therapist) {
    jsonResponse(false, 'Therapist not found');
    exit();
}

$isApproved = ($therapist['status'] === 'active');
$hasFullAccess = $isApproved;

// Get today's patient activity
$todayActivity = [];
if ($hasFullAccess) {
    $stmt2 = $conn->prepare("
        SELECT
            p.patient_id,
            p.full_name,
            p.finger_condition,
            COALESCE(p.pain_score, 0) as pain_score,
            COALESCE(p.compliance_rate, 0) as compliance_rate,
            COALESCE(p.daily_status, 'Pending today') as daily_status,
            es.set_name as exercise_set
        FROM patients p
        LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
        LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
        WHERE p.therapist_id = ? AND p.status = 'active'
        ORDER BY
            CASE p.daily_status
                WHEN 'Completed today' THEN 1
                WHEN 'Pending today' THEN 2
                WHEN 'Missed today' THEN 3
                ELSE 4
            END,
            p.full_name
        LIMIT 10
    ");
    $stmt2->bind_param("i", $therapistId);
    $stmt2->execute();
    $result2 = $stmt2->get_result();

    while ($row = $result2->fetch_assoc()) {
        $todayActivity[] = [
            'patient_id' => (int)$row['patient_id'],
            'full_name' => $row['full_name'],
            'finger_condition' => $row['finger_condition'],
            'pain_score' => (int)$row['pain_score'],
            'compliance_rate' => (float)$row['compliance_rate'],
            'daily_status' => $row['daily_status'],
            'exercise_set' => $row['exercise_set']
        ];
    }
}

// Get recent notifications
$notifications = [];
$tableCheck = $conn->query("SHOW TABLES LIKE 'notifications'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    $stmt3 = $conn->prepare("
        SELECT notification_id, title, message, type, is_read, created_at
        FROM notifications
        WHERE user_type = 'therapist' AND user_id = ?
        ORDER BY created_at DESC
        LIMIT 5
    ");
    $stmt3->bind_param("i", $therapistId);
    $stmt3->execute();
    $result3 = $stmt3->get_result();

    while ($row = $result3->fetch_assoc()) {
        $notifications[] = $row;
    }
}

// Get unread notification count
$unreadCount = 0;
if ($tableCheck && $tableCheck->num_rows > 0) {
    $stmt4 = $conn->prepare("
        SELECT COUNT(*) as unread
        FROM notifications
        WHERE user_type = 'therapist' AND user_id = ? AND is_read = 0
    ");
    $stmt4->bind_param("i", $therapistId);
    $stmt4->execute();
    $unreadCount = $stmt4->get_result()->fetch_assoc()['unread'];
}

error_log("Dashboard data - Patients: {$therapist['actual_patient_count']}, Today activity: " . count($todayActivity));

jsonResponse(true, 'Dashboard data retrieved', [
    'therapist' => [
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
        'total_patients' => (int)$therapist['actual_patient_count'],
        'active_patients' => (int)$therapist['active_patients'],
        'average_compliance' => round((float)$therapist['avg_compliance'], 1)
    ],
    'stats' => [
        'total_patients' => (int)$therapist['actual_patient_count'],
        'active_patients' => (int)$therapist['active_patients'],
        'inactive_patients' => (int)$therapist['inactive_patients'],
        'pending_patients' => 0,
        'average_compliance' => round((float)$therapist['avg_compliance'], 1)
    ],
    'today_activity' => $todayActivity,
    'notifications' => $notifications,
    'unread_count' => (int)$unreadCount
]);
?>