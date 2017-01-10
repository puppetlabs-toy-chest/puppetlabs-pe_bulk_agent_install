#!/bin/bash
# An SSH private key can be supplied for authenticating to remote nodes.
#
# The credentials JSON file will need a "ssh_key_file" key whose value is the absolute path
# to an SSH private key file. For example:
#
# {
#   "username": "vagrant",
#   "ssh_key_file": "~/private_key.rsa",
#   "master" : "pe-201620-master"
# }
#
sudo puppet bulk install unprovisioned-agent2 unprovisioned-agent3 --credentials ../json/sudo_install_private_key.json
