source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  gem 'puppet-lint',                        :require => false
  gem 'metadata-json-lint',                 :require => false
  gem 'puppet_facts',                       :require => false
  gem 'puppet-blacksmith', '>= 3.4.0',      :require => false
  gem 'puppetlabs_spec_helper', '>= 1.2.1', :require => false
  gem 'rspec-puppet', '>= 2.3.2',           :require => false
  gem 'rspec-puppet-facts',                 :require => false
  gem 'mocha', '< 1.2.0',                   :require => false
  gem 'simplecov',                          :require => false
  gem 'parallel_tests', '< 2.10.0',         :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'parallel_tests',                     :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.0.0')
  gem 'rubocop', '0.41.2',                  :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'rubocop',                            :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.0.0')
  gem 'rubocop-rspec', '~> 1.9.0',          :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
  gem 'pry',                                :require => false
  gem 'json_pure', '<= 2.0.1',              :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'fast_gettext', '1.1.0',              :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.1.0')
  gem 'fast_gettext',                       :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
  gem 'CFPropertyList',                     :require => false
end

ENV['PUPPET_VERSION'].nil? ? puppetversion = '~> 4.8.0' : puppetversion = ENV['PUPPET_VERSION'].to_s
gem 'puppet', puppetversion, :require => false, :groups => [:test]
