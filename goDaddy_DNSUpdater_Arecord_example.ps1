#
#This script is used to check and update your GoDaddy DNS server to the IP address of your current internet connection.
#
# First go to GoDaddy developer site to create a developer account and get your key and secret
#
#https://developer.godaddy.com/getstarted
# 
#Update the first 4 varriables with your information
#
# to allow scripts to run, start powershell as administrator & execute     set-executionpolicy remotesigned
 #
#
$domain = 'somedomain.com'  # your domain
$name = 'sftp' #name of the A record to update
$key = 'xxxAPIKeyxxx' # key for godaddy developer API
$secret = 'xxxAPIKeySecretxxx' # Secret for godday developer API

$headers = @{}
$headers["Authorization"] = 'sso-key ' + $key + ':' + $secret
$result = Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/A/$name -method get -headers $headers
$content = ConvertFrom-Json $result.content
$dnsIp = $content.data

#Write-output ("dnsIP: " + $dnsIp)
# Extract Date/Time information for log time stamp
$a = Get-Date
$currentDate = $a.ToShortDateString()
$currentTime = $a.ToShortTimeString()

# Modify C:\ApplicationLogs\LogFile.txt to your directory/filename of preference
add-content C:\ApplicationLogs\LogFile.txt ("[" + $currentDate + " " + $currentTime + "]" + " dnsIP: " + $dnsIp)

# Get public ip address there are several websites that can do this.
$currentIp = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip
add-content C:\ApplicationLogs\LogFile.txt ("[" + $currentDate + " " + $currentTime + "]" + " ip in GoDaddy: " + $currentIp)


if ( $currentIp -ne $dnsIp) {
    add-content C:\ApplicationLogs\LogFile.txt ("[" + $currentDate + " " + $currentTime + "]" + "changing from " + $currentIp + " to dnsIP: " + $dnsIp)
    $Request = @{ttl=3600;data=$currentIp }
    $JSON = Convertto-Json $request
    Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/A/$name -method put -headers $headers -Body $json -ContentType "application/json"
}