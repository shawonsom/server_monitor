#!/bin/bash

# This script generates an HTML server performance report.
# It is designed to be run by a cron job.

# Find the script's own directory, so it can be run from anywhere.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT_DIR="${SCRIPT_DIR}/public_html/report"
OUTPUT_FILE="${OUTPUT_DIR}/report.html"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# --- Start HTML Generation ---
# Overwrite the file with the HTML header.
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="300">
    <title>Server Performance Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Helvetica Neue", Arial, sans-serif; background-color: #f4f4f9; color: #333; margin: 0; padding: 1em; }
        .container { background-color: #fff; padding: 2em; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); max-width: 900px; margin: auto; }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 1em; }
        h2 { color: #3498db; border-bottom: 2px solid #ecf0f1; padding-bottom: 10px; margin-top: 30px; }
        .green { color: #27ae60; font-weight: bold; }
        .data-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1em; margin-top: 1em; }
        .data-item { background-color: #fdfdfd; padding: 15px; border-radius: 5px; border: 1px solid #ecf0f1; }
        .data-item strong { display: block; margin-bottom: 5px; color: #7f8c8d; }
        pre { background-color: #2c3e50; color: #ecf0f1; padding: 1em; border-radius: 5px; white-space: pre-wrap; word-break: break-all; font-family: "Menlo", "Monaco", "Consolas", monospace; font-size: 0.9em; }
        .footer { text-align: center; margin-top: 2em; font-size: 0.9em; color: #95a5a6; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Performance Report</h1>
EOF

# --- Helper function to append content to the report file ---
print_header() {
    echo "<h2>$1</h2>" >> "$OUTPUT_FILE"
}

# --- Collect Data and Append to HTML ---

# IP Address & Hostname
print_header "System Identity"
IP_ADDR=$(ip -4 addr show $(ip route get 1 | awk '{print $5}' | head -1) | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
HOSTNAME_VAL=$(hostname)
cat >> "$OUTPUT_FILE" << EOF
<div class="data-grid">
    <div class="data-item"><strong>Hostname:</strong> <span class="green">${HOSTNAME_VAL}</span></div>
    <div class="data-item"><strong>Primary IP:</strong> <span class="green">${IP_ADDR:-Not Found}</span></div>
</div>
EOF

# Uptime
print_header "Uptime"
UPTIME_STR=$(uptime -p)
cat >> "$OUTPUT_FILE" << EOF
<div class="data-item"><strong>System Uptime:</strong> <span class="green">${UPTIME_STR}</span></div>
EOF

# Memory Usage
print_header "Memory Usage"
read total_memory available_memory <<< $(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
used_memory=$((total_memory - available_memory))
total_memory_gb=$(awk -v t=$total_memory 'BEGIN { printf("%.2f", t / 1048576) }')
used_memory_gb=$(awk -v u=$used_memory 'BEGIN { printf("%.2f", u / 1048576) }')
used_memory_percent=$(awk -v u=$used_memory -v t=$total_memory 'BEGIN { if (t > 0) printf("%.1f", (u / t) * 100); else print "0"; }')
cat >> "$OUTPUT_FILE" << EOF
<div class="data-grid">
    <div class="data-item"><strong>Total Memory:</strong> <span class="green">${total_memory_gb} GB</span></div>
    <div class="data-item"><strong>Used Memory:</strong> <span class="green">${used_memory_gb} GB (${used_memory_percent}%)</span></div>
</div>
EOF

# CPU Usage & Load
print_header "CPU Usage & Load"
cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/')
cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN { printf("%.1f", 100 - idle) }')
load_avg=$(cut -d' ' -f1,2,3 /proc/loadavg)
cat >> "$OUTPUT_FILE" << EOF
<div class="data-grid">
    <div class="data-item"><strong>Current Usage:</strong> <span class="green">${cpu_usage}%</span></div>
    <div class="data-item"><strong>Load Average (1, 5, 15m):</strong> <span class="green">${load_avg}</span></div>
</div>
EOF

# Disk Usage
print_header "Disk Usage"
cat >> "$OUTPUT_FILE" << EOF
<pre>
$(df -h --output=source,size,used,avail,pcent,target | grep -vE '^Filesystem|tmpfs|cdrom')
</pre>
EOF

# Top Processes by CPU
print_header "Top 5 Processes (by CPU)"
cat >> "$OUTPUT_FILE" << EOF
<pre>
<strong>COMMAND         %CPU</strong>
$(ps -eo comm,%cpu --sort=-%cpu | head -n 6 | tail -n 5)
</pre>
EOF

# Top Processes by Memory
print_header "Top 5 Processes (by Memory)"
cat >> "$OUTPUT_FILE" << EOF
<pre>
<strong>COMMAND         %MEM</strong>
$(ps -eo comm,%mem --sort=-%mem | head -n 6 | tail -n 5)
</pre>
EOF

# --- Finalize HTML ---
LAST_UPDATED=$(date)
cat >> "$OUTPUT_FILE" << EOF
        <div class="footer">
            <p>Report last updated on: ${LAST_UPDATED}</p>
        </div>
    </div>
</body>
</html>
EOF

# This message appears in the terminal when run manually
echo "Performance report saved to: ${OUTPUT_FILE}"
