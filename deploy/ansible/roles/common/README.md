Role Name
=========


Requirements
------------

Role Variables
--------------


Dependencies
------------


Example Playbook
----------------

```
- hosts: servers
  roles:
    - role: common
      users:
          - name: developer1
            sudo: true
            ssh_keys: 
                - "public_key_this"
                - "public_key_that"
            private_keys:
                - name: id_rsa
                  value: "{{ something_taken_from_vault }}"
                - name: id_rsa_other
                  value: "{{ you_do_use_vault_right }}"
          - name: application1
            mode: "u=rwx,g=x,o=x"                           # or "711", 0711 not recommended due to variable handling in jinja2
            create_log_dir: true                            # will create /data/logs/application1
            ssh_keys: 
                - "{{ webistrano_public_key }}"
            private_keys:
                - name: id_rsa
                  value: "{{ stash_access_private_key }}"
          - name: old.developer                             # Remove old user with him/her home dir
            state: absent
            remove: yes
          - name: bad.developer                             # With force. Note: This option is dangerous and may leave your system in an inconsistent state.
            state: absent
            force: yes

```

Development
-------

When modifying or adding a new feature, please make sure you write/moddify appropriate test for it. More information can be found inside test_kitchen directory.

License
-------


Author Information
------------------

