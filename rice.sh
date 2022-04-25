#!/bin/sh

# Copies theme configuration from .Xresources to neovim, kitty, dunst, i3wm, and
# sets corresponding wallpaper with nitrogen
#
# NOTE: when specifying the layout of config files, ^ and $ are used to denote
# the start and end of lines

# INITAL VARIABLES --------------------------------------------------------- {{{

usage="usage: rice.sh <theme> [--light] [--dark] [--toggle]"

# Intended usage:
# rice.sh [theme] -> $theme set to $1
# rice.sh [theme] [--light OR --dark] -> $theme set to $1, $bg set per $2
# rice.sh [--toggle] -> $toggle set to $1
# rice.sh [--light OR --dark] -> $toggle set to 2, $bg set per $1

if [ -z "$1" ]; then # No arguments -> usage warning
    echo "$usage"
    exit
elif [ "$1" = "--toggle" ]; then # --toggle -> set $toggle to 1
    toggle="1"
elif [ "$1" = "--light" ]; then # --light -> set $toggle to 2, light $bg
    toggle="2"
    bg="light"
elif [ "$1" = "--dark" ]; then # --dark -> set $toggle to 2, dark $bg
    toggle="2"
    bg="dark"
elif [ "$1" ]; then # other argument -> set $theme to argument
    theme="$1"
fi
    
if [ "$theme" ] && [ -z "$2" ]; then # no $2, theme set -> default to dark $bg
    bg="dark"
elif [ "$theme" ] && [ "$2" = "--light" ]; then # --light, theme set -> set
    bg="light"                                  # -> $theme and $bg as per spec
    theme="$theme""L"
elif [ "$theme" ] && [ "$2" = "--dark" ]; then # --dark, theme set -> set dark $bg
    bg="dark"
elif [ "$2" ]; then # invalid $2 -> usage warning
    echo "$usage"
    exit
fi

# $warningline is placed in files to be overwritten by the script
warningline="# FOLLOWING LINES WILL BE OVERWRITTEN"

# }}}

# SET .XRESOURCES THEME ---------------------------------------------------- {{{

# ---- THEME SPECIFICATION ------------------------------------------------- {{{

# Themes should be laid out in xresources in the format:
#
# ^! [xtheme] [vimtheme] !$
#
# where the xtheme is given as $theme, all lowercase letters.
# Uppercase L is reserved for light verstions of a theme:
#
# ^! [xthemeL] [vimtheme] !$
#
# The pallette should be defined by variables in format: 
#
# ^#define xtheme_colour #XXXXXX$
#
# and the final theme by variables in formats:
#
# ^#define xthemeDD xtheme_colour$ or
# ^#define xthemeXXX xtheme_colour$
#
# where DD takes the format of 2 numbers for the first 16 ANSII colours,
# or XXX is two lowercase letters followed by an optional digit (either 2 or 3).
# In the rest of this script, final theme variables are used for the following:
#
# xtheme00-15       -->  kitty:  ANSII colours
# xthemebg/fg/cc    -->  kitty:  background, foreground and cursor
#                    ∟>  i3wm:   fg for urgent window border text
#                    ∟>  i3bar:  fg for urgent/binding workspace text
#                    ∟>  i3bar:  bg for binding workspace border/background
#                    ∟>  dunst:  bg for notification background
#                    ∟>  dunst:  fg for notification foreground
# xthemewf/wf2      -->  i3wm:   focused window border and indicator
#                    ∟>  dunst:  wf for normal urgency notification frame
# xthemewu/wu2      -->  i3wm:   urgent window border and indicator
#                    ∟>  i3bar:  wu for urgent workspace border/background
#                    ∟>  dunst:  wu critical urgency notification frame
# xthemewi          -->  i3wm:   inactive/unfocused/placeholder window border
#                    ∟>  dunst:  low urgency notification frame
# xthemebb          -->  i3bar:  background
# xthemebs/bs2      -->  i3bar:  i3status text and divider
# xthemebf          -->  i3bar:  focused workspace text
#                    ∟>  i3wm:   active window border text
# xthemebf2         -->  i3bar:  focused workspace background
# xthemebf3         -->  i3bar:  focused workspace border
# xthemeba/ba2/ba3  -->  i3bar:  active workspace as above
# xthemebi/bi2/bi3  -->  i3bar:  inactive workspace as above
#                    ∟>  i3wm:   bi for inactive window border text
#
# overall variables are then set from xtheme variable in formats:
#
# ^#define cDD xthemeDD$ or
# ^#define XXX xtheme XXX$
#
# where DD and XXX are as above.
#
# Finally, xresources are set from these variables, unabbreviating in the
# following formats:
#
# ^*colorD/DD:       cDD$
# ^*back/foreground: bg/fg$
# ^*cursorColor:     cc$
# ^*windowXX:        wXX$
# ^barXX:            bXX$

# ---- }}}

xres=~/.Xresources # location of Xresources config

if [ ! -f $xres ]; then # warn if not found (required for script)
    echo "no Xresources configuration found at $xres"
    exit
fi

# If $toggle = 1, find current theme and toggle xtheme <-> xthemeL, set $bg:
# If $toggle = 2, find current theme and switch to variant set by $bg already

if [ "$toggle" ]; then # if toggle is set, set $oldtheme literally
    oldtheme="$(grep "#define fg [a-zL]\+fg" $xres | sed "s/#define fg \([a-zL]\+\)fg/\1/")"
    if echo "$oldtheme" | grep -q "L"; then # if $oldtheme is light
        oldtheme="$(echo "$oldtheme" | sed "s/L//")" # set to basic form
        oldbg="light" # and set $oldbg to light
    else
        oldbg="dark" # if $oldtheme dark, set $oldbg to dark
    fi
    if [ "$toggle" = "1"  ]; then # toggling between dark and light
        if [ "$oldbg" = "dark" ]; then
            theme="$oldtheme""L"
            bg="light"
        else
            theme="$oldtheme"
            bg="dark"
        fi
    fi
    if [ "$toggle" = "2" ]; then # If switching to specified $bg, set theme
        if [ "$bg" = "light" ]; then
            theme="$oldtheme""L"
        elif [ "$bg" = "dark" ]; then
            theme="$oldtheme"
        fi
    fi
fi

# Set $xtheme to $theme if it is found in line specified format, and exit if it
# is not set (invalid input/Xresources layout):

xtheme="$(cat $xres | grep "^\! $theme [a-z0-9]\+ \!$" | cut -s -d ' ' -f 2)"

if [ -z "$xtheme" ]; then
    echo "Please select a valid theme from .Xresources"
    exit
fi

# Overall variables are then set from xtheme variables as specified,
# by finding and replacing corresponding lines with the current $xtheme:

sed -i "s/^\(#define c\)\([0-9]\{2\}\) [a-zL]\+\2$/\1\2 $xtheme\2/" $xres
sed -i "s/^\(#define \)\([a-z]\{2\}[0-9]\?\)\s[a-zL]\+\2$/\1\2 $xtheme\2/" $xres

xrdb $xres # update xrdb for later

# }}}

# SET VIM COLORSCHEME ------------------------------------------------------ {{{

vimconf=~/.config/nvim/init.vim # set location of MYVIMRC

if [ -f $vimconf ]; then # set vimtheme from $xres if $vimconf exists
    vimtheme="$(cat $xres | grep "^\! $theme [a-z0-9]\+ \!$" | cut -s -d ' ' -f 3)"
fi

# If $vimtheme was found, replace current setting in $vimconf for colorscheme
# and background:

if [ "$vimtheme" ]; then
    sed -i "s/^\(colorscheme \)[a-z0-9]\+$/\1$vimtheme/" $vimconf
    sed -i "s/^\(set background=\)[a-z]\+$/\1$bg/" $vimconf
fi

# }}}

