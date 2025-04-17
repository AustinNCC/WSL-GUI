#!/bin/bash
#
# KaliDash - A GUI Dashboard for Kali Linux
# Author: AustinNCC
# Created: 16 April 2025
# Last Updated: 17 April 2025
# Version: 1.0.1
# Created for Kali Linux 2025.1 on WSL2

# Description: This script provides a graphical dashboard for managing and monitoring Kali Linux.
# It includes system information, network information, application launcher, service manager, and more.

# Usage: Run this script in a terminal with GUI support (like xterm) on Kali Linux.
# Note: This script is intended for educational purposes only. It is not responsible for any misuse or damage caused by its use.

# This script is provided "as is" without warranty of any kind. Use at your own risk.
# Dependencies: zenity, yad, xterm, htop, neofetch, inxi, bmon, nmap, metasploit-framework


# Check for required packages and install if needed
REQUIRED_PACKAGES=("zenity" "yad" "xterm" "htop" "neofetch" "inxi" "bmon" "nmap" "metasploit-framework")

echo "Checking required packages..."
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "ii  $pkg"; then
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg" || echo "Failed to install $pkg"
    fi
done

# Create temporary directory
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/kalidash.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Error function
error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    zenity --error --title="KaliDash Error" --text="$1" --width=300
}

# Success function
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Get system information
get_system_info() {
    {
        echo "<b>System Information:</b>"
        echo ""
        inxi -Fxxxza 2>/dev/null || neofetch
        echo ""
        echo "<b>Disk Usage:</b>"
        echo ""
        df -h | grep -v "loop" | awk '{print $1 " - " $2 " total, " $3 " used, " $4 " free (" $5 " used)"}'
        echo ""
        echo "<b>Memory Usage:</b>"
        echo ""
        free -h | awk '/^Mem:/ {print "Total: " $2 "   Used: " $3 "   Free: " $4 "   Buff/Cache: " $5}'
        echo ""
        echo "<b>Running Services:</b>"
        echo ""
        systemctl list-units --type=service --state=running | grep -v "loaded units listed" | head -20
    } > "$TEMP_DIR/sysinfo.txt"
    
    yad --text-info --filename="$TEMP_DIR/sysinfo.txt" --title="Kali Linux System Information" \
        --width=700 --height=500 --center --button="Close":0 --fontname="Monospace 10" --wrap \
        --text="<b>System Information for Kali Linux</b>" --html
}

# Network Information
get_network_info() {
    {
        echo "<b>Network Interfaces:</b>"
        echo ""
        ip -c a
        echo ""
        echo "<b>Routing Table:</b>"
        echo ""
        ip route
        echo ""
        echo "<b>Open Ports (Quick Scan):</b>"
        echo ""
        ss -tuln | grep LISTEN
    } > "$TEMP_DIR/netinfo.txt"
    
    yad --text-info --filename="$TEMP_DIR/netinfo.txt" --title="Network Information" \
        --width=700 --height=500 --center --button="Close":0 --fontname="Monospace 10" \
        --text="<b>Network Information for Kali Linux</b>" --html
}

# Monitor System in Real-time
monitor_system() {
    xterm -title "System Monitor - htop" -geometry 100x40 -e "htop" &
}

# Monitor Network in Real-time
monitor_network() {
    xterm -title "Network Monitor - bmon" -geometry 100x40 -e "bmon" &
}

# Application launcher
launch_application() {
    local app_choice=$(zenity --list --title="Launch Application" --column="Category" --column="Application" --column="Description" \
        "Information Gathering" "nmap" "Network scanner" \
        "Information Gathering" "maltego" "Graphical link analyzer" \
        "Information Gathering" "recon-ng" "Web reconnaissance framework" \
        "Vulnerability Analysis" "nikto" "Web server scanner" \
        "Vulnerability Analysis" "nessus" "Vulnerability scanner" \
        "Vulnerability Analysis" "sqlmap" "SQL injection tool" \
        "Web Application Analysis" "burpsuite" "Web vulnerability scanner" \
        "Web Application Analysis" "zaproxy" "OWASP ZAP" \
        "Database Assessment" "sqlmap" "SQL injection tool" \
        "Password Attacks" "hydra" "Password cracker" \
        "Password Attacks" "john" "John the Ripper" \
        "Password Attacks" "hashcat" "Advanced password recovery" \
        "Wireless Attacks" "aircrack-ng" "Wireless security tool" \
        "Wireless Attacks" "wifite" "Automated wireless auditor" \
        "Exploitation Tools" "metasploit" "Metasploit Framework" \
        "Exploitation Tools" "set" "Social-Engineer Toolkit" \
        "Sniffing & Spoofing" "wireshark" "Network protocol analyzer" \
        "Sniffing & Spoofing" "ettercap" "Man-in-the-middle attacks" \
        "Post Exploitation" "empire" "Post-exploitation framework" \
        "Post Exploitation" "meterpreter" "Metasploit payload" \
        "Forensics" "autopsy" "Digital forensics platform" \
        "Forensics" "foremost" "File recovery" \
        "Reverse Engineering" "ghidra" "Software reverse engineering" \
        "Reverse Engineering" "radare2" "Disassembler and debugger" \
        "System Tools" "terminal" "Terminal emulator" \
        "System Tools" "browser" "Web browser" \
        "System Tools" "filemanager" "File manager" \
        --width=800 --height=600)
    
    if [[ -z "$app_choice" ]]; then
        return
    fi
    
    # Extract the application name (second column)
    local app=$(echo "$app_choice" | awk -F'|' '{print $2}')
    
    case "$app" in
        "nmap")
            xterm -title "nmap" -geometry 100x30 -e "sudo nmap -v -A localhost && echo 'Press ENTER to close' && read" &
            ;;
        "terminal")
            xterm -geometry 100x30 &
            ;;
        "browser")
            firefox &
            ;;
        "filemanager")
            thunar &
            ;;
        "metasploit")
            xterm -title "Metasploit Framework" -geometry 120x40 -e "sudo msfconsole" &
            ;;
        "wireshark")
            sudo wireshark &
            ;;
        *)
            # Generic launcher for other applications
            if command -v "$app" >/dev/null 2>&1; then
                xterm -title "$app" -geometry 100x30 -e "sudo $app && echo 'Press ENTER to close' && read" &
            else
                error "Application '$app' not found or not installed."
            fi
            ;;
    esac
}

