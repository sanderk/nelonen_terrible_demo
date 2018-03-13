#!/bin/bash

MK_CFGDIR='/etc/check-mk-agent'

application=$(basename $0 .sh)



# Redis is default running on port 6379
port=6379
host=127.0.0.1

if [[ -f $MK_CFGDIR/$application.cfg ]]; then
    source $MK_CFGDIR/$application.cfg
fi

# Redis might be running unmanaged, so try to at least monitor something by
# default.
service_name=redis

if [[ -f /etc/init.d/redis-server_default ]];
then
    # Redis is installed via Puppet profile, so monitor this service.
    service_name=redis-server_default
fi

if chkconfig --levels 3 $service_name 2>&1 > /dev/null;
then
    # Application exists, it should be listening the default port
    if [[ $(redis-cli -p $port -h $host info &>/dev/null ; echo $?) -eq 0 ]]; then
        status=0

        # Get some performance data
        connected_clients=$(redis-cli -h $host info | awk -F: '/connected_clients/{print $2}' | tr -d '\r')
        uptime_in_days=$(redis-cli -h $host info | awk -F: '/uptime_in_days/{print $2}' | tr -d '\r')
        used_memory=$(redis-cli -h $host info| awk -F: '/used_memory:/{print $2}' | tr -d '\r')
        used_memory_human=$(redis-cli -h $host info | awk -F: '/used_memory_human/{print $2}' | tr -d '\r')
        redis_version=$(redis-cli -h $host info | awk -F: '/redis_version/{print $2}' | tr -d '\r')


        text="Redis is using $used_memory_human of RAM. Days up: $uptime_in_days. Clients: $connected_clients. Version: $redis_version"
        performance_data="clients=$connected_clients|uptime_in_days=$uptime_in_days|used_memory=$used_memory"
    else
        status=2
        text="Unable to connect to $application"
        performance_data="-"
    fi

    # Output results. Format:
    item_name="$(tr '[:lower:]' '[:upper:]' <<< ${application:0:1})${application:1}"
    check_output="$text"
    echo "$status $item_name $performance_data $check_output"
fi
