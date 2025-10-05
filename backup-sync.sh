# File: backup-sync.sh
#!/usr/bin/env bash
#
# backup-sync.sh
# Simple script to backup or sync two directories using rsync
# Author: Your Name
# License: MIT

set -euo pipefail
IFS=$'\n\t'

DRY_RUN=false
EXCLUDE_FILE=""
LOG_FILE="/var/log/backup-sync.log"
LOCK_FILE="/tmp/backup-sync.lock"

usage() {
  cat <<EOF
Usage: $(basename "$0") -s SOURCE -d DESTINATION [options]

Options:
  -s SOURCE        Path to source directory (required)
  -d DESTINATION   Path to destination directory (required)
  -e EXCLUDE_FILE  File containing exclude patterns (one per line)
  -l LOG_FILE      Path to log file (default: $LOG_FILE)
  -n               Dry-run mode (show commands without executing)
  -h               Show this help message
EOF
  exit 1
}

# Parse command-line arguments
while getopts ":s:d:e:l:nh" opt; do
  case ${opt} in
    s) SOURCE="$OPTARG" ;;
    d) DESTINATION="$OPTARG" ;;
    e) EXCLUDE_FILE="$OPTARG" ;;
    l) LOG_FILE="$OPTARG" ;;
    n) DRY_RUN=true ;;
    h|*) usage ;;
  esac
done

# Validate required arguments
if [[ -z "${SOURCE-}" || -z "${DESTINATION-}" ]]; then
  echo "ERROR: SOURCE and DESTINATION are required." >&2
  usage
fi

# Prevent concurrent runs
if [[ -e "$LOCK_FILE" ]]; then
  echo "Another instance is already running. Exiting." >&2
  exit 2
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Build rsync options
RSYNC_OPTS=(-a --delete --human-readable --info=progress2)
[[ -n "$EXCLUDE_FILE" ]] && RSYNC_OPTS+=(--exclude-from="$EXCLUDE_FILE")
[[ "$DRY_RUN" = true ]] && RSYNC_OPTS+=(--dry-run)

# Execute rsync
echo "[$(date '+%F %T')] Starting backup from $SOURCE to $DESTINATION" | tee -a "$LOG_FILE"
rsync "${RSYNC_OPTS[@]}" "$SOURCE"/ "$DESTINATION"/ >> "$LOG_FILE" 2>&1
STATUS=$?
echo "[$(date '+%F %T')] Finished with status $STATUS" | tee -a "$LOG_FILE"

exit $STATUS

# -------------------------------------------------------------------
# File: exclude.txt
# -------------------------------------------------------------------
*.cache
node_modules/
*.tmp

# -------------------------------------------------------------------
# File: README.md
# -------------------------------------------------------------------
# backup-sync

A simple script to backup or sync directories using `rsync`.

## Repository Structure
- `backup-sync.sh` : Main backup/sync script  
- `exclude.txt`    : Exclude patterns file  
- `README.md`      : Project documentation  
- `LICENSE`        : MIT License details

## Prerequisites
- Linux/Unix environment  
- Bash (version 4+)  
- `rsync` installed  

## Installation
```bash
git clone https://github.com/YOUR_USERNAME/backup-sync.git
cd backup-sync
chmod +x backup-sync.sh
