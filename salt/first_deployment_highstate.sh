#!/bin/bash

# Applies the "minimal" state in isolation to set the hostname and update Salt itself
# then applies the highstate

if [ -f /etc/debian_version ]; then
   echo "Debian detected. exiting"
   exit 1;
fi

salt-call --local --file-root=/root/salt/ --log-level=quiet --output=quiet state.sls default.minimal ||:
echo "---------------------------------------------------------------------------------------------------"
salt-call --local --file-root=/root/salt/ --log-level=info --retcode-passthrough --force-color state.highstate || exit 1

chmod +x /root/salt/highstate.sh
