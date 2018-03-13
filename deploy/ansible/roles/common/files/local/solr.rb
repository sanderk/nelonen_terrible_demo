#!/usr/bin/ruby

require 'yaml'
require 'uri'
require 'net/http'
require 'rexml/document'
require 'time'

CONFIG_FILE = '/etc/check-mk-agent/solr.yaml'

# Default replication settings are `nil` indicating that there is no threshold.
slave = false
port = 8080
host = 'http://localhost'
partition = 'data'

warn_replication = nil
crit_replication = nil
warn_disk_size = nil
crit_disk_size = nil


if File.exists? CONFIG_FILE
  config = YAML.load_file(CONFIG_FILE)
  if config.is_a?(Hash)
    if config.has_key?('port')
      port = config['port'].to_i
    end
    if config.has_key?('partition')
      partition = config['partition'].to_s
    end
    if config.has_key?('crit_replication')
      crit_replication = config['crit_replication'].to_i
    end
    if config.has_key?('warn_replication')
      warn_replication = config['warn_replication'].to_i
    end
    if config.has_key?('warn_disk_size')
      warn_disk_size = config['warn_disk_size'].to_i
    end
    if config.has_key?('crit_disk_size')
      crit_disk_size = config['crit_disk_size'].to_i
    end
  end
end

def process_xml_slave(url)
  uri = URI.parse(url + "/solr/replication?command=details")
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = 5
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  report = {}

  begin
    doc = REXML::Document.new(response.body)
    root = doc.root

    details = root.elements["lst[@name='details']"]
    report['indexSize'] = details.elements["str[@name='indexSize']"].text.chomp(' GB')
    report['indexVersion'] = details.elements["long[@name='indexVersion']"].text
    report['isSlave'] = details.elements["str[@name='isSlave']"].text
    report['isMaster'] = details.elements["str[@name='isMaster']"].text

    slave = details.elements["lst[@name='slave']"]
    report['masterUrl'] = slave.elements["str[@name='masterUrl']"].text

    indexReplicatedAt = slave.elements["str[@name='indexReplicatedAt']"].text
    report['indexReplicatedAt'] = Time.parse(indexReplicatedAt).to_i
    replicationFailedAt = slave.elements["str[@name='replicationFailedAt']"].text
    report['replicationFailedAt'] = Time.parse(replicationFailedAt).to_i
  rescue
      report["failed"] = "Not a slave. master url not set or could not parse xml"
  end
  return report
end

def process_xml_master(url)
  uri = URI.parse(url + "/admin/cores?action=STATUS")
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = 5
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  report = {}

  begin
    doc = REXML::Document.new(response.body)
    root = doc.root

    cores = root.elements["lst[@name='status']"]
    cores.each do |core|
      name = core.elements["str[@name='name']"].text
      report[name] = {}
      report[name]['name'] = name
      report[name]['isDefaultCore'] = core.elements["bool[@name='isDefaultCore']"].text

      index = core.elements["lst[@name='index']"]
      report[name]['indexSize'] = index.elements["str[@name='size']"].text.chomp(' GB')
      report[name]['indexVersion'] = index.elements["long[@name='version']"].text
      report[name]['numDocs'] = index.elements["int[@name='numDocs']"].text
      report[name]['maxDoc'] = index.elements["int[@name='maxDoc']"].text
      report[name]['deletedDocs'] = index.elements["int[@name='deletedDocs']"].text
      report[name]['segmentCount'] = index.elements["int[@name='segmentCount']"].text
      report[name]['indexHeapUsageBytes'] = index.elements["long[@name='indexHeapUsageBytes']"].text
    end
    rescue
        report["failed"] = "Could not parse xml"
    end
    return report
end

status = 0
status_message = 'OK'
last_replication = 0
message = ''
replication_message = ''

#apply disk space check (master/slave)
if (not warn_disk_size.nil? or not crit_disk_size.nil?)
  disk_used = `df /#{partition} --local --exclude-type=tmpfs -P -B 1024 | awk '{total+=$2; used+=$3;} END { print (used/total)*100}'`
  disk_used = disk_used.strip.to_i
  if (disk_used and not disk_used.nil?)
    if (not crit_disk_size.nil? and disk_used >= crit_disk_size)
      status = 2
      status_message = 'CRITICAL'
      message = " - critical: low disk space: #{disk_used}% used"
    elsif(not warn_disk_size.nil? and disk_used >= warn_disk_size)
      status = 1
      status_message = 'WARNING'
      message = " - warning: low disk space: #{disk_used}% used"
    end
  end
end

# apply replication check (slave). Give precedence to disk warning.
if (status == 0)
  if (not crit_replication.nil? or not crit_replication.nil?)
    url = host.to_s + ":" + port.to_s
    slave_info = process_xml_slave(url)
    if (not slave_info.nil? and !slave_info.has_key?("failed"))
      last_replication = Time.now.to_i - slave_info['indexReplicatedAt']
      message = " - #{last_replication} seconds since last replication"
      replication_message = "last_replication=#{last_replication} "
      if (not crit_replication.nil? and last_replication >= crit_replication)
        status = 2
        status_message = 'CRITICAL'
      elsif (not warn_replication.nil? and last_replication >= warn_replication)
        status = 1
        status_message = 'WARNING'
      end
    end
  end
end
puts "#{status} SolrSlave #{replication_message}- #{status_message}#{message}"
