#!/bin/bash
#
# MySQL, check if it is running
# If it's configured as a slave, check slave status
#


MK_CFGDIR='/etc/check-mk-agent'

application=$(basename $0 .sh)
port=3306

warnSlave=100
critSlave=300

if [[ -f $MK_CFGDIR/$application.cfg ]]; then
    source $MK_CFGDIR/$application.cfg
fi


MYSQL="mysql --defaults-extra-file=$MK_CFGDIR/mysql.cfg -s -B"

# Which mysql is running, mysqld or mysql?

MYSQLDAEMON=$(chkconfig --list | awk '{ print $1 }' | grep -E '^mysql')

if [[ $(chkconfig --levels 3 $MYSQLDAEMON ; echo $?) -eq 0 ]];
then
  if [[ $($MYSQL -e "show status;" &>/dev/null ; echo $?) -eq 0 ]]; then
        maxConnections=$($MYSQL -e "show variables like 'max_connections'" | cut -f2)
        status=0
        text="MySQL is running"
  else
        status=2
        text="Unable to connect to MySQL"
  fi
  performance_data="-"
  check_output="$text"
  item_name="MySQL"
  echo "$status $item_name $performance_data $check_output"



  # Now check for Slave
  slaveStatus=$($MYSQL -e 'show slave status\G' | awk '/Seconds_Behind_Master/{ print $2 }')

  if [[ -n $slaveStatus ]]; then
    # Is a server configured as a slave
    # Check running behind
    if [[ $slaveStatus == "NULL" ]]; then
        status=2
        text="Slave is NOT running"
    elif [[ $slaveStatus -gt $critSlave ]]; then
        status=2
        text="Slave is $slaveStatus seconds behind (level $critSlave)"
    elif [[ $slaveStatus -gt $warnSlave ]]; then
        status=1
        text="Slave is $slaveStatus seconds behind (level $warnSlave)"
    else
        status=0
        text="Slave is $slaveStatus seconds behind"
    fi
    performance_data="slave_status=$slaveStatus;$warnSlave;$critSlave"
    check_output="$text"
    item_name="MySQL_Slave"
    echo "$status $item_name $performance_data $check_output"
  fi

  # Is it a Galera Node? If so, please check the local-state
  galeraStatus=$($MYSQL -e 'show status like "wsrep_local_state_comment";' | awk '{ print $2 }')
  if [[ -n $galeraStatus ]]; then
    if [[ $galeraStatus == 'Synced' ]]; then
      status=0
    else 
      status=1
    fi
    check_output="Galera Node is $galeraStatus"
    performance_data="-"
    item_name="Galera"
    echo "$status $item_name $performance_data $check_output"
  fi


fi
