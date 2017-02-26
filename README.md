# PE Bulk Agent Install

[![License](https://img.shields.io/github/license/puppetlabs/puppetlabs-pe_bulk_agent_install.svg)](https://github.com/puppetlabs/puppetlabs-pe_bulk_agent_install/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-pe_bulk_agent_install.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-pe_bulk_agent_install)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppetlabs/pe_bulk_agent_install.svg)](https://forge.puppetlabs.com/puppetlabs/pe_bulk_agent_install)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppetlabs/pe_bulk_agent_install.svg)](https://forge.puppetlabs.com/puppetlabs/pe_bulk_agent_install)

Puppet toolkit for rapidly installing Puppet agents in Puppet Enterprise

## Table of Contents

* [Overview](#overview)
* [Module State](#module-state)
* [Command Line Usage](#command-line-usage)
* [Installation Requirements](#installation-requirements)
* [Simple SSH agent deployment](#simple-ssh-agent-deployment)
  * [Simple SSH agent deployment with nodes file](#simple-ssh-agent-deployment-with-nodes-file)
  * [Simple SSH agent deployment with nodes STDIN](#simple-ssh-agent-deployment-with-nodes-stdin)
  * [Multiple thread support](#multiple-thread-support)
* [Credentials](#credentials)
  * [Sudo \+ Password](#sudo--password)
  * [Sudo \+ Private key w/ no passphrase](#sudo--private-key-w-no-passphrase)
  * [Root \+ Private key w/ no passphrase](#root--private-key-w-no-passphrase)
  * [Root \+ Private key w/ passphrase](#root--private-key-w-passphrase)
  * [Puppet Config Arguments and CSR Attributes](#puppet-config-arguments-and-csr-attributes)
* [Fixing DNS and NTP on agent nodes](#fixing-dns-and-ntp-on-agent-nodes)
* [Windows](#windows)
  * [Setup](#setup)
  * [Usage](#usage)
    * [Single\-agent](#single-agent)
    * [Pass Windows credentials](#pass-windows-credentials)
    * [Multiple agents (using agents\.txt)](#multiple-agents-using-agentstxt)
    * [Multiple agents (using provided file)](#multiple-agents-using-provided-file)
  * [Caveats](#caveats)
    * [Domain Member vs Standalone System](#domain-member-vs-standalone-system)
* [Reference](#reference)
  * [Command Line Options](#command-line-options)
  * [Class Usage](#class-usage)
    * [pe\_bulk\_agent\_install::windows::bastion](#pe_bulk_agent_installwindowsbastion)
  * [WinRM Script Arguments](#winrm-script-arguments)
* [Limitations](#limitations)
* [Maintainers](#maintainers)

---

## Overview

This module is used for bulk installs of Puppet Agents on Linux and Windows machines with Puppet Enterprise. It builds on the standard
Simplified Agent Installation process that comes with Puppet Enterprise.

The goal of this module is to accomplish the following tasks, rapidly and remotely, on Linux and Windows nodes:

* Install the Puppet agent
* Start the Puppet Agent

## Module State

**NOTE:** This module started as a Puppet Professional Services toolkit. It is a side project, and it is currently neither officially
maintained nor officially supported by Puppet, Inc. It may not function as expected; however, it is actively used in the wild so issues
are likely to be resolved if found and reported. Have fun!

## Command Line Usage

This module ships a Puppet face, `puppet bulk install`. The face can be used with any
system that supports SSH to allow for the mass installation of Puppet agent nodes using
the simplified installer bundled with Puppet Enterprise.

**Example CLI usage** can be found in the [examples folder](https://github.com/puppetlabs/puppetlabs-pe_bulk_agent_install/tree/master/examples/cli_usage) of this module.

All possible CLI flags can be seen in the [Command Line Options](#command-line-options) section.

For Windows nodes, a separate method that uses a PowerShell script should be used. See [the docs here](#windows).

## Installation Requirements

### Chloride Gem

The Puppet face requires the [chloride](https://rubygems.org/gems/chloride) gem to be in place in the Puppet ruby stack (not puppetserver)
of the node that will be executing the Puppet face. This could be your Puppet master or some other Puppet agent that is able to connect
to the soon-to-be Puppet agents.

Install Chloride using one of these methods:

* Automatically, with Puppet:

  ```puppet
  include pe_bulk_agent_install::chloride
  ```

* Manually, into Puppet's Ruby stack:

  ```shell
  /opt/puppetlabs/puppet/bin/gem install chloride --no-ri --no-rdoc
  ```

> Future versions of Puppet Enterprise (2017'ish) will likely ship with Chloride built-in to Puppet's Ruby stack on the master.

### pe_repo

Because the Bulk Agent Installer face leverages the built-in Simplified Agent Installer of Puppet Enterprise, it's important that the
simplified agent installer is setup accordingly. Namely, make sure that your Puppet master has the correct `pe_repo::platform` classes
applied to it before attempting to run the Bulk Agent Installer.

Documentation for doing this is available here: <https://docs.puppet.com/pe/latest/install_agents.html#install-agents-with-a-different-os-and-architecture-than-the-puppet-master>

## Simple SSH agent deployment

```shell
sudo puppet bulk install unprovisioned-agent1 unprovisioned-agent2  \
                 --credentials ./examples/json/sudo_install.json \
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
--nodes ./examples/el_nodes.txt \
--credentials ./examples/json/sudo_install.json --trace --debug
```

This assumes a file that contains node names with newline character separating each

### Simple SSH agent deployment with nodes STDIN

```shell
#!/bin/bash
printf '%s\n%s\n%s\n' unprovisioned-agent1 unprovisioned-agent2 unprovisioned-agent4 |
sudo puppet bulk install \
--nodes - \
--credentials ./examples/json/sudo_install.json --trace --debug
```

You can build your own custom scripts to add agent nodes to the install list and pass them
in via STDIN. I.e. you can ping the nodes and only echo them if they respond.

### Multiple thread support

`puppet bulk install` supports a `--threads` argument which defaults to the number of processors on the bastion host times 2.
You can increase or decrease this to control the load on your masters and bastion host running the SSH sessions.

## Credentials

Authentication credentials must be specified as a JSON hash and passed in a file to `--credentials`:

```shell
puppet bulk install --credentials bulk_install.json
```

By default, a credentials file named `bulk_install.json` is looked for and parsed if `--credentials` is not used.

The credentials JSON must be a hash containing the following keys:

|  Key Name          |                                Description                                 |
|:-------------------|:---------------------------------------------------------------------------|
| username           | **(required)** Username for the SSH connection to the agent                |
| master             | **(required)** FQDN of the Puppet master                                   |
| sudo\_password     | Password used for SSH login and sudo escalation                            |
| ssh\_key\_file     | Path to SSH private key if using key-based auth                            |
| ssh\_key\_password | SSH passphrase for the private key                                         |
| arguments          | Hash of Puppet configs, CSR attributes, and/or extension requestss         |

### Sudo + Password

```json
{
  "username": "provisioner",
  "sudo_password": "p_4_s_s_w_0_r_d",
  "master" : "pe-201620-master"
}
```

This assumes a user named `provisioner` with sudo access exists on the target agent system. The agent node will run the Simplified
Agent Installer from the Puppet master named pe-201620-master. The master's hostname must be resolvable and reachable by the agent node as
it is used in the yum/apt repos. Ensure your site has proper DNS or /etc/hosts entries configured for the Puppet master.

### Sudo + Private key w/ no passphrase

```json
{
  "username": "provisioner",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "master" : "pe-201620-master"
}
```

This assumes a private key is installed and readable on the machine running the CLI (with no passphrase set), and that it corresponds
to an authorized\_key file on the target host using the username `provisioner` (who has sudo access that doesn't require a password).

### Root + Private key w/ no passphrase

```json
{
  "username": "root",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "master" : "pe-201620-master"
}
```

This assumes a private key is installed and readable on the machine running the CLI (with no passphrase set), and that the key
corresponds to an authorized\_key file on the target agent using the username root.

### Root + Private key w/ passphrase

```json
{
  "username": "root",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "ssh_key_passphrase": "freyjaIscute",
  "master" : "pe-201620-master"
}
```

This assumes a private key is installed and readable on the machine running the CLI (with a passphrase set), and that it corresponds
to an authorized\_key file on the target host using the username root.

### Puppet Config Arguments and CSR Attributes

```json
{
  "username": "root",
  "ssh_key_file": "/root/.ssh/id_rsa",
  "master" : "pe-201620-master",
  "arguments" :
    {
      "agent": { "environment": "development" },
      "custom_attributes": { "challengePassword": "imyourpuppet" },
      "extension_requests": { "pp_role": "gitlab_runner" }
    }
}
```

Using the arguments key of the json file, you can specify puppet.conf settings, CSR attributes, and extension requests. They will be passed to the bash installer as arguments to `-s`.

Refer to the Puppet Enterprise install script docs on possible options that can be specified here:

<https://docs.puppet.com/pe/2016.5/install_agents.html#passing-configuration-parameters-to-the-install-script>

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

See the WinRM Install Script [documentation](#winrm-script-arguments) for options that can be passed into the script.

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

If this is not a desired result, at the completion of the distributed install script execution you can clean out the [Trusted Hosts](https://msdn.microsoft.com/en-us/library/aa384372.aspx) file. One method to complete this task programmatically is as follows:

[Use PowerShell to clear the Trusted Hosts file](https://blogs.technet.microsoft.com/heyscriptingguy/2013/11/29/powertip-use-powershell-to-clear-the-trusted-hosts-file/)

---

## Reference

### Command Line Options

The bulk installer face accepts options from the command line as shown below.

#### `--credentials=`

The relative or absolute path to a JSON file containing the credentials information.

* Default: `bulk_install.json`

#### `--sudo`

A boolean flag that specifies weather or not to run the installation scripts with `sudo` on Linux/Unix hosts.

Sudo is automatically used if the credentials hash contains a `sudo_password` key or a non root username.

#### `--threads=`

The number of threads to use for concurrent agent installations.

* Default: Number of processors times 2.

#### `--script=`

The name of the Puppet Enterprise agent installation script to run by default.

* Default: `install.bash`

#### `--nodes=`

The relative or absolute path to a new line separated file containing node names to install Puppet on.

* Default: `nodes.txt`

### Class Usage

#### `pe_bulk_agent_install::windows::bastion`

This class is expected to be installed on a Windows node that has had Puppet
manually installed. This "bastion" host will connect to unprovisioned Windows nodes.

##### `master`

* Type: `String`
* Default: `$::settings::server`

The hostname of the Puppet master where the client will register its certificate.

##### `master_port`

* Type: `Integer[0,65535]`
* Default: `8140`

The port number that puppetserver is listening on.

##### `scripts_install_location`

* Type: `String`
* Default: `C:/Windows/Temp`

The directory to put the `Invoke-PuppetAgentInstall.ps1` WinRM install script on the Windows bastion.

##### `script_name`

* Type: `String`
* Default: `install.ps1`

The name of the simplified agent install script Invoke-PuppetAgentInstall will attempt to execute.

### WinRM Script Arguments

The WinRM script, `Invoke-PuppetAgentInstall.ps1`, accepts the following command line arguments.

#### `Node`

A comma-separated list of node names to install Puppet on. The node names must be resolvable by the Windows bastion running this script.

Mutually exclusive with the `FilePath` argument.

* Type: `String`
* Default: `$null`

#### `Credential`

The username used to authenticate to the unprovisioned Windows agent.

* Type: `String`
* Default: `$null`

#### `FilePath`

The relative or absolute path to a new-line separated file containing node names to install Puppet on.

Mutually exclusive with the `Node` argument.

* Type: `String`
* Default: `nodes.txt`

#### `LogPath`

The relative or absolute path to the log file used by this script.

* Type: `String`
* Default: `pe_bulk_agent_install.log`

#### `InstallScript`

The name of the Simplified Agent Install script on the Puppet master.

* Type: `String`
* Default: `install.ps1`

#### `InstallDest`

The full path to where the Simplified Agent Install script will be copied to the unprovisioned Windows agent.

* Type: `String`
* Default: `C:\Windows\Temp\install.ps1`

#### `PMHostname`

The FQDN of the Puppet Master that the Windows agent will communicate with.

* Type: `String`
* Default: The FQDN of the Puppet Master that manages the Windows bastion

## Maintainers

This repository is largely the work of the Puppet Professional Services team. It is not officially maintained by Puppet, or any
individual in particular. Issues should be opened in GitHub. Questions should be directed at the individuals responsible for
committing that particular code.

The list of contributors to this module can be found here: <https://github.com/puppetlabs/puppet-pe_bulk_agent_install/graphs/contributors>

