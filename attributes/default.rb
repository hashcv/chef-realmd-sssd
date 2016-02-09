default['realmd-sssd']['join'] = false
default['realmd-sssd']['host-spn'] = node.attribute?('fqdn') ? node['fqdn'] : node['machinename']

default['realmd-sssd']['packages'] = [ 'realmd' ]
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
  default['realmd-sssd']['packages'].push(['krb5-workstation', 'polkit',
    'PackageKit', 'samba-common-tools']).flatten!
  if node['platform_version'].to_f >= 23
    default['realmd-sssd']['packages'].push('crypto-policies >= 20151104-1.gitf1cba5f')
  end
end

default['realmd-sssd']['password-auth'] = false
default['realmd-sssd']['ldap-key-auth']['enable'] = false
default['realmd-sssd']['ldap-key-auth']['cidr'] = []

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
