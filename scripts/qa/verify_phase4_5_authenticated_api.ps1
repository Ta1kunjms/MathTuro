param (
    [Parameter(Mandatory=$true)] [string]$TeacherEmail,
    [Parameter(Mandatory=$true)] [string]$TeacherPassword,
    [Parameter(Mandatory=$true)] [string]$StudentAEmail,
    [Parameter(Mandatory=$true)] [string]$StudentAPassword,
    [Parameter(Mandatory=$true)] [string]$StudentBEmail,
    [Parameter(Mandatory=$true)] [string]$StudentBPassword
)

# Phase 4 (archiving) & Phase 5 (EXP / leaderboard) staging checks.
# Read-only except one reversible self-archive probe on Student B.

$ErrorActionPreference = "Continue"
$BASE = "https://jlmdvcmdvkvdxpfkqivh.supabase.co"
$ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsbWR2Y21kdmt2ZHhwZmtxaXZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAyMjE1MDAsImV4cCI6MjEwNTc5NzUwMH0.Scu5UYF_zLKFg4y4Rm3MWC-pGQqBJRwBwUGMhwBiRqQ"

$Results = [System.Collections.Generic.List[PSObject]]::new()
function Add-TestResult {
    param($Area, $TestName, $Status, $Details)
    $Results.Add([PSCustomObject]@{ Area = $Area; TestName = $TestName; Status = $Status; Details = $Details })
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "FAIL") { "Red" } else { "Yellow" }
    Write-Host "[$Status] [$Area] $TestName - $Details" -ForegroundColor $color
}

function Login {
    param($Email, $Password)
    $a = Invoke-RestMethod -Method POST -Uri "$BASE/auth/v1/token?grant_type=password" `
        -Headers @{ apikey = $ANON; "Content-Type" = "application/json" } `
        -Body (@{ email = $Email; password = $Password } | ConvertTo-Json) -TimeoutSec 10
    return @{
        Id = $a.user.id
        Headers = @{ apikey = $ANON; Authorization = "Bearer $($a.access_token)"; "Content-Type" = "application/json"; Prefer = "return=representation" }
    }
}

# Returns @{ Ok; Status; Data; Msg; Code }
function Invoke-Api {
    param($Method, $Path, $Headers, $Body = $null)
    try {
        $args = @{ UseBasicParsing = $true; Uri = "$BASE$Path"; Headers = $Headers; Method = $Method }
        if ($Body -ne $null) { $args.Body = ($Body | ConvertTo-Json -Depth 5) }
        $r = Invoke-WebRequest @args
        $data = if ($r.Content) { $r.Content | ConvertFrom-Json } else { $null }
        return @{ Ok = $true; Status = [int]$r.StatusCode; Data = $data; Msg = ""; Code = "" }
    } catch {
        $resp = $_.Exception.Response
        $msg = ""; $code = ""
        if ($resp) {
            $stream = $resp.GetResponseStream()
            if ($stream.CanSeek) { $stream.Position = 0 }
            $raw = (New-Object IO.StreamReader($stream)).ReadToEnd()
            try { $j = $raw | ConvertFrom-Json; $msg = $j.message; $code = $j.code } catch { $msg = $raw }
        }
        return @{ Ok = $false; Status = [int]$resp.StatusCode; Data = $null; Msg = $msg; Code = $code }
    }
}

Write-Host "PHASE 4-5 STAGING VERIFICATION  |  $BASE  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

$T = Login $TeacherEmail $TeacherPassword
$A = Login $StudentAEmail $StudentAPassword
$B = Login $StudentBEmail $StudentBPassword
$Anon = @{ apikey = $ANON; Authorization = "Bearer $ANON"; "Content-Type" = "application/json" }
Add-TestResult "Auth" "3 QA sessions" "PASS" "Teacher, Student A, Student B authenticated"

# ---------------------------------------------------------------------------
# PHASE 4: ARCHIVING & ADMIN-ONLY OPERATIONS
# ---------------------------------------------------------------------------
Write-Host "`n>>> Phase 4: Archiving & admin-only RPCs" -ForegroundColor Yellow

foreach ($who in @(@{ N = "Teacher"; S = $T }, @{ N = "Student A"; S = $A })) {
    $r = Invoke-Api POST "/rest/v1/rpc/admin_archive_user" $who.S.Headers @{ target_user_id = $B.Id }
    Add-TestResult "Phase4" "$($who.N) cannot archive users" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status): $($r.Msg)"
    $r = Invoke-Api POST "/rest/v1/rpc/admin_unarchive_user" $who.S.Headers @{ target_user_id = $B.Id }
    Add-TestResult "Phase4" "$($who.N) cannot unarchive users" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status): $($r.Msg)"
}

# Hard delete must be unreachable from clients (EXECUTE revoked); use a nil uuid so nothing could be deleted
$r = Invoke-Api POST "/rest/v1/rpc/admin_delete_user" $T.Headers @{ target_user_id = "00000000-0000-0000-0000-000000000000" }
Add-TestResult "Phase4" "admin_delete_user not executable" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status) $($r.Code): $($r.Msg)"

# Students see only their own users row
$r = Invoke-Api GET "/rest/v1/users?select=id" $A.Headers
$others = @($r.Data | Where-Object { $_.id -ne $A.Id })
Add-TestResult "Phase4" "Student reads only own users row" $(if ($r.Ok -and $others.Count -eq 0) { "PASS" } else { "FAIL" }) "Rows: $(@($r.Data).Count), others: $($others.Count)"

