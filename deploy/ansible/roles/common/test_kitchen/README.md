test-kitchen for ansible
=========
test kitchen runs serverspec tests against common role on 3 different environment settings:

- developmet
- !development with resolver
- !development with dnsmasq enabled

Requirements
------------------
- rubygems
- docker or vagrant

Developing tests
------------
.kitchen.local.yml describes your local environment

- copy .kitchen.local.yml test_kitchen/local dir to test_kitchen/
- bundle install --without=ec2 --path vendor/ (from test_kitchen dir as non root)
- bundle exec kitchen test (use --destroy=never while writing tests)
- write a test
- bundle exec kitchen verify
- bundle exec kitchen destroy (when done, if needed)

you can specify an environment if you need to run just one environment, e.g bundle exec kitchen <command> <env> (see kitchen list)

keep in mind that for !development environments some tests are meant to fail locally due to networking settings, as well as you will need to manually adjust dns nameservers in template files, otherwise ansible provisioner will hang due to not being able to resolv anything.
