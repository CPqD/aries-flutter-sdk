# Define the URL and paths
$url = "https://github.com/CPqD/askar-wrapper-dart/releases/download/v0.0.1/libaskar_uniffi_android.zip"
$zipFilePath = "./libaskar_uniffii_android.zip"
$destinationPath = "./android/app/src/main/jniLibs"

try {
    # Download the zip file
    Invoke-WebRequest -Uri $url -OutFile $zipFilePath -ErrorAction Stop
    Write-Host "Download successful."

    # Unzip the file
    Expand-Archive -Path $zipFilePath -DestinationPath $destinationPath -ErrorAction Stop
    Write-Host "Unzip successful."

    # Clean up the zip file
    Remove-Item $zipFilePath -ErrorAction Stop
    Write-Host "Cleanup successful."
} catch {
    Write-Host "An error occurred: $_"
}
