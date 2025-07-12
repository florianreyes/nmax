#!/usr/bin/env bash

# A quick NMAP script
# Author: Ch4rlieG4uss

if [ "$#" -gt 2 ]; then
    echo "[!] Usage: $0 [-v] <IP>"
    exit 1
fi

function ctrl-c {
    echo "[!] Aborting..."
    exit 1
}

# Catch ctrl-c
trap ctrl-c SIGINT SIGTERM

VERBOSE=false

while [[ "$1" =~ ^- ]]; do
	case "$1" in
		-v|--verbose)
			VERBOSE=true
			shift
			;;
	*)
		echo "[!] Unknown option: $1"
		exit 1
		;;
	esac
done

TARGET_IP="$1"

if [ -f "$TARGET_IP" ]; then
    echo "[!] Not implemented yet mate!"
    exit 1

elif [[ "$TARGET_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Input is an IP address: $TARGET_IP"
    # Validate each octet <= 255
    for octet in $(echo "$TARGET_IP" | tr '.' ' '); do
        if [ "$octet" -gt 255 ]; then
            echo "[!] Invalid IP address: Octet $octet is too large"
            exit 1
        fi
    done
	
	spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done
	}

    # Extract Port function
    extract_ports() {
        local input_file="$1"

        if [ ! -f "$input_file" ]; then
            echo "Error: File '$input_file' not found"
            return 1
        fi

        ports=$(grep -oP "(?<=Ports:).*" "$input_file" | tr "," "\n" | awk -F'/' '{print $1}' | tr -d ' ' | tr '\n' ',' | sed 's/,$//')

        echo "[*] Ports extracted: $ports"
        
        export ports
    }

	echo "[+] Launching nmap Syn portscan NO DNS - NO ICMP"
	filename_ss=${TARGET_IP//./}

	if $VERBOSE; then
		nmap -n -Pn --min-rate 5000 -p- -sS "$TARGET_IP" -oG "$(pwd)/${filename_ss}_full"
	else
		nmap -n -Pn --min-rate 5000 -p- -sS "$TARGET_IP" -oG "$(pwd)/${filename_ss}_full" > /dev/null 2>&1 &
		nmap_pid=$!
		spinner $nmap_pid
		wait $nmap_pid
	fi

	extract_ports "${filename_ss}_full"

	echo "[+] Launching nmap Depth on discovered ports - sCV"
	if $VERBOSE; then
		nmap -n -Pn -sCV -p"$ports" "$TARGET_IP" -oN "$(pwd)/${filename_ss}_depth"
	else
		nmap -n -Pn -sCV -p"$ports" "$TARGET_IP" -oN "$(pwd)/${filename_ss}_depth" > /dev/null 2>&1 &
		nmap_pid=$!
		spinner $nmap_pid
		wait $nmap_pid
	fi
	
	rm $(pwd)/${filename_ss}_full
	echo "[*] Created final Depth file in $(pwd)/${filename_ss}_depth"

else
    echo "[!] Invalid input, please enter a single IP or filename."
    exit 1
fi
