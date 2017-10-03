#
# Update DNS A record in CloudFlare with external IP address
#
# Adapted from information on this blog:
# https://blog.netnerds.net/2015/12/powershell-invoke-restmethod-cloudflare-api-v4-code-sample/
# Set auth and subdomain information
# API token from CloudFlare
$token = "xxxxxxKeepSecretxxxxxx"
# CloudFlare email signon
$email = "someuser@somedomain.com"
# Domain Name on CloudFlare
$domain = "somedomain.com"
# The record to add/update
$record = "sftp"

# Extract date/time stamp information for log messages
$a = Get-Date
$currentDate = $a.ToShortDateString()
$currentTime = $a.ToShortTimeString()
 
# Get external IP
$ipaddr = Invoke-RestMethod http://ipinfo.io/json | Select-Object -ExpandProperty ip

Write-Output "External ip is  $($ipaddr)"
 
$baseurl = "https://api.cloudflare.com/client/v4/zones"
$zoneurl = "$baseurl/?name=$domain"
 
# To login use...
$headers2 = @{
 'X-Auth-Key ' = $token
 'X-Auth-Email ' = $email
 'Content-Type ' = 'application/json'
}


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Auth-Key", $token)
$headers.Add("X-Auth-Email", $email)
$headers.Add("Content-Type", 'application/json')

  
# Get Zone info for the domain
$zone = Invoke-RestMethod -Uri $zoneurl -Method Get -Headers $headers
$zoneid = $zone.result.id
 
$recordurl = "$baseurl/$zoneid/dns_records?name=$record.$domain&type=A"

# Write-Output "record url is $($recordurl)"
 
# Get current DNS record
$dnsrecord = Invoke-RestMethod -Uri $recordurl -Method Get -Headers $headers

$currentDNSIp = $($dnsrecord.result.content)
Write-output "current ip registered is $($dnsrecord.result.content)"

# Upodate C:\ApplicationLogs\LogFile.txt to your directory/filename of preference
add-content C:\ApplicationLogs\LogFile.txt ("[" + $currentDate + " " + $currentTime + "]" + " ip queried: " + $ipaddr)
add-content C:\ApplicationLogs\LogFile.txt ("[" + $currentDate + " " + $currentTime + "]" + " ip in CloudFlare: " + $currentDNSIp)

 
# If it exists, update, if not, add
if ($dnsrecord.result.count -gt 0) {

 if ($currentDNSIp -eq $ipaddr) 
 {
 	Write-output "DNS ip $($currentDNSIp) matches queried ip $($ipaddr)"
 }
 else {
 
	 Write-output "Updating DNS ip from $($currentDNSIp) to queried ip $($ipaddr)"
   add-content C:\ApplicationLogs\LogFile.txt  ("[" + $currentDate + " " + $currentTime + "]" + " ip changing from " + $currentDNSIp + " to dnsIP: " + $ipaddr)

	 $recordid = $dnsrecord.result.id 
	 $dnsrecord.result | Add-Member "content"  $ipaddr -Force 
	 $body = $dnsrecord.result | ConvertTo-Json 
	 
	 $updateurl = "$baseurl/$zoneid/dns_records/$recordid/" 
	 $result = Invoke-RestMethod -Uri $updateurl -Method Put -Headers $headers -Body $body
	 
	 Write-Output "Record $record.$domain has been updated to the IP $($result.result.content)"
 }
} else {
 $newrecord = @{
 "type" = "A"
 "name" =  "$record.$domain"
 "content" = $ipaddr
 }
 
 $body = $newrecord | ConvertTo-Json
 $newrecordurl = "$baseurl/$zoneid/dns_records"
 $request = Invoke-RestMethod -Uri $newrecordurl -Method Post -Headers $headers -Body $body -ContentType "application/json"
 Write-Output "New record $record.$domain has been created with the ID $($request.result.id)"
}