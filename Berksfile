source "https://supermarket.chef.io"

metadata

cookbook "apt"
cookbook "chef-vault"
cookbook "openssh"
cookbook "yum"
group :integration do
  cookbook 'test-helper', path: 'test/fixtures/cookbooks/test-helper'
  cookbook 'resolver'
end
