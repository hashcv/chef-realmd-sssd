name             'realmd-sssd'
maintainer       'John Bartko'
maintainer_email 'jbartko@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures realmd and sssd'
long_description 'Installs/Configures realmd and sssd for use with a Microsoft Active Directory/Kerberos realm'
source_url       'https://github.com/jbartko/chef-realmd-sssd' if respond_to?(:source_url)
issues_url       'https://github.com/jbartko/chef-realmd-sssd/issues' if respond_to?(:issues_url)
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION')) rescue '0.0.1'

depends 'apt'
depends 'chef-vault'
depends 'openssh'
depends 'yum'
