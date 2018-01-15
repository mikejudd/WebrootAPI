## AMorgan Dec 2017.
## Outputs csv containing policy and other info for all endpoints at all sites.
## Intended to help locate machines incorrectly set to the wrong policy.

## Includes syntax from a script by Robbie Vance at 
## http://pleasework.robbievance.net/howto-get-webroot-endpoints-using-unity-rest-api-and-powershell/

# The base URL for which all REST operations will be performed against
$BaseURL = 'https://unityapi.webrootcloudav.com'

# ACM - global GSM keycode (same for all admins and sites)
$GsmKey = 'XXXX-XXXX-XXXX-XXXX'

# An administrator user for your Webroot portal -- this is typically the same user you use to login to the main portal
$WebrootUser = 'jdoe@mycompany.com'
 
# This is typically the same password used to log into the main portal
$WebrootPassword = 'xxxxxxxxxxxxxxxxxxx'
 
# This must have previously been generated from the Webroot GSM for the site you wish to view
$APIClientID = 'client_xXXxxXXXY@mycompany.com'
$APIPassword = 'xxxxxxxxxxxxxxx'
 
# You must first get a token which will be good for 300 seconds of future queries.  We do that from here
$TokenURL = "$BaseURL/auth/token"
 
# Once we have the token, we must get the SiteID of the site with the keycode we wish to view Endpoints from
$SiteIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites"
 
# All Rest Credentials must be first converted to a base64 string so they can be transmitted in this format
$Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($APIClientID+":"+$APIPassword ))
 
write-host "Get token" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $TokenURL
            "Headers" = @{"Authorization" = "Basic "+ $Credentials}
            "Body" = @{
                          "username" = $WebrootUser
                          "password" = $WebrootPassword
                          "grant_type" = 'password'
                          "scope" = 'Console.GSM'
                        }
            "Method" = 'post'
            "ContentType" = 'application/x-www-form-urlencoded'
            }
 
$AccessToken = (Invoke-RestMethod @Params).access_token

write-host "Get sites data" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $SiteIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }

# For every site, get endpoint info and append to csv.
(Invoke-RestMethod @Params).Sites | 
	ForEach-Object {
		$mySiteName = $_.SiteName #Get name of site for which we're about to list endpoints
		write-host ""
		write-host "Getting endpoint info for site $mySiteName"
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"
		# New array for the GET request we'll be sending for each site
		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# List all endpoints for this site, showing only desired properties.  Add SiteName as extra property to each item in object. Filter-out deactivated entries.
		(Invoke-RestMethod @Params2).Endpoints | 
			foreach-object {$_|add-member -type noteproperty -name SiteName -value $mySiteName;$_} | 
			Where-Object {$_.Deactivated -eq $false} | 
			Select-Object -Property SiteName,HostName,PolicyName,Mac,MACAddress,LastSeen,EndpointId | 
			Sort-Object SiteName,PolicyName,Hostname | 
			Export-Csv -Append -Path "PolicyAudit.csv"

	}
write-host ""
write-host "--------------------------------"
write-host "Script Finished"
exit
