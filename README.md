# check_ports_notconnect

This is a script that presents information about unused (notconnect) ports on (Cisco) switches.
The script outputs how many unused ports there are right now,
and the names of the ports with the amount of days they have been "down".
The number of unused ports is also sent as performance data so that it can be graphed.

The script saves the names of all the not connected ports with a timestamp so that the
information will be available even if the switch is rebooted.

The information about the ports is retrieved with SNMP.
Cisco switches reset the switchport status when rebooted.
Due to this the script saves the status in text files.
There will be one file created per switch.
Make sure that the script is able to write and read these files.
There is a variable at the top of the script that points to a directory where these files are saved.

## Usage
Edit the script and make sure that the variable "tempdir" points to a directory that is writable by the user running the script.
Also make sure that the variable "snmpwalk" points to snmpbulkwalk. 
Add this script as a service check in Op5/Nagios/Icinga... for a Cisco device.
Apply the SNMP authentication information as variables to the service.

If you have a setup with several monitoring peers, it might be usable to rsync the "tempdir" from crontab every now and then
so that the latest information about the switches is available to all the peers.

Licensed under the Apache license version 2.0
Written by farid.joubbi@consign.se

## Version history:
1.0 2016-06-15  Initial version.

* http://www.consign.se/monitoring/