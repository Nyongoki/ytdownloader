@echo off
setlocal EnableDelayedExpansion
title YouTube Playlist Auto Downloader v2.0
color 0a

:: Initialize variables
set "LOG_FILE=%~dp0download.log"
set "CONFIG_FILE=%~dp0config.txt"
set "ERROR_COUNT=0"

echo ===============================================
echo   YT-DLP PLAYLIST DOWNLOADER v2.0
echo ===============================================
echo.

:: Check for command line arguments
if "%~1" neq "" (
    set "playlist=%~1"
    if "%~2" neq "" (
        set "folder=%~2"
        goto :validate_inputs
    )
)

:: Dependency checks
echo [INFO] Checking dependencies...
call :check_dependencies
if !ERROR_COUNT! gtr 0 (
    echo.
    echo [ERROR] Missing dependencies. Please install them and try again.
    pause
    exit /b 1
)

:: Load or create configuration
call :load_config

echo.
echo Configuration options:
echo [1] Video + Audio (Best Quality)
echo [2] Audio Only (MP3)
echo [3] Video Only (MP4)
echo [4] Custom Quality
echo.
set /p "quality_choice=Choose download type (1-4, default: 1): "
if "!quality_choice!"=="" set "quality_choice=1"

:: Get playlist URL
:get_url
if not defined playlist (
    echo.
    set /p "playlist=Paste YouTube URL (playlist or single video): "
)

if "!playlist!"=="" (
    echo [ERROR] No URL provided.
    goto :get_url
)

:: Validate URL
call :validate_url "!playlist!"
if !errorlevel! neq 0 (
    echo [ERROR] Invalid YouTube URL. Please try again.
    set "playlist="
    goto :get_url
)

:: Get download folder
:get_folder
if not defined folder (
    echo.
    if exist "!default_folder!" (
        echo Default folder: !default_folder!
        set /p "folder=Enter download folder path (or press Enter for default): "
        if "!folder!"=="" set "folder=!default_folder!"
    ) else (
        set /p "folder=Enter download folder path: "
    )
)

if "!folder!"=="" (
    echo [ERROR] No folder path provided.
    set "folder="
    goto :get_folder
)

:validate_inputs
:: Validate and create folder
call :validate_folder "!folder!"
if !errorlevel! neq 0 (
    echo [ERROR] Cannot access or create folder: !folder!
    pause
    set "folder="
    goto :get_folder
)

:: Save current settings as defaults
call :save_config "!folder!"

:: Create metadata subfolder
set "metadata_folder=!folder!\metadata"
if not exist "!metadata_folder!" (
    mkdir "!metadata_folder!" 2>nul
    echo [INFO] Created metadata folder: !metadata_folder!
)

:: Set download format based on choice
call :set_download_format !quality_choice!

echo.
echo ===============================================
echo [INFO] Starting download...
echo [INFO] URL: !playlist!
echo [INFO] Folder: !folder!
echo [INFO] Format: !format_description!
echo [INFO] Log file: !LOG_FILE!
echo ===============================================
echo.

:: Create log entry
echo [%date% %time%] Starting download >> "!LOG_FILE!"
echo URL: !playlist! >> "!LOG_FILE!"
echo Folder: !folder! >> "!LOG_FILE!"
echo Format: !format_description! >> "!LOG_FILE!"
echo. >> "!LOG_FILE!"

:: Execute download with enhanced options
yt-dlp !download_format! ^
 --concurrent-fragments 1 --fragment-retries 20 ^
 --extractor-args "youtube:player_client=default" ^
 --write-info-json --write-description --write-thumbnail ^
 --embed-metadata --add-metadata ^
 --no-overwrites --continue ^
 --ignore-errors --no-abort-on-error ^
 --progress --console-title ^
 -o "!folder!\%%(uploader)s - %%(title)s.%%(ext)s" ^
 --write-thumbnail -o "thumbnail:!metadata_folder!\%%(uploader)s - %%(title)s.%%(ext)s" ^
 --write-info-json -o "infojson:!metadata_folder!\%%(uploader)s - %%(title)s.info.json" ^
 --write-description -o "description:!metadata_folder!\%%(uploader)s - %%(title)s.description" ^
 "!playlist!"

