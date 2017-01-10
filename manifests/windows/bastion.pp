# Class: pe_bulk_agent_install::bastion
# ===========================
#
# This class is responsible for placing all Windows client-side bulk agent install scripts
# on a bastion Windows server.
#
# Parameters
# ----------
# @param master                   [String]         FQDN of Puppet Master.  Needed to populate PowerShell template scripts.
# @param master_port              Integer[0,65535] Network port associated with master_ip serving PowerShell template scripts. Defaults to 8140 (Puppetserver).
# @param script_name              String           The name of the agent install Powershell script. Defaults to 'install.ps1'.
# @param scripts_install_location [String]   			 Directory on the Bastion that will contain the bulk agent install scripts. Defaults to C:\Windows\Temp.
#
class pe_bulk_agent_install::windows::bastion (
  String           $master                   = $::settings::server,
  Integer[1,65535] $master_port              = 8140,
  String           $script_name              = 'install.ps1',
  String           $scripts_install_location = 'C:/Windows/Temp',
) {

  validate_absolute_path($scripts_install_location)

  # Template uses:
  # @master, @master_port, @script_name, @scripts_install_location
  file { 'Windows Puppet Agent Bulk Installer':
    ensure  => file,
    path    => "${scripts_install_location}/Invoke-PuppetAgentInstall.ps1",
    content => template('pe_bulk_agent_install/Invoke-PuppetAgentInstall.ps1.erb'),
  }

}

