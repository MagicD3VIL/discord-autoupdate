# discord-autoupdate
Discord auto-update script for Linux systems using RPM packages, written in Lua.

* Script supports both the **Stable** and the **Canary** release of Discord.
* Supported RPM file managers are **urpmi** and **dnf**.

### Prerequisites
To run this script, you need to have these packages installed on your system:
* Discord
* Lua *(tested >=5.3)*
* DNF or URPMI
* wget
* alien

### Why?
On Linux, Discord requires you to download and install the whole package every time a major update is released. However, the only available package format is `.deb` or the compressed `.tar.gz` archive. There is no official `.rpm` package available.

Since I have switched to using the Canary version of the Discord client, I needed to download the package file even more frequently. Moreover, since the only available package format is `.deb`, I always had to run it through the `alien` utility to get the `.rpm` package format I needed.

This script automates all of the steps I had to previously take manually. I've also added this script to my system's Autostart settings, so the Discord gets automatically updated when I boot my computer.

### What does it do?
When you launch the script, it can detect a forced (major) Discord update. If no update is detected, the Discord will launch normally, and the script finishes. However, if an update is found, the script will take the following steps: 

1. The script will automatically download the updated `.deb` package. 
2. Then the script will send the downloaded `.deb` package to the `alien` utility to re-package it as a `.rpm` package *(this will most probably require elevated permissions or a sudo password)*. 
3. After the conversion finishes, the script will call the selected package manager to install the updated Discord package *(elevated permissions or sudo password required)*. 
4. The script will clean up and delete the temporary rpm package files created by the `alien`.
5. Discord will be launched in the background in a detached session so the script can finish. 

### Settings
At the top of the script, you can change the following variables to change the script settings:
* **app_name** => Supported values are `'discord'` or `'discord-canary'`
* **package_manager** => Supported values are `'urpmi'` or `'dnf'`

### Contributing
If you find a problem or a way to improve this script, feel free to submit an issue or a pull request, respectively.
