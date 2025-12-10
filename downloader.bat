@echo off
title YouTube Playlist Auto Downloader
color 0a

echo ============================
echo   YT-DLP PLAYLIST DOWNLOADER
echo ============================
echo.

:: Ask for playlist link
set /p playlist="Paste YouTube playlist link: "

:: Ask for download folder
set /p folder="Enter download folder path: "

:: Create folder if it doesn't exist
if not exist "%folder%" (
    echo Creating folder: %folder%
    mkdir "%folder%"
)

echo.
echo Starting download...
echo.

:: FIXED yt-dlp command with all flags
yt-dlp -f "bestvideo+bestaudio/best" ^
 --concurrent-fragments 1 --fragment-retries 20 ^
 --extractor-args "youtube:player_client=default" ^
 -o "%folder%\%%(title)s.%%(ext)s" %playlist%

echo.
echo ============================
echo   DOWNLOAD COMPLETE!
echo ============================
pause
