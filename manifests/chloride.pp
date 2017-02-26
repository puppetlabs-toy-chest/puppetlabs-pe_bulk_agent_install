# Manage the chloride gem for the PE Bulk Agent Install tool
#
# @param gem_provider The provider used to install the chloride gem.
# @param gem_source The gem source to use when installing gems.
#
class pe_bulk_agent_install::chloride (
  String           $gem_provider = 'puppet_gem',
  Optional[String] $gem_source   = undef,
) {

  package {'chloride':
    ensure   => 'present',
    provider => $gem_provider,
    source   => $gem_source,
  }

}
