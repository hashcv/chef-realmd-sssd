require 'rspec'
require 'serverspec'

RSpec.shared_examples 'default' do
  describe package('sssd') do
    it { should be_installed }
  end

  describe service('sssd') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/sssd/sssd.conf') do
    it { should be_file }
    it { should be_mode 600 }
  end
end
