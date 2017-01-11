# PE Bulk Agent Install

Professional Services toolkit for installing Puppet Enterprise agents in bulk

## Table of Contents

* [Overview](#overview)
* [Command Line Usage](#command-line-usage)
* [Installation](#installation)
* [Simple SSH agent deployment](#simple-ssh-agent-deployment)
  * [Simple SSH agent deployment with nodes file](#simple-ssh-agent-deployment-with-nodes-file)
  * [Simple SSH agent deployment with nodes STDIN](#simple-ssh-agent-deployment-with-nodes-stdin)
  * [Multiple thread support](#multiple-thread-support)
* [Credentials](#credentials)
  * [Sudo \+ Password Credentials](#sudo--password-credentials)
  * [Sudo \+ Private key Credentials](#sudo--private-key-credentials)
  * [Private key Credentials \+ no password](#private-key-credentials--no-password)
  * [Private key Credentials \+ password](#private-key-credentials--password)
  * [Extras](#extras)
* [Fixing DNS and NTP on agent nodes](#fixing-dns-and-ntp-on-agent-nodes)
* [Windows](#windows)
  * [Setup](#setup)
  * [Usage](#usage)
    * [Single\-agent](#single-agent)
    * [Pass Windows credentials](#pass-windows-credentials)
    * [Multiple agents (using nodes\.txt)](#multiple-agents-using-nodestxt)
    * [Multiple agents (using provided file)](#multiple-agents-using-provided-file)
  * [Caveats](#caveats)
    * [Domain Member vs Standalone System](#domain-member-vs-standalone-system)
    * [Windows Bastion](#windows-bastion)
* [Expectations](#expectations)
* [Class Usage](#class-usage)
  * [pe\_bulk\_agent\_install::windows::bastion](#pe_bulk_agent_installwindowsbastion)
* [Limitations](#limitations)
* [Development](#development)
* [Contributors](#contributors)

---

## Overview

This module is used to build installation scripts for doing bulk installs of Puppet Agents on Linux and Windows machines with Puppet Enterprise.

It builds on the original curl to bash installation method available on the master

## Command Line Usage

This module ships a puppet face `puppet bulk install`, it can be used with any
system that supports ssh to allow for the mass installation of agent nodes using
the simplified installer bundled with Puppet Enterprise.

For windows a powershell script is provided  and configured via the modules classes

## Installation

The puppet face requires the [chloride](https://rubygems.org/gems/chloride) gem to be in place in the puppet ruby stack (not puppetserver).This gem only needs to be installed on the bastion host performing the command line operations.

This gem can be installed manually with the following command:

```shell
/opt/puppetlabs/puppet/bin/gem install chloride --no-ri --no-rdoc
```

> Future versions of Puppet Enterprise will likely ship with this gem see: [PE-17084](https://tickets.puppetlabs.com/browse/PE-17084)

This can be automatically installed via puppet with the following code:

```puppet
package {'chloride':
  ensure   => 'present',
  provider => 'puppet_gem',
}
```

> This should be incorporated into this module at a later date

## Simple SSH agent deployment

```shell
sudo puppet bulk install unprovisioned-agent1 unprovisioned-agent2  \
--credentials /vagrant/examples/json/sudo_install.json \
--debug
```

This invocation would connect to unprovisioned-agent1 and unprovisioned-agent2
node and initiate the `curl | bash` installer. The credentials for the ssh
connection would be contained in the JSON file passed with `--credentials`.

In the event other authentication methods fail, the user will be prompted for the password by the installer libraries.
This may allow for some systems such as two factor to be used however it likely will
be cumbersome on large numbers of nodes.

> This may stop an unattended installation waiting for input. Ensure your
> credentials are correct

### Simple SSH agent deployment with nodes file

```shell
sudo puppet bulk install \
--nodes /vagrant/examples/el_nodes.txt \
--credentials /vagrant/examples/json/sudo_install.json --trace --debug
```

This assumes a file that contains node names with newline character separating each

### Simple SSH agent deployment with nodes STDIN

```shell
#!/bin/bash
printf '%s\n%s\n%s\n' unprovisioned-agent1 unprovisioned-agent2 unprovisioned-agent4 |
sudo puppet bulk install \
--nodes - \
--credentials /vagrant/examples/json/sudo_install.json --trace --debug
```

You can build your own custom scripts to add agent nodes to the install list and pass them
in via STDIN. I.e. you can ping the nodes and only echo them if they respond.

### Multiple thread support

`puppet bulk install` supports a `--threads` argument which defaults to the number of processors on the bastion host times 2.
You can increase or decrease this to control the load on your masters and bastion host running the ssh sessions.


## Credentials

Credentials for the nodes can be specified in the json file, options for passing them in are not supplied for security reasons.

### Sudo + Password Credentials

```json
{
  "username": "vagrant",
  "sudo_password": "vagrant",
  "master" : "pe-201620-master"
}
```

This file assume a user with sudo access on the target agent system. The master pe-201620-master will be used to curl the installer from.
This hostname must be reachable by the agent node as it is use in the yum/apt repos no matter what is passed at this step. Ensure your site has
proper DNS or /etc/hosts entries configured for the Puppet Master.

### Sudo + Private key Credentials

```json
{
  "username": "root",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "master" : "pe-201620-master"
}
```

This file assumes a private key is installed and readable on the box running the CLI, and that it corresponds to an authorized_key file on the target host
using the username root.

### Private key Credentials + no password

```json
{
  "username": "bob",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "master" : "pe-201620-master"
}
```

This file assumes a private key is installed and readable on the box running the CLI ( with no password set), and that it corresponds to an authorized_key file on the target host
using the username bob (who has sudo access).

### Private key Credentials + password

```json
{
  "username": "bob",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "ssh_key_passphrase": "freyjaIscute",
  "master" : "pe-201620-master"
}
```

This file assumes a private key is installed and readable on the box running the CLI ( with a password set), and that it corresponds to an authorized_key file on the target host
using the username bob (who has sudo access).

### Extras

```json
{
  "username": "vagrant",
  "ssh_key_file": "/vagrant/examples/vagrant.rsa",
  "master" : "pe-201620-master",
  "arguments" :
    {"agent": { "environment": "development" }}
}
```

Using the arguments key of the json file, you can specify csr_attributes and puppet.conf settings. This allows for you to pass them in at installation time and will be passed
to the bash installer as `section:key=value` arguments to `-s`

## Fixing DNS and NTP on agent nodes

Ideally your environment will have correct DNS and Time synchronized ahead of
the Puppet Enterprise installation by way of your preseed/kickstart/sysprep
provisioning process. In the event that you need to update this information,
you can pass execute this face with an alternate script on the master.

```json
{
  "username": "root",
  "ssh_key_file": "/vagrant/examples/vagrant.rsa",
  "master" : "10.0.1.1",
}
```

```shell
sudo puppet bulk install \
--nodes /vagrant/examples/el_nodes.txt \
--credentials /vagrant/examples/json/sudo_install.json \
--debug
--script 'validate_install.sh'
```

This will download the preflight.sh script using your master's ip address and
execute it. An example of this script is located in the files directory,
> Note at the time of this writing you may need to build a custom wrapper script to pass this script arguments.

## Windows

### Setup

#### PE 2016.3.x and higher

1. Apply the `pe_repo::platform::windows_<arch>` class to the Puppet master and run Puppet. This will stage the MSI agent installer as well as the `install.ps1` PowerShell install script.

1. Apply the `pe_bulk_agent_install::windows::bastion` class to the bastion host you wish to install the PowerShell bulk agent install scripts to.

#### PE 2016.2.x and lower

1. Apply the `pe_bulk_agent_install::windows::master` class to the Puppet master and run Puppet. This will stage the MSI agent installer as well as the `install.ps1` PowerShell install script.

1. Apply the `pe_bulk_agent_install::windows::bastion` class to the bastion host you wish to install the PowerShell bulk agent install scripts to.
### Usage

#### Single-agent

The Agent argument supports hostname or IP Address.

```PowerShell
.\Invoke-PuppetAgentInstall.ps1 -Node fqdn.example.com -PMHostname master.puppet.vm
```

#### Pass Windows credentials

Credentials associated with a Windows user account.

```PowerShell
.\Invoke-PuppetAgentInstall.ps1 -Credential MYDOMAIN\Administrator -PMHostname master.puppet.vm
```

#### Multiple agents (using agents.txt)

Placing the FQDN of each of the respective agents in a file called agents.txt in the working directory where the distrib_agent.ps1 executable will be run.

```PowerShell
.\Invoke-PuppetAgentInstall.ps1 -PMHostname master.puppet.vm
```

#### Multiple agents (using provided file)

Placing the FQDN of each of the respective agents in a file and file path of your choosing then referencing said path with the FilePath argument.

```PowerShell
.\Invoke-PuppetAgentInstall.ps1 -FilePath C:\ProgramData\nodes_list.txt -PMHostname master.puppet.vm
```

### Caveats

#### Domain Member vs Standalone System

Regardless if the system running the remote script is a domain member or a standalone system, an entry for the each remote system will be created in the [Trusted Hosts](https://msdn.microsoft.com/en-us/library/aa384372.aspx) file.

If this is not a desired result, at the completion of the distributed install script execution you can clean out the [Trusted Hosts](https://msdn.microsoft.com/en-us/library/aa384372.aspx) file.  One method to complete this task programmatically is as follows:

[Use PowerShell to clear the Trusted Hosts file](https://blogs.technet.microsoft.com/heyscriptingguy/2013/11/29/powertip-use-powershell-to-clear-the-trusted-hosts-file/)

#### Windows Bastion

If the goal is to bulk install Windows agents, you will want to setup a Windows system purely for contacting other systems via [WinRM](https://msdn.microsoft.com/en-us/library/aa384426.aspx).

Post creation of said system, you will want to install an agent as you would traditionally or with the [`pe_install_ps1`](https://github.com/natemccurdy/puppet-pe_install_ps1) module as used by this bulk windows agent installer.

Once the agent is installed, it is time to classify the Windows distribution system with the class below:

## Expectations

In all cases, these scripts will:

* Install the appropriate Puppet Agent
* Start the Puppet Agent

---

## Class Usage

### `pe_bulk_agent_install::windows::bastion`

This class is expected to be installed on a Windows node that has had Puppet
manually installed. This "bastion" host will the node that will connect to unprovisioned Windows nodes.

### `master`

* Type: `String`
* Default: `$::settings::server`

The hostname of the Puppet master where the client will register its certificate.

### `master_port`

* Type: `Integer[0,65535]`
* Default: `8140`

The port number that puppetserver is listening on.

### `script_name`

* Type: `String`
* Default: `install.ps1`

The filename of the agent install script that gets put on the bastion.

### `scripts_install_location`

* Type: `String`
* Default: `C:/Windows/Temp`

The directory to store the agent install script on the bastion.

---

## Limitations

This is still considered pre-alpha, technical toolkit.

## Development

Currently, contributions for this module are only accepted from internal Customer Success team members within Puppet and affiliate partners.

## Contributors

* [Paul Anderson](https://github.com/hpcprofessional)
* [Andrew Brader](https://github.com/abrader)
* [Trev Harmon](https://github.com/trevharmon)
* [Brandon High](https://github.com/highb)
* [Troy Klein](https://github.com/spidersddd)
* [Nate McCurdy](https://github.com/natemccurdy)
* [Zack Smith](https://github.com/acidprime)
