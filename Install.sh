#!/bin/bash

# Check for Root
if [ $UID -ne 0 ]
then
 echo "Please run this script as root: sudo Installer.sh"
 exit 1
fi

# Disclaimer
if whiptail --yesno "We're about to configure your Raspberry Pi as a HoneyPot!" 20 60
then
    echo "Continuing"
else
    echo "Install terminated by user"
    exit 1
fi