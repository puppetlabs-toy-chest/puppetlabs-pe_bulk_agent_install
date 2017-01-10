# Class: pe_bulk_agent_install::windows::master
# ===========================
#
# This class is responsible for creating the install.ps1 Puppet Agent install script on the master.
# This class is here for backwards compatability with Puppet masters older than 2016.3.x as the pe_repo
# module used in those versions doesn't have a native Windows agent installer.
#
# If using PE 2016.3.x or higher, this class does not need to be used.
#
# Parameters
# ----------
#
# @param public_dir [String] The directory on the master to put the install.ps1 script. Defaults to '/opt/puppetlabs/server/data/packages/public'.
#
class pe_bulk_agent_install::windows::master (
  $public_dir = '/opt/puppetlabs/server/data/packages/public',
) {

  validate_absolute_path($public_dir)

  # In PE 2016.3.x and higher, the pe_repo module has its own version of this file.
  # We are wrapping this entire thing in an if ! defined() to prevent our version from being
  # used if pe_repo tries to make it.
  # This logic isn't fool proof because it's based on parse order, but it's close enough.
  if ! defined(File["${public_dir}/${::pe_server_version}/install.ps1"]) {

    require pe_repo

    file { "${public_dir}/${::pe_server_version}/install.ps1":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/install.ps1.erb"),
    }

  }

}

