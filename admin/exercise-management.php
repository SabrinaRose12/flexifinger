<?php
require_once 'includes/config.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

$auth->requireLogin();

$exerciseSets = $functions->getExerciseSets();
$allExercises = $functions->getAllExercises();

// Handle POST actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'add_exercise_set') {
        $setName = $_POST['set_name'] ?? '';
        $condition = $_POST['condition_target'] ?? '';
        $description = $_POST['description'] ?? '';
        if ($setName && $condition) {
            $functions->createExerciseSet($setName, $condition, $description, $_SESSION['admin_id']);
            $success = "Exercise set created successfully!";
            $exerciseSets = $functions->getExerciseSets();
        }
    } elseif ($action === 'delete_set') {
        $setId = $_POST['set_id'] ?? '';
        if ($setId && $functions->deleteExerciseSet($setId)) {
            $success = "Exercise set deleted!";
            $exerciseSets = $functions->getExerciseSets();
        }
    } elseif ($action === 'add_exercise') {
        $exerciseName = $_POST['exercise_name'] ?? '';
        $description = $_POST['description'] ?? '';
        $instructions = $_POST['instructions'] ?? '';
        $difficulty = $_POST['difficulty'] ?? 'beginner';
        $reps = $_POST['reps_default'] ?? 10;
        $sets = $_POST['sets_default'] ?? 3;
        $holdDuration = $_POST['hold_duration_sec'] ?? 5;
        $video_path = '';
        if (isset($_FILES['exercise_video']) && $_FILES['exercise_video']['error'] === UPLOAD_ERR_OK) {
            $uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/flexi/flexifinger/mobile/assets/videos/';
            if (!file_exists($uploadDir)) mkdir($uploadDir, 0777, true);
            $fileExt = strtolower(pathinfo($_FILES['exercise_video']['name'], PATHINFO_EXTENSION));
            if ($fileExt === 'mp4') {
                $fileName = preg_replace('/[^a-zA-Z0-9]/', '_', strtolower($exerciseName)) . '_' . time() . '.mp4';
                if (move_uploaded_file($_FILES['exercise_video']['tmp_name'], $uploadDir . $fileName)) {
                    $video_path = '/flexi/flexifinger/mobile/assets/videos/' . $fileName;
                }
            } else { $error = "Only MP4 format allowed!"; }
        }
        if ($exerciseName) {
            $functions->addExercise($exerciseName, $description, $instructions, $difficulty, $reps, $sets, $holdDuration, $video_path);
            $success = "Exercise added!";
            $allExercises = $functions->getAllExercises();
        }
    } elseif ($action === 'update_exercise') {
        $exercise_id = $_POST['exercise_id'] ?? '';
        $exercise_name = $_POST['exercise_name'] ?? '';
        $description = $_POST['description'] ?? '';
        $instructions = $_POST['instructions'] ?? '';
        $difficulty = $_POST['difficulty'] ?? 'beginner';
        $reps = $_POST['reps_default'] ?? 10;
        $sets = $_POST['sets_default'] ?? 3;
        $hold_duration_sec = $_POST['hold_duration_sec'] ?? 5;
        $video_path = $_POST['existing_video_path'] ?? '';
        if (isset($_FILES['exercise_video']) && $_FILES['exercise_video']['error'] === UPLOAD_ERR_OK) {
            $uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/flexi/flexifinger/mobile/assets/videos/';
            $fileExt = strtolower(pathinfo($_FILES['exercise_video']['name'], PATHINFO_EXTENSION));
            if ($fileExt === 'mp4') {
                $fileName = preg_replace('/[^a-zA-Z0-9]/', '_', strtolower($exercise_name)) . '_' . time() . '.mp4';
                if (move_uploaded_file($_FILES['exercise_video']['tmp_name'], $uploadDir . $fileName)) {
                    if (!empty($video_path) && file_exists($_SERVER['DOCUMENT_ROOT'] . $video_path)) unlink($_SERVER['DOCUMENT_ROOT'] . $video_path);
                    $video_path = '/flexi/flexifinger/mobile/assets/videos/' . $fileName;
                }
            } else { $error = "Only MP4 format allowed!"; }
        }
        if ($exercise_id && $exercise_name) {
            $conn = getDBConnection();
            $stmt = $conn->prepare("UPDATE exercises SET exercise_name=?, description=?, instructions=?, difficulty=?, reps_default=?, sets_default=?, hold_duration_sec=?, video_path=? WHERE exercise_id=?");
            $stmt->bind_param("ssssiiisi", $exercise_name, $description, $instructions, $difficulty, $reps, $sets, $hold_duration_sec, $video_path, $exercise_id);
            $stmt->execute();
            $success = "Exercise updated!";
            $allExercises = $functions->getAllExercises();
        }
    } elseif ($action === 'add_to_set') {
        $setId = $_POST['set_id'] ?? '';
        $exerciseId = $_POST['exercise_id'] ?? '';
        if ($setId && $exerciseId) {
            $conn = getDBConnection();
            $result = $conn->query("SELECT MAX(order_in_set) as max_order FROM set_exercises WHERE set_id = $setId");
            $order = ($result->fetch_assoc()['max_order'] ?? 0) + 1;
            if ($functions->addExerciseToSet($setId, $exerciseId, $order)) {
                $success = "Exercise added to set!";
                $exerciseSets = $functions->getExerciseSets();
            }
        }
    } elseif ($action === 'remove_from_set') {
        $setId = $_POST['set_id'] ?? '';
        $exerciseId = $_POST['exercise_id'] ?? '';
        if ($setId && $exerciseId && $functions->removeExerciseFromSet($setId, $exerciseId)) {
            $success = "Exercise removed from set!";
            $exerciseSets = $functions->getExerciseSets();
        }
    } elseif ($action === 'delete_exercise') {
        $exercise_id = $_POST['exercise_id'] ?? '';
        if ($exercise_id) {
            $conn = getDBConnection();
            $videoResult = $conn->query("SELECT video_path FROM exercises WHERE exercise_id = $exercise_id");
            $videoPath = $videoResult->fetch_assoc()['video_path'] ?? '';
            $conn->query("DELETE FROM set_exercises WHERE exercise_id = $exercise_id");
            $stmt = $conn->prepare("DELETE FROM exercises WHERE exercise_id = ?");
            $stmt->bind_param("i", $exercise_id);
            if ($stmt->execute()) {
                if (!empty($videoPath) && file_exists($_SERVER['DOCUMENT_ROOT'] . $videoPath)) unlink($_SERVER['DOCUMENT_ROOT'] . $videoPath);
                $success = "Exercise deleted!";
                $allExercises = $functions->getAllExercises();
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exercise Management - FlexiFinger Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/admin.css">
    <style>
        /* ===== TABS - TEKS SENTIASA HITAM ===== */
        .nav-tabs .nav-link {
            color: #1e293b !important;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-bottom: none;
            font-weight: 500;
        }
        
        .nav-tabs .nav-link:hover {
            color: #1e293b !important;
            background: #f1f5f9;
        }
        
        .nav-tabs .nav-link.active {
            color: #1e293b !important;
            background: white;
            border-top: 2px solid #667eea;
            border-left: 1px solid #e2e8f0;
            border-right: 1px solid #e2e8f0;
            border-bottom: 2px solid white;
        }
        /* Additional style for sidebar logo */
        .sidebar-header {
            text-align: center;
        }
        .sidebar-logo {
            width: 50px;
            height: 50px;
            object-fit: contain;
            margin-bottom: 12px;
            border-radius: 12px;
            padding: 5px;
        }
        .sidebar-header h3 i {
            display: none;
        }
    </style>
</head>
<body>
    <div class="sidebar">
    <div class="sidebar-header">
        <img src="images/logowhite.png" alt="FlexiFinger Logo" class="sidebar-logo" style="width:80px;height:80px;" onerror="this.src='https://placehold.co/32x32?text=FF'">
        <h5>Admin Panel</h5>
    </div>
        <nav class="nav flex-column mt-4">
            <a href="dashboard.php" class="nav-link"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="approval.php" class="nav-link"><i class="fas fa-user-check"></i> Approval</a>
            <a href="patient-management.php" class="nav-link"><i class="fas fa-users"></i> Patient Management</a>
            <a href="therapist-management.php" class="nav-link"><i class="fas fa-user-md"></i> Therapist Management</a>
            <a href="exercise-management.php" class="nav-link active"><i class="fas fa-dumbbell"></i> Exercise Management</a>
            <a href="reporting.php" class="nav-link"><i class="fas fa-chart-bar"></i> Reports</a>
            <a href="profile.php" class="nav-link"><i class="fas fa-user-cog"></i> Settings</a>
            <a href="logout.php" class="nav-link mt-4"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </nav>
    </div>

    <div class="main-content">
        <div class="navbar-top">
            <div class="welcome-text">
                <h4>Exercise Management</h4>
                <p>Manage exercise sets, exercises, and videos</p>
            </div>
            <div class="admin-badge"><i class="fas fa-user-shield"></i> Administrator</div>
        </div>

        <?php if (isset($success)): ?>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i><?php echo htmlspecialchars($success); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>
        
        <?php if (isset($error)): ?>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><?php echo htmlspecialchars($error); ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>

        <ul class="nav nav-tabs">
            <li class="nav-item">
                <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#sets">Exercise Sets</button>
            </li>
            <li class="nav-item">
                <button class="nav-link" data-bs-toggle="tab" data-bs-target="#exercises">All Exercises</button>
            </li>
        </ul>

        <div class="tab-content mt-3">
            <!-- Tab 1: Exercise Sets -->
            <div class="tab-pane fade show active" id="sets">
                <div class="row">
                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-header">Create New Set</div>
                            <div class="card-body">
                                <form method="POST">
                                    <input type="hidden" name="action" value="add_exercise_set">
                                    <div class="mb-3"><label class="form-label">Set Name *</label><input type="text" class="form-control" name="set_name" required></div>
                                    <div class="mb-3"><label class="form-label">Target Condition *</label><input type="text" class="form-control" name="condition_target" required></div>
                                    <div class="mb-3"><label class="form-label">Description</label><textarea class="form-control" name="description" rows="3"></textarea></div>
                                    <button type="submit" class="btn btn-primary w-100">Create Set</button>
                                </form>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-8">
                        <?php foreach ($exerciseSets as $set): ?>
                        <div class="card mb-3" style="border-left: 4px solid #667eea;">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div>
                                        <h5><?php echo htmlspecialchars($set['set_name']); ?></h5>
                                        <span class="badge bg-info"><?php echo htmlspecialchars($set['condition_target']); ?></span>
                                        <span class="badge bg-secondary ms-2"><?php echo count($set['exercises']); ?> exercises</span>
                                    </div>
                                    <button class="btn btn-danger btn-sm" data-bs-toggle="modal" data-bs-target="#deleteSetModal" onclick="setDeleteSet(<?php echo $set['set_id']; ?>, '<?php echo htmlspecialchars($set['set_name']); ?>')"><i class="fas fa-trash"></i> Delete</button>
                                </div>
                                <div class="mt-3">
                                    <?php foreach ($set['exercises'] as $exercise): ?>
                                    <div class="exercise-item mb-2 p-2 bg-light rounded">
                                        <div class="d-flex justify-content-between">
                                            <div>
                                                <strong><?php echo htmlspecialchars($exercise['exercise_name']); ?></strong><br>
                                                <small><?php echo $exercise['reps_default']; ?> reps x <?php echo $exercise['sets_default']; ?> sets</small>
                                            </div>
                                            <form method="POST">
                                                <input type="hidden" name="action" value="remove_from_set">
                                                <input type="hidden" name="set_id" value="<?php echo $set['set_id']; ?>">
                                                <input type="hidden" name="exercise_id" value="<?php echo $exercise['exercise_id']; ?>">
                                                <button type="submit" class="btn btn-outline-danger btn-sm">Remove</button>
                                            </form>
                                        </div>
                                    </div>
                                    <?php endforeach; ?>
                                    <button class="btn btn-primary btn-sm mt-2" data-bs-toggle="modal" data-bs-target="#addToSetModal" onclick="setAddToSet(<?php echo $set['set_id']; ?>, '<?php echo htmlspecialchars($set['set_name']); ?>')"><i class="fas fa-plus"></i> Add Exercise</button>
                                </div>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>

            <!-- Tab 2: All Exercises -->
            <div class="tab-pane fade" id="exercises">
                <div class="text-end mb-3">
                    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addExerciseModal"><i class="fas fa-plus"></i> Add New Exercise</button>
                </div>
                <div class="row">
                    <?php foreach ($allExercises as $exercise): ?>
                    <div class="col-md-4 mb-4">
                        <div class="card h-100">
                            <div class="card-body">
                                <h6><?php echo htmlspecialchars($exercise['exercise_name']); ?></h6>
                                <span class="badge bg-<?php echo $exercise['difficulty']; ?>"><?php echo ucfirst($exercise['difficulty']); ?></span>
                                <?php if(!empty($exercise['video_path'])): ?>
                                    <div class="mt-2"><i class="fas fa-video text-primary"></i> <small>Video attached</small></div>
                                <?php endif; ?>
                                <div class="mt-3 d-flex justify-content-between">
                                    <button class="btn btn-warning btn-sm" data-bs-toggle="modal" data-bs-target="#editExerciseModal" onclick="editExercise(<?php echo htmlspecialchars(json_encode($exercise)); ?>)"><i class="fas fa-edit"></i> Edit</button>
                                    <button class="btn btn-danger btn-sm" onclick="confirmDeleteExercise(<?php echo $exercise['exercise_id']; ?>, '<?php echo htmlspecialchars($exercise['exercise_name']); ?>')"><i class="fas fa-trash"></i> Delete</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>

    <!-- Add Exercise Modal -->
    <div class="modal fade" id="addExerciseModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header"><h5 class="modal-title">Add New Exercise</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
                <form method="POST" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="add_exercise">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6"><label class="form-label">Exercise Name *</label><input type="text" class="form-control" name="exercise_name" required></div>
                            <div class="col-md-6"><label class="form-label">Difficulty</label><select class="form-select" name="difficulty"><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option></select></div>
                            <div class="col-12 mt-3"><label class="form-label">Description</label><textarea class="form-control" name="description" rows="2"></textarea></div>
                            <div class="col-md-4 mt-3"><label class="form-label">Repetitions</label><input type="number" class="form-control" name="reps_default" value="10"></div>
                            <div class="col-md-4 mt-3"><label class="form-label">Sets</label><input type="number" class="form-control" name="sets_default" value="3"></div>
                            <div class="col-md-4 mt-3"><label class="form-label">Hold Duration (sec)</label><input type="number" class="form-control" name="hold_duration_sec" value="5"></div>
                            <div class="col-12 mt-3"><label class="form-label">Instructions</label><textarea class="form-control" name="instructions" rows="4"></textarea></div>
                            <div class="col-12 mt-3"><label class="form-label">Exercise Video (MP4 only)</label><input type="file" class="form-control" name="exercise_video" accept="video/mp4"><small>Only MP4 format allowed</small></div>
                        </div>
                    </div>
                    <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button><button type="submit" class="btn btn-primary">Add Exercise</button></div>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit Exercise Modal -->
    <div class="modal fade" id="editExerciseModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header"><h5 class="modal-title">Edit Exercise</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
                <form method="POST" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="update_exercise">
                    <input type="hidden" name="exercise_id" id="edit_exercise_id">
                    <input type="hidden" name="existing_video_path" id="edit_existing_video">
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6"><label class="form-label">Exercise Name *</label><input type="text" class="form-control" name="exercise_name" id="edit_exercise_name" required></div>
                            <div class="col-md-6"><label class="form-label">Difficulty</label><select class="form-select" name="difficulty" id="edit_difficulty"><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option></select></div>
                            <div class="col-12 mt-3"><label class="form-label">Description</label><textarea class="form-control" name="description" id="edit_description" rows="2"></textarea></div>
                            <div class="col-md-4 mt-3"><label class="form-label">Repetitions</label><input type="number" class="form-control" name="reps_default" id="edit_reps"></div>
                            <div class="col-md-4 mt-3"><label class="form-label">Sets</label><input type="number" class="form-control" name="sets_default" id="edit_sets"></div>
                            <div class="col-md-4 mt-3"><label class="form-label">Hold Duration</label><input type="number" class="form-control" name="hold_duration_sec" id="edit_hold"></div>
                            <div class="col-12 mt-3"><label class="form-label">Instructions</label><textarea class="form-control" name="instructions" id="edit_instructions" rows="4"></textarea></div>
                            <div class="col-12 mt-3"><div id="current_video_preview"></div><label class="form-label mt-2">Upload New Video (MP4 only)</label><input type="file" class="form-control" name="exercise_video" accept="video/mp4"><small>Leave empty to keep current video</small></div>
                        </div>
                    </div>
                    <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button><button type="submit" class="btn btn-primary">Save Changes</button></div>
                </form>
            </div>
        </div>
    </div>

    <!-- Add to Set Modal -->
    <div class="modal fade" id="addToSetModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header"><h5 class="modal-title" id="addToSetModalTitle">Add to Exercise Set</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
                <form method="POST">
                    <input type="hidden" name="action" value="add_to_set">
                    <input type="hidden" name="set_id" id="addToSetSetId">
                    <div class="modal-body">
                        <select class="form-select" name="exercise_id" required>
                            <option value="">Choose exercise...</option>
                            <?php foreach ($allExercises as $exercise): ?>
                                <option value="<?php echo $exercise['exercise_id']; ?>"><?php echo htmlspecialchars($exercise['exercise_name']); ?> (<?php echo $exercise['difficulty']; ?>)</option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button><button type="submit" class="btn btn-primary">Add to Set</button></div>
                </form>
            </div>
        </div>
    </div>

    <!-- Delete Set Modal -->
    <div class="modal fade" id="deleteSetModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header"><h5 class="modal-title">Confirm Delete</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
                <form method="POST">
                    <input type="hidden" name="action" value="delete_set">
                    <input type="hidden" name="set_id" id="deleteSetId">
                    <div class="modal-body"><p>Delete <strong id="deleteSetName"></strong>? This cannot be undone.</p></div>
                    <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button><button type="submit" class="btn btn-danger">Delete</button></div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function setDeleteSet(id, name) { document.getElementById('deleteSetId').value = id; document.getElementById('deleteSetName').textContent = name; }
        function setAddToSet(id, name) { document.getElementById('addToSetSetId').value = id; document.getElementById('addToSetModalTitle').textContent = 'Add Exercise to ' + name; }
        function editExercise(ex) {
            document.getElementById('edit_exercise_id').value = ex.exercise_id;
            document.getElementById('edit_exercise_name').value = ex.exercise_name;
            document.getElementById('edit_description').value = ex.description || '';
            document.getElementById('edit_instructions').value = ex.instructions || '';
            document.getElementById('edit_difficulty').value = ex.difficulty || 'beginner';
            document.getElementById('edit_reps').value = ex.reps_default || 10;
            document.getElementById('edit_sets').value = ex.sets_default || 3;
            document.getElementById('edit_hold').value = ex.hold_duration_sec || 5;
            document.getElementById('edit_existing_video').value = ex.video_path || '';
            let preview = document.getElementById('current_video_preview');
            if (ex.video_path) preview.innerHTML = '<video controls style="max-width:100%;max-height:100px"><source src="' + ex.video_path + '" type="video/mp4"></video><br><small>Current video</small>';
            else preview.innerHTML = '<span class="text-muted">No video attached</span>';
        }
        function confirmDeleteExercise(id, name) { if(confirm('Delete exercise "'+name+'"?')){ let f=document.createElement('form'); f.method='POST'; f.innerHTML='<input type="hidden" name="action" value="delete_exercise"><input type="hidden" name="exercise_id" value="'+id+'">'; document.body.appendChild(f); f.submit(); } }
    </script>
</body>
</html>