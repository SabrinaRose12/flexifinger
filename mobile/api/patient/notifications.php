<?php
// api/patient/notifications.php - Get Notifications

require_once '../auth.php';

$user = requireAuth('patient');
$patientId = $user['user_id'];
$conn = getDBConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $unreadOnly = isset($_GET['unread_only']) && $_GET['unread_only'] === 'true';
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    
    $query = "
        SELECT notification_id, title, message, type, is_read, created_at, data
        FROM notifications
        WHERE user_type = 'patient' AND user_id = ?
    ";
    
    if ($unreadOnly) {
        $query .= " AND is_read = 0";
    }
    
    $query .= " ORDER BY created_at DESC LIMIT ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $patientId, $limit);
    $stmt->execute();
    $notifications = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    
    // Get unread count
    $stmt2 = $conn->prepare("
        SELECT COUNT(*) as unread
        FROM notifications
        WHERE user_type = 'patient' AND user_id = ? AND is_read = 0
    ");
    $stmt2->bind_param("i", $patientId);
    $stmt2->execute();
    $unreadCount = $stmt2->get_result()->fetch_assoc()['unread'];
    
    jsonResponse(true, 'Notifications retrieved', [
        'unread_count' => (int)$unreadCount,
        'notifications' => array_map(function($n) {
            return [
                'id' => $n['notification_id'],
                'title' => $n['title'],
                'message' => $n['message'],
                'type' => $n['type'],
                'is_read' => (bool)$n['is_read'],
                'created_at' => $n['created_at'],
                'data' => $n['data'] ? json_decode($n['data'], true) : null
            ];
        }, $notifications)
    ]);
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    $notificationId = $input['notification_id'] ?? 0;
    $markAllRead = $input['mark_all_read'] ?? false;
    
    if ($markAllRead) {
        $stmt = $conn->prepare("
            UPDATE notifications SET is_read = 1, read_at = NOW()
            WHERE user_type = 'patient' AND user_id = ? AND is_read = 0
        ");
        $stmt->bind_param("i", $patientId);
        $stmt->execute();
        jsonResponse(true, 'All notifications marked as read');
    } else {
        $stmt = $conn->prepare("
            UPDATE notifications SET is_read = 1, read_at = NOW()
            WHERE notification_id = ? AND user_type = 'patient' AND user_id = ?
        ");
        $stmt->bind_param("ii", $notificationId, $patientId);
        $stmt->execute();
        jsonResponse(true, 'Notification marked as read');
    }
    
} else {
    jsonResponse(false, 'Method not allowed');
}
?>