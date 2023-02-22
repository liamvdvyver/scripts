#!/bin/env sh
# Connect to ANU VPN

usage="usage: gp [-d] [--disconnect]"

openconnect_proc="$(pgrep openconnect)"
homedrive_mount="$(mount -t cifs | grep 'homedrive\.anu\.edu\.au')"

if [ "$1" = "-d" ] || [ "$1" = "--disconnect" ]; then
    sudo killall openconnect &
    sudo umount -a -l -f -t cifs
elif [ "$1" ]; then
    echo $usage
else
    pass="$(pass anu/passwordless.anu.edu.au | head -n 1)"
    user="$(pass anu/passwordless.anu.edu.au | grep '^username:' | sed 's/^username: \(.*\)/\1'/)"
    if ! [ $openconnect_proc ]; then
        echo "$pass" | sudo openconnect --background --protocol=gp -u "$user" student-access.anu.edu.au --passwd-on-stdin &&
        gp
    elif ! [ "$homedrive_mount" ]; then
        # For some reason this line doesn't work after the &&, so call recursively
        # so the previous line is not run before this one
        # This is gross code but I am too lazy to fix this right now
        sudo mkdir -p /mnt/anu
        sudo mount -t cifs "//homedrive.anu.edu.au/users/$user" /mnt/anu -o "uid=1000,domain=UDS.anu.edu.au,username=$user,password=$pass"
        user_local="$(whoami)"
        sudo chown $user_local /mnt/anu
    fi
fi
