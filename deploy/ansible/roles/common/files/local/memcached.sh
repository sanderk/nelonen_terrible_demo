#!/bin/bash
#
# Memcached, check with memcached-tool 127.0.0.1:$port stats | grep ...
#


MK_CFGDIR='/etc/check-mk-agent'

application=$(basename $0 .sh)
port=11211


if [[ -f $MK_CFGDIR/$application.cfg ]]; then
    source $MK_CFGDIR/$application.cfg
fi

if type $application &>/dev/null
then
    # Application exists, it should be listening the default port
    # we could check netstat, but this check actually talks to memcached
    if [[ $(memcached-tool 127.0.0.1:$port stats | awk '/accepting_conns/{ print $2 }' | tr -d '\r') -eq 1 ]]; then
        status=0
        text="$application is running"
    else
        status=2
        text="Unable to connect to $application"
    fi

    # Output results. Format: 
    item_name="$(tr '[:lower:]' '[:upper:]' <<< ${application:0:1})${application:1}"
    performance_data="-"
    check_output="$text"
    echo "$status $item_name $performance_data $check_output"
fi
