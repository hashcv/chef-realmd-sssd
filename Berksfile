source 'https://supermarket.chef.io'

metadata

cookbook 'apt'
cookbook 'chef-vault'
cookbook 'openssh', '~> 1.6.0'
cookbook 'selinux', git: 'https://github.com/jbartko/selinux.git', branch: 'feature/add-serverspec'
cookbook 'selinux_policy', '~> 0.9.3'
cookbook 'yum', '~> 3.9.0'
group :integration do
  cookbook 'hostname'
  cookbook 'test-helper', path: 'test/fixtures/cookbooks/test-helper'
  cookbook 'resolver'
end
