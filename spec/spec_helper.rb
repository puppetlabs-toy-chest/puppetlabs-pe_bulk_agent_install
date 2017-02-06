require 'puppetlabs_spec_helper/module_spec_helper'

require 'rspec-puppet-facts'
include RspecPuppetFacts

if Puppet.version.to_f >= 4.5
  RSpec.configure do |c|
    c.before :each do
      Puppet.settings[:strict] = :error
    end
  end
end
