<?php
// admin/includes/email-config.php

function sendEmail($to, $subject, $htmlMessage) {
    $headers = "MIME-Version: 1.0" . "\r\n";
    $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
    $headers .= "From: a.flexifinger@gmail.com" . "\r\n";
    $headers .= "Reply-To: a.flexifinger@gmail.com" . "\r\n";
    
    return mail($to, $subject, $htmlMessage, $headers);
}

function sendAdminNotification($subject, $message) {
    return sendEmail('a.flexifinger@gmail.com', $subject, $message);
}
?>