PHP
===

A generic role for installing a PHP server.

Dependencies
------------

- Nginx role (when using Zend PHP with FPM)

Role Variables
--------------

`php_version`: Version of PHP package to install.

Supported versions:

- `5.5`, `5.6`, `7.0`: Will be installed from Zend repos
- `system`: Will install the default `php` package available on your system (e.g. 5.4 on CentOS 7)

- - - - -

`php_manage_ini`: Whether to create the php.ini file with this role. Set to false if you want to use use the packaged ini file or your own template.

See `templates/php.ini.j2` and `defaults/main.yml` for contents and default values.

- - - - -

`php_modules`: List of PHP extensions. Will install yum packages with the following pattern:

 - `php-{{php_version}}-{{item}}-zend-server` When using Zend PHP
 - `php-{{item}}` When using system PHP

- - - - -

`php_enable_modphp`: Install and enable the Apache PHP module.

- - - - -

`php_enable_fpm`: Install and enable the php-fpm service. Use this with the nginx role.

- - - - -

`php_ini_custom_settings`: Custom configuration to be added to the main ini file. See example below.

Example Playbooks
-----------------
```
- hosts: servers
  roles:
     - role: nginx
       nginx_sites:
         - name: "{{ product }}"
           enabled: true
           type: php
           server: "{{ ansible_fqdn }}"
           log_path: /data/logs/{{ product }}
           root: /data/home/{{ product }}/public
           socket_type: 'unix:'
           socket_location: '/usr/local/zend/tmp/php-fpm.sock'
     - role: php
       php_version: '7.0' # Don't forget quotes!
       php_enable_fpm: true
```

```
- hosts: servers
  roles:
     - apache
     - role: php
       php_version: 'system'
       php_enable_modphp: true
       php_ini_custom_settings:
          - name: phar.readonly
            value: Off
            section: Phar
          - name: short_open_tag
            value: Off
            section: PHP
```
