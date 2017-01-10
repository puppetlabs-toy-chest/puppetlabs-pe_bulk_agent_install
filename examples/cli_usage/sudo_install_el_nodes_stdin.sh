#!/bin/bash
# You can also pass FQDN's in via STDIN, separated by new lines, if you add '-' after '--nodes'.
#
printf '%s\n%s\n' unprovisioned-agent1 unprovisioned-agent2 | sudo puppet bulk install --credentials ../json/sudo_install.json --nodes -

