#!/usr/bin/ruby

require 'open3'
require 'yaml'

CONFIG_FILE = '/etc/check-mk-agent/rabbitmq.yaml'

def command_output(command)
  stdin, stdout, stderr, retval = Open3.popen3(command)
  stdin.close
  output = stdout.read.split("\n")
  errors = stderr.read

  if retval and retval.value != 0
    $stderr.puts "Error running /usr/sbin/rabbitmqctl: #{errors}"
  end

  output
end

unless File.executable? '/usr/sbin/rabbitmqctl'
  # Assuming no RabbitMQ installed.
  exit 0
end

# Default thresholds are `nil` indicating that there is no threshold.
critical_threshold = nil
warning_threshold = nil

if File.exists? CONFIG_FILE
  config = YAML.load_file(CONFIG_FILE)
  if config.is_a?(Hash)
    if config.has_key?('critical')
      critical_threshold = config['critical'].to_i
    end
    if config.has_key?('warning')
      warning_threshold = config['warning'].to_i
    end
    if config.has_key?('critical_ready')
      critical_ready_threshold = config['critical_ready'].to_i
    end
    if config.has_key?('warning_ready')
      warning_ready_threshold = config['warning_ready'].to_i
    end
    if config.has_key?('critical_total')
      critical_total_threshold = config['critical_total'].to_i
    end
    if config.has_key?('warning_total')
      warning_total_threshold = config['warning_total'].to_i
    end
  end
end

vhosts = command_output('/usr/sbin/rabbitmqctl -q list_vhosts')

vhosts.each do |vhost|
  lines = command_output("rabbitmqctl -q -p #{vhost} list_queues messages messages_ready")
  total_messages = 0
  total_messages_ready = 0

  lines.each do |line|
    if line =~ /^\d+\s+\d+$/
      messages, messages_ready = line.split
      total_messages += messages.to_i
      total_messages_ready += messages_ready.to_i
    end
  end

  total_open_messages = total_messages - total_messages_ready
  status = 0
  status_message = 'OK'

  if ((not critical_threshold.nil?) and (total_open_messages >= critical_threshold)) or
  ((not critical_ready_threshold.nil?) and (total_messages_ready >= critical_ready_threshold)) or
  ((not critical_total_threshold.nil?) and (total_messages >= critical_total_threshold))
    status = 2
    status_message = 'CRITICAL'
  elsif ((not warning_threshold.nil?) and (total_open_messages >= warning_threshold)) or
  ((not warning_ready_threshold.nil?) and (total_messages_ready >= warning_ready_threshold)) or
  ((not warning_total_threshold.nil?) and (total_messages >= warning_total_threshold))
    status = 1
    status_message = 'WARNING'
  end

  puts "#{status} RabbitMQ-#{vhost} total=#{total_messages}|ready=#{total_messages_ready}|open=#{total_open_messages} #{status_message} - #{total_open_messages} open message(s)"
end