# SET KITTY COLOURS -------------------------------------------------------- {{{

kittyconf=~/.config/kitty/kitty.conf # set location of kitty config

# Regex to match *colorDD, *background, *foregound, *cursorColor from Xresources
# database:

kittyregex='^\*\(color[0-9]\{1,2\}\|background\|foreground\|cursorColor\):\s#[a-zA-Z0-9]\{6\}$'

# If the $warningline line is matched, delete all following lines and replace
# with colours from Xresources, keeping variable names (except cursorColor) and
# formatting as follows:
#
# ^*cursorColor: #XXXXXX$ --> ^cursor #XXXXXX$

if [ -f $kittyconf ] && grep -q "^$warningline$" $kittyconf; then
    sed -i "/^$warningline$/q" $kittyconf
    echo "" >> $kittyconf
    xrdb -query | grep "$kittyregex" |cut -c 2- | sed "s/:\s/ /" | sed -r "s/^cursorColor/cursor/" >> $kittyconf
fi

# }}}

# SET DUNST COLOURS -------------------------------------------------------- {{{

dunstconf=~/.config/dunst/dunstrc # set dunst config location

# Set $dunstXX from Xresources database:
dunstbg=$(xrdb -query | grep '^\*background:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstfg=$(xrdb -query | grep '^\*foreground:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstwi=$(xrdb -query | grep '^\*windowi:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstwf=$(xrdb -query | grep '^\*windowf:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstwu=$(xrdb -query | grep '^\*windowu:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)

# Set $dunstXXline in appropriate format for $dunstconf:
dunstbgline="    background = \"$dunstbg\""
dunstfgline="    foreground = \"$dunstfg\""
dunstwiline="    frame_color = \"$dunstwi\""
dunstwfline="    frame_color = \"$dunstwf\""
dunstwuline="    frame_color = \"$dunstwu\""

# If the $warningline line is matched, delete all following lines and replace
# with $dunstXXline in appopriate sections:

if [ -f $dunstconf ] && grep -q "^$warningline$" $dunstconf; then
    sed -i "/^$warningline$/q" $dunstconf
    {
        echo ""
        echo "[urgency_low]"
        echo "$dunstbgline"
        echo "$dunstfgline"
        echo "$dunstwiline"
        echo ""
        echo "[urgency_normal]"
        echo "$dunstbgline"
        echo "$dunstfgline"
        echo "$dunstwfline"
        echo ""
        echo "[urgency_critical]"
        echo "$dunstbgline"
        echo "$dunstfgline"
        echo "$dunstwuline"
    } >> $dunstconf
fi

# }}}

# SET NITROGEN WALLPAPER --------------------------------------------------- {{{

# Set niteogen config location and regex for wallpaper directory:
nitrogenconf=~/.config/nitrogen/bg-saved.cfg
papedir='/home/lvdv/drive/Pictures/Wallpapers/themes/'
papedirregex="$(echo $papedir | sed 's/\//\\\//g')"

# If config is found and file exists names $theme, replace old theme.jpg with
# current $theme.jpg in config:

if [ -f $nitrogenconf ] && [ -f "$papedir$theme.jpg" ]; then
    sed -i "s/^\(file=$papedirregex\)[a-zA-Z0-9]\+\(\.jpg\)/\1$theme\2/" $nitrogenconf
fi

# }}}

# RELOAD ------------------------------------------------------------------- {{{

# Restart i3

if [ "$(command -v i3-msg)" ]; then i3-msg restart; fi # restart i3 if installed

# Send SIGUSR1 to runnin kitty instances (reloads config):
pgrep kitty | xargs kill -s USR1

# Find nvim server sockets and remote send command to reload config:
nvim_socks="$(find /tmp/ -regex "/tmp/nvim[a-zA-Z0-9]+/0" -print 2>/dev/null | paste -s -d ' ')"
echo "$nvim_socks" | xargs -r -n 1 nvim --remote-send ':source $MYVIMRC<CR>' --server

# }}}
