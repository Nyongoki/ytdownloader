# YouTube Downloader PowerShell Script v2.0
param(
    [string]$Url = "",
    [string]$OutputPath = "",
    [string]$Quality = "best",
    [switch]$AudioOnly,
    [switch]$Help
)

# Script configuration
$script:LogFile = Join-Path $PSScriptRoot "download.log"
$script:ConfigFile = Join-Path $PSScriptRoot "config.json"
$script:DefaultFolder = Join-Path $env:USERPROFILE "Downloads\YouTube"

# Color functions
function Write-ColoredText {
    param([string]$Text, [ConsoleColor]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Success { param([string]$Text) Write-ColoredText $Text Green }
function Write-Error { param([string]$Text) Write-ColoredText $Text Red }
function Write-Warning { param([string]$Text) Write-ColoredText $Text Yellow }
function Write-Info { param([string]$Text) Write-ColoredText $Text Cyan }

# Show help
if ($Help) {
    Write-Host @"
YouTube Downloader v2.0 - PowerShell Edition

USAGE:
    .\downloader.ps1 [OPTIONS]
    .\downloader.ps1 -Url <URL> -OutputPath <PATH> [OPTIONS]

OPTIONS:
    -Url <string>        YouTube URL (playlist or single video)
    -OutputPath <string> Download folder path
    -Quality <string>    Quality preset: best, 1080p, 720p, 480p, audio
    -AudioOnly          Download audio only (MP3 format)
    -Help               Show this help message

EXAMPLES:
    .\downloader.ps1
    .\downloader.ps1 -Url "https://youtube.com/playlist?list=..." -OutputPath "C:\Downloads"
    .\downloader.ps1 -Url "https://youtu.be/..." -AudioOnly
"@
    exit 0
}

# Header
Clear-Host
Write-Host "===============================================" -ForegroundColor Green
Write-Host "   YT-DLP PLAYLIST DOWNLOADER v2.0 (PowerShell)" -ForegroundColor Green  
Write-Host "===============================================" -ForegroundColor Green
Write-Host

# Dependency check function
function Test-Dependencies {
    Write-Info "Checking dependencies..."
    
    $dependencies = @()
    
    # Check yt-dlp
    try {
        $ytdlpVersion = & yt-dlp --version 2>$null
        Write-Success "[OK] yt-dlp found (version: $ytdlpVersion)"
    }
    catch {
        Write-Error "[ERROR] yt-dlp not found. Please install it first."
        $dependencies += @{
            Name = "yt-dlp"
            InstallCommand = "pip install yt-dlp"
            Url = "https://github.com/yt-dlp/yt-dlp"
        }
    }
    
    # Check ffmpeg
    try {
        $ffmpegInfo = & ffmpeg -version 2>$null | Select-Object -First 1
        Write-Success "[OK] ffmpeg found"
    }
    catch {
        Write-Warning "[WARNING] ffmpeg not found. Video+audio merging may not work."
        Write-Info "[INFO] Install ffmpeg for best results."
    }
    
    if ($dependencies.Count -gt 0) {
        Write-Host
        Write-Error "Missing dependencies found. Please install:"
        foreach ($dep in $dependencies) {
            Write-Host "  • $($dep.Name): $($dep.InstallCommand)" -ForegroundColor Yellow
            Write-Host "    More info: $($dep.Url)" -ForegroundColor Gray
        }
        Write-Host
        Read-Host "Press Enter to continue anyway or Ctrl+C to exit"
    }
}

# URL validation
function Test-YouTubeUrl {
    param([string]$TestUrl)
    return $TestUrl -match "(youtube\.com|youtu\.be)"
}

# Configuration management
function Get-Config {
    if (Test-Path $script:ConfigFile) {
        try {
            return Get-Content $script:ConfigFile | ConvertFrom-Json
        }
        catch {
            Write-Warning "Could not load config file. Using defaults."
        }
    }
    return @{
        DefaultFolder = $script:DefaultFolder
        LastQuality = "best"
    }
}

function Save-Config {
    param($Config)
    try {
        $Config | ConvertTo-Json | Set-Content $script:ConfigFile
    }
    catch {
        Write-Warning "Could not save configuration."
    }
}

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Add-Content $script:LogFile
}

# Main execution
try {
    # Check dependencies
    Test-Dependencies
    
    # Load configuration
    $config = Get-Config
    
    # Get URL if not provided
    while (-not $Url -or -not (Test-YouTubeUrl $Url)) {
        Write-Host
        $Url = Read-Host "Paste YouTube URL (playlist or single video)"
        if (-not (Test-YouTubeUrl $Url)) {
            Write-Error "Invalid YouTube URL. Please try again."
            $Url = ""
        }
    }
    
    # Quality selection if not specified
    if ($AudioOnly) {
        $Quality = "audio"
    }
    elseif (-not $Quality -or $Quality -eq "best") {
        Write-Host
        Write-Host "Quality options:"
        Write-Host "[1] Best Video + Audio (default)"
        Write-Host "[2] Audio Only (MP3)"
        Write-Host "[3] 1080p max"
        Write-Host "[4] 720p max" 
        Write-Host "[5] 480p max"
        Write-Host
        
        $choice = Read-Host "Choose quality (1-5, default: 1)"
        switch ($choice) {
            "2" { $Quality = "audio" }
            "3" { $Quality = "1080p" }
            "4" { $Quality = "720p" }
            "5" { $Quality = "480p" }
            default { $Quality = "best" }
        }
    }
    
    # Get output path if not provided
    if (-not $OutputPath) {
        Write-Host
        if (Test-Path $config.DefaultFolder) {
            Write-Info "Default folder: $($config.DefaultFolder)"
            $userPath = Read-Host "Enter download folder path (or press Enter for default)"
            $OutputPath = if ($userPath) { $userPath } else { $config.DefaultFolder }
        }
        else {
            $OutputPath = Read-Host "Enter download folder path"
        }
    }
    
    # Validate and create output directory
    if (-not (Test-Path $OutputPath)) {
        Write-Info "Creating folder: $OutputPath"
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Test write access
    try {
        $testFile = Join-Path $OutputPath "test_write.tmp"
        "" | Out-File $testFile -ErrorAction Stop
        Remove-Item $testFile -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Cannot write to folder: $OutputPath"
        exit 1
    }
    
    # Update and save configuration
    $config.DefaultFolder = $OutputPath
    $config.LastQuality = $Quality
    Save-Config $config
    
    # Prepare download format
    $formatArgs = switch ($Quality) {
        "audio" { 
            @("-f", "bestaudio/best", "-x", "--audio-format", "mp3", "--audio-quality", "0")
            $formatDesc = "Audio Only (MP3)"
        }
        "1080p" { 
            @("-f", "bestvideo[height<=1080]+bestaudio/best[height<=1080]")
            $formatDesc = "1080p Maximum"
        }
        "720p" { 
            @("-f", "bestvideo[height<=720]+bestaudio/best[height<=720]")
            $formatDesc = "720p Maximum"
        }
        "480p" { 
            @("-f", "bestvideo[height<=480]+bestaudio/best[height<=480]")
            $formatDesc = "480p Maximum"
        }
        default { 
            @("-f", "bestvideo+bestaudio/best")
            $formatDesc = "Best Quality"
        }
    }
    
    # Display download info
    Write-Host
    Write-Host "===============================================" -ForegroundColor Green
    Write-Info "Starting download..."
    Write-Info "URL: $Url"
    Write-Info "Folder: $OutputPath"  
    Write-Info "Format: $formatDesc"
    Write-Info "Log file: $script:LogFile"
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host
    
    # Log the download
    Write-Log "Starting download"
    Write-Log "URL: $Url"
    Write-Log "Folder: $OutputPath"
    Write-Log "Format: $formatDesc"
    
    # Build yt-dlp arguments
    $ytdlpArgs = @(
        $formatArgs
        "--concurrent-fragments", "1"
        "--fragment-retries", "20" 
        "--extractor-args", "youtube:player_client=default"
        "--write-info-json"
        "--write-description"
        "--write-thumbnail"
        "--embed-metadata"
        "--add-metadata"
        "--no-overwrites"
        "--continue"
        "--ignore-errors"
        "--no-abort-on-error"
        "--progress"
        "--console-title"
        "-o", "$OutputPath\%(uploader)s - %(title)s.%(ext)s"
        $Url
    )
    
    # Execute download
    $process = Start-Process -FilePath "yt-dlp" -ArgumentList $ytdlpArgs -NoNewWindow -Wait -PassThru
    $exitCode = $process.ExitCode
    
    # Log completion
    Write-Log "Download completed with exit code: $exitCode"
    Write-Log "==============================================="
    
    Write-Host
    if ($exitCode -eq 0) {
        Write-Host "===============================================" -ForegroundColor Green
        Write-Success "   DOWNLOAD COMPLETED SUCCESSFULLY!"
        Write-Host "===============================================" -ForegroundColor Green
    }
    else {
        Write-Host "===============================================" -ForegroundColor Yellow
        Write-Warning "   DOWNLOAD COMPLETED WITH ERRORS"
        Write-Warning "   Check $script:LogFile for details"
        Write-Host "===============================================" -ForegroundColor Yellow
    }
    
    Write-Host
    Write-Info "Files saved to: $OutputPath"
    Write-Info "Log file: $script:LogFile"
    
    # Open output folder option
    Write-Host
    $openFolder = Read-Host "Open download folder? (y/N)"
    if ($openFolder -eq "y" -or $openFolder -eq "Y") {
        Start-Process explorer $OutputPath
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Log "Error: $($_.Exception.Message)"
    exit 1
}
finally {
    Write-Host
    Read-Host "Press Enter to exit"
}