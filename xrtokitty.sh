#!/bin/bash
# copy colours in .Xresources to kitty.conf

conf=~/.config/kitty/kitty.conf


figlet kitty.conf | sed -e 's/^/# /' > $conf

echo "" >> $conf

xrdb -query | grep ^* | cut -c 2- | sed 's/://' | sed -r 's/^cursorColor/cursor/' >> $conf

echo "" >> $conf

echo "enable_audio_bell no" >> $conf
