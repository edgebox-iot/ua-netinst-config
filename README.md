# ua-netinst-config

A set of configurations for Edgebox base unattended install, to be used with [edgebox-iot/raspberrypi-ua-netinst](https://github.com/edgebox-iot/raspberrypi-ua-netinst)
This installer creates a image of all necessary firmware files and the base installer for the latest version of a stripped down version of Debian with the edgebox system installed inside it. 

## Requirements

- Intended for Edgebox Model 1 (Raspberry Pi 4B based), though it can be used with any Raspberry Pi (from model 1B up to 4B, 3A+, 3B+ or Zero including Zero W)
- SD card with at least 1GB, or at least 128MB for USB root install (without customization). We recommend at least 8GB for confortable operation.
- ethernet or wireless LAN with a working internet connection

### Features

- Configures an operating system through unnatended installer, you only need a working internet connection through the ethernet port or use the onboard wireless LAN (supported on model 3B, 3B+, 4B and 0W)
- DHCP and static IP configuration (DHCP is the default)
- always installs the latest version of Raspbian
- configurable default settings
- extra configuration over HTTP possible - gives unlimited flexibility
- installation takes about **20 minutes** with fast internet from power on to sshd running
- can fit on a 512MB SD card, but 1GB is more reasonable
- default installation includes `fake-hwclock` to save the current time at shutdown
- default installation includes NTP to keep time
- `/tmp` is mounted as tmpfs to improve speed
- no clutter included, you only get the bare essential packages
- option to install root to a USB drive
- Contains a script in ~/home/system to allows automatic setup of the Edgebox repositories

## Install instructions

### Formatting your SD card

- Format your SD card as **FAT32** (MS-DOS on _Mac OS X_) and extract the downloaded .zip file  directly into the SD Card.

  _Tip: When formatting the SD card we recommend using the SD Cards manufacturer tool (if it exists), or as a more general all-around tool, Gparted. When creating new partitions for SD cards it is recommended that the preceding  space of the partition is set to 4MB_

### Running the install script

![Installer](example.gif)

1. Run `make install`
2. Answer the required questions
3. After the installation is done, copy the contents of the "image" folder into the root of your SD card
4. Insert the SD card on your Edgebox and wait until the installation is done

### Installer customization

You can use the installer _as is_ and get a minimal system installed which you can then use and customize to your needs.

**All advanced configuration files and folders should be placed in `image/config` after running the installation script.**  
This is the configuration directory of the installer.

#### Unattended install settings

The primary way to customize the installation process is done through the file `config/installer-config.txt`.

If you want settings changed for your installation, you should **only** place that changed setting in the `config/installer-config.txt` file. So for example if you want to have vim and aptitude installed by default, edit the file with the following contents:

```
packages=vim,aptitude
```
That's it!

Here is another example for a _installer-config.txt_ file:

```
packages=nano
firmware_packages=1

timezone=America/New_York
keyboard_layout=us
system_default_locale=en_US

username=pi
userpw=login
userperms_admin=1
usergpu=1

rootpw=raspbian
root_ssh_pwlogin=0

gpu_mem=32
```

All possible parameters and their description, are documented in [docs/INSTALL_CUSTOM.md](/docs/INSTALL_CUSTOM.md).

#### Advanced customization

More advanced customization as providing files or executing own scripts is documented in [docs/INSTALL_ADVANCED.md](/docs/INSTALL_ADVANCED.md).

## Installing on Raspberry Pi

Under normal circumstances, you can just insert the SD card, power on your Edgebox and cross your fingers.

If you don't have a display attached, you can monitor the ethernet card LEDs to guess the activity status. When it finally reboots after installing everything you will see them illuminate on and off a few times when Raspbian configures on boot.

If the installation process fails, you will see **SOS** in Morse code (... --- ...) on an led.  In this case, power off the Pi and check the log on the sd card.

If you do have a display, you can follow the progress and catch any possible errors in the default configuration or your own modifications. Once a network connection has been established, the process can also be followed via telnet (port 23).

If you have a serial cable connected, installer output can be followed there, too. If 'console=tty1' at then end of the `cmdline.txt` file is removed, you have access to the console in case of problems.

## First boot

The system is almost completely unconfigured on first boot. Here are some tasks you most definitely want to do on first boot.  
Note, that this manual work can be done automatically during the installation process if the appropriate options in [`installer-config.txt`](#installer-customization)) are set.

Some sane defaults for Edgebox product development are pre-set, but you might want to tweak some of the parameters.

The default **root** password is **edgebox-root**.

- Set new root password: `passwd`
- Configure your default locale: `dpkg-reconfigure locales`
- Configure your keyboard layout: `dpkg-reconfigure keyboard-configuration`
- Configure your timezone: `dpkg-reconfigure tzdata`

Optional:  
Create a swap file with `dd if=/dev/zero of=/swap bs=1M count=512 && chmod 600 /swap && mkswap /swap` (example is 512MB) and enable it on boot by appending `/swap none swap sw 0 0` to `/etc/fstab`.  

## The edgebox setup script

Included after installation in `~/home/system/` is a basg script with the name `edgebox.sh`. This script can be ran after installation to setup the necessary components for a proper functioning Edgebox. It can be run anywhere in a terminal as it is pre-included in the PATH.

The recommendation is that after installation, you should run the setup script. The system is SSH accessible through `ssh system@edgebox`, using the password set on the `installer-config.txt` file.

The available commands are:

 - edgebox -s | --setup -> Setup script, configures GitHub SSH Key (if it exists), and downloads all repositories and starts all components. Project files are available at `~/home/system/components` >
 - edgebox -u | --update -> Pulls all newest commits form every repository in the project.

## GitHub Key Setup

When running the setup scirpt, it will try to find a private ssh key in `~/home/system/.ssh/` called `github_key`.

If it exists, it will automatically setup ssh to use this key when pulling repositories from GitHub, avoiding you having to insert credentials to clone / pull / push to repositories.

To learn how to properly generate a GitHub SSH key for using here, please refer to [GitHub's documentation on how to generate a new SSH key](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key). The step of "Adding your SSH key to the ssh-agent" is taken care by the setup command `edgebox -s`. So in steps, before copying the files to the SD card, do the following:

 - $ ssh-keygen -t ed25519 -C "your_email@example.com"
 - Press Enter 2 Times
 - mv github_* ~/[THIS REPO PATH]/files/root/home/system/.ssh/
 - Create the file ssh.list in ~/[THIS REPO PATH]/files/
 - Insert in the ssh.list file, the following 2 lines: 

        system:system 755 /home/system/.ssh/github_key
        system:system 755 /home/system/.ssh/github_key.pub
 - Make sure you've added the public key in your GitHub settings. [Check here how to do it](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account).

For easing development, the setup script also sets up [credential caching in Git for GitHub](https://docs.github.com/en/free-pro-team@latest/github/using-git/caching-your-github-credentials-in-git), which in the case of not using an SSH key setup, allows to insert your GitHub credentials only once on the command `edgebox -s`, for it to be able to download all the repositories necessary.

## Logging

The output of the installation process is logged to file.  
When the installation completes successfully, the logfile is placed in `/var/log/raspberrypi-ua-netinst.log` on the installed system.  
When an error occurs during install, the logfile is placed in the `raspberrypi-ua-netinst` folder and is named `error-\<datetimestamp\>.log`

## Reinstalling or replacing an existing system

If you want to reinstall with the same settings you did your first install you can just move the original _config.txt_ back and reboot.

```
mv /boot/raspberrypi-ua-netinst/reinstall/config.txt /boot/config.txt
reboot
```

**Remember to backup all your data and original `config.txt` before doing this!**