## Based on a script by Robbie Vance at 
## http://pleasework.robbievance.net/howto-get-webroot-endpoints-using-unity-rest-api-and-powershell/

## AMorgan Dec 2017.
## Example gets token in GSM scope, gets info on all sites in GSM console, and lists a few properties of each in table format.


# The base URL for which all REST operations will be performed against
$BaseURL = 'https://unityapi.webrootcloudav.com'
 
# Global GSM keycode (same for all admins and sites)
$GsmKey = 'XXXX-XXXX-XXXX-XXXX-XXXX'

# An administrator user for your Webroot portal -- this is typically the same user you use to login to the main portal
$WebrootUser = 'jdoe@mycompany.com'
 
# This is typically the same password used to log into the main portal
$WebrootPassword = 'xxxxxxxxxxxxxxxxxxxxxxx'
 
# This must have previously been generated from the Webroot GSM under "API Access" tab
$APIClientID = 'client_jJRshURI@mycompany.com'
$APIPassword = 'xxxxxxxxxxxxxx'
 
# You must first get a token which will be good for 300 seconds of future queries.  We do that from here
$TokenURL = "$BaseURL/auth/token"
 
# Once we have the token, we must get the SiteID of the site with the keycode we wish to view Endpoints from
$SiteIDURL = "$BaseURL/service/api/console/gsm/$GsmKey/sites"
 
# All Rest Credentials must be first converted to a base64 string so they can be transmitted in this format
$Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($APIClientID+":"+$APIPassword ))
 
write-host "Getting Token" -ForegroundColor Green
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


write-host "Getting info" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $SiteIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }

# Now we use Invoke-RestMethod to grab "Sites" - this also converts
# it from json to a normal Powershell object that we can parse and display
# using standard syntax.

(Invoke-RestMethod @Params).Sites | format-table SiteName,SiteId

exit
