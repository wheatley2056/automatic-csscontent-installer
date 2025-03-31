Add-Type -AssemblyName System.Windows.Forms

# Funktion, um den Garry's Mod Installationspfad vom Benutzer zu erhalten
function Get-GarrysModPath {
    # Eingabefeld für den Pfad
    $path = Read-Host "Bitte den Pfad zu deiner Garry's Mod-Installation eingeben"
    
    # Überprüfe, ob der angegebene Pfad existiert
    if (Test-Path -Path $path) {
        return $path
    } else {
        Write-Host "Der angegebene Pfad existiert nicht."
        return $null
    }
}

# Funktion zum Herunterladen und Extrahieren der ZIP-Datei
function Download-AndExtractZip {
    param(
        [string]$Url,
        [string]$TargetPath,
        [string]$FileName
    )

    # Definiere den Zielpfad für die heruntergeladene Datei
    $downloadFilePath = "$TargetPath\$FileName"
    
    # Herunterladen der ZIP-Datei mit Fortschrittsanzeige
    try {
        Write-Host "Starte den Download..."
        Invoke-WebRequest -Uri $Url -OutFile $downloadFilePath -Verbose
        Write-Host "Download abgeschlossen!"
    } catch {
        Write-Error "Fehler beim Herunterladen der Datei: $_"
        return $false
    }

    # Extrahieren der ZIP-Datei
    try {
        Write-Host "Starte die Extraktion..."
        Expand-Archive -Path $downloadFilePath -DestinationPath $TargetPath -Force
        Write-Host "Extraktion abgeschlossen!"
        return $true
    } catch {
        Write-Error "Fehler beim Entpacken der ZIP-Datei: $_"
        return $false
    }
}

# Funktion zum Kopieren von Dateien und Ordnern
function Copy-Files {
    param(
        [string]$SourceFolder,
        [string]$DestinationFolder
    )

    # Hole alle Items im Quellordner
    $items = Get-ChildItem -Path $SourceFolder -Recurse

    # Schleife durch jedes Item
    foreach ($item in $items) {
        # Erstelle den Zielpfad
        $destinationPath = Join-Path -Path $DestinationFolder -ChildPath $item.FullName.Substring($SourceFolder.Length)

        # Wenn es ein Verzeichnis ist, erstelle es im Ziel
        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        }
        # Wenn es eine Datei ist, kopiere sie ins Ziel
        else {
            Copy-Item -Path $item.FullName -Destination $destinationPath -Force
        }
    }
}

# Hauptskript
$downloadUrl = "https://twogg.de/share/css-content-gmodcontent.zip"
$fileName = "css-content-gmodcontent.zip"
$downloadsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"

# Holen des Garry's Mod Installationspfades
$garrysmodInstallPath = Get-GarrysModPath

# Überprüfen, ob der Benutzer einen Pfad ausgewählt hat
if (-not $garrysmodInstallPath) {
    Write-Host "Kein Pfad ausgewählt."
    return
}

Write-Host "Garry's Mod Installationspfad: $garrysmodInstallPath"

# Erstelle das Downloads-Verzeichnis, falls es nicht existiert
if (-not (Test-Path -Path $downloadsPath)) {
    New-Item -ItemType Directory -Path $downloadsPath | Out-Null
}

# Herunterladen und Extrahieren der ZIP-Datei
if (Download-AndExtractZip -Url $downloadUrl -TargetPath $downloadsPath -FileName $fileName) {
    # Setze den Quellordner (erst nach dem Entpacken vorhanden)
    $sourceFolder = Join-Path -Path $downloadsPath -ChildPath "css-content-gmodcontent"

    # Überprüfen, ob der Quellordner existiert, bevor die Dateien kopiert werden
    if (Test-Path -Path $sourceFolder) {
        $destinationFolder = Join-Path -Path $garrysmodInstallPath -ChildPath "garrysmod"
        
        # Dateien kopieren
        Copy-Files -SourceFolder $sourceFolder -DestinationFolder $destinationFolder
        Write-Host "Dateien erfolgreich kopiert!"

        # Überprüfen, ob die Dateien im Ziel existieren
        $sourceItems = Get-ChildItem -Path $sourceFolder -Recurse
        $allCopied = $true

        foreach ($item in $sourceItems) {
            $destinationPath = Join-Path -Path $destinationFolder -ChildPath $item.FullName.Substring($sourceFolder.Length)

            if (-not (Test-Path -Path $destinationPath)) {
                Write-Host "Datei nicht gefunden am Ziel: $destinationPath"
                $allCopied = $false
            }
        }

        # Bereinigen nur, wenn alle Dateien kopiert wurden
        if ($allCopied) {
            # Entferne die heruntergeladene ZIP-Datei
            if (Test-Path -Path "$downloadsPath\$fileName") {
                Remove-Item -Path "$downloadsPath\$fileName" -Force
            }

            # Entferne extrahierte Ordner
            if (Test-Path -Path "$downloadsPath\css-content-gmodcontent") {
                Remove-Item -Path "$downloadsPath\css-content-gmodcontent" -Recurse -Force
            }

            Write-Host "Bereinigung abgeschlossen."
        } else {
            Write-Host "Nicht alle Dateien wurden kopiert, Bereinigung abgebrochen."
        }
    } else {
        Write-Host "Quellordner existiert nicht nach der Extraktion: $sourceFolder"
    }
} else {
    Write-Host "Download oder Extraktion fehlgeschlagen."
}
