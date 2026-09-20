<?php
// admin/includes/functions.php
require_once __DIR__ . '/config.php';

class Functions {
    
    // Dashboard Stats
    public function getDashboardStats() {
        $conn = getDBConnection();
        return [
            'total_patients' => $conn->query("SELECT COUNT(*) as c FROM patients")->fetch_assoc()['c'],
            'pending_patients' => $conn->query("SELECT COUNT(*) as c FROM patients WHERE status='pending'")->fetch_assoc()['c'],
            'active_patients' => $conn->query("SELECT COUNT(*) as c FROM patients WHERE status='active'")->fetch_assoc()['c'],
            'inactive_patients' => $conn->query("SELECT COUNT(*) as c FROM patients WHERE status='inactive'")->fetch_assoc()['c'],
            'total_therapists' => $conn->query("SELECT COUNT(*) as c FROM therapists")->fetch_assoc()['c'],
            'pending_therapists' => $conn->query("SELECT COUNT(*) as c FROM therapists WHERE status='pending'")->fetch_assoc()['c']
        ];
    }
    
    // System Activity for Dashboard Chart
    public function getSystemActivity() {
        $conn = getDBConnection();
        
        $result = $conn->query("
            SELECT DATE(created_at) as date, COUNT(*) as count
            FROM activity_logs
            WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(created_at)
            ORDER BY date
        ");
        
        $activities = [];
        while ($row = $result->fetch_assoc()) {
            $activities[$row['date']] = $row['count'];
        }
        
        $approvals = $conn->query("
            SELECT DATE(validated_at) as date, COUNT(*) as count
            FROM patients
            WHERE validated_at IS NOT NULL AND validated_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(validated_at)
        ");
        while ($row = $approvals->fetch_assoc()) {
            $activities[$row['date']] = ($activities[$row['date']] ?? 0) + $row['count'];
        }
        
        $therapistApprovals = $conn->query("
            SELECT DATE(validated_at) as date, COUNT(*) as count
            FROM therapists
            WHERE validated_at IS NOT NULL AND validated_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(validated_at)
        ");
        while ($row = $therapistApprovals->fetch_assoc()) {
            $activities[$row['date']] = ($activities[$row['date']] ?? 0) + $row['count'];
        }
        
        return $activities;
    }
    
    // Get recent validations
    public function getRecentValidations($limit = 5) {
        $conn = getDBConnection();
        $patients = $conn->query("SELECT full_name, 'Patient' as type, validated_at FROM patients WHERE validated_at IS NOT NULL ORDER BY validated_at DESC LIMIT $limit")->fetch_all(MYSQLI_ASSOC);
        $therapists = $conn->query("SELECT full_name, 'Therapist' as type, validated_at FROM therapists WHERE validated_at IS NOT NULL ORDER BY validated_at DESC LIMIT $limit")->fetch_all(MYSQLI_ASSOC);
        $all = array_merge($patients, $therapists);
        usort($all, function($a, $b) { return strtotime($b['validated_at']) - strtotime($a['validated_at']); });
        return array_slice($all, 0, $limit);
    }
    
    // Patient Management
    public function getAllPatients() {
        $conn = getDBConnection();
        return $conn->query("
            SELECT p.*, t.full_name as therapist_name, t.staff_id as therapist_staff_id
            FROM patients p LEFT JOIN therapists t ON p.therapist_id = t.therapist_id
            ORDER BY p.created_at DESC
        ")->fetch_all(MYSQLI_ASSOC);
    }
    
    public function getPendingPatients() {
        $conn = getDBConnection();
        return $conn->query("SELECT * FROM patients WHERE status='pending' ORDER BY created_at DESC")->fetch_all(MYSQLI_ASSOC);
    }
    
    public function approvePatient($patientId, $adminId) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("UPDATE patients SET status='active', validated_at=NOW(), validated_by=? WHERE patient_id=?");
        $stmt->bind_param("ii", $adminId, $patientId);
        return $stmt->execute();
    }
    
    public function rejectPatient($patientId, $adminId) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("UPDATE patients SET status='inactive', validated_at=NOW(), validated_by=? WHERE patient_id=?");
        $stmt->bind_param("ii", $adminId, $patientId);
        return $stmt->execute();
    }
    
    // Therapist Management
    public function getAllTherapists() {
        $conn = getDBConnection();
        return $conn->query("SELECT * FROM therapists ORDER BY created_at DESC")->fetch_all(MYSQLI_ASSOC);
    }
    
    public function getPendingTherapists() {
        $conn = getDBConnection();
        return $conn->query("SELECT * FROM therapists WHERE status='pending' ORDER BY created_at DESC")->fetch_all(MYSQLI_ASSOC);
    }
    
    public function approveTherapist($therapistId, $adminId) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("UPDATE therapists SET status='active', validated_at=NOW(), validated_by=? WHERE therapist_id=?");
        $stmt->bind_param("ii", $adminId, $therapistId);
        return $stmt->execute();
    }
    
    public function rejectTherapist($therapistId, $adminId) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("UPDATE therapists SET status='inactive', validated_at=NOW(), validated_by=? WHERE therapist_id=?");
        $stmt->bind_param("ii", $adminId, $therapistId);
        return $stmt->execute();
    }
    
