#!/bin/bash

# Default values for the installer (when user selects no to override them)
DEFAULT_HOSTNAME="edgebox"
DEFAULT_TIMEZONE_COUNTRY_CODE="DE"
DEFAULT_KEYBOARD_LAYOUT_COUNTRY_CODE="de"
DEFAULT_LOCALE="en_US"
RECOMMENDED_RASPBERRYPI_UA_NETINST_RELEASE="v2.4.0_caf7423"

# Var helpers
EMPTY_LINE=""
GREEN='\033[0;32m'  # Green color escape code
NC='\033[0m'  # Reset color escape code
USER_INSTALLER_CONFIG_LOCATION=./image/config/installer-config.txt

# Print ASCII art using a here document
cat << "EOF"
                                                     
,------.   ,--.              ,--.                    
|  .---' ,-|  | ,---.  ,---. |  |-.  ,---.,--.  ,--. 
|  `--, ' .-. || .-. || .-. :| .-. '| .-. |\  `'  /  
|  `---.\ `-' |' '-' '\   --.| `-' |' '-' '/  /.  \  
`------' `---' .`-  /  `----' `---'  `---''--'  '--' 
               `---'                                 
EOF

# Print a message
echo "This process will ask you a couple of questions to setup..."
echo "Press [ENTER] to continue..."

# Wait for user input
read

# Ask for the root password
echo "Please enter the root password for the system:"
read -s root_password
echo $EMPTY_LINE

# Ask if root user should have SSH access
echo "Should the root user have SSH access? (y/n):"
read root_ssh
echo $EMPTY_LINE

# Validate if answer is y or n. If not, repeat
while [[ $root_ssh != "y" && $root_ssh != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read root_ssh
done

# Convert answer to 0 if n, 1 of y
if [[ $root_ssh == "n" ]]; then
    root_ssh=0
else
    root_ssh=1
fi

# Ask for the user password
echo "Please enter the password for the system user (sudo user):"
read -s user_password
echo $EMPTY_LINE

# Ask if user is going to use Wifi to connect to the network
echo "Will you use Wifi to connect to the network? (y/n):"
read wifi
echo $EMPTY_LINE

# Validate if answer is y or n. If not, repeat
while [[ $wifi != "y" && $wifi != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read wifi
done

# If user is going to use Wifi, ask for the SSID and password
if [[ $wifi == "y" ]]; then
    echo "Please enter the SSID of the network:"
    read ssid
    echo $EMPTY_LINE

    echo "Please enter the password of the network:"
    read -s wifi_password
    echo $EMPTY_LINE

    echo "Please enter the country code of the network (eg. DE, PT, ES, FR):"
    read wifi_country_code
    echo $EMPTY_LINE
fi

# As if user wants to introduce a custom timezone country code
echo "Do you want to introduce a custom timezone country code? (y/n):"
read custom_timezone
echo $EMPTY_LINE

# Validate if answer is y or n. If not, repeat
while [[ $custom_timezone != "y" && $custom_timezone != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read custom_timezone
done

# If user wants to introduce a custom timezone country code, ask for it
if [[ $custom_timezone == "y" ]]; then
    echo "Please enter the timezone country code (eg. DE, PT, ES, FR):"
    read timezone_country_code
    echo $EMPTY_LINE

    # Convert answer to uppercase
    timezone_country_code=$(echo $timezone_country_code | tr '[:lower:]' '[:upper:]')
else
    timezone_country_code=$DEFAULT_TIMEZONE_COUNTRY_CODE
fi

# Ask if the user wants to override keyboard layout country code
echo "Do you want to override the keyboard layout country code? (y/n):"
read override_keyboard_layout
echo $EMPTY_LINE

# Validate if answer is y or n. If not, repeat
while [[ $override_keyboard_layout != "y" && $override_keyboard_layout != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read override_keyboard_layout
done

# If user wants to override keyboard layout country code, ask for it
if [[ $override_keyboard_layout == "y" ]]; then
    echo "Please enter the keyboard layout country code (eg. us, de, pt, es):"
    read keyboard_layout_country_code
    echo $EMPTY_LINE
else
    keyboard_layout_country_code=$DEFAULT_KEYBOARD_LAYOUT_COUNTRY_CODE
fi

# Ask if user wants to override default locale
echo "Do you want to override the default locale? (y/n):"
read override_locale
echo $EMPTY_LINE

# Validate if answer is y or n. If not, repeat
while [[ $override_locale != "y" && $override_locale != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read override_locale
done

# If user wants to override default locale, ask for it
if [[ $override_locale == "y" ]]; then
    echo "Please enter the locale (eg. en_US, pt_PT, es_ES):"
    read locale
    echo $EMPTY_LINE
else
    locale=$DEFAULT_LOCALE
fi

# Ask if user wants to override the default hostname (edgebox)
echo "Do you want to override the default hostname (edgebox)? (y/n):"
read override_hostname
echo $EMPTY_LINE

# Validate if answer is y or n. If not, repeat
while [[ $override_hostname != "y" && $override_hostname != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read override_hostname
done

# If user wants to override the default hostname, ask for it
if [[ $override_hostname == "y" ]]; then
    echo "Please enter the desired hostname:"
    read hostname
    echo $EMPTY_LINE

else
    hostname=$DEFAULT_HOSTNAME
fi

# Ask if user wants to install a specific release of raspberrypi-ua-netinst
echo "Do you want to install a specific release of raspberrypi-ua-netinst? (y/n) [recommended: n]:"
read specific_release
echo $EMPTY_LINE


# Validate if answer is y or n. If not, repeat
while [[ $specific_release != "y" && $specific_release != "n" ]]; do
    echo $EMPTY_LINE
    echo "Please enter y or n"
    read specific_release
done

# If user wants to install a specific release of raspberrypi-ua-netinst, ask for it
if [[ $specific_release == "y" ]]; then
    echo "Please enter the release tag (eg. v2.4.0):"
    read release_tag
    echo $EMPTY_LINE

else
    release_tag=$RECOMMENDED_RASPBERRYPI_UA_NETINST_RELEASE
fi

# Print a thank you message
echo $EMPTY_LINE
echo -e "${GREEN}Thank you! The installer will now start preparing the image.${NC}"
echo $EMPTY_LINE

# Download the requested release from https://github.com/FooDeas/raspberrypi-ua-netinst/releases
echo "Downloading raspberrypi-ua-netinst..."
zip_url="https://github.com/FooDeas/raspberrypi-ua-netinst/archive/${release_tag}.zip"

# Download the release zip file, deleting a previous one if it exists, and delete the extracted folder if it exists too
rm -r ${release_tag}.zip
curl -L -o ${release_tag}.zip ${zip_url}

echo "Extracting raspberrypi-ua-netinst..."
# Extract the contents of the zip file (optional). First delete the folder if it exists
rm -rf raspberrypi-ua-netinst-${release_tag}
unzip ${release_tag}.zip

# Delete image folder and recreate it
rm -rf image
mkdir image

echo "Copying raspberrypi-ua-netinst files..."
# Copy the contents of the extracted folder to the "image" folder
# Note, release tag "v" char is not included in the folder name
extracted_release_tag=${release_tag:1}
cp -r ./raspberrypi-ua-netinst-${extracted_release_tag}/* image/

echo "Cleaning up..."
# Remove the zip file
rm ${release_tag}.zip
# Remove the extracted folder
rm -rf ./raspberrypi-ua-netinst-${extracted_release_tag}/

# Copy the contents of the "config" folder to the "image/raspberrypi-ua-netinst/config/" folder
cp -r ./config/* ./image/config/

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
    echo "wlan_ssid=${ssid}" >> $USER_INSTALLER_CONFIG_LOCATION
    echo "wlan_psk=${wifi_password}" >> $USER_INSTALLER_CONFIG_LOCATION
fi

# Print success message (in green font) and exit
echo -e "${GREEN}Configuration complete! Copy the contents on the 'image' folder into your SD card, turn your edgebox on, and wait around 25 minutes for the installation to complete!${NC}"