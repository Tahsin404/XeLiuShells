#!/usr/bin/env bash
# ~/.config/quickshell/scripts/on_notify.sh
# Dunst strictly passes: $1=appname, $2=summary, $3=body

mkdir -p "$HOME/.cache"
echo -e "$1\t$2\t$3" >>"$HOME/.cache/quickshell_notifs.log"
