<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/email-config.php';

$error = '';
$success = '';
$step = $_GET['step'] ?? 'request';

// Check if already logged in
if ($auth->isLoggedIn()) {
    header("Location: dashboard.php");
    exit();
}

$conn = getDBConnection();

// STEP 1: Request OTP
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['request_otp'])) {
    $email = $_POST['email'] ?? '';
    
    if (empty($email)) {
        $error = "Please enter your email address";
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = "Please enter a valid email address";
    } else {
        // Check if email exists in admins table
        $stmt = $conn->prepare("SELECT admin_id, full_name FROM admins WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $admin = $result->fetch_assoc();
            
            // Generate 6-digit OTP
            $otp = sprintf("%06d", mt_rand(1, 999999));
            $token = bin2hex(random_bytes(25));
            $expires = date('Y-m-d H:i:s', strtotime('+15 minutes'));
            
            // Delete any existing tokens for this email
            $deleteStmt = $conn->prepare("DELETE FROM password_resets WHERE email = ?");
            $deleteStmt->bind_param("s", $email);
            $deleteStmt->execute();
            
            // Insert new OTP
            $insertStmt = $conn->prepare("INSERT INTO password_resets (email, token, otp_code, expires_at) VALUES (?, ?, ?, ?)");
            $insertStmt->bind_param("ssss", $email, $token, $otp, $expires);
            
            if ($insertStmt->execute()) {
                $subject = "Your FlexiFinger Password Reset OTP";
                
                $message = "
                <html>
                <head>
                    <style>
                        body { font-family: Arial, sans-serif; line-height: 1.6; }
                        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; }
                        .content { padding: 30px; background: #f9f9f9; }
                        .otp-box { background: white; border: 2px solid #667eea; padding: 20px; text-align: center; margin: 20px 0; }
                        .otp-code { font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 5px; }
                        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
                        .warning { color: #dc3545; font-size: 13px; }
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h2>FlexiFinger Password Reset</h2>
                        </div>
                        <div class='content'>
                            <p>Hello <strong>" . htmlspecialchars($admin['full_name']) . "</strong>,</p>
                            <p>We received a request to reset your password for your FlexiFinger admin account.</p>
                            
                            <div class='otp-box'>
                                <p>Your OTP Code is:</p>
                                <div class='otp-code'>{$otp}</div>
                                <p>Valid for 15 minutes</p>
                            </div>
                            
                            <p>If you didn't request this password reset, please ignore this email or contact support if you have concerns.</p>
                            
                            <p class='warning'><strong>⚠️ For security reasons, never share this OTP with anyone.</strong></p>
                            
                            <p>Best regards,<br>FlexiFinger System Team</p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated message, please do not reply to this email.</p>
                            <p>&copy; " . date('Y') . " FlexiFinger - Finger Exercise Monitoring System</p>
                        </div>
                    </div>
                </body>
                </html>
                ";
                
                if (sendEmail($email, $subject, $message)) {
                    $_SESSION['reset_email'] = $email;
                    $_SESSION['reset_token'] = $token;
                    $success = "OTP has been sent to your email! Please check your inbox.";
                    $step = 'verify';
                } else {
                    $error = "Failed to send OTP email. Please check your email configuration or try again later.";
                    
                    if (strpos($_SERVER['HTTP_HOST'], 'localhost') !== false || strpos($_SERVER['HTTP_HOST'], 'bijakmahir') !== false) {
                        $demo_otp = $otp;
                        $demo_mode = true;
                    }
                }
            } else {
                $error = "Failed to process request. Please try again.";
            }
        } else {
            $success = "If the email exists in our system, an OTP has been sent.";
            $step = 'verify';
        }
    }
}

// STEP 2: Verify OTP
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['verify_otp'])) {
    $otp = $_POST['otp'] ?? '';
    $email = $_SESSION['reset_email'] ?? '';
    
    if (empty($otp) || strlen($otp) != 6) {
        $error = "Please enter a valid 6-digit OTP";
    } else {
        $stmt = $conn->prepare("SELECT * FROM password_resets WHERE email = ? AND otp_code = ? AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1");
        $stmt->bind_param("ss", $email, $otp);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $_SESSION['reset_verified'] = true;
            $_SESSION['reset_email'] = $email;
            $step = 'reset';
        } else {
            $error = "Invalid or expired OTP. Please try again.";
        }
    }
}

