# required to verify SSH key-based authentication
file '/root/integration-key' do
  content "-----BEGIN EC PRIVATE KEY-----\nMIHcAgEBBEIBGN7vJ6OqD2Mhm1slVpnQ0M81tdxhsfP4+eWe1sSYl9ZEth3PioNz\n9qN7pxLHUdSlc24PhcWcFaZ/a5qlmYss7EmgBwYFK4EEACOhgYkDgYYABAHJ3sWS\nWZfjEw3mGCqIksxa8mRl5X3LEvLuLuMtIv/U9Efaku/lsLNNsmUiQ2x/8+k4Tumm\nCCR37vTnmsdB+BljdQFOOrq7FXJjaAQrHqIXDc/B2X5HIWveG6KbOnPluSLdenrr\nzm1CpZn5WHS2HePyS1+2OEalX+JZsStCVwZKlVTHJw==\n-----END EC PRIVATE KEY-----\n"
  owner 'root'
  group 'root'
  mode '0600'
  sensitive true
end

# required for Centos 7 sshpass
if platform?('centos')
  package 'epel-release'
end

# required to verify SSH password authentication -- not recommended!
package 'sshpass'

# required to verify dynamic DNS
case node['platform_family']
when 'rhel'
  package 'bind-utils'
when 'debian'
  package 'dnsutils'
end
