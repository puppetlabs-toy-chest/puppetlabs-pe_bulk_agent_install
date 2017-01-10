#!/bin/bash
# You can pass the FQDN of each node right in the CLI.
# In this case unprovisioned-agent1 is an FQDN as is unprovisioned-agent2, etc...
#
sudo puppet bulk install unprovisioned-agent1 \
                         unprovisioned-agent2 \
                         unprovisioned-agent3 \
                         --credentials ../json/sudo_install.json --trace --debug

