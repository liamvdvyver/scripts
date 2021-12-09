#!/bin/bash
# copy colours in .Xresources to dunstrc

conf=~/.config/dunst/dunstrc

bg=$(xrdb -query | grep 'background' | head -n1 | cut -f 2)
fg=$(xrdb -query | grep 'foreground' | head -n1 | cut -f 2)
fc=$(xrdb -query | grep 'cursorColor' | cut -f 2)

bgline="    background = \"$bg\""
fgline="    foreground = \"$fg\""
fcline="    frame_color = \"$fc\""

echo "[urgency_low]" > $conf
echo $bgline >> $conf
echo $fgline >> $conf
echo $fcline >> $conf
echo "" >> $conf
echo "[urgency_normal]" >> $conf
echo $bgline >> $conf
echo $fgline >> $conf
echo $fcline >> $conf
echo "" >> $conf
echo "[urgency_critical]" >> $conf
echo $bgline >> $conf
echo $fgline >> $conf
echo $fcline >> $conf
echo "" >> $conf
