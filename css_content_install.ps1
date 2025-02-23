Add-Type -AssemblyName System.Windows.Forms

# Function to get the Garry's Mod installation path from the user
function Get-GarrysModPath {
    # Create a new FolderBrowserDialog object
    $openFileDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $openFileDialog.Description = "Select Garry's Mod Installation Folder"

    # Show the dialog and get the result
    $result = $openFileDialog.ShowDialog()

    # If the user clicks OK, return the selected path
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.SelectedPath
    }
}

# Function to download and extract the ZIP file
function Download-AndExtractZip {
    param(
        [string]$Url,
        [string]$TargetPath,
        [string]$FileName
    )

    # Download the ZIP file
    try {
        Invoke-WebRequest -Uri $Url -OutFile "$TargetPath\$FileName"
    } catch {
        Write-Error "Error downloading file: $_"
        return
    }

    # Extract the ZIP file
    try {
        Expand-Archive -Path "$TargetPath\$FileName" -DestinationPath $TargetPath -Force
    } catch {
        Write-Error "Error extracting ZIP file: $_"
        return
    }
}

# Function to copy files and directories
function Copy-Files {
    param(
        [string]$SourceFolder,
        [string]$DestinationFolder
    )

    # Get all items in the source folder
    $items = Get-ChildItem -Path $SourceFolder -Recurse

    # Loop through each item
    foreach ($item in $items) {
        # Create the destination path
        $destinationPath = Join-Path -Path $DestinationFolder -ChildPath $item.FullName.Substring($SourceFolder.Length)

        # If the item is a directory, create it in the destination
        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        }
        # If the item is a file, copy it to the destination
        else {
            Copy-Item -Path $item.FullName -Destination $destinationPath -Force
        }
    }
}

# Main script
$downloadUrl = "https://twogg.de/share/css-content-gmodcontent.zip"
$fileName = "css-content-gmodcontent.zip"
$downloadsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"

# Get the Garry's Mod installation path
$garrysmodInstallPath = Get-GarrysModPath

# Check if the user selected a path
if (-not $garrysmodInstallPath) {
    Write-Host "No path selected."
    return
}

Write-Host "Garry's Mod installation path: $garrysmodInstallPath"

# Create the downloads directory if it doesn't exist
if (-not (Test-Path -Path $downloadsPath)) {
    New-Item -ItemType Directory -Path $downloadsPath | Out-Null
}

# Download and extract the ZIP file
Download-AndExtractZip -Url $downloadUrl -TargetPath $downloadsPath -FileName $fileName

# Set the source folder
$sourceFolder = Join-Path -Path $downloadsPath -ChildPath "css-content-gmodcontent"

# Check if the source folder exists before copying files
if (Test-Path -Path $sourceFolder) {
    $destinationFolder = Join-Path -Path $garrysmodInstallPath -ChildPath "garrysmod"
    
    # Copy the files
    Copy-Files -SourceFolder $sourceFolder -DestinationFolder $destinationFolder
    Write-Host "Files copied successfully!"

    # Verify if files exist at the destination
    $sourceItems = Get-ChildItem -Path $sourceFolder -Recurse
    $allCopied = $true

    foreach ($item in $sourceItems) {
        $destinationPath = Join-Path -Path $destinationFolder -ChildPath $item.FullName.Substring($sourceFolder.Length)

        if (-not (Test-Path -Path $destinationPath)) {
            Write-Host "File not found at destination: $destinationPath"
            $allCopied = $false
        }
    }

    # Clean up only if all files were copied
    if ($allCopied) {
        # Remove the downloaded ZIP file
        if (Test-Path -Path "$downloadsPath\$fileName") {
            Remove-Item -Path "$downloadsPath\$fileName" -Force
        }

        # Remove extracted folders
        if (Test-Path -Path "$downloadsPath\css-content-gmodcontent") {
            Remove-Item -Path "$downloadsPath\css-content-gmodcontent" -Recurse -Force
        }

        Write-Host "Cleanup completed."
    } else {
        Write-Host "Not all files were copied, cleanup aborted."
    }
} else {
    Write-Host "Source folder does not exist: $sourceFolder"
}
