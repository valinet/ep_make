param (
	[string]$Commit="default"
)

$QuickEditCodeSnippet=@" 
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

 
public static class DisableConsoleQuickEdit
{
 
const uint ENABLE_QUICK_EDIT = 0x0040;

// STD_INPUT_HANDLE (DWORD): -10 is the standard input device.
const int STD_INPUT_HANDLE = -10;

[DllImport("kernel32.dll", SetLastError = true)]
static extern IntPtr GetStdHandle(int nStdHandle);

[DllImport("kernel32.dll")]
static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

[DllImport("kernel32.dll")]
static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

public static bool SetQuickEdit(bool SetEnabled)
{

    IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);

    // get current console mode
    uint consoleMode;
    if (!GetConsoleMode(consoleHandle, out consoleMode))
    {
        // ERROR: Unable to get console mode.
        return false;
    }

    // Clear the quick edit bit in the mode flags
    if (SetEnabled)
    {
        consoleMode &= ~ENABLE_QUICK_EDIT;
    }
    else
    {
        consoleMode |= ENABLE_QUICK_EDIT;
    }

    // set the new mode
    if (!SetConsoleMode(consoleHandle, consoleMode))
    {
        // ERROR: Unable to set console mode
        return false;
    }

    return true;
}
}

"@

$QuickEditMode=add-type -TypeDefinition $QuickEditCodeSnippet -Language CSharp


function Set-QuickEdit() 
{
[CmdletBinding()]
param(
[Parameter(Mandatory=$false, HelpMessage="This switch will disable Console QuickEdit option")]
    [switch]$DisableQuickEdit=$false
)


    if([DisableConsoleQuickEdit]::SetQuickEdit($DisableQuickEdit))
    {
        Write-Output "QuickEdit settings has been updated."
    }
    else
    {
        Write-Output "Something went wrong."
    }
}
Set-QuickEdit -DisableQuickEdit

function Test-RegistryKeyValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )
    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        return $false
    }
    $properties = Get-ItemProperty -Path $Path 
    if( -not $properties )
    {
        return $false
    }
    $member = Get-Member -InputObject $properties -Name $Name
    if( $member )
    {
        return $true
    }
    else
    {
        return $false
    }
}

$Host.UI.RawUI.WindowTitle = "ep_make: Initializing"

# Set up some properties
$EP_WinSDK_Short="22621"
$EP_WinSDK_Long="10.0." + $EP_WinSDK_Short + ".0"
$EP_OldPath=$env:PATH
$ProgressPreference = 'SilentlyContinue' # Disable Invoke-WebRequest progress bar which slows down downloads tremendously
$url_git="https://github.com/git-for-windows/git/releases/download/v2.45.0.windows.1/PortableGit-2.45.0-64-bit.7z.exe"
$url_python="https://github.com/indygreg/python-build-standalone/releases/download/20240224/cpython-3.10.13+20240224-x86_64-pc-windows-msvc-static-install_only.tar.gz"
$url_cmake="https://github.com/Kitware/CMake/releases/download/v3.29.3/cmake-3.29.3-windows-x86_64.zip"
$url_nuget="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$url_portable_msvc="https://gist.github.com/7f3162ec2988e81e56d5c4e22cde9977.git"
$portable_msvc_commit="d6d965ec296832941a83d512eed057d88552dd36"
$url_explorerpatcher="https://github.com/valinet/ExplorerPatcher"

Write-Host "ep_make - Build environment for ExplorerPatcher"
Write-Host "==============================================="
Write-Host "Copyright 2024 VALINET Solutions SRL"
Write-Host "Author(s): Valentin Radu (valentin.radu@valinet.ro)"
Write-Host ""
Write-Host "Using SDK version      : $EP_WinSDK_Long"
Write-Host "Build directory        : `"$env:AppData\ExplorerPatcher\ep_make`""
Write-Host "ep_setup location      : `"$env:AppData\ExplorerPatcher\ep_make\repo\build\Release\ep_setup.exe`""
Write-Host "URL for Git            : $url_git"
Write-Host "URL for Python         : $url_python"
Write-Host "URL for cmake          : $url_cmake"
Write-Host "URL for nuget          : $url_nuget"
Write-Host "URL for portable_msvc  : $url_portable_msvc@$portable_msvc_commit"
Write-Host "URL for ExplorerPatcher: $url_explorerpatcher"

