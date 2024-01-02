#!/usr/bin/env bash
# taken from github.com/ThePrimeagen/.dotfiles
# adapted to provide man, tldr or hoogle results

usage="Usage: tmux-cht.sh [tldr] [cht.sh] [man]"

if [[ -n "$1" ]]; then
    mode="$1"
else
    mode_options=$(echo "tldr" && echo "cht.sh" && echo "hoogle" && echo man)
    mode=$(echo "$mode_options" | fzf)
fi

if [[ "$mode" == man ]]; then

    selected="$(man -k "" | cut -f 1 -d ' ' | fzf)"
    if [[ -z $selected ]]; then
        exit 0
    fi

    command="man $selected"

elif [[ "$mode" == "tldr" ]]; then

    read -p "Enter Command: " selected
    if [[ -z $selected ]]; then
        exit 0
    fi

    command="tldr $selected | less"

elif [[ "$mode" == "cht.sh" ]]; then

    langfile=~/.config/tmux/.tmux-cht-languages
    cmdfile=~/.config/tmux/.tmux-cht-commands

    selected=$(cat $langfile $cmdfile | fzf)
    if [[ -z $selected ]]; then
        exit 0
    fi

    read -p "Enter Query: " query
    query=$(echo "$query" | tr ' ' '+' | sed 's/\([()]\)/\\\1/g')

    if grep -qs "$selected" "$langfile"; then
        command='curl -s cht.sh\/'"$selected\/$query"' | less -R'
    else
        command="curl -s cht.sh\/$selected~$query | less -R"
    fi

elif [[ "$mode" == "hoogle" ]]; then

    read -p "Enter Query: " query
    if [[ -z $query ]]; then
        exit 0
    fi
    selected=$(hoogle "$query" --count=1000 | fzf | cut -f 2- -d ' ')
    if [[ -z $selected ]]; then
        exit 0
    fi

    command='hoogle "'"$selected"'" --info --colour | less -R'

else
    echo "$usage"
    exit 1
fi

if [[ -n $TMUX ]]; then
    tmux neww bash -c "$command"
else
    eval "$command"
fi
