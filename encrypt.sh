#!/bin/sh
# Encrypt, commit and push dotfiles with yadm

yadm encrypt
cp ~/.local/share/yadm/archive ~/git/dotfiles-secret || exit
cd ~/git/dotfiles-secret || exit
git add archive
git commit -am "chore: encrypt files"
git push
