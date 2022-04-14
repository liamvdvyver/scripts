#!/bin/sh
# set Xresources and vim colours from positional arguments and update kitty and dunst configs from .Xresources
theme="$1"
vimtheme=$1$2

# set .Xresources theme

xres=~/.Xresources

sed -i "s/\(#define c[0-9]\{2\} \)[a-z]*\([0-9]\{2\}\)/\1$theme\2/" $xres
sed -i "s/\(#define \)\([a-z]\{2\}2\?\)\( *\)[a-z]*\2/\1\2\3$theme\2/g" $xres

xrdb $xres

# set vim colourscheme

vimconf=~/.config/nvim/init.vim

sed -i "s/\(colorscheme \).*/\1$vimtheme/" $vimconf

# copy colours in .Xresources to kitty.conf

kittyconf=~/.config/kitty/kitty.conf

sed -i "/# FOLLOWING LINES WILL BE AUTOMATICALLY OVERWRITTEN/q" $kittyconf

echo "" >> $kittyconf

xrdb -query | grep ^* | sed -E "/ground2:|accent/d" | cut -c 2- | sed "s/://" | sed -r "s/^cursorColor/cursor/" >> $kittyconf

# copy colours in .Xresources to dunstrc

dunstconf=~/.config/dunst/dunstrc

bg=$(xrdb -query | grep '^\*background:' | cut -f 2)
b2=$(xrdb -query | grep '^\*background2:' | cut -f 2)
fg=$(xrdb -query | grep '^\*foreground:' | cut -f 2)
ac=$(xrdb -query | grep '^\*accent:' | cut -f 2)

bgline="    background = \"$bg\""
b2line="    frame_color = \"$b2\""
fgline="    foreground = \"$fg\""
f2line="    frame_color = \"$fg\""
acline="    frame_color = \"$ac\""

echo "[urgency_low]" > $dunstconf
echo $bgline >> $dunstconf
echo $fgline >> $dunstconf
echo $b2line >> $dunstconf
echo "" >> $dunstconf
echo "[urgency_normal]" >> $dunstconf
echo $bgline >> $dunstconf
echo $fgline >> $dunstconf
echo $f2line >> $dunstconf
echo "" >> $dunstconf
echo "[urgency_critical]" >> $dunstconf
echo $bgline >> $dunstconf
echo $fgline >> $dunstconf
echo $acline >> $dunstconf
