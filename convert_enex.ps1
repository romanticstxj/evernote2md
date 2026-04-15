# convert_enex.ps1
# Usage: .\convert_enex.ps1 -Source D:\evernote1 -Output D:\evernote2
# Recursively finds all directories containing .enex files and converts them.
# Failed notes are logged to failed_notes.txt for review.

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Output,

    [string]$Exe = "D:\tools\evernote2md.exe",

    [string]$FailLog = "failed_notes.txt"
)

$Source = $Source.TrimEnd('\', '/')
$Output = $Output.TrimEnd('\', '/')

if (-not (Test-Path $Exe)) {
    Write-Error "evernote2md.exe not found: $Exe"
    Write-Error "Use -Exe to specify the correct path."
    exit 1
}

if (-not (Test-Path $Source)) {
    Write-Error "Source directory not found: $Source"
    exit 1
}

$dirsWithEnex = Get-ChildItem -Path $Source -Recurse -Filter "*.enex" |
    Select-Object -ExpandProperty DirectoryName |
    Sort-Object -Unique

if ($dirsWithEnex.Count -eq 0) {
    Write-Host "No .enex files found. Exiting."
    exit 0
}

Write-Host "Found $($dirsWithEnex.Count) director(ies) with .enex files."
Write-Host ""

$successCount = 0
$failCount = 0
$partialCount = 0
$failLogLines = @()

foreach ($srcDir in $dirsWithEnex) {
    $relativePath = $srcDir.Substring($Source.Length).TrimStart('\', '/')
    if ($relativePath -eq "") {
        $destDir = $Output
    } else {
        $destDir = Join-Path $Output $relativePath
    }

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Write-Host "Converting: $srcDir"
    Write-Host "       To: $destDir"

    # 捕获 stdout + stderr
    $procOutput = & $Exe "$srcDir" "$destDir" 2>&1

    # 打印原始输出
    $procOutput | ForEach-Object { Write-Host "  $_" }

    # 检测输出里是否有 [ERROR] 行
    $errorLines = $procOutput | Where-Object { $_ -match '\[ERROR\]' }

    if ($errorLines) {
        # 有错误但也可能转换了部分笔记
        Write-Host "  [PARTIAL] Some notes failed:" -ForegroundColor Yellow
        foreach ($errLine in $errorLines) {
            Write-Host "    $errLine" -ForegroundColor Yellow
            $failLogLines += "[$srcDir] $errLine"
        }
        $partialCount++
    } else {
        Write-Host "  [OK]" -ForegroundColor Green
        $successCount++
    }

    Write-Host ""
}

# 写失败日志
if ($failLogLines.Count -gt 0) {
    $failLogLines | Out-File -FilePath $FailLog -Encoding UTF8
    Write-Host "Failed notes logged to: $FailLog"
}

Write-Host "Done: $successCount OK, $partialCount partial (with errors), $failCount failed."
