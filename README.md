# check_ports_notconnect

This is a script that presents information about unused (notconnect according to "show interface status" on Cisco switches) ports on (Cisco and probably other) switches.
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
Edit the script and make sure that the variable "tempdir" points to a directory that is writable by the user running the script (Usually nagios, icinga or monitor).
Also make sure that the variable "snmpwalk" points to snmpbulkwalk. 
Add this script as a service check for a switch in Op5 Monitor/Nagios/Icinga or whichever compatible monitoring system is your choice.
Apply the SNMP authentication information as variables to the service.

In case you have a setup with several monitoring peers, it might be usable to rsync the "tempdir" from crontab every now and then
so that the latest information about the switches is available to all the peers.

## Compability
I have tested this script with Cisco Catalyst 2960G, 2960-S, 2960-X and 3750G.
It should however work with other models and brands.
Let me know if you have a switch that supports SNMP and works or doesn't with this plugin.

Licensed under the Apache license version 2.0
Written by farid.joubbi@consign.se

## Version history:
1.0 2016-06-15  Initial version.

* http://www.consign.se/monitoring/

