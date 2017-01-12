require 'spec_helper'

describe "pe_bulk_agent_install::windows::bastion" do

  before :each do
    Puppet.settings[:server] = 'puppet.master.local'
  end

  context "on Windows with custom parameters" do

    let(:facts) {{
      :os => { :family => 'windows' }
    }}

    let(:params) {{
      # Need to set the location to a POSIX path for the spec test to work:
      # https://github.com/rodjek/rspec-puppet/issues/192
      :scripts_install_location => '/tmp',
      :master_port              => 9999,
      :script_name              => 'meow.ps1'
    }}

    it { is_expected.to compile.with_all_deps }

    it { should contain_file('Windows Puppet Agent Bulk Installer').with_ensure('file') }
    it { should contain_file('Windows Puppet Agent Bulk Installer').with_path('/tmp/Invoke-PuppetAgentInstall.ps1') }
    it { should contain_file('Windows Puppet Agent Bulk Installer').with_content(/puppet\.master\.local/) }
    it { should contain_file('Windows Puppet Agent Bulk Installer').with_content(/9999/) }
    it { should contain_file('Windows Puppet Agent Bulk Installer').with_content(/meow\.ps1/) }

  end

  context "on a non-Windows server" do

    let(:facts) {{
      :os => { :family => 'RedHat' }
    }}

    let(:params) {{
      # Need to set the location to a POSIX path for the spec test to work:
      # https://github.com/rodjek/rspec-puppet/issues/192
      :scripts_install_location => '/tmp',
    }}

    it { should raise_error(/class must only be applied to Windows agents/) }

  end
end

