#!/bin/bash
# copy colours in .Xresources to dunstrc

conf=~/.config/dunst/dunstrc

bg=$(xrdb -query | grep 'background' | head -n1 | cut -f 2)
b2=$(xrdb -query | grep 'color8' | head -n1 | cut -f 2)
fg=$(xrdb -query | grep 'foreground' | head -n1 | cut -f 2)
cc=$(xrdb -query | grep 'cursorColor' | cut -f 2)

bgline="    background = \"$bg\""
b2line="    frame_color = \"$b2\""
fgline="    foreground = \"$fg\""
ccline="    frame_color = \"$cc\""

echo "[urgency_low]" > $conf
echo $bgline >> $conf
echo $fgline >> $conf
echo $ccline >> $conf
echo "" >> $conf
echo "[urgency_normal]" >> $conf
echo $bgline >> $conf
echo $fgline >> $conf
echo $b2line >> $conf
echo "" >> $conf
echo "[urgency_critical]" >> $conf
echo $bgline >> $conf
echo $fgline >> $conf
echo $b2line >> $conf
echo "" >> $conf
