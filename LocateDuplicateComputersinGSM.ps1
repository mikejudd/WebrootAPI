## Based on a script by Robbie Vance at 
## http://pleasework.robbievance.net/howto-get-webroot-endpoints-using-unity-rest-api-and-powershell/

## AMorgan Dec 2017.
## We already know how to get an object containing with all properties for all Sites.
## This example builds on that, and loops through multiple sites to get endpoint info for each.
## It then exports all endpoints to csv, sorted by Site,MAC, and LastSeen date, to help with finding duplicates.

# The base URL for which all REST operations will be performed against
$BaseURL = 'https://unityapi.webrootcloudav.com'

# ACM - global GSM keycode (same for all admins and sites)
$GsmKey = 'XXXX-XXXX-XXXX-XXXX-XXXX'

# An administrator user for your Webroot portal -- this is typically the same user you use to login to the main portal
$WebrootUser = 'jdoe@mycompany.com'
 
# This is typically the same password used to log into the main portal
$WebrootPassword = 'xxxxxxxxxxxxxxxxxxxx'
 
# This must have previously been generated from the Webroot GSM for the site you wish to view
$APIClientID = 'client_rNguIW@mycompany.com'
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

# Note: the following comment blocks each have a little example I used while building the final block at the end.
# They can be uncommented and followed by an "exit" line to debug your code.
		
# Now we can use Invoke-RestMethod to grab "Sites" - this also converts
# it from json to a normal Powershell object that we can parse and display
# using standard syntax.
#(Invoke-RestMethod @Params).Sites | format-table SiteName,SiteId
#write-host "SiteID"
#write-host $SiteID

# Try filtering site results on some arbitrary property, just to down to a short list for testing.
# This example filters-out all sites except those with 10 endpoints.
#(Invoke-RestMethod @Params).Sites | Where-Object { $_.TotalEndpoints -eq "10" }

# Try simply displaying the SiteName property for each item
#(Invoke-RestMethod @Params).Sites | 
#	Where-Object { $_.TotalEndpoints -eq "10" } | 
#	ForEach-Object {
#		write-host $_.SiteName
#	}

#We'd like to get a list of endpoints for each site. But first we'll check that we're creating the correct URI for each.
#(Invoke-RestMethod @Params).Sites | 
#	Where-Object { $_.TotalEndpoints -eq "10" } | 
#	ForEach-Object {
#		$mySiteID = $_.SiteId
#		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"
#		write-host $EndpointIDURL
#	}


#Now we'll try doing something with all those site URIs, namely listing every endpoint for that site, along with 
#a few specific properties for each.
<#
(Invoke-RestMethod @Params).Sites | 
	Where-Object { $_.TotalEndpoints -eq "10" } | 
	ForEach-Object {
		write-host ""
		write-host $_.SiteName #Output name of site for which we're about to list endpoints
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"
		# write-host $EndpointIDURL #This is for debugging only
		## New array for the GET request we'll be sending for each site
		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# List all endpoints for this site, showing only desired properties
		(Invoke-RestMethod @Params2).Endpoints | Sort-Object MACAddress | Format-Table -Property HostName,MACAddress,LastSeen,EndpointId
		#write-host "press any key"
		#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
#>

# Now we'll instead try outputting all these endpoints to the same csv file
<#
(Invoke-RestMethod @Params).Sites | 
	Where-Object { $_.TotalEndpoints -eq "10" } | 
	ForEach-Object {
		$mySiteName = $_.SiteName #Get name of site for which we're about to list endpoints
		write-host ""
		write-host "Getting endpoint info for site $mySiteName"
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"
		# write-host $EndpointIDURL #This is for debugging only
		## New array for the GET request we'll be sending for each site
		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# List all endpoints for this site, showing only desired properties
		(Invoke-RestMethod @Params2).Endpoints | Select-Object -Property HostName,MACAddress,LastSeen,EndpointId | Sort-Object MACAddress | Export-Csv -Append -Path "endpoints.csv"
		#write-host "press any key"
		#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
#>

#Now let's add the "SiteName" property to each item, and output all endpoints sorted by SiteName and then MACAddress, so we can more easily find duplicates by Mac.
<#
(Invoke-RestMethod @Params).Sites | 
	Where-Object { $_.TotalEndpoints -eq "10" } | 
	ForEach-Object {
		$mySiteName = $_.SiteName #Get name of site for which we're about to list endpoints
		write-host ""
		write-host "Getting endpoint info for site $mySiteName"
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"
		# write-host $EndpointIDURL #This is for debugging only
		## New array for the GET request we'll be sending for each site
		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# List all endpoints for this site, showing only desired properties.  Add SiteName as extra property to each item in object
		(Invoke-RestMethod @Params2).Endpoints | foreach-object {$_|add-member -type noteproperty -name SiteName -value $mySiteName;$_} | Select-Object -Property SiteName,HostName,MACAddress,LastSeen,EndpointId | Sort-Object SiteName,MACAddress | Export-Csv -Append -Path "endpoints.csv"

		#write-host "press any key"
		#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
#>


# Finally, since we're done testing our code, we'll just remove the "Where-Object" filter so we get a list of all sites and their endpoints.
# I also made it sort by the additional property LastSeen to make finding duplicates even faster.
# Note: the above example didn't filter-out deactivated sites, which caused errors to be returned for these at end of script.
(Invoke-RestMethod @Params).Sites | 
	ForEach-Object {
		$mySiteName = $_.SiteName #Get name of site for which we're about to list endpoints
		write-host ""
		write-host "Getting endpoint info for site $mySiteName"
		$mySiteID = $_.SiteId
		$EndpointIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites/$mySiteId/endpoints"
		# write-host $EndpointIDURL #This is for debugging only
		## New array for the GET request we'll be sending for each site
		$Params2 = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
		# List all endpoints for this site, showing only desired properties.  Add SiteName as extra property to each item in object
		(Invoke-RestMethod @Params2).Endpoints | foreach-object {$_|add-member -type noteproperty -name SiteName -value $mySiteName;$_} | Select-Object -Property SiteName,HostName,MACAddress,LastSeen,EndpointId | Sort-Object SiteName,MACAddress,LastSeen | Export-Csv -Append -Path "endpoints.csv"

		#write-host "press any key"
		#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
write-host ""
write-host "--------------------------------"
write-host "Script Finished"
exit
