#!/bin/bash

# Define the URL and paths
url="https://github.com/CPqD/askar-wrapper-dart/releases/download/v0.0.1/libaskar_uniffi_android.zip"
zipFilePath="libaskar_uniffii_android.zip"
destinationPath="./android/app/src/main/jniLibs"

# Download the zip file
curl -L -o "$zipFilePath" "$url"

# Unzip the file
unzip "$zipFilePath" -d "$destinationPath"

# Clean up the zip file
rm "$zipFilePath"
