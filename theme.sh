#!/bin/sh
# set Xresources and vim colours from positional arguments and update kitty and dunst configs from .Xresources

# REQUIRED/SUPPORTED PROGRAMS

# .Xresources with colorschemes
# kitty, dusnt, nitrogen with config files to be edited
# reloads i3wm, kitty, and nvim as server

theme=${1-gruv}

# set .Xresources theme

xres=~/.Xresources
xtheme=$theme

sed -i "s/^\(#define c\)\([0-9]\{2\}\) [a-z]\+\2$/\1\2 $xtheme\2/" $xres
sed -i "s/^\(#define \)\([a-z]\{2\}[0-9]\?\)\s[a-z]\+\2$/\1\2 $xtheme\2/" $xres

xrdb $xres

# set vim colourscheme

vimconf=~/.config/nvim/init.vim
vimtheme=$(cat $xres | grep "^\! $theme [a-z0-9]\+ \!$" | cut -s -d ' ' -f 3)

sed -i "s/^\(colorscheme \)[a-z0-9]*$/\1$vimtheme/" $vimconf

# copy colours in .Xresources to kitty.conf

kittyconf=~/.config/kitty/kitty.conf

sed -i "/# FOLLOWING LINES WILL BE AUTOMATICALLY OVERWRITTEN/q" $kittyconf

echo "" >> $kittyconf

kittyregex='^\*\(color[0-9]\{1,2\}\|background\|foreground\|cursorColor\):\s#[a-zA-Z0-9]\{6\}$'

xrdb -query | grep "$kittyregex" |cut -c 2- | sed "s/:\s/ /" | sed -r "s/^cursorColor/cursor/" >> $kittyconf

# copy colours in .Xresources to dunstrc

dunstconf=~/.config/dunst/dunstrc

bg=$(xrdb -query | grep '^\*background:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
fg=$(xrdb -query | grep '^\*foreground:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
wi=$(xrdb -query | grep '^\*windowi:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
wf=$(xrdb -query | grep '^\*windowf:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
wu=$(xrdb -query | grep '^\*windowu:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)

bgline="    background = \"$bg\""
fgline="    foreground = \"$fg\""
wiline="    frame_color = \"$wi\""
wfline="    frame_color = \"$wf\""
wuline="    frame_color = \"$wu\""

sed -i "/# FOLLOWING LINES WILL BE AUTOMATICALLY OVERWRITTEN/q" $dunstconf

echo "" >> $dunstconf
echo "[urgency_low]" >> $dunstconf
echo $bgline >> $dunstconf
echo $fgline >> $dunstconf
echo $wiline >> $dunstconf
echo "" >> $dunstconf
echo "[urgency_normal]" >> $dunstconf
echo $bgline >> $dunstconf
echo $fgline >> $dunstconf
echo $wfline >> $dunstconf
echo "" >> $dunstconf
echo "[urgency_critical]" >> $dunstconf
echo $bgline >> $dunstconf
echo $fgline >> $dunstconf
echo $wuline >> $dunstconf

# set nitrogen wallpaper

nitrogenconf=~/.config/nitrogen/bg-saved.cfg 

sed -i "s/^\(file=\/home\/lvdv\/drive\/Pictures\/Wallpapers\/themes\/\)[a-zA-Z0-9]\+\(\.jpg\)/\1$theme\2/" $nitrogenconf

# reload things

i3-msg restart
pgrep kitty | xargs kill -s USR1
nvim --server $NVIM_LISTEN_ADDRESS --remote-send ':source $MYVIMRC<CR>'
