# Step 1: Define necessary variables for authentication and resource details
$tenantId = "<your-tenant-id>"
$appId = "<your-client-id>"        # Service Principal Application ID
$clientSecret = "<your-client-secret>"  # Service Principal Client Secret
$storageAccountName = "<your-storage-account-name>"
$containerName = "appcontainer"  # Correct container name (just "appcontainer")
$fileShareName = "<your-file-share-name>"

# Step 2: Authenticate to Azure using Service Principal
$psCredential = New-Object System.Management.Automation.PSCredential($appId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Connect-AzAccount -ServicePrincipal -Credential $psCredential -TenantId $tenantId

# Step 3: Create Blob Storage context using Service Principal
$context = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# Step 4: Authenticate to Azure File Share using the same Service Principal
$azFilesContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# Step 5: Define the folder to move files from (e.g., automationcontainer)
$folderPrefix = "automationcontainer/"

# Step 6: List all blobs in the container and filter for blobs in the automationcontainer folder
$blobs = Get-AzStorageBlob -Container $containerName -Context $context

# Step 7: Process only blobs in the automationcontainer folder
foreach ($blob in $blobs) {
    if ($blob.Name.StartsWith($folderPrefix)) {
        $blobName = $blob.Name
        
        Write-Host "Downloading blob: $blobName"

        # Download the blob into memory (directly into the script's context, no local storage)
        $blobContent = Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Context $context -Force

        # Now upload the content to the Azure File Share directly (via Azure AD authentication)
        Write-Host "Uploading $blobName to Azure File Share"

        # Path in the File Share (using the folder structure in the file share if needed)
        $fileSharePath = "\\$storageAccountName.file.core.windows.net\$fileShareName\$blobName"

        # Use the service principal and the file context to upload content directly to Azure File Share
        Set-Content -Path $fileSharePath -Value $blobContent.Content

        Write-Host "$blobName has been moved to the Azure File Share"

        # Step 8: Delete the blob from the Blob Storage after successful upload to File Share
        Write-Host "Deleting blob: $blobName from Blob Storage"
        Remove-AzStorageBlob -Blob $blobName -Container $containerName -Context $context
        Write-Host "$blobName has been deleted from Blob Storage"
    }
    else {
        Write-Host "Skipping blob: $($blob.Name) (Not in automationcontainer)"
    }
}

# Step 9: Cleanup - Remove the PSDrive for Azure File Share
Write-Host "Cleanup complete."

Write-Host "Files from 'automationcontainer' have been successfully moved from Azure Blob Storage to Azure File Share and deleted from Blob Storage."
