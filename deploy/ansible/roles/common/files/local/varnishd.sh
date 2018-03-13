#!/bin/bash

MK_CFGDIR='/etc/check-mk-agent'

application=$(basename $0 .sh)

# default values, override by creating config file at MK_CFGDIR
port=6081

if [[ -f $MK_CFGDIR/$application.cfg ]]; then
    source $MK_CFGDIR/$application.cfg
fi

if [[ $(chkconfig --levels 3 varnish ; echo $?) -eq 0 ]];
then
	# Determine Varnish version. 
	if [[ $(varnishstat -1 | head -n1 | sed 's/MAIN\(.*\)/MAIN/') == "MAIN" ]]; then
		varnishversion=4
		fieldlist="-f MAIN.uptime -f MAIN.cache_hit -f MAIN.cache_miss -f MAIN.cache_hitpass -f MAIN.n_object -f MAIN.client_req -f MAIN.backend_req -f MAIN.backend_busy"
	else
		varnishversion=3
		fieldlist="-f uptime,cache_hit,cache_miss,cache_hitpass,n_object,client_req,backend_req,backend_busy"
	fi
    # Application exists, it should be listening the default port
    if [[ $(service varnish status &> /dev/null ; echo $?) -eq 0 ]]; then
        status=0
        laststats=/tmp/varnishstat.last
        prevstats=/tmp/varnishstat.previous

        # Create a temporary dump of current vars, with a timestamp in seconds (for diffing the counters):
        varnishstat -1 $fieldlist > $laststats

        # diff the current counters with the previous counters
        cache_hit_last=$(awk '($1 ~ "cache_hit$"){ print $2 }' $laststats)
        cache_miss_last=$(awk '($1 ~ "cache_miss$"){ print $2 }' $laststats)
        cache_hitpass_last=$(awk '($1 ~ "cache_hitpass$"){ print $2 }' $laststats)
        uptime_last=$(awk '($1 ~ "uptime$"){ print $2 }' $laststats)
        client_req_last=$(awk '($1 ~ "client_req$"){ print $2 }' $laststats)
        backend_req_last=$(awk '($1 ~ "backend_req$"){ print $2 }' $laststats)
        backend_busy_last=$(awk '($1 ~ "backend_busy$"){ print $2 }' $laststats)
        objects=$(awk '($1 ~ "n_object$"){ print $2 }' $laststats)


        if [ -f $prevstats ]; then
            cache_hit_prev=$(awk '($1 ~ "cache_hit$"){ print $2 }' $prevstats)
            cache_miss_prev=$(awk '($1 ~ "cache_miss$"){ print $2 }' $prevstats)
            cache_hitpass_prev=$(awk '($1 ~ "cache_hitpass$"){ print $2 }' $prevstats)
            uptime_prev=$(awk '($1 ~ "uptime$"){ print $2 }' $prevstats)
            client_req_prev=$(awk '($1 ~ "client_req$"){ print $2 }' $prevstats)
            backend_req_prev=$(awk '($1 ~ "backend_req$"){ print $2 }' $prevstats)
            backend_busy_prev=$(awk '($1 ~ "backend_busy$"){ print $2 }' $prevstats)

        fi
        cache_hit=$(($cache_hit_last-${cache_hit_prev:=0}))
        cache_miss=$(($cache_miss_last-${cache_miss_prev:=0}))
        cache_hitpass=$(($cache_hitpass_last-${cache_hitpass_prev:=0}))
        timediff=$(($uptime_last-${uptime_prev:=0}))

        if [[ $timediff -eq 0 ]]; then 
            timediff=1
        fi

        client_req=$(($client_req_last-${client_req_prev:=0}))
        client_req_sec=$(($client_req/$timediff))
        backend_req=$(($backend_req_last-${backend_req_prev:=0}))
        backend_req_sec=$(($backend_req/$timediff))
        backend_busy=$(($backend_busy_last-${backend_busy_prev:=0}))
        backend_busy_sec=$(($backend_busy/$timediff))


        if [[ $cache_miss -eq 0 ]] ; then
            cache_miss=1
        fi
        hitrate=$(echo "($cache_hit + $cache_hitpass) / ( $cache_hit + $cache_miss + $cache_hitpass ) * 100" | bc -l)


        performance_data="hitrate=$(printf "%0.2f" $hitrate)|objects=$objects|req_sec=$client_req_sec|backend_req_sec=$backend_req_sec|backend_busy_sec=$backend_busy_sec"
        text="$application is running. Hitrate $(printf "%0.2f" $hitrate)%. $client_req_sec req/sec"


        #Rotate last -> prev
        mv -f $laststats $prevstats

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
