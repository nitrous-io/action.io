#!/bin/sh
#
# Simple tty.js init.d script conceived to work on Linux systems
# as it does use of the /proc filesystem.

TTYPORT=8080
EXECNAME=tty.js
EXEC=/usr/local/bin/${EXECNAME}

case "$1" in
    start)
        PID=$(pidof $EXECNAME)
        if [ $PID ]
        then
                echo "tty.js exists with pid $PID, process is already running or crashed"
        else
                echo "Starting tty.js server..."
                $EXEC --port $TTYPORT --daemonize
        fi
        ;;
    stop)
        PID=$(pidof $EXECNAME)
        if [ -z $PID ]
        then
                echo "tty.js process is not running"
        else
                echo "Stopping ..."
                kill -9 $PID
                while [ $(pidof $EXECNAME) ]
                do
                    echo "Waiting for tty.js to shutdown ..."
                    sleep 1
                done
                echo "tty.js stopped"
        fi
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac
