<#
.SYNOPSIS
    A function to send local notification to Lametric Time .
.DESCRIPTION
    A function to send local notification to a Lametric Time clock.You can send one message as a string or an object containing multiple messages .
    If you send one message it will be displayed based on the paramiters you select.If you send an object containing multiple messages it will be 
    sent as one notification.The Lametric Time will loop though all the messages and display them in the order they were stored in the object with the specified parameters .
.PARAMETER Ipaddress
    The Ipaddress of the Lametric Time .
.PARAMETER Port
    The Port used by the Lametric Time , currently this is always 8080 for local notifications .
.PARAMETER ApiKey
    The API key used by the Lametric Time , follow the guid at https://lametric-documentation.readthedocs.io/en/latest/guides/first-steps/first-local-notification.html 
    to find the API key .
.PARAMETER Messages
    The message or messages to send , see the examples .
.PARAMETER MessagesIcon
    The Icon that will be displayed with the message,find a list of Icons at https://developer.lametric.com/icons .The link also allows the creation of icons .
.PARAMETER Priority
    The priority the message will be given , more information at https://lametric-documentation.readthedocs.io/en/latest/reference-docs/device-notifications.html .
.PARAMETER IconType
    The IconType represents the nature of notification , more information at https://lametric-documentation.readthedocs.io/en/latest/reference-docs/device-notifications.html . 
.PARAMETER lifetime
    The time the notification lives in queue to be displayed in milliseconds , more information at https://lametric-documentation.readthedocs.io/en/latest/reference-docs/device-notifications.html . 
.PARAMETER Cycles
    The number of times notification should be displayed , more information at https://lametric-documentation.readthedocs.io/en/latest/reference-docs/device-notifications.html . 
.EXAMPLE
    Invoke-lametric -Ipaddress '10.0.0.1' -Messages 'Test notification' -MessagesIcon '20935' -Cycles 1 
    <Simple Example to that sends a message saying 'Test notification'>
.NOTES
    Author: Justin Fourie Date:   4 September 2018   
#>
function Invoke-lametric{
        [CmdletBinding()]
        param (
                [string]$Ipaddress = '10.0.0.1',
                [int]$Port  = '8080',
                [string]$ApiKey  ='dev:1' <# Place your API key e.g 'dev:343sgsag1441sdafasd414'#>,
                [string[]]$Messages = (''),
                [string]$MessagesIcon = '1036',
                [ValidateSet('info','warning','critical')][string]$Priority = 'info',
                [ValidateSet('none','info','alert')][string]$IconType = 'none',
                [int]$LifeTime = '1000',
                [int]$Cycles = 1      
        )   
        begin {
                # any thing in the begin only runs once
                $APIBIT  = [System.Text.Encoding]::UTF8.GetBytes("$ApiKey")
                $API64BIT = [System.Convert]::ToBase64String($APIBIT) 
                $Payload = ''  
        }
        process {
            # any thing you want to loop would run hear , Process block is called once for each item in the pipeline
            # Lets check how many messages we are sending 

            IF(@($Messages).length -eq 1) 
             {
              $Payload = '{"priority":"'+$Priority+'","icon_type":"'+$IconType+'","lifeTime":'+$LifeTime+',"model":{"frames":[{"icon":"'+$MessagesIcon+'","text":"' + $Messages[0]+'"}],"cycles":'+$Cycles+'}}';
             }      
            IF(@($Messages).length -gt 1) 
             {
              $Payload = '{"priority":"'+$Priority+'","icon_type":"'+$IconType+'","lifeTime":'+$LifeTime+',"model":{"frames":['
                foreach ($Message in $Messages) 
                        {
                          IF($Messages.IndexOf($Message) -ne (@($Messages).length-1))
                            {$Payload = $Payload + '{"icon":"'+$MessagesIcon+'","text":"' + $Message+'"},'}        
                          else {$Payload = $Payload + '{"icon":"'+$MessagesIcon+'","text":"' + $Message+'"}'}   
                        }
              $Payload = $Payload + '],"cycles":'+$Cycles+'}}'
             }
        
        }

        end { # this is where you would normaly place the output  
                $GetRequest = @{uri = 'http://'+$Ipaddress+':'+$Port+'/api/v2';
                                Method = 'GET';
                                Headers = @{Authorization = 'Basic '+$API64BIT +'';}
                               } 
                

                $MessagePost = @{uri = 'http://'+$Ipaddress+':'+$Port+'/api/v2/device/notifications';
                                 Method = 'POST';
                                 Headers = @{Authorization = 'Basic '+$API64BIT +'';"Content-Type" = 'application/json';}
                                 Body = $Payload 
                                    }
                # This seems to be a powershell / Dot Net bug if you dont make a get request you cant post a message to Lametric                 
                Invoke-RestMethod -UseBasicParsing @GetRequest -TimeoutSec 10 | Out-Null            
                Invoke-WebRequest -UseBasicParsing @MessagePost -TimeoutSec 30          

        }
    }
