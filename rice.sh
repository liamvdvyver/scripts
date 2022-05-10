#!/bin/sh
# Source Xresources and copy configuration to config files
# Themes and documentation at gitlab.com/liamvdvyver/dotfiles

# INITAL VARIABLES --------------------------------------------------------- {{{

xres=~/.Xresources  # location of Xresources config
xdir=~/.config/rice/themes/ # location of theme files

if [ ! -f $xres ]; then # warn if not found (required for script)
    echo "no Xresources configuration found at $xres"
    exit
fi

themelist="$(ls "$xdir" -w 1)"
themelistindent="$(echo "$themelist" | sed 's/^/    /')"
usage="usage: rice.sh <theme> [--light] [--dark] [--toggle] [--list]\n\nthemes found in $xdir:\n$themelistindent\n"

# Intended usage:
# rice.sh [theme] -> $theme set to $1
# rice.sh [theme] [--light OR --dark] -> $theme set to $1, $bg set per $2
# rice.sh [--toggle] -> $toggle set to $1
# rice.sh [--light OR --dark] -> $toggle set to 2, $bg set per $1
# rice.sh [--light OR --dark] -> $toggle set to 2, $bg set per $1
# rice.sh [--list] -> print $themelist

# Parse $1:
if [ -z "$1" ]; then # No arguments -> usage warning
    printf "$usage"
    exit
elif [ "$1" = "--list" ]; then
    echo "$themelist"
    exit
elif [ "$1" = "--toggle" ] || [ "$1" = "-t" ]; then # --toggle -> set $toggle to 1
    toggle="1"
elif [ "$1" = "--light" ] || [ "$1" = "-l" ]; then # --light -> set $toggle to 2, light $bg
    toggle="2"
    bg="light"
elif [ "$1" = "--dark" ] || [ "$1" = "-d" ]; then # --dark -> set $toggle to 2, dark $bg
    toggle="2"
    bg="dark"
elif [ "$1" ]; then # other argument -> set $theme to argument
    theme="$1"
fi

# Parse $2:
if [ "$theme" ] && [ "$2" = "--light" ] || [ "$2" = "-l" ]; then # --light, theme set -> set
    bg="light"                                  # -> $theme and $bg as per spec
    theme="$theme""-light"
elif [ "$theme" ] && [ "$2" = "--dark" ] || [ "$2" = "-d" ]; then # --dark, theme set -> set dark $bg
    bg="dark"
    theme="$theme""-dark"
elif [ "$2" ]; then # invalid $2 -> usage warning
    printf "$usage"
    exit
fi

# $warningline is placed in files to be overwritten by the script
warningline="# FOLLOWING LINES WILL BE OVERWRITTEN"

# }}}

# SET .XRESOURCES THEME ---------------------------------------------------- {{{

# If $toggle = 1, find current theme and toggle theme-light <-> theme-dark
# If $toggle = 2, find current theme and switch to variant set by $bg

if [ "$toggle" ]; then # if toggle is set, set $oldtheme literally
    oldtheme="$(xrdb -query | grep "^rice\.theme:\s.\+$" | cut -f 2)"
    oldbg="$(xrdb -query | grep "^rice\.background:\s[a-z]\+$" | cut -f 2)"
    echo old
    echo $oldtheme
    echo $oldbg
    if [ "$toggle" = "1"  ]; then # toggling between dark and light
        if [ "$oldbg" = "dark" ]; then
            theme="$oldtheme""-light"
            bg="light"
        else
            theme="$oldtheme""-dark"
            bg="dark"
        fi
    fi
    if [ "$toggle" = "2" ]; then # If switching to specified $bg, set theme
        if [ "$bg" = "light" ]; then
            theme="$oldtheme""-light"
        elif [ "$bg" = "dark" ]; then
            theme="$oldtheme""-dark"
        fi
    fi
fi

# By now, should have $theme and $bg set directly or by reading $xres
echo "theme: $theme"
echo ""

xtheme="$(echo "$themelist" | grep "^$theme$")"

if [ "$xtheme" ]; then
    echo "xresources theme: $xtheme"
else
    echo "Xresources: theme not found"
    printf "\nthemes found in $xdir:\n$themelistindent\n"
    exit
fi

xthemepath="$(echo $xdir | sed 's/\//\\\//g')"

sed -i "s/^\(#include \)\".\+\"$/\1\"$xthemepath$xtheme\"/" $xres && \
    xrdb $xres 2>/dev/null && \
    echo "updated $xres"

bg=$(xrdb -query | grep 'rice.background:\s.\+$' | cut -f 2)

# }}}

# SET GTK THEMES ----------------------------------------------------------- {{{

# Set gtk themes from xresources:
gtkdark=$(xrdb -query | grep 'rice.gtk.dark:\s.\+$' | cut -f 2)
gtklight=$(xrdb -query | grep 'rice.gtk.light:\s.\+$' | cut -f 2)
icondark=$(xrdb -query | grep 'rice.icon.dark:\s.\+$' | cut -f 2)
iconlight=$(xrdb -query | grep 'rice.icon.light:\s.\+$' | cut -f 2)

# Set single widget and icon theme based on $bg
if [ "$bg" = "dark" ]; then
    gtk="$gtkdark"
    icon="$icondark"
elif [ "$bg" = "light" ]; then
    gtk="$gtklight"
    icon="$iconlight"
fi

echo "gtk widget theme: $gtk"
echo "gtk icon theme: $icon"

# Location of gtk2 and gtk3 configs:
gtk2conf=~/.gtkrc-2.0
gtk3conf=~/.config/gtk-3.0/settings.ini

# Set themes in config files
if [ -f $gtk2conf ]; then
    sed -i "s/^\(gtk-theme-name=\)\"[a-zA-Z\-]*\"$/\1\"$gtk\"/" $gtk2conf && \
    sed -i "s/^\(gtk-icon-theme-name=\)\"[a-zA-Z\-]*\"$/\1\"$icon\"/" $gtk2conf && \
    echo "updated $gtk2conf"
fi

if [ -f $gtk3conf ]; then
    sed -i "s/^\(gtk-theme-name=\)[a-zA-Z\-]*$/\1$gtk/" $gtk3conf && \
    sed -i "s/^\(gtk-icon-theme-name=\)[a-zA-Z]*$/\1$icon/" $gtk3conf && \
    echo "updated $gtk3conf"
fi

# }}}

# SET VIM COLORSCHEME ------------------------------------------------------ {{{

vimconf=~/.config/nvim/init.vim # set location of MYVIMRC

# Set $vimtheme and $vimbg from xresources:
vimtheme="$(xrdb -query | grep '^rice\.nvim\.theme:\s[a-z0-9]\+$' | cut -f 2)"
vimbg="$(xrdb -query | grep '^rice\.nvim\.background:\s[a-z0-9]\+$' | cut -f 2)"

# If $vimconf found, replace with $vimtheme and $vimbg (if either set):
if [ "$vimconf" ]; then
    if [ "$vimbg" ]; then
        sed -i "s/^\(set background=\)[a-z]\+$/\1$vimbg/" $vimconf
    fi
    if [ "$vimtheme" ]; then
        sed -i "s/^\(colorscheme \)[a-z0-9]\+$/\1$vimtheme/" $vimconf
        echo "nvim theme: $vimtheme"
    fi
    echo updated "$vimconf"
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
    xrdb -query | grep "$kittyregex" | cut -c 2- | sed "s/:\s/ /" | sed -r "s/^cursorColor/cursor/" >> $kittyconf
    echo "updated $kittyconf"
fi

# }}}

# SET ZATHURA COLOURS ------------------------------------------------------ {{{

zathuraconf=~/.config/zathura/zathurarc

zathbg=$(xrdb -query | grep '^\*background:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
zathfg=$(xrdb -query | grep '^\*foreground:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
zathbg2=$(xrdb -query | grep '^rice\.background\.active:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
zathfg2=$(xrdb -query | grep '^rice\.foreground\.active:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
zathbg3=$(xrdb -query | grep '^rice\.background\.focused:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
zathfg3=$(xrdb -query | grep '^rice\.foreground\.focused:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
zathbgr=$(xrdb -query | grep '^rice\*urgent:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)

if [ -f "$zathuraconf" ]; then
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #fg\)/\1$zathfg\2/" "$zathuraconf"
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #bg\)/\1$zathbg\2/" "$zathuraconf"
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #bg2\)/\1$zathbg2\2/" "$zathuraconf"
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #fg2\)/\1$zathfg2\2/" "$zathuraconf"
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #bg3\)/\1$zathbg3\2/" "$zathuraconf"
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #fg3\)/\1$zathfg3\2/" "$zathuraconf"
    sed -i "s/\(set [a-z\-]\+ \\\\\)\#[a-zA-Z0-9]\{6\}\( #bgr\)/\1$zathbgr\2/" "$zathuraconf"
fi

# }}}

# SET DUNST COLOURS -------------------------------------------------------- {{{

dunstconf=~/.config/dunst/dunstrc # set dunst config location

# Set $dunstXX from Xresources database:
dunstbg=$(xrdb -query | grep '^\*background:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstfg=$(xrdb -query | grep '^\*foreground:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstfl=$(xrdb -query | grep '^rice\.border\.unfocused:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstfn=$(xrdb -query | grep '^rice\.border\.focused:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)
dunstfc=$(xrdb -query | grep '^\rice\*urgent:\s#[a-zA-Z0-9]\{6\}$' | cut -f 2)

# Set $dunstXXline in appropriate format for $dunstconf:
dunstbgline="background = \"$dunstbg\""
dunstfgline="foreground = \"$dunstfg\""
dunstflline="frame_color = \"$dunstfl\""
dunstfnline="frame_color = \"$dunstfn\""
dunstfcline="frame_color = \"$dunstfc\""

# Set $dunsticonline from $icon and enable recursive lookup:
dunsticonline="icon_theme = \"$icon\""
dunstlookline="enable_recursive_icon_lookup = \"true\""

# If the $warningline line is matched, delete all following lines and replace
# with $dunstXXline in appopriate sections:
if [ -f $dunstconf ] && grep -q "^$warningline$" $dunstconf; then
    sed -i "/^$warningline$/q" $dunstconf
    {
        echo ""
        echo "[global]"
        echo "$dunsticonline"
        echo "$dunstlookline"
        echo ""
        echo "[urgency_low]"
        echo "$dunstbgline"
        echo "$dunstfgline"
        echo "$dunstflline"
        echo ""
        echo "[urgency_normal]"
        echo "$dunstbgline"
        echo "$dunstfgline"
        echo "$dunstfnline"
        echo ""
        echo "[urgency_critical]"
        echo "$dunstbgline"
        echo "$dunstfgline"
        echo "$dunstfcline"
    } >> $dunstconf && \
        echo "updated $dunstconf"
fi

# }}}

# SET NITROGEN WALLPAPER --------------------------------------------------- {{{

# Set niteogen config location and regex for wallpaper directory:
nitrogenconf=~/.config/nitrogen/bg-saved.cfg
papedir=~/.config/rice/papes/
papedirregex="$(echo $papedir | sed 's/\//\\\//g')"
wallpaper="$(ls $papedir -w 1 | grep "^$theme\.[a-zA_Z]\+$")"

# If config is found and file exists names $theme, replace old theme.jpg with
# current $theme.jpg in config:
if [ -f $nitrogenconf ] && [ "$wallpaper" ]; then
    sed -i "s/^\(file=\).\+/\1$papedirregex$wallpaper/" $nitrogenconf && \
    echo "updated $nitrogenconf"
fi

# }}}

# RELOAD ------------------------------------------------------------------- {{{

# Restart i3:
if [ "$(command -v i3-msg)" ]; then i3-msg restart && echo "reloaded i3"; fi # restart i3 if installed

# Send SIGUSR1 to runnin kitty instances (reloads config):
pgrep kitty | xargs kill -s USR1 && echo "reloaded kitty"

# Find nvim server sockets and remote send command to reload config:
nvim_socks="$(find /tmp/ -regex "/tmp/nvim[a-zA-Z0-9]+/0" -print 2>/dev/null | paste -s -d ' ')"
echo "$nvim_socks" | xargs -r -n 1 nvim --remote-send "<esc>:source \$MYVIMRC<CR>" --server && \
echo "reloaded nvim"

# Find zathura instances and source condig with dbus
pgrep zathura | xargs -I '{}' dbus-send --type=method_call --dest=org.pwmt.zathura.PID-'{}' /org/pwmt/zathura org.pwmt.zathura.ExecuteCommand string:source

# }}}