$EP_updatePreferStaging=0
$EP_updateURL="https://github.com/valinet/ExplorerPatcher/releases/latest"
$EP_updateURLStaging="https://api.github.com/repos/valinet/ExplorerPatcher/releases?per_page=1"
$regKey = "HKCU:\SOFTWARE\ExplorerPatcher"
if (Test-RegistryKeyValue -Path $regKey -Name "UpdatePreferStaging") {
	$EP_updatePreferStaging = (Get-ItemProperty -Path $regKey -Name "UpdatePreferStaging").UpdatePreferStaging
}
if (Test-RegistryKeyValue -Path $regKey -Name "UpdateURL") {
	$EP_updateURL = (Get-ItemProperty -Path $regKey -Name "UpdateURL").UpdateURL
}
if (Test-RegistryKeyValue -Path $regKey -Name "UpdateURLStaging") {
	$EP_updateURLStaging = (Get-ItemProperty -Path $regKey -Name "UpdateURLStaging").UpdateURLStaging
}
Write-Host "Builds pre-release     : $EP_updatePreferStaging"
Write-Host "URL for stable release : $EP_updateURL"
Write-Host "URL for pre-release    : $EP_updateURLStaging"

$EP_hashToUse=""
$EP_commitId=""
if ($EP_updatePreferStaging -eq 1) {
	$EP_hashToUse = curl.exe -L -r 78-109 ((curl.exe -L $EP_updateURLStaging 2>$null | ConvertFrom-Json).assets.browser_download_url) 2>$null
	$EP_commitId = (curl.exe -L $EP_updateURLStaging 2>$null | ConvertFrom-Json).html_url.Split("_")[1]
} else {
	$EP_hashToUse = curl.exe -L -r 78-109 $EP_updateURL/download/ep_setup.exe 2>$null
	$EP_commitId = (((curl.exe -L $EP_updateURL 2>$null | Out-String) -Split "up to and including")[1] -Split "/")[6].Substring(0, 7)
}
if ($Commit -ne "default") {
	$EP_commitId = $Commit
}
Write-Host "Building for hash      : $EP_hashToUse"
Write-Host "Commit to check out    : $EP_commitId"
Write-Host ""
Write-Host "Initialization finished. High-level progress is displayed in the window title bar, detailed progress is shown in the console window."
Write-Host ""

New-Item -ItemType Directory -Path "$env:AppData\ExplorerPatcher\ep_make" -ErrorAction SilentlyContinue
cd $env:AppData\ExplorerPatcher\ep_make
md downloads -ErrorAction SilentlyContinue

