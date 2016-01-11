# sssd-cookbook

Launch, configure, and manage the SSSD service for communication with an AD backend such as Amazon Directory Service (Simple AD)

## Supported Platforms

- Debian 8 / Jessie
- CentOS 7

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['join']</tt></td>
    <td>Boolean</td>
    <td>whether or not to join the domain (should be set by role or environment)</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['debian-mkhomedir-umask']</tt></td>
    <td>String</td>
    <td>octal representation of the home directory creation mask</td>
    <td><tt>'0022'</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['packages']</tt></td>
    <td>Array</td>
    <td>list of packages to install prior to realm join</td>
    <td><tt>varies by OS</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['host-spn']</tt></td>
    <td>String</td>
    <td>an optional alternate computer name to use when joining the domain (IE: ec2 instance ID)</td>
    <td><tt>node['fqdn'] given proper DNS, or node['machinename']</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['password-auth']</tt></td>
    <td>Boolean</td>
    <td>enable SSH password authentication</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['net-password-auth']['enable']</tt></td>
    <td>Boolean</td>
    <td>enable SSH password authentication from only specific networks</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['net-password-auth']['cidr']</tt></td>
    <td>Array</td>
    <td>list of CIDR notation networks from which to allow SSH</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['config']</tt></td>
    <td>Hash</td>
    <td>default configuration hash. You likely won't need to change this.</td>
    <td><tt>Default sssd configuration Hash</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['extra-config']</tt></td>
    <td>Hash</td>
    <td>extra configuration which will be merged and override the default and templated realm config. See Usage for example.</td>
    <td><tt>Default sssd configuration Hash</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['vault-name']</tt></td>
    <td>String</td>
    <td>name of the chef-vault with the vault item holding realm info</td>
    <td><tt>realmd-sssd</tt></td>
  </tr>
  <tr>
    <td><tt>['realmd-sssd']['vault-item']</tt></td>
    <td>String</td>
    <td>name of the chef-vault item caintaing values for `realm`, `username`, `password`, and optionally `computer-ou`</td>
    <td><tt>realm</tt></td>
  </tr>
</table>

## Usage

### sssd::default

Include `sssd` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[sssd::default]"
  ]
}
```

### attributes

The example role default attributes below demonstrate how to add and override `sssd.conf` values via the `node['realmd-sssd']['extra-config']` attribute.

```json
{
  "default_attributes": {
    "realmd-sssd": {
      "join": "true",
      "extra-config": {
        "[domain/example.org]": {
          "realmd_tags": "managed by chef",
          "ad_access_filter": "(&(memberOf=CN=linux-users,OU=Groups,DC=example,DC=org)(objectCategory=user)(sAMAccountName=*))"
        }
      },
      "debian-mkhomedir-umask": "0077",
      "net-password-auth": {
        "enable": "true",
        "cidr": [
          "192.0.2.0/24"
        ]
      }
    }
  }
}

```

## Testing

See .kitchen.yml and .kitchen.local.yml.EXAMPLE.

To create a local databag for use with test kitchen's with-registration suite, do:

  ```bash
  $ openssl rand -base64 512 | tr -d '\r\n' > test/integration/with-registration/encrypted_data_bag_secret_key
  $ knife solo data bag create sssd_credentials realm -c .chef/solo.rb
  ```

## License and Authors

Author:: John Bartko (jbartko@gmail.com)

```text
Copyright:: 2016 John Bartko

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
