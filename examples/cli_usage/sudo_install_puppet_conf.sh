#!/bin/bash
# This shows an example of customizing puppet.conf after installing the Puppet agent.
#
# The credentials JSON file used below includes a hash named "arguments".
# Each value of that hash must be another hash whose key name corresponds
# to a section in puppet.conf (main, agent, etc...). For example:
#
#  {
#    "username": "vagrant",
#    "ssh_key_file": "/vagrant/examples/vagrant.rsa",
#    "master" : "pe-201620-master",
#    "arguments" :
#      {"agent": { "environment": "development" }}
#  }
#
#
sudo puppet bulk install unprovisioned-agent1 --credentials ../json/sudo_install_puppet_conf.json