    // Exercise Management
    public function getExerciseSets() {
        $conn = getDBConnection();
        $sets = $conn->query("SELECT * FROM exercise_sets ORDER BY set_name")->fetch_all(MYSQLI_ASSOC);
        foreach ($sets as &$set) {
            $stmt = $conn->prepare("SELECT e.* FROM set_exercises se JOIN exercises e ON se.exercise_id = e.exercise_id WHERE se.set_id = ? ORDER BY se.order_in_set");
            $stmt->bind_param("i", $set['set_id']);
            $stmt->execute();
            $set['exercises'] = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        }
        return $sets;
    }
    
    public function getAllExercises() {
        $conn = getDBConnection();
        return $conn->query("SELECT * FROM exercises ORDER BY exercise_name")->fetch_all(MYSQLI_ASSOC);
    }
    
    public function addExercise($name, $description, $instructions, $difficulty, $reps, $sets, $hold, $video_path = '') {
        $conn = getDBConnection();
        $stmt = $conn->prepare("INSERT INTO exercises (exercise_name, description, instructions, difficulty, reps_default, sets_default, hold_duration_sec, video_path) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("ssssiiis", $name, $description, $instructions, $difficulty, $reps, $sets, $hold, $video_path);
        $stmt->execute();
        return $conn->insert_id;
    }
    
    public function addExerciseToSet($setId, $exerciseId, $order) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("INSERT INTO set_exercises (set_id, exercise_id, order_in_set) VALUES (?,?,?)");
        $stmt->bind_param("iii", $setId, $exerciseId, $order);
        return $stmt->execute();
    }
    
