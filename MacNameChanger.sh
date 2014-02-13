#!/bin/sh

# Script to automate the name change of a UAL mac

# Based on the work of Andrina Kelly
# https://github.com/andrina/JNUC2013/blob/master/Users%20Do%20Your%20Job/ChangeComputerName.sh

# Author  : r.purves@arts.ac.uk
# Version : 1.0 - 26-11-2013 - Initial Version

# Set variables here

CD="/private/tmp/CocoaDialog.app/Contents/MacOS/CocoaDialog"

# Dialog to enter the computer name and the create $COMPUTERNAME variable
rv=($($CD standard-inputbox --title "Computer Name" --no-newline --informative-text "Enter the new name of the computer. e.g. M-A1234"))
COMPUTERNAME=${rv[1]}

# Dialog to show a please wait box while we work ...
rm -f /private/tmp/hpipe
mkfifo /private/tmp/hpipe

$CD progressbar --indeterminate --title "Renaming Computer" --width 250 --height 80 < /tmp/hpipe &

exec 3<> /tmp/hpipe
echo -n . >&3

# Unbind from AD here
dsconfigad -force -remove -username *replace* -password *replace*

# Set Hostname using variable created above
scutil --set HostName $COMPUTERNAME
scutil --set LocalHostName $COMPUTERNAME
scutil --set ComputerName $COMPUTERNAME

# Rebind to UAL AD here
jamf bind -type ad \
     -domain ?.? \
     -username *replace* \
     -password *replace* \
     -ou "OU=Mac,OU=?,OU=?,OU=?,DC=*replace*,DC=*replace*" \
     -cache \
     -localHomes \
     -useUNCPath \
     -mountStyle SMB \
     -defaultShell /bin/bash \
     -adminGroups "domain admins,enterprise admins,domain\group"

# All done, clean up after ourselves.

exec 3>&-
wait
rm -f /private/tmp/hpipe
    
# Dialog to confirm that the hostname was changed and what it was changed to.
tb=`$CD ok-msgbox --text "Computer Name Changed!" \
--informative-text "The computer name has been changed to $COMPUTERNAME" \
--no-newline --float`
if [ "$tb" == "1" ]; then
echo "Computer name changed"
elif [ "$tb" == "2" ]; then
echo "Canceling"
fi

# All done!

exit 0