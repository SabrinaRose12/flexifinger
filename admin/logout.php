<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';

// Check if it's a POST request with confirmation
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['confirm_logout'])) {
    $auth->logout();
    header("Location: index.php");
    exit();
}

// If direct access without POST, show confirmation page
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Logout - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Inter', sans-serif;
        }
        .logout-card {
            background: white;
            border-radius: 24px;
            padding: 40px;
            text-align: center;
            max-width: 450px;
            width: 100%;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
        }
        .logout-icon {
            width: 80px;
            height: 80px;
            background: #fee2e2;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .logout-icon i {
            font-size: 40px;
            color: #ef4444;
        }
        h3 {
            color: #1e293b;
            margin-bottom: 10px;
        }
        p {
            color: #64748b;
            margin-bottom: 30px;
        }
        .btn-confirm {
            background: #ef4444;
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 12px;
            font-weight: 600;
            margin-right: 10px;
        }
        .btn-confirm:hover {
            background: #dc2626;
        }
        .btn-cancel {
            background: #e2e8f0;
            color: #1e293b;
            border: none;
            padding: 12px 30px;
            border-radius: 12px;
            font-weight: 600;
            text-decoration: none;
        }
        .btn-cancel:hover {
            background: #cbd5e1;
            color: #1e293b;
        }
    </style>
</head>
<body>
    <div class="logout-card">
        <div class="logout-icon">
            <i class="fas fa-sign-out-alt"></i>
        </div>
        <h3>Confirm Logout</h3>
        <p>Are you sure you want to logout from your admin account?</p>
        <form method="POST">
            <input type="hidden" name="confirm_logout" value="1">
            <button type="submit" class="btn-confirm"><i class="fas fa-check-circle me-2"></i> Yes, Logout</button>
            <a href="dashboard.php" class="btn-cancel"><i class="fas fa-times-circle me-2"></i> Cancel</a>
        </form>
    </div>
</body>
</html>
<?php
exit();
?>