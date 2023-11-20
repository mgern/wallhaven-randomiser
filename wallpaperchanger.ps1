# URL of the website
$url = "https://wallhaven.cc/random"

# CSS selector for the list item
$liSelector = "li"

# CSS selector for the section
$sectionSelector = 'section class="thumb-listing-page"'
$scriptPath = $MyInvocation.MyCommand.Path
$imagePath = "$env:TEMP\wallpaper.jpg"

# Download the HTML content of the website
$html = Invoke-WebRequest -Uri $url

# Find the section with the specified class
$sectionTag = $html.RawContent -match "<$sectionSelector>(.*?)</section>"

# Check if a section tag was found
if ($Matches.Count -gt 0) {
    # Find all unordered lists within the section
    $ulTags = $Matches[0] -split "<ul[^>]*>"

    # Check if unordered lists were found
    if ($ulTags.Count -gt 1) {
        # Extract the content of the first list item within the first unordered list
        $firstListItemContent = $ulTags[1] -match "<$liSelector.*?>(.*?)</$liSelector>"

        # Check if a list item was found
        if ($Matches.Count -gt 0) {
            # Extract the text content of the first list item
            $firstListItemText = $Matches[1].Trim()

            # Save the text content to a file
            $firstListItemText | Out-File -FilePath $outputPath -Encoding UTF8
            Write-Host "Text content of the first list item saved successfully."
        } else {
            Write-Host "List item not found based on the provided list item selector."
        }
    } else {
        Write-Host "No unordered lists found within the section."
    }
} else {
    Write-Host "Section with class '$sectionSelector' not found on the page."
}


#when the url is https://wallhaven.cc/w/dpovpm for example
#the full image will be https://w.wallhaven.cc/full/dp/wallhaven-dpovpm.jpg
# see how the dp part is is split

# Use regular expression to extract the href value
$hrefPattern = 'href="([^"]+)"'
$match = [regex]::Match($firstListItemText, $hrefPattern)

# Check if a match is found
if ($match.Success) {
    $hrefValue = $match.Groups[1].Value
    Write-Output $hrefValue
} else {
    Write-Output "Href not found in the input string."
}

#we only care about the last 6 characters of the url
$hrefValue = $hrefValue[-6..-1] -join ''
$firstTwoChars = $hrefValue.Substring(0, 2)
$newUrl = "https://w.wallhaven.cc/full/${firstTwoChars}/wallhaven-${hrefValue}.jpg"

    # Use Invoke-WebRequest to download the image
    try {
        Invoke-WebRequest -Uri $newUrl -OutFile $imagePath
    }
    catch {

        Write-Host "Image not found. Restarting the script..."

        # Restart the script
        & "$scriptPath"
        exit
    }

Write-Output $newUrl


# Set the desktop background
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@

# Constants for SystemParametersInfo
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

# Set the desktop background
[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $imagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
