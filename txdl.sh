#!/data/data/com.termux/files/usr/bin/bash

#=============================================================
# txdl.sh - Download accelerator for Termux
# Author: Mario
# Version: 0.0.1
# Description: Accelerates downloads on Android devices using aria2c
# Supports HTTP/HTTPS URLs, magnet links, and torrent files
#=============================================================

# Script configuration via environment variables
ARIA2_MAX_CONNECTIONS="${ARIA2_MAX_CONNECTIONS:-16}"
ARIA2_MIN_SPLIT_SIZE="${ARIA2_MIN_SPLIT_SIZE:-1M}"
ARIA2_MAX_CONCURRENT_DOWNLOADS="${ARIA2_MAX_CONCURRENT_DOWNLOADS:-3}"
ARIA2_TIMEOUT="${ARIA2_TIMEOUT:-60}"
ARIA2_RETRY_WAIT="${ARIA2_RETRY_WAIT:-3}"
ARIA2_MAX_TRIES="${ARIA2_MAX_TRIES:-5}"

# Default download directory
DEFAULT_DOWNLOAD_DIR="$HOME/Downloads"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Show usage information
show_help() {
    cat << 'EOF'
txdl.sh v0.0.1 by Mario - Download accelerator for Termux

USAGE:
    bash txdl.sh -l <URL|magnet|torrent_file> [-d <directory>]
    bash txdl.sh -t [-d <directory>]
    bash txdl.sh -r <file_to_resume> [-d <directory>]
    bash txdl.sh -h

OPTIONS:
    -l  Link or file (HTTP/HTTPS URL, magnet link, or .torrent file path)
    -t  Use the most recent .torrent file in the download directory
    -r  Resume an interrupted download (specify the incomplete file name)
    -d  Specify custom download directory (default: ~/Downloads)
    -h  Display this help message

EXAMPLES:
    # Download from HTTP/HTTPS URL
    bash txdl.sh -l https://example.com/file.zip

    # Download using magnet link
    bash txdl.sh -l "magnet:?xt=urn:btih:..."

    # Download torrent file
    bash txdl.sh -l /path/to/file.torrent

    # Use most recent torrent in download directory
    bash txdl.sh -t

    # Resume interrupted download
    bash txdl.sh -r incomplete_file.zip

    # Specify custom download directory
    bash txdl.sh -l https://example.com/file.zip -d /sdcard/MyDownloads

CONFIGURATION:
    Set these environment variables to customize behavior:
    ARIA2_MAX_CONNECTIONS=16        # Max connections per server
    ARIA2_MIN_SPLIT_SIZE=1M         # Minimum split size
    ARIA2_MAX_CONCURRENT_DOWNLOADS=3 # Max parallel downloads
    ARIA2_TIMEOUT=60                # Connection timeout
    ARIA2_RETRY_WAIT=3              # Wait time between retries
    ARIA2_MAX_TRIES=5               # Maximum retry attempts

REQUIREMENTS:
    - aria2c (automatically installed if missing)
    - Storage permission (run termux-setup-storage if needed)

EOF
}

# Check if aria2c is installed
check_dependencies() {
    if ! command -v aria2c &> /dev/null; then
        print_warning "aria2c not found. Installing..."
        if ! pkg install aria2 -y; then
            print_error "Failed to install aria2. Please install manually: pkg install aria2"
            return 1
        fi
        print_success "aria2c installed successfully"
    fi
    return 0
}

# Check available disk space
check_disk_space() {
    local download_dir="$1"
    local required_space_mb=100  # Minimum 100MB required

    # Get available space in MB
    local available_space=$(df "$download_dir" 2>/dev/null | awk 'NR==2 {print int($4/1024)}')

    if [[ -z "$available_space" || "$available_space" -lt "$required_space_mb" ]]; then
        print_error "Insufficient disk space. At least ${required_space_mb}MB required in $download_dir"
        return 1
    fi

    print_info "Available disk space: ${available_space}MB"
    return 0
}

# Check if directory is writable
check_permissions() {
    local dir="$1"

    # Create directory if it doesn't exist
    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            print_error "Cannot create directory: $dir"
            return 1
        fi
        print_info "Created directory: $dir"
    fi

    # Check write permissions
    if [[ ! -w "$dir" ]]; then
        print_error "No write permission for directory: $dir"
        return 1
    fi

    return 0
}

