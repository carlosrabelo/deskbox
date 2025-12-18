#!/bin/bash
# ==============================================================================
# Deskbox Log Rotation Script
# ==============================================================================
# Rotates and manages log files to prevent disk space issues
# Configured to run via cron or manually
# ==============================================================================

set -e

# Configuration
LOG_DIR="/var/log/deskbox"
RETENTION_DAYS=30
MAX_LOG_SIZE="100M"  # Rotate when log reaches 100MB
COMPRESS_DELAY=1     # Compress after 1 day
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to check log size
check_log_size() {
    local log_file=$1
    if [ -f "$log_file" ]; then
        local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
        echo $size
    else
        echo 0
    fi
}

# Function to convert size to bytes
size_to_bytes() {
    local size=$1
    case $size in
        *K|*k) echo $((${size%[Kk]} * 1024)) ;;
        *M|m) echo $((${size%[Mm]} * 1024 * 1024)) ;;
        *G|g) echo $((${size%[Gg]} * 1024 * 1024 * 1024)) ;;
        *) echo $size ;;
    esac
}

# Function to rotate log file
rotate_log() {
    local log_file=$1
    local log_name=$(basename "$log_file")
    
    if [ ! -f "$log_file" ]; then
        print_status $YELLOW "Log file does not exist: $log_file"
        return 0
    fi
    
    local current_size=$(check_log_size "$log_file")
    local max_size_bytes=$(size_to_bytes "$MAX_LOG_SIZE")
    
    if [ $current_size -gt $max_size_bytes ]; then
        print_status $YELLOW "Rotating log file: $log_file (size: $current_size bytes)"
        
        # Create rotated log file with timestamp
        local rotated_file="${log_file}.${TIMESTAMP}"
        mv "$log_file" "$rotated_file"
        
        # Create new empty log file
        touch "$log_file"
        
        # Set proper permissions
        chmod 644 "$log_file"
        chown root:root "$log_file" 2>/dev/null || true
        
        print_status $GREEN "Log rotated successfully: $rotated_file"
        return 1  # Indicate rotation occurred
    fi
    
    return 0  # No rotation needed
}

# Function to compress old logs
compress_logs() {
    print_status $BLUE "Compressing old logs..."
    
    find "$LOG_DIR" -name "*.log.*" -type f -mtime +$COMPRESS_DELAY ! -name "*.gz" -print0 | while IFS= read -r -d $'\0' log_file; do
        print_status $YELLOW "Compressing: $log_file"
        gzip "$log_file"
        print_status $GREEN "Compressed: ${log_file}.gz"
    done
}

# Function to clean old logs
clean_old_logs() {
    print_status $BLUE "Cleaning logs older than $RETENTION_DAYS days..."
    
    local deleted_count=0
    find "$LOG_DIR" -name "*.log.*" -type f -mtime +$RETENTION_DAYS -print0 | while IFS= read -r -d $'\0' log_file; do
        print_status $YELLOW "Deleting old log: $log_file"
        rm -f "$log_file"
        deleted_count=$((deleted_count + 1))
    done
    
    print_status $GREEN "Log cleanup completed"
}

# Function to show log statistics
show_stats() {
    print_status $BLUE "Log Directory Statistics:"
    echo "=================================="
    
    if [ ! -d "$LOG_DIR" ]; then
        print_status $RED "Log directory does not exist: $LOG_DIR"
        return 1
    fi
    
    # Total size
    local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
    print_status $GREEN "Total log directory size: $total_size"
    
    # Number of log files
    local log_count=$(find "$LOG_DIR" -name "*.log*" -type f | wc -l)
    print_status $GREEN "Number of log files: $log_count"
    
    # Current log files
    echo ""
    print_status $BLUE "Current log files:"
    ls -lah "$LOG_DIR"/*.log 2>/dev/null || print_status $YELLOW "No current log files found"
    
    # Rotated logs
    echo ""
    print_status $BLUE "Rotated logs (last 10):"
    find "$LOG_DIR" -name "*.log.*" -type f -printf "%T@ %p\n" | sort -nr | head -10 | while read timestamp file; do
        local file_time=$(date -d "@${timestamp%.*}" '+%Y-%m-%d %H:%M:%S')
        local file_size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  $file_time - $file ($file_size)"
    done
}

# Function to show help
show_help() {
    echo "Deskbox Log Rotation Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  rotate     Rotate logs if they exceed size limit"
    echo "  compress   Compress old uncompressed logs"
    echo "  clean      Remove logs older than retention period"
    echo "  all        Run full rotation cycle (rotate + compress + clean)"
    echo "  stats      Show log directory statistics"
    echo "  help       Show this help"
    echo ""
    echo "Configuration:"
    echo "  Log Directory: $LOG_DIR"
    echo "  Max Log Size: $MAX_LOG_SIZE"
    echo "  Retention Days: $RETENTION_DAYS"
    echo "  Compress Delay: $COMPRESS_DELAY days"
}

# Main script logic
case "${1:-help}" in
    rotate)
        print_status $GREEN "Starting log rotation..."
        rotation_needed=0
        
        # Rotate main log files
        for log_file in "$LOG_DIR/startup.log" "$LOG_DIR/xrdp.log"; do
            if ! rotate_log "$log_file"; then
                rotation_needed=1
            fi
        done
        
        if [ $rotation_needed -eq 0 ]; then
            print_status $GREEN "No logs needed rotation"
        fi
        ;;
        
    compress)
        compress_logs
        ;;
        
    clean)
        clean_old_logs
        ;;
        
    all)
        print_status $GREEN "Starting full log rotation cycle..."
        rotate
        compress
        clean
        print_status $GREEN "Full log rotation cycle completed"
        ;;
        
    stats)
        show_stats
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        print_status $RED "Unknown command: $1"
        show_help
        exit 1
        ;;
esac