$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring git"
if (Test-Path -Path ".\downloads\git-portable_ep_make.exe") {
	$Host.UI.RawUI.WindowTitle += ": skipped"
} else {
	Invoke-WebRequest $url_git -OutFile .\downloads\git-portable_ep_make.exe
	.\downloads\git-portable_ep_make.exe -o".\git" -y
	$process = Get-Process -Name "git-portable_ep_make" -ErrorAction SilentlyContinue
	if ($process) {
		$process | Wait-Process
	}
	$Host.UI.RawUI.WindowTitle += ": ok"
}
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring python"
if (Test-Path -Path ".\python\python.exe") {
	$Host.UI.RawUI.WindowTitle += ": skipped"
} else {
	Invoke-WebRequest $url_python -OutFile .\downloads\python.tar.gz
	tar.exe -xzf .\downloads\python.tar.gz
	$Host.UI.RawUI.WindowTitle += ": ok"
}
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring cmake"
if (Test-Path -Path ".\cmake\bin\cmake.exe") {
	$Host.UI.RawUI.WindowTitle += ": skipped"
} else {
	Invoke-WebRequest $url_cmake -OutFile downloads\cmake.zip
	Expand-Archive -LiteralPath .\downloads\cmake.zip -DestinationPath .
	Get-ChildItem -Directory -Filter "cmake*" | Rename-Item -NewName "cmake" -Force
	$Host.UI.RawUI.WindowTitle += ": ok"
}
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring nuget"
if (Test-Path -Path ".\nuget\nuget.exe") {
	$Host.UI.RawUI.WindowTitle += ": skipped"
} else {
	md nuget
	Invoke-WebRequest $url_nuget -OutFile .\nuget\nuget.exe
	$Host.UI.RawUI.WindowTitle += ": ok"
}
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring portable-msvc"
if (Test-Path -Path ".\portable-msvc\portable-msvc.py") {
	$Host.UI.RawUI.WindowTitle += ": skipped"
} else {
	.\git\bin\git.exe clone $url_portable_msvc .\portable-msvc
	.\git\bin\git.exe -C portable-msvc fetch
	.\git\bin\git.exe -C portable-msvc reset --hard
	.\git\bin\git.exe -C portable-msvc checkout $portable_msvc_commit
	$Host.UI.RawUI.WindowTitle += ": ok"
}
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Patching portable-msvc"
# Fix msiexec extraction getting stuck/not working with relative paths
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('OUTPUT = Path("msvc") '), 'OUTPUT = Path("msvc").resolve()' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('DOWNLOADS = Path("downloads") '), 'DOWNLOADS = Path("downloads").resolve()' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Implement "--target" parameter
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('args = ap.parse_args()'), "ap.add_argument(`"--target`", help=`"Target architecture`")`nargs =  ap.parse_args()`nTARGET = args.target or TARGET" | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Grab some additional required packages (including vsdevcmd or not)
#(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('#f"microsoft.vc.{msvc_ver}.crt.redist.x64.base",'), 'f"microsoft.build",f"microsoft.build.dependencies",f"microsoft.visualstudio.vc.msbuild.v170.base",f"microsoft.visualstudio.vc.msbuild.v170.{TARGET}",f"microsoft.visualstudio.vc.msbuild.v170.{TARGET}.v143",f"microsoft.visualstudio.vc.devcmd",f"microsoft.visualstudio.vc.vcvars",f"microsoft.visualcpp.tools.core.x86",f"microsoft.visualcpp.tools.host{HOST}.target{TARGET}",f"microsoft.visualcpp.tools.common.utils",f"microsoft.visualcpp.servicing.redist",f"microsoft.visualstudio.vsdevcmd.core.winsdk",' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('#f"microsoft.vc.{msvc_ver}.crt.redist.x64.base",'), 'f"microsoft.build",f"microsoft.build.dependencies",f"microsoft.visualstudio.vc.msbuild.v170.base",f"microsoft.visualstudio.vc.msbuild.v170.{TARGET}",f"microsoft.visualstudio.vc.msbuild.v170.{TARGET}.v143",f"microsoft.visualcpp.tools.core.x86",' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Support neutral language
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('p = first(packages[pkg], lambda p: p.get("language") in (None, "en-US"))'), 'p = first(packages[pkg], lambda p: p.get("language") in (None, "en-US", "neutral"))' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Some packages have file name simply "package.vsix", make up some name for them
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('filename = payload["fileName"]'), 'filename = (pkg + ".vsix") if payload["fileName"] == "payload.vsix" else payload["fileName"]' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Disable deletion of Common7 folder by portable-msvc
#(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('### cleanup'), "### cleanup`n'''" | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('for arch in ["x86", "x64", "arm", "arm64"]:'), "'''`nfor arch in [`"x86`", `"x64`", `"arm64`", `"arm`"]:" | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('# executable that is collecting'), "'''`n# executable which is collecting" | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Generate customized build script (or not)
#(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('(OUTPUT / "setup.bat").write_text(SETUP)'), '(OUTPUT / f"setup_{TARGET}.bat").write_text(SETUP)' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('(OUTPUT / "setup.bat").write_text(SETUP)'), '' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

