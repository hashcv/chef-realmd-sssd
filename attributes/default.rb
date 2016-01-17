default['realmd-sssd']['join'] = false
default['realmd-sssd']['host-spn'] = node.attribute?('fqdn') ? node['fqdn'] : node['machinename']

default['realmd-sssd']['packages'] = [ 'realmd', 'sssd' ]
case node['platform_family']
when 'debian'
  default['realmd-sssd']['debian-mkhomedir-umask'] = '0022'
  default['realmd-sssd']['packages'].push('krb5-user')
  if platform?('ubuntu')
    default['realmd-sssd']['packages'].push('packagekit')
  end
when 'rhel'
  default['realmd-sssd']['packages'].push('krb5-workstation')
when 'fedora'
  default['realmd-sssd']['packages'].
    push(['krb5-workstation', 'polkit', 'PackageKit', 'crypto-policies >= 20151104']).
    flatten!
end

default['realmd-sssd']['password-auth'] = false
default['realmd-sssd']['ldap-key-auth']['enable'] = false
default['realmd-sssd']['ldap-key-auth']['cidr'] = []

if node['realmd-sssd']['password-auth']
  force_default['openssh']['server']['password_authentication'] = 'yes'
elsif node['realmd-sssd']['ldap-key-auth']['enable']
  match = {}
  node['realmd-sssd']['ldap-key-auth']['cidr'].each do |network|
    match.merge!({
      "Address #{network}" => {
        'password_authentication' => 'yes',
        'AuthorizedKeysCommand' => '/usr/bin/sss_ssh_authorizedkeys',
	'AuthorizedKeysCommandUser' => 'nobody'
      }
    })
  end
  match.merge!({
    "Address *,#{node['realmd-sssd']['ldap-key-auth']['cidr'].
      map { |whitelist| "!#{whitelist}" }.
      join(',')}" => { 'password_authentication' => 'no' }
  })
  force_default['openssh']['server']['match'] = match
end

default['realmd-sssd']['config'] = {
  '[sssd]' => {
    'config_file_version' => ['2'],
    'services'=> ['nss', 'pam', 'ssh', 'sudo'],
    'domains' => ['LOCAL']
  },
  '[nss]' => {
    'filter_users' => ['root', 'named', 'avahi', 'haldaemon', 'dbus',
                       'radiusd', 'news', 'nscd', 'centos', 'ubuntu']
  },
  '[pam]' => {},
  '[ssh]' => {},
  '[sudo]' => {},
  '[domain/LOCAL]' => {
    'enumerate' => ['true'],
    'min_id' => ['500'],
    'max_id' => ['999'],
    'id_provider' => ['local'],
    'auth_provider' => ['local']
  }
}
default['realmd-sssd']['extra-config'] = {}

# databag/vault-name
# id: vault-item
# computer-ou:
# password:
# realm:
# username:
default['realmd-sssd']['vault-name'] = 'realmd-sssd'
default['realmd-sssd']['vault-item'] = 'realm'
