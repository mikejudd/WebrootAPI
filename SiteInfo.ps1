#
# From http://pleasework.robbievance.net/howto-get-webroot-endpoints-using-unity-rest-api-and-powershell/
#
# Comments to review:
#
#    I did find an error on line 24 – instead of $APIUsername it should read $APIClientID
#    With multiple Sites, the code needs to be adjusted a bit (GSM Masterkeycode and Site Keycode)
#

# The base URL for which all REST operations will be performed against
$BaseURL = 'https://unityapi.webrootcloudav.com'
 
# The keycode for the site that you wish to extract endpoint details from
$Keycode = 'AAAA-BBBB-CCCC-DDDD-EEEE'
 
# An administrator user for your Webroot portal -- this is typically the same user you use to login to the main portal
$WebrootUser = 'user@company.com'
 
# This is typically the same password used to log into the main portal
$WebrootPassword = 'mypassword'
 
# This must have previously been generated from the Webroot GSM for the site you wish to view
$APIClientID = 'client_abcdefgh@company.com'
$APIPassword = 'generatedpassword'
 
# You must first get a token which will be good for 300 seconds of future queries.  We do that from here
$TokenURL = "$BaseURL/auth/token"
 
# Once we have the token, we must get the SiteID of the site with the keycode we wish to view Endpoints from
$SiteIDURL = "$BaseURL/service/api/console/gsm/$KeyCode/sites"
 
# All Rest Credentials must be first converted to a base64 string so they can be transmitted in this format
$Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($APIUsername+":"+$APIPassword ))
 
write-host "Processing connection 1 of 3 (Obtain an access token)" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $TokenURL
            "Headers" = @{"Authorization" = "Basic "+ $Credentials}
            "Body" = @{
                          "username" = $WebrootUser
                          "password" = $WebrootPassword
                          "grant_type" = 'password'
                          "scope" = '*'
                        }
            "Method" = 'post'
            "ContentType" = 'application/x-www-form-urlencoded'
            }
 
$AccessToken = (Invoke-RestMethod @Params).access_token
 
write-host "Processing connection 2 of 3 (Obtain the site ID for the provided keycode)" -ForegroundColor Green
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $SiteIDURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
 
$SiteID = (Invoke-RestMethod @Params).Sites.SiteId
 
write-host "Processing connection 3 of 3 (Get list of all endpoints and their details)" -ForegroundColor Green
$EndpointURL = "$BaseURL/service/api/console/gsm/$KeyCode/sites/$SiteID" +'/endpoints?PageSize=1000'
 
$Params = @{
            "ErrorAction" = "Stop"
            "URI" = $EndpointURL
            "ContentType" = "application/json"
            "Headers" = @{"Authorization" = "Bearer "+ $AccessToken}
            "Method" = "Get"
        }
 
$AllEndpoints = (Invoke-RestMethod @Params)
 
$AllEndpoints.Endpoints | Format-Table
