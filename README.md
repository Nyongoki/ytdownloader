# YouTube Video & Playlist Downloader

A simple batch file tool for downloading YouTube videos and playlists using yt-dlp.

## Requirements

Before using this tool, you must have the following installed on your system:

### 1. yt-dlp
yt-dlp is the core download utility that powers this tool.

**Installation:**
- Download from: https://github.com/yt-dlp/yt-dlp/releases
- Or install via pip: `pip install yt-dlp`
- Or install via winget: `winget install yt-dlp`

Make sure yt-dlp is added to your system PATH so it can be run from anywhere.

### 2. FFmpeg
FFmpeg is required for merging audio and video streams and for converting media formats.

**Installation:**
- Download from: https://ffmpeg.org/download.html
- Or install via winget: `winget install ffmpeg`
- Or download a pre-built binary from: https://www.gyan.dev/ffmpeg/builds/

**Important:** After downloading FFmpeg, you must add it to your system PATH:
1. Extract the FFmpeg archive to a permanent location (e.g., `C:\ffmpeg`)
2. Add the `bin` folder to your system PATH environment variable
3. Restart your command prompt/PowerShell after adding to PATH

### 3. Python (Optional)
If you installed yt-dlp via pip, you'll need Python installed:
- Download from: https://www.python.org/downloads/
- Make sure to check "Add Python to PATH" during installation

## How to Use

1. Double-click `downloader.bat` to run the program
2. When prompted, paste your YouTube playlist URL **or** a single video URL
3. Enter the folder path where you want to save the downloaded videos
4. Press Enter and wait for the download to complete

## Features

- Downloads entire YouTube playlists or individual videos
- Downloads best quality video and audio (bestvideo+bestaudio format)
- Improved download reliability with fragment retry mechanisms (20 retries per fragment)
- Single concurrent fragment download to prevent connection issues
- Creates the download folder if it doesn't exist
- Uses clean filenames based on video titles
- Shows download progress in real-time
- Compatible with Windows systems

## Troubleshooting

**"yt-dlp is not recognized as an internal or external command"**
- yt-dlp is not installed or not in your PATH. Install it and add to PATH.

**Videos download without audio or in poor quality**
- FFmpeg is not installed or not in your PATH. Install FFmpeg and add it to PATH.

**"Access is denied" error when creating folder**
- Choose a folder location where you have write permissions
- Try running the batch file as Administrator

## Notes

- The script uses enhanced download settings for better reliability:
  - `-f "bestvideo+bestaudio/best"` - Downloads the best quality video and audio
  - `--concurrent-fragments 1` - Downloads one fragment at a time to prevent connection issues
  - `--fragment-retries 20` - Retries up to 20 times per fragment for better success rate
  - `--extractor-args "youtube:player_client=default"` - Ensures compatibility with current YouTube restrictions
- Downloaded files are saved with their original video titles
- FFmpeg automatically merges the best video and audio streams into a single file

## License

This is a simple utility script provided as-is for personal use.
