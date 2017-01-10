#!/bin/bash
# This example shows how to use a list of Linux node names in a txt file as the target.
#
# el_nodes.txt should have one FQDN per line
#
sudo puppet bulk install --nodes ~/el_nodes.txt --credentials ../json/sudo_install.json

