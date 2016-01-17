source 'https://supermarket.chef.io'

metadata

cookbook 'apt'
cookbook 'chef-vault'
cookbook 'openssh', '~> 1.6.0'
cookbook 'yum', '~> 3.9.0'
group :integration do
  cookbook 'test-helper', path: 'test/fixtures/cookbooks/test-helper'
  cookbook 'resolver'
end
