<#
    Title: Magdy MS Activation v1.0
    Copyright© 2024 Magdy. All rights reserved.
    Contact: The Lost Land
#>


# Function to center text
function CenterText {
    param (
        [string]$text,
        [int]$width
    )
    
    $textLength = $text.Length
    $padding = ($width - $textLength) / 2
    return (" " * [math]::Max([math]::Ceiling($padding), 0)) + $text + (" " * [math]::Max([math]::Floor($padding), 0))
}

# Function to create a border
function CreateBorder {
    param (
        [string[]]$lines,
        [int]$width
    )

    $borderLine = "+" + ("-" * $width) + "+"
    $borderedText = @($borderLine)
    foreach ($line in $lines) {
        $borderedText += "|$(CenterText $line $width)|"
    }
    $borderedText += $borderLine
    return $borderedText -join "`n"
}

# Display script information with border
$title = "Magdy MS Activation v1.0"
$copyright = "Copyright 2024 Magdy. All rights reserved."
$contact = "Contact: The lost land"
$maxWidth = 50

$infoText = @($title, $copyright, $contact)
$borderedInfo = CreateBorder -lines $infoText -width $maxWidth

Write-Host $borderedInfo -ForegroundColor Cyan


# The following get.ps1 code is hosted on magdy.activation for Magdy. For more info, please visit Magdy.

$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$DownloadURL1 = 'https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/35e044ddc85eed60b27b37c48371bd19cdc678b7/MAS/All-In-One-Version/MAS_AIO-CRC32_8C3AA7E0.cmd'
$DownloadURL2 = 'https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/35e044ddc85eed60b27b37c48371bd19cdc678b7/MAS/All-In-One-Version/MAS_AIO-CRC32_8C3AA7E0.cmd'
$DownloadURL3 = 'https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/commit/35e044ddc85eed60b27b37c48371bd19cdc678b7/MAS/All-In-One-Version/MAS_AIO-CRC32_8C3AA7E0.cmd'

$URLs = @($DownloadURL1, $DownloadURL2, $DownloadURL3)
$ShuffledURLs = $URLs | Sort-Object { Get-Random }

try {
    $response = Invoke-WebRequest -Uri $ShuffledURLs[0] -UseBasicParsing
}
catch {
    try {
        $response = Invoke-WebRequest -Uri $ShuffledURLs[1] -UseBasicParsing
    }
    catch {
        $response = Invoke-WebRequest -Uri $ShuffledURLs[2] -UseBasicParsing
    }
}

# Verify script integrity
$releaseHash = 'D666A4C7810B9D3FE9749F2D4E15C5A65D4AC0D7F0B14A144D6631CE61CC5DF3'
$stream = New-Object IO.MemoryStream
$writer = New-Object IO.StreamWriter $stream
$writer.Write($response)
$writer.Flush()
$stream.Position = 0
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($stream)) -replace '-'
if ($hash -ne $releaseHash) {
    Write-Warning "Hash ($hash) mismatch, aborting!`nReport this issue at https://massgrave.dev/troubleshoot"
    $response = $null
    return
}

# Check for AutoRun registry which may create issues with CMD
$paths = "HKCU:\SOFTWARE\Microsoft\Command Processor", "HKLM:\SOFTWARE\Microsoft\Command Processor"
foreach ($path in $paths) { 
    if (Get-ItemProperty -Path $path -Name "Autorun" -ErrorAction SilentlyContinue) { 
        Write-Warning "Autorun registry found, CMD may crash! `nManually copy-paste the below command to fix...`nRemove-ItemProperty -Path '$path' -Name 'Autorun'"
    } 
}

$rand = [Guid]::NewGuid().Guid
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
$FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\MAS_$rand.cmd" } else { "$env:TEMP\MAS_$rand.cmd" }

$ScriptArgs = "$args "
$prefix = "@::: $rand `r`n"
$content = $prefix + $response
Set-Content -Path $FilePath -Value $content

# Set ComSpec variable for current session in case its corrupt in the system
$env:ComSpec = "$env:SystemRoot\system32\cmd.exe"
Start-Process cmd.exe "/c """"$FilePath"" $ScriptArgs""" -Wait

$FilePaths = @("$env:TEMP\MAS*.cmd", "$env:SystemRoot\Temp\MAS*.cmd")
foreach ($FilePath in $FilePaths) { Get-Item $FilePath | Remove-Item }