set "exit_code=!errorlevel!"

echo. >> "!LOG_FILE!"
echo [%date% %time%] Download completed with exit code: !exit_code! >> "!LOG_FILE!"
echo =============================================== >> "!LOG_FILE!"

echo.
if !exit_code! equ 0 (
    echo ===============================================
    echo   DOWNLOAD COMPLETED SUCCESSFULLY!
    echo ===============================================
) else (
    echo ===============================================
    echo   DOWNLOAD COMPLETED WITH ERRORS
    echo   Check !LOG_FILE! for details
    echo ===============================================
)

echo.
echo [INFO] Files saved to: !folder!
if exist "!LOG_FILE!" echo [INFO] Log file: !LOG_FILE!
echo.
pause
exit /b !exit_code!

:: Functions
:check_dependencies
echo Checking yt-dlp...
yt-dlp --version >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] yt-dlp not found. Please install it first.
    set /a ERROR_COUNT+=1
) else (
    echo [OK] yt-dlp found
)

echo Checking ffmpeg...
ffmpeg -version >nul 2>&1
if !errorlevel! neq 0 (
    echo [WARNING] ffmpeg not found. Video+audio merging may not work properly.
    echo [INFO] Install ffmpeg for best results.
) else (
    echo [OK] ffmpeg found
)
goto :eof

:validate_url
set "url=%~1"
echo !url! | findstr /i "youtube.com youtu.be" >nul
if !errorlevel! neq 0 exit /b 1
exit /b 0

:validate_folder
set "test_folder=%~1"

:: Check if folder path contains invalid characters or is too long
if "!test_folder!"=="" (
    echo [ERROR] Empty folder path provided.
    exit /b 1
)

:: Check if folder exists
if not exist "!test_folder!" (
    echo [INFO] Creating folder: !test_folder!
    :: Use md with quotes to handle spaces and create parent directories
    md "!test_folder!" 2>nul
    if not exist "!test_folder!" (
        echo [ERROR] Failed to create directory. Check permissions and path validity.
        exit /b 1
    )
) else (
    echo [INFO] Folder exists: !test_folder!
)

:: Test write access - use a simpler approach
set "test_file=!test_folder!\~ytdl_test_%RANDOM%.tmp"
echo test > "!test_file!" 2>nul
if exist "!test_file!" (
    del "!test_file!" 2>nul
    echo [INFO] Write access confirmed
    exit /b 0
)
echo [ERROR] Cannot write to folder. Check permissions.
exit /b 1


:load_config
if exist "!CONFIG_FILE!" (
    for /f "tokens=1,* delims==" %%a in (!CONFIG_FILE!) do (
        if "%%a"=="default_folder" set "default_folder=%%b"
    )
) else (
    set "default_folder=%USERPROFILE%\Downloads\YouTube"
)
goto :eof

:save_config
set "save_folder=%~1"
(
    echo default_folder=!save_folder!
) > "!CONFIG_FILE!"
goto :eof

:set_download_format
set "choice=%~1"
if "!choice!"=="1" (
    set "download_format=-f bestvideo+bestaudio/best"
    set "format_description=Best Video + Audio"
) else if "!choice!"=="2" (
    set "download_format=-f bestaudio/best -x --audio-format mp3 --audio-quality 0"
    set "format_description=Audio Only (MP3)"
) else if "!choice!"=="3" (
    set "download_format=-f bestvideo/best"
    set "format_description=Video Only (MP4)"
) else if "!choice!"=="4" (
    echo.
    echo Quality options:
    echo [1080p] -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
    echo [720p]  -f "bestvideo[height<=720]+bestaudio/best[height<=720]"
    echo [480p]  -f "bestvideo[height<=480]+bestaudio/best[height<=480]"
    echo.
    set /p "custom_format=Enter custom yt-dlp format (or press Enter for 1080p): "
    if "!custom_format!"=="" (
        set "download_format=-f bestvideo[height<=1080]+bestaudio/best[height<=1080]"
        set "format_description=Custom (1080p max)"
    ) else (
        set "download_format=-f !custom_format!"
        set "format_description=Custom Format"
    )
) else (
    set "download_format=-f bestvideo+bestaudio/best"
    set "format_description=Best Video + Audio (default)"
)
goto :eof