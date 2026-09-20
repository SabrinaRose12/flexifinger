<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';

$error = '';

if ($auth->isLoggedIn()) {
    header("Location: dashboard.php");
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        $error = "Please enter both email and password";
    } else {
        if ($auth->adminLogin($email, $password)) {
            header("Location: dashboard.php");
            exit();
        } else {
            $error = "Invalid email or password";
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - FlexiFinger Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            position: relative;
            overflow: hidden;
        }
        body::before {
            content: '';
            position: absolute;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 1px, transparent 1px);
            background-size: 50px 50px;
            animation: moveBackground 60s linear infinite;
            opacity: 0.5;
        }
        @keyframes moveBackground {
            0% { transform: translate(0, 0); }
            100% { transform: translate(100px, 100px); }
        }
        .login-container { width: 100%; max-width: 460px; position: relative; z-index: 1; }
        .login-card {
            background: rgba(255, 255, 255, 0.98);
            border-radius: 32px;
            padding: 48px 40px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            backdrop-filter: blur(10px);
            transition: transform 0.3s ease;
        }
        .login-card:hover { transform: translateY(-5px); }
        .logo { text-align: center; margin-bottom: 32px; }
        .logo-img {
            width: 200px;
            height: 200px;
            object-fit: contain;
            margin-bottom: 20px;
        }
        .logo h2 {
            font-size: 28px; font-weight: 800;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            margin-bottom: 8px;
        }
        .logo p { color: #64748b; font-size: 14px; font-weight: 500; }
        .error-message {
            background: #fee2e2;
            border-left: 4px solid #ef4444;
            padding: 14px 16px;
            border-radius: 12px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .error-message i { color: #ef4444; font-size: 18px; }
        .error-message span { color: #991b1b; font-size: 14px; font-weight: 500; }
        .input-group { margin-bottom: 24px; }
        .input-label { display: block; font-size: 14px; font-weight: 600; color: #1e293b; margin-bottom: 8px; }
        .input-wrapper { position: relative; }
        .input-wrapper i:first-child {
            position: absolute;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            color: #94a3b8;
            font-size: 18px;
        }
        .input-wrapper input {
            width: 100%;
            padding: 14px 16px 14px 48px;
            border: 2px solid #e2e8f0;
            border-radius: 16px;
            font-size: 15px;
            font-family: 'Inter', sans-serif;
            transition: all 0.3s;
            background: #f8fafc;
        }
        .input-wrapper input:focus {
            outline: none;
            border-color: #667eea;
            background: white;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
        }
        .input-wrapper input:focus + i:first-child { color: #667eea; }
        .toggle-password {
            position: absolute;
            right: 16px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #94a3b8;
        }
        .toggle-password:hover { color: #667eea; }
        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 16px;
            color: white;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s;
            margin-top: 8px;
        }
        .btn-login:hover { transform: translateY(-2px); box-shadow: 0 10px 25px -5px rgba(102, 126, 234, 0.4); }
        .btn-login i { margin-right: 8px; }
        .forgot-link { text-align: center; margin-top: 24px; }
        .forgot-link a { color: #64748b; text-decoration: none; font-size: 14px; font-weight: 500; }
        .forgot-link a:hover { color: #667eea; }
        @media (max-width: 480px) { .login-card { padding: 32px 24px; } .logo h2 { font-size: 24px; } }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-card">
            <div class="logo">
                <img src="images/logo1.png" alt="FlexiFinger Logo" class="logo-img" onerror="this.src='https://placehold.co/80x80?text=FF'">
                <h2>FlexiFinger Admin</h2>
                <p>Finger Exercise Monitoring System</p>
            </div>
            
            <?php if ($error): ?>
                <div class="error-message"><i class="fas fa-exclamation-circle"></i><span><?php echo htmlspecialchars($error); ?></span></div>
            <?php endif; ?>
            
            <form method="POST" action="">
                <div class="input-group">
                    <label class="input-label">Email Address</label>
                    <div class="input-wrapper">
                        <i class="fas fa-envelope"></i>
                        <input type="email" name="email" placeholder="admin@flexifinger.com" required value="admin@flexifinger.com">
                    </div>
                </div>
                
                <div class="input-group">
                    <label class="input-label">Password</label>
                    <div class="input-wrapper">
                        <i class="fas fa-lock"></i>
                        <input type="password" name="password" id="password" placeholder="Enter your password" required>
                        <i class="fas fa-eye-slash toggle-password" id="togglePassword"></i>
                    </div>
                </div>
                
                <button type="submit" class="btn-login"><i class="fas fa-sign-in-alt"></i> Login to Dashboard</button>
                
                <div class="forgot-link"><a href="forgot-password.php"><i class="fas fa-key"></i> Forgot Password?</a></div>
            </form>
        </div>
    </div>

    <script>
        const togglePassword = document.getElementById('togglePassword');
        const password = document.getElementById('password');
        togglePassword.addEventListener('click', function() {
            const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
            password.setAttribute('type', type);
            this.classList.toggle('fa-eye');
            this.classList.toggle('fa-eye-slash');
        });
    </script>
</body>
</html>