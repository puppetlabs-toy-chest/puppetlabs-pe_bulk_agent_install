require 'puppet_blacksmith/rake_tasks'
require 'puppetlabs_spec_helper/rake_tasks'

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('relative')
PuppetLint.configuration.send('disable_documentation')
PuppetLint.configuration.send('disable_single_quote_string_with_variables')
PuppetLint.configuration.send('disable_140chars')

desc 'Run the metadata_lint and release_checks tests'
task test: [
  :metadata_lint,
  :release_checks
]
