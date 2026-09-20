-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Apr 23, 2026 at 11:40 PM
-- Server version: 8.0.37
-- PHP Version: 8.4.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bijakmah_flexi`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`bijakmah`@`localhost` PROCEDURE `sp_get_patient_progress` (IN `p_patient_id` INT)   BEGIN
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

CREATE DEFINER=`bijakmah`@`localhost` PROCEDURE `sp_get_therapist_patients` (IN `p_therapist_id` INT)   BEGIN
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

CREATE DEFINER=`bijakmah`@`localhost` PROCEDURE `sp_update_patient_stats` (IN `p_patient_id` INT)   BEGIN
    DECLARE v_compliance DECIMAL(5,2);
    DECLARE v_streak INT;
    
    SELECT 
        COALESCE(
            ROUND(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2),
            0
        ) INTO v_compliance
    FROM daily_exercise_tracking
    WHERE patient_id = p_patient_id 
    AND exercise_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
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
  `log_id` int NOT NULL,
  `admin_id` int DEFAULT NULL,
  `action` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `details` text COLLATE utf8mb4_general_ci,
  `ip_address` varchar(45) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
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
(7, 1, 'Therapist approved', 'Approved therapist ID: 1', '::1', '2026-02-10 13:03:35');

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `centre_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `centre_address` text COLLATE utf8mb4_general_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
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
  `token_id` int NOT NULL,
  `user_type` enum('patient','therapist','admin') COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` int NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `refresh_token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `device_info` text COLLATE utf8mb4_general_ci,
  `expires_at` datetime NOT NULL,
  `last_used` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_exercise_tracking`
--

CREATE TABLE `daily_exercise_tracking` (
  `tracking_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `schedule_id` int DEFAULT NULL,
  `exercise_date` date NOT NULL,
  `status` enum('pending','completed','missed','skipped') COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `completed_at` datetime DEFAULT NULL,
  `pain_score_before` int DEFAULT NULL,
  `pain_score_after` int DEFAULT NULL,
  `notes` text COLLATE utf8mb4_general_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exercises`
--

CREATE TABLE `exercises` (
  `exercise_id` int NOT NULL,
  `exercise_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `instructions` text COLLATE utf8mb4_general_ci,
  `difficulty` enum('beginner','intermediate','advanced') COLLATE utf8mb4_general_ci DEFAULT 'beginner',
  `reps_default` int DEFAULT '10',
  `sets_default` int DEFAULT '3',
  `hold_duration_sec` int DEFAULT '5',
  `video_url` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `thumbnail_path` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `video_path` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `media_type` enum('local','youtube','vimeo','external') COLLATE utf8mb4_general_ci DEFAULT 'local',
  `media_asset_id` int DEFAULT NULL,
  `duration_seconds` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `exercises`
--

INSERT INTO `exercises` (`exercise_id`, `exercise_name`, `description`, `instructions`, `difficulty`, `reps_default`, `sets_default`, `hold_duration_sec`, `video_url`, `thumbnail_path`, `video_path`, `media_type`, `media_asset_id`, `duration_seconds`, `created_at`) VALUES
(1, 'Finger Taps', 'This exercise is designed to train each finger to move independently, enhancing coordination and fine motor control.', '1. Sit at a table and rest your forearm on the tabletop.\n2. Move your fingers slowly, one finger at a time, with your hand relaxed, making a wave with your fingers.', 'beginner', 5, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:12:34'),
(2, 'Finger Abduction and Adduction', 'This exercise helps improve finger mobility and strength.', '1. Sit comfortably with your hand resting on a table\n2. Slowly spread your fingers apart as far as comfortable\n3. Hold the position for 3 seconds\n4. Slowly bring your fingers back together\n5. Repeat 5 times', 'beginner', 3, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:14:16'),
(3, 'Knuckle bend', 'Knuckle bending exercises improve flexibility, strengthen muscles, prevent stiffness, enhance hand coordination.', '1. Sit or stand comfortably with your hand resting on a table or in the air\n2. Keep your palm facing up and fingers fully straight\n3. Without moving your wrist, bend all fingers at the knuckle joints\n4. Keep the middle and tip joints straight\n5. Hold the bent position for 1 second\n6. Slowly straighten your fingers back to the starting position\n7. Repeat 5 times', 'beginner', 3, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:15:53'),
(4, 'Thumb and Little Finger Abduction/Adduction', 'The Thumb and Little Finger Abduction-Adduction Exercise strengthens and increases mobility of the thumb and little finger.', '1. Keep your fingers together and wrist straight\n2. Keeping the palm flat, slide your thumb slowly outward\n3. Slide the thumb back so it touches the side of your index finger\n4. With your thumb now in place, slide your little finger slowly outward\n5. Slide the pinky back so it touches the ring finger\n6. Perform 7 cycles in a row', 'beginner', 7, 3, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:17:24'),
(5, 'Middle joint finger flexion with open palm', 'This exercise focuses on bending the fingers at the middle joints while keeping the palm flat.', '1. Sit comfortably at a table with your forearm resting on the surface\n2. Place your hand palm-down on the table, fingers extended and relaxed\n3. Slowly bend each finger at the middle joint\n4. Hold the bend for 1 second, then return the finger to a flat, extended position.\n5. Repeat 5 times', 'beginner', 3, 5, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:18:27'),
(6, 'Thumb Flexion to Each Finger', 'Place your hand in a comfortable position. Bring your thumb towards the tip of the index finger and apply pressure.', '1. Touch the tip of the index finger with your thumb and gently slide down\n2. Touch the tip of the middle finger with your thumb and gently slide down\n3. Continue the same movements with the other fingers\n4. Repeat 10 times', 'beginner', 4, 10, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:19:52'),
(7, 'Thumb Flexion', 'Bend thumb across the palm', '1. Place your hand palm-up or flat on a table\n2. Slowly bend your thumb across your palm toward the base of your little finger\n3. Hold the position for 1 second\n4. Straighten your thumb back to the starting position\n5. Repeat 5 times', 'beginner', 5, 3, 1, NULL, NULL, NULL, 'local', NULL, 0, '2026-04-22 02:22:04');

-- --------------------------------------------------------

--
-- Table structure for table `exercise_logs`
--

CREATE TABLE `exercise_logs` (
  `log_id` int NOT NULL,
  `patient_id` int DEFAULT NULL,
  `exercise_id` int DEFAULT NULL,
  `date_completed` date DEFAULT NULL,
  `reps_completed` int DEFAULT NULL,
  `sets_completed` int DEFAULT NULL,
  `pain_score` int DEFAULT NULL,
  `duration_minutes` int DEFAULT NULL,
  `logged_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exercise_schedules`
--

CREATE TABLE `exercise_schedules` (
  `schedule_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `exercise_set_id` int NOT NULL,
  `therapist_id` int NOT NULL,
  `frequency` enum('Daily','2x Weekly','3x Weekly','Weekly','Custom') COLLATE utf8mb4_general_ci DEFAULT 'Daily',
  `custom_days` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `reminder_time` time DEFAULT '21:00:00',
  `send_reminder` tinyint(1) DEFAULT '1',
  `alert_on_missed` tinyint(1) DEFAULT '1',
  `total_sessions` int DEFAULT '30',
  `completed_sessions` int DEFAULT '0',
  `status` enum('active','paused','completed','cancelled') COLLATE utf8mb4_general_ci DEFAULT 'active',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exercise_sets`
--

CREATE TABLE `exercise_sets` (
  `set_id` int NOT NULL,
  `set_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `condition_target` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `created_by` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `exercise_sets`
--

INSERT INTO `exercise_sets` (`set_id`, `set_name`, `condition_target`, `description`, `created_by`, `created_at`) VALUES
(6, 'Gamer\'s Hand Relief', 'Gaming-related strain', 'Exercises for gamers and heavy mouse users', NULL, '2026-02-10 13:02:32'),
(9, 'Stiff Finger', 'Finger stiffness, reduced flexibility', 'This set focuses on improving finger mobility and flexibility.', 1, '2026-04-22 02:28:05'),
(10, 'Muscle Fatigue', 'Hand fatigue, muscle tiredness', 'Designed to reduce muscle fatigue and improve endurance in the hand.', 1, '2026-04-22 02:29:23'),
(11, 'Joint Stiffness', 'Stiff joints, limited range of motion', 'This set targets joint flexibility and helps loosen stiff finger joints.', 1, '2026-04-22 02:30:11'),
(12, 'Paresthesia (Numbness / Tingling)', 'Numbness, tingling sensation', 'These exercises help stimulate nerves and improve blood circulation in the hand.', 1, '2026-04-22 02:31:08'),
(13, 'Hand Weakness', 'Weak grip, reduced hand strength', 'This set strengthens the muscles of the hand and fingers to improve grip strength.', 1, '2026-04-22 02:32:02'),
(14, 'Trigger Finger', 'Finger locking, clicking sensation', 'A gentle exercise set designed to improve tendon movement and reduce stiffness.', 1, '2026-04-22 02:33:20'),
(15, 'Typing Recovery', 'Strain from typing, keyboard overuse', 'Ideal for individuals who spend long hours typing.', 1, '2026-04-22 02:34:03'),
(16, 'Phone / Scrolling Strain', 'Thumb strain, excessive phone use', 'Targets thumb fatigue and stiffness caused by prolonged phone usage.', 1, '2026-04-22 02:35:35'),
(17, 'Heavy Lifting / Grip Strength', 'Post-workout recovery, grip strengthening', 'Designed for individuals who frequently lift heavy objects.', 1, '2026-04-22 02:36:31');

-- --------------------------------------------------------

--
-- Table structure for table `media_assets`
--

CREATE TABLE `media_assets` (
  `asset_id` int NOT NULL,
  `asset_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `asset_type` enum('image','video','document','audio') COLLATE utf8mb4_general_ci NOT NULL,
  `category` enum('exercise','profile','logo','banner','other') COLLATE utf8mb4_general_ci DEFAULT 'exercise',
  `file_path` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `file_size` int DEFAULT '0',
  `mime_type` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `width` int DEFAULT NULL,
  `height` int DEFAULT NULL,
  `duration_seconds` int DEFAULT NULL,
  `thumbnail_path` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `external_url` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `uploaded_by` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `media_assets`
--

INSERT INTO `media_assets` (`asset_id`, `asset_name`, `asset_type`, `category`, `file_path`, `file_size`, `mime_type`, `width`, `height`, `duration_seconds`, `thumbnail_path`, `external_url`, `is_active`, `uploaded_by`, `created_at`, `updated_at`) VALUES
(1, 'App Logo', 'image', 'logo', 'assets/images/logo.png', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(2, 'Finger Flexion Video', 'video', 'exercise', 'assets/videos/finger_flexion.mp4', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(3, 'Grip Strength Video', 'video', 'exercise', 'assets/videos/grip_strength.mp4', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(4, 'Thumb Stretch Video', 'video', 'exercise', 'assets/videos/thumb_stretch.mp4', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(5, 'Finger Abduction Video', 'video', 'exercise', 'assets/videos/finger_abduction.mp4', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(6, 'Default Avatar', 'image', 'profile', 'assets/images/profiles/default_avatar.png', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(7, 'Onboarding Image 1', 'image', 'banner', 'assets/images/display1.png', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(8, 'Onboarding Image 2', 'image', 'banner', 'assets/images/display2.png', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(9, 'Onboarding Image 3', 'image', 'banner', 'assets/images/display3.png', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54'),
(10, 'Onboarding Image 4', 'image', 'banner', 'assets/images/display4.png', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, '2026-04-23 15:29:54', '2026-04-23 15:29:54');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int NOT NULL,
  `user_type` enum('patient','therapist','admin') COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `message` text COLLATE utf8mb4_general_ci NOT NULL,
  `type` enum('reminder','alert','info','success','warning') COLLATE utf8mb4_general_ci DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT '0',
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pain_score_history`
--

CREATE TABLE `pain_score_history` (
  `pain_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `pain_score` int NOT NULL,
  `recorded_date` date NOT NULL,
  `recorded_time` time DEFAULT NULL,
  `notes` text COLLATE utf8mb4_general_ci,
  `session_type` enum('pre-exercise','post-exercise','daily-check') COLLATE utf8mb4_general_ci DEFAULT 'post-exercise',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `reset_id` int NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `token` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `otp_code` varchar(6) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `patient_id` int NOT NULL,
  `patient_ic` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `profile_picture` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `finger_condition` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `therapist_id` int DEFAULT NULL,
  `program_start_date` date DEFAULT NULL,
  `exercise_set_id` int DEFAULT NULL,
  `status` enum('pending','active','inactive') COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `pain_score` int DEFAULT '0',
  `compliance_rate` decimal(5,2) DEFAULT '0.00',
  `streak` int DEFAULT '0',
  `last_exercise` datetime DEFAULT NULL,
  `daily_status` enum('Completed today','Pending today','Missed today') COLLATE utf8mb4_general_ci DEFAULT 'Pending today',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `validated_at` datetime DEFAULT NULL,
  `validated_by` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patients`
--

INSERT INTO `patients` (`patient_id`, `patient_ic`, `full_name`, `email`, `phone`, `profile_picture`, `password_hash`, `finger_condition`, `therapist_id`, `program_start_date`, `exercise_set_id`, `status`, `pain_score`, `compliance_rate`, `streak`, `last_exercise`, `daily_status`, `created_at`, `validated_at`, `validated_by`) VALUES
(1, '900101-10-1234', 'Test Patient', 'patient@test.com', '012-3456789', NULL, '123456', 'Trigger Finger', 2, '2026-04-22', NULL, 'active', 0, 0.00, 0, NULL, 'Pending today', '2026-04-23 15:29:54', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `patient_exercises`
--

CREATE TABLE `patient_exercises` (
  `assignment_id` int NOT NULL,
  `patient_id` int DEFAULT NULL,
  `set_id` int DEFAULT NULL,
  `therapist_id` int DEFAULT NULL,
  `frequency` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `reminder_enabled` tinyint(1) DEFAULT '1',
  `reminder_time` time DEFAULT '09:00:00',
  `alert_on_missed` tinyint(1) DEFAULT '1',
  `status` enum('active','completed','cancelled') COLLATE utf8mb4_general_ci DEFAULT 'active',
  `total_sessions` int DEFAULT '0',
  `completed_sessions` int DEFAULT '0',
  `assigned_date` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patient_progress_summary`
--

CREATE TABLE `patient_progress_summary` (
  `summary_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `week_start_date` date NOT NULL,
  `total_sessions_scheduled` int DEFAULT '0',
  `sessions_completed` int DEFAULT '0',
  `sessions_missed` int DEFAULT '0',
  `avg_pain_score` decimal(3,1) DEFAULT '0.0',
  `compliance_rate` decimal(5,2) DEFAULT '0.00',
  `streak_days` int DEFAULT '0',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patient_sessions`
--

CREATE TABLE `patient_sessions` (
  `session_id` int NOT NULL,
  `patient_id` int NOT NULL,
  `login_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `logout_time` datetime DEFAULT NULL,
  `device_token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `device_type` enum('android','ios','web') COLLATE utf8mb4_general_ci DEFAULT 'android',
  `app_version` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `last_active` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `set_exercises`
--

CREATE TABLE `set_exercises` (
  `id` int NOT NULL,
  `set_id` int DEFAULT NULL,
  `exercise_id` int DEFAULT NULL,
  `order_in_set` int DEFAULT NULL
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
(18, 13, 3, 2),
(19, 13, 5, 3),
(20, 13, 7, 4),
(21, 14, 1, 1),
(22, 14, 3, 2),
(23, 14, 5, 3),
(24, 14, 7, 4),
(25, 15, 1, 1),
(26, 15, 3, 2),
(27, 15, 6, 3),
(28, 15, 2, 4),
(29, 6, 1, 1),
(30, 6, 3, 2),
(31, 6, 7, 3),
(32, 16, 2, 1),
(33, 16, 7, 2),
(34, 16, 6, 3),
(35, 16, 1, 4),
(36, 17, 2, 1),
(37, 17, 1, 2),
(38, 17, 5, 5),
(39, 17, 4, 6),
(40, 17, 6, 7),
(41, 17, 7, 8),
(42, 17, 3, 9);

-- --------------------------------------------------------

--
-- Table structure for table `support_messages`
--

CREATE TABLE `support_messages` (
  `message_id` int NOT NULL,
  `sender_type` enum('patient','therapist','admin') COLLATE utf8mb4_general_ci NOT NULL,
  `sender_id` int NOT NULL,
  `receiver_type` enum('patient','therapist','admin') COLLATE utf8mb4_general_ci NOT NULL,
  `receiver_id` int NOT NULL,
  `subject` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `message` text COLLATE utf8mb4_general_ci NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `parent_message_id` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `setting_id` int NOT NULL,
  `setting_key` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `setting_value` text COLLATE utf8mb4_general_ci,
  `setting_type` enum('string','integer','boolean','json') COLLATE utf8mb4_general_ci DEFAULT 'string',
  `description` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`setting_id`, `setting_key`, `setting_value`, `setting_type`, `description`, `updated_at`, `updated_by`) VALUES
(1, 'app_version_android', '1.0.0', 'string', 'Current Android app version', '2026-04-23 15:29:54', NULL),
(2, 'app_version_ios', '1.0.0', 'string', 'Current iOS app version', '2026-04-23 15:29:54', NULL),
(3, 'min_app_version_android', '1.0.0', 'string', 'Minimum supported Android version', '2026-04-23 15:29:54', NULL),
(4, 'min_app_version_ios', '1.0.0', 'string', 'Minimum supported iOS version', '2026-04-23 15:29:54', NULL),
(5, 'maintenance_mode', 'false', 'boolean', 'System maintenance mode', '2026-04-23 15:29:54', NULL),
(6, 'default_reminder_time', '21:00', 'string', 'Default daily reminder time', '2026-04-23 15:29:54', NULL),
(7, 'max_pain_score', '10', 'integer', 'Maximum pain score value', '2026-04-23 15:29:54', NULL),
(8, 'session_timeout_minutes', '30', 'integer', 'User session timeout in minutes', '2026-04-23 15:29:54', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `therapists`
--

CREATE TABLE `therapists` (
  `therapist_id` int NOT NULL,
  `staff_id` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `profile_picture` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `whatsapp` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `centre_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `centre_type` enum('hospital','clinic','centre') COLLATE utf8mb4_general_ci DEFAULT 'clinic',
  `status` enum('pending','active','inactive') COLLATE utf8mb4_general_ci DEFAULT 'pending',
  `patient_count` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `validated_at` datetime DEFAULT NULL,
  `validated_by` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `therapists`
--

INSERT INTO `therapists` (`therapist_id`, `staff_id`, `full_name`, `email`, `phone`, `profile_picture`, `whatsapp`, `password_hash`, `centre_name`, `centre_type`, `status`, `patient_count`, `created_at`, `validated_at`, `validated_by`) VALUES
(2, 'TH002', 'Dr. Lee Wei', 'therapist@test.com', '012-3456789', NULL, NULL, '123456', 'Kuantan Physio Clinic', 'clinic', 'active', 1, '2026-04-23 15:29:54', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `therapist_sessions`
--

CREATE TABLE `therapist_sessions` (
  `session_id` int NOT NULL,
  `therapist_id` int NOT NULL,
  `login_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `logout_time` datetime DEFAULT NULL,
  `device_token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `device_type` enum('android','ios','web') COLLATE utf8mb4_general_ci DEFAULT 'android',
  `app_version` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `last_active` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_patient_dashboard`
-- (See below for the actual view)
--
CREATE TABLE `v_patient_dashboard` (
`compliance_rate` decimal(5,2)
,`current_exercise_set` varchar(255)
,`daily_status` enum('Completed today','Pending today','Missed today')
,`email` varchar(255)
,`finger_condition` varchar(255)
,`frequency` enum('Daily','2x Weekly','3x Weekly','Weekly','Custom')
,`full_name` varchar(255)
,`last_pain_score` bigint
,`pain_score` int
,`patient_id` int
,`reminder_time` time
,`streak` int
,`therapist_name` varchar(255)
,`therapist_whatsapp` varchar(20)
,`total_completed_sessions` bigint
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_therapist_dashboard`
-- (See below for the actual view)
--
CREATE TABLE `v_therapist_dashboard` (
`active_patients` bigint
,`avg_compliance` decimal(9,6)
,`centre_name` varchar(255)
,`email` varchar(255)
,`full_name` varchar(255)
,`inactive_patients` bigint
,`status` enum('pending','active','inactive')
,`therapist_id` int
,`total_patients` bigint
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_weekly_compliance`
-- (See below for the actual view)
--
CREATE TABLE `v_weekly_compliance` (
`completed` decimal(23,0)
,`compliance_rate` decimal(29,2)
,`full_name` varchar(255)
,`missed` decimal(23,0)
,`patient_id` int
,`total_scheduled` bigint
,`week_number` int
);

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
  ADD UNIQUE KEY `token` (`token`);

--
-- Indexes for table `daily_exercise_tracking`
--
ALTER TABLE `daily_exercise_tracking`
  ADD PRIMARY KEY (`tracking_id`),
  ADD UNIQUE KEY `unique_patient_date` (`patient_id`,`exercise_date`);

--
-- Indexes for table `exercises`
--
ALTER TABLE `exercises`
  ADD PRIMARY KEY (`exercise_id`);

--
-- Indexes for table `exercise_logs`
--
ALTER TABLE `exercise_logs`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `exercise_schedules`
--
ALTER TABLE `exercise_schedules`
  ADD PRIMARY KEY (`schedule_id`);

--
-- Indexes for table `exercise_sets`
--
ALTER TABLE `exercise_sets`
  ADD PRIMARY KEY (`set_id`);

--
-- Indexes for table `media_assets`
--
ALTER TABLE `media_assets`
  ADD PRIMARY KEY (`asset_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`);

--
-- Indexes for table `pain_score_history`
--
ALTER TABLE `pain_score_history`
  ADD PRIMARY KEY (`pain_id`);

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
  ADD PRIMARY KEY (`assignment_id`);

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
  ADD PRIMARY KEY (`session_id`);

--
-- Indexes for table `set_exercises`
--
ALTER TABLE `set_exercises`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `support_messages`
--
ALTER TABLE `support_messages`
  ADD PRIMARY KEY (`message_id`);

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
  ADD PRIMARY KEY (`session_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `log_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `admin_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `api_tokens`
--
ALTER TABLE `api_tokens`
  MODIFY `token_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_exercise_tracking`
--
ALTER TABLE `daily_exercise_tracking`
  MODIFY `tracking_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exercises`
--
ALTER TABLE `exercises`
  MODIFY `exercise_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `exercise_logs`
--
ALTER TABLE `exercise_logs`
  MODIFY `log_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exercise_schedules`
--
ALTER TABLE `exercise_schedules`
  MODIFY `schedule_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exercise_sets`
--
ALTER TABLE `exercise_sets`
  MODIFY `set_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `media_assets`
--
ALTER TABLE `media_assets`
  MODIFY `asset_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pain_score_history`
--
ALTER TABLE `pain_score_history`
  MODIFY `pain_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `reset_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patients`
--
ALTER TABLE `patients`
  MODIFY `patient_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `patient_exercises`
--
ALTER TABLE `patient_exercises`
  MODIFY `assignment_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patient_progress_summary`
--
ALTER TABLE `patient_progress_summary`
  MODIFY `summary_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patient_sessions`
--
ALTER TABLE `patient_sessions`
  MODIFY `session_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `set_exercises`
--
ALTER TABLE `set_exercises`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `support_messages`
--
ALTER TABLE `support_messages`
  MODIFY `message_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `setting_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `therapists`
--
ALTER TABLE `therapists`
  MODIFY `therapist_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `therapist_sessions`
--
ALTER TABLE `therapist_sessions`
  MODIFY `session_id` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Structure for view `v_patient_dashboard`
--
DROP TABLE IF EXISTS `v_patient_dashboard`;

CREATE ALGORITHM=UNDEFINED DEFINER=`bijakmah`@`localhost` SQL SECURITY DEFINER VIEW `v_patient_dashboard`  AS SELECT `p`.`patient_id` AS `patient_id`, `p`.`full_name` AS `full_name`, `p`.`email` AS `email`, `p`.`finger_condition` AS `finger_condition`, `p`.`pain_score` AS `pain_score`, `p`.`streak` AS `streak`, `p`.`compliance_rate` AS `compliance_rate`, `p`.`daily_status` AS `daily_status`, `t`.`full_name` AS `therapist_name`, `t`.`whatsapp` AS `therapist_whatsapp`, `es`.`set_name` AS `current_exercise_set`, `sch`.`frequency` AS `frequency`, `sch`.`reminder_time` AS `reminder_time`, (select count(0) from `daily_exercise_tracking` `det` where ((`det`.`patient_id` = `p`.`patient_id`) and (`det`.`status` = 'completed'))) AS `total_completed_sessions`, (select `ph`.`pain_score` from `pain_score_history` `ph` where (`ph`.`patient_id` = `p`.`patient_id`) order by `ph`.`recorded_date` desc limit 1) AS `last_pain_score` FROM (((`patients` `p` left join `therapists` `t` on((`p`.`therapist_id` = `t`.`therapist_id`))) left join `exercise_schedules` `sch` on(((`p`.`patient_id` = `sch`.`patient_id`) and (`sch`.`status` = 'active')))) left join `exercise_sets` `es` on((`sch`.`exercise_set_id` = `es`.`set_id`))) WHERE (`p`.`status` = 'active') ;

-- --------------------------------------------------------

--
-- Structure for view `v_therapist_dashboard`
--
DROP TABLE IF EXISTS `v_therapist_dashboard`;

CREATE ALGORITHM=UNDEFINED DEFINER=`bijakmah`@`localhost` SQL SECURITY DEFINER VIEW `v_therapist_dashboard`  AS SELECT `t`.`therapist_id` AS `therapist_id`, `t`.`full_name` AS `full_name`, `t`.`email` AS `email`, `t`.`centre_name` AS `centre_name`, `t`.`status` AS `status`, count(distinct `p`.`patient_id`) AS `total_patients`, count(distinct (case when (`p`.`status` = 'active') then `p`.`patient_id` end)) AS `active_patients`, count(distinct (case when (`p`.`status` = 'inactive') then `p`.`patient_id` end)) AS `inactive_patients`, avg(`p`.`compliance_rate`) AS `avg_compliance` FROM (`therapists` `t` left join `patients` `p` on((`t`.`therapist_id` = `p`.`therapist_id`))) GROUP BY `t`.`therapist_id` ;

-- --------------------------------------------------------

--
-- Structure for view `v_weekly_compliance`
--
DROP TABLE IF EXISTS `v_weekly_compliance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`bijakmah`@`localhost` SQL SECURITY DEFINER VIEW `v_weekly_compliance`  AS SELECT `p`.`patient_id` AS `patient_id`, `p`.`full_name` AS `full_name`, yearweek(`det`.`exercise_date`,0) AS `week_number`, count(0) AS `total_scheduled`, sum((case when (`det`.`status` = 'completed') then 1 else 0 end)) AS `completed`, sum((case when (`det`.`status` = 'missed') then 1 else 0 end)) AS `missed`, round(((sum((case when (`det`.`status` = 'completed') then 1 else 0 end)) / count(0)) * 100),2) AS `compliance_rate` FROM (`patients` `p` join `daily_exercise_tracking` `det` on((`p`.`patient_id` = `det`.`patient_id`))) GROUP BY `p`.`patient_id`, yearweek(`det`.`exercise_date`,0) ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