// STEP 3: Reset Password
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['reset_password'])) {
    if (!isset($_SESSION['reset_verified']) || $_SESSION['reset_verified'] !== true) {
        $error = "Please verify your OTP first";
        $step = 'verify';
    } else {
        $password = $_POST['password'] ?? '';
        $confirm_password = $_POST['confirm_password'] ?? '';
        $email = $_SESSION['reset_email'] ?? '';
        
        if (empty($password) || empty($confirm_password)) {
            $error = "Please fill in all fields";
        } elseif (strlen($password) < 6) {
            $error = "Password must be at least 6 characters long";
        } elseif ($password !== $confirm_password) {
            $error = "Passwords do not match";
        } elseif (!preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/', $password)) {
            $error = "Password must contain at least one uppercase letter, one lowercase letter, and one number";
        } else {
            $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
            
            $updateStmt = $conn->prepare("UPDATE admins SET password_hash = ? WHERE email = ?");
            $updateStmt->bind_param("ss", $hashedPassword, $email);
            
            if ($updateStmt->execute()) {
                $deleteStmt = $conn->prepare("DELETE FROM password_resets WHERE email = ?");
                $deleteStmt->bind_param("s", $email);
                $deleteStmt->execute();
                
                unset($_SESSION['reset_email']);
                unset($_SESSION['reset_token']);
                unset($_SESSION['reset_verified']);
                
                $success = "Password has been reset successfully! You can now login with your new password.";
                $step = 'complete';
            } else {
                $error = "Failed to reset password. Please try again.";
            }
        }
    }
}

