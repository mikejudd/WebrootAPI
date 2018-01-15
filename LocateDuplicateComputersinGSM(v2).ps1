## AMorgan Dec 2017.
## Finds duplicate agents for all by MAC Address in GSM.
## v1 of this script simply exported info for all endpoints (including non-duplicates) to "endpoints.csv".
## This version (v2) only gets info for duplicate entries, and puts them into "duplicates.csv".
## At the end it will give errors for each empty or deactivated site - this is ok.

##NOTE: if the working directory already contains a file name "duplicates.csv", this
##script will append entries to the end instead of replacing it, so delete your existing file
##before running it.

## Contains syntax from a script by Robbie Vance at  
## http://pleasework.robbievance.net/howto-get-webroot-endpoints-using-unity-rest-api-and-powershell/

##########------------------------------####
## These variables are specific to your console and credentials these variables.
# global GSM keycode (same for all admins and sites)
$GsmKey = 'XXXX-XXXX-XXXX-XXXX-XXXX'

# An administrator user for your Webroot portal -- this is typically the same user you use to login to the main portal
$WebrootUser = 'jdoe@mycompany.com'
 
# This is typically the same password used to log into the main portal
$WebrootPassword = 'xxxxxxxxxxxxxxxxxxxx'
 
# This must have previously been generated from the Webroot GSM for the site you wish to view
$APIClientID = 'client_hYFhneRES@mycompany.com'
$APIPassword = 'xxxxxxxxxxxxxxx'
##########------------------------------####


######################################
### These are common variables that you don't need to change
# The base URL for which all REST operations will be performed against
$BaseURL = 'https://unityapi.webrootcloudav.com'
 
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


# Loop through every site, get endpoint info for each.
write-host "Getting endpoint info for site $mySiteName"
(Invoke-RestMethod @Params).Sites | 
	ForEach-Object {
		$mySiteName = $_.SiteName #Get name of site for which we're about to list endpoints
		write-host $mySiteName
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"

		## New array for the GET request we'll be sending for each site
		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# Get all endpoints for this site. Add properties for SiteName and Duplicate (yes/no).
		$mySite = (Invoke-RestMethod @Params2).Endpoints | 
			foreach-object {$_|add-member -type noteproperty -name SiteName -value $mySiteName;$_} | 
			foreach-object {$_|add-member -type noteproperty -name Duplicate -value $false;$_} | 
			Where-Object {$_.Deactivated -eq $false} | 
			Select-Object SiteName,HostName,MACAddress,LastSeen,EndpointId,Duplicate | 
			Sort-Object MACAddress,LastSeen
	
		#Mark duplicates
		$MACcount = $mySite | group-object -Property MACAddress | Where-Object -Filter {$_.Count -ge "2"}
		$mySite | Foreach-Object {if ($MACcount.Name -contains $_.MACAddress) {$_.Duplicate = $true}}
		#add duplicates to growing csv file
		$mySite | Where-Object -Filter {$_.Duplicate -eq $true} | Export-Csv -Append -Path "Duplicates.csv"

	}
write-host ""
write-host "--------------------------------"
write-host "Script Finished"
exit
