; ======================================================================================================================
; Module: Actions_Utility.ahk - 11 File, Path & System Office Utilities
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterUtilityActions() {
    RegisterAction("Export Diagnostic & Analytics Report", "📁 Utility", "Generates and opens complete diagnostics & telemetry report on Desktop", "export, debug, diagnostics, telemetry, report, logs, stats", (*) => ExportDiagnosticsReport())
    RegisterAction("Copy Clean File Path (Forward Slashes)", "📁 Utility", "Converts clipboard/selection file path to C:/Folder/File format", "path, forward, slash, url, linux, copy", (*) => ConvertClipboardPath("/"))
    RegisterAction("Copy Clean File Path (Escaped Slashes)", "📁 Utility", "Converts clipboard/selection file path to C:\\Folder\\File format", "path, escaped, double, backslash, json, code", (*) => ConvertClipboardPath("\\"))
    RegisterAction("Prefix Selected File with Timestamp", "📁 Utility", "Renames selected file in Explorer with YYMMDD_ prefix", "rename, prefix, explorer, file, timestamp", (*) => PrefixExplorerSelectedFile())
    RegisterAction("Google Search Selected Text", "📁 Utility", "Opens default browser searching selected term", "search, google, web, query, lookup", (*) => SearchWebSelection("https://www.google.com/search?q="))
    RegisterAction("Google Translate Selected Text", "📁 Utility", "Opens Google Translate for selected text", "translate, language, dict, meaning", (*) => SearchWebSelection("https://translate.google.com/?text="))
    RegisterAction("Toggle Window Always-on-Top", "📁 Utility", "Pins or unpins active window to always stay visible", "pin, top, always on top, float, window", (*) => ToggleAlwaysOnTop())
    RegisterAction("Toggle Window Transparency (75%)", "📁 Utility", "Toggles semi-transparency on active window for comparing docs", "transparent, opacity, ghost, trace, window", (*) => ToggleWindowTransparency())
    RegisterAction("Open Today's Daily Scratchpad Notes", "📁 Utility", "Opens a timestamped daily text file for notes", "scratchpad, notes, daily, journal, memo", (*) => OpenDailyScratchpad(), "n")
    RegisterAction("Empty Windows Recycle Bin", "📁 Utility", "Silently purges all items from Windows Recycle Bin", "recycle, bin, trash, clean, empty, purge", (*) => SilentEmptyRecycleBin())
    RegisterAction("Quick Privacy Screen / Lock", "📁 Utility", "Instantly locks the Windows workstation", "lock, privacy, screen, secure, workstation", (*) => DllCall("LockWorkStation"))
}

