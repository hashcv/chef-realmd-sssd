require 'serverspec'
require 'json'

set :backend, :exec

$node = ::JSON.parse(File.read('/tmp/serverspec/node.json'))
$realm_info = ::JSON.parse(File.read("/tmp/kitchen/data_bags/#{$node['realmd-sssd']['vault-name']}/#{$node['realmd-sssd']['vault-item']}.json"))
