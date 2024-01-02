#!/usr/bin/env bash
# taken from github.com/ThePrimeagen/.dotfiles
# adapted to provide man or tldr results

usage="Usage: tmux-cht.sh [tldr] [cht.sh] [man]"

if [[ -n "$1" ]]; then
    mode="$1"
else
    mode_options=$(echo "tldr" && echo "cht.sh" && echo man)
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
else
    echo "$usage"
    exit 1
fi

if [[ -n $TMUX ]]; then
    tmux neww bash -c "$command"
else
    eval "$command"
fi
