-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 23, 2026 at 05:07 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `flexifinger`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_patient_progress` (IN `p_patient_id` INT)   BEGIN
    SELECT 
        p.patient_id,
        p.full_name,
        p.streak,
        p.compliance_rate,
        p.pain_score AS current_pain,
        COUNT(DISTINCT DATE(det.exercise_date)) AS days_exercised,
        AVG(det.pain_score_after) AS avg_pain_after,
        (SELECT pain_score FROM pain_score_history ph 
         WHERE ph.patient_id = p_patient_id 
         ORDER BY ph.recorded_date DESC LIMIT 1) AS last_pain_score,
        (SELECT pain_score FROM pain_score_history ph 
         WHERE ph.patient_id = p_patient_id 
         AND ph.recorded_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
         ORDER BY ph.recorded_date ASC LIMIT 1) AS pain_score_7days_ago
    FROM patients p
    LEFT JOIN daily_exercise_tracking det ON p.patient_id = det.patient_id
    WHERE p.patient_id = p_patient_id
    GROUP BY p.patient_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_therapist_patients` (IN `p_therapist_id` INT)   BEGIN
    SELECT 
        p.patient_id,
        p.full_name,
        p.email,
        p.phone,
        p.finger_condition,
        p.pain_score,
        p.streak,
        p.compliance_rate,
        p.daily_status,
        p.status,
        p.program_start_date,
        es.set_name AS exercise_set_name,
        sch.frequency,
        sch.start_date,
        sch.end_date,
        (SELECT COUNT(*) FROM daily_exercise_tracking det 
         WHERE det.patient_id = p.patient_id AND det.status = 'completed') AS total_completed
    FROM patients p
    LEFT JOIN exercise_schedules sch ON p.patient_id = sch.patient_id AND sch.status = 'active'
    LEFT JOIN exercise_sets es ON sch.exercise_set_id = es.set_id
    WHERE p.therapist_id = p_therapist_id
    ORDER BY p.daily_status, p.full_name;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_patient_stats` (IN `p_patient_id` INT)   BEGIN
    DECLARE v_compliance DECIMAL(5,2);
    DECLARE v_streak INT;
    
    -- Calculate compliance rate (last 30 days)
    SELECT 
        COALESCE(
            ROUND(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2),
            0
        ) INTO v_compliance
    FROM daily_exercise_tracking
    WHERE patient_id = p_patient_id 
    AND exercise_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
    -- Calculate current streak
    SELECT COUNT(*) INTO v_streak
    FROM (
        SELECT exercise_date,
               ROW_NUMBER() OVER (ORDER BY exercise_date DESC) as rn
        FROM daily_exercise_tracking
        WHERE patient_id = p_patient_id 
        AND status = 'completed'
        AND exercise_date <= CURDATE()
        GROUP BY exercise_date
    ) t
    WHERE DATEDIFF(CURDATE(), exercise_date) = rn - 1;
    
    -- Update patient stats
    UPDATE patients 
    SET compliance_rate = v_compliance,
        streak = COALESCE(v_streak, 0),
        daily_status = CASE 
            WHEN EXISTS (
                SELECT 1 FROM daily_exercise_tracking 
                WHERE patient_id = p_patient_id 
                AND exercise_date = CURDATE() 
                AND status = 'completed'
            ) THEN 'Completed today'
            WHEN EXISTS (
                SELECT 1 FROM daily_exercise_tracking 
                WHERE patient_id = p_patient_id 
                AND exercise_date = CURDATE() 
                AND status = 'pending'
            ) THEN 'Pending today'
            ELSE 'Missed today'
        END
    WHERE patient_id = p_patient_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `log_id` int(11) NOT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`log_id`, `admin_id`, `action`, `details`, `ip_address`, `created_at`) VALUES
(1, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-02-10 12:36:03'),
(2, 1, 'Admin logout', 'Admin logged out', '::1', '2026-02-10 12:37:23'),
(3, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-02-10 12:38:13'),
(4, 1, 'Patient approved', 'Approved patient ID: 1', '::1', '2026-02-10 12:38:45'),
(5, 1, 'Admin logout', 'Admin logged out', '::1', '2026-02-10 12:39:28'),
(6, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-02-10 12:43:59'),
(7, 1, 'Therapist approved', 'Approved therapist ID: 1', '::1', '2026-02-10 13:03:35'),
(8, 1, 'Patient validated', 'Validated patient Ahmad Zaki', '192.168.1.100', '2026-02-09 13:10:25'),
(9, 1, 'Therapist added', 'Added new therapist Dr. Siti Nur', '192.168.1.100', '2026-02-08 13:10:25'),
(10, 1, 'Exercise set created', 'Created Carpal Tunnel Relief set', '192.168.1.100', '2026-02-07 13:10:25'),
(11, 1, 'Report generated', 'Generated monthly compliance report', '192.168.1.100', '2026-02-06 13:10:25'),
(12, 1, 'Patient assigned', 'Assigned patient to therapist', '192.168.1.100', '2026-02-05 13:10:25'),
(13, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-02-21 00:23:59'),
(14, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-02-21 01:41:03'),
(15, 1, 'Admin logout', 'Admin logged out', '::1', '2026-02-21 01:41:38'),
(16, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-04 22:57:07'),
(17, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-08 11:11:23'),
(18, 1, 'Patient approved', 'Approved patient ID: 6', '::1', '2026-04-08 11:13:03'),
(19, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-08 11:24:04'),
(20, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-08 11:24:06'),
(21, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-16 10:42:19'),
(22, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-18 18:20:35'),
(23, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-18 18:25:18'),
(24, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-21 18:33:45'),
(25, 1, 'Patient approved', 'Approved patient ID: 15', '::1', '2026-04-21 19:17:24'),
(26, 1, 'Therapist approved', 'Approved therapist ID: 5', '::1', '2026-04-21 21:33:17'),
(27, 1, 'Patient approved', 'Approved patient ID: 16', '::1', '2026-04-21 21:42:16'),
(28, 1, 'Therapist approved', 'Approved therapist ID: 6', '::1', '2026-04-21 21:46:38'),
(29, 1, 'Patient approved', 'Approved patient ID: 13', '::1', '2026-04-21 21:47:35'),
(30, 1, 'Therapist approved', 'Approved therapist ID: 7', '::1', '2026-04-21 23:15:02'),
(31, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-22 01:58:51'),
(32, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 01:58:53'),
(33, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-22 02:06:11'),
(34, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 02:06:27'),
(35, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 09:58:43'),
(36, 1, 'Patient approved', 'Approved patient ID: 17', '::1', '2026-04-22 10:04:52'),
(37, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 11:24:48'),
(38, 1, 'Patient approved', 'Approved patient ID: 18', '::1', '2026-04-22 11:37:35'),
(39, 1, 'Patient approved', 'Approved patient ID: 19', '::1', '2026-04-22 11:43:12'),
(40, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 18:52:57'),
(41, 1, 'Patient approved', 'Approved patient ID: 18', '::1', '2026-04-22 18:55:55'),
(42, 1, 'Patient approved', 'Approved patient ID: 21', '::1', '2026-04-22 21:40:26'),
(43, 1, 'Patient approved', 'Approved patient ID: 20', '::1', '2026-04-22 22:29:42'),
(44, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-22 22:31:22'),
(45, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 22:32:35'),
(46, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-22 22:33:11'),
(47, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-22 22:33:26'),
(48, 1, 'Admin logout', 'Admin logged out', '::1', '2026-04-22 22:40:08'),
(49, 1, 'Admin login', 'Admin logged in from IP: ::1', '::1', '2026-04-23 00:02:42');

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `centre_name` varchar(255) DEFAULT NULL,
  `centre_address` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `full_name`, `email`, `password_hash`, `phone`, `centre_name`, `centre_address`, `created_at`) VALUES
(1, 'System Administrator', 'admin@flexifinger.com', '$2y$10$K.3CbL/V9I8h5Jb5K0xY6e2qY6L7a9B8c0D1e2F3g4H5i6J7k8L9m0N1o2P', '0192791425', 'UMPSA Health Centre', '', '2026-02-10 12:31:43');

-- --------------------------------------------------------

--
-- Table structure for table `api_tokens`
--

CREATE TABLE `api_tokens` (
  `token_id` int(11) NOT NULL,
  `user_type` enum('patient','therapist','admin') NOT NULL,
  `user_id` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `refresh_token` varchar(255) DEFAULT NULL,
  `device_info` text DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `last_used` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_exercise_tracking`
