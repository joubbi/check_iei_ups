.SYNOPSIS
This is a PowerShell script used by NSClient++ to check the status of an
iEi Technology Corp. AUPS series VESA Mount Intelligent UPS Module.
NSClient++ can then be called by Nagios (Op5 Monitor, Icinga or similar) to run this script.

.DESCRIPTION
This script assumes that the UPS is reachable over the network.
This means that you have to run "AUPS Battery Status Monitor" first
in order to set an IP address on the battery and to "Enable LAN".
Then you need to run the tool "IEI REMOTE AP" in order to activate the
web server in the battery by clicking the IP address of the battery.

The IP address that you configure in the above step is the variable
battery_address used by this script.

Optional parameters:
-battery_address [IP address or FQDN of the battery]
-capacity_warning [warning level for the capacity]
-capacity_critical [critical level for the capacity]
-temperature_warning [warning level for the temperature]
-temperature_critical [critical level for the temperature]
-shutdown, The computer running this script will shut down if this switch is supplied and the capacity is below 10% ($shutdown_capacity)

The script outputs something like this:
Battery status: Standby | status=2 capacity=100%;40;10 voltage=16690 Current=0 Temperature=33;50;60 'Remaining time'=0

.EXAMPLE
.\check_iei_ups.ps1 192.168.0.10

.EXAMPLE
.\check_iei_ups.ps1 -battery_address 192.168.0.10 -capacity_warning 40 -capacity_critical 10 -temperature_warning 40 -temperature_critical 50 -shutdown

.NOTES
Licensed under the Apache license version 2.
Written by farid.joubbi@consign.se

Tested with an AUPS-B10 and should work with the other models.

Version history:
1.0 2016-04-19 initial version.

.LINK
http://www.consign.se/monitoring/
http://nsclient.org/
http://tw.ieiworld.com/