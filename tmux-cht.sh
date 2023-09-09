#!/usr/bin/env bash
# taken from github.com/ThePrimeagen/.dotfiles
# adapted to provide man or tldr results

if [[ $1 == "man" ]]; then

    selected="$(man -k "" | cut -f 1 -d ' ' | fzf)"
    if [[ -z $selected ]]; then
        exit 0
    fi

    command="man $selected"

elif [[ $1 == "tldr" ]]; then

    read -p "Enter Command: " selected
    if [[ -z $selected ]]; then
        exit 0
    fi

    command="tldr $selected | less"

else

    langfile=~/.config/tmux/.tmux-cht-languages
    cmdfile=~/.config/tmux/.tmux-cht-commands

    selected=`cat $langfile $cmdfile | fzf`
    if [[ -z $selected ]]; then
        exit 0
    fi

    read -p "Enter Query: " query
    query=`echo $query | tr ' ' '+'`

    if grep -qs "$selected" "$langfile"; then
        command="curl -s cht.sh\/$selected\/$query | less -R"
    else
        command="curl -s cht.sh\/$selected~$query | less -R"
    fi

fi

if [[ -n $TMUX ]]; then
    tmux neww bash -c "$command"
else
    eval "$command"
fi
