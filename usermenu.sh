#!/usr/bin/env bash
# Credit to github.com/stefanv

shopt -s nullglob globstar

typeit=0
if [[ $1 == "--type" ]]; then
    typeit=1
    shift
fi

prefix=${PASSWORD_STORE_DIR-~/.password-store}
password=$(cd "$prefix" && find * -type f -iname "*.gpg" -exec sh -c 'printf "%s\n" "${@%.gpg}"' _ {} + | dmenu -i "$@")

[[ -n $password ]] || exit

if [[ $typeit -eq 0 ]]; then
    username=$(pass show "$password" | grep -o -P "user(name)?: \K.*")
    echo "$username" | xclip  # send the username to middle button paste
else
    username=$(pass show "$password" | grep -o -P "user(name)?: \K.*")
    xdotool type "$username" # type the username
fi
