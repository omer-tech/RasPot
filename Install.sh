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
whiptail --msgbox "Installing log monitoring and network scan identification software \n" 20 60 5
apt-get -y install psad ssmtp python-twisted iptables-persistent libnotify-bin fwsnort # raspberrypi-kernel-headers (cannot find package)

# Choose notification option
OPTION=$(whiptail --menu "Choose how you want to get notified:" 20 60 5 "email" "Send me an email" "script" "Execute a script" 3>&2 2>&1 1>&3)
emailaddy=test@example.com
enablescript=N
externalscript=/bin/true
alertingmethod=ALL
check=1

case $OPTION in
	email)
		emailaddy=$(whiptail --inputbox "Ok, we're going to use a gmail address. If you do not gave a gmail address, create a burner gmail for this HoneyPot. What's your email address?" 20 60 3>&1 1>&2 2>&3)
		sed -i "s/xemailx/$emailaddy/g" ssmtp.conf
		cp ssmtp.conf /etc/ssmtp/ssmtp.conf
		check=30
		whiptail --msgbox "Now, make sure your gmail has two-factor authentication turned on and create an App Password (HOW TO: https://devanswers.co/create-application-specific-password-gmail/). Because we don't want to assign your password to any variables, you have to manually edit the smtp configuration file on the next screen. 'AuthUser' is the first part of your email address before the @. Save and exit the editor and I'll see you back here." 20 60
		pico /etc/ssmtp/ssmtp.conf
		whiptail --msgbox "Welcome back! Well Done! Here comes a test message to your email address, give it a few minutes" 20 60
		echo "test message from RasPot" | ssmtp -vvv $emailaddy
		if whiptail --yesno "Cool. Did a test message show up in your inbox? 'Yes' to continue or 'No' to exit and mess with your smtp config." 20 60
 		then
  			echo "Continue"
		else
			exit 1
 		fi
    
    ;;
	script)
		externalscript=$(whiptail --inputbox "Enter the full path and name of the script you would like to execute when an alert is triggered:" 20 60 3>&1 1>&2 2>&3)
		enablescript=Y
		alertingmethod=noemail
esac 

# Update configuration files with set variables
sed -i "s/xhostnamex/$sensitivename/g" psad.conf
sed -i "s/xemailx/$emailaddy/g" psad.conf
sed -i "s/xenablescriptx/$enablescript/g" psad.conf
sed -i "s/xalertingmethodx/$alertingmethod/g" psad.conf
sed -i "s=xexternalscriptx=$externalscript=g" psad.conf
sed -i "s/xcheckx/$check/g" psad.conf

# Wrap up everything and exit
whiptail --msgbox "Configuration files created. Next we will move those files to the right places." 20 60
mkdir /root/RasPot
cp blink*.* /root/RasPot
cp psad.conf /etc/psad/psad.conf
iptables --flush
iptables -A INPUT -p igmp -j DROP
iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG
service netfilter-persistent save
service netfilter-persistent restart
psad --sig-update
service psad restart
cp FakePorts.py /root/RasPot
(crontab -l 2>/dev/null; echo "@reboot python /root/RasPot FakePorts.py &") | crontab -
python /root/RasPot FakePorts.py &
ifconfig
printf "\n \n Now reboot and you should be good to go. Then, gportscan this RasPot and see if you get an alert!\n"