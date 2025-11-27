# PowerShell C2 Framework (Educational Purposes Only)

A PowerShell-based Command & Control (C2) framework that supports multiple clients, reverse shells, and a `.lnk`-based launcher.  
Built for learning about networking, PowerShell automation, sockets, threading, and security research.

⚠️ **This project is for educational and cybersecurity lab use only.  
Do NOT use on systems you do not own or have permission to test.**

---

## Features

### ✅ C2-Server.ps1  
- Accepts multiple simultaneous client connections  
- Sends commands to connected hosts  
- Receives real-time command output  
- Supports file transfer (via Invoke-WebRequest)  
- Built-in help menu (`help`)  
- Clear screen (`cls` / `clear`)  
- Session manager for interacting with multiple clients  

---

### ✅ powershell-rev-shell.ps1  
- Connects back to the server  
- Sends a hostname/banner on connection  
- Receives and executes commands  
- Sends back command output  
- Background listener thread  
- Gracefully handles disconnects  

---

### ✅ lnk-file.ps1 (Launcher Generator)
Creates a `.lnk` Windows shortcut that:

- Runs hidden (no PowerShell window flash)  
- Downloads the PowerShell reverse shell into memory  
- Automatically connects back to the attacker’s C2 server  

Useful for **payload chaining**, **user execution testing**, and **malware simulation**, strictly for **educational purposes**.

---

## Usage

### 🔹 1. Start the C2 Server

```powershell
pwsh c2-server.ps1
```

---

### 🔹 2. Host `powershell-rev-shell.ps1` on an Apache2 server

Place the reverse shell script on your Apache web server:

```
/var/www/html/powershell-rev-shell.ps1
```

This is the script the `.lnk` launcher will download and execute.

---

### 🔹 3. Generate the `.lnk` launcher

On a Windows machine:

```powershell
pwsh lnk-file.ps1
```

This generates a `.lnk` shortcut that will:

- Download `powershell-rev-shell.ps1` from your Apache server  
- Execute it in memory  
- Connect back to your C2 server  

---

### 🔹 4. Deliver the `.lnk` file to the target (lab machine)

When the user double-clicks the `.lnk` file:

- The reverse shell is retrieved  
- PowerShell runs it silently  
- The client connects back to the C2 server  

You can now fully control the client through the server interface.

---

## Versioning

Releases follow semantic versioning:

```
v1.0 – Initial release  
v1.1 – Code cleanup and improvements  
v2.0 – Feature expansion
```

---

## License

This project is licensed under the **MIT License**, allowing modification and redistribution as long as the LICENSE file is included.

---

## Disclaimer

This project is built solely for:

- Penetration testing labs  
- Red team learning  
- Network and PowerShell education  
- Malware analysis training  

The author is **not responsible** for any misuse or illegal activity.