--

CREATE TABLE `daily_exercise_tracking` (
  `tracking_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `schedule_id` int(11) DEFAULT NULL,
  `exercise_date` date NOT NULL,
  `status` enum('pending','completed','missed','skipped') DEFAULT 'pending',
  `completed_at` datetime DEFAULT NULL,
  `pain_score_before` int(11) DEFAULT NULL,
  `pain_score_after` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `daily_exercise_tracking`
--

INSERT INTO `daily_exercise_tracking` (`tracking_id`, `patient_id`, `schedule_id`, `exercise_date`, `status`, `completed_at`, `pain_score_before`, `pain_score_after`, `notes`, `created_at`) VALUES
(1, 17, 5, '2026-04-22', 'completed', '2026-04-22 10:53:01', NULL, 10, '', '2026-04-22 10:43:39');

--
-- Triggers `daily_exercise_tracking`
--
DELIMITER $$
CREATE TRIGGER `trg_after_exercise_complete` AFTER UPDATE ON `daily_exercise_tracking` FOR EACH ROW BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        CALL sp_update_patient_stats(NEW.patient_id);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `exercises`
--

CREATE TABLE `exercises` (
  `exercise_id` int(11) NOT NULL,
  `exercise_name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `instructions` text DEFAULT NULL,
  `difficulty` enum('beginner','intermediate','advanced') DEFAULT 'beginner',
  `reps_default` int(11) DEFAULT 10,
  `sets_default` int(11) DEFAULT 3,
  `hold_duration_sec` int(11) DEFAULT 5,
  `video_url` varchar(500) DEFAULT NULL,
  `thumbnail_path` varchar(500) DEFAULT NULL COMMENT 'Path to exercise thumbnail image',
  `video_path` varchar(500) DEFAULT NULL COMMENT 'Local path or URL to video file',
  `media_type` enum('local','youtube','vimeo','external') DEFAULT 'local',
  `media_asset_id` int(11) DEFAULT NULL,
  `duration_seconds` int(11) DEFAULT 0 COMMENT 'Video duration in seconds',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `exercises`
--

INSERT INTO `exercises` (`exercise_id`, `exercise_name`, `description`, `instructions`, `difficulty`, `reps_default`, `sets_default`, `hold_duration_sec`, `video_url`, `thumbnail_path`, `video_path`, `media_type`, `media_asset_id`, `duration_seconds`, `created_at`) VALUES
(1, 'Finger Taps', 'This exercise is designed to train each finger to move independently, enhancing coordination and fine motor control.\r\nBy lifting and tapping each fingertip in a controlled manner, you strengthen the small intrinsic muscles of the hand, promote healthy tendon gliding, and prevent stiffness', '1. Sit at a table and rest your forearm on the tabletop.\r\n2. Move your fingers slowly, one finger at a time, with your\r\nhand relaxed, making a wave with your fingers.', 'beginner', 5, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:12:34'),
(2, 'Finger Abduction and Adduction', 'This exercise helps improve finger mobility and strength. It involves spreading the fingers apart and bringing them back together, which enhances flexibility, coordination, and overall hand function', '1. Sit comfortably with your hand resting on a table\r\n2. Slowly spread your fingers apart as far as comfortable\r\n3. Hold the position for 3 seconds\r\n4. Slowly bring your fingers back together\r\n5. Repeat 5 times', 'beginner', 3, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:14:16'),
(3, 'Knuckle bend', 'Knuckle bending exercises improve flexibility, strengthen muscles, prevent stiffness, enhance hand coordination, and promote functional independence for daily activities like gripping and writing', '1. Sit or stand comfortably with your hand resting on a\r\ntable or in the air\r\n2. Keep your palm facing up and fingers fully straight\r\n3. Without moving your wrist, bend all fingers at the knuckle joints (where fingers meet the palm)\r\n4. Keep the middle and tip joints straight - only the big knuckles should bend\r\n5. Hold the bent position for 1 second\r\n6. Slowly straighten your fingers back to the starting position\r\n7. Repeat 5 times', 'beginner', 3, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:15:53'),
(4, 'Thumb and Lilttle Finger Abduction/Adduction', 'The Thumb and Little Finger Abduction-Adduction Exercise is a simple but effective hand movement designed to strengthen and increase mobility of the thumb and little finger. This exercise targets intrinsic hand muscles, promotes finger coordination, and supports overall hand function', '1. Keep your fingers together and wrist straight\r\n2. Keeping the palm flat, slide your thumb slowly outward\r\n(away from the other fingers)\r\n﻿﻿3. Slide the thumb back so it touches the side of your index finger\r\n4. ﻿﻿With your thumb now in place, slide your little finger\r\n(pinky) slowly outward (away from the other fingers)\r\n5. ﻿﻿Slide the pinky back so it touches the ring finger\r\n6. ﻿﻿Perform 7 cycles in a row', 'beginner', 7, 3, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:17:24'),
(5, 'Middle joint finger flexion with open palm', 'This exercise focuses on bending the fingers at the middle joints (proximal interphalangeal joints) while keeping the palm flat and extended on a stable surface, such as a table. It targets the small muscles and tendons in the fingers responsible for fine motor control and gripping function, which are often affected after hand injuries, surgeries, or neurological conditions such as stroke', '1. Sit comfortably at a table with your forearm resting on\r\nthe surface\r\n2. Place your hand palm-down on the table, fingers\r\nextended and relaxed\r\n3. Slowly bend each finger at the middle joint (PIP joint), while keeping the fingertips and knuckles as still as possible. The fingertip may lift slightly, but focus on isolating the bend at the middle joint\r\n4. Hold the bend for 1 second, then return the finger to a flat, extended position.\r\n5. Repeat 5 times', 'beginner', 3, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:18:27'),
(6, 'Thumb Flexion to Each Finger', 'Place your hand in a comfortable position. Bring your thumb towards the tip of the index finger. Slowly apply pressure with the thumb, bending it downward until it reaches the center of the palm. Extend all fingers outward, like a fan. Repeat this movement with the middle finger. Touch the thumb to the tip of the middle finger and apply a slow, gentle squeeze. Gradually slide the fingers downward', '1. Touch the tip of the index finger with your thumb and\r\ngently slide down while maintaining pressure\r\n2. Touch the tip of the middle finger with your thumb and gently slide down while maintaining pressure. Try to keep the thumb as close to the center of the palm as possible\r\n3. Continue the same movements with the other fingers, maintaining pressure as you slide down each finger\r\n4. Repeat 10 times', 'beginner', 4, 10, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:19:52'),
(7, 'Thumb Flextion', 'Bend thumb across the palm', '1. Place your hand palm-up or flat on a table\r\n2. Slowly bend your thumb across your palm toward the\r\nbase of your little finger\r\n3. Hold the position for 1 second\r\n4. Straighten your thumb back to the starting position\r\n5. Repeat 5 times', 'beginner', 5, 3, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:22:04');

-- --------------------------------------------------------

--
-- Table structure for table `exercise_logs`
--

CREATE TABLE `exercise_logs` (
  `log_id` int(11) NOT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `exercise_id` int(11) DEFAULT NULL,
  `date_completed` date DEFAULT NULL,
  `reps_completed` int(11) DEFAULT NULL,
  `sets_completed` int(11) DEFAULT NULL,
  `pain_score` int(11) DEFAULT NULL,
  `duration_minutes` int(11) DEFAULT NULL,
  `logged_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exercise_schedules`
--

CREATE TABLE `exercise_schedules` (
  `schedule_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `exercise_set_id` int(11) NOT NULL,
  `therapist_id` int(11) NOT NULL,
  `frequency` enum('Daily','2x Weekly','3x Weekly','Weekly','Custom') DEFAULT 'Daily',
  `custom_days` varchar(50) DEFAULT NULL COMMENT 'Comma separated days: mon,tue,wed',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `reminder_time` time DEFAULT '21:00:00',
  `send_reminder` tinyint(1) DEFAULT 1,
  `alert_on_missed` tinyint(1) DEFAULT 1,
  `total_sessions` int(11) DEFAULT 30,
  `completed_sessions` int(11) DEFAULT 0,
  `status` enum('active','paused','completed','cancelled') DEFAULT 'active',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `exercise_schedules`
--

INSERT INTO `exercise_schedules` (`schedule_id`, `patient_id`, `exercise_set_id`, `therapist_id`, `frequency`, `custom_days`, `start_date`, `end_date`, `reminder_time`, `send_reminder`, `alert_on_missed`, `total_sessions`, `completed_sessions`, `status`, `created_at`, `updated_at`) VALUES
(4, 14, 6, 2, 'Daily', NULL, '2026-04-21', '2026-04-29', '21:00:00', 1, 1, 30, 2, 'active', '2026-04-22 00:14:14', '2026-04-22 01:33:15'),
(5, 17, 16, 2, 'Daily', NULL, '2026-04-23', '2026-04-24', '21:00:00', 1, 1, 30, 3, 'active', '2026-04-22 10:42:11', '2026-04-22 10:53:01'),
(6, 19, 9, 2, 'Daily', NULL, '2026-04-22', '2026-04-30', '21:00:00', 1, 1, 30, 0, 'active', '2026-04-22 12:09:02', '2026-04-22 12:09:02');

-- --------------------------------------------------------

--
-- Table structure for table `exercise_sets`
--

CREATE TABLE `exercise_sets` (
  `set_id` int(11) NOT NULL,
  `set_name` varchar(255) NOT NULL,
  `condition_target` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `exercise_sets`
--

INSERT INTO `exercise_sets` (`set_id`, `set_name`, `condition_target`, `description`, `created_by`, `created_at`) VALUES
(6, 'Gamer\'s Hand Relief', 'Gaming-related strain', 'Exercises for gamers and heavy mouse users', NULL, '2026-02-10 13:02:32'),
(9, 'Stiff Finger', 'Finger stiffness, reduced flexibility', 'This set focuses on improving finger mobility and flexibility by gently stretching and activating all finger joints. It is suitable for individuals experiencing stiffness due to inactivity or prolonged hand use.', 1, '2026-04-22 02:28:05'),
(10, 'Muscle Fatigue', 'Hand fatigue, muscle tiredness', 'Designed to reduce muscle fatigue and improve endurance in the hand. These exercises promote controlled movement and help restore strength after repetitive activities.', 1, '2026-04-22 02:29:23'),
(11, 'Joint Stiffness', 'Stiff joints, limited range of motion', 'This set targets joint flexibility and helps loosen stiff finger joints, especially after long periods of rest or in the morning.', 1, '2026-04-22 02:30:11'),
(12, 'Paresthesia (Numbness / Tingling)', 'Numbness, tingling sensation', 'These exercises help stimulate nerves and improve blood circulation in the hand, reducing numbness and tingling sensations.', 1, '2026-04-22 02:31:08'),
(13, 'Hand Weakness', 'Weak grip, reduced hand strength', 'This set strengthens the muscles of the hand and fingers to improve grip strength and overall hand function.', 1, '2026-04-22 02:32:02'),
(14, 'Trigger Finger', 'Finger locking, clicking sensation', 'A gentle exercise set designed to improve tendon movement and reduce stiffness associated with trigger finger. Movements should be performed slowly and without force.', 1, '2026-04-22 02:33:20'),
(15, 'Typing Recovery', 'Strain from typing, keyboard overuse', 'Ideal for individuals who spend long hours typing. This set reduces strain, improves finger coordination, and restores flexibility.', 1, '2026-04-22 02:34:03'),
(16, 'Phone / Scrolling Strain', 'Thumb strain, excessive phone use', 'Targets thumb fatigue and stiffness caused by prolonged phone usage, scrolling, or texting.', 1, '2026-04-22 02:35:35'),
(17, 'Heavy Lifting / Grip Strength', 'Post-workout recovery, grip strengthening Description:', 'Designed for individuals who frequently lift heavy objects or perform strength training. Helps improve grip power and prevent stiffness.', 1, '2026-04-22 02:36:31');

-- --------------------------------------------------------

--
-- Table structure for table `media_assets`
--

CREATE TABLE `media_assets` (
  `asset_id` int(11) NOT NULL,
  `asset_name` varchar(255) NOT NULL,
  `asset_type` enum('image','video','document','audio') NOT NULL,
  `category` enum('exercise','profile','logo','banner','other') DEFAULT 'exercise',
  `file_path` varchar(500) NOT NULL,
  `file_size` int(11) DEFAULT 0,
  `mime_type` varchar(100) DEFAULT NULL,
  `width` int(11) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `duration_seconds` int(11) DEFAULT NULL COMMENT 'For videos',
  `thumbnail_path` varchar(500) DEFAULT NULL,
  `external_url` varchar(500) DEFAULT NULL COMMENT 'For YouTube/Vimeo videos',
  `is_active` tinyint(1) DEFAULT 1,
  `uploaded_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `media_assets`
--

INSERT INTO `media_assets` (`asset_id`, `asset_name`, `asset_type`, `category`, `file_path`, `file_size`, `mime_type`, `width`, `height`, `duration_seconds`, `thumbnail_path`, `external_url`, `is_active`, `uploaded_by`, `created_at`, `updated_at`) VALUES
(1, 'App Logo', 'image', 'logo', 'assets/images/logo.png', 0, 'image/png', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(2, 'Finger Flexion Video', 'video', 'exercise', 'assets/videos/finger_flexion.mp4', 0, 'video/mp4', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(3, 'Grip Strength Video', 'video', 'exercise', 'assets/videos/grip_strength.mp4', 0, 'video/mp4', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(4, 'Thumb Stretch Video', 'video', 'exercise', 'assets/videos/thumb_stretch.mp4', 0, 'video/mp4', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(5, 'Finger Abduction Video', 'video', 'exercise', 'assets/videos/finger_abduction.mp4', 0, 'video/mp4', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(6, 'Default Avatar', 'image', 'profile', 'assets/images/profiles/default_avatar.png', 0, 'image/png', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(7, 'Onboarding Image 1', 'image', 'banner', 'assets/images/display1.png', 0, 'image/png', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(8, 'Onboarding Image 2', 'image', 'banner', 'assets/images/display2.png', 0, 'image/png', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(9, 'Onboarding Image 3', 'image', 'banner', 'assets/images/display3.png', 0, 'image/png', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22'),
(10, 'Onboarding Image 4', 'image', 'banner', 'assets/images/display4.png', 0, 'image/png', NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-21 02:32:22', '2026-04-21 02:32:22');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `user_type` enum('patient','therapist','admin') NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('reminder','alert','info','success','warning') DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT 0,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Additional JSON data' CHECK (json_valid(`data`)),
  `created_at` datetime DEFAULT current_timestamp(),
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notification_id`, `user_type`, `user_id`, `title`, `message`, `type`, `is_read`, `data`, `created_at`, `read_at`) VALUES
(1, 'patient', 2, 'Exercise Reminder', 'Time for your daily finger exercises!', 'reminder', 0, NULL, '2026-04-21 02:30:52', NULL),
(2, 'patient', 2, 'Streak Achieved!', 'Congratulations! You have a 6-day streak!', 'success', 0, NULL, '2026-04-21 02:30:52', NULL),
(3, 'therapist', 2, 'Patient Update', 'Nurul Iman completed today\'s exercises', 'info', 0, NULL, '2026-04-21 02:30:52', NULL),
(4, 'patient', 3, 'Exercise Reminder', 'Don\'t forget your exercises today!', 'reminder', 0, NULL, '2026-04-21 02:30:52', NULL),
(5, 'therapist', 3, 'New Patient Assigned', 'Patient shuhada has been assigned to you.', 'success', 0, NULL, '2026-04-21 19:42:42', NULL),
(6, 'therapist', 5, 'New Patient Assigned', 'Patient nur farhana has been assigned to you.', 'success', 0, NULL, '2026-04-21 21:42:31', NULL),
(7, 'therapist', 6, 'New Patient Assigned', 'Patient New Patient has been assigned to you.', 'success', 0, NULL, '2026-04-21 21:47:43', NULL),
(8, 'therapist', 2, 'Exercise Completed', 'ayam Patient completed today\'s exercises. Pain score: 10/10', 'success', 0, NULL, '2026-04-22 00:52:49', NULL),
(9, 'therapist', 2, 'New Patient Assigned', 'Patient darwisya sofea has been assigned to you.', 'success', 0, NULL, '2026-04-22 10:05:32', NULL),
(10, 'therapist', 2, 'New Patient Assigned', 'Patient sofea has been assigned to you.', 'success', 0, NULL, '2026-04-22 11:40:34', NULL),
(11, 'therapist', 2, 'New Patient Assigned', 'Patient fatin has been assigned to you.', 'success', 0, NULL, '2026-04-22 12:00:01', NULL),
(12, 'therapist', 2, 'New Patient Assigned', 'Patient nur farhana has been assigned to you.', 'success', 0, NULL, '2026-04-22 18:56:31', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `pain_score_history`
--

CREATE TABLE `pain_score_history` (
  `pain_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `pain_score` int(11) NOT NULL CHECK (`pain_score` between 1 and 10),
  `recorded_date` date NOT NULL,
  `recorded_time` time DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `session_type` enum('pre-exercise','post-exercise','daily-check') DEFAULT 'post-exercise',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pain_score_history`
--

INSERT INTO `pain_score_history` (`pain_id`, `patient_id`, `pain_score`, `recorded_date`, `recorded_time`, `notes`, `session_type`, `created_at`) VALUES
(9, 14, 10, '2026-04-22', NULL, NULL, 'daily-check', '2026-04-22 00:52:49'),
(10, 14, 10, '2026-04-22', NULL, NULL, 'post-exercise', '2026-04-22 00:52:49'),
(11, 14, 4, '2026-04-22', NULL, NULL, 'daily-check', '2026-04-22 01:32:20'),
(12, 17, 9, '2026-04-22', NULL, NULL, 'daily-check', '2026-04-22 10:43:39'),
(13, 17, 3, '2026-04-22', NULL, NULL, 'daily-check', '2026-04-22 10:49:50'),
(14, 17, 10, '2026-04-22', NULL, NULL, 'daily-check', '2026-04-22 10:53:01');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `reset_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `token` varchar(100) NOT NULL,
  `otp_code` varchar(6) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`reset_id`, `email`, `token`, `otp_code`, `expires_at`, `created_at`) VALUES
(8, 'admin@flexifinger.com', 'ccb31563062ece6b789c50792d41b5d2ad422a7df36630bcf2', '892586', '2026-04-22 22:47:25', '2026-04-22 22:32:25');

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `patient_id` int(11) NOT NULL,
  `patient_ic` varchar(20) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `profile_picture` varchar(500) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `finger_condition` varchar(255) DEFAULT NULL,
  `therapist_id` int(11) DEFAULT NULL,
  `program_start_date` date DEFAULT NULL,
  `exercise_set_id` int(11) DEFAULT NULL,
  `status` enum('pending','active','inactive') DEFAULT 'pending',
  `pain_score` int(11) DEFAULT 0,
  `compliance_rate` decimal(5,2) DEFAULT 0.00,
  `streak` int(11) DEFAULT 0,
  `last_exercise` datetime DEFAULT NULL,
  `daily_status` enum('Completed today','Pending today','Missed today') DEFAULT 'Pending today',
  `created_at` datetime DEFAULT current_timestamp(),
  `validated_at` datetime DEFAULT NULL,
  `validated_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patients`
--

INSERT INTO `patients` (`patient_id`, `patient_ic`, `full_name`, `email`, `phone`, `profile_picture`, `password_hash`, `finger_condition`, `therapist_id`, `program_start_date`, `exercise_set_id`, `status`, `pain_score`, `compliance_rate`, `streak`, `last_exercise`, `daily_status`, `created_at`, `validated_at`, `validated_by`) VALUES
(13, '900202-10-5678', 'New Patient', 'newpatient@test.com', '013-9876543', NULL, '123456', 'Carpal Tunnel Syndrome', NULL, '2026-04-21', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-21 18:27:59', '2026-04-21 21:47:35', 1),
(14, '900101-10-1734', 'ayam Patient', 'ayam@test.com', '012-3476789', NULL, '123456', 'Trigger Finger', 2, '2026-04-21', NULL, 'active', 4, 0.00, 2, NULL, 'Missed today', '2026-04-21 18:37:21', NULL, NULL),
(15, '125478258745', 'shuhada', 'naktest@gmail.com', '01587216825', NULL, '123456', 'Stiff Finger', 3, '2026-04-21', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-21 19:11:27', '2026-04-21 19:17:24', 1),
(16, '054821526587', 'nur farhana', 'farhana@gmail.com', '018536745', NULL, '123456', 'Stiff Finger', 2, '2026-04-22', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-21 21:37:59', '2026-04-21 21:42:16', 1),
(17, '05184882959529', 'darwisya sofea', 'dar@test.com', '0192548524', NULL, '123456', 'Trigger Finger', 2, '2026-04-22', NULL, 'active', 10, 0.00, 3, NULL, 'Pending today', '2026-04-22 10:03:14', '2026-04-22 10:04:52', 1),
(18, '0148155555', 'sofea', 'sofea@test.com', '0185555555', NULL, '123456', 'Stiff Finger', 2, '2026-04-22', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-22 11:29:07', '2026-04-22 18:55:55', 1),
(19, '0115514525', 'fatin', 'fatin@test.com', '015115151515', NULL, '123456', 'Stiff Finger', 2, '2026-04-22', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-22 11:42:47', '2026-04-22 11:43:12', 1),
(20, '05184112241', 'Najla Rusli', 'najla06@test.com', '0154285412', NULL, '123456', 'Gaming-related strain', 2, '2026-04-22', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-22 20:04:44', '2026-04-22 22:29:42', 1),
(21, '147852369', 'Jamilah', 'jai@test.com', '0122518146', NULL, '123456', 'Gaming-related strain', NULL, NULL, NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-22 20:13:50', '2026-04-22 21:40:26', 1),
(22, '01851484154', 'Safiah Rosli', 'safiah@test.com', '019882154', NULL, '123456', 'Weak grip, reduced hand strength', NULL, NULL, NULL, 'pending', 0, 0.00, 0, NULL, 'Pending today', '2026-04-22 22:35:53', NULL, NULL);

--
-- Triggers `patients`
--
DELIMITER $$
CREATE TRIGGER `trg_after_pain_score_update` AFTER UPDATE ON `patients` FOR EACH ROW BEGIN
    IF NEW.pain_score != OLD.pain_score THEN
        INSERT INTO pain_score_history (patient_id, pain_score, recorded_date, session_type)
        VALUES (NEW.patient_id, NEW.pain_score, CURDATE(), 'daily-check');
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `patient_exercises`
--

CREATE TABLE `patient_exercises` (
  `assignment_id` int(11) NOT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `set_id` int(11) DEFAULT NULL,
  `therapist_id` int(11) DEFAULT NULL,
  `frequency` varchar(50) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `reminder_enabled` tinyint(1) DEFAULT 1,
  `reminder_time` time DEFAULT '09:00:00',
  `alert_on_missed` tinyint(1) DEFAULT 1,
  `status` enum('active','completed','cancelled') DEFAULT 'active',
  `total_sessions` int(11) DEFAULT 0,
  `completed_sessions` int(11) DEFAULT 0,
  `assigned_date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patient_progress_summary`
--

CREATE TABLE `patient_progress_summary` (
  `summary_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `week_start_date` date NOT NULL,
  `total_sessions_scheduled` int(11) DEFAULT 0,
  `sessions_completed` int(11) DEFAULT 0,
  `sessions_missed` int(11) DEFAULT 0,
  `avg_pain_score` decimal(3,1) DEFAULT 0.0,
  `compliance_rate` decimal(5,2) DEFAULT 0.00,
  `streak_days` int(11) DEFAULT 0,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patient_sessions`
--

CREATE TABLE `patient_sessions` (
  `session_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `login_time` datetime DEFAULT current_timestamp(),
  `logout_time` datetime DEFAULT NULL,
  `device_token` varchar(255) DEFAULT NULL,
  `device_type` enum('android','ios','web') DEFAULT 'android',
  `app_version` varchar(20) DEFAULT NULL,
  `last_active` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patient_sessions`
--

INSERT INTO `patient_sessions` (`session_id`, `patient_id`, `login_time`, `logout_time`, `device_token`, `device_type`, `app_version`, `last_active`) VALUES
(1, 15, '2026-04-21 19:13:13', NULL, NULL, 'android', NULL, '2026-04-21 19:13:13'),
(2, 14, '2026-04-21 19:13:55', NULL, NULL, 'android', NULL, '2026-04-21 19:13:55'),
(3, 15, '2026-04-21 19:17:11', NULL, NULL, 'android', NULL, '2026-04-21 19:17:11'),
(4, 15, '2026-04-21 19:17:53', NULL, NULL, 'android', NULL, '2026-04-21 19:17:53'),
(5, 15, '2026-04-21 19:30:43', NULL, NULL, 'android', NULL, '2026-04-21 19:30:43'),
(6, 15, '2026-04-21 19:43:48', NULL, NULL, 'android', NULL, '2026-04-21 19:43:48'),
(7, 15, '2026-04-21 20:38:41', NULL, NULL, 'android', NULL, '2026-04-21 20:38:41'),
(8, 14, '2026-04-22 00:36:19', NULL, NULL, 'android', NULL, '2026-04-22 00:36:19'),
(10, 14, '2026-04-22 00:52:10', NULL, NULL, 'android', NULL, '2026-04-22 00:52:10'),
(11, 14, '2026-04-22 01:11:28', NULL, NULL, 'android', NULL, '2026-04-22 01:11:28'),
(12, 14, '2026-04-22 01:12:59', NULL, NULL, 'android', NULL, '2026-04-22 01:12:59'),
(13, 14, '2026-04-22 01:23:39', NULL, NULL, 'android', NULL, '2026-04-22 01:23:39'),
(14, 14, '2026-04-22 01:25:27', NULL, NULL, 'android', NULL, '2026-04-22 01:25:27'),
(15, 14, '2026-04-22 01:31:56', NULL, NULL, 'android', NULL, '2026-04-22 01:31:56'),
(16, 17, '2026-04-22 10:03:56', NULL, NULL, 'android', NULL, '2026-04-22 10:03:56'),
(17, 17, '2026-04-22 10:05:45', NULL, NULL, 'android', NULL, '2026-04-22 10:05:45'),
(18, 17, '2026-04-22 10:38:47', NULL, NULL, 'android', NULL, '2026-04-22 10:38:47'),
(19, 17, '2026-04-22 10:42:42', NULL, NULL, 'android', NULL, '2026-04-22 10:42:42'),
(20, 17, '2026-04-22 10:49:01', NULL, NULL, 'android', NULL, '2026-04-22 10:49:01'),
(21, 17, '2026-04-22 10:52:31', NULL, NULL, 'android', NULL, '2026-04-22 10:52:31'),
(22, 18, '2026-04-22 11:30:59', NULL, NULL, 'android', NULL, '2026-04-22 11:30:59'),
(23, 18, '2026-04-22 11:38:54', NULL, NULL, 'android', NULL, '2026-04-22 11:38:54'),
(24, 18, '2026-04-22 11:40:14', NULL, NULL, 'android', NULL, '2026-04-22 11:40:14'),
(25, 18, '2026-04-22 11:41:01', NULL, NULL, 'android', NULL, '2026-04-22 11:41:01'),
(26, 19, '2026-04-22 12:05:22', NULL, NULL, 'android', NULL, '2026-04-22 12:05:22'),
(27, 19, '2026-04-22 12:09:40', NULL, NULL, 'android', NULL, '2026-04-22 12:09:40'),
(28, 18, '2026-04-22 18:52:28', NULL, NULL, 'android', NULL, '2026-04-22 18:52:28'),
(29, 18, '2026-04-22 18:57:14', NULL, NULL, 'android', NULL, '2026-04-22 18:57:14'),
(30, 18, '2026-04-22 19:35:49', NULL, NULL, 'android', NULL, '2026-04-22 19:35:49'),
(31, 18, '2026-04-22 19:43:54', NULL, NULL, 'android', NULL, '2026-04-22 19:43:54'),
(32, 18, '2026-04-22 21:39:28', NULL, NULL, 'android', NULL, '2026-04-22 21:39:28'),
(33, 19, '2026-04-22 21:41:07', NULL, NULL, 'android', NULL, '2026-04-22 21:41:07'),
(34, 19, '2026-04-22 21:45:21', NULL, NULL, 'android', NULL, '2026-04-22 21:45:21'),
(35, 22, '2026-04-23 00:03:23', NULL, NULL, 'android', NULL, '2026-04-23 00:03:23');

-- --------------------------------------------------------

--
-- Table structure for table `set_exercises`
--

CREATE TABLE `set_exercises` (
  `id` int(11) NOT NULL,
  `set_id` int(11) DEFAULT NULL,
  `exercise_id` int(11) DEFAULT NULL,
  `order_in_set` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `set_exercises`
--

INSERT INTO `set_exercises` (`id`, `set_id`, `exercise_id`, `order_in_set`) VALUES
(1, 9, 2, 1),
(2, 9, 1, 2),
(3, 9, 3, 3),
(4, 9, 5, 4),
(5, 10, 1, 1),
(6, 10, 7, 2),
(7, 10, 6, 3),
(8, 10, 3, 4),
(9, 11, 3, 1),
(10, 11, 5, 2),
(11, 11, 2, 3),
(12, 11, 4, 4),
(13, 12, 1, 1),
(14, 12, 2, 2),
(15, 12, 7, 3),
(16, 12, 6, 4),
(17, 13, 4, 1),
(20, 13, 3, 2),
(21, 13, 5, 3),
(22, 13, 7, 4),
(23, 14, 1, 1),
(24, 14, 3, 2),
(25, 14, 5, 3),
(26, 14, 7, 4),
(27, 15, 1, 1),
(28, 15, 3, 2),
(29, 15, 6, 3),
(30, 15, 2, 4),
(31, 6, 1, 1),
(32, 6, 3, 2),
(33, 6, 7, 3),
(34, 16, 2, 1),
(35, 16, 7, 2),
(36, 16, 6, 3),
(37, 16, 1, 4),
(38, 17, 2, 1),
(39, 17, 1, 2),
(42, 17, 5, 5),
(43, 17, 4, 6),
(44, 17, 6, 7),
(45, 17, 7, 8),
(46, 17, 3, 9),
(47, 17, 3, 10);

-- --------------------------------------------------------

--
-- Table structure for table `support_messages`
--

CREATE TABLE `support_messages` (
  `message_id` int(11) NOT NULL,
  `sender_type` enum('patient','therapist','admin') NOT NULL,
  `sender_id` int(11) NOT NULL,
  `receiver_type` enum('patient','therapist','admin') NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `parent_message_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `setting_id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `setting_type` enum('string','integer','boolean','json') DEFAULT 'string',
  `description` varchar(255) DEFAULT NULL,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`setting_id`, `setting_key`, `setting_value`, `setting_type`, `description`, `updated_at`, `updated_by`) VALUES
(1, 'app_version_android', '1.0.0', 'string', 'Current Android app version', '2026-04-21 02:30:52', NULL),
(2, 'app_version_ios', '1.0.0', 'string', 'Current iOS app version', '2026-04-21 02:30:52', NULL),
(3, 'min_app_version_android', '1.0.0', 'string', 'Minimum supported Android version', '2026-04-21 02:30:52', NULL),
(4, 'min_app_version_ios', '1.0.0', 'string', 'Minimum supported iOS version', '2026-04-21 02:30:52', NULL),
(5, 'maintenance_mode', 'false', 'boolean', 'System maintenance mode', '2026-04-21 02:30:52', NULL),
(6, 'default_reminder_time', '21:00', 'string', 'Default daily reminder time', '2026-04-21 02:30:52', NULL),
(7, 'max_pain_score', '10', 'integer', 'Maximum pain score value', '2026-04-21 02:30:52', NULL),
(8, 'session_timeout_minutes', '30', 'integer', 'User session timeout in minutes', '2026-04-21 02:30:52', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `therapists`
--

CREATE TABLE `therapists` (
  `therapist_id` int(11) NOT NULL,
  `staff_id` varchar(50) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `profile_picture` varchar(500) DEFAULT NULL,
  `whatsapp` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `centre_name` varchar(255) NOT NULL,
  `centre_type` enum('hospital','clinic','centre') DEFAULT 'clinic',
  `status` enum('pending','active','inactive') DEFAULT 'pending',
  `patient_count` int(11) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `validated_at` datetime DEFAULT NULL,
  `validated_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `therapists`
--

INSERT INTO `therapists` (`therapist_id`, `staff_id`, `full_name`, `email`, `phone`, `profile_picture`, `whatsapp`, `password_hash`, `centre_name`, `centre_type`, `status`, `patient_count`, `created_at`, `validated_at`, `validated_by`) VALUES
(2, 'TH002', 'Dr. Lee Wei', 'therapist@test.com', '012-3456789', NULL, NULL, '123456', 'Kuantan Physio Clinic', 'clinic', 'active', 6, '2026-04-21 23:25:25', NULL, NULL),
(3, 'TH003', 'Dr. Raj Kumar', 'raj@example.com', '+60173334455', NULL, '60173334455', NULL, 'Gambang Medical Centre', 'centre', 'active', 4, '2026-02-10 12:31:43', NULL, NULL),
(8, 'TH009', 'Najla Wakeel', 'najlacutie@test.com', '0214514054', NULL, '', '123456', 'Hospital Umum Sarawak', 'hospital', 'pending', 0, '2026-04-22 22:37:06', NULL, NULL),
(9, 'TH100', 'huda bin masod', 'huda@test.com', '0511515551', NULL, '', '123456', 'Physiotherapy KL', 'centre', 'pending', 0, '2026-04-23 00:06:10', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `therapist_sessions`
--

CREATE TABLE `therapist_sessions` (
  `session_id` int(11) NOT NULL,
  `therapist_id` int(11) NOT NULL,
  `login_time` datetime DEFAULT current_timestamp(),
  `logout_time` datetime DEFAULT NULL,
  `device_token` varchar(255) DEFAULT NULL,
  `device_type` enum('android','ios','web') DEFAULT 'android',
  `app_version` varchar(20) DEFAULT NULL,
  `last_active` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `therapist_sessions`
--

INSERT INTO `therapist_sessions` (`session_id`, `therapist_id`, `login_time`, `logout_time`, `device_token`, `device_type`, `app_version`, `last_active`) VALUES
(12, 2, '2026-04-21 23:44:00', NULL, NULL, 'android', NULL, '2026-04-21 23:44:00'),
(13, 2, '2026-04-21 23:59:05', NULL, NULL, 'android', NULL, '2026-04-21 23:59:05'),
(14, 2, '2026-04-22 00:06:48', NULL, NULL, 'android', NULL, '2026-04-22 00:06:48'),
(15, 2, '2026-04-22 00:09:01', NULL, NULL, 'android', NULL, '2026-04-22 00:09:01'),
(16, 2, '2026-04-22 00:13:54', NULL, NULL, 'android', NULL, '2026-04-22 00:13:54'),
(17, 2, '2026-04-22 00:25:47', NULL, NULL, 'android', NULL, '2026-04-22 00:25:47'),
(18, 2, '2026-04-22 10:39:15', NULL, NULL, 'android', NULL, '2026-04-22 10:39:15'),
(19, 2, '2026-04-22 10:44:45', NULL, NULL, 'android', NULL, '2026-04-22 10:44:45'),
(20, 2, '2026-04-22 10:50:22', NULL, NULL, 'android', NULL, '2026-04-22 10:50:22'),
(21, 2, '2026-04-22 11:56:06', NULL, NULL, 'android', NULL, '2026-04-22 11:56:06'),
(22, 2, '2026-04-22 12:06:23', NULL, NULL, 'android', NULL, '2026-04-22 12:06:23'),
(23, 2, '2026-04-22 12:21:25', NULL, NULL, 'android', NULL, '2026-04-22 12:21:25'),
(24, 2, '2026-04-22 17:35:17', NULL, NULL, 'android', NULL, '2026-04-22 17:35:17'),
(25, 2, '2026-04-22 21:48:32', NULL, NULL, 'android', NULL, '2026-04-22 21:48:32'),
(26, 2, '2026-04-23 00:04:52', NULL, NULL, 'android', NULL, '2026-04-23 00:04:52'),
(27, 9, '2026-04-23 00:06:22', NULL, NULL, 'android', NULL, '2026-04-23 00:06:22'),
(28, 2, '2026-04-23 00:22:00', NULL, NULL, 'android', NULL, '2026-04-23 00:22:00');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_patient_dashboard`
-- (See below for the actual view)
--
CREATE TABLE `v_patient_dashboard` (
`patient_id` int(11)
,`full_name` varchar(255)
,`email` varchar(255)
,`finger_condition` varchar(255)
,`pain_score` int(11)
,`streak` int(11)
,`compliance_rate` decimal(5,2)
,`daily_status` enum('Completed today','Pending today','Missed today')
,`therapist_name` varchar(255)
,`therapist_whatsapp` varchar(20)
,`current_exercise_set` varchar(255)
,`frequency` enum('Daily','2x Weekly','3x Weekly','Weekly','Custom')
,`reminder_time` time
,`total_completed_sessions` bigint(21)
,`last_pain_score` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_therapist_dashboard`
-- (See below for the actual view)
--
CREATE TABLE `v_therapist_dashboard` (
`therapist_id` int(11)
,`full_name` varchar(255)
,`email` varchar(255)
,`centre_name` varchar(255)
,`status` enum('pending','active','inactive')
,`total_patients` bigint(21)
,`active_patients` bigint(21)
,`inactive_patients` bigint(21)
,`avg_compliance` decimal(9,6)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_weekly_compliance`
-- (See below for the actual view)
--
CREATE TABLE `v_weekly_compliance` (
`patient_id` int(11)
,`full_name` varchar(255)
,`week_number` int(6)
,`total_scheduled` bigint(21)
,`completed` decimal(22,0)
,`missed` decimal(22,0)
,`compliance_rate` decimal(28,2)
);

-- --------------------------------------------------------

--
-- Structure for view `v_patient_dashboard`
--
DROP TABLE IF EXISTS `v_patient_dashboard`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_patient_dashboard`  AS SELECT `p`.`patient_id` AS `patient_id`, `p`.`full_name` AS `full_name`, `p`.`email` AS `email`, `p`.`finger_condition` AS `finger_condition`, `p`.`pain_score` AS `pain_score`, `p`.`streak` AS `streak`, `p`.`compliance_rate` AS `compliance_rate`, `p`.`daily_status` AS `daily_status`, `t`.`full_name` AS `therapist_name`, `t`.`whatsapp` AS `therapist_whatsapp`, `es`.`set_name` AS `current_exercise_set`, `sch`.`frequency` AS `frequency`, `sch`.`reminder_time` AS `reminder_time`, (select count(0) from `daily_exercise_tracking` `det` where `det`.`patient_id` = `p`.`patient_id` and `det`.`status` = 'completed') AS `total_completed_sessions`, (select `ph`.`pain_score` from `pain_score_history` `ph` where `ph`.`patient_id` = `p`.`patient_id` order by `ph`.`recorded_date` desc limit 1) AS `last_pain_score` FROM (((`patients` `p` left join `therapists` `t` on(`p`.`therapist_id` = `t`.`therapist_id`)) left join `exercise_schedules` `sch` on(`p`.`patient_id` = `sch`.`patient_id` and `sch`.`status` = 'active')) left join `exercise_sets` `es` on(`sch`.`exercise_set_id` = `es`.`set_id`)) WHERE `p`.`status` = 'active' ;

-- --------------------------------------------------------

--
-- Structure for view `v_therapist_dashboard`
--
DROP TABLE IF EXISTS `v_therapist_dashboard`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_therapist_dashboard`  AS SELECT `t`.`therapist_id` AS `therapist_id`, `t`.`full_name` AS `full_name`, `t`.`email` AS `email`, `t`.`centre_name` AS `centre_name`, `t`.`status` AS `status`, count(distinct `p`.`patient_id`) AS `total_patients`, count(distinct case when `p`.`status` = 'active' then `p`.`patient_id` end) AS `active_patients`, count(distinct case when `p`.`status` = 'inactive' then `p`.`patient_id` end) AS `inactive_patients`, avg(`p`.`compliance_rate`) AS `avg_compliance` FROM (`therapists` `t` left join `patients` `p` on(`t`.`therapist_id` = `p`.`therapist_id`)) GROUP BY `t`.`therapist_id` ;

-- --------------------------------------------------------

--
-- Structure for view `v_weekly_compliance`
--
DROP TABLE IF EXISTS `v_weekly_compliance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_weekly_compliance`  AS SELECT `p`.`patient_id` AS `patient_id`, `p`.`full_name` AS `full_name`, yearweek(`det`.`exercise_date`,0) AS `week_number`, count(0) AS `total_scheduled`, sum(case when `det`.`status` = 'completed' then 1 else 0 end) AS `completed`, sum(case when `det`.`status` = 'missed' then 1 else 0 end) AS `missed`, round(sum(case when `det`.`status` = 'completed' then 1 else 0 end) / count(0) * 100,2) AS `compliance_rate` FROM (`patients` `p` join `daily_exercise_tracking` `det` on(`p`.`patient_id` = `det`.`patient_id`)) GROUP BY `p`.`patient_id`, yearweek(`det`.`exercise_date`,0) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `api_tokens`
--
ALTER TABLE `api_tokens`
  ADD PRIMARY KEY (`token_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_user_token` (`user_type`,`user_id`);

--
-- Indexes for table `daily_exercise_tracking`
--
ALTER TABLE `daily_exercise_tracking`
  ADD PRIMARY KEY (`tracking_id`),
  ADD UNIQUE KEY `unique_patient_date` (`patient_id`,`exercise_date`),
  ADD KEY `schedule_id` (`schedule_id`),
  ADD KEY `idx_patient_tracking` (`patient_id`,`exercise_date`);

--
-- Indexes for table `exercises`
--
ALTER TABLE `exercises`
  ADD PRIMARY KEY (`exercise_id`),
  ADD KEY `media_asset_id` (`media_asset_id`);

--
-- Indexes for table `exercise_logs`
--
ALTER TABLE `exercise_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `exercise_id` (`exercise_id`);

--
-- Indexes for table `exercise_schedules`
--
ALTER TABLE `exercise_schedules`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `exercise_set_id` (`exercise_set_id`),
  ADD KEY `idx_patient_schedule` (`patient_id`,`status`),
  ADD KEY `idx_therapist_schedule` (`therapist_id`,`status`);

--
-- Indexes for table `exercise_sets`
--
ALTER TABLE `exercise_sets`
  ADD PRIMARY KEY (`set_id`);

--
-- Indexes for table `media_assets`
--
ALTER TABLE `media_assets`
  ADD PRIMARY KEY (`asset_id`),
  ADD KEY `idx_asset_type` (`asset_type`,`category`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_user_notifications` (`user_type`,`user_id`,`is_read`);

--
-- Indexes for table `pain_score_history`
--
ALTER TABLE `pain_score_history`
  ADD PRIMARY KEY (`pain_id`),
  ADD KEY `idx_patient_pain` (`patient_id`,`recorded_date`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`reset_id`);

--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
  ADD PRIMARY KEY (`patient_id`),
  ADD UNIQUE KEY `patient_ic` (`patient_ic`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `patient_exercises`
--
ALTER TABLE `patient_exercises`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `set_id` (`set_id`),
  ADD KEY `therapist_id` (`therapist_id`);

--
-- Indexes for table `patient_progress_summary`
--
ALTER TABLE `patient_progress_summary`
  ADD PRIMARY KEY (`summary_id`),
  ADD UNIQUE KEY `unique_patient_week` (`patient_id`,`week_start_date`);

--
-- Indexes for table `patient_sessions`
--
ALTER TABLE `patient_sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD KEY `patient_id` (`patient_id`);

--
-- Indexes for table `set_exercises`
--
ALTER TABLE `set_exercises`
  ADD PRIMARY KEY (`id`),
  ADD KEY `set_id` (`set_id`),
  ADD KEY `exercise_id` (`exercise_id`);

--
-- Indexes for table `support_messages`
--
ALTER TABLE `support_messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `idx_conversation` (`sender_type`,`sender_id`,`receiver_type`,`receiver_id`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `therapists`
--
ALTER TABLE `therapists`
  ADD PRIMARY KEY (`therapist_id`),
  ADD UNIQUE KEY `staff_id` (`staff_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `therapist_sessions`
--
ALTER TABLE `therapist_sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD KEY `therapist_id` (`therapist_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `api_tokens`
--
ALTER TABLE `api_tokens`
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_exercise_tracking`
--
ALTER TABLE `daily_exercise_tracking`
  MODIFY `tracking_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `exercises`
--
ALTER TABLE `exercises`
  MODIFY `exercise_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `exercise_logs`
--
ALTER TABLE `exercise_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exercise_schedules`
--
ALTER TABLE `exercise_schedules`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `exercise_sets`
--
ALTER TABLE `exercise_sets`
  MODIFY `set_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `media_assets`
--
ALTER TABLE `media_assets`
  MODIFY `asset_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `pain_score_history`
--
ALTER TABLE `pain_score_history`
  MODIFY `pain_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `reset_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `patients`
--
ALTER TABLE `patients`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `patient_exercises`
--
ALTER TABLE `patient_exercises`
  MODIFY `assignment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patient_progress_summary`
--
ALTER TABLE `patient_progress_summary`
  MODIFY `summary_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patient_sessions`
--
ALTER TABLE `patient_sessions`
  MODIFY `session_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `set_exercises`
--
ALTER TABLE `set_exercises`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT for table `support_messages`
--
ALTER TABLE `support_messages`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `therapists`
--
ALTER TABLE `therapists`
  MODIFY `therapist_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `therapist_sessions`
--
ALTER TABLE `therapist_sessions`
  MODIFY `session_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `daily_exercise_tracking`
--
ALTER TABLE `daily_exercise_tracking`
  ADD CONSTRAINT `daily_exercise_tracking_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `daily_exercise_tracking_ibfk_2` FOREIGN KEY (`schedule_id`) REFERENCES `exercise_schedules` (`schedule_id`) ON DELETE SET NULL;

--
-- Constraints for table `exercises`
--
ALTER TABLE `exercises`
  ADD CONSTRAINT `exercises_ibfk_1` FOREIGN KEY (`media_asset_id`) REFERENCES `media_assets` (`asset_id`) ON DELETE SET NULL;

--
-- Constraints for table `exercise_logs`
--
ALTER TABLE `exercise_logs`
  ADD CONSTRAINT `exercise_logs_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`),
  ADD CONSTRAINT `exercise_logs_ibfk_2` FOREIGN KEY (`exercise_id`) REFERENCES `exercises` (`exercise_id`);

--
-- Constraints for table `exercise_schedules`
--
ALTER TABLE `exercise_schedules`
  ADD CONSTRAINT `exercise_schedules_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `exercise_schedules_ibfk_2` FOREIGN KEY (`exercise_set_id`) REFERENCES `exercise_sets` (`set_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `exercise_schedules_ibfk_3` FOREIGN KEY (`therapist_id`) REFERENCES `therapists` (`therapist_id`) ON DELETE CASCADE;

--
-- Constraints for table `pain_score_history`
--
ALTER TABLE `pain_score_history`
  ADD CONSTRAINT `pain_score_history_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE;

--
-- Constraints for table `patient_exercises`
--
ALTER TABLE `patient_exercises`
  ADD CONSTRAINT `patient_exercises_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`),
  ADD CONSTRAINT `patient_exercises_ibfk_2` FOREIGN KEY (`set_id`) REFERENCES `exercise_sets` (`set_id`),
  ADD CONSTRAINT `patient_exercises_ibfk_3` FOREIGN KEY (`therapist_id`) REFERENCES `therapists` (`therapist_id`);

--
-- Constraints for table `patient_progress_summary`
--
ALTER TABLE `patient_progress_summary`
  ADD CONSTRAINT `patient_progress_summary_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE;

--
-- Constraints for table `patient_sessions`
--
ALTER TABLE `patient_sessions`
  ADD CONSTRAINT `patient_sessions_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE;

--
-- Constraints for table `set_exercises`
--
ALTER TABLE `set_exercises`
  ADD CONSTRAINT `set_exercises_ibfk_1` FOREIGN KEY (`set_id`) REFERENCES `exercise_sets` (`set_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `set_exercises_ibfk_2` FOREIGN KEY (`exercise_id`) REFERENCES `exercises` (`exercise_id`) ON DELETE CASCADE;

--
-- Constraints for table `therapist_sessions`
--
ALTER TABLE `therapist_sessions`
  ADD CONSTRAINT `therapist_sessions_ibfk_1` FOREIGN KEY (`therapist_id`) REFERENCES `therapists` (`therapist_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
