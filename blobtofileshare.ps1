# Define your Blob Storage context
$storageAccountName = "<your-storage-account-name>"
$containerName = "<your-container-name>"
$fileShareName = "<your-file-share-name>"

# Create the Blob storage context using your Service Principal credentials
$storageAccountKey = "<your-storage-account-key>"
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# List all blobs in the container
$blobs = Get-AzStorageBlob -Container $containerName -Context $context

foreach ($blob in $blobs) {
    $blobName = $blob.Name
    $localFilePath = "C:\Temp\$blobName"  # Temporary local path (in case needed)
    
    # Download the blob from Blob Storage to a local file (or directly use in memory)
    Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Destination $localFilePath -Context $context

    # Move the file to Azure File Share
    $destinationFilePath = "AzureFileShare:\$blobName"
    Move-Item -Path $localFilePath -Destination $destinationFilePath

    # Clean up: Remove the local file after transferring it
    Remove-Item -Path $localFilePath
}

# Cleanup - Remove the PSDrive to the Azure File Share
Remove-PSDrive -Name "AzureFileShare"
