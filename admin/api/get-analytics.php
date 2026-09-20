<?php
require_once '../includes/config.php';
require_once '../includes/auth.php';
require_once '../includes/functions.php';

// Check authentication
session_start();
if (!isset($_SESSION['logged_in']) || $_SESSION['logged_in'] !== true) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$auth = new Auth();
$functions = new Functions();

header('Content-Type: application/json');

// Get parameters
$report_type = $_GET['type'] ?? 'overview';
$start_date = $_GET['start_date'] ?? date('Y-m-01');
$end_date = $_GET['end_date'] ?? date('Y-m-t');

try {
    switch ($report_type) {
        case 'patient':
            $data = $functions->getDetailedAnalytics($start_date, $end_date);
            break;
            
        case 'compliance':
            $data = $functions->getComplianceStats($start_date, $end_date);
            break;
            
        case 'pain':
            $data = $functions->getPainScoreTrends($start_date, $end_date);
            break;
            
        case 'overview':
        default:
            $data = [
                'stats' => $functions->getDashboardStats(),
                'analytics' => $functions->getReportingAnalytics(),
                'detailed' => $functions->getDetailedAnalytics($start_date, $end_date)
            ];
            break;
    }
    
    echo json_encode([
        'success' => true,
        'data' => $data,
        'period' => [
            'start_date' => $start_date,
            'end_date' => $end_date
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => true,
        'message' => $e->getMessage()
    ]);
}
?>