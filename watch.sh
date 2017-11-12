#!/bin/sh

while true
do
    make $@
    inotifywait -rqe close_write src
done
