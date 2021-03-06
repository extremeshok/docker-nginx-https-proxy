#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
# Monitor the /certs directory and sub directories
# When a chnage is detected, wait 30 seconds and issue the nginx reload command
################################################################################
while true
do
        /usr/bin/inotifywait -e create -e modify -e delete -r /certs/
        echo "Change detetect in /certs"
        sleep 30s
        echo "Reloading nginx"
        /usr/sbin/nginx -s reload
done
