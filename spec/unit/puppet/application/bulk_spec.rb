require 'spec_helper'
require 'puppet/application/bulk'

describe Puppet::Application::Bulk do
  it { is_expected.to be_a_kind_of Puppet::Application::FaceBase }
end
