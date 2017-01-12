# PE Bulk Agent Install

Puppet toolkit for rapidly installing Puppet agents in Puppet Enterprise

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
* [Command Line Options](#command-line-options)
* [Class Usage](#class-usage)
  * [pe\_bulk\_agent\_install::windows::bastion](#pe_bulk_agent_installwindowsbastion)
* [Limitations](#limitations)
* [Development](#development)
* [Contributors](#contributors)

---

## Overview

This module is used for bulk installs of Puppet Agents on Linux and Windows machines with Puppet Enterprise. It builds on the standard
Simplified Agent Installation process that comes with Puppet Enterprise.

The goal of this module is to accomplish the following tasks, rapidly and remotely, on Linux and Windows nodes:

* Install the Puppet agent
* Start the Puppet Agent

## Command Line Usage

This module ships a Puppet face, `puppet bulk install`. The face can be used with any
system that supports SSH to allow for the mass installation of Puppet agent nodes using
the simplified installer bundled with Puppet Enterprise.

See the [Command Line Options](#command-line-options) section for flags that can be passed to the CLI.

For Windows nodes, a separate method that uses a PowerShell script should be used. See [the docs here](#windows).

## Installation

The Puppet face requires the [chloride](https://rubygems.org/gems/chloride) gem to be in place in the Puppet ruby stack (not puppetserver)
of the node that will be executing the Puppet face. This could be your Puppet master or some other Puppet agent that is able to connect
to the soon-to-be Puppet agents.

Install the gem manually with the following shell command:

```shell
/opt/puppetlabs/puppet/bin/gem install chloride --no-ri --no-rdoc
```

> Future versions of Puppet Enterprise will likely ship with this gem see: [PE-17084](https://tickets.puppetlabs.com/browse/PE-17084)

The gem can also be installed via Puppet with the following code:

```puppet
package {'chloride':
  ensure   => 'present',
  provider => 'puppet_gem',
}
```

> This should be incorporated into this module at a later date

### pe_repo Setup

Because the Bulk Agent Installer face leverages the built-in Simplified Agent Installer of Puppet Enterprise, it's important that the
simplified agent installer is setup accordingly. Namely, make sure that your Puppet master has the correct `pe_repo::platform` classes
applied to it before attempting to run the Bulk Agent Installer.

Documentation for doing this is available here: <https://docs.puppet.com/pe/latest/install_agents.html#install-agents-with-a-different-os-and-architecture-than-the-puppet-master>

## Simple SSH agent deployment

```shell
sudo puppet bulk install unprovisioned-agent1 unprovisioned-agent2  \
                 --credentials /vagrant/examples/json/sudo_install.json \
                 --debug
```

This invocation would connect to unprovisioned-agent1 and unprovisioned-agent2
node and execute the simplified agent installer. The credentials for the SSH
connection should be contained in the JSON file passed with `--credentials`.

In the event other authentication methods fail, the user will be prompted for the password by the installer libraries.
This may allow for some systems such as two factor to be used however it likely will
be cumbersome on large numbers of nodes.

> This may stop an unattended installation waiting for input. Ensure your credentials are correct.

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
You can increase or decrease this to control the load on your masters and bastion host running the SSH sessions.

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
you can have the bulk install tool copy a script to the agent and execute it
before installing Puppet. That script could setup DNS and NTP.

Use the `--script` option of the CLI to do this as shown below.

```shell
sudo puppet bulk install \
--nodes el_nodes.txt \
--credentials sudo_install.json \
--debug
--script 'setup_prerequisites.sh'
```

This will download the `setup_prerequisites.sh` script to the soon-to-be agent and execute it.

> Note at the time of this writing you may need to build a custom wrapper script to pass this script arguments.

## Windows

### Setup

To use this module for Windows agents, things are a bit different, and you'll need to setup some prerequisites first. You'll need:

1. An existing Windows agent that will act as a Windows bastion.
1. WinRM configured on the Windows bastion and your soon-to-be Windows agents.

> Note: Configuration of WinRM is out-of-scope for this module at this time and must be manually setup prior to attempting to use this tool. This link may help: <https://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx>

This module comes with a PowerShell script, called `Invoke-PuppetAgentInstall.ps1` that will connect to Windows nodes via WinRM and execute
the standard [Simplified Agent installer for Windows](https://docs.puppet.com/pe/latest/install_windows.html#installing-with-pe-package-management)
that comes bundled with Puppet Enterprise. The `Invoke-PuppetAgentInstall.ps1` script is managed on the Windows bastion with the
`pe_bulk_agent_install::windows::bastion` class.

To prepare a Windows bastion, follow these steps, choosing the correct set based on your version of Puppet Enterprise:

#### PE 2016.3.x and higher

1. Apply the `pe_repo::platform::windows_<arch>` class to the Puppet master and run Puppet. This will prepare the Puppet agent MSI package and the Simplified Agent Installer for Windows.
1. Apply the `pe_bulk_agent_install::windows::bastion` class to the Windows bastion server. This creates the WinRM installer script (by default, at `C:\Windows\Temp\Invoke-PuppetAgentInstall.ps1`).

#### PE 2016.2.x and lower

1. Apply the `pe_repo::platform::windows_<arch>` class to the Puppet master and run Puppet. This will prepare the Puppet agent MSI package.
1. Apply the `pe_bulk_agent_install::windows::master` class to the Puppet master and run Puppet. This will prepare a copy of the Simplified Agent Installer for Windows.
1. Apply the `pe_bulk_agent_install::windows::bastion` class to the Windows bastion server. This creates the WinRM installer script (by default, at `C:\Windows\Temp\Invoke-PuppetAgentInstall.ps1`).

> Note: The Simplified Agent Installer for Windows was added in PE 2016.3.0, hence the additional step for older versions.

### Usage

Below are examples of using the `Invoke-PuppetAgentInstall.ps1` script in various scenarios.

See the `pe_bulk_agent_install::windows::bastion` [class documentation](#pe_bulk_agent_installwindowsbastion) for how to customize the Windows bastion.

See the WinRM Install Script documentation for options that can be passed into the script.

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

Placing the FQDN of each of the respective agents in a file called `agents.txt` in the same directory as the script.

```PowerShell
.\Invoke-PuppetAgentInstall.ps1 -PMHostname master.puppet.vm
```

#### Multiple agents (using provided file)

Placing the FQDN of each of the respective agents in a file of your choosing then referencing said file with the `FilePath` argument.

```PowerShell
.\Invoke-PuppetAgentInstall.ps1 -FilePath C:\ProgramData\nodes_list.txt -PMHostname master.puppet.vm
```

### Caveats

#### Domain Member vs Standalone System

Regardless if the system running the remote script is a domain member or a standalone system, an entry for the each remote system will be created in the [Trusted Hosts](https://msdn.microsoft.com/en-us/library/aa384372.aspx) file.

If this is not a desired result, at the completion of the distributed install script execution you can clean out the [Trusted Hosts](https://msdn.microsoft.com/en-us/library/aa384372.aspx) file.  One method to complete this task programmatically is as follows:

[Use PowerShell to clear the Trusted Hosts file](https://blogs.technet.microsoft.com/heyscriptingguy/2013/11/29/powertip-use-powershell-to-clear-the-trusted-hosts-file/)

---

## Command Line Options

The bulk installer accepts options from the command line as shown below.

### `--credentials=`

The relative or absolute path to a JSON file containing the credentials information.

* Default: `bulk_install.json`

### `--sudo`

A boolean flag that specifies weather or not to run the installation scripts with `sudo` on Linux/Unix hosts.

Sudo is automatically used if the credentials hash contains a `sudo_password` key or a non root username.

### `--threads=`

The number of threads to use for concurrent agent installations.

* Default: Number of processors times 2.

### `--script=`

The name of the Puppet Enterprise agent installation script to run by default.

* Default: `install.bash`

### `--nodes=`

The relative or absolute path to a new line separated file containing node names to install Puppet on.

* Default: `nodes.txt`

## Class Usage

### `pe_bulk_agent_install::windows::bastion`

This class is expected to be installed on a Windows node that has had Puppet
manually installed. This "bastion" host will connect to unprovisioned Windows nodes.

#### `master`

* Type: `String`
* Default: `$::settings::server`

The hostname of the Puppet master where the client will register its certificate.

#### `master_port`

* Type: `Integer[0,65535]`
* Default: `8140`

The port number that puppetserver is listening on.

#### `scripts_install_location`

* Type: `String`
* Default: `C:/Windows/Temp`

The directory to put the `Invoke-PuppetAgentInstall.ps1` WinRM install script on the Windows bastion.

#### `script_name`

* Type: `String`
* Default: `install.ps1`

The name of the simplified agent install script Invoke-PuppetAgentInstall will attempt to execute.

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

