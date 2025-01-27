#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 -u <domain> [--output <file>]"
    echo ""
    echo "Options:"
    echo "  -u <domain>        Specify the domain for which to search subdomains (do not include http or https)."
    echo "  --output <file>    Save the subdomains and httpx output to a specified file."
    echo "  -h                 Show this help message."
    exit 0
}

# Function to display the logo at the start
show_logo() {
    echo -e "\e[31m" # Set the color to red
    echo "   _____       _      _____          _       "
    echo "  / ____|     | |    / ____|        | |      "
    echo " | (___  _   _| |__ | |     ___ _ __| |_ ___ "
    echo "  \___ \| | | | '_ \| |    / _ \ '__| __/ __|"
    echo "  ____) | |_| | |_) | |___|  __/ |  | |_\__ \\"
    echo " |_____/ \__,_|_.__/ \_____\___|_|   \__|___/"
    echo -e "\e[0m" # Reset the color
    echo "         SubCerts - created by 0xJin"
}

# Loading animation
loading_animation() {
    chars="/-\|"
    start_time=$(date +%s)
    while :; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -ne "\r\e[31m[*]\e[0m \e[32mSearching for subdomains...\e[0m ${chars:$i:1}"
            sleep 0.1
            elapsed_time=$(( $(date +%s) - start_time ))
            if [ "$elapsed_time" -ge 60 ]; then
                echo -ne "\n\e[31m[*]\e[0m \e[33mThis might take a few minutes. Please wait...\e[0m\n"
                start_time=$(date +%s)
            fi
        done
    done
}

# Function to start the animation
start_loading() {
    loading_animation & 
    spinner_pid=$!
    disown
}

# Function to stop the loading animation
stop_loading() {
    kill "$spinner_pid" 2>/dev/null
    printf "\r%-50s\n" " "  # Clear animation line
}

# Cleanup function
cleanup() {
    stop_loading
    exit 1
}
trap cleanup SIGINT

# Variable for output file
output_file=""

# Check if no arguments were passed
if [ "$#" -eq 0 ]; then
    show_help
fi

# Parsing the options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u)
            domain="$2"
            shift 2
            ;;
        --output)
            output_file="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1" 1>&2
            show_help
            ;;
    esac
done

# Display the logo at the start
show_logo

# Start the loading animation
start_loading

# Check if the domain was provided
if [ -z "$domain" ]; then
    echo "Error: You must specify a domain with the -u option."
    stop_loading
    show_help
fi

# Function to extract subdomains from crt.sh
extract_subdomains() {
    crtsh_url="https://crt.sh/?q=%25.$domain&output=json"
    
    # Check dependencies
    if ! command -v curl &>/dev/null || ! command -v jq &>/dev/null; then
        echo "Error: Install 'curl' and 'jq' to run this script."
        exit 1
    fi

    # Fetch data with error handling
    response=$(curl -f -s "$crtsh_url" 2>&1)
    if [ $? -ne 0 ]; then
        echo "Error: Connection to crt.sh failed. Check your network or the domain."
        echo "Debug: $response"
        exit 1
    fi

    # Validate JSON
    if ! echo "$response" | jq -e '.' >/dev/null 2>&1; then
        echo "Error: crt.sh returned invalid JSON. Response received:"
        echo "$response"
        exit 1
    fi

    # Extract and filter subdomains
    subdomains=$(echo "$response" | jq -r '.[].name_value' | grep -v "@" | sed 's/^\*\.//g' | sort -u)
    filtered_subdomains=$(echo "$subdomains" | grep -E "\.?${domain}$" | awk '!seen[$0]++')

    echo "$filtered_subdomains"
}

# Function to run httpx
run_httpx() {
    subdomains="$1"
    [ -z "$subdomains" ] && return

    if ! command -v httpx &>/dev/null; then
        echo "Error: Install 'httpx' to get live subdomains."
        return
    fi

    echo "$subdomains" | httpx -status-code -title -silent 2>>error.log
}

# Main execution
subdomains=$(extract_subdomains)
stop_loading

# Print results
echo -e "\n[*] Subdomains found:"
[ -n "$subdomains" ] && echo "$subdomains" || echo "No subdomains found."

echo -e "\n[*] httpx Results:"
httpx_results=$(run_httpx "$subdomains")
[ -n "$httpx_results" ] && echo "$httpx_results" || echo "No live subdomains detected."

# Save results if specified
if [ -n "$output_file" ]; then
    {
        echo "[*] Subdomains found:"
        echo "$subdomains"
        echo -e "\n[*] httpx Results:"
        echo "$httpx_results"
    } > "$output_file"
    echo "[*] Results saved to $output_file"
fi
