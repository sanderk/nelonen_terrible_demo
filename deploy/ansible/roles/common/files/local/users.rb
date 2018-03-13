#!/usr/bin/env ruby
#
# Monitor users on the system that should be absent, or are not managed by
# Puppet.
#
require 'json'
require 'rbconfig'
require 'socket'

local_users = {}
ignore_users = {
  'nfsnobody' => 65534,
}

if RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
  catalog_dir = 'C:/ProgramData/PuppetLabs/puppet/var/client_data/catalog'
  # Using the last part of the SID, 500 is the local administrator account and
  # 501 the local guest account.
  max_system_user = 501

  require 'win32ole'
  wmi = WIN32OLE.connect('winmgmts://')
  users = wmi.ExecQuery('select * from Win32_UserAccount')

  users.each do |user|
    if user.LocalAccount
      local_users[user.Name] = user.SID.gsub(/^.*-/,'').to_i
    end
  end
else
  if File.directory?('/opt/puppetlabs/puppet/cache/client_data/catalog')
    # Puppet 4 location.
    catalog_dir = '/opt/puppetlabs/puppet/cache/client_data/catalog'
  else
    # Puppet 3
    catalog_dir = '/var/lib/puppet/client_data/catalog'
  end

  max_system_user = 500
  if File.exists?('/etc/login.defs')
    uid_min = File.readlines('/etc/login.defs').select { |line| line =~ /^UID_MIN/ }
    if uid_min and uid_min[0]
      max_system_user = uid_min[0].scan(/\d+/).first.to_i
    end
  end

  require 'etc'
  Etc.passwd {|u|
    local_users[u.name] = u.uid.to_i
  }
end

status = 3
performance_data = '-'
check_output = 'Unknown'

hostname = Socket.gethostname
if hostname =~ /\./
  catalog_file = File.join(catalog_dir, "#{hostname}.json")
else
  catalog_file = Dir.glob(File.join(catalog_dir, "#{hostname}.*.json")).first
end

unmanaged = []
not_absent = []

if catalog_file and File.exist?(catalog_file)
  file = File.read(catalog_file)
  catalog = JSON.parse(file)

  if catalog.has_key?('data')
    catalog_data = catalog['data']
  else
    # Puppet 4 structure is flatter.
    catalog_data = catalog
  end

  if catalog_data.has_key?('resources')
    managed_users = {}

    catalog_data['resources'].each do |r|
      if r.has_key?('type') and r['type'] == 'User'
        if r.has_key?('title') and r['title']
          username = r['title']
          managed_users[username] = true

          if r.has_key?('parameters') and r['parameters'].has_key?('ensure') and r['parameters']['ensure'] == 'absent'
            # User absent
            if local_users.has_key?(username)
              unless ignore_users.has_key?(username)
                not_absent << username
              end
            end
          end
        end
      end
    end

    local_users.each do |username, uid|
      if (not managed_users.has_key?(username)) and uid > max_system_user
        unless ignore_users.has_key?(username)
          unmanaged << username
        end
      end
    end

    if not_absent.empty? and unmanaged.empty?
      status = 0
      check_output = 'OK'
    else
      unless not_absent.empty?
        status = 2
      else
        status = 1
      end

      counter_text = []
      unless not_absent.empty?
        user_list = not_absent.join(',')
        counter_text << "Should be absent: (#{user_list})"
      end
      unless unmanaged.empty?
        user_list = unmanaged.join(',')
        counter_text << "Unmanaged users: (#{user_list})"
      end
      check_output = counter_text.join(', ')
    end
  else
    check_output = 'Catalog does not have expected structure.'
  end
else
  check_output = "Unable to read catalog '#{catalog_file}'"
end

puts "#{status} PuppetUsers #{performance_data} #{check_output}\n"
