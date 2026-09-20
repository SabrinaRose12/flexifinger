<?php
// api/get-media.php
// Serve media files to mobile app

require_once '../includes/config.php';

$file = $_GET['file'] ?? '';
$type = $_GET['type'] ?? 'video'; // video, image, thumbnail

// Security: Prevent directory traversal
$file = basename($file);

$base_path = '../assets/';
$full_path = '';

switch ($type) {
    case 'video':
        $full_path = $base_path . 'videos/' . $file;
        $mime_type = 'video/mp4';
        break;
    case 'image':
        $full_path = $base_path . 'images/exercises/' . $file;
        $mime_type = 'image/jpeg';
        break;
    case 'thumbnail':
        $full_path = $base_path . 'images/exercises/' . $file;
        $mime_type = 'image/jpeg';
        break;
    case 'profile':
        $full_path = $base_path . 'images/profiles/' . $file;
        $mime_type = 'image/png';
        break;
    default:
        http_response_code(400);
        exit('Invalid type');
}

// Check if file exists
if (!file_exists($full_path)) {
    http_response_code(404);
    exit('File not found');
}

// Support range requests for video streaming (important for Flutter video_player)
if ($type === 'video') {
    $size = filesize($full_path);
    $length = $size;
    $start = 0;
    $end = $size - 1;
    
    header('Content-Type: ' . $mime_type);
    header("Accept-Ranges: bytes");
    
    if (isset($_SERVER['HTTP_RANGE'])) {
        $c_start = $start;
        $c_end = $end;
        list(, $range) = explode('=', $_SERVER['HTTP_RANGE'], 2);
        
        if (strpos($range, ',') !== false) {
            http_response_code(416);
            exit('Requested Range Not Satisfiable');
        }
        
        if ($range == '-') {
            $c_start = $size - substr($range, 1);
        } else {
            $range = explode('-', $range);
            $c_start = $range[0];
            $c_end = (isset($range[1]) && is_numeric($range[1])) ? $range[1] : $size - 1;
        }
        
        $c_end = ($c_end > $end) ? $end : $c_end;
        
        if ($c_start > $c_end || $c_start > $size - 1 || $c_end >= $size) {
            http_response_code(416);
            exit('Requested Range Not Satisfiable');
        }
        
        $start = $c_start;
        $end = $c_end;
        $length = $end - $start + 1;
        
        http_response_code(206);
        header("Content-Range: bytes $start-$end/$size");
    }
    
    header("Content-Length: $length");
    
    $fp = fopen($full_path, 'rb');
    fseek($fp, $start);
    
    $buffer = 8192;
    $position = 0;
    
    while ($position < $length) {
        $chunk = min($buffer, $length - $position);
        echo fread($fp, $chunk);
        $position += $chunk;
    }
    
    fclose($fp);
} else {
    // For images, just output the file
    header('Content-Type: ' . $mime_type);
    header('Content-Length: ' . filesize($full_path));
    header('Cache-Control: public, max-age=86400'); // Cache for 24 hours
    readfile($full_path);
}
?>