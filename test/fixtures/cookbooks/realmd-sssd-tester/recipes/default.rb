bash "hostnamectl set-hostname #{node['realmd-sssd']['host-spn']}" do
  code "hostnamectl set-hostname #{node['realmd-sssd']['host-spn']}"
  not_if "test \"x$(hostname)\" = \"x#{node['realmd-sssd']['host-spn']}\""
end

if node['resolver']['nameservers'].any? && node['virtualization']['system'] == 'vbox'
  case node['platform_family']
  when %r{fedora|rhel}
    cookbook_file '/etc/dhcp/dhclient-enter-hooks' do
      mode "0755"
    end
  end
end

# required to verify SSH key-based authentication
file '/root/integration-key' do
  content "-----BEGIN EC PRIVATE KEY-----\nMIHcAgEBBEIBGN7vJ6OqD2Mhm1slVpnQ0M81tdxhsfP4+eWe1sSYl9ZEth3PioNz\n9qN7pxLHUdSlc24PhcWcFaZ/a5qlmYss7EmgBwYFK4EEACOhgYkDgYYABAHJ3sWS\nWZfjEw3mGCqIksxa8mRl5X3LEvLuLuMtIv/U9Efaku/lsLNNsmUiQ2x/8+k4Tumm\nCCR37vTnmsdB+BljdQFOOrq7FXJjaAQrHqIXDc/B2X5HIWveG6KbOnPluSLdenrr\nzm1CpZn5WHS2HePyS1+2OEalX+JZsStCVwZKlVTHJw==\n-----END EC PRIVATE KEY-----\n"
  owner 'root'
  group 'root'
  mode '0600'
  sensitive true
end

# dig required to verify dynamic DNS
# epel-release required for Centos 7 sshpass
case node['platform_family']
when 'debian'
  include_recipe 'apt'
  package 'dnsutils'
when %r{fedora|rhel}
  include_recipe 'yum'
  include_recipe 'yum::dnf_yum_compat' if platform_family?('fedora')
  package 'bind-utils'
  package 'epel-release' if platform?('centos')
end

# required to verify SSH password authentication -- not recommended!
package 'sshpass'

# required for kitchen-sync rsync transport
# https://github.com/coderanger/kitchen-sync
include_recipe 'rsync' unless node['virtualization']['system'] == 'vbox'
