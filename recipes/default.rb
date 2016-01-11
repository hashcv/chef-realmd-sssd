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

chef_gem 'deep_merge' do
  compile_time true if respond_to?(:compile_time)
end

case node['platform_family']
when 'debian'
  include_recipe 'apt'
when 'rhel'
  include_recipe 'yum'
end

node['realmd-sssd']['packages'].each do |pkg|
  package pkg
end

if node['realmd-sssd']['join']
  require 'deep_merge'
  include_recipe 'chef-vault'
  include_recipe 'openssh'
  begin
    realm_info = chef_vault_item(node['realmd-sssd']['vault-name'],
                                 node['realmd-sssd']['vault-item'])
  rescue Exception => e
    Chef::Application.fatal!(e.to_s)
  end

  merged_config = Chef::Mixin::DeepMerge.merge({
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
  }}.deep_merge!(node['realmd-sssd']['extra-config']), node['realmd-sssd']['config'])
else
  merged_config = Chef::Mixin::DeepMerge.deep_merge!(node['realmd-sssd']['extra-config'], node['realmd-sssd']['config'])
end

if node['realmd-sssd']['join']
  bash "join #{realm_info['realm']} realm" do
    user 'root'
    code <<-EOT.gsub(/^\s+/, '').sub(/\n$/, '')
    echo '#{realm_info['password']}' | realm join -v --unattended #{"--computer-ou '#{realm_info['computer-ou']}'" unless realm_info['computer-ou'].empty?} -U #{realm_info['username']} #{realm_info['realm']}
    EOT
    not_if "klist -k | grep -qi '@#{realm_info['realm']}'"
  end

  if node['platform_family'] == 'debian'
    template '/usr/share/pam-configs/mkhomedir' do
      source 'mkhomedir.erb'
      owner 'root'
      group 'root'
      mode '0644'
      notifies :run, "execute[pam-auth-update]"
    end

    execute 'pam-auth-update' do
      command 'pam-auth-update --package'
      action :nothing
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
  notifies :restart, 'service[sssd]', :immediate
end

service 'sssd' do
  supports :status => true, :restart => true
  action [:enable, :start]
end

# vim: set ts=2 sw=2 et ft=ruby:
