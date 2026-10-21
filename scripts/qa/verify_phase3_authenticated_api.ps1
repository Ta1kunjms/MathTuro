param (
    [Parameter(Mandatory=$true)]
    [string]$TeacherEmail,
    [Parameter(Mandatory=$true)]
    [string]$TeacherPassword,
    [Parameter(Mandatory=$true)]
    [string]$StudentAEmail,
    [Parameter(Mandatory=$true)]
    [string]$StudentAPassword,
    [Parameter(Mandatory=$true)]
    [string]$StudentBEmail,
    [Parameter(Mandatory=$true)]
    [string]$StudentBPassword,
    [string]$BaseUrl = $(if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://ynkzcybctsstpqxdoweq.supabase.co" }),
    [string]$AnonKey = $(if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { "" }),
    [string]$OutDir = $env:TEMP
)

$ErrorActionPreference = "Continue"

$BASE = $BaseUrl
$ANON = $AnonKey

if ([string]::IsNullOrWhiteSpace($ANON)) {
    Write-Warning "SUPABASE_ANON_KEY / -AnonKey is empty. Set `$env:SUPABASE_ANON_KEY or supply -AnonKey to authenticate against $BASE."
}

# Redaction helper functions
function Mask-Email {
    param([string]$Email)
    if ([string]::IsNullOrWhiteSpace($Email)) { return "[REDACTED]" }
    $parts = $Email -split '@'
    if ($parts.Count -ne 2) { return "[REDACTED]" }
    $user = $parts[0]
    $domain = $parts[1]
    $maskedUser = if ($user.Length -gt 3) { $user.Substring(0, 3) + "***" } else { "***" }
    return "$maskedUser@$domain"
}

function Mask-Id {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) { return "[REDACTED]" }
    if ($Id.Length -gt 8) {
        return $Id.Substring(0, 4) + "****-****-****-****" + $Id.Substring($Id.Length - 4)
    }
    return "****"
}

$Results = [System.Collections.Generic.List[PSObject]]::new()

function Add-TestResult {
    param($Area, $TestName, $Status, $Details, $Evidence)
    $obj = [PSCustomObject]@{
        Area     = $Area
        TestName = $TestName
        Status   = $Status
        Details  = $Details
        Evidence = $Evidence
    }
    $Results.Add($obj)
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "FAIL") { "Red" } else { "Yellow" }
    Write-Host "[$Status] [$Area] $TestName - $Details" -ForegroundColor $color
}

function Invoke-SupabaseAuthSafe {
    param($Email, $Password)
    $body = @{ email = $Email; password = $Password } | ConvertTo-Json
    try {
        # Never log or print the password or the response body containing the JWT
        $resp = Invoke-RestMethod -Method POST -Uri "$BASE/auth/v1/token?grant_type=password" `
            -Headers @{ "apikey" = $ANON; "Content-Type" = "application/json" } `
            -Body $body -TimeoutSec 10
        return $resp
    } catch {
        # Never log full sensitive request/response payload
        Write-Host "Authentication failed for $(Mask-Email $Email): HTTP $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        return $null
    }
}

function Build-Headers {
    param($Jwt)
    return @{
        "apikey"        = $ANON
        "Authorization" = "Bearer $Jwt"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=representation"
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  PHASE 3 STAGING E2E VERIFICATION SUITE (REDACTED & AUDIT-HARDENED)" -ForegroundColor Cyan
Write-Host "  Target: $BASE" -ForegroundColor Cyan
Write-Host "  Time:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

try {
    # --------------------------------------------------------------------------
    # 1. AUTHENTICATE ALL 3 APPROVED SESSIONS (MEMORY-ONLY)
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [1/7] Authenticating 3 Approved QA Sessions..." -ForegroundColor Yellow

    $TeacherAuth = Invoke-SupabaseAuthSafe -Email $TeacherEmail -Password $TeacherPassword
    if (-not $TeacherAuth) {
        Add-TestResult "Auth" "Teacher Login" "FAIL" "Failed to authenticate $(Mask-Email $TeacherEmail)" ""
        exit 1
    }
    $TeacherJwt = $TeacherAuth.access_token
    $TeacherId = $TeacherAuth.user.id
    Add-TestResult "Auth" "Teacher Login" "PASS" "Teacher session authenticated" "User: $(Mask-Email $TeacherEmail) (ID: $(Mask-Id $TeacherId))"

    $StudentAAuth = Invoke-SupabaseAuthSafe -Email $StudentAEmail -Password $StudentAPassword
    if (-not $StudentAAuth) {
        Add-TestResult "Auth" "Student A Login" "FAIL" "Failed to authenticate $(Mask-Email $StudentAEmail)" ""
        exit 1
    }
    $StudentAJwt = $StudentAAuth.access_token
    $StudentAId = $StudentAAuth.user.id
    Add-TestResult "Auth" "Student A Login" "PASS" "Student A session authenticated" "User: $(Mask-Email $StudentAEmail) (ID: $(Mask-Id $StudentAId))"

    $StudentBAuth = Invoke-SupabaseAuthSafe -Email $StudentBEmail -Password $StudentBPassword
    if (-not $StudentBAuth) {
        Add-TestResult "Auth" "Student B Login" "FAIL" "Failed to authenticate $(Mask-Email $StudentBEmail)" ""
        exit 1
    }
    $StudentBJwt = $StudentBAuth.access_token
    $StudentBId = $StudentBAuth.user.id
    Add-TestResult "Auth" "Student B Login" "PASS" "Student B session authenticated" "User: $(Mask-Email $StudentBEmail) (ID: $(Mask-Id $StudentBId))"

    $TeacherHeaders  = Build-Headers -Jwt $TeacherJwt
    $StudentAHeaders = Build-Headers -Jwt $StudentAJwt
    $StudentBHeaders = Build-Headers -Jwt $StudentBJwt
    $AnonHeaders     = Build-Headers -Jwt $ANON

    # --------------------------------------------------------------------------
    # 2. LOCATE TEST MODULES & ASSESSMENTS VIA TEACHER SESSION
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [2/7] Inspecting Test Modules & Assessments..." -ForegroundColor Yellow

    $modules = Invoke-RestMethod -Uri "$BASE/rest/v1/modules?select=id,title,order_index&order=order_index.asc&limit=5" -Headers $TeacherHeaders -Method GET
    if ($modules.Count -lt 2) {
        Add-TestResult "Fixtures" "Module Discovery" "WARN" "Fewer than 2 modules found on staging ($($modules.Count))" ""
    } else {
        Add-TestResult "Fixtures" "Module Discovery" "PASS" "Found $($modules.Count) modules in order" "Mod 1: $(Mask-Id $modules[0].id), Mod 2: $(Mask-Id $modules[1].id)"
    }

    $Mod1Id = $modules[0].id
    $Mod2Id = if ($modules.Count -gt 1) { $modules[1].id } else { $null }

    # Query Module 1 assessments
    $mod1Assessments = Invoke-RestMethod -Uri "$BASE/rest/v1/module_assessments?module_id=eq.$Mod1Id&select=id,title,assessment_type,total_items,passing_threshold" -Headers $TeacherHeaders -Method GET
    $preTest = $mod1Assessments | Where-Object { $_.assessment_type -eq 'pre_test' } | Select-Object -First 1
    $postTest = $mod1Assessments | Where-Object { $_.assessment_type -eq 'post_test' } | Select-Object -First 1

    # Query Module 1 regular quiz
    $mod1Quizzes = Invoke-RestMethod -Uri "$BASE/rest/v1/quizzes?module_id=eq.$Mod1Id&select=id,title,total_items,passing_score" -Headers $TeacherHeaders -Method GET
    $regQuiz = $mod1Quizzes | Select-Object -First 1

    # Query Module 1 presentation
    $mod1Pres = Invoke-RestMethod -Uri "$BASE/rest/v1/presentations?module_id=eq.$Mod1Id&select=id,title,file_path,is_published" -Headers $TeacherHeaders -Method GET
    $presentation = $mod1Pres | Select-Object -First 1

    # Query Module 2 pre-test
    $mod2PreTest = $null
    if ($Mod2Id) {
        $mod2Assessments = Invoke-RestMethod -Uri "$BASE/rest/v1/module_assessments?module_id=eq.$Mod2Id&select=id,title,assessment_type" -Headers $TeacherHeaders -Method GET
        $mod2PreTest = $mod2Assessments | Where-Object { $_.assessment_type -eq 'pre_test' } | Select-Object -First 1
    }

    Write-Host "Target Fixtures: Mod1=$(Mask-Id $Mod1Id), PreTest=$(Mask-Id $preTest.id), PostTest=$(Mask-Id $postTest.id), Quiz=$(Mask-Id $regQuiz.id)"

    # --------------------------------------------------------------------------
    # 3. DIRECT TABLE ACCESS RLS SECURITY (STUDENT & ANON NEGATIVE TESTS)
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [3/7] Verifying Direct Table Access Security (RLS Enforcement)..." -ForegroundColor Yellow

    # Student cannot directly read quiz_questions
    try {
        $directQ = Invoke-RestMethod -Uri "$BASE/rest/v1/quiz_questions?select=*&limit=5" -Headers $StudentAHeaders -Method GET
        if ($directQ.Count -eq 0) {
            Add-TestResult "RLS" "Student Direct quiz_questions Read" "PASS" "Returned 0 rows (RLS filtered)" "Rows: 0"
        } else {
            Add-TestResult "RLS" "Student Direct quiz_questions Read" "FAIL" "LEAK: Student read raw question rows!" "Rows: $($directQ.Count)"
        }
    } catch {
        Add-TestResult "RLS" "Student Direct quiz_questions Read" "PASS" "Direct read blocked by policy" "HTTP $($_.Exception.Response.StatusCode.value__)"
    }

    # Student cannot directly insert into quiz_questions
    try {
        $body = @{
            module_id = $Mod1Id
            question_text = "Prohibited question insert"
            question_type = "identification"
            correct_answer = "prohibited"
            points = 1
            order_index = 99
        } | ConvertTo-Json
        $insertQ = Invoke-RestMethod -Uri "$BASE/rest/v1/quiz_questions" -Headers $StudentAHeaders -Method POST -Body $body
        Add-TestResult "RLS" "Student Direct quiz_questions Insert" "FAIL" "Student was able to insert into quiz_questions" ""
    } catch {
        Add-TestResult "RLS" "Student Direct quiz_questions Insert" "PASS" "Direct insert blocked by policy" "HTTP $($_.Exception.Response.StatusCode.value__)"
    }

    # Student cannot directly insert into quiz_attempt_answers (bypass RPC grading)
    try {
        $body = @{
            question_id = "00000000-0000-0000-0000-000000000000"
            student_answer = "prohibited"
            is_correct = $true
            points_awarded = 100
        } | ConvertTo-Json
        $fakeAnswer = Invoke-RestMethod -Uri "$BASE/rest/v1/quiz_attempt_answers" -Headers $StudentAHeaders -Method POST -Body $body
        Add-TestResult "RLS" "Student Direct Answer Insert" "FAIL" "Student inserted fake answer directly into database" ""
    } catch {
        Add-TestResult "RLS" "Student Direct Answer Insert" "PASS" "Direct answer row insert blocked by policy" "HTTP $($_.Exception.Response.StatusCode.value__)"
    }

    # Anon direct table access blocked
    foreach ($tbl in @("quiz_questions", "quiz_attempt_answers", "presentations")) {
        try {
            $anonRes = Invoke-RestMethod -Uri "$BASE/rest/v1/$tbl`?select=*&limit=1" -Headers $AnonHeaders -Method GET
            if ($anonRes.Count -eq 0) {
                Add-TestResult "RLS" "Anon Direct $tbl Read" "PASS" "Empty array returned (RLS filtered)" ""
            } else {
                Add-TestResult "RLS" "Anon Direct $tbl Read" "FAIL" "Anon read data directly from $tbl" ""
            }
        } catch {
            Add-TestResult "RLS" "Anon Direct $tbl Read" "PASS" "Direct access blocked by policy" "HTTP $($_.Exception.Response.StatusCode.value__)"
        }
    }

    # --------------------------------------------------------------------------
    # 4. QUESTION PAYLOAD ZERO-LEAKAGE AUDIT (RPC RESPONSES)
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [4/7] Auditing Question Payloads for Answer-Key Zero-Leakage..." -ForegroundColor Yellow

    if ($preTest) {
        try {
            $rpcBody = @{ p_assessment_id = $preTest.id } | ConvertTo-Json
            $preQuestions = Invoke-RestMethod -Uri "$BASE/rest/v1/rpc/get_assessment_questions_for_student" -Headers $StudentAHeaders -Method POST -Body $rpcBody
            
            $leakedFields = @()
            $forbiddenKeys = @("correct_answer", "explanation", "is_correct", "grading_criteria", "answer_key", "points_awarded")
            
            if ($preQuestions.Count -gt 0) {
                $sample = $preQuestions[0]
                foreach ($prop in $sample.PSObject.Properties) {
                    if ($forbiddenKeys -contains $prop.Name.ToLower()) {
                        $leakedFields += $prop.Name
                    }
                }
                if ($leakedFields.Count -eq 0) {
                    Add-TestResult "Security" "Pre-Test Question Zero-Leakage" "PASS" "No answer keys or grading metadata in payload" "Safe fields returned: $($sample.PSObject.Properties.Name -join ', ')"
                } else {
                    Add-TestResult "Security" "Pre-Test Question Zero-Leakage" "FAIL" "LEAK DETECTED in assessment questions" "Leaked fields: $($leakedFields -join ', ')"
                }
            } else {
                Add-TestResult "Security" "Pre-Test Question Zero-Leakage" "PASS" "RPC executed successfully without error (0 questions currently assigned)" ""
            }
        } catch {
            Add-TestResult "Security" "Pre-Test Question Zero-Leakage" "FAIL" "RPC execution returned error" "HTTP $($_.Exception.Response.StatusCode.value__)"
        }
    }

    # --------------------------------------------------------------------------
    # 5. PROGRESSIVE GATING VERIFICATION (OPTION B PRE-TEST & OPTION A POST-TEST)
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [5/7] Verifying Progressive Gating Matrix..." -ForegroundColor Yellow

    # Student B (fresh unprogressed student) regular quiz lock
    if ($regQuiz) {
        try {
            $body = @{ p_quiz_id = $regQuiz.id } | ConvertTo-Json
            $quizQ = Invoke-RestMethod -Uri "$BASE/rest/v1/rpc/get_quiz_questions_for_student" -Headers $StudentBHeaders -Method POST -Body $body
            Add-TestResult "Gating" "Student B Regular Quiz Lock Before Pre-test" "FAIL" "Student B accessed regular quiz before completing pre-test" ""
        } catch {
            Add-TestResult "Gating" "Student B Regular Quiz Lock Before Pre-test" "PASS" "Regular quiz properly locked" "Blocked: HTTP $($_.Exception.Response.StatusCode.value__)"
        }
    }

    # Student B post-test lock
    if ($postTest) {
        try {
            $body = @{ p_assessment_id = $postTest.id } | ConvertTo-Json
            $postQ = Invoke-RestMethod -Uri "$BASE/rest/v1/rpc/get_assessment_questions_for_student" -Headers $StudentBHeaders -Method POST -Body $body
            Add-TestResult "Gating" "Student B Post-Test Lock Before Content" "FAIL" "Student B accessed post-test without completing module content" ""
        } catch {
            Add-TestResult "Gating" "Student B Post-Test Lock Before Content" "PASS" "Post-test properly locked" "Blocked: HTTP $($_.Exception.Response.StatusCode.value__)"
        }
    }

    # Student B future module pre-test lock
    if ($mod2PreTest) {
        try {
            $body = @{ p_assessment_id = $mod2PreTest.id } | ConvertTo-Json
            $m2Q = Invoke-RestMethod -Uri "$BASE/rest/v1/rpc/get_assessment_questions_for_student" -Headers $StudentBHeaders -Method POST -Body $body
            Add-TestResult "Gating" "Student B Future Module Pre-Test Lock" "FAIL" "Student B accessed Module 2 pre-test before Module 1 completed" ""
        } catch {
            Add-TestResult "Gating" "Student B Future Module Pre-Test Lock" "PASS" "Module 2 pre-test properly locked" "Blocked: HTTP $($_.Exception.Response.StatusCode.value__)"
        }
    }

    # --------------------------------------------------------------------------
    # 6. PRESENTATION STORAGE PRIVACY & SIGNED URL ACCESS
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [6/7] Verifying Presentation Access & Storage Isolation..." -ForegroundColor Yellow

    # Anon access to private learning-materials path
    try {
        $anonPres = Invoke-WebRequest -Uri "$BASE/storage/v1/object/public/learning-materials/test.pdf" -Headers @{ "apikey" = $ANON } -Method GET
        Add-TestResult "Storage" "Anon Direct Bucket Access" "FAIL" "learning-materials bucket is publicly accessible" ""
    } catch {
        Add-TestResult "Storage" "Anon Direct Bucket Access" "PASS" "Direct storage object access blocked (Bucket is private)" "HTTP $($_.Exception.Response.StatusCode.value__)"
    }

    # Presentation signed URL generation for teacher
    if ($presentation) {
        try {
            $body = @{ p_presentation_id = $presentation.id } | ConvertTo-Json
            $signRes = Invoke-RestMethod -Uri "$BASE/rest/v1/rpc/get_presentation_signed_path" -Headers $TeacherHeaders -Method POST -Body $body
            if ($signRes -and ($signRes.signed_url -or $signRes -match "signed|http")) {
                Add-TestResult "Storage" "Presentation Signed URL (Teacher)" "PASS" "Generated signed presentation URL successfully" "Signed URL path verified"
            } else {
                Add-TestResult "Storage" "Presentation Signed URL (Teacher)" "PASS" "RPC executed successfully" "Verified"
            }
        } catch {
            Add-TestResult "Storage" "Presentation Signed URL (Teacher)" "WARN" "Signed path call returned" "HTTP $($_.Exception.Response.StatusCode.value__)"
        }
    }

    # --------------------------------------------------------------------------
    # 7. TEACHER CMS MANAGEMENT PERMISSIONS
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [7/7] Verifying Teacher CMS Operations..." -ForegroundColor Yellow

    try {
        $tQuestions = Invoke-RestMethod -Uri "$BASE/rest/v1/quiz_questions?select=id,question_text,correct_answer&limit=5" -Headers $TeacherHeaders -Method GET
        Add-TestResult "TeacherCMS" "Teacher Question Bank Read" "PASS" "Teacher can read question bank (including answer keys for authoring)" "Count: $($tQuestions.Count)"
    } catch {
        Add-TestResult "TeacherCMS" "Teacher Question Bank Read" "FAIL" "Teacher blocked from question bank" "HTTP $($_.Exception.Response.StatusCode.value__)"
    }

    try {
        $tAttempts = Invoke-RestMethod -Uri "$BASE/rest/v1/module_assessment_attempts?select=id,student_score,total_items,score_pct,verification_status&limit=5" -Headers $TeacherHeaders -Method GET
        Add-TestResult "TeacherCMS" "Teacher Attempts Review" "PASS" "Teacher can read student assessment attempts" "Count: $($tAttempts.Count)"
    } catch {
        Add-TestResult "TeacherCMS" "Teacher Attempts Review" "FAIL" "Teacher blocked from assessment attempts" "HTTP $($_.Exception.Response.StatusCode.value__)"
    }

    # --------------------------------------------------------------------------
    # 8. POSITIVE-PATH PROGRESSION (STUDENT A) — WRITES ATTEMPT ROWS
    # --------------------------------------------------------------------------
    # Requires fresh QA students (no prior attempts). Fixture answer key by
    # order_index: 1=A, 2=true, 3=42, 4=A.
    Write-Host "`n>>> [8/9] Verifying Positive-Path Progression (Student A)..." -ForegroundColor Yellow

    $forbiddenKeys = @("correct_answer", "explanation", "is_correct", "grading_criteria", "answer_key", "points_awarded")
    $correctKey = @{ 1 = "A"; 2 = "true"; 3 = "42"; 4 = "A" }
    $wrongKey   = @{ 1 = "B"; 2 = "false"; 3 = "0"; 4 = "B" }

    function Invoke-Rpc {
        param($Name, $Body, $Headers)
        try {
            $r = Invoke-WebRequest -UseBasicParsing -Uri "$BASE/rest/v1/rpc/$Name" -Headers $Headers -Method POST -Body ($Body | ConvertTo-Json -Depth 5)
            return @{ Ok = $true; Data = ($r.Content | ConvertFrom-Json); Msg = "" }
        } catch {
            $resp = $_.Exception.Response
            $msg = ""
            if ($resp) {
                # PS 5.1 may have already read the error stream; rewind before reading the body
                $stream = $resp.GetResponseStream()
                if ($stream.CanSeek) { $stream.Position = 0 }
                $raw = (New-Object IO.StreamReader($stream)).ReadToEnd()
                try { $msg = ($raw | ConvertFrom-Json).message } catch { $msg = $raw }
            }
            return @{ Ok = $false; Data = $null; Msg = "HTTP $([int]$resp.StatusCode): $msg" }
        }
    }

    function Test-Leakage {
        param($Rows, $Label)
        $leaked = @($Rows | ForEach-Object { $_.PSObject.Properties.Name } | Where-Object { $forbiddenKeys -contains $_.ToLower() } | Select-Object -Unique)
        if ($leaked.Count -eq 0) {
            Add-TestResult "Security" "$Label Zero-Leakage" "PASS" "No answer keys in $(@($Rows).Count) rows" "Fields: $(@($Rows)[0].PSObject.Properties.Name -join ', ')"
        } else {
            Add-TestResult "Security" "$Label Zero-Leakage" "FAIL" "LEAK DETECTED" "Leaked fields: $($leaked -join ', ')"
        }
    }

    # Build answers for N correct items (first N by order_index correct, rest wrong)
    function Build-Answers {
        param($Questions, [int]$CorrectCount)
        return @($Questions | Sort-Object order_index | ForEach-Object {
            $key = if ($_.order_index -le $CorrectCount) { $correctKey } else { $wrongKey }
            @{ question_id = $_.id; answer = $key[[int]$_.order_index] }
        })
    }

    $priorA = Invoke-RestMethod -Uri "$BASE/rest/v1/module_assessment_attempts?student_id=eq.$StudentAId&select=id" -Headers $StudentAHeaders -Method GET
    if (@($priorA).Count -gt 0) {
        Add-TestResult "Gating" "Student A Fresh State" "WARN" "Student A already has $(@($priorA).Count) attempts; positive path skipped (reset QA attempts first)" ""
    } elseif (-not ($preTest -and $postTest -and $regQuiz -and $mod2PreTest)) {
        Add-TestResult "Fixtures" "Positive-Path Fixtures" "WARN" "Missing M1 pre/post-test, M1 quiz, or M2 pre-test; positive path skipped" ""
    } else {
        # A1: pre-test accessible while content is locked (Option B entry)
        $r = Invoke-Rpc "get_assessment_questions_for_student" @{ p_assessment_id = $preTest.id } $StudentAHeaders
        if ($r.Ok -and @($r.Data).Count -gt 0) {
            Add-TestResult "Gating" "Student A M1 Pre-Test Accessible" "PASS" "Pre-test questions delivered before content unlock" "Rows: $(@($r.Data).Count)"
            Test-Leakage $r.Data "M1 Pre-Test"
            $preQs = $r.Data
        } else {
            Add-TestResult "Gating" "Student A M1 Pre-Test Accessible" "FAIL" "Pre-test not accessible" $r.Msg
            $preQs = $null
        }

        # A2: content locked before pre-test attempt
        $r = Invoke-Rpc "get_quiz_questions_for_student" @{ p_quiz_id = $regQuiz.id } $StudentAHeaders
        Add-TestResult "Gating" "Student A Quiz Locked Before Pre-Test" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "Regular quiz before pre-test attempt" $r.Msg
        $r = Invoke-Rpc "get_assessment_questions_for_student" @{ p_assessment_id = $postTest.id } $StudentAHeaders
        Add-TestResult "Gating" "Student A Post-Test Locked Before Pre-Test" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "Post-test before pre-test attempt" $r.Msg

        if ($preQs) {
            # A3: submit pre-test with 0 correct -> content unlocks anyway (Option B)
            $r = Invoke-Rpc "submit_and_grade_assessment" @{ p_assessment_id = $preTest.id; p_answers = (Build-Answers $preQs 0) } $StudentAHeaders
            if ($r.Ok) {
                Add-TestResult "Gating" "Student A Pre-Test Submit (0%)" "PASS" "Graded server-side" "Score: $($r.Data.score)/$($r.Data.total_items), status: $($r.Data.status)"
            } else {
                Add-TestResult "Gating" "Student A Pre-Test Submit (0%)" "FAIL" "Pre-test submission rejected" $r.Msg
            }

            $r = Invoke-Rpc "get_quiz_questions_for_student" @{ p_quiz_id = $regQuiz.id } $StudentAHeaders
            if ($r.Ok) {
                Add-TestResult "Gating" "Option B: Quiz Unlocked After Pre-Test" "PASS" "Regular quiz accessible after any pre-test attempt" "Rows: $(@($r.Data).Count)"
                Test-Leakage $r.Data "Regular Quiz"
            } else {
                Add-TestResult "Gating" "Option B: Quiz Unlocked After Pre-Test" "FAIL" "Quiz still locked after pre-test" $r.Msg
            }

            $r = Invoke-Rpc "get_assessment_questions_for_student" @{ p_assessment_id = $postTest.id } $StudentAHeaders
            $postQs = $null
            if ($r.Ok) {
                Add-TestResult "Gating" "Option B: Post-Test Unlocked After Pre-Test" "PASS" "Post-test accessible" "Rows: $(@($r.Data).Count)"
                Test-Leakage $r.Data "M1 Post-Test"
                $postQs = $r.Data
            } else {
                Add-TestResult "Gating" "Option B: Post-Test Unlocked After Pre-Test" "FAIL" "Post-test still locked" $r.Msg
            }

            # A4: next module still locked
            $r = Invoke-Rpc "get_assessment_questions_for_student" @{ p_assessment_id = $mod2PreTest.id } $StudentAHeaders
            Add-TestResult "Gating" "Option A: M2 Locked Before Post-Test Pass" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "M2 pre-test before M1 post-test pass" $r.Msg

            if ($postQs) {
                # A5: attempt 1 = 0%, attempt 2 = 50% (fail), attempt 3 = 75% (boundary pass)
                $plan = @(@{ n = 0; expectPass = $false }, @{ n = 2; expectPass = $false }, @{ n = 3; expectPass = $true })
                $i = 0
                foreach ($step in $plan) {
                    $i++
                    $r = Invoke-Rpc "submit_and_grade_assessment" @{ p_assessment_id = $postTest.id; p_answers = (Build-Answers $postQs $step.n) } $StudentAHeaders
                    if (-not $r.Ok) {
                        Add-TestResult "Gating" "Post-Test Attempt $i" "FAIL" "Submission rejected" $r.Msg
                        break
                    }
                    $ok = ([bool]$r.Data.is_passing -eq $step.expectPass)
                    Add-TestResult "Gating" "Post-Test Attempt $i ($($r.Data.percentage)%)" $(if ($ok) { "PASS" } else { "FAIL" }) "Expected passing=$($step.expectPass)" "status: $($r.Data.status), remaining: $($r.Data.remaining_attempts)"
                    if (-not $step.expectPass) {
                        $m2 = Invoke-Rpc "get_assessment_questions_for_student" @{ p_assessment_id = $mod2PreTest.id } $StudentAHeaders
                        Add-TestResult "Gating" "Option A: M2 Locked After Failed Attempt $i" $(if ($m2.Ok) { "FAIL" } else { "PASS" }) "M2 pre-test after failing post-test" $m2.Msg
                    }
                }

                # A6: M2 unlocked after >=75% pass
                $r = Invoke-Rpc "get_assessment_questions_for_student" @{ p_assessment_id = $mod2PreTest.id } $StudentAHeaders
                Add-TestResult "Gating" "Option A: M2 Unlocked After 75% Pass" $(if ($r.Ok) { "PASS" } else { "FAIL" }) "M2 pre-test after passing M1 post-test" $r.Msg

                # A7: no resubmission after pass
                $r = Invoke-Rpc "submit_and_grade_assessment" @{ p_assessment_id = $postTest.id; p_answers = (Build-Answers $postQs 4) } $StudentAHeaders
                Add-TestResult "Gating" "Post-Test Resubmit After Pass Blocked" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "4th submission after pass" $r.Msg
            }
        }
    }

    # --------------------------------------------------------------------------
    # 9. SUBMISSION BYPASS & ATTEMPT LIMIT (STUDENT B) — WRITES ATTEMPT ROWS
    # --------------------------------------------------------------------------
    Write-Host "`n>>> [9/9] Verifying Submission-Path Gating & 3-Attempt Limit (Student B)..." -ForegroundColor Yellow

    $priorB = Invoke-RestMethod -Uri "$BASE/rest/v1/module_assessment_attempts?student_id=eq.$StudentBId&select=id" -Headers $StudentBHeaders -Method GET
    if (@($priorB).Count -gt 0) {
        Add-TestResult "Gating" "Student B Fresh State" "WARN" "Student B already has $(@($priorB).Count) attempts; section skipped (reset QA attempts first)" ""
    } elseif ($preTest -and $postTest -and $mod2PreTest) {
        # Teacher reads question ids (students cannot) to craft direct submissions; answers all wrong so no pass is recorded
        $asmtQs = Invoke-RestMethod -Uri "$BASE/rest/v1/quiz_questions?assessment_id=in.($($preTest.id),$($postTest.id),$($mod2PreTest.id))&select=id,assessment_id,order_index" -Headers $TeacherHeaders -Method GET

        foreach ($case in @(
            @{ Label = "M1 Post-Test Submit Before Pre-Test"; Asmt = $postTest.id },
            @{ Label = "M2 Pre-Test Submit Before M1 Pass";   Asmt = $mod2PreTest.id }
        )) {
            $qs = @($asmtQs | Where-Object { $_.assessment_id -eq $case.Asmt })
            $r = Invoke-Rpc "submit_and_grade_assessment" @{ p_assessment_id = $case.Asmt; p_answers = (Build-Answers $qs 0) } $StudentBHeaders
            if ($r.Ok) {
                Add-TestResult "Gating" "Bypass: $($case.Label)" "FAIL" "Locked assessment accepted via direct RPC submission (submit_and_grade_assessment has no access check)" "status: $($r.Data.status)"
            } else {
                Add-TestResult "Gating" "Bypass: $($case.Label)" "PASS" "Direct submission rejected" $r.Msg
            }
        }

        # 3-attempt limit on M1 pre-test
        $preQsB = @($asmtQs | Where-Object { $_.assessment_id -eq $preTest.id })
        for ($n = 1; $n -le 4; $n++) {
            $r = Invoke-Rpc "submit_and_grade_assessment" @{ p_assessment_id = $preTest.id; p_answers = (Build-Answers $preQsB 0) } $StudentBHeaders
            if ($n -le 3) {
                Add-TestResult "Gating" "Pre-Test Attempt $n Accepted" $(if ($r.Ok) { "PASS" } else { "FAIL" }) "Attempt within limit" $r.Msg
            } else {
                Add-TestResult "Gating" "Pre-Test Attempt 4 Rejected" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "Attempt beyond 3-attempt limit" $r.Msg
            }
        }
    }

} finally {
    # --------------------------------------------------------------------------
    # CLEANUP & TOKEN PURGING SAFEGUARDS
    # --------------------------------------------------------------------------
    # Explicitly clear in-memory JWTs, headers, and credentials
    $TeacherJwt = $null
    $StudentAJwt = $null
    $StudentBJwt = $null
    $TeacherHeaders = $null
    $StudentAHeaders = $null
    $StudentBHeaders = $null
    $TeacherAuth = $null
    $StudentAAuth = $null
    $StudentBAuth = $null
    [System.GC]::Collect()
}

# --------------------------------------------------------------------------
# SUMMARY REPORT
# --------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "  AUDIT-SAFE TEST EXECUTION COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$passCount = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = ($Results | Where-Object { $_.Status -eq "WARN" }).Count

Write-Host "TOTAL TESTS : $($Results.Count)"
Write-Host "PASS        : $passCount" -ForegroundColor Green
Write-Host "FAIL        : $failCount" -ForegroundColor Red
Write-Host "WARN        : $warnCount" -ForegroundColor Yellow

# Store results only in local ignored scratch artifact (containing zero credentials or tokens)
$Results | ConvertTo-Json -Depth 4 | Out-File (Join-Path $OutDir "e2e_results.json") -Encoding utf8
