source ENV['GEM_SOURCE'] || "https://rubygems.org"

# Find a location or specific version for a gem. place_or_version can be a
# version, which is most often used. It can also be git, which is specified as
# `git://somewhere.git#branch`. You can also use a file source location, which
# is specified as `file://some/location/on/disk`.
def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place_or_version =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place_or_version, { :require => false }]
  end
end

group :development do
  gem 'puppet-lint',                        :require => false
  gem 'metadata-json-lint',                 :require => false, :platforms => 'ruby'
  gem 'puppet_facts',                       :require => false
  gem 'puppet-blacksmith', '>= 3.4.0',      :require => false, :platforms => 'ruby'
  gem 'puppetlabs_spec_helper', '>= 1.2.1', :require => false
  gem 'rspec-puppet', '>= 2.3.2',           :require => false
  gem 'rspec-puppet-facts',                 :require => false, :platforms => 'ruby'
  gem 'mocha', '< 1.2.0',                   :require => false
  gem 'simplecov',                          :require => false, :platforms => 'ruby'
  gem 'parallel_tests', '< 2.10.0',         :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'parallel_tests',                     :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.0.0')
  gem 'rubocop', '0.41.2',                  :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'rubocop',                            :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.0.0')
  gem 'rubocop-rspec', '~> 1.6',            :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.3.0')
  gem 'pry',                                :require => false
  gem 'json_pure', '<= 2.0.1',              :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'fast_gettext', '1.1.0',              :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.1.0')
  gem 'fast_gettext',                       :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
end

gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])
