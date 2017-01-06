# Find TFSSecurity.exe
$VSDirectories = @()
$VSDirectories += "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE"
$VSDirectories += "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE"
$VSDirectories += "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE"
$VSDirectories += "${env:ProgramFiles(x86)}\Microsoft Visual Studio 10.0\Common7\IDE"

$TFSSecurityExe = "TFSSecurity.exe"

if(-not (Get-Command $TFSSecurityExe -ErrorAction SilentlyContinue)) {
  Write-Host -Verbose "Unable to find TFSSecurity.exe on your pathtempting VS install directories"
  foreach($vsDir in $VSDirectories) {
    $TFSSecurityExe = Join-Path $vsDir "TFSSecurity.exe"
    Write-Host -Verbose "Testing for $TFSSecurityExe"
    if(Test-Path $TFSSecurityExe) {
      break
    }
  }
}

# PowerYaml
Import-Module '..\..\PowerYaml\PowerYaml.psm1'