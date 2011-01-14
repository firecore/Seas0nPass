#!/bin/bash
shopt -s extglob

function stash() {
    src=$1
    dst=var/stash/${src##*/}
    mv "${src}" "${dst}"
    dst=${src//+([A-Za-z])/..}/${dst}
    ln -s "${dst#../}" "${src}"
}

mnt=$1
cd "${mnt}"

mkdir -p var/stash
mkdir -p usr/include

stash Applications
stash Library/Ringtones
stash Library/Wallpaper
stash usr/bin
stash usr/include
stash usr/lib/pam
stash usr/libexec
stash usr/share