    public function removeExerciseFromSet($setId, $exerciseId) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("DELETE FROM set_exercises WHERE set_id=? AND exercise_id=?");
        $stmt->bind_param("ii", $setId, $exerciseId);
        return $stmt->execute();
    }
    
    public function createExerciseSet($name, $condition, $desc, $createdBy) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("INSERT INTO exercise_sets (set_name, condition_target, description, created_by) VALUES (?,?,?,?)");
        $stmt->bind_param("sssi", $name, $condition, $desc, $createdBy);
        $stmt->execute();
        return $conn->insert_id;
    }
    
    public function deleteExerciseSet($setId) {
        $conn = getDBConnection();
        $stmt = $conn->prepare("DELETE FROM exercise_sets WHERE set_id=?");
        $stmt->bind_param("i", $setId);
        return $stmt->execute();
    }
    
    // Reporting Functions
    public function getReportingAnalytics() {
        $conn = getDBConnection();
        return [
            'top_conditions' => $conn->query("SELECT finger_condition, COUNT(*) as count FROM patients WHERE finger_condition IS NOT NULL GROUP BY finger_condition ORDER BY count DESC LIMIT 5")->fetch_all(MYSQLI_ASSOC)
        ];
    }
    
    public function getRegistrationTrends() {
        $conn = getDBConnection();
        $trends = ['labels' => [], 'patients' => [], 'therapists' => []];
        for ($i = 5; $i >= 0; $i--) {
            $month = date('Y-m', strtotime("-$i months"));
            $monthName = date('M', strtotime("-$i months"));
            $patients = $conn->query("SELECT COUNT(*) as count FROM patients WHERE DATE_FORMAT(created_at, '%Y-%m') = '$month'")->fetch_assoc()['count'];
            $therapists = $conn->query("SELECT COUNT(*) as count FROM therapists WHERE DATE_FORMAT(created_at, '%Y-%m') = '$month'")->fetch_assoc()['count'];
            $trends['labels'][] = $monthName;
            $trends['patients'][] = $patients;
            $trends['therapists'][] = $therapists;
        }
        return $trends;
    }
    
    public function getPatientConditions() {
        $conn = getDBConnection();
        $result = $conn->query("SELECT finger_condition, COUNT(*) as count FROM patients WHERE finger_condition IS NOT NULL AND finger_condition != '' GROUP BY finger_condition ORDER BY count DESC LIMIT 5");
        $conditions = [];
        $colors = ['#667eea', '#764ba2', '#10b981', '#f59e0b', '#ef4444'];
        $i = 0;
        while ($row = $result->fetch_assoc()) {
            $conditions[] = ['condition' => $row['finger_condition'], 'count' => $row['count'], 'color' => $colors[$i % 5]];
            $i++;
        }
        return $conditions;
    }
    
    public function getPatientStatusStats() {
        $conn = getDBConnection();
        return [
            'active' => $conn->query("SELECT COUNT(*) as count FROM patients WHERE status = 'active'")->fetch_assoc()['count'],
            'pending' => $conn->query("SELECT COUNT(*) as count FROM patients WHERE status = 'pending'")->fetch_assoc()['count'],
            'inactive' => $conn->query("SELECT COUNT(*) as count FROM patients WHERE status = 'inactive'")->fetch_assoc()['count']
        ];
    }
    
    public function getTopTherapists() {
        $conn = getDBConnection();
        return $conn->query("
            SELECT t.full_name, t.staff_id, COUNT(p.patient_id) as patient_count,
                   COALESCE(AVG(p.compliance_rate), 0) as avg_compliance
            FROM therapists t
            LEFT JOIN patients p ON t.therapist_id = p.therapist_id
            WHERE t.status = 'active'
            GROUP BY t.therapist_id
            ORDER BY patient_count DESC
            LIMIT 5
        ")->fetch_all(MYSQLI_ASSOC);
    }
    
    public function getWeeklyCompliance() {
        $conn = getDBConnection();
        $compliance = ['labels' => [], 'data' => []];
        for ($i = 5; $i >= 0; $i--) {
            $weekStart = date('Y-m-d', strtotime("-$i weeks"));
            $weekEnd = date('Y-m-d', strtotime("-$i weeks +6 days"));
            $weekLabel = 'Week ' . (6 - $i + 1);
            $result = $conn->query("
                SELECT COALESCE(AVG(daily_rate), 0) as avg_compliance
                FROM (
                    SELECT exercise_date, 
                           (SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) as daily_rate
                    FROM daily_exercise_tracking
                    WHERE exercise_date BETWEEN '$weekStart' AND '$weekEnd'
                    GROUP BY exercise_date
                ) as daily
            ");
            $compliance['labels'][] = $weekLabel;
            $compliance['data'][] = round($result->fetch_assoc()['avg_compliance'], 1);
        }
        return $compliance;
    }
    
    public function getExerciseUsage() {
        $conn = getDBConnection();
        $result = $conn->query("
            SELECT e.exercise_name, COUNT(det.tracking_id) as usage_count
            FROM exercises e
            LEFT JOIN set_exercises se ON e.exercise_id = se.exercise_id
            LEFT JOIN daily_exercise_tracking det ON det.exercise_id = e.exercise_id
            GROUP BY e.exercise_id
            ORDER BY usage_count DESC
            LIMIT 6
        ");
        $usage = ['labels' => [], 'data' => []];
        while ($row = $result->fetch_assoc()) {
            $usage['labels'][] = $row['exercise_name'];
            $usage['data'][] = $row['usage_count'];
        }
        return $usage;
    }
    
    public function getDifficultyDistribution() {
        $conn = getDBConnection();
        return [
            'beginner' => $conn->query("SELECT COUNT(*) as count FROM exercises WHERE difficulty = 'beginner'")->fetch_assoc()['count'],
            'intermediate' => $conn->query("SELECT COUNT(*) as count FROM exercises WHERE difficulty = 'intermediate'")->fetch_assoc()['count'],
            'advanced' => $conn->query("SELECT COUNT(*) as count FROM exercises WHERE difficulty = 'advanced'")->fetch_assoc()['count']
        ];
    }
    
    public function getTopPatients() {
        $conn = getDBConnection();
        return $conn->query("
            SELECT p.full_name, p.finger_condition, p.compliance_rate, p.streak, p.pain_score,
                   t.full_name as therapist_name
            FROM patients p
            LEFT JOIN therapists t ON p.therapist_id = t.therapist_id
            WHERE p.status = 'active' AND p.compliance_rate > 0
            ORDER BY p.compliance_rate DESC
            LIMIT 10
        ")->fetch_all(MYSQLI_ASSOC);
    }
}

$functions = new Functions();
?>