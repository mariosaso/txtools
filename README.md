# txdl: Accelerated Download Manager for Termux

**Version:** 0.0.1  
**Author:** Mario Saso

***

## Table of Contents

- [Overview](#overview)  
- [Features](#features)  
- [Requirements](#requirements)  
- [Installation](#installation)  
- [Usage](#usage)  
  - [Basic HTTP/HTTPS Download](#basic-httphttps-download)  
  - [Magnet Link Download](#magnet-link-download)  
  - [Torrent File Download](#torrent-file-download)  
  - [Most Recent Torrent](#most-recent-torrent)  
  - [Resume Interrupted Download](#resume-interrupted-download)  
  - [Custom Download Directory](#custom-download-directory)  
  - [Help & Examples](#help--examples)  
- [Configuration & Environment Variables](#configuration--environment-variables)  
- [Error Handling & Exit Codes](#error-handling--exit-codes)  
- [How It Works](#how-it-works)  
- [Troubleshooting](#troubleshooting)  
- [License](#license)  

***

## Overview

**txdl** is a robust, production-ready Bash script designed to accelerate downloads on Android devices running Termux. Leveraging the power of [aria2c](https://aria2.github.io/), it supports HTTP/HTTPS URLs, magnet links, and torrent files, providing multi-connection transfers, resume capability, and optimized BitTorrent settings.

***

## Features

- **Protocol Support**  
  - HTTP & HTTPS  
  - Magnet links  
  - .torrent files (by path or auto-detection)

- **Download Modes**  
  - Single-link downloads (`-l`)  
  - Auto-detect latest torrent (`-t`)  
  - Resume interrupted downloads (`-r`)

- **Performance Optimizations**  
  - Multi-source, multi-connection downloads  
  - Split downloads and file preallocation  
  - BitTorrent enhancements (DHT, LPD, peer limits)

- **Robust Error Handling**  
  - Dependency checks (auto-installs aria2)  
  - Disk space & permission validation  
  - Input sanitization and validation  
  - Cleanup of temporary/partial files  

- **User-Friendly**  
  - Colored, informative output  
  - Progress summary with speed, percentage, ETA  
  - Comprehensive help and usage examples  
  - Configurable via environment variables  

***

## Requirements

- **Termux** (with `termux-setup-storage` configured)  
- **aria2** package (installed automatically by the script if missing)  
- Bash shell (`/data/data/com.termux/files/usr/bin/bash`)  

***

## Installation

1. Copy `txdl.sh` into your Termux home directory:  
   ```bash
   cp txdl.sh ~/txdl.sh
   ```
2. Make the script executable:  
   ```bash
   chmod +x ~/txdl.sh
   ```
3. (Optional) Move to a directory in your PATH for global access:
   ```bash
   mv ~/txdl.sh /data/data/com.termux/files/usr/bin/txdl
   ```

***

## Usage

```bash
bash txdl.sh [OPTIONS]
```

### Basic HTTP/HTTPS Download

```bash
bash txdl.sh -l https://example.com/file.zip
```

### Magnet Link Download

```bash
bash txdl.sh -l "magnet:?xt=urn:btih:abcdef1234567890..."
```

### Torrent File Download

```bash
bash txdl.sh -l /path/to/file.torrent
```

### Most Recent Torrent

Automatically locate and download the newest `.torrent` in the default directory:

```bash
bash txdl.sh -t
```

### Resume Interrupted Download

Resume using the existing `.aria2` control file:

```bash
bash txdl.sh -r incomplete_file.zip
```

### Custom Download Directory

Specify an alternate directory (must exist or be creatable):

```bash
bash txdl.sh -l https://example.com/file.zip -d /sdcard/MyDownloads
```

### Help & Examples

Display detailed help and usage examples:

```bash
bash txdl.sh -h
```

***

## Configuration & Environment Variables

Customize default behavior by exporting environment variables before running:

```bash
export ARIA2_MAX_CONNECTIONS=16
export ARIA2_MIN_SPLIT_SIZE=1M
export ARIA2_MAX_CONCURRENT_DOWNLOADS=3
export ARIA2_TIMEOUT=60
export ARIA2_RETRY_WAIT=3
export ARIA2_MAX_TRIES=5
```

- **ARIA2_MAX_CONNECTIONS**: Connections per server  
- **ARIA2_MIN_SPLIT_SIZE**: Minimum split size for segments  
- **ARIA2_MAX_CONCURRENT_DOWNLOADS**: Parallel downloads  
- **ARIA2_TIMEOUT**: Connection timeout (seconds)  
- **ARIA2_RETRY_WAIT**: Wait time between retries (seconds)  
- **ARIA2_MAX_TRIES**: Number of retry attempts  

***

## Error Handling & Exit Codes

- `0` — Success  
- `1` — General error or invalid input  
- `2` — Dependency install failure  
- `3` — Disk space or permission error  
- `4` — Download or resume failure  
- `130` — Interrupted by user (SIGINT/SIGTERM)  

Clear, colored messages indicate status and errors; temporary `.aria2` files are cleaned up on failure.

***

## How It Works

1. **Dependency Check**  
   Installs `aria2` if missing.  
2. **Option Parsing**  
   Validates `-l`, `-t`, `-r`, `-d`, and `-h`.  
3. **Environment & Permissions**  
   Expands `~`, creates download directory, checks write access and disk space.  
4. **Input Validation**  
   Ensures URLs, magnet links, and torrent paths are valid.  
5. **Aria2c Command Assembly**  
   Builds an optimized command string with proper flags.  
6. **Execution & Progress**  
   Runs `aria2c` with summary updates every 5 seconds.  
7. **Cleanup**  
   Removes temporary files on error or interruption.  

***

## Troubleshooting

- **Permission Denied**:  
  Ensure Termux has storage permission:  
  ```bash
  termux-setup-storage
  ```

- **Insufficient Disk Space**:  
  Free up space or choose a different download directory with `-d`.

- **aria2 Install Fails**:  
  Manually install with:
  ```bash
  pkg update && pkg install aria2
  ```

- **Resume Not Working**:  
  Verify the `.aria2` control file exists alongside the partial file.  

***

## License

This project is released under the GPL3 License. See [LICENSE](LICENSE) for details.

***

*Accelerate your downloads on Termux with txdl!*

