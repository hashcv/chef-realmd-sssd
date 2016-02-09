#
# Cookbook Name:: realmd-sssd
# Recipe:: default
#
# Copyright (C) 2016 John Bartko
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

extend Chef::Util::Selinux
chef_gem 'deep_merge' do
  compile_time true if respond_to?(:compile_time)
end

case node['platform_family']
when 'debian'
  include_recipe 'apt'
  # no Debian packages provide the private dir
  directory '/var/lib/samba' do
    owner 'root'
    group 'root'
    mode '0755'
  end
  directory '/var/lib/samba/private' do
    owner 'root'
    group 'root'
    mode '0700'
  end
when %r{fedora|rhel}
  include_recipe 'yum'
  include_recipe 'yum::dnf_yum_compat' if platform_family?('fedora')
end

package 'sssd'

if node['realmd-sssd']['join']
  node['realmd-sssd']['packages'].each do |pkg|
    package pkg do
      provider Chef::Provider::Package::Yum if node.platform_family?('fedora')
    end
  end
  require 'deep_merge'

  if node['realmd-sssd']['password-auth']
    node.default['openssh']['server']['password_authentication'] = 'yes'
  elsif node['realmd-sssd']['ldap-key-auth']['enable']
    match = {}
    match.merge!({
      "Address #{node['realmd-sssd']['ldap-key-auth']['cidr'].join(',')}" => {
        'AuthorizedKeysCommand' => '/usr/bin/sss_ssh_authorizedkeys',
        'AuthorizedKeysCommandUser' => 'nobody',
        'PasswordAuthentication' => 'yes'
      },
      "Address *,#{node['realmd-sssd']['ldap-key-auth']['cidr'].
        map { |whitelist| "!#{whitelist}" }.
        join(',')}" => { 'password_authentication' => 'no' }
    })
    node.default['openssh']['server']['match'] = match
  end

  include_recipe 'chef-vault'
  include_recipe 'openssh'

  begin
    realm_info = chef_vault_item_for_environment(node['realmd-sssd']['vault-name'],
                                                 node['realmd-sssd']['vault-item'])
    realm_info = realm_info.empty? ?
      chef_vault_item(node['realmd-sssd']['vault-name'], node['realmd-sssd']['vault-item']) :
      realm_info.select { |key| %w[computer-ou password realm username].include? key }
  rescue Exception => e
    Chef::Application.fatal!(e.to_s)
  end

  domain_config = {
    '[sssd]' => { 'domains' => [ realm_info['realm'] ]},
    "[domain/#{realm_info['realm']}]" => {
      'ad_domain' => [ realm_info['realm'] ],
      'krb5_realm' => [ realm_info['realm'].upcase ],
      'realmd_tags' => [ 'manages-system joined-with-samba'],
      'cache_credentials' => [ 'True' ],
      'id_provider' => [ 'ad' ],
      'krb5_store_password_if_offline' => [ 'True' ],
      'default_shell' => [ '/bin/bash' ],
      'ldap_id_mapping' => [ 'True' ],
      'use_fully_qualified_names' => [ 'True' ],
      'fallback_homedir' => [ '/home/%d/%u' ],
      'access_provider' => [ 'ad' ]
    }
  }

  merged_config = Chef::Mixin::DeepMerge.deep_merge(node['realmd-sssd']['extra-config'],
    domain_config.deep_merge(node['realmd-sssd']['config']))
else
  merged_config = Chef::Mixin::DeepMerge.deep_merge(node['realmd-sssd']['extra-config'], node['realmd-sssd']['config'])
end

if node['realmd-sssd']['join']

  if selinux_enabled?
    include_recipe 'selinux'
    include_recipe 'selinux_policy::install'

    selinux_policy_module 'sssd-samba-socket-create' do
      content <<-eos
        module sssd-samba-socket-create 1.0;

        require {
          type samba_net_t;
          type samba_var_t;
          class sock_file create;
        }

        #============= samba_net_t ==============
        allow samba_net_t samba_var_t:sock_file create;
      eos
      action :deploy
    end
  end

  bash "join #{realm_info['realm']} realm" do
    user 'root'
    code <<-EOT.gsub(/^\s+/, '').sub(/\n$/, '')
    echo -n '#{realm_info['password']}' | realm join -v --unattended #{"--user-principal 'HOST/#{node['realmd-sssd']['host-spn']}@#{realm_info['realm']}'" unless node['realmd-sssd']['host-spn'].empty?} #{"--computer-ou '#{realm_info['computer-ou']}'" unless realm_info['computer-ou'].empty?} -U #{realm_info['username']} #{realm_info['realm']}
    EOT
    not_if "klist -k | grep -qi '@#{realm_info['realm']}'"
    notifies :create, 'template[/etc/sssd/sssd.conf]', :immediately
  end

  case node['platform_family']
    when 'debian'
      template '/usr/share/pam-configs/mkhomedir' do
        source 'mkhomedir.erb'
        owner 'root'
        group 'root'
        mode '0644'
        notifies :run, 'execute[pam-auth-update]'
      end
      execute 'pam-auth-update' do
        command 'pam-auth-update --package'
        action :nothing
      end
    when 'fedora', 'rhel'
      bash 'authconfig' do
        user 'root'
        code 'authconfig --enablesssd --enablesssdauth --enablemkhomedir --update'
        not_if 'grep -q pam_oddjob_mkhomedir /etc/pam.d/*'
      end

      nsswitch = Chef::Util::FileEdit.new('/etc/nsswitch.conf')
      sudoers_line = 'sudoers: files sss # managed by Chef'
      ruby_block 'nssswitch' do
        block do
          Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
          nsswitch.write_file
        end
	      only_if {
          nsswitch.search_file_replace_line(/sudoers(?!#{sudoers_line[/:.*/]}$)/, sudoers_line) || \
            nsswitch.insert_line_if_no_match(/^sudoers: +files sss/, sudoers_line)
        }
      end
  end

  %w[nss pam ssh sudo].each do |pipe|
    bash "restart service[sssd] on missing #{pipe} pipe" do
      code '/bin/true'
      creates "/var/lib/sss/pipes/#{pipe}"
      notifies :restart, 'service[sssd]'
    end
  end

end

template '/etc/sssd/sssd.conf' do
  source 'sssd.conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    :config => merged_config
  })
  notifies :restart, 'service[sssd]', :immediately
end

service 'sssd' do
  supports :status => true, :restart => true
  action [:enable, :start]
end
