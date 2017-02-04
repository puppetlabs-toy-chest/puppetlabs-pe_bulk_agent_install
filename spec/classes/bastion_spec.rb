require 'spec_helper'

describe 'pe_bulk_agent_install::windows::bastion' do
  before do
    Puppet.settings[:server] = 'puppet.master.local'
  end

  context 'on Windows with custom parameters' do
    let(:facts) do
      {
        os: { family: 'windows' }
      }
    end

    let(:params) do
      {
        # Need to set the location to a POSIX path for the spec test to work:
        # https://github.com/rodjek/rspec-puppet/issues/192
        scripts_install_location: '/tmp',
        master_port:              9999,
        script_name:              'meow.ps1'
      }
    end

    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_file('Windows Puppet Agent Bulk Installer').with_ensure('file') }
    it { is_expected.to contain_file('Windows Puppet Agent Bulk Installer').with_path('/tmp/Invoke-PuppetAgentInstall.ps1') }
    it { is_expected.to contain_file('Windows Puppet Agent Bulk Installer').with_content(%r{puppet\.master\.local}) }
    it { is_expected.to contain_file('Windows Puppet Agent Bulk Installer').with_content(%r{9999}) }
    it { is_expected.to contain_file('Windows Puppet Agent Bulk Installer').with_content(%r{meow\.ps1}) }
  end

  context 'on a non-Windows server' do
    let(:facts) do
      {
        os: { family: 'RedHat' }
      }
    end

    let(:params) do
      {
        # Need to set the location to a POSIX path for the spec test to work:
        # https://github.com/rodjek/rspec-puppet/issues/192
        scripts_install_location: '/tmp'
      }
    end

    it { is_expected.to raise_error(%r{class must only be applied to Windows agents}) }
  end
end
