require '/tmp/kitchen/spec/spec_helper.rb'
 
describe 'dnsmasq_and_resolver' do
	describe file('/etc/dnsmasq.d/upstream.conf') do
		it { should_not exist }
	end
	describe file('/etc/resolv.conf') do
		it { should_not contain 'Ansible generated', 'resolv.conf is managed by Ansible' }
	end
	describe service('dnsmasq') do
		it { should_not be_running }
		it { should_not be_enabled }
	end
end

describe 'awsbackup' do
	["/usr/local/bin/aws_backup.sh", "/etc/sysconfig/aws_backup", "/data/logs/backup"].each do |file|
		describe file(file) do
			it { should_not exist }
		end
	end
	describe cron do
		it { should_not have_entry "#Ansible: awsbackup" }
	end
end

describe 'monitor' do
		['check-mk-agent', 'xinetd'].each do |package|
			describe package(package) do
				it { should_not be_installed }
			end
		end
		describe service('xinetd') do
			it { should_not be_running }
			it { should_not be_enabled }
		end
		describe file('/usr/share/check-mk-agent') do
			it { should_not exist }
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
