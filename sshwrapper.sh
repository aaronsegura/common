#!/bin/bash

if [ "$( echo $SSH_ORIGINAL_COMMAND | egrep '^cat\ /proc/stat$|^free$|^uptime$|^cat\ /proc/diskstats$|^df$|^cat\ /proc/net/dev$|^netstat$|^cat\ /proc/vmstat$|^netstat -ant$|^free -ob$')" ]; then
       $SSH_ORIGINAL_COMMAND
else
       logger -t sshWrapper -p auth.warn "Unauthorized access attempt from $SSH_CLIENT with command: $SSH_ORIGINAL_COMMAND"
fi
