# YouTube Video & Playlist Downloader

A robust Windows batch and PowerShell tool for downloading YouTube videos and playlists using yt-dlp with enhanced features like quality selection, logging, error handling, and configuration management.

## Features

✅ **Multiple Quality Options** - Best quality, audio-only (MP3), video-only, or custom quality presets (1080p/720p/480p)  
✅ **Enhanced Error Handling** - Dependency checks, input validation, and detailed error messages  
✅ **Download Logging** - Automatic logging of all downloads with timestamps  
✅ **Configuration Memory** - Remembers your preferred download folder  
✅ **Resume Support** - Continue interrupted downloads automatically  
✅ **Metadata Embedding** - Adds metadata, descriptions, and thumbnails to downloaded files  
✅ **Batch & PowerShell Versions** - Choose between traditional batch file or modern PowerShell script  
✅ **Command-line Support** - Run with arguments for automation and scripting

## Available Scripts

- `downloader.bat` - Original simple batch version
- `downloader_improved.bat` - Enhanced batch version with all features
- `downloader.ps1` - PowerShell version with colored output and better error handling

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

### Batch Script (Simple)
```cmd
downloader_improved.bat
```

1. Double-click `downloader_improved.bat` to run the program
2. Choose quality preset (1-4)
3. Paste your YouTube playlist URL **or** a single video URL
4. Enter the folder path where you want to save the downloaded videos (or press Enter to use default)
5. Press Enter and wait for the download to complete

### PowerShell Script (Recommended)
```powershell
# Interactive mode
.\downloader.ps1

# With command-line arguments
.\downloader.ps1 -Url "https://youtu.be/..." -OutputPath "C:\Downloads" -Quality "1080p"

# Audio only download
.\downloader.ps1 -Url "https://youtu.be/..." -AudioOnly

# Show help
.\downloader.ps1 -Help
```

**Note:** You may need to enable PowerShell script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Quality Options

- **Best Quality** - Downloads highest quality video + audio and merges them
- **Audio Only (MP3)** - Extracts audio and converts to MP3 format
- **Video Only** - Downloads video without audio
- **1080p/720p/480p** - Downloads video capped at specified resolution
- **Custom** - Enter your own yt-dlp format string

## File Organization

Downloads are automatically organized:
- **Main folder:** Video and audio files (e.g., `Channel Name - Video Title.mp4`)
- **`metadata` subfolder:** Thumbnails, descriptions, and .info.json files

This keeps your download folder clean with only media files visible, while metadata is neatly organized separately.

## Configuration Files

- `config.txt` / `config.json` - Stores your default download folder
- `download.log` - Records all download activity with timestamps

These files are created automatically on first run and are excluded from git.
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

**PowerShell script won't run**
- Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` in PowerShell as Administrator

**Download fails immediately**
- Check the `download.log` file for detailed error messages
- Ensure the YouTube URL is valid and accessible
- Try updating yt-dlp to the latest version: `pip install --upgrade yt-dlp`

## Technical Details

The scripts use enhanced download settings for reliability:
- `-f "bestvideo+bestaudio/best"` - Downloads the best quality video and audio
- `--concurrent-fragments 1` - Downloads one fragment at a time to prevent connection issues
- `--fragment-retries 20` - Retries up to 20 times per fragment for better success rate
- `--extractor-args "youtube:player_client=default"` - Ensures compatibility with YouTube restrictions
- `--embed-metadata` - Embeds video metadata into downloaded files
- `--write-thumbnail` - Downloads video thumbnails
- `--no-overwrites --continue` - Resumes interrupted downloads

## Contributing

Contributions are welcome! Feel free to:
- Report bugs or issues
- Suggest new features
- Submit pull requests with improvements

## Disclaimer

This tool is for personal use only. Users are responsible for complying with YouTube's Terms of Service and applicable copyright laws. Only download content you have the right to download.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**MIT License Summary:**
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Private use allowed
- ⚠️ No warranty provided
- ⚠️ No liability accepted

Copyright (c) 2025. All rights reserved.

---

**Built with:** yt-dlp, FFmpeg, Windows Batch, PowerShell  
**Maintained by:** Community Contributors
