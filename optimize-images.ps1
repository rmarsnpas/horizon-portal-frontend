# Image Optimization Script
# Compresses large images to improve website loading speed

Add-Type -AssemblyName System.Drawing

function Optimize-Image {
    param(
        [string]$InputPath,
        [int]$MaxWidth = 1920,
        [int]$Quality = 80
    )
    
    if (-not (Test-Path $InputPath)) {
        Write-Host "File not found: $InputPath" -ForegroundColor Red
        return
    }
    
    $file = Get-Item $InputPath
    $outputPath = Join-Path $file.Directory ($file.BaseName + "-optimized" + $file.Extension)
    
    Write-Host "Processing: $($file.Name) ($([math]::Round($file.Length/1MB, 2)) MB)" -ForegroundColor Cyan
    
    try {
        # Load the image
        $img = [System.Drawing.Image]::FromFile($InputPath)
        
        # Calculate new dimensions maintaining aspect ratio
        $ratio = $img.Height / $img.Width
        $newWidth = [Math]::Min($MaxWidth, $img.Width)
        $newHeight = [int]($newWidth * $ratio)
        
        # Create new bitmap
        $newImg = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($newImg)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        
        # Draw resized image
        $graphics.DrawImage($img, 0, 0, $newWidth, $newHeight)
        
        # Set up encoder parameters for quality
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality, 
            [long]$Quality
        )
        
        # Get JPEG encoder
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | 
            Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
        
        # Save optimized image
        $newImg.Save($outputPath, $jpegCodec, $encoderParams)
        
        # Cleanup
        $graphics.Dispose()
        $newImg.Dispose()
        $img.Dispose()
        
        $newFile = Get-Item $outputPath
        $savings = [math]::Round((1 - $newFile.Length/$file.Length) * 100, 1)
        $newSizeMB = [math]::Round($newFile.Length/1MB, 2)
        
        Write-Host "Saved: $($newFile.Name) - $newSizeMB MB - $savings% reduction" -ForegroundColor Green
        
    } catch {
        Write-Host "Error processing $($file.Name): $_" -ForegroundColor Red
    }
}

# Main execution
Write-Host "`n=== Image Optimization Starting ===" -ForegroundColor Yellow
Write-Host "This will create -optimized versions of large images`n" -ForegroundColor Yellow

# List of images to optimize
$imagesToOptimize = @(
    "sunrise1.jpg"
    "houses.jpg"
    "snowmnts.png"
    "living-room.jpg"
    "pool321.jpg"
    "living-room1.jpg"
    "living-room2.jpg"
    "bedroom.jpg"
    "bedroom2.jpg"
    "pool3.jpg"
)

foreach ($image in $imagesToOptimize) {
    $path = Join-Path $PSScriptRoot $image
    if (Test-Path $path) {
        Optimize-Image -InputPath $path -MaxWidth 1920 -Quality 80
    } else {
        Write-Host "Skipping: $image (not found)" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Optimization Complete ===" -ForegroundColor Yellow
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Review the -optimized.jpg files" -ForegroundColor White
Write-Host "2. If satisfied, replace originals: rename sunrise1.jpg sunrise1-original.jpg; rename sunrise1-optimized.jpg sunrise1.jpg" -ForegroundColor White
Write-Host "3. Test website loading speed" -ForegroundColor White
Write-Host "4. Delete -original.jpg backups if all looks good" -ForegroundColor White
