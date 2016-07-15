#!/bin/sh

##########################################################################################
#                                                                                        #
# A script for presenting information about unused (notconnect) ports on switches.       #
# The script outputs how many unused ports there are right now,                          #
# and the names of the ports with the amount of days they have been "down".              #
# The number of unused ports is also sent as performance data so that it can be graphed. #
#                                                                                        #
# The script saves the name of the ports with a timestamp so that the                    #
# information will be available even if the switch is rebooted.                          #
#                                                                                        #
# USAGE:                                                                                 #
# Edit the "snmpwalk" and "tempdir" variables in this script below.                      #
# Add this script as a service check in Op5/Nagios/Icinga... for a Cisco device.         #
# Apply the SNMP authentication information as variables to the service.                 #
#                                                                                        #
# Version history:                                                                       #
# 1.1 2016-07-15  Fixed a critical bug.
# 1.0 2016-06-16  Initial version.                                                       #
#                                                                                        #
# Licensed under the Apache license version 2.0                                          #
# Written by Farid.Joubbi@consign.se                                                     #
#                                                                                        #
##########################################################################################



# Make sure that this points to snmpbulkwalk. snmpwalk works too, but snmpbulkwalk is better.
snmpwalk="/usr/bin/snmpbulkwalk"

# Temporary filenames. Make sure that the tempdir exists and is writable by the user running this script.
tempdir="/opt/monitor/var/check_ports_notconnect"
snmp_file=$(mktemp)
interface_file="$tempdir/ports_down_$1"

# This timestamp is used throughout the scrpit.
datestamp=`date +%s`

if [ $# == 6 ]; then
  snmpopt="-v 3 -l authPriv -u $2 -a $3 -A $4 -x $5 -X $6 $1 -On -Lo"
fi

if [ $# == 2 ]; then
  snmpopt="-v 2c -c $2 $1 -Ov -t 0.5 -Lo"
fi

if [ $# != 2 ] && [ $# != 6 ]; then
  echo "Wrong amount of arguments!"
  echo
  echo "Usage:"
  echo "SNMPv2c: ./check_ports_notconnect.sh HOSTNAME community"
  echo "SNMPv3: ./check_ports_notconnect.sh HOSTNAME username MD5/SHA authpass DES/AES privpass"
  exit 3
fi


# Read and store interface entries, exit on error.
$snmpwalk $snmpopt 1.3.6.1.2.1.2.2.1.1 > "$snmp_file"
if [ "$?" != 0 ]; then
  echo "Something went wrong communicating with the SNMP agent on "$1"!"
  exit 3
fi
$snmpwalk $snmpopt 1.3.6.1.2.1.2.2.1.2 >> "$snmp_file" 2>/dev/null
$snmpwalk $snmpopt 1.3.6.1.2.1.2.2.1.8 >> "$snmp_file" 2>/dev/null

# The file does not exist the first run. Create it.
if [ ! -f "$interface_file" ]; then
  touch "$interface_file"
  if [ $? != 0 ]; then
    echo "Something went wrong when creating "$interface_file"!"
    exit 3
  fi
fi


# Get interface indexes.
indexes=$(sed -n -e "s/.1.3.6.1.2.1.2.2.1.1.\([0-9]\+\).*/\1/p" "$snmp_file")

# Get the name and operational status of the interfaces, store interfaces that are down with the oldest timestamp.
for index in $indexes; do
  ifDescr=$(sed -n -e "s/.1.3.6.1.2.1.2.2.1.2.${index} = .*: \(.*\)/\1/p" "$snmp_file" | tr -d \")
  ifOperStatus=$(sed -n -e "s/.1.3.6.1.2.1.2.2.1.8.${index} = .*: \(.*\)/\1/p" "$snmp_file")
  if [[ "$ifOperStatus" == *"down"* && "$ifDescr" != *"Stack"* && "$ifDescr" != *"Vlan"* ]]; then
    grep -w "$ifDescr" "$interface_file" >> "$interface_file"-latest
    if [ $? != 0 ]; then
      printf "%s!%s\n" "$ifDescr" "$datestamp" >> "$interface_file"-latest
    fi
  fi
done


# remove temporary files
unlink "$snmp_file"
mv "$interface_file"-latest "$interface_file"

notconnected_interfaces=`wc -l < "$interface_file"`

# Print the contents of the gathered data in preferred format
printf "%s %s %s %s %s\n" "$notconnected_interfaces" 'interfaces not connected' `date -d @"$datestamp" +'%Y-%m-%d %H:%M:%S'` "| 'Not connected interfaces'="$notconnected_interfaces""
while read LINE; do
  printf "%s\t%s %s\n" `echo "$LINE" | cut -d! -f1` $(( ($datestamp - `echo "$LINE" | cut -d! -f2`) / 86400 )) 'days' 
done < "$interface_file"
exit 0

