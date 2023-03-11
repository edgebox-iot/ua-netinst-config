#!/bin/bash
set -euo pipefail
cat << "EOF"
                                                     
,------.   ,--.              ,--.                    
|  .---' ,-|  | ,---.  ,---. |  |-.  ,---.,--.  ,--. 
|  `--, ' .-. || .-. || .-. :| .-. '| .-. |\  `'  /  
|  `---.\ `-' |' '-' '\   --.| `-' |' '-' '/  /.  \  
`------' `---' .`-  /  `----' `---'  `---''--'  '--' 
               `---'                                 
EOF

# Default Values
DEFAULT_HOSTNAME="edgebox"
DEFAULT_TIMEZONE_COUNTRY_CODE="DE"
DEFAULT_KEYBOARD_LAYOUT_COUNTRY_CODE="de"
DEFAULT_LOCALE="en_US"
RASPBERRYPI_UA_NETINST_RELEASE="v2.4.0_caf7423"
RASPBERRYPI_UA_NETINST_RELEASE_URL="https://github.com/FooDeas/raspberrypi-ua-netinst/releases/download/v2.4.0_caf7423/raspberrypi-ua-netinst-git-caf7423.zip"

# Color Escape Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# File Paths
USER_INSTALLER_CONFIG_LOCATION=./image/raspberrypi-ua-netinst/config/installer-config.txt

# Functions
function print_success {
    # Prints a message in green
    echo -e "${GREEN}$1${NC}"
}

function print_error {
    # Print a message in red
    echo -e "${RED}$1${NC}"
}

function print_warning {
    # Prints a message in yellow
    echo -e "${YELLOW}$1${NC}"
}

function print_question {
    # Prints a message in blue
    echo -e "${BLUE}$1${NC}"
}

function get_yes_or_no() {
    # Ask for a yes or no answer
    # Keep attempting to read until a valid answer is given
    local response
    read response
    while [[ ! $response =~ ^[yn]$ ]]; do
        echo "Please enter y or n"
        read response
    done
    echo $response
}

# Print a message
echo "This process will ask you a couple of questions to setup..."
echo "Press [ENTER] to continue..."

# Wait for user input
read

# Ask for the root password
print_question "Type the root password for the system:"
read -s root_password
echo

# Ask if root user should have SSH access
print_question "Should the root user have SSH access? (y/n):"
root_ssh=$(get_yes_or_no)
echo


# Convert answer to 0 if n, 1 of y
if [[ $root_ssh == "n" ]]; then
    root_ssh=0
else
    root_ssh=1
fi

# Ask for the user password
print_question "Please enter the password for the system user (sudo user):"
read -s user_password
echo

# Ask if user is going to use Wifi to connect to the network
print_question "Will you use Wifi to connect to the network? (y/n):"
wifi=$(get_yes_or_no)
echo

# If user is going to use Wifi, ask for the SSID and password
if [[ $wifi == "y" ]]; then
    print_question "Type the SSID of the network:"
    read ssid
    echo

    print_question "Type the password of the network:"
    read -s wifi_password
    echo

    print_question "Type the country code of the network (eg. DE, PT, ES, FR):"
    read wifi_country_code
    echo
fi

# As if user wants to introduce a custom timezone country code
print_question "Override the default timezone country code \"$DEFAULT_TIMEZONE_COUNTRY_CODE\"? (y/n):"
custom_timezone=$(get_yes_or_no)
echo

# If user wants to introduce a custom timezone country code, ask for it
if [[ $custom_timezone == "y" ]]; then
    print_question "Type the timezone country code (eg. DE, PT, ES, FR):"
    read timezone_country_code
    echo

    # Convert answer to uppercase
    timezone_country_code=$(echo $timezone_country_code | tr '[:lower:]' '[:upper:]')
else
    timezone_country_code=$DEFAULT_TIMEZONE_COUNTRY_CODE
fi

# Ask if the user wants to override keyboard layout country code
print_question "Override the default keyboard layout country code \"$DEFAULT_KEYBOARD_LAYOUT_COUNTRY_CODE\"? (y/n) :"
override_keyboard_layout=$(get_yes_or_no)
echo

# If user wants to override keyboard layout country code, ask for it
if [[ $override_keyboard_layout == "y" ]]; then
    print_question "Type the keyboard layout country code (eg. us, de, pt, es):"
    read keyboard_layout_country_code
    echo
else
    keyboard_layout_country_code=$DEFAULT_KEYBOARD_LAYOUT_COUNTRY_CODE
fi

# Ask if user wants to override default locale
print_question "Override the default locale \"$DEFAULT_LOCALE\"? (y/n):"
override_locale=$(get_yes_or_no)
echo

# If user wants to override default locale, ask for it
if [[ $override_locale == "y" ]]; then
    print_question "Type the locale (eg. en_US, pt_PT, es_ES):"
    read locale
    echo
else
    locale=$DEFAULT_LOCALE
fi

# Ask if user wants to override the default hostname (edgebox)
print_question "Override the default hostname ($DEFAULT_HOSTNAME)? (y/n):"
override_hostname=$(get_yes_or_no)
echo

# If user wants to override the default hostname, ask for it
if [[ $override_hostname == "y" ]]; then
    print_question "Type the desired hostname:"
    read hostname
    echo

else
    hostname=$DEFAULT_HOSTNAME
fi

# Print a thank you message
echo
print_success "Thank you! The system will now be configured..."
echo

# Download the requested release from https://github.com/FooDeas/raspberrypi-ua-netinst/releases
print_warning "Downloading raspberrypi-ua-netinst..."

# Download the release zip file, deleting a previous one if it exists, and delete the extracted folder if it exists too
rm -rf ${RASPBERRYPI_UA_NETINST_RELEASE}.zip
curl -L -o ${RASPBERRYPI_UA_NETINST_RELEASE}.zip ${RASPBERRYPI_UA_NETINST_RELEASE_URL}

print_warning "Extracting raspberrypi-ua-netinst..."
# Extract the contents of the zip file (optional). First delete the folder if it exists
rm -rf raspberrypi-ua-netinst-${RASPBERRYPI_UA_NETINST_RELEASE}
unzip -d raspberrypi-ua-netinst-${RASPBERRYPI_UA_NETINST_RELEASE} ${RASPBERRYPI_UA_NETINST_RELEASE}.zip

# Delete image folder and recreate it
rm -rf image
mkdir image

print_warning "Copying raspberrypi-ua-netinst files..."
# Copy the contents of the extracted folder to the "image" folder
cp -r ./raspberrypi-ua-netinst-${RASPBERRYPI_UA_NETINST_RELEASE}/* image/

print_warning "Cleaning up..."
# Remove the zip file
rm ${RASPBERRYPI_UA_NETINST_RELEASE}.zip
# Remove the extracted folder
rm -rf ./raspberrypi-ua-netinst-${RASPBERRYPI_UA_NETINST_RELEASE}/

# Copy the contents of the "config" folder to the "image/raspberrypi-ua-netinst/config/" folder
cp -r ./config/* ./image/raspberrypi-ua-netinst/config/

# Append the introduced user settings to installer-config.txt
echo "rootpw=${root_password}" >> $USER_INSTALLER_CONFIG_LOCATION
echo "userpw=${user_password}" >> $USER_INSTALLER_CONFIG_LOCATION
echo "hostname=${hostname}" >> $USER_INSTALLER_CONFIG_LOCATION
echo "timezone=${timezone_country_code}" >> $USER_INSTALLER_CONFIG_LOCATION
echo "keyboard_layout=${keyboard_layout_country_code}" >> $USER_INSTALLER_CONFIG_LOCATION
echo "system_default_locale=${locale}" >> $USER_INSTALLER_CONFIG_LOCATION
echo "root_ssh_pwlogin=${root_ssh}" >> $USER_INSTALLER_CONFIG_LOCATION

# If user is going to use Wifi, append the settings to installer-config.txt
if [[ $wifi == "y" ]]; then
    echo "ifname=wlan0" >> $USER_INSTALLER_CONFIG_LOCATION
    echo "wlan_country=${wifi_country_code}" >> $USER_INSTALLER_CONFIG_LOCATION
    echo "wlan_ssid='${ssid}'" >> $USER_INSTALLER_CONFIG_LOCATION
    echo "wlan_psk=${wifi_password}" >> $USER_INSTALLER_CONFIG_LOCATION
fi

# Print success message (in green font) and exit
print_success "Configuration complete! Copy the contents on the 'image' folder into your SD card, turn your edgebox on, and wait around 25 minutes for the installation to complete!"