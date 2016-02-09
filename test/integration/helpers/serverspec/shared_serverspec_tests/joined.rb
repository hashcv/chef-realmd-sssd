require 'rspec'
require 'spec_helper'
require 'ipaddr'

require_relative '../shared_serverspec_tests/default.rb'

RSpec.shared_examples 'joined' do
  include_examples 'default'

  describe package('realmd') do
    it { should be_installed }
  end

  [ 'nss', 'pam', 'ssh', 'sudo' ].
    each do |pipe|
      describe file("/var/lib/sss/pipes/#{pipe}") do
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
        it { should be_writable.by('others') }
        it { should be_mode 666 }
        it { should be_socket }
      end
    end

  # We sleep until the test user is "resolvable", up to five minutes,
  # due to not having an easy way of actually knowing if SSSD is online yet:
  #   https://fedorahosted.org/sssd/ticket/385
  describe command("fail_count=0; while ! id #{$realm_info['username']}@#{$realm_info['realm']}; do sleep 5; fail_count=$(expr $fail_count + 1); if [ $fail_count -gt 60 ]; then exit 1; fi; done") do
    its(:exit_status) { should eq 0 }
  end

  describe user("#{$realm_info['username']}@#{$realm_info['realm']}") do
    it { should exist }
  end

  describe command("/usr/bin/sss_ssh_authorizedkeys #{$realm_info['username']}@#{$realm_info['realm']}") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^(ssh-)?([rd]|ecd)sa/) }
  end

  # Used just to create the directory if it doesn't already exist
  describe command("/bin/su #{$realm_info['username']}@#{$realm_info['realm']} -c /bin/true") do
    its(:exit_status) { should eq 0 }
  end

  describe file("/home/#{$realm_info['realm']}/#{$realm_info['username']}") do
    it { should be_directory }
  end

  # Verify LDAP sudoers integration
  describe file('/etc/nsswitch.conf') do
    its(:content) { should match(/^sudoers: +files sss/) }
  end

  describe command("/usr/bin/sudo -U #{$realm_info['username']}@#{$realm_info['realm']} -l") do
    its(:stdout) { should match(/User #{$realm_info['username']}@#{$realm_info['realm']} may run the following commands on/) }
  end

  # Verify LDAP/Kerberos password authentication
  ENV['SSHPASS'] = "#{$realm_info['password']}"
  describe command("fail_count=0; while ! sshpass -e ssh -v -o StrictHostKeyChecking=no -o PubKeyAuthentication=no -l #{$realm_info['username']}@#{$realm_info['realm']} ::1 2>&1 -- /bin/true; do sleep 5; fail_count=$(expr $fail_count + 1); if [ $fail_count -gt 5 ]; then exit 1; fi; done") do
    its(:exit_status) { should eq 0 }
  end

  # Verify LDAP SSH public key integration
  describe command("ssh -v -o StrictHostKeyChecking=no -o PasswordAuthentication=no -i /root/integration-key -l #{$realm_info['username']}@#{$realm_info['realm']} ::1 2>&1 -- /bin/true") do
    its(:exit_status) { should eq 0 }
  end

  describe file("/home/#{$realm_info['realm']}/#{$realm_info['username']}/.ssh/authorized_keys") do
    it { should_not exist }
  end

  if $node['realmd-sssd']['extra-config']["[domain/#{$realm_info['realm']}]"]['dyndns_iface'].to_s.empty?
    my_ip = ::IPAddr.new($node['ipaddress'])
  else
    my_domain = "[domain/#{$realm_info['realm']}]"
    my_dyndns_iface = $node['realmd-sssd']['extra-config'][my_domain]['dyndns_iface']
    my_dyndns_addr = $node['network']['interfaces'][my_dyndns_iface]['addresses'].keys[0]
    my_ip = ::IPAddr.new(my_dyndns_addr)
  end

  # Verify dynamic foward DNS
  dns_forward_regexp = Regexp.new("^#{$node['realmd-sssd']['host-spn']}.*#{my_ip.to_s}$")
  describe command("dig #{$node['realmd-sssd']['host-spn']}") do
    its(:stdout) { should match(/status: NOERROR/) }
    its(:stdout) { should match(dns_forward_regexp) }
  end

  # Verify dynamic reverse DNS
  # Test only the realm -- some drivers will create conflicting PTR records
  dns_reverse_regexp = Regexp.new("^#{my_ip.reverse}.*#{$realm_info['realm']}\.$")
  describe command("dig -x #{my_ip.to_s}") do
    its(:stdout) { should match(/status: NOERROR/) }
    its(:stdout) { should match(dns_reverse_regexp) }
  end
end