# Only update MSIs if new versions were downloaded
(gc -Encoding UTF8 .\portable-msvc\portable-msvc.py) -replace [regex]::Escape('OUTPUT.resolve()}"])'), 'OUTPUT.resolve()}"]) if total_download != 0 else None' | Out-File -Encoding UTF8 .\portable-msvc\portable-msvc.py

$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring Build Tools for x86 using portable-msvc"
.\python\python.exe .\portable-msvc\portable-msvc.py --accept-license --target x86 --sdk-version $EP_WinSDK_Short
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring Build Tools for x64 using portable-msvc"
.\python\python.exe .\portable-msvc\portable-msvc.py --accept-license --target x64 --sdk-version $EP_WinSDK_Short
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Acquiring ExplorerPatcher"
.\git\bin\git.exe clone --recursive $url_explorerpatcher repo
.\git\bin\git.exe -C repo fetch
.\git\bin\git.exe -C repo reset --hard
.\git\bin\git.exe -C repo checkout $EP_commitId
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Patching ExplorerPatcher"
.\git\usr\bin\touch.exe repo\ep_weather_host\ep_weather_host_h.h
(gc .\repo\ep_dwm\ep_dwm\ep_dwm.vcxproj) -replace [regex]::Escape('<PlatformToolset>v142</PlatformToolset>'), '<PlatformToolset>v143</PlatformToolset>' | Out-File .\repo\ep_dwm\ep_dwm\ep_dwm.vcxproj
$dateOfCurrentC=Get-Date(.\git\bin\git.exe -C repo log -1 --format='%ci' $EP_commitId)
try { $dateOfEpGuiFix=Get-Date(.\git\bin\git.exe -C repo log -1 --format='%ci' 5ed503e) }
catch { $dateOfEpGuiFix=Get-Date }
try { $dateOfEpGuiBug=Get-Date(.\git\bin\git.exe -C repo log -1 --format='%ci' 639d7aa) }
catch { $dateOfEpGuiBug=Get-Date -Date "01/01/1970" }
if ($dateOfCurrentC -ge $dateOfEpGuiBug -and $dateOfCurrentC -lt $dateOfEpGuiFix) {
	cd repo
	curl.exe -L https://github.com/valinet/ExplorerPatcher/commit/5ed503e451fa5b2c7ec7df6fd05c3fa25414b050.patch 2>$null | ..\git\usr\bin\unix2dos.exe | ..\git\usr\bin\patch.exe -N -p1
	cd ..
}
try { $dateOfEpSetupPatchFix=Get-Date(.\git\bin\git.exe -C repo log -1 --format='%ci' c41b93b) }
catch { $dateOfEpSetupPatchFix=Get-Date }
if ($dateOfCurrentC -lt $dateOfEpSetupPatchFix) {
	cd repo
	curl.exe -L https://github.com/valinet/ExplorerPatcher/commit/c41b93b6b4e8632c5c686ccb0ba4d10612a285eb.patch 2>$null | ..\git\usr\bin\unix2dos.exe | ..\git\usr\bin\patch.exe -N -p1
	cd ..
}
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Preparing build environment"
$env:Platform="x64"
$env:EnterpriseWDK="True"
$env:DisableRegistryUse="true"
$env:VisualStudioVersion="17.0"
$env:VSINSTALLDIR="$env:AppData\ExplorerPatcher\ep_make\msvc\"
$env:VCToolsVersion=(Get-Content $env:AppData\ExplorerPatcher\ep_make\msvc\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt -Raw).Trim()
$env:VCToolsInstallDir="$env:AppData\ExplorerPatcher\ep_make\msvc\VC\Tools\MSVC\$env:VCToolsVersion\"
$env:VCToolsInstallDir_170="$env:VCToolsInstallDir"
$env:WindowsSDKDir="$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\"
$env:WindowsSDK_IncludePath="$env:AppData\ExplorerPatcher\ep_make\msvc\VC\Tools\MSVC\$env:VCToolsVersion\include;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Include\$EP_WinSDK_Long\um;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Include\$EP_WinSDK_Long\ucrt;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Include\$EP_WinSDK_Long\cppwinrt;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Include\$EP_WinSDK_Long\shared;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Include\$EP_WinSDK_Long\winrt"
$env:WindowsSDK_LibraryPath_x86="$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Lib\$EP_WinSDK_Long\um\x86;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Lib\$EP_WinSDK_Long\ucrt\x86"
$env:WindowsSDK_LibraryPath_x64="$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Lib\$EP_WinSDK_Long\um\x64;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\Lib\$EP_WinSDK_Long\ucrt\x64"
$EP_NewPath=$EP_OldPath+"$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\bin;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\bin\$EP_WinSDK_Long\x64;;$env:AppData\ExplorerPatcher\ep_make\msvc\VC\Tools\MSVC\$env:VCToolsVersion\bin\HostX64\x64;;$env:AppData\ExplorerPatcher\ep_make\msvc\MSBuild\Current\Bin\amd64;;$env:AppData\ExplorerPatcher\ep_make\msvc\Common7\IDE\;;$env:AppData\ExplorerPatcher\ep_make\msvc\Common7\Tools\;;"
$env:PATH=$EP_NewPath
gci env:* | sort-object name
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Building funchook"
cd repo
cd libs
cd funchook
md build -ErrorAction SilentlyContinue
cd build
..\..\..\..\cmake\bin\cmake.exe -G "Visual Studio 17 2022" -A x64 ..
(gc .\funchook-static.vcxproj) -replace '<RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>', '<RuntimeLibrary>MultiThreaded</RuntimeLibrary>' | Out-File .\funchook-static.vcxproj
..\..\..\..\cmake\bin\cmake.exe --build . --config Release
cd ..
cd ..
cd ..
cd ..
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Restoring NuGet packages"
cd repo
..\nuget\nuget.exe restore ExplorerPatcher.sln
cd ..
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Building ExplorerPatcher for x86"
cd repo
$env:Platform="x86"
$env:PATH=$EP_OldPath+"$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\bin;;$env:AppData\ExplorerPatcher\ep_make\msvc\Windows Kits\10\bin\$EP_WinSDK_Long\x86;;$env:AppData\ExplorerPatcher\ep_make\msvc\VC\Tools\MSVC\$env:VCToolsVersion\bin\HostX64\x86;;$env:AppData\ExplorerPatcher\ep_make\msvc\MSBuild\Current\Bin\amd64;;$env:AppData\ExplorerPatcher\ep_make\msvc\Common7\IDE\;;$env:AppData\ExplorerPatcher\ep_make\msvc\Common7\Tools\;;"
msbuild ExplorerPatcher.sln /property:Configuration=Release /property:Platform=IA-32
$env:Platform="x64"
$env:PATH=$EP_NewPath
cd ..
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

$Host.UI.RawUI.WindowTitle = "ep_make: Building ExplorerPatcher for x64"
cd repo
msbuild ExplorerPatcher.sln /property:Configuration=Release /property:Platform=amd64
cd ..
$Host.UI.RawUI.WindowTitle += ": ok"
Start-Sleep -Seconds 1

if (Test-Path .\repo\build\Release\ep_setup.exe) {
	$Host.UI.RawUI.WindowTitle = "ep_make: Finalizing build"
	if (-not (Test-Path $regKey)) {
		New-Item -Path $regKey -Force -ErrorAction SilentlyContinue
	}
	Set-ItemProperty -Path $regKey -Name "UpdateUseLocal" -Value 1 -Type DWORD
	cd repo
	cd build
	cd Release
	.\ep_setup_patch.exe $EP_hashToUse
	$process = Get-Process -Name "ep_setup_patch" -ErrorAction SilentlyContinue
	if ($process) {
		$process | Wait-Process
	}
	cd ..
	cd ..
	cd ..
	$Host.UI.RawUI.WindowTitle += ": ok"
	Start-Sleep -Seconds 1
} else {
	$Host.UI.RawUI.WindowTitle = "ep_make: Build failed"
	Write-Host "Build failed. Press any key to continue..."
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
