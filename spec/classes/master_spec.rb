require 'spec_helper'

describe 'pe_bulk_agent_install::windows::master' do
  let(:pre_condition) { "class pe_repo( $master = 'puppet' ) {}" }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(
          pe_server_version: '2015.2.3',
          settings: { masterport: '8140' }
        )
      end

      context 'with default parameters' do
        it { is_expected.to compile }

        it { is_expected.to contain_file('/opt/puppetlabs/server/data/packages/public/2015.2.3/install.ps1').with_content(%r{^\$server\s+=\s+'puppet'$})  }
        it { is_expected.to contain_file('/opt/puppetlabs/server/data/packages/public/2015.2.3/install.ps1').with_content(%r{^\$port\s+=\s+'8140'$})  }

        it { is_expected.to contain_class('pe_bulk_agent_install::chloride') }
      end

      context 'with install_chloride set to false' do
        let(:params) do
          {
            install_chloride: false
          }
        end

        it { is_expected.to compile }
        it { is_expected.not_to contain_class('pe_bulk_agent_install::chloride') }
      end
    end
  end
end
