#!/bin/bash
# copy colours in .Xresources to kitty.conf

conf=~/.config/kitty/kitty.conf

sed -i '/# LINES WILL BE AUTOMATICALLY OVERWRITTEN/q' $conf

echo "" >> $conf

xrdb -query | grep ^* | cut -c 2- | sed 's/://' | sed -r 's/^cursorColor/cursor/' >> $conf
