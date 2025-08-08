# Step 1: Define necessary variables for authentication and resource details
$tenantId = "<your-tenant-id>"
$appId = "<your-client-id>"        # Service Principal Application ID
$clientSecret = "<your-client-secret>"  # Service Principal Client Secret
$storageAccountName = "<your-storage-account-name>"
$containerName = "<your-container-name>"
$fileShareName = "<your-file-share-name>"

# Step 2: Authenticate to Azure using Service Principal
$psCredential = New-Object System.Management.Automation.PSCredential($appId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Connect-AzAccount -ServicePrincipal -Credential $psCredential -TenantId $tenantId

# Step 3: Create Blob Storage context using Service Principal
$context = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# Step 4: Authenticate to Azure File Share using the same Service Principal

# Use Azure File Share AAD authentication for Service Principal
$storageAccountResourceId = "/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group>/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
$azFilesContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# Step 5: List all blobs in the container and move them to Azure File Share
$blobs = Get-AzStorageBlob -Container $containerName -Context $context

foreach ($blob in $blobs) {
    $blobName = $blob.Name
    
    Write-Host "Downloading blob: $blobName"

    # Download the blob into memory (directly into the script's context, no local storage)
    $blobContent = Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Context $context -Force

    # Now upload the content to the Azure File Share directly (via Azure AD authentication)
    Write-Host "Uploading $blobName to Azure File Share"

    $fileSharePath = "\\$storageAccountName.file.core.windows.net\$fileShareName\$blobName"

    # Use the service principal and the file context to upload content directly to Azure File Share
    Set-Content -Path $fileSharePath -Value $blobContent.Content

    Write-Host "$blobName has been moved to the Azure File Share"

    # Step 6: Delete the blob from the Blob Storage after successful upload to File Share
    Write-Host "Deleting blob: $blobName from Blob Storage"
    Remove-AzStorageBlob -Blob $blobName -Container $containerName -Context $context
    Write-Host "$blobName has been deleted from Blob Storage"
}

# Step 7: Cleanup - Remove the PSDrive for Azure File Share
Write-Host "Cleanup complete."

Write-Host "Files have been successfully moved from Azure Blob Storage to Azure File Share and deleted from Blob Storage."
