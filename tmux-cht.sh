#!/usr/bin/env bash
# taken from github.com/ThePrimeagen/.dotfiles

langfile=~/.config/tmux/.tmux-cht-languages
cmdfile=~/.config/tmux/.tmux-cht-commands

selected=`cat $langfile $cmdfile | fzf`
if [[ -z $selected ]]; then
    exit 0
fi

read -p "Enter Query: " query

if grep -qs "$selected" "$langfile"; then
    query=`echo $query | tr ' ' '+'`
    tmux neww bash -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
    tmux neww bash -c "curl -s cht.sh/$selected~$query | less -R"
fi
