# PowerShell script to replace app icons
# Usage: Place your new icon files in a folder structure like:
# new_icons/
#   android/
#     mipmap-hdpi/
#     mipmap-mdpi/
#     mipmap-xhdpi/
#     mipmap-xxhdpi/
#     mipmap-xxxhdpi/

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [string]$ProjectPath = "c:\Users\Dev2\Desktop\Amrit Work\Android Project\jaykisan_card"
)

Write-Host "Replacing app icons..." -ForegroundColor Green

$targetBase = "$ProjectPath\android\app\src\main\res"
$densities = @("hdpi", "mdpi", "xhdpi", "xxhdpi", "xxxhdpi")

foreach ($density in $densities) {
    $sourceFolder = "$SourcePath\android\mipmap-$density"
    $targetFolder = "$targetBase\mipmap-$density"
    
    if (Test-Path $sourceFolder) {
        Write-Host "Copying $density icons..." -ForegroundColor Yellow
        
        # Copy all files from source to target
        if (Test-Path $targetFolder) {
            Copy-Item "$sourceFolder\*" $targetFolder -Force -Recurse
            Write-Host "✓ Copied $density icons successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Target folder $targetFolder not found" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Source folder $sourceFolder not found" -ForegroundColor Red
    }
}

Write-Host "Icon replacement completed!" -ForegroundColor Green
Write-Host "You can now run: flutter clean && flutter run" -ForegroundColor Cyan