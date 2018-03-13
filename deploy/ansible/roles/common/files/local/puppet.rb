#!/usr/bin/ruby
#
# Check MK script to monitor the state of the Puppet agent.
#

require 'date'
require 'fileutils'
require 'json'
require 'rbconfig'
require 'yaml'

check_report = true
if RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
  state_dir = 'C:/ProgramData/PuppetLabs/puppet/var/state'
  check_mk_dir = 'C:/Program Files (x86)/check_mk'
else
  if File.directory?('/opt/puppetlabs/puppet/cache/state')
    # Location for Puppet 4 - use its built-in Ruby.
    if RbConfig.ruby != '/opt/puppetlabs/puppet/bin/ruby'
      exec("/opt/puppetlabs/puppet/bin/ruby #{$PROGRAM_NAME}")
    end
    state_dir = '/opt/puppetlabs/puppet/cache/state'
    # Issues when loading reports in Puppet 4, so disabled for now.
    check_report = false
  else
    # For Puppet 3
    state_dir = '/var/lib/puppet/state'
  end
  check_mk_dir = '/var/lib/check_mk_agent'
end

# Late require, in case out interpreter has "changed".
require 'puppet'

last_summary_file  = "#{state_dir}/last_run_summary.yaml"
last_report_file   = "#{state_dir}/last_run_report.yaml"
disabled_lock_file = "#{state_dir}/agent_disabled.lock"

check_mk_last_summary_file = "#{check_mk_dir}/last_run_summary.yaml"
check_mk_prev_summary_file = "#{check_mk_dir}/prev_run_summary.yaml"

# Default check output
item_name = 'Puppet'
performance_data = '-'
check_output="Currently no output, probably no Puppet installed"
status=3

if check_report and File.exists?(last_report_file)
  # Report is a serialised Puppet::Transaction::Report object.
  report = YAML.load_file(last_report_file)
  warnings = report.logs.select{ |log| log.level == :warning }
end

if File.exists?(last_summary_file)
  summary = YAML.load_file(last_summary_file)
  last_run = Time.at(summary['time']['last_run'].to_i).strftime('%Y/%m/%d %H:%M:%S')

  if File.exists?(disabled_lock_file)
    # If the agent has been disabled, retrieve the reason from the lock file.
    status = 2
    lock = JSON.parse(File.read(disabled_lock_file))
    check_output = "Puppet disabled since #{last_run}. Reason: #{lock['disabled_message']}"
  elsif summary['version']['config']
    # A configuration has been applied.
    performance_data = "config_retrieval=#{summary['time']['config_retrieval']}|total_time=#{summary['time']['total']}|resources=#{summary['resources']['total']}"

    # Load stats of the previous Puppet run(s).
    prev_summary = nil
    if File.exists?(check_mk_prev_summary_file)
      prev_summary = YAML.load_file(check_mk_prev_summary_file)
    end

    check_mk_last_summary = nil
    if File.exists?(check_mk_last_summary_file)
      check_mk_last_summary = YAML.load_file(check_mk_last_summary_file)
    end

    # Rotate the last summary to previous if this is a new run.
    if check_mk_last_summary
      if summary['time']['last_run'] != check_mk_last_summary['time']['last_run']
        FileUtils.copy(check_mk_last_summary_file, check_mk_prev_summary_file)
      end
    end

    # Keep our own copy of the last run stats, otherwise it will may overwritten by Puppet.
    if check_mk_last_summary == nil or summary['time']['last_run'] != check_mk_last_summary['time']['last_run']
      FileUtils.copy(last_summary_file, check_mk_last_summary_file)
    end

    # These are the things we actually want to check and report on.
    if Time.now.to_i - summary['time']['last_run'] > 24*60*60
      status = 1
      check_output = "Puppet did not run for more than 24 hours, last run was #{last_run}"
    elsif summary['resources']['failed'].to_i > 0
      status = 2
      check_output="Failed to apply #{summary['resources']['failed']} changes in last run @ #{last_run}"
    elsif summary['resources']['changed'].to_i > 0
      if prev_summary and summary['resources']['changed'] == prev_summary['resources']['changed']
        status = 1
        check_output = "Applied #{summary['resources']['changed']} changes (REPEAT) in last run @ #{last_run}"
      else
        status = 0
        check_output = "Applied #{summary['resources']['changed']} changes in last run @ #{last_run}"
      end
    elsif summary['resources']['out_of_sync'].to_i > 0
      status = 2
      check_output = "Pending #{summary['resources']['out_of_sync']} changes (NOOP) in last run @ #{last_run}"
    elsif warnings and not warnings.empty?
      status = 1
      check_output = "#{warnings.count} warnings in last run @ #{last_run}"
    else
      status = 0
      check_output = "Puppet is running fine, last run #{last_run}"
    end
  else
    # If no configuration identifier is present, the last run was unsuccessful.
    status = 2
    check_output = "Puppet is running, no config retrieved, last run was @ #{last_run}"
  end
end

# Output the results.
puts "#{status} #{item_name} #{performance_data} #{check_output}\n"

