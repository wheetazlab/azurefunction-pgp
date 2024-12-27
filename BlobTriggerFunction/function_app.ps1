param($TriggerMetadata)

Write-Host "Processing blob: $($TriggerMetadata.Name)"

# Retrieve environment variables
$pgpKey = $env:PGP_KEY_SECRET
$pgpPassphrase = $env:PGP_KEY_PASSPHRASE
$storageSrcConnectionString = $env:STORAGE_SRC_CONNECTION_STRING
$storageDstConnectionString = $env:STORAGE_DST_CONNECTION_STRING

if (-not $pgpKey) {
    Write-Error "PGP key not found in environment variables"
    exit 1
}

if (-not $pgpPassphrase) {
    Write-Error "PGP passphrase not found in environment variables"
    exit 1
}

# Initialize BlobServiceClient for Storage Account SRC
$blobServiceClientSrc = [Microsoft.Azure.Storage.Blob.CloudBlobClient]::new($storageSrcConnectionString)
$containerClientSrc = $blobServiceClientSrc.GetContainerReference($TriggerMetadata.ContainerName)

# Initialize BlobServiceClient for Storage Account DST
$blobServiceClientDst = [Microsoft.Azure.Storage.Blob.CloudBlobClient]::new($storageDstConnectionString)
$containerClientDst = $blobServiceClientDst.GetContainerReference($TriggerMetadata.ContainerName)

# Initialize GPG
$gpg = New-Object -TypeName System.Diagnostics.Process
$gpg.StartInfo.FileName = "gpg"
$gpg.StartInfo.Arguments = "--import"
$gpg.StartInfo.RedirectStandardInput = $true
$gpg.StartInfo.RedirectStandardOutput = $true
$gpg.StartInfo.RedirectStandardError = $true
$gpg.StartInfo.UseShellExecute = $false
$gpg.Start()

$gpg.StandardInput.WriteLine($pgpKey)
$gpg.StandardInput.Close()
$gpg.WaitForExit()

if ($gpg.ExitCode -ne 0) {
    Write-Error "Failed to import PGP key"
    exit 1
}

Write-Host "PGP key imported successfully"

# Decrypt the blob
$pgpMessage = Get-Content -Raw -Path $TriggerMetadata.Uri
$gpg = New-Object -TypeName System.Diagnostics.Process
$gpg.StartInfo.FileName = "gpg"
$gpg.StartInfo.Arguments = "--decrypt --passphrase-fd 0"
$gpg.StartInfo.RedirectStandardInput = $true
$gpg.StartInfo.RedirectStandardOutput = $true
$gpg.StartInfo.RedirectStandardError = $true
$gpg.StartInfo.UseShellExecute = $false
$gpg.Start()

$gpg.StandardInput.WriteLine($pgpPassphrase)
$gpg.StandardInput.WriteLine($pgpMessage)
$gpg.StandardInput.Close()
$decryptedData = $gpg.StandardOutput.ReadToEnd()
$gpg.WaitForExit()

if ($gpg.ExitCode -ne 0) {
    Write-Error "Decryption failed"
    exit 1
}

Write-Host "Decryption successful"

# Upload decrypted data to Storage Account DST
$blobClientDst = $containerClientDst.GetBlockBlobReference($TriggerMetadata.Name)
$blobClientDst.UploadText($decryptedData)

Write-Host "Decrypted blob uploaded to Storage Account DST: $($TriggerMetadata.Name)"
