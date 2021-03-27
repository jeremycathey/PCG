#Get Rubrik Cluster FQDN/IP
$Server = Read-Host -Prompt 'Enter Rubrik Cluster FQDN/IP'
#Gather Rubrik Credentials & Connect-Rubrik with Username/Password
$Creds = Get-Credential -Message 'Enter Rubrik Credentials'
$rbkConnect = Connect-Rubrik -Server $Server -Username $Creds.UserName -Password $Creds.Password

Function RA_GetAPIAuth{
    param([parameter(Mandatory=$true)]$Creds)
        Try{$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Creds.UserName + ':' + $Creds.GetNetworkCredential().Password))}
            catch{Write-Host 'Invalid Credential Format.  Exiting . . .'
                  exit}
        return $auth
}

function register_agents{
    param([parameter(Mandatory=$true)]$URI, [parameter(Mandatory=$true)]$Creds)

    #Create Auth for Basic API Authentication
    $auth = RA_GetAPIAuth -Creds $Creds
    $headers = @{
        'Content-Type'  = 'application/json';
        'Accept'        = 'application/json';
        'Authorization' = "Basic $auth";
    }
    $endpoint = 'https://' + $URI + '/api/internal/graphql'
    # Get number of vms Protected
    $payload = @{
        "operationName" = "FindVMDetails";
        "query"         = "query FindVMDetails
                          {
                           vmwareVirtualMachineConnection 
                            {
                                    nodes{
                                       name
                                       id
                                       }
                            }
                          }";
                 }

    $response = Invoke-RestMethod -Method POST -Uri $endpoint -Body $($payload | ConvertTo-JSON -Depth 100) -Headers $headers

    $RCount = $response.data.vmwareVirtualMachineConnection.nodes.count - 1

    $Count = 0
        do{

            #Create API Header with basic authorization and user input credentials
            $APIHeaders = @{
                        'Authorization' = "Basic $auth"
                        }
            #Create $Address to simplify Uri calls
            $Address = 'https://'+$URI

            $RA_params = @{
                Uri = $Address + '/api/v1/vmware/vm/' + $response.data.vmwareVirtualMachineConnection.nodes[$Count].id + '/register_agent'
                Headers= $APIHeaders
                Method = 'POST'
                ContentType = 'application/json'
            }

            try{$RA_Call = Invoke-RestMethod @RA_params}
            catch{}
            finally{$Error.Clear()}


            $Log1 = $response.data.vmwareVirtualmachineConnection.nodes[$Count].name
            $Log2 = $response.data.vmwareVirtualmachineConnection.nodes[$Count].id
            $Log3 = 'Register Agent Executed'

            $Log1 | Out-File ./register_agents.log -Append
            $Log2 | Out-File ./register_agents.log -Append
            $Log3 | Out-File ./register_agents.log -Append

        $Count += 1

        }until($Count -ge $RCount)

}

register_agents -URI $Server -Creds $Creds