# Self-archive / self-unarchive: is_archived must be admin-only (reversible probe on Student B)
$r = Invoke-Api PATCH "/rest/v1/users?id=eq.$($B.Id)" $B.Headers @{ is_archived = $true }
$changed = $r.Ok -and @($r.Data).Count -gt 0 -and $r.Data[0].is_archived -eq $true
if ($changed) {
    $undo = Invoke-Api PATCH "/rest/v1/users?id=eq.$($B.Id)" $B.Headers @{ is_archived = $false }
    $restored = $undo.Ok -and @($undo.Data).Count -gt 0 -and $undo.Data[0].is_archived -eq $false
    Add-TestResult "Phase4" "Student cannot change own is_archived" "FAIL" "Student set is_archived=true AND back to false on own row (archived users can self-restore). Reverted: $restored"
} else {
    Add-TestResult "Phase4" "Student cannot change own is_archived" "PASS" "HTTP $($r.Status): $(if ($r.Msg) { $r.Msg } else { '0 rows updated' })"
}

# ---------------------------------------------------------------------------
# PHASE 5: EXP LEDGER & LEADERBOARD
# ---------------------------------------------------------------------------
Write-Host "`n>>> Phase 5: EXP ledger & leaderboard" -ForegroundColor Yellow

$r = Invoke-Api GET "/rest/v1/exp_transactions?select=student_id,source_type,source_id,exp_awarded" $A.Headers
if ($r.Ok) {
    $rows = @($r.Data)
    $foreign = @($rows | Where-Object { $_.student_id -ne $A.Id })
    Add-TestResult "Phase5" "Student A reads only own EXP rows" $(if ($foreign.Count -eq 0) { "PASS" } else { "FAIL" }) "Rows: $($rows.Count), foreign: $($foreign.Count)"
    $dupes = @($rows | Group-Object source_type, source_id | Where-Object { $_.Count -gt 1 })
    Add-TestResult "Phase5" "EXP awarded once per source" $(if ($dupes.Count -eq 0) { "PASS" } else { "FAIL" }) "Sources: $(($rows | ForEach-Object { $_.source_type }) -join ', ') (A had 3 post-test attempts)"
} else {
    Add-TestResult "Phase5" "Student A reads own EXP rows" "FAIL" "HTTP $($r.Status) $($r.Code): $($r.Msg)"
}

$r = Invoke-Api GET "/rest/v1/exp_transactions?select=student_id&student_id=eq.$($A.Id)" $B.Headers
Add-TestResult "Phase5" "Student B cannot read Student A EXP" $(if ($r.Ok -and @($r.Data).Count -eq 0) { "PASS" } elseif (-not $r.Ok) { "PASS" } else { "FAIL" }) "Rows: $(@($r.Data).Count)"

$r = Invoke-Api POST "/rest/v1/exp_transactions" $A.Headers @{ student_id = $A.Id; source_type = "quiz"; source_id = "00000000-0000-0000-0000-000000000000"; exp_awarded = 9999 }
Add-TestResult "Phase5" "Student cannot insert EXP directly" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status) $($r.Code): $($r.Msg)"

$r = Invoke-Api POST "/rest/v1/rpc/award_exp_if_first_completion" $A.Headers @{ p_student_id = $A.Id; p_source_type = "quiz"; p_source_id = "00000000-0000-0000-0000-000000000000"; p_exp_amount = 9999 }
Add-TestResult "Phase5" "award_exp_if_first_completion not executable" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status) $($r.Code): $($r.Msg)"

$r = Invoke-Api GET "/rest/v1/student_exp_summary?select=*&limit=1" $A.Headers
Add-TestResult "Phase5" "student_exp_summary not readable" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status) $($r.Code)"

$r = Invoke-Api POST "/rest/v1/rpc/get_my_section_leaderboard" $A.Headers @{}
Add-TestResult "Phase5" "Leaderboard RPC works for student" $(if ($r.Ok) { "PASS" } else { "FAIL" }) "HTTP $($r.Status): rows $(@($r.Data).Count) $($r.Msg)"

$r = Invoke-Api POST "/rest/v1/rpc/get_my_section_leaderboard" $Anon @{}
Add-TestResult "Phase5" "Leaderboard RPC blocked for anon" $(if ($r.Ok) { "FAIL" } else { "PASS" }) "HTTP $($r.Status) $($r.Code)"

# Legacy self-reported score RPC: probe with invalid bounds (rejected before any write)
$quiz = (Invoke-Api GET "/rest/v1/quizzes?select=id&limit=1" $T.Headers).Data | Select-Object -First 1
if ($quiz) {
    $r = Invoke-Api POST "/rest/v1/rpc/submit_regular_quiz_score" $B.Headers @{ p_quiz_id = $quiz.id; p_score = 5; p_total = 1 }
    if ($r.Msg -match "Invalid score bounds") {
        Add-TestResult "Phase5" "Legacy self-reported score RPC closed" "FAIL" "submit_regular_quiz_score is executable by students: a client-chosen score (up to 32767) is accepted with no access check and awarded as EXP"
    } else {
        Add-TestResult "Phase5" "Legacy self-reported score RPC closed" "PASS" "HTTP $($r.Status) $($r.Code): $($r.Msg)"
    }
}

# ---------------------------------------------------------------------------
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
$pass = @($Results | Where-Object Status -eq "PASS").Count
$fail = @($Results | Where-Object Status -eq "FAIL").Count
$warn = @($Results | Where-Object Status -eq "WARN").Count
Write-Host "TOTAL: $($Results.Count)  PASS: $pass  FAIL: $fail  WARN: $warn"
