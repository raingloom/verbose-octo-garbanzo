#!/bin/sh

while true
do
    reset
    make $@
    inotifywait -rqe close_write src
done
