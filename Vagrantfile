##
#
# = Generic Vagrantfile for Sanoma Ansible-based projects
#
# This Vagrantfile may be used to facilitate the use of Vagrant and Ansible in
# your development project. It provides a number of custom Vagrant commands
# which can be used to clone and maintain the required repositories and
# supports a simple YAML configuration file in which boxes can be defined. For
# full details, consult the `README` file and `doc` directory.
#
# == Copyright
#
# Copyright 2016 Sanoma Digital
#
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
CONFIGFILE="vagrant.yml"
WORKDIR=File.dirname(__FILE__)
require 'getoptlong'

opts = GetoptLong.new(
  [ '--use-tags', GetoptLong::OPTIONAL_ARGUMENT ]
)

customTags=[]

opts.each do |opt, arg|
  case opt
    when '--use-tags'
      customTags=arg.split(",")
  end
end

def set_default(default, value)
  if value.nil? then
    return default
  else
    return value
  end
end
# }}}
# Arguments {{{
if ARGV.count == 0 or ARGV[0] == 'help' then
  print "
## Sanoma Vagrant Help ##
  Please use vagrant with the following commands

  help - Show this help message
  up <<host>> - Start a single node, or if not specified all nodes
  provision <<host>> - Run Ansible code against node

## Configuration File ##
  This vagrantfile reads configuration from the #{CONFIGFILE}, example provided in #{CONFIGFILE}.example
"
  exit 0
end
# }}}
# base_images (box) {{{
base_images = {
  'centos6-latest'               => 'https://snm-nl-hostingsupport-test.s3.amazonaws.com/vagrant/centos6-latest.box',
  'centos7-latest'               => "https://snm-nl-hostingsupport-test.s3.amazonaws.com/vagrant/centos7-latest.box",
}
# }}}
# Load Configuration File {{{
if not File.exists?(File.join(File.dirname(__FILE__),CONFIGFILE))
  print "Missing #{CONFIGFILE} file\n"
  print "Go Fix-it Felix and try again...\n"
  exit(1)
else
  require 'yaml'
  configfile = YAML.load_file(File.join(File.dirname(__FILE__),CONFIGFILE))
  clone_protocol = set_default('https', configfile['clone_protocol'])
end
# }}}

# Set default variables {{{
vmprefix = set_default('Vagrant',configfile['vmprefix'])
environment = set_default('development',configfile['environment'])
nodes = configfile["nodes"]
product = configfile["product"]
cluster = configfile["cluster"]
box = set_default('centos7-base',configfile["box"])
natdnshostresolver = set_default('off',configfile['natdnshostresolver'])
# }}}
# Show configuration on screen {{{
if ARGV[0] == 'provision' or ARGV[0] == 'up' then
  print "CONFIG Default product: #{product}\n"
  print "CONFIG Default box: #{box}\n"
end
# }}}

# The use of ansible_galaxy requires at least Vagrant version 1.8.1
Vagrant.require_version ">= 1.8.1"

Vagrant.configure("2") do |groupconfig|
  amount_of_boxes_enabled = 0

  if nodes then
    nodes.each do |key, opts|
      # Defaults
      opts["name"] = key
      opts["product"] = product if opts["product"].nil?
      opts["role"] = opts["name"] if opts["role"].nil?
      opts["environment"] = environment if opts["environment"].nil?
      opts["cluster"] = cluster if opts["cluster"].nil?
      opts["enabled"] = true if opts["enabled"].nil?
      opts["box"] = box if opts["box"].nil?
      opts["box_url"] = base_images[opts["box"]]
      opts["vname"] = "#{vmprefix} - %s" % opts["name"] if opts["box_name"].nil?
      opts["natdnshostresolver"] = natdnshostresolver if opts["natdnshostresolver"].nil?
      opts["natdnshostresolver"] = 'on' if opts['natdnshostresolver']
      opts["natdnshostresolver"] = 'off' if not opts['natdnshostresolver']
      opts["cpus"] = '1' if opts["cpus"].nil?
      opts["gui"] = false if opts["gui"].nil?
      opts["windows"] = false
      opts["windows"] = true if opts["box"].start_with?('win')
      if opts["windows"] then
        opts["hostname"] =  "%s" % opts["name"] if opts["hostname"].nil?
      else
        opts["hostname"] =  "%s.local" % opts["name"] if opts["hostname"].nil?
      end
      # Memory Warning {{{
      if opts["windows"] then
        opts["memory"] = 2048 if opts["memory"].nil?
        if opts["memory"] < 2048 then
          printf "[%s] WARNING Less than 2048mb memory configured for a windows machine, this might result in buggy and/or slow runs\n", opts["name"]
        end
      else
        opts["memory"] = 1024 if opts["memory"].nil?
        if opts["memory"] < 1024 then
          printf "[%s] WARNING Less than 1024mb memory configured for a linux machine, this might result in buggy and/or slow runs\n", opts["name"]
        end
      end
      # }}}

      # Box Enabled? {{{
      if opts["enabled"] then
        amount_of_boxes_enabled = amount_of_boxes_enabled + 1
        ## Config Loop per Box {{{
        groupconfig.vm.define opts["name"] do |config|
          # Show feedback {{{
          if ARGV[0] == 'provision' or ARGV[0] == 'up' then
            printf "[%s] Role: %s - Environment: %s\n", opts["name"], opts["role"], opts["environment"]
            printf "[%s] Box: %s - VName: %s - Hostname: %s\n", opts["name"], opts["box"], opts["vname"], opts["hostname"]
          end
          # }}}
          # Configure Virtual Machine - config.vm {{{
          config.vm.box = opts["box"]
          config.vm.box_url = opts["box_url"]
          config.vm.network :private_network, ip: opts["ip"]
          config.vm.hostname = opts["hostname"]
          config.vm.host_name = opts["hostname"]
          config.ssh.forward_agent = true
          config.ssh.paranoid = false
          # Special Mounts for Development
          if not opts["synced_folder"].nil? then
            opts["synced_folder"].each do |projectdir, projectsettings|
              if projectsettings.is_a?(Hash) then
                if not projectsettings['mount'] then
                  print "No mount setting for synced_folder_option[#{projectdir}]\n"
                  exit(1)
                end
                config.vm.synced_folder projectdir, projectsettings['mount'],
                  create: set_default(false, projectsettings['create']),
                  group: set_default(false, projectsettings['group']),
                  owner: set_default(false, projectsettings['owner']),
                  mount_options: set_default(false, projectsettings['mount_options']),
                  type: set_default(false, projectsettings['type'])
              else
                config.vm.synced_folder projectdir, projectsettings
              end
            end
          end
          # Configured port forwards
          if not opts["forwarded_port"].nil? then
            opts["forwarded_port"].each do |keyv, value|
              config.vm.network :forwarded_port, guest: keyv.to_i, host: value.to_i
            end
          end
          # }}}
          # Configure Virtual Machine - Windows {{{
          if opts["windows"] then
            config.vm.communicator = 'winrm'
            # config.vm.network :forwarded_port, guest: 5985, host: 5985, id: 'winrm', auto_correct: true
            config.vm.guest = :windows
            if RUBY_PLATFORM !~ /darwin/ then
              # Windows guest support on OS X isn't quite 100% yet. Skipping these
              # options at least allows the VM to boot up so it can be (re)started
              # in VirtualBox and provisioned manually.
              config.winrm.username = 'administrator'
              config.winrm.password = 'vagrant'
              config.winrm.max_tries = 40
              config.windows.halt_timeout = 30
            end
          end # if opts["windows"]
          # }}}
          # Configure Virtual Machine - Virtualbox {{{
          config.vm.provider :virtualbox do |vb|
            vb.gui = opts["gui"]
            vb.name = opts["vname"]
            vb.customize [
              "modifyvm", :id,
              "--memory", opts["memory"],
              "--cpus", opts["cpus"],
              "--natdnshostresolver1", opts["natdnshostresolver"],
              "--groups", "/#{vmprefix}"
            ]
          end # do |vb| }}}
          # Ansible {{{
            # Windows {{{
            if Vagrant::Util::Platform.windows?
              config.vm.provision "shell", inline: "ssh-keyscan -t rsa -p 7999 source.sanoma.com >> /etc/ssh/ssh_known_hosts && cp /vagrant/vagrant_ansible_vault_password_file.txt /tmp/ && chmod 664 /tmp/vagrant_ansible_vault_password_file.txt", privileged: true
              config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true
              config.vm.provision "ansible_local" do |ansible|
                ansible.playbook = "deploy/ansible/vagrant.yml"
                # requires Vagrant 1.8!
                ansible.galaxy_role_file = "deploy/ansible/requirements.yml"
                ansible.verbose = true
                ansible.tags = customTags if customTags.size > 0
                ansible.raw_arguments = [
                  "--vault-password-file=/tmp/vagrant_ansible_vault_password_file.txt",
                ]
                ansible.extra_vars = {
                  hostname: opts["hostname"],
                  stage: opts["environment"],
                  cluster: opts["cluster"],
                  product: opts["product"],
                  role: opts["role"],
                  common_gather_ec2_facts: false
                }
              end

              if ARGV.include? '--provision-with'
                config.vm.provision "deploy", type: "ansible_local" do |ansible|
                  ansible.verbose = true
                  ansible.playbook = "deploy/ansible/vagrant.yml"
                  # requires Vagrant 1.8!
                  ansible.galaxy_role_file = "deploy/ansible/requirements.yml"
                  ansible.verbose = true
                  ansible.tags = customTags if customTags.size > 0
                  ansible.raw_arguments = [
                    "--vault-password-file=/tmp/vagrant_ansible_vault_password_file.txt",
                  ]
                  ansible.extra_vars = {
                    hostname: opts["hostname"],
                    stage: opts["environment"],
                    cluster: opts["cluster"],
                    product: opts["product"],
                    role: opts["role"],
                    common_gather_ec2_facts: false
                  }
                  ansible.tags = customTags.unshift('deploy')
                end
              end
            # }}}
            # Linux {{{
            else
              config.vm.provision "ansible" do |ansible|
                ansible.verbose = true
                ansible.playbook = "deploy/ansible/vagrant.yml"
                # requires Vagrant 1.8!
                ansible.galaxy_role_file = "deploy/ansible/requirements.yml"
                ansible.verbose = true
                ansible.tags = customTags if customTags.size > 0
                ansible.raw_arguments = [
                  "--ask-vault-pass",
                ]
                ansible.extra_vars = {
                  hostname: opts["hostname"],
                  stage: opts["environment"],
                  cluster: opts["cluster"],
                  product: opts["product"],
                  role: opts["role"],
                  common_gather_ec2_facts: false
                }
              end

              if ARGV.include? '--provision-with'
                config.vm.provision "deploy", type: "ansible" do |ansible|
                  ansible.verbose = true
                  ansible.playbook = "deploy/ansible/vagrant.yml"
                  # requires Vagrant 1.8!
                  ansible.galaxy_role_file = "deploy/ansible/requirements.yml"
                  ansible.verbose = true
                  ansible.tags = customTags if customTags.size > 0
                  ansible.raw_arguments = [
                    "--ask-vault-pass",
                  ]
                  ansible.extra_vars = {
                    hostname: opts["hostname"],
                    stage: opts["environment"],
                    cluster: opts["cluster"],
                    product: opts["product"],
                    role: opts["role"]
                  }
                  ansible.tags = customTags.unshift('deploy')
                end
              end
            end
            # }}}
          # }}}
        end # config.vm.define opts["name"] do |config| }}}
      end # opts["enabled"] }}}
    end
  end # boxes.each do |opts|
  if amount_of_boxes_enabled == 0 then
    print "WARNING: You did not enable any machines in the configuration, check the nodes: part in config.yml\n"
  end
end # do |config|
