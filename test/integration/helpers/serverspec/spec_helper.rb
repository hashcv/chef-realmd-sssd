require 'serverspec'
require 'json'

set :backend, :exec

$node = ::JSON.parse(File.read('/tmp/kitchen/chef_node.json'))
data_bag_file = "/tmp/kitchen/data_bags/#{$node['realmd-sssd']['vault-name']}/#{$node['realmd-sssd']['vault-item']}.json"
data_bag = ::JSON.parse(File.read(data_bag_file))
case $node['chef_environment']
when '_default'
  $realm_info = data_bag
else
  $realm_info = data_bag[$node['chef_environment']]
end
