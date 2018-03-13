#!/usr/bin/ruby

require 'open3'
require 'yaml'

CONFIG_FILE = '/etc/check-mk-agent/mongodb.yaml'

def command_output(command)
  stdin, stdout, stderr, retval = Open3.popen3(command)
  stdin.close
  output = stdout.read.split("\n")
  errors = stderr.read

  if retval and retval.value != 0
    $stderr.puts "Error running {command}: #{errors}"
  end

  output
end

unless File.executable? '/usr/bin/mongo'
  # Assuming no MongoDB installed.
  exit 0
end

# Default thresholds are `nil` indicating that there is no threshold.
critical_threshold = nil
warning_threshold = nil

if File.exists? CONFIG_FILE
  config = YAML.load_file(CONFIG_FILE)
  if config.is_a?(Hash)
    if config.has_key?('critical_connections')
      critical_threshold = config['critical_connections'].to_i
    end
    if config.has_key?('warning_connections')
      warning_threshold = config['warning_connections'].to_i
    end
  end
end

status = 3
status_message = 'UNKNOWN'
total_connections = 0
connections_message = ''
mongo_command = 'printjson(db.serverStatus().connections.current);'

if File.exists? '/root/.mongorc.js'
  mongo_command = "load(\"/root/.mongorc.js\");#{mongo_command}"
end

lines = command_output("mongo --quiet --eval '#{mongo_command}'")
lines.each do |line|
  if line =~ /^\d+$/
    total_connections = line.to_i
    status = 0
    status_message = 'OK'
    connections_message = "- #{total_connections} open connection(s)"
  end
end


if (not critical_threshold.nil? and total_connections >= critical_threshold)
  status = 2
  status_message = 'CRITICAL'
elsif (not warning_threshold.nil? and total_connections >= warning_threshold)
  status = 1
  status_message = 'WARNING'
end


puts "#{status} MongoDB total_connections=#{total_connections} #{status_message} #{connections_message}"