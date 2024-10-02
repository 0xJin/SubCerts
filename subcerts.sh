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
    start_time=$(date +%s) # Record the start time
    while :; do
        for (( i=0; i<${#chars}; i++ )); do
            # Display the animation and elapsed time
            echo -ne "\r\e[31m[*]\e[0m \e[32mSearching for subdomains...\e[0m ${chars:$i:1}"
            sleep 0.1

            # After 60 seconds, display a waiting message
            elapsed_time=$(( $(date +%s) - start_time ))
            if [ "$elapsed_time" -ge 60 ]; then
                echo -ne "\n\e[31m[*]\e[0m \e[33mThis might take a few minutes. Please wait...\e[0m\n"
                # Reset the timer to prevent continuous message display
                start_time=$(date +%s)
            fi
        done
    done
}

# Function to start the animation in the background
start_loading() {
    loading_animation &
    spinner_pid=$!
}

# Function to stop the loading animation
stop_loading() {
    kill "$spinner_pid" &> /dev/null
    wait "$spinner_pid" 2>/dev/null
}

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

# Start the loading animation immediately
start_loading

# Check if the domain was provided
if [ -z "$domain" ]; then
    echo "Error: You must specify a domain with the -u option."
    stop_loading
    show_help
fi

# Function to extract subdomains from crt.sh and filter to only include valid subdomains
extract_subdomains() {
    crtsh_url="https://crt.sh/?q=%25.$domain&output=json"
    # Fetch subdomains, exclude lines with '@', and log any errors
    subdomains=$(curl -s "$crtsh_url" | jq -r '.[].name_value' | grep -v "@" | sort -u 2>error.log)

    # Filter the subdomains to include only those matching the target domain
    filtered_subdomains=$(echo "$subdomains" | grep "\.${domain}$")

    echo "$filtered_subdomains"
}

# Function to run httpx on the extracted subdomains
run_httpx() {
    subdomains="$1"
    # Run httpx, logging errors
    httpx_results=$(echo "$subdomains" | httpx -status-code -title -silent 2>>error.log)
    echo "$httpx_results"
}

# Extract subdomains and run httpx
subdomains=$(extract_subdomains)
httpx_results=$(run_httpx "$subdomains")

# Stop the loading animation once done
stop_loading

# Print both subdomains and httpx results at the end
echo -e "\n[*] Subdomains found:"
echo "$subdomains"

echo -e "\n[*] httpx Results:"
echo "$httpx_results"

# Save subdomains and httpx results to the output file if specified
if [ -n "$output_file" ]; then
    echo "$subdomains" > "$output_file"
    echo "$httpx_results" >> "$output_file"
    echo "[*] Results saved to $output_file"
fi