ConvertClipboardPath(slashType) {
    path := ResolveCurrentFilePath()
    
    if (path = "") {
        ShowToast("⚠️ No file or folder path found", 2000)
        return
    }

    pathClean := Trim(path, ' "`'')
    
    if (slashType = "/") {
        clean := StrReplace(pathClean, "\", "/")
    } else if (slashType = "\\") {
        clean := StrReplace(StrReplace(pathClean, "\\", "\"), "\", "\\")
    } else {
        clean := pathClean
    }

    A_Clipboard := clean
    
    if CanPasteToTargetWindow() {
        InsertText(clean)
    }
    
    preview := StrLen(clean) > 45 ? SubStr(clean, 1, 42) . "..." : clean
    ShowToast("✔ Copied path: " . preview, 2000)
}

PrefixExplorerSelectedFile() {
    targetPath := ResolveCurrentFilePath()
    
    if (targetPath = "" || !FileExist(targetPath)) {
        ShowToast("⚠️ Please select a file or folder in File Explorer first", 2000)
        return
    }
        
    SplitPath(targetPath, &fileName, &fileDir, &fileExt, &nameNoExt)
    prefix := FormatTime(A_Now, "yyMMdd_")
    
    if InStr(fileName, prefix) = 1 {
        ShowToast("⚠️ Already has timestamp prefix: " . fileName, 2000)
        return
    }
    
    newPath := fileDir . "\" . prefix . fileName
    try {
        if InStr(FileExist(targetPath), "D") {
            DirMove(targetPath, newPath, 0)
        } else {
            FileMove(targetPath, newPath)
        }
        ShowToast("✔ Renamed to: " . prefix . fileName, 2000)
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("PrefixExplorerSelectedFile", err)
        ShowToast("Rename Error: " . err.Message, 2500)
    }
}

SearchWebSelection(urlPrefix) {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Enter search query:", "Web Lookup")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    Run(urlPrefix . EncodeUriComponent(Trim(sel)))
}

EncodeUriComponent(str) {
    if (str = "")
        return ""
    try {
        utf8Buf := Buffer(StrPut(str, "UTF-8"))
        StrPut(str, utf8Buf, "UTF-8")
        encoded := ""
        loop utf8Buf.Size - 1 {
            b := NumGet(utf8Buf, A_Index - 1, "UChar")
            if ((b >= 48 && b <= 57) || (b >= 65 && b <= 90) || (b >= 97 && b <= 122) || b = 45 || b = 95 || b = 46 || b = 33 || b = 126 || b = 42 || b = 39 || b = 40 || b = 41) {
                encoded .= Chr(b)
            } else {
                encoded .= Format("%{:02X}", b)
            }
        }
        return encoded
    } catch {
        return str
    }
}

ToggleAlwaysOnTop() {
    hwnd := WinActive("A")
    if !hwnd
        return
    exStyle := WinGetExStyle(hwnd)
    isTop := (exStyle & 0x8)
    curTitle := WinGetTitle(hwnd)
    
    if isTop {
        ; Unpin window
        WinSetAlwaysOnTop(0, hwnd)
        if InStr(curTitle, "[📌] ") == 1 {
            newTitle := SubStr(curTitle, 6) ; remove '[📌] '
            try WinSetTitle(newTitle, hwnd)
        }
        ShowToast("📌 Window Unpinned (Normal)", 1500)
    } else {
        ; Pin window
        WinSetAlwaysOnTop(1, hwnd)
        if InStr(curTitle, "[📌] ") != 1 {
            newTitle := "[📌] " . curTitle
            try WinSetTitle(newTitle, hwnd)
        }
        ShowToast("📌 Window Pinned (Always on Top)", 1500)
    }
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [WINDOW TRANSPARENCY TOGGLE - FIXED 75% INTENT]:
; 1. Fixed 75% opacity (alpha 190) — no user-configurable value or original alpha restoration for this simple toggle.
; 2. This is intentional: Quick, zero-dialog 1-click toggling between solid (255) and semi-transparent (190).
; 3. Advanced use cases with configurable transparency levels (5%–90%) and multi-window depth slicing are handled 
;    separately by the dedicated 'X-Ray Layer Peek' engine.
; ======================================================================================================================
ToggleWindowTransparency() {
    hwnd := WinActive("A")
    if !hwnd
        return
    curTrans := WinGetTransparent(hwnd)
    if (curTrans = 190) {
        WinSetTransparent(255, hwnd)
        ShowToast("Window Opacity: 100% (Solid)", 1500)
    } else {
        WinSetTransparent(190, hwnd)
        ShowToast("Window Opacity: 75% (Semi-Transparent)", 1500)
    }
}

OpenDailyScratchpad() {
    scratchPath := DataDir . "\Scratchpad_" . FormatTime(A_Now, "yyyy_MM_dd") . ".txt"
    if !FileExist(scratchPath) {
        header := "========================================================`n"
            . "Daily Scratchpad: " . FormatTime(A_Now, "dddd, MMMM d, yyyy") . "`n"
            . "========================================================`n`n"
        FileAppend(header, scratchPath, "UTF-8")
    }
    Run('notepad.exe "' . scratchPath . '"')
}

; ======================================================================================================================
; ARCHITECTURAL INTENT [EMPTY RECYCLE BIN - ZERO-DIALOG SILENT CLEANUP]:
; 1. Silent Operation: Uses SHEmptyRecycleBin flags (SHERB_NOCONFIRMATION | SHERB_NOPROGRESSUI | SHERB_NOSOUND = 7)
;    to instantly purge deleted temporary items without prompting for confirmation.
; 2. Design Rationale: Streamlined for maximum productivity speed and zero popup interruptions.
;    Important project files and persistent datasets are maintained in dedicated repositories and automated backups.
; ======================================================================================================================
SilentEmptyRecycleBin() {
    DllCall("Shell32\SHEmptyRecycleBin", "Ptr", 0, "Ptr", 0, "UInt", 7)
    ShowToast("🗑️ Recycle Bin Emptied", 1500)
}

