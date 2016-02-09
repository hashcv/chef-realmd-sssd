source 'https://supermarket.chef.io'

metadata

cookbook 'apt'
cookbook 'chef-vault'
cookbook 'openssh', '~> 1.6.0'
cookbook 'selinux', git: 'https://github.com/jbartko/selinux.git', branch: 'feature/add-serverspec'
cookbook 'selinux_policy', '~> 0.9.3'
cookbook 'yum', '~> 3.9.0'
group :integration do
  cookbook 'export_node', path: 'test/fixtures/cookbooks/export_node'
  cookbook 'os_floating_lo', '~> 0.1.2'
  cookbook 'realmd-sssd-tester', path: 'test/fixtures/cookbooks/realmd-sssd-tester'
  cookbook 'resolver'
end
