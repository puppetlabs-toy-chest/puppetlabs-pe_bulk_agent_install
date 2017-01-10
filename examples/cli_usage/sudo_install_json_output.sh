#!/bin/bash
# Add '--render-as json' to output the results of the run as JSON for easiser parsing.
# Additionally, we are piping the output through 'python -m json.tool' to pretty print it.
#
sudo puppet bulk install unprovisioned-agent1 \
                         unprovisioned-agent2 \
                         unprovisioned-agent3 \
                         unprovisioned-agent4 \
                         unprovisioned-agent5 \
                         --credentials ../json/sudo_install.json \
                         --log_level err \
                         --render-as json | python -m json.tool

