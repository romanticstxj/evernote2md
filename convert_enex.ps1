# convert_enex.ps1
# Usage: .\convert_enex.ps1 -Source D:\evernote1 -Output D:\evernote2
# Recursively finds all directories containing .enex files and converts them.

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Output,

    [string]$Exe = "D:\tools\evernote2md.exe"
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

    $proc = Start-Process -FilePath $Exe `
        -ArgumentList "`"$srcDir`"", "`"$destDir`"" `
        -Wait -PassThru -NoNewWindow

    if ($proc.ExitCode -eq 0) {
        Write-Host "  [OK]"
        $successCount++
    } else {
        Write-Host "  [FAILED] exit code: $($proc.ExitCode)"
        $failCount++
    }

    Write-Host ""
}

Write-Host "Done: $successCount succeeded, $failCount failed."
