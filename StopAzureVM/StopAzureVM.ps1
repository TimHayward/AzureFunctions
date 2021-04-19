# Input bindings are passed in via param block.
param($Timer)
    Write-Host "Get Credentials"
    # define the following variables
    $ApplicationID =    "xxxxxxxx-aaaa-aaaa-bbbb-cccccccccccc"
    $TenantDomainName = "xxxxxxxx-aaaa-aaaa-bbbb-cccccccccccc"
    $AccessSecret =     "asdfghjklzxcvbnm"
    $Subscription = "xxxxxxxx-aaaa-aaaa-bbbb-cccccccccccc"
    $ResourceGroup = "RGNAME"


    $Body = @{
    Grant_Type = "client_credentials"
    Scope = "https://management.azure.com/.default"
    client_Id = $ApplicationID
    Client_Secret = $AccessSecret
    }
    # make initial connection to Graph
    Write-Host "connect"
    $ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token" -Method POST -Body $Body
    #get the token
    $token = $ConnectGraph.access_token

    # now do things...
    Write-Host "get devices"
    $Devices = Invoke-RestMethod -Method Get -uri "https://management.azure.com/subscriptions/$Subscription/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines?api-version=2020-12-01" -Headers @{ "Authorization" = "Bearer $token"} | Select-Object -ExpandProperty Value
    Write-Host "process devices"
    foreach ($Device in $Devices){
        $DeviceName = $Device.Name
        $State = Invoke-RestMethod -Method Get -uri "https://management.azure.com/subscriptions/$Subscription/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$DeviceName/InstanceView?api-version=2020-12-01" -Headers @{ "Authorization" = "Bearer $token"} | Select-Object -ExpandProperty Statuses
            if ($state.code[1] -eq "PowerState/running") {
                Write-Host "VM Running"
            }
            if ($state.code[1] -eq "PowerState/deallocated") {
                Write-Host "VM Deprovisioned"
            }
            if ($state.code[1] -eq "PowerState/stopped") {
                Write-Host "VM Stopped"
                Write-Host "Stopping VM"
                Invoke-RestMethod -Method POST -uri "https://management.azure.com/subscriptions/$Subscription/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$DeviceName/deallocate?api-version=2020-12-01" -Headers @{ "Authorization" = "Bearer $token"}
            }

    }
