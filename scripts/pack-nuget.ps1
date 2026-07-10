#
# Packs the CMake-built C# bindings (bindings/csharp) into a MicroStrain.MSCL .nupkg.
#
# MSCL's C# bindings are SWIG-generated: a native P/Invoke library (MSCL.dll) plus a
# managed class library (MSCL_Managed.dll) that calls into it. This script auto-detects
# the actual .NET target framework the managed assembly was built against (CMake's
# experimental C# support doesn't let us pin this ourselves) so the package's `lib/<tfm>`
# folder always matches what was really built, rather than guessing.
#
param(
    [Parameter(Mandatory)] [string]$InstallDir,   # Root of a `cmake --install` output containing dotnet/x64/*.dll
    [Parameter(Mandatory)] [string]$Version,
    [string]$OutputDir = "nuget-output"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$dotnetDir = Join-Path $InstallDir "dotnet\x64"
$managedDll = Join-Path $dotnetDir "MSCL_Managed.dll"
$nativeDll = Join-Path $dotnetDir "MSCL.dll"

if (-not (Test-Path $managedDll)) { throw "Managed assembly not found at $managedDll" }
if (-not (Test-Path $nativeDll)) { throw "Native assembly not found at $nativeDll" }

# Determine the target framework the managed assembly was actually built against
$asm = [System.Reflection.Assembly]::LoadFile($managedDll)
$tfmAttrData = $asm.GetCustomAttributesData() | Where-Object { $_.AttributeType.Name -eq "TargetFrameworkAttribute" }
if (-not $tfmAttrData) {
    throw "Could not read TargetFrameworkAttribute from $managedDll. This script needs updating to match however this assembly was actually built."
}
$frameworkName = $tfmAttrData.ConstructorArguments[0].Value
Write-Host "Detected target framework: $frameworkName"

if ($frameworkName -match "^\.NETFramework,Version=v(?<maj>\d)\.(?<min>\d)(\.(?<patch>\d))?$") {
    $tfm = "net$($Matches.maj)$($Matches.min)$($Matches.patch)"
} elseif ($frameworkName -match "^\.NETCoreApp,Version=v(?<ver>[\d\.]+)$") {
    $tfm = "net$($Matches.ver)"
} else {
    throw "Unrecognized target framework '$frameworkName'. This script needs updating to map it to a NuGet lib/<tfm> folder."
}
Write-Host "Mapped to NuGet lib folder: lib/$tfm"

$stageDir = Join-Path ([System.IO.Path]::GetTempPath()) "mscl-nuget-stage"
Remove-Item -Recurse -Force $stageDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$stageDir\lib\$tfm" -Force | Out-Null
New-Item -ItemType Directory -Path "$stageDir\runtimes\win-x64\native" -Force | Out-Null
New-Item -ItemType Directory -Path "$stageDir\build" -Force | Out-Null

Copy-Item $managedDll "$stageDir\lib\$tfm\"
Copy-Item $nativeDll "$stageDir\runtimes\win-x64\native\"
Copy-Item $nativeDll "$stageDir\build\"
Copy-Item (Join-Path $repoRoot "LICENSE") "$stageDir\LICENSE"

# Copies MSCL.dll next to the consuming app's output. `runtimes/win-x64/native` only gets
# resolved automatically by SDK-style (PackageReference) projects; this targets file makes
# the native dependency work for classic (packages.config) projects too.
Set-Content -Path "$stageDir\build\MicroStrain.MSCL.targets" -Encoding UTF8 -Value @'
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup>
    <None Include="$(MSBuildThisFileDirectory)MSCL.dll">
      <Link>MSCL.dll</Link>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
'@

$nuspecPath = "$stageDir\MicroStrain.MSCL.nuspec"
Set-Content -Path $nuspecPath -Encoding UTF8 -Value @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
  <metadata>
    <id>MicroStrain.MSCL</id>
    <version>$Version</version>
    <authors>MicroStrain by HBK</authors>
    <owners>MicroStrain by HBK</owners>
    <description>MSCL - The MicroStrain Communication Library. A simple, user-friendly API to interact with MicroStrain Wireless and Inertial sensors.</description>
    <projectUrl>https://github.com/HBK-MicroStrain/MSCL</projectUrl>
    <license type="file">LICENSE</license>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <tags>microstrain mscl sensors wireless inertial</tags>
  </metadata>
  <files>
    <file src="lib\**" target="lib" />
    <file src="runtimes\**" target="runtimes" />
    <file src="build\**" target="build" />
    <file src="LICENSE" target="LICENSE" />
  </files>
</package>
"@

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
nuget pack $nuspecPath -OutputDirectory $OutputDir -Version $Version
if ($LASTEXITCODE -ne 0) { throw "nuget pack failed with exit code $LASTEXITCODE" }
