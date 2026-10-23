# =============================================================================
# MathTuro LMS -- Fully Automated QA Master Runner
# Bootstraps ephemeral test users + fixtures, runs Phase 3 + Phase 4/5 suites,
# then cleans up via admin_qa_cleanup_test_users() RPC.
#
# PREREQUISITES (set in your PowerShell session before running):
#   $env:SUPABASE_ANON_KEY         = '<your-anon-key>'
#   $env:SUPABASE_SERVICE_ROLE_KEY = '<your-service-role-key>'
#
# USAGE:
#   cd d:\Personal_Projects\MathTuro
#   powershell -ExecutionPolicy Bypass -File scripts/qa/run_full_qa_suite.ps1
# =============================================================================

$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------------
# 0. CONFIGURATION
# ---------------------------------------------------------------------------
$BASE    = "https://ynkzcybctsstpqxdoweq.supabase.co"
$ANON    = $env:SUPABASE_ANON_KEY
$SVC_KEY = $env:SUPABASE_SERVICE_ROLE_KEY

if ([string]::IsNullOrWhiteSpace($ANON)) {
    Write-Host "ERROR: `$env:SUPABASE_ANON_KEY is not set." -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($SVC_KEY)) {
    Write-Host "ERROR: `$env:SUPABASE_SERVICE_ROLE_KEY is not set." -ForegroundColor Red
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir    = $env:TEMP

$TEACHER_EMAIL   = "qa-teacher-auto@mathturo-qa.test"
$TEACHER_PASS    = "QaTeacher!Secure2026x"
$STUDENT_A_EMAIL = "qa-student-a-auto@mathturo-qa.test"
$STUDENT_A_PASS  = "QaStudentA!Secure2026x"
$STUDENT_B_EMAIL = "qa-student-b-auto@mathturo-qa.test"
$STUDENT_B_PASS  = "QaStudentB!Secure2026x"

$SvcHeaders = @{
    "apikey"        = $SVC_KEY
    "Authorization" = "Bearer $SVC_KEY"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

$CreatedIds = @{
    TeacherId   = $null
    StudentAId  = $null
    StudentBId  = $null
    Module1Id   = $null
    Module2Id   = $null
    PreTest1Id  = $null
    PostTest1Id = $null
    Quiz1Id     = $null
    PreTest2Id  = $null
}

# ---------------------------------------------------------------------------
# HELPER: Invoke Supabase REST with service role
# ---------------------------------------------------------------------------
function Invoke-Svc {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers = $SvcHeaders,
        [string]$Body = $null,
        [string]$Prefer = "return=representation"
    )
    $h = $Headers.Clone()
    $h["Prefer"] = $Prefer
    try {
        $args = @{ Method = $Method; Uri = $Uri; Headers = $h; UseBasicParsing = $true }
        if ($Body) { $args.Body = $Body }
        $r = Invoke-WebRequest @args
        return @{ Ok = $true; Status = [int]$r.StatusCode; Data = ($r.Content | ConvertFrom-Json) }
    } catch {
        $resp = $_.Exception.Response
        $msg = ""
        if ($resp) {
            $stream = $resp.GetResponseStream()
            if ($stream.CanSeek) { $stream.Position = 0 }
            try { $msg = (New-Object IO.StreamReader($stream)).ReadToEnd() } catch { }
        }
        return @{ Ok = $false; Status = [int]$resp.StatusCode; Msg = $msg }
    }
}

# ---------------------------------------------------------------------------
# HELPER: Create auth user via Admin API
# ---------------------------------------------------------------------------
function Create-AuthUser {
    param([string]$Email, [string]$Password, [string]$DisplayName, [string]$Role = "student")
    $names = $DisplayName -split " ", 2
    $fn = $names[0]
    $ln = if ($names.Count -gt 1) { $names[1] } else { "QA" }
    $meta = [ordered]@{
        full_name  = $DisplayName
        first_name = $fn
        last_name  = $ln
        role       = $Role
    }
    if ($Role -eq "student") {
        $meta["lrn"]         = "999999" + [Math]::Abs($Email.GetHashCode() % 900000 + 100000).ToString()
        $meta["gender"]      = "Male"
        $meta["school_year"] = "S.Y. 2026-2027"
    }
    $body = @{
        email         = $Email
        password      = $Password
        email_confirm = $true
        user_metadata = $meta
    } | ConvertTo-Json -Depth 3

    $r = Invoke-Svc -Method POST -Uri "$BASE/auth/v1/admin/users" -Body $body
    if ($r.Ok) {
        Write-Host "    [OK] Auth user created: $($r.Data.id)" -ForegroundColor Green
        return $r.Data.id
    } else {
        Write-Host "    [FAIL] Auth create failed for ${Email}: $($r.Msg)" -ForegroundColor Red
        return $null
    }
}

# ---------------------------------------------------------------------------
# HELPER: Upsert public.users row (service_role now bypasses the trigger)
# ---------------------------------------------------------------------------
function Upsert-PublicUser {
    param([string]$UserId, [string]$Email, [string]$Role, [string]$DisplayName)
    $names = $DisplayName -split " ", 2
    $fn = $names[0]
    $ln = if ($names.Count -gt 1) { $names[1] } else { "QA" }

    $patch = [ordered]@{
        full_name       = $DisplayName
        first_name      = $fn
        last_name       = $ln
        role            = $Role
        approval_status = "approved"
        is_active       = $true
        is_archived     = $false
    }
    if ($Role -eq "student") {
        $patch["lrn"]         = "999999" + [Math]::Abs($Email.GetHashCode() % 900000 + 100000).ToString()
        $patch["gender"]      = "Male"
        $patch["school_year"] = "S.Y. 2026-2027"
    }
    $r = Invoke-Svc -Method PATCH -Uri "$BASE/rest/v1/users?id=eq.$UserId" -Body ($patch | ConvertTo-Json -Depth 3)
    if ($r.Ok) {
        Write-Host "    [OK] public.users approved as $Role" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] public.users PATCH: $($r.Status) $($r.Msg)" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# HELPER: Insert a row and return the id
# ---------------------------------------------------------------------------
function Insert-Row {
    param([string]$Table, [hashtable]$Data, [string]$Label)
    $h = $SvcHeaders.Clone()
    $h["Prefer"] = "return=representation"
    $r = Invoke-Svc -Method POST -Uri "$BASE/rest/v1/$Table" -Headers $h -Body ($Data | ConvertTo-Json -Depth 5)
    if ($r.Ok -and $r.Data) {
        $id = if ($r.Data -is [array]) { $r.Data[0].id } else { $r.Data.id }
        Write-Host "    [OK] $Label created ($id)" -ForegroundColor Green
        return $id
    } else {
        Write-Host "    [FAIL] $Label insert failed ($($r.Status)): $($r.Msg)" -ForegroundColor Red
        return $null
    }
}

function Insert-RawJson {
    param([string]$Table, [string]$JsonBody, [string]$Label)
    $h = $SvcHeaders.Clone()
    $h["Prefer"] = "return=representation"
    $r = Invoke-Svc -Method POST -Uri "$BASE/rest/v1/$Table" -Headers $h -Body $JsonBody
    if ($r.Ok -and $r.Data) {
        $id = if ($r.Data -is [array]) { $r.Data[0].id } else { $r.Data.id }
        Write-Host "    [OK] $Label created ($id)" -ForegroundColor Green
        return $id
    } else {
        Write-Host "    [FAIL] $Label insert failed ($($r.Status)): $($r.Msg)" -ForegroundColor Red
        return $null
    }
}

# ---------------------------------------------------------------------------
# PHASE 1: BOOTSTRAP TEST USERS
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Magenta
Write-Host "  MATHTURO LMS -- AUTOMATED QA MASTER RUNNER" -ForegroundColor Magenta
Write-Host "  Target: $BASE" -ForegroundColor Magenta
Write-Host ("  Time:   " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -ForegroundColor Magenta
Write-Host "===========================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host ">>> PHASE 1: Bootstrapping Ephemeral QA Test Accounts..." -ForegroundColor Yellow

Write-Host "  -> Creating teacher account: $TEACHER_EMAIL" -ForegroundColor Cyan
$CreatedIds.TeacherId = Create-AuthUser -Email $TEACHER_EMAIL -Password $TEACHER_PASS -DisplayName "QA Teacher Auto" -Role "teacher"
if ($CreatedIds.TeacherId) {
    Upsert-PublicUser -UserId $CreatedIds.TeacherId -Email $TEACHER_EMAIL -Role "teacher" -DisplayName "QA Teacher Auto"
}

Write-Host "  -> Creating student A: $STUDENT_A_EMAIL" -ForegroundColor Cyan
$CreatedIds.StudentAId = Create-AuthUser -Email $STUDENT_A_EMAIL -Password $STUDENT_A_PASS -DisplayName "QA Student Alpha" -Role "student"
if ($CreatedIds.StudentAId) {
    Upsert-PublicUser -UserId $CreatedIds.StudentAId -Email $STUDENT_A_EMAIL -Role "student" -DisplayName "QA Student Alpha"
}

Write-Host "  -> Creating student B: $STUDENT_B_EMAIL" -ForegroundColor Cyan
$CreatedIds.StudentBId = Create-AuthUser -Email $STUDENT_B_EMAIL -Password $STUDENT_B_PASS -DisplayName "QA Student Beta" -Role "student"
if ($CreatedIds.StudentBId) {
    Upsert-PublicUser -UserId $CreatedIds.StudentBId -Email $STUDENT_B_EMAIL -Role "student" -DisplayName "QA Student Beta"
}

if (-not $CreatedIds.TeacherId -or -not $CreatedIds.StudentAId -or -not $CreatedIds.StudentBId) {
    Write-Host "FATAL: Account creation incomplete. Aborting." -ForegroundColor Red
    & powershell -ExecutionPolicy Bypass -Command "Invoke-RestMethod -Method POST -Uri '$BASE/rest/v1/rpc/admin_qa_cleanup_test_users' -Headers @{apikey='$SVC_KEY';Authorization='Bearer $SVC_KEY';'Content-Type'='application/json'} -Body '{}'"
    exit 1
}

Write-Host ""
Write-Host "  [OK] All 3 QA accounts created." -ForegroundColor Green
Start-Sleep -Seconds 3

# ---------------------------------------------------------------------------
# PHASE 2: CREATE QA FIXTURES (Modules, Assessments, Quizzes, Questions)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Yellow
Write-Host ">>> PHASE 2: Creating QA Fixtures (Modules + Assessments + Questions)..." -ForegroundColor Yellow
Write-Host "===========================================================================" -ForegroundColor Yellow

$tid = $CreatedIds.TeacherId

# Module 1
$CreatedIds.Module1Id = Insert-Row -Table "modules" -Label "QA Module 1" -Data @{
    title       = "QA Module 1 - Fractions"
    description = "QA ephemeral test module"
    teacher_id  = $tid
    status      = "published"
    order_index = 900
    term_number = 1
    week_number = 1
}

# Module 2
$CreatedIds.Module2Id = Insert-Row -Table "modules" -Label "QA Module 2" -Data @{
    title       = "QA Module 2 - Decimals"
    description = "QA ephemeral test module 2"
    teacher_id  = $tid
    status      = "published"
    order_index = 901
    term_number = 1
    week_number = 2
}

# Module 1 Pre-Test
if ($CreatedIds.Module1Id) {
    $CreatedIds.PreTest1Id = Insert-Row -Table "module_assessments" -Label "M1 Pre-Test" -Data @{
        module_id          = $CreatedIds.Module1Id
        assessment_type    = "pre_test"
        title              = "QA Pre-Test: Fractions Entry"
        total_items        = 4
        max_attempts       = 3
        passing_threshold  = 75.00
        is_published       = $true
        created_by         = $tid
    }
}

# Module 1 Post-Test
if ($CreatedIds.Module1Id) {
    $CreatedIds.PostTest1Id = Insert-Row -Table "module_assessments" -Label "M1 Post-Test" -Data @{
        module_id          = $CreatedIds.Module1Id
        assessment_type    = "post_test"
        title              = "QA Post-Test: Fractions Exit"
        total_items        = 4
        max_attempts       = 3
        passing_threshold  = 75.00
        is_published       = $true
        created_by         = $tid
    }
}

# Module 2 Pre-Test
if ($CreatedIds.Module2Id) {
    $CreatedIds.PreTest2Id = Insert-Row -Table "module_assessments" -Label "M2 Pre-Test" -Data @{
        module_id          = $CreatedIds.Module2Id
        assessment_type    = "pre_test"
        title              = "QA Pre-Test: Decimals Entry"
        total_items        = 4
        max_attempts       = 3
        passing_threshold  = 75.00
        is_published       = $true
        created_by         = $tid
    }
}

# Module 1 Regular Quiz
if ($CreatedIds.Module1Id) {
    $CreatedIds.Quiz1Id = Insert-Row -Table "quizzes" -Label "M1 Quiz" -Data @{
        module_id      = $CreatedIds.Module1Id
        title          = "QA Quiz: Fractions Formative"
        total_items    = 4
        passing_score  = 3
        is_published   = $true
        created_by     = $tid
        teacher_id     = $tid
        order_index    = 1
    }
}

# Add questions to each assessment and quiz matching test key contract:
# Key: 1="A", 2="true", 3="42", 4="A"
foreach ($pair in @(
    @{ Id = $CreatedIds.PreTest1Id;  Kind = "assessment_id"; Label = "M1 Pre-Test Q" }
    @{ Id = $CreatedIds.PostTest1Id; Kind = "assessment_id"; Label = "M1 Post-Test Q" }
    @{ Id = $CreatedIds.PreTest2Id;  Kind = "assessment_id"; Label = "M2 Pre-Test Q" }
    @{ Id = $CreatedIds.Quiz1Id;     Kind = "quiz_id";       Label = "M1 Quiz Q" }
)) {
    if (-not $pair.Id) { continue }
    $q1Json = @"
{
    "order_index": 1,
    "question_text": "What is 1/2 + 1/4?",
    "question_type": "multiple_choice",
    "options": [
        {"id": "A", "text": "3/4"},
        {"id": "B", "text": "1/2"},
        {"id": "C", "text": "1/4"},
        {"id": "D", "text": "2/3"}
    ],
    "correct_answer": "A",
    "points": 1,
    "$($pair.Kind)": "$($pair.Id)"
}
"@
    $q2Json = @"
{
    "order_index": 2,
    "question_text": "Is 3/4 greater than 1/2?",
    "question_type": "true_false",
    "options": [
        {"id": "true", "text": "True"},
        {"id": "false", "text": "False"}
    ],
    "correct_answer": "true",
    "points": 1,
    "$($pair.Kind)": "$($pair.Id)"
}
"@
    $q3Json = @"
{
    "order_index": 3,
    "question_text": "What is 6 * 7?",
    "question_type": "identification",
    "options": null,
    "correct_answer": "42",
    "points": 1,
    "$($pair.Kind)": "$($pair.Id)"
}
"@
    $q4Json = @"
{
    "order_index": 4,
    "question_text": "Which fraction is equivalent to 2/4?",
    "question_type": "multiple_choice",
    "options": [
        {"id": "A", "text": "1/2"},
        {"id": "B", "text": "3/4"},
        {"id": "C", "text": "1/3"},
        {"id": "D", "text": "2/5"}
    ],
    "correct_answer": "A",
    "points": 1,
    "$($pair.Kind)": "$($pair.Id)"
}
"@
    Insert-RawJson -Table "quiz_questions" -JsonBody $q1Json -Label "$($pair.Label)1" | Out-Null
    Insert-RawJson -Table "quiz_questions" -JsonBody $q2Json -Label "$($pair.Label)2" | Out-Null
    Insert-RawJson -Table "quiz_questions" -JsonBody $q3Json -Label "$($pair.Label)3" | Out-Null
    Insert-RawJson -Table "quiz_questions" -JsonBody $q4Json -Label "$($pair.Label)4" | Out-Null
}

Write-Host ""
Write-Host "  [OK] QA fixtures created." -ForegroundColor Green
Start-Sleep -Seconds 2

# ---------------------------------------------------------------------------
# PHASE 3: RUN PHASE 4 & 5 SUITE
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Cyan
Write-Host ">>> PHASE 3: Running Phase 4+5 Suite (EXP, Archiving)..." -ForegroundColor Cyan
Write-Host "===========================================================================" -ForegroundColor Cyan

$p45Script = Join-Path $ScriptDir "verify_phase4_5_authenticated_api.ps1"
& powershell -ExecutionPolicy Bypass -File $p45Script `
    -TeacherEmail   $TEACHER_EMAIL   -TeacherPassword  $TEACHER_PASS `
    -StudentAEmail  $STUDENT_A_EMAIL -StudentAPassword $STUDENT_A_PASS `
    -StudentBEmail  $STUDENT_B_EMAIL -StudentBPassword $STUDENT_B_PASS `
    -BaseUrl        $BASE `
    -AnonKey        $ANON

# ---------------------------------------------------------------------------
# PHASE 4: RUN PHASE 3 SUITE (Security, Gating, Zero-Leakage)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Cyan
Write-Host ">>> PHASE 4: Running Phase 3 Suite (Security and Gating)..." -ForegroundColor Cyan
Write-Host "===========================================================================" -ForegroundColor Cyan

$p3Script = Join-Path $ScriptDir "verify_phase3_authenticated_api.ps1"
& powershell -ExecutionPolicy Bypass -File $p3Script `
    -TeacherEmail   $TEACHER_EMAIL   -TeacherPassword  $TEACHER_PASS `
    -StudentAEmail  $STUDENT_A_EMAIL -StudentAPassword $STUDENT_A_PASS `
    -StudentBEmail  $STUDENT_B_EMAIL -StudentBPassword $STUDENT_B_PASS `
    -BaseUrl        $BASE `
    -AnonKey        $ANON `
    -OutDir         $OutDir

# ---------------------------------------------------------------------------
# PHASE 5: CLEANUP via admin_qa_cleanup_test_users() RPC
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Yellow
Write-Host ">>> PHASE 5: Cleaning Up via admin_qa_cleanup_test_users() RPC..." -ForegroundColor Yellow
Write-Host "===========================================================================" -ForegroundColor Yellow

# Step 1: Delete fixture data (modules cascade-deletes assessments, quizzes, questions)
foreach ($modId in @($CreatedIds.Module1Id, $CreatedIds.Module2Id)) {
    if (-not $modId) { continue }
    $r = Invoke-Svc -Method DELETE -Uri "$BASE/rest/v1/modules?id=eq.$modId"
    if ($r.Ok -or $r.Status -eq 204) {
        Write-Host "  [OK] Module $modId deleted (cascade)" -ForegroundColor DarkGray
    } else {
        Write-Host "  [WARN] Module delete: $($r.Status) $($r.Msg)" -ForegroundColor Yellow
    }
}

# Step 2: Call RPC to delete all @mathturo-qa.test auth + public users
$cleanupBody = "{}"
$r = Invoke-Svc -Method POST -Uri "$BASE/rest/v1/rpc/admin_qa_cleanup_test_users" -Body $cleanupBody
if ($r.Ok) {
    Write-Host "  [OK] Cleanup RPC: deleted_public=$($r.Data.deleted_public_users) deleted_auth=$($r.Data.deleted_auth_users)" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Cleanup RPC: $($r.Status) $($r.Msg)" -ForegroundColor Yellow
    Write-Host "  NOTE: Manually run DELETE FROM auth.users WHERE email LIKE '%@mathturo-qa.test'" -ForegroundColor Yellow
}

# Clear sensitive vars
$SVC_KEY    = $null
$ANON       = $null
$SvcHeaders = $null
[System.GC]::Collect()

Write-Host ""
Write-Host "===========================================================================" -ForegroundColor Magenta
Write-Host "  AUTOMATED QA MASTER RUNNER -- COMPLETE" -ForegroundColor Magenta
Write-Host ("  Time:   " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -ForegroundColor Magenta
Write-Host "  Results: $OutDir\e2e_results.json" -ForegroundColor Magenta
Write-Host "===========================================================================" -ForegroundColor Magenta