# Validate URL format
validate_url() {
    local url="$1"

    # Check for HTTP/HTTPS URLs
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    fi

    # Check for magnet links
    if [[ "$url" =~ ^magnet: ]]; then
        return 0
    fi

    # Check for torrent files
    if [[ -f "$url" && "$url" =~ \.torrent$ ]]; then
        return 0
    fi

    print_error "Invalid URL or file: $url"
    return 1
}

# Escape special characters in magnet links
escape_magnet_link() {
    local magnet="$1"
    # Properly quote the magnet link to handle special characters
    printf '%q' "$magnet"
}

# Find the most recent .torrent file
find_recent_torrent() {
    local download_dir="$1"
    local torrent_file

    # Find the most recent .torrent file
    torrent_file=$(find "$download_dir" -name "*.torrent" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

    if [[ -z "$torrent_file" ]]; then
        print_error "No .torrent files found in $download_dir"
        return 1
    fi

    if [[ ! -f "$torrent_file" ]]; then
        print_error "Torrent file not found: $torrent_file"
        return 1
    fi

    echo "$torrent_file"
    return 0
}

# Clean up temporary and partial files
cleanup_files() {
    local download_dir="$1"
    local pattern="$2"

    if [[ -n "$pattern" ]]; then
        print_info "Cleaning up temporary files matching: $pattern"
        find "$download_dir" -name "$pattern" -type f -delete 2>/dev/null || true
    fi
}

# Build aria2c command with optimized options
build_aria2_command() {
    local input="$1"
    local download_dir="$2"
    local resume_mode="$3"

    local cmd="aria2c"

    # Basic options
    cmd+=" --dir='$download_dir'"
    cmd+=" --max-connection-per-server=$ARIA2_MAX_CONNECTIONS"
    cmd+=" --min-split-size=$ARIA2_MIN_SPLIT_SIZE"
    cmd+=" --max-concurrent-downloads=$ARIA2_MAX_CONCURRENT_DOWNLOADS"
    cmd+=" --timeout=$ARIA2_TIMEOUT"
    cmd+=" --retry-wait=$ARIA2_RETRY_WAIT"
    cmd+=" --max-tries=$ARIA2_MAX_TRIES"

    # Resume support
    if [[ "$resume_mode" == "true" ]]; then
        cmd+=" --continue=true"
        cmd+=" --allow-overwrite=false"
    else
        cmd+=" --continue=true"
        cmd+=" --auto-file-renaming=true"
    fi

    # Optimize for different protocols
    cmd+=" --split=16"
    cmd+=" --file-allocation=falloc"
    cmd+=" --check-certificate=false"

    # BitTorrent specific options for magnet/torrent
    if [[ "$input" =~ ^magnet: ]] || [[ "$input" =~ \.torrent$ ]]; then
        cmd+=" --seed-time=0"
        cmd+=" --bt-max-peers=100"
        cmd+=" --bt-request-peer-speed-limit=100K"
        cmd+=" --max-upload-limit=1K"
        cmd+=" --listen-port=6881-6999"
        cmd+=" --enable-dht=true"
        cmd+=" --bt-enable-lpd=true"
        cmd+=" --bt-enable-hook-after-hash-check=true"
    fi

    # Progress and interface options
    cmd+=" --summary-interval=5"
    cmd+=" --console-log-level=notice"

    # Add the input (URL, magnet, or torrent file)
    if [[ "$input" =~ ^magnet: ]]; then
        local escaped_magnet=$(escape_magnet_link "$input")
        cmd+=" $escaped_magnet"
    else
        cmd+=" '$input'"
    fi

    echo "$cmd"
}

# Main download function
download_file() {
    local input="$1"
    local download_dir="$2"
    local resume_mode="${3:-false}"

    print_info "Starting download..."
    print_info "Input: $input"
    print_info "Download directory: $download_dir"

    # Build and execute aria2c command
    local aria2_cmd=$(build_aria2_command "$input" "$download_dir" "$resume_mode")

    print_info "Executing: aria2c with optimized settings"

    # Execute the command
    if eval "$aria2_cmd"; then
        print_success "Download completed successfully!"
        return 0
    else
        local exit_code=$?
        print_error "Download failed with exit code: $exit_code"

        # Cleanup on failure
        cleanup_files "$download_dir" "*.aria2"

        return $exit_code
    fi
}

# Resume download function
resume_download() {
    local file_to_resume="$1"
    local download_dir="$2"

    local full_path="$download_dir/$file_to_resume"
    local control_file="$full_path.aria2"

    # Check if control file exists
    if [[ ! -f "$control_file" ]]; then
        print_error "Control file not found: $control_file"
        print_error "Cannot resume download without control file"
        return 1
    fi

    print_info "Resuming download: $file_to_resume"

    # Try to resume using the same command that created the control file
    local aria2_cmd="aria2c --continue=true --dir='$download_dir' --max-connection-per-server=$ARIA2_MAX_CONNECTIONS"
    aria2_cmd+=" --min-split-size=$ARIA2_MIN_SPLIT_SIZE --timeout=$ARIA2_TIMEOUT"
    aria2_cmd+=" --retry-wait=$ARIA2_RETRY_WAIT --max-tries=$ARIA2_MAX_TRIES"
    aria2_cmd+=" --allow-overwrite=false --auto-file-renaming=false"

    print_info "Attempting to resume with existing control file"

    # Change to download directory and run aria2c
    if (cd "$download_dir" && eval "$aria2_cmd" 2>/dev/null); then
        print_success "Download resumed and completed successfully!"
        return 0
    else
        print_error "Failed to resume download"
        print_info "Control file may be corrupted or incompatible"
        return 1
    fi
}

# Main script logic
main() {
    local link=""
    local download_dir="$DEFAULT_DOWNLOAD_DIR"
    local use_recent_torrent=false
    local resume_file=""

    # Parse command line options
    while getopts ":l:d:tr:h" opt; do
        case $opt in
            l)
                link="$OPTARG"
                ;;
            d)
                download_dir="$OPTARG"
                ;;
            t)
                use_recent_torrent=true
                ;;
            r)
                resume_file="$OPTARG"
                ;;
            h)
                show_help
                exit 0
                ;;
            :)
                print_error "Option -$OPTARG requires an argument"
                show_help
                exit 1
                ;;
            \?)
                print_error "Invalid option: -$OPTARG"
                show_help
                exit 1
                ;;
        esac
    done

    # Check if no options provided
    if [[ $OPTIND -eq 1 ]]; then
        show_help
        exit 0
    fi

    # Validate mutually exclusive options
    local option_count=0
    [[ -n "$link" ]] && ((option_count++))
    [[ "$use_recent_torrent" == true ]] && ((option_count++))
    [[ -n "$resume_file" ]] && ((option_count++))

    if [[ $option_count -eq 0 ]]; then
        print_error "No download option specified. Use -l, -t, or -r"
        show_help
        exit 1
    elif [[ $option_count -gt 1 ]]; then
        print_error "Only one download option (-l, -t, or -r) can be used at a time"
        show_help
        exit 1
    fi

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Expand tilde in download directory
    download_dir="${download_dir/#\~/$HOME}"

    # Check permissions and disk space
    if ! check_permissions "$download_dir"; then
        exit 1
    fi

    if ! check_disk_space "$download_dir"; then
        exit 1
    fi

    # Handle different download modes
    if [[ -n "$resume_file" ]]; then
        # Resume mode
        if ! resume_download "$resume_file" "$download_dir"; then
            exit 1
        fi
    elif [[ "$use_recent_torrent" == true ]]; then
        # Use most recent torrent file
        local torrent_file
        if ! torrent_file=$(find_recent_torrent "$download_dir"); then
            exit 1
        fi
        print_info "Using torrent file: $torrent_file"
        if ! download_file "$torrent_file" "$download_dir"; then
            exit 1
        fi
    else
        # Regular download mode
        if ! validate_url "$link"; then
            exit 1
        fi
        if ! download_file "$link" "$download_dir"; then
            exit 1
        fi
    fi

    print_success "Operation completed successfully!"
    exit 0
}

# Trap signals for cleanup
trap 'print_warning "Download interrupted by user"; exit 130' INT TERM

# Run main function with all arguments
main "$@"