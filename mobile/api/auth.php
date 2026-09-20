<?php
// mobile/api/auth.php
require_once __DIR__ . '/config.php';

function generateToken($userId, $userType) {
    $payload = [
        'user_id' => $userId,
        'user_type' => $userType,
        'exp' => time() + (30 * 24 * 60 * 60)
    ];

    $header = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payloadEncoded = base64_encode(json_encode($payload));
    $signature = hash_hmac('sha256', "$header.$payloadEncoded", JWT_SECRET);

    return "$header.$payloadEncoded.$signature";
}

function verifyToken($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;

    list($header, $payload, $signature) = $parts;
    $expectedSignature = hash_hmac('sha256', "$header.$payload", JWT_SECRET);

    if (!hash_equals($expectedSignature, $signature)) return false;

    $data = json_decode(base64_decode($payload), true);
    if ($data['exp'] < time()) return false;

    return $data;
}

function getAuthUser() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if (empty($authHeader) || !preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
        return null;
    }

    $token = $matches[1];
    return verifyToken($token);
}

function requireAuth($userType = null) {
    $user = getAuthUser();

    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized - Invalid or missing token']);
        exit();
    }

    if ($userType && $user['user_type'] !== $userType) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Forbidden']);
        exit();
    }

    return $user;
}

function jsonResponse($success, $message, $data = null) {
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit();
}
?>