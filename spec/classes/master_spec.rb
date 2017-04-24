require 'spec_helper'

describe 'pe_bulk_agent_install::windows::master' do
  let(:pre_condition) { "class pe_repo( $master = 'puppet' ) {}" }

  context 'on a Puppet Enterprise master older than 2016.3' do
    let(:facts) do
      {
        pe_server_version: '2015.2.3',
        settings: { masterport: '8140' }
      }
    end

    context 'with default parameters' do
      it { is_expected.to compile }
      it { is_expected.to contain_class('pe_bulk_agent_install::windows::master') }

      it { is_expected.to contain_file('/opt/puppetlabs/server/data/packages/public/2015.2.3/install.ps1').with_content(%r{^\$server\s+=\s+'puppet'$}) }
      it { is_expected.to contain_file('/opt/puppetlabs/server/data/packages/public/2015.2.3/install.ps1').with_content(%r{^\$port\s+=\s+'8140'$})  }

      it { is_expected.to contain_class('pe_bulk_agent_install::chloride') }
      it { is_expected.to contain_class('pe_repo').that_comes_before('Class[pe_bulk_agent_install::windows::master]') }
    end

    context 'with install_chloride set to false' do
      let(:params) do
        {
          install_chloride: false
        }
      end

      it { is_expected.to compile }
      it { is_expected.to contain_class('pe_bulk_agent_install::windows::master') }
      it { is_expected.not_to contain_class('pe_bulk_agent_install::chloride') }
    end
  end

  context 'on a non-Puppet Enterprise master' do
    it { is_expected.to raise_error(%r{should only be applied to a Puppet Master}) }
  end

  context 'on a Puppet Enterprise master that already has an install.ps1' do
    let(:pre_condition) { "file { '/opt/puppetlabs/server/data/packages/public/2016.5.1/install.ps1': }" }

    let(:facts) do
      {
        pe_server_version: '2016.5.1',
        settings: { masterport: '8140' }
      }
    end

    context 'with default parameters' do
      it { is_expected.to compile }
      it { is_expected.not_to contain_class('pe_repo') }
    end
  end
end
