<#

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
#>

param (
    [ValidateScript({$_ -match [IPAddress]$_ })]  
    [String]$battery_address = '192.168.0.10',

    [ValidateRange(0,100)]
    [Int]
    [string]$capacity_warning = 40,
    [ValidateRange(0,100)]
    [Int]
    [string]$capacity_critical = 10,

    [ValidateRange(0,200)]
    [Int]
    [string]$temperature_warning = 50,
    [ValidateRange(0,200)]
    [Int]
    [string]$temperature_critical = 60,
    
    [switch]$shutdown
)

$shutdown_capacity = 10
$plugin_status = 'OK'
$status_bool = 3

try {
    $result = Invoke-RestMethod http://$battery_address/status.xml
}
catch {
    write-host 'Cannot communicate with battery!'
    exit 3
}

$ups_status = @{
    Status = $result.response.pot1
    Capacity = $result.response.pot2
    Voltage = $result.response.pot3
    Current = $result.response.pot4
    Temperature = $result.response.pot5
    Time = $result.response.pot6
}



if ($ups_status.Status -eq 'Standby'){
    $status_bool = 2
}
if ($ups_status.Status -eq 'Charging'){
    $status_bool = 1
}
if ($ups_status.Status -eq 'USE'){
    $status_bool = 0
}


# ups_status.Capacity is not an integer. Convert
[int]$capacity = [convert]::ToInt32($ups_status.Capacity, 10)

if ($capacity -le $capacity_warning) {
    $plugin_status = 'WARNING'
}
if ($capacity -le $capacity_critical) {
    $plugin_status = 'CRITICAL'
}

if ($ups_status.Temperature -gt $temperature_warning) {
    $plugin_status = 'WARNING'
}
if ($ups_status.Temperature -gt $temperature_critical) {
    $plugin_status = 'CRITICAL'
}

if ($ups_status.Time -like "Not Used*"){
    $ups_status.Time = 0
}

if ($shutdown -and $ups_status.Capacity -le $shutdown_capacity){
    Stop-Computer -Force
}


$status_string = "status={0} capacity={1}%;{2};{3} voltage={4} Current={5} Temperature={6};{7};{8} 'Remaining time'={9}" -f
$status_bool, $capacity, $capacity_warning, $capacity_critical, $ups_status.Voltage, $ups_status.Current, $ups_status.Temperature, $temperature_warning, $temperature_critical, $ups_status.Time
write-host 'Battery status:' $ups_status.Status '|'$status_string

if ($plugin_status -eq 'WARNING') { exit 1 }
if ($plugin_status -eq 'CRITICAL') { exit 2 }
if ($status_bool -eq 3) { exit 3 }
exit 0