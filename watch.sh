#!/bin/zsh

while true
do
    reset
    time make $@ 2> >(tee .trace 1>&2) && notify-send "$@ finished building"
    inotifywait -rqe close_write src
done
