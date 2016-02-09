# 0.2.4

- serverspec now leverages shared examples between suites

# 0.2.3

- better documentation
- better attribute handling
- add per-environment Vault data
- support SELinux-enabled operating systems (Thanks [Nitzan Raz](https://github.com/BackSlasher))
- gitignore fixup

# 0.2.2

- fix supported platform versions in metadata

# 0.2.1

- add supported platforms to metadata

# 0.2.0

- serverspec integration tests leverage solo data bag contents
- 7 new serverspec resources, 14 new matchers
- better documentation
- add support for Ubuntu 14 and Fedora 23
- add ability to enforce SSH password authentication for only approved networks/hosts
- more robust logic around ensuring the domain is properly joined and SSSD services meet all requirements for LDAP/Kerberos integration.
- update [openssh cookbook](https://github.com/chef-cookbooks/openssh/commit/cfcf4cdb8b096a6cf364a813ac7ebaa889c71fb5) dependency to help mitigate [CVE-2016-0777 / CVE-2016-0778 OpenSSH client bug](http://www.openssh.com/txt/release-7.1p2)
- update yum cookbook to support [Test Kitchen on FC23](https://github.com/chef-cookbooks/yum/pull/143)
- attribute 'net-password-auth' renamed to 'ldap-key-auth'

# 0.1.1

- Fix host SPN creation

# 0.1.0

Initial fork of realmd-sssd from [localytics/chef-sssd](https://github.com/localytics/chef-sssd)

- entirely code-driven sssd.conf template
- programmatic hooks into configuring OpenSSH server
- move to Chef Vault from encrypted data bags
- simplified realm joining process
- support for specifying destination OU
