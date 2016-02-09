name             'realmd-sssd'
maintainer       'John Bartko'
maintainer_email 'jbartko@gmail.com'
license          'Apache 2.0'
description      'Joins a realm via realmd and configures SSSD'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url       'https://github.com/jbartko/chef-realmd-sssd' if respond_to?(:source_url)
issues_url       'https://github.com/jbartko/chef-realmd-sssd/issues' if respond_to?(:issues_url)
version          '0.2.4'

supports 'centos', '>= 7.0'
supports 'debian', '>= 8.0'
supports 'fedora'
supports 'ubuntu', '>= 14.04'

depends 'apt'
depends 'chef-vault'
depends 'openssh', '~> 1.6.0'
depends 'selinux'
depends 'selinux_policy', '~> 0.9.3'
depends 'yum', '~> 3.9.0'
