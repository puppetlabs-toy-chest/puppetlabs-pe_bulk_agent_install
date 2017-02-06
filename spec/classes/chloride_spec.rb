require 'spec_helper'

describe 'pe_bulk_agent_install::chloride' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'when declared with all defaults' do
        it { is_expected.to compile }

        it { is_expected.to contain_package('chloride').with_ensure('present') }
        it { is_expected.to contain_package('chloride').with_provider('puppet_gem') }
        it { is_expected.to contain_package('chloride').with_source(nil) }
      end
    end
  end
end
