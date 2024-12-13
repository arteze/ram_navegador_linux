#!/bin/sh

sleep 0.1
xdotool getactivewindow set_window --name "$@"
PS1="$PS1\[\e];$@\a\]"
