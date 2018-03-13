require '/tmp/kitchen/spec/spec_helper.rb'

describe 'resolver' do
	describe file('/etc/resolv.conf') do
		it { should exist }
		it { should contain 'kitchen.staging.core-services.aws.sanomahost.nl service.consul' }
		it { should contain('10.164.136.252').after('10.164.176.252') }
		it { should contain('10.164.136.252').before('10.164.96.252') }
	end
	["sanoma.fi", "sanoma.nl"].each do |hostname|
		describe host(hostname) do
			it { should be_resolvable.by('dns') }
		end
	end
end

#tests that ar included in all non development suites

describe 'monitor' do
	["xinetd", "check-mk-agent"].each do |package|
		describe package(package) do
			it { should be_installed }
		end
	end
	describe service('xinetd') do
		it { should be_running }
		it { should be_enabled }
	end
	["600", "7200"].each do |dir|
    	describe file('/usr/share/check-mk-agent/local/' + dir) do
        	it { should be_directory}
        	it { should be_mode 755 }
    	end
    end
	["aws_metrics", "ec2_events", "86400"].each do |plugin|
    	describe file('/usr/share/check-mk-agent/local/' + plugin) do
        	it { should_not exist}
    	end
    end
	["mk_services", "600/aws_metrics", "7200/ec2_events"].each do |plugin|
    	describe file('/usr/share/check-mk-agent/local/' + plugin) do
        	it { should exist }
        	it { should be_mode 755 }
    	end
    end
    describe host('smarthost.aws.sanomahost.nl') do
    	it { should be_reachable.with(:timeout=> 10)}
    	describe file('/usr/share/check-mk-agent/plugins/mk_inventory') do
    		it { should exist }
    		it { should be_mode 755 }
    	end
    end
end

describe 'awsbackup' do
	describe package('bc') do
		it { should be_installed }
	end
	describe file('/usr/local/bin/aws_backup.sh') do
		it { should exist }
		it { should be_file }
		it { should be_mode 755 }
		it { should contain 'function putS3', 'BACKUP_CONFIG', 'AWSBackup' }
	end
	describe file('/etc/sysconfig/aws_backup') do
		it { should exist }
		it { should be_mode 600 }
		it { should contain 'BACKUP_PREFIX="core-services/staging/kitchen"' }
	end
	describe file('/data/logs/backup') do
		it { should exist }
		it { should be_directory }
	end
	describe cron do
		minutes = /(\d{1,3})$/.match(host_inventory['ec2']['local-ipv4'])
		minutes = ((( "#{minutes}".to_f ) / 254 ) * 59 ).to_i
		it { should have_entry "#{minutes} 6 * * * /usr/local/bin/aws_backup.sh >> /data/logs/backup/awsbackup.log", "#Ansible: awsbackup" }
	end
end

#common tests that are included in all suites

describe 'structure' do
	["/data/home", "/data/logs"].each do |dir|
    	describe file(dir) do
        	it { should be_directory}
    	end
    end
end

describe 'usermanagement' do
	["developers", "admins"].each do |group|
		describe group(group) do
  			it { should exist }
		end
		describe file('/etc/sudoers.d/' + group) do
			it { should be_file }
			it { should contain group }
		end
	end
	describe user('t.est') do
		it { should have_login_shell '/bin/bash' }
		it { should have_home_directory '/home' }
		it { should exist }
		["admins", "adm", "wheel"].each do |group|
			it { should belong_to_group group}
		end
		it { should have_authorized_key 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAteststring' }
	end
	describe user('tes.t') do
		it { should have_login_shell '/bin/bash' }
		it { should have_home_directory '/data/home' }
		it { should exist }
		it { should belong_to_group 'developers'}
		it { should have_authorized_key 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAsecondteststring' }
	end
	["/data/logs/tes.t", "/data/home/tes.t"].each do |file|
		describe file(file) do
			it { should be_directory }
			it { should be_owned_by 'tes.t' }
			it { should be_grouped_into 'tes.t' }
			it { should be_mode 755 }
		end
	end
	describe file('/data/home/tes.t/.ssh') do
		it { should be_directory }
		it { should exist }
		it { should be_grouped_into 'tes.t' }
		it { should be_owned_by 'tes.t' }
		it { should be_mode 700 }
	end
	describe file('/data/home/tes.t/.ssh/') do
		it { should be_directory }
		it { should exist }
		it { should be_grouped_into 'tes.t' }
		it { should be_owned_by 'tes.t' }
		it { should be_mode 700 }
	end
	describe x509_private_key('/data/home/tes.t/.ssh/test_key') do
		it { should be_valid }
	end
end

describe 'motd' do
	describe file('/etc/motd') do
		it { should be_file }
		it { should contain 'This machine is managed by Terrible' }
	end
end

describe 'postfix' do
	describe package('postfix') do
		it { should be_installed }
	end
	describe file('/etc/postfix/main.cf') do
		it { should be_file }
		it { should contain 'smarthost.aws.sanomahost.nl', host_inventory['hostname'] }
	end
	describe service('postfix') do
		it { should be_enabled }
	end
end

describe 'serf_cleanup' do
	describe file('/etc/serf') do
		it { should_not be_file }
	end
end
