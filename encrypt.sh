#!/bin/sh
# Encrypt, commit and push dotfiles with yadm

gitdir=~/git/dotfiles-secret
yadmdir=~/.local/share/yadm

if [ -z "$1" ]; then
    yadm encrypt
    cp $yadmdir/archive $gitdir || exit
    cd $gitdir || exit
    git add archive
    git commit -am "chore: encrypt files"
    git push
elif [ "$1" = "-d" ] || [ "$1" = "--decrypt" ]; then
    cd $gitdir || exit
    git pull
    cp archive $yadmdir || exit
    yadm decrypt
else
    echo "usage: encrypt.sh [--decrypt]"
    exit
fi
