# list-tasks.ps1
# Lists all tasks in the current planning session with their status
# Usage: .\list-tasks.ps1 [-SessionDir <path>] [-Filter <status>] [-Verbose]

param(
    [string]$SessionDir = "",
    [string]$Filter = "all",
    [switch]$Verbose
)

# Determine session directory
if (-not $SessionDir) {
    $SessionDir = Join-Path (Get-Location) ".planning-session"
}

# Validate session directory exists
if (-not (Test-Path $SessionDir)) {
    Write-Error "No active planning session found at: $SessionDir"
    Write-Host "Run init-session.ps1 to start a new planning session."
    exit 1
}

# Read session metadata
$metaFile = Join-Path $SessionDir "session.json"
if (-not (Test-Path $metaFile)) {
    Write-Error "Session metadata not found. Session may be corrupted."
    exit 1
}

$session = Get-Content $metaFile -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Planning Session: $($session.name)" -ForegroundColor Cyan
Write-Host "  Started: $($session.created_at)" -ForegroundColor Gray
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Collect all task files
$taskFiles = Get-ChildItem -Path $SessionDir -Filter "task-*.md" | Sort-Object Name

if ($taskFiles.Count -eq 0) {
    Write-Host "No tasks found in this session." -ForegroundColor Yellow
    exit 0
}

# Parse and display tasks
$tasks = @()
$statusCounts = @{
    "pending"     = 0
    "in-progress" = 0
    "complete"    = 0
    "blocked"     = 0
}

foreach ($file in $taskFiles) {
    $content = Get-Content $file.FullName -Raw

    # Extract task ID
    $idMatch = [regex]::Match($content, '(?m)^##\s+Task\s+(\S+)')
    $taskId = if ($idMatch.Success) { $idMatch.Groups[1].Value } else { $file.BaseName }

    # Extract title
    $titleMatch = [regex]::Match($content, '(?m)^##\s+Task\s+\S+\s*[:\-]?\s*(.+)')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "(untitled)" }

    # Extract status
    $statusMatch = [regex]::Match($content, '(?mi)^\*\*Status\*\*:\s*(.+)$')
    $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim().ToLower() } else { "pending" }

    # Extract priority
    $priorityMatch = [regex]::Match($content, '(?mi)^\*\*Priority\*\*:\s*(.+)$')
    $priority = if ($priorityMatch.Success) { $priorityMatch.Groups[1].Value.Trim() } else { "normal" }

    # Extract assignee
    $assigneeMatch = [regex]::Match($content, '(?mi)^\*\*Assignee\*\*:\s*(.+)$')
    $assignee = if ($assigneeMatch.Success) { $assigneeMatch.Groups[1].Value.Trim() } else { "unassigned" }

    $task = [PSCustomObject]@{
        Id       = $taskId
        Title    = $title
        Status   = $status
        Priority = $priority
        Assignee = $assignee
        File     = $file.FullName
    }

    $tasks += $task

    if ($statusCounts.ContainsKey($status)) {
        $statusCounts[$status]++
    }
}

# Apply filter
$filteredTasks = if ($Filter -eq "all") {
    $tasks
} else {
    $tasks | Where-Object { $_.Status -eq $Filter.ToLower() }
}

if ($filteredTasks.Count -eq 0) {
    Write-Host "No tasks match filter: '$Filter'" -ForegroundColor Yellow
} else {
    foreach ($task in $filteredTasks) {
        # Choose color based on status
        $statusColor = switch ($task.Status) {
            "complete"    { "Green" }
            "in-progress" { "Yellow" }
            "blocked"     { "Red" }
            default       { "White" }
        }

        $statusIcon = switch ($task.Status) {
            "complete"    { "[x]" }
            "in-progress" { "[~]" }
            "blocked"     { "[!]" }
            default       { "[ ]" }
        }

        Write-Host "  $statusIcon " -NoNewline -ForegroundColor $statusColor
        Write-Host "$($task.Id)" -NoNewline -ForegroundColor Cyan
        Write-Host " - $($task.Title)" -NoNewline
        Write-Host "  [$($task.Priority)]" -ForegroundColor Gray

        if ($Verbose) {
            Write-Host "       Assignee : $($task.Assignee)" -ForegroundColor Gray
            Write-Host "       File     : $($task.File)" -ForegroundColor Gray
            Write-Host ""
        }
    }
}

# Summary footer
Write-Host ""
Write-Host "-------------------------------------------------" -ForegroundColor Gray
Write-Host "  Total: $($tasks.Count)  |  " -NoNewline -ForegroundColor Gray
Write-Host "Done: $($statusCounts['complete'])  " -NoNewline -ForegroundColor Green
Write-Host "In Progress: $($statusCounts['in-progress'])  " -NoNewline -ForegroundColor Yellow
Write-Host "Blocked: $($statusCounts['blocked'])  " -NoNewline -ForegroundColor Red
Write-Host "Pending: $($statusCounts['pending'])" -ForegroundColor White
Write-Host "-------------------------------------------------" -ForegroundColor Gray
Write-Host ""
