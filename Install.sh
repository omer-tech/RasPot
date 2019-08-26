#!/bin/bash

# Check for Root
if [ $UID -ne 0 ]
then
 echo "Please run this script as root: sudo Installer.sh"
 exit 1
fi

# Disclaimer
if whiptail --yesno "We're about to configure your Raspberry Pi as a HoneyPot! This install process will change some vital configurations on your Pi. We recommend only using this Pi as a HoneyPot, and not for other uses." 20 60
then
    echo "Continue"
else
    echo "Install terminated by user"
    exit 1
fi

# Change Password prompt if password is default
if [ $SUDO_USER == 'pi' ]
then
    if whiptail --yesno "Would you like to change your password? If you still have your default password, we highly recommend this." 20 60
    then 
     passwd 
    else
     echo "Continue"
    fi
fi

if whiptail --yesno "Let's install some updates. If you're just experimenting and want to skip this, press no." 20 60
then
    apt-get update
    apt-get dist-upgrade
else
    echo "Continuing without updates"
fi

# Name the host something enticing
sensitivename=$(whiptail --inputbox "Name your Pi/VM something sensitive, but not too obvious. Something like "FileServer01" Keep it short and without symbols or special chracters" 20 60 3>&1 1>&2 2>&3)
echo $sensitivename > /etc/hostname
echo "127.0.0.1 $sensitivename" >> /etc/hosts

# Install PSAD
whiptail --infobox "Installing log monitoring and network scan identification software \n"
apt-get -y install psad ssmtp python-twisted iptables-persistent libnotify-bin fwsnort # raspberrypi-kernel-headers (cannot find package)

# Choose notification option



