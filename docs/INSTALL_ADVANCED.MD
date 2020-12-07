## Installer customization

### Configuration file locations

Configuration files have to be placed as follows:

| File(s) | Description |
|-----------------------------------------------------------------|---------------------------------|
| `/installer-config.txt` | General installer configuration |
| `/post-install.txt` | Post installation script |
| `/wpa_supplicant.conf` | WiFi configuration file |
| `/files/<listname>.list` | List(s) of additional files |
| `/files/root/[folder/][filename]` | Listed additional files |

### Bring your own files

If you want to provide files to the installed system during the installation, place them in the `files/root` directory. The folder `root` is the root-point. It must have the same structure as inside the installed system.  
So, a file that you place on the SD card in `root/etc/my_folder/my_file.conf` will end up on the installed system as `/etc/my_folder/my_file.conf`.
Each file or directory that you wish to place on the target system must also be listed in a configuration file in the directory `files`. This allows you to specify the owner (and group) and the permissions of the file. An example file is provided with the installer (see [ref: ../files/custom_files.txt](../files/custom_files.txt) for more information). ONLY files listed there are copied over to the installed system.

Please be aware that some restrictions may apply to the sum of the file sizes. If you wish to supply large files in this manner you may need to adjust the value of the `bootsize` parameter.

### Post installer script

You can provide a _post-install.txt_ file that is executed at the very end of the installation process and you can use it to tweak and finalize your automatic installation.
