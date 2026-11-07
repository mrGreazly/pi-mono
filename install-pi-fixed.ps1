# Installs or updates pi-fixed (pi built from the pi-fixed branch of mrGreazly/pi-mono) on Windows.
# Usage: powershell -c "irm https://raw.githubusercontent.com/mrGreazly/pi-mono/pi-fixed/install-pi-fixed.ps1 | iex"
& {
	$ErrorActionPreference = "Stop"
	$ProgressPreference = "SilentlyContinue"

	$repo = "mrGreazly/pi-mono"
	$installDir = Join-Path $env:LOCALAPPDATA "pi-fixed"
	$platform = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "windows-arm64" } else { "windows-x64" }
	$url = "https://github.com/$repo/releases/latest/download/pi-$platform.zip"

	$work = Join-Path ([IO.Path]::GetTempPath()) ("pi-fixed-" + [Guid]::NewGuid())
	New-Item -ItemType Directory -Path $work | Out-Null
	try {
		Write-Host "Downloading $url"
		$zip = Join-Path $work "pi.zip"
		Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
		$staged = Join-Path $work "pi"
		Expand-Archive -Path $zip -DestinationPath $staged

		if (Test-Path $installDir) {
			try {
				Remove-Item -Recurse -Force $installDir
			} catch {
				throw "Cannot replace $installDir. Close every running pi and run the installer again."
			}
		}
		Move-Item $staged $installDir
	} finally {
		Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
	}

	# Edit the raw user PATH so %VARIABLES% in other entries stay unexpanded.
	$key = (Get-Item "HKCU:\").OpenSubKey("Environment", $true)
	$raw = $key.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
	$kind = if ($raw) { $key.GetValueKind("Path") } else { [Microsoft.Win32.RegistryValueKind]::ExpandString }
	$entries = @($raw -split ";" | Where-Object { $_ })
	# The official pi installer's entries would shadow or replace pi-fixed; its files stay on disk.
	$official = @($entries | Where-Object { $_ -like "*\pi-agent\releases\*" })
	$kept = @($entries | Where-Object { ($_ -notlike "*\pi-agent\releases\*") -and ($_.TrimEnd("\") -ne $installDir) })
	$key.SetValue("Path", (@($installDir) + $kept) -join ";", $kind)
	$key.Close()
	foreach ($entry in $official) { Write-Host "Removed official pi from user PATH: $entry" }

	$env:Path = "$installDir;" + (($env:Path -split ";" | Where-Object { $_ -and ($_ -notlike "*\pi-agent\releases\*") }) -join ";")

	$version = & (Join-Path $installDir "pi.exe") --version
	Write-Host "Installed pi-fixed $version to $installDir"
	Write-Host "Open a new terminal (restart T3 Code for its terminals) so 'pi' starts pi-fixed."
}
