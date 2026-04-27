# update-task.ps1
# Updates a task's status in the planning session file
# Usage: .\update-task.ps1 -TaskId <id> -Status <status> [-Notes <notes>]

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("pending", "in-progress", "complete", "blocked", "skipped")]
    [string]$Status,

    [Parameter(Mandatory=$false)]
    [string]$Notes = "",

    [Parameter(Mandatory=$false)]
    [string]$SessionFile = ".codebuddy/session.md"
)

# Verify the session file exists
if (-not (Test-Path $SessionFile)) {
    Write-Error "Session file not found: $SessionFile"
    Write-Host "Run init-session.ps1 first to create a planning session."
    exit 1
}

$content = Get-Content $SessionFile -Raw

# Build status emoji mapping
$statusMap = @{
    "pending"     = "[ ]"
    "in-progress" = "[~]"
    "complete"    = "[x]"
    "blocked"     = "[!]"
    "skipped"     = "[-]"
}

$newMarker = $statusMap[$Status]

# Pattern to match a task line by its ID
# Supports formats like: - [ ] TASK-001: Description or - [x] TASK-001: Description
$pattern = "(?m)^(\s*- )\[[^\]]*\]( $([regex]::Escape($TaskId)):.*)"
$replacement = "`${1}$newMarker`${2}"

if ($content -notmatch $pattern) {
    Write-Error "Task ID '$TaskId' not found in session file: $SessionFile"
    exit 1
}

$updatedContent = [regex]::Replace($content, $pattern, $replacement)

# Append notes as a sub-item if provided
if ($Notes -ne "") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $noteEntry = "  - _[$timestamp] $Notes_"

    # Insert the note after the matched task line
    $notePattern = "(?m)(^\s*- \[[^\]]*\] $([regex]::Escape($TaskId)):.*)"
    $noteReplacement = "`${1}`n$noteEntry"
    $updatedContent = [regex]::Replace($updatedContent, $notePattern, $noteReplacement)
}

# Write updated content back to file
Set-Content -Path $SessionFile -Value $updatedContent -NoNewline

Write-Host "Task '$TaskId' updated to status: $Status" -ForegroundColor Green

if ($Notes -ne "") {
    Write-Host "Note added: $Notes" -ForegroundColor Cyan
}

# Show a brief summary of current task statuses
Write-Host ""
Write-Host "Current task summary:" -ForegroundColor Yellow

$lines = $updatedContent -split "`n"
foreach ($line in $lines) {
    if ($line -match "^\s*- \[(.*)\] (\S+):") {
        $marker = $Matches[1]
        $id = $Matches[2]
        $statusLabel = switch ($marker) {
            " " { "pending" }
            "~" { "in-progress" }
            "x" { "complete" }
            "!" { "blocked" }
            "-" { "skipped" }
            default { "unknown" }
        }
        $color = switch ($statusLabel) {
            "pending"     { "Gray" }
            "in-progress" { "Cyan" }
            "complete"    { "Green" }
            "blocked"     { "Red" }
            "skipped"     { "DarkGray" }
            default       { "White" }
        }
        Write-Host "  [$marker] $id — $statusLabel" -ForegroundColor $color
    }
}
