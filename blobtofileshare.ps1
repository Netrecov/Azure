# Authenticate to Azure
$TenantId = "your-tenant-id"
$AppId = "your-app-id"
$Secret = ConvertTo-SecureString "your-app-secret" -AsPlainText -Force
$PSCredential = New-Object System.Management.Automation.PSCredential($AppId, $Secret)
Connect-AzAccount -ServicePrincipal -Credential $PSCredential -TenantId $TenantId

# Define Variables
$resourceGroup = "your-resource-group"
$storageAccountName = "your-storage-account"
$containerName = "your-container"
$fileShareName = "your-file-share"
$domainAccount = "your-domain\\your-username"
$domainPassword = "your-domain-password"

# Mount the Azure File Share
$networkPath = "\\$storageAccountName.file.core.windows.net\$fileShareName"
$securePassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($domainAccount, $securePassword)

New-PSDrive -Name "AzureFileShare" -PSProvider FileSystem -Root $networkPath -Persist -Credential $credentials

# Access Blob Storage and Copy Files
$blobServiceClient = Get-AzStorageAccount -ResourceGroupName $resourceGroup -AccountName $storageAccountName
$container = Get-AzStorageContainer -Context $blobServiceClient.Context -Name $containerName
$blobs = Get-AzStorageBlob -Container $container.Name -Context $blobServiceClient.Context

foreach ($blob in $blobs) {
    $blobName = $blob.Name
    $fileSharePath = "AzureFileShare:\$blobName"
    
    # Download the Blob directly to the File Share
    $blob | Get-AzStorageBlobContent -Destination $fileSharePath -Context $blobServiceClient.Context
}

# Cleanup
Remove-PSDrive -Name "AzureFileShare"