# Service manager
manage_services() {
    # Get list of services
    services=$(systemctl list-units --type=service --all | grep '\.service' | awk '{print $1}' | sort)
    
    # Create a file with service status
    local services_file="$TEMP_DIR/services.txt"
    echo "" > "$services_file"
    
    for service in $services; do
        status=$(systemctl is-active "$service")
        if [[ "$status" == "active" ]]; then
            echo "$service|Running|Stop" >> "$services_file"
        else
            echo "$service|Stopped|Start" >> "$services_file"
        fi
    done
    
    # Display service manager
    local selection=$(yad --list --title="Service Manager" --text="<b>Manage Kali Linux Services</b>" \
        --column="Service" --column="Status" --column="Action" \
        --button="Refresh:2" --button="Close:1" \
        --width=700 --height=500 --center \
        $(cat "$services_file"))
    
    local ret=$?
    
    if [[ $ret -eq 2 ]]; then
        # Refresh button pressed
        manage_services
        return
    elif [[ $ret -eq 1 ]]; then
        # Close button pressed
        return
    fi
    
    # Extract selected service and action
    local selected_service=$(echo "$selection" | cut -d'|' -f1)
    local action=$(echo "$selection" | cut -d'|' -f3)
    
    if [[ -z "$selected_service" ]]; then
        return
    fi
    
    # Perform action
    if [[ "$action" == "Start" ]]; then
        sudo systemctl start "$selected_service" && \
        success "Started $selected_service" || \
        error "Failed to start $selected_service"
    elif [[ "$action" == "Stop" ]]; then
        sudo systemctl stop "$selected_service" && \
        success "Stopped $selected_service" || \
        error "Failed to stop $selected_service"
    fi
    
    # Refresh the service manager
    manage_services
}

# Run a custom command
run_custom_command() {
    local command=$(zenity --entry --title="Run Custom Command" --text="Enter the command to run:" --width=400)
    
    if [[ -z "$command" ]]; then
        return
    fi
    
    xterm -title "Custom Command: $command" -geometry 100x30 -e "sudo $command; echo 'Press ENTER to close'; read" &
}

# Main menu
main_menu() {
    while true; do
        local choice=$(yad --list --title="KaliDash - Kali Linux Dashboard" \
            --text="<b>Welcome to KaliDash</b>\nUser: XXXXX | Kali Linux 2025.1" \
            --column="Action" --column="Description" \
            "System Information" "View detailed system information" \
            "Network Information" "View network interfaces and connections" \
            "Monitor System" "Monitor system resources in real-time" \
            "Monitor Network" "Monitor network activity in real-time" \
            "Launch Application" "Launch Kali Linux applications" \
            "Manage Services" "Start/stop system services" \
            "Run Custom Command" "Run a custom command with sudo" \
            "Exit" "Exit KaliDash" \
            --width=600 --height=400 --center --button="Select:0")
        
        # Check if user closed the window
        if [[ $? -ne 0 ]]; then
            break
        fi
        
        # Extract the action (first column)
        local action=$(echo "$choice" | cut -d'|' -f1)
        
        case "$action" in
            "System Information")
                get_system_info
                ;;
            "Network Information")
                get_network_info
                ;;
            "Monitor System")
                monitor_system
                ;;
            "Monitor Network")
                monitor_network
                ;;
            "Launch Application")
                launch_application
                ;;
            "Manage Services")
                manage_services
                ;;
            "Run Custom Command")
                run_custom_command
                ;;
            "Exit")
                break
                ;;
            *)
                # Handle window close or empty selection
                break
                ;;
        esac
    done
}

# Check if running in WSL
if grep -qi microsoft /proc/version; then
    log "Running in WSL environment"
    
    # Check if X server is available
    if ! xset q &>/dev/null; then
        error "No X server detected. Make sure an X server (like VcXsrv, Xming) is running on Windows and DISPLAY is set."
        echo "You may need to:"
        echo "1. Install an X server on Windows (VcXsrv recommended)"
        echo "2. Start the X server"
        echo "3. Set the DISPLAY variable: export DISPLAY=:0"
        exit 1
    fi
fi

# Start the dashboard
log "Starting KaliDash..."
main_menu

# Cleanup
rm -rf "$TEMP_DIR"
log "KaliDash closed. Temporary files cleaned up."
exit 0