// Resend OTP
if (isset($_GET['resend']) && $_GET['resend'] == 'otp') {
    $email = $_SESSION['reset_email'] ?? '';
    if ($email) {
        $otp = sprintf("%06d", mt_rand(1, 999999));
        $expires = date('Y-m-d H:i:s', strtotime('+15 minutes'));
        
        $updateStmt = $conn->prepare("UPDATE password_resets SET otp_code = ?, expires_at = ? WHERE email = ?");
        $updateStmt->bind_param("sss", $otp, $expires, $email);
        
        if ($updateStmt->execute()) {
            $stmt = $conn->prepare("SELECT full_name FROM admins WHERE email = ?");
            $stmt->bind_param("s", $email);
            $stmt->execute();
            $admin = $stmt->get_result()->fetch_assoc();
            
            $subject = "Your New FlexiFinger Password Reset OTP";
            $message = "
            <html>
            <body>
                <h2>FlexiFinger Password Reset</h2>
                <p>Hello <strong>" . htmlspecialchars($admin['full_name']) . "</strong>,</p>
                <p>Your new OTP code is:</p>
                <h1 style='color: #667eea; font-size: 36px;'>{$otp}</h1>
                <p>Valid for 15 minutes</p>
                <p>If you didn't request this, please ignore.</p>
            </body>
            </html>
            ";
            
            if (sendEmail($email, $subject, $message)) {
                $success = "New OTP has been sent to your email!";
            }
        }
    }
    header("Location: forgot-password.php?step=verify");
    exit();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container-custom { width: 100%; max-width: 500px; }
        .card {
            background: white;
            border-radius: 24px;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
            padding: 40px;
        }
        .header { text-align: center; margin-bottom: 30px; }
        .header i { font-size: 48px; color: #667eea; margin-bottom: 15px; }
        .header h2 { font-size: 24px; font-weight: 700; color: #1e293b; margin-bottom: 8px; }
        .header p { font-size: 14px; color: #64748b; }
        .form-control, .otp-input {
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            padding: 12px 15px;
            transition: all 0.3s;
            font-size: 15px;
        }
        .form-control:focus, .otp-input:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            outline: none;
        }
        .otp-input {
            text-align: center;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: 10px;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            color: white;
            padding: 12px;
            border-radius: 12px;
            font-weight: 600;
            width: 100%;
            transition: all 0.3s;
            margin-top: 20px;
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 25px -5px rgba(102,126,234,0.4); }
        .btn-outline-primary {
            background: white;
            border: 2px solid #667eea;
            color: #667eea;
            padding: 10px;
            border-radius: 12px;
            font-weight: 600;
            width: 100%;
            text-align: center;
            display: inline-block;
            text-decoration: none;
            margin-top: 12px;
        }
        .btn-outline-primary:hover { background: #667eea; color: white; }
        .alert { border-radius: 12px; padding: 15px; margin-bottom: 20px; }
        .alert-success { background: #d1fae5; color: #065f46; border-left: 4px solid #10b981; }
        .alert-danger { background: #fee2e2; color: #991b1b; border-left: 4px solid #ef4444; }
        .steps {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
            position: relative;
        }
        .steps::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 0;
            right: 0;
            height: 2px;
            background: #e2e8f0;
            transform: translateY(-50%);
            z-index: 1;
        }
        .step {
            background: white;
            border: 2px solid #e2e8f0;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            color: #94a3b8;
            position: relative;
            z-index: 2;
        }
        .step.active { background: #667eea; border-color: #667eea; color: white; }
        .step.completed { background: #10b981; border-color: #10b981; color: white; }
        .timer { text-align: center; font-size: 13px; color: #64748b; margin-top: 15px; }
        .timer span { font-weight: 700; color: #667eea; }
        .password-requirements { font-size: 12px; margin-top: 15px; padding-left: 20px; }
        .password-requirements li { margin-bottom: 5px; }
        .password-requirements .valid { color: #10b981; }
        .password-requirements .invalid { color: #ef4444; }
        .demo-otp {
            background: #fef3c7;
            border: 1px solid #fde68a;
            color: #92400e;
            padding: 15px;
            border-radius: 12px;
            margin-top: 20px;
            text-align: center;
        }
        .demo-otp strong { font-size: 24px; color: #f59e0b; }
    </style>
</head>
<body>
    <div class="container-custom">
        <div class="card">
            <div class="header">
                <i class="fas fa-lock"></i>
                <h2>Reset Password</h2>
                <p>Secure password reset with OTP verification</p>
            </div>
            
            <!-- Steps -->
            <div class="steps">
                <div class="step <?php echo $step == 'request' ? 'active' : ''; ?> <?php echo $step != 'request' ? 'completed' : ''; ?>">1</div>
                <div class="step <?php echo $step == 'verify' ? 'active' : ''; ?> <?php echo in_array($step, ['reset', 'complete']) ? 'completed' : ''; ?>">2</div>
                <div class="step <?php echo $step == 'reset' ? 'active' : ''; ?> <?php echo $step == 'complete' ? 'completed' : ''; ?>">3</div>
            </div>
            
            <?php if ($error): ?>
                <div class="alert alert-danger"><i class="fas fa-exclamation-circle me-2"></i><?php echo htmlspecialchars($error); ?></div>
            <?php endif; ?>
            
            <?php if ($success): ?>
                <div class="alert alert-success"><i class="fas fa-check-circle me-2"></i><?php echo htmlspecialchars($success); ?></div>
            <?php endif; ?>
            
            <?php if (isset($demo_mode) && isset($demo_otp)): ?>
                <div class="demo-otp">
                    <p><strong>🔧 DEVELOPMENT MODE</strong></p>
                    <p>Your OTP is: <strong><?php echo $demo_otp; ?></strong></p>
                    <p class="small">(For testing purposes only)</p>
                </div>
            <?php endif; ?>
            
            <!-- STEP 1: Request OTP -->
            <?php if ($step == 'request'): ?>
                <form method="POST">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Email Address</label>
                        <div class="input-group">
                            <span class="input-group-text bg-transparent border-end-0"><i class="fas fa-envelope text-muted"></i></span>
                            <input type="email" class="form-control" name="email" placeholder="admin@flexifinger.com" required>
                        </div>
                        <small class="text-muted">We'll send a 6-digit OTP to this email</small>
                    </div>
                    
                    <button type="submit" name="request_otp" class="btn-primary"><i class="fas fa-paper-plane me-2"></i>Send OTP</button>
                    
                    <a href="index.php" class="btn-outline-primary"><i class="fas fa-arrow-left me-2"></i>Back to Login</a>
                </form>
            <?php endif; ?>
            
            <!-- STEP 2: Verify OTP -->
            <?php if ($step == 'verify'): ?>
                <form method="POST" id="otpForm">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Enter 6-digit OTP</label>
                        <input type="text" class="otp-input" name="otp" maxlength="6" pattern="\d{6}" placeholder="000000" required>
                        <div class="timer" id="timer">OTP expires in: <span id="time">15:00</span></div>
                    </div>
                    
                    <button type="submit" name="verify_otp" class="btn-primary"><i class="fas fa-check-circle me-2"></i>Verify OTP</button>
                    
                    <div class="text-center mt-3"><a href="?resend=otp" class="text-decoration-none"><i class="fas fa-redo-alt me-1"></i>Resend OTP</a></div>
                    
                    <a href="forgot-password.php" class="btn-outline-primary"><i class="fas fa-arrow-left me-2"></i>Start Over</a>
                </form>
                
                <script>
                    let timeLeft = 15 * 60;
                    const timerElement = document.getElementById('time');
                    function updateTimer() {
                        const minutes = Math.floor(timeLeft / 60);
                        const seconds = timeLeft % 60;
                        timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
                        if (timeLeft <= 0) { timerElement.textContent = "Expired"; timerElement.style.color = "#dc3545"; }
                        else { timeLeft--; }
                    }
                    setInterval(updateTimer, 1000);
                    document.querySelector('.otp-input').addEventListener('input', function(e) {
                        if (this.value.length === 6) document.getElementById('otpForm').submit();
                    });
                </script>
            <?php endif; ?>
            
            <!-- STEP 3: Reset Password -->
            <?php if ($step == 'reset'): ?>
                <form method="POST" id="resetForm">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">New Password</label>
                        <div class="input-group">
                            <span class="input-group-text bg-transparent"><i class="fas fa-lock text-muted"></i></span>
                            <input type="password" class="form-control" name="password" id="password" required>
                            <button class="btn btn-outline-secondary" type="button" id="togglePassword"><i class="fas fa-eye"></i></button>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Confirm Password</label>
                        <div class="input-group">
                            <span class="input-group-text bg-transparent"><i class="fas fa-lock text-muted"></i></span>
                            <input type="password" class="form-control" name="confirm_password" id="confirm_password" required>
                        </div>
                    </div>
                    
                    <div class="password-requirements">
                        <p><strong>Password must contain:</strong></p>
                        <ul>
                            <li id="length" class="invalid">At least 6 characters</li>
                            <li id="uppercase" class="invalid">At least one uppercase letter</li>
                            <li id="lowercase" class="invalid">At least one lowercase letter</li>
                            <li id="number" class="invalid">At least one number</li>
                            <li id="match" class="invalid">Passwords match</li>
                        </ul>
                    </div>
                    
                    <button type="submit" name="reset_password" class="btn-primary" id="submitBtn" disabled><i class="fas fa-sync-alt me-2"></i>Reset Password</button>
                    
                    <a href="index.php" class="btn-outline-primary"><i class="fas fa-sign-in-alt me-2"></i>Back to Login</a>
                </form>
                
                <script>
                    const password = document.getElementById('password');
                    const confirm = document.getElementById('confirm_password');
                    const lengthReq = document.getElementById('length');
                    const upperReq = document.getElementById('uppercase');
                    const lowerReq = document.getElementById('lowercase');
                    const numberReq = document.getElementById('number');
                    const matchReq = document.getElementById('match');
                    const submitBtn = document.getElementById('submitBtn');
                    
                    function checkPassword() {
                        const pass = password.value;
                        lengthReq.className = pass.length >= 6 ? 'valid' : 'invalid';
                        upperReq.className = /[A-Z]/.test(pass) ? 'valid' : 'invalid';
                        lowerReq.className = /[a-z]/.test(pass) ? 'valid' : 'invalid';
                        numberReq.className = /\d/.test(pass) ? 'valid' : 'invalid';
                        matchReq.className = (pass === confirm.value && pass !== '') ? 'valid' : 'invalid';
                        submitBtn.disabled = !(pass.length >= 6 && /[A-Z]/.test(pass) && /[a-z]/.test(pass) && /\d/.test(pass) && pass === confirm.value);
                    }
                    
                    password.addEventListener('input', checkPassword);
                    confirm.addEventListener('input', checkPassword);
                    
                    document.getElementById('togglePassword').addEventListener('click', function() {
                        const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
                        password.setAttribute('type', type);
                        this.querySelector('i').classList.toggle('fa-eye');
                        this.querySelector('i').classList.toggle('fa-eye-slash');
                    });
                </script>
            <?php endif; ?>
            
            <!-- STEP 4: Complete -->
            <?php if ($step == 'complete'): ?>
                <div class="text-center">
                    <i class="fas fa-check-circle text-success" style="font-size: 64px;"></i>
                    <h4 class="mt-3 fw-bold">Password Reset Complete!</h4>
                    <p class="text-muted">Your password has been successfully reset.</p>
                    <a href="index.php" class="btn-primary d-block text-center text-decoration-none"><i class="fas fa-sign-in-alt me-2"></i>Login Now</a>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>