; ======================================================================================================================
; Module: SnippetManager.ahk - Unified Snippet Storage, Dynamic Hotstring Engine & CRUD Operations
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

InitSnippetEngine() {
    global LastSnippetFileModTime, SnippetsFile
    LoadSnippets()
    RegisterDynamicHotstrings()
    if FileExist(SnippetsFile)
        LastSnippetFileModTime := FileGetTime(SnippetsFile, "M")
    SetTimer(CheckExternalSnippetFileChanges, 2000)
}

ScoreSnippetCandidate(fPath, &parsedList) {
    parsedList := []
    if (!FileExist(fPath) || FileGetSize(fPath) = 0)
        return -1

    try {
        content := FileRead(fPath, "UTF-8")
        rows := ParseFullCSV(content)
        tempList := []
        customCount := 0
        dummyCount := 0
        totalCharCount := 0

        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "trigger")
                continue
            if (row.Length >= 2) {
                t := Trim(row[1])
                if (t = "")
                    continue
                r := StrReplace(StrReplace(row[2], "\\n", "`n"), "`r`n", "`n")
                e := (row.Length >= 3) ? (StrLower(Trim(row[3])) = "true" || Trim(row[3]) = "1") : true
                tempList.Push({trigger: t, replacement: r, enabled: e})
                
                tLower := StrLower(t)
                if (tLower = "myemail" || tLower = "myphone" || tLower = "myaddr")
                    dummyCount++
                else
                    customCount++
                
                totalCharCount += StrLen(t) + StrLen(r)
            }
        }

        if (tempList.Length = 0)
            return 0  ; Valid CSV but empty of data rows

        parsedList := tempList

        ; If it only has dummy seed triggers
        if (customCount = 0 && dummyCount > 0)
            return 10 + dummyCount

        ; Calculate mod time bonus (normalize to small fraction for tie-breaking)
        mTime := 0
        try mTime := Number(FileGetTime(fPath, "M"))
        recencyBonus := (mTime > 0) ? (mTime / 1000000000000.0) : 0

        ; Score: 1000 base + (customCount * 100) + dummyCount + char richness + recency
        score := 1000 + (customCount * 100) + dummyCount + Min(100, totalCharCount // 50) + recencyBonus
        return score
    } catch as err {
        try LogAppError("ScoreSnippetCandidate (" . fPath . ")", err)
        return -1
    }
}

IsSnippetCatalogChanged(newSnippets, targetFilePath) {
    if (!FileExist(targetFilePath) || FileGetSize(targetFilePath) = 0)
        return true

    try {
        content := FileRead(targetFilePath, "UTF-8")
        rows := ParseFullCSV(content)
        existing := []

        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "trigger")
                continue
            if (row.Length >= 2) {
                t := Trim(row[1])
                if (t = "")
                    continue
                r := StrReplace(StrReplace(row[2], "\\n", "`n"), "`r`n", "`n")
                e := (row.Length >= 3) ? (StrLower(Trim(row[3])) = "true" || Trim(row[3]) = "1") : true
                existing.Push({trigger: t, replacement: r, enabled: e})
            }
        }

        if (existing.Length != newSnippets.Length)
            return true

        for idx, snip in newSnippets {
            ex := existing[idx]
            if (snip.trigger != ex.trigger || snip.replacement != ex.replacement || snip.enabled != ex.enabled)
                return true
        }
        return false
    } catch {
        return true
    }
}

MergeIntoMasterBackup(incomingSnippets) {
    global SnippetsMasterBackupFile, DataDir
    if (incomingSnippets.Length = 0)
        return

    backupDir := DataDir . "\Backups"
    if !DirExist(backupDir)
        DirCreate(backupDir)

    masterList := []
    if (FileExist(SnippetsMasterBackupFile) && FileGetSize(SnippetsMasterBackupFile) > 0) {
        try {
            content := FileRead(SnippetsMasterBackupFile, "UTF-8")
            rows := ParseFullCSV(content)
            for rIdx, row in rows {
                if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "trigger")
                    continue
                if (row.Length >= 2) {
                    t := Trim(row[1])
                    if (t = "")
                        continue
                    r := StrReplace(StrReplace(row[2], "\\n", "`n"), "`r`n", "`n")
                    e := (row.Length >= 3) ? (StrLower(Trim(row[3])) = "true" || Trim(row[3]) = "1") : true
                    masterList.Push({trigger: t, replacement: r, enabled: e})
                }
            }
        }
    }

    ; Merge incoming items into masterList:
    ; 1. Exact match (trigger + replacement identical) -> keep single entry with current enabled state
    ; 2. Conflicting replacement (same trigger, different replacement) -> preserve both in master snapshot!
    ;    Keep incoming active (enabled := incoming.enabled), mark older conflicting version as enabled := false (inactive) without renaming trigger.
    ; 3. New trigger -> append to masterList
    for inSnip in incomingSnippets {
        exactFound := false
        for mSnip in masterList {
            if (StrLower(mSnip.trigger) == StrLower(inSnip.trigger)) {
                if (mSnip.replacement == inSnip.replacement) {
                    mSnip.enabled := inSnip.enabled
                    exactFound := true
                    break
                } else {
                    ; Conflicting replacement: make older entry inactive
                    mSnip.enabled := false
                }
            }
        }
        if !exactFound {
            masterList.Push({trigger: inSnip.trigger, replacement: inSnip.replacement, enabled: inSnip.enabled})
        }
    }

    content := "trigger,replacement,enabled`n"
    for snip in masterList {
        enStr := snip.enabled ? "true" : "false"
        content .= FormatCSVRow([snip.trigger, snip.replacement, enStr])
    }

    tempFile := SnippetsMasterBackupFile . ".tmp"
    try {
        fileObj := FileOpen(tempFile, "w", "UTF-8")
        if IsObject(fileObj) {
            fileObj.Write(content)
            fileObj.Close()
            if FileExist(SnippetsMasterBackupFile)
                FileDelete(SnippetsMasterBackupFile)
            FileMove(tempFile, SnippetsMasterBackupFile)
        }
    } catch as err {
        try LogAppError("MergeIntoMasterBackup", err)
    }
}

CreateSnippetBackup(targetBackupPath, force := false) {
    global SnippetsFile, DataDir
    if !FileExist(SnippetsFile)
        return false
    try {
        if (FileGetSize(SnippetsFile) = 0)
            return false
        backupDir := DataDir . "\Backups"
        if !DirExist(backupDir)
            DirCreate(backupDir)

        ; "Never overwrite more with less" guard
        if (!force && FileExist(targetBackupPath) && FileGetSize(targetBackupPath) > 0) {
            existingBackupList := []
            backupScore := ScoreSnippetCandidate(targetBackupPath, &existingBackupList)
            currentList := []
            currentScore := ScoreSnippetCandidate(SnippetsFile, &currentList)

            ; If existing backup has custom data (score >= 1000) and current file is dummy/inferior
            if (backupScore >= 1000 && currentScore < 1000) {
                return false ; Block destructive overwrite
            }
        }

        FileCopy(SnippetsFile, targetBackupPath, 1)
        return true
    } catch as err {
        try LogAppError("CreateSnippetBackup", err)
        return false
    }
}

LoadSnippets() {
    global Snippets, SnippetsFile, SnippetsMasterBackupFile, SnippetsPrevBackupFile, SnippetsPreImportFile, LastSnippetFileModTime, DataDir
    Snippets := []

    candidateFiles := [SnippetsFile, SnippetsMasterBackupFile, SnippetsPrevBackupFile, SnippetsPreImportFile]

    bestScore := -1
    bestCandidate := ""
    bestSnippets := []

    for fPath in candidateFiles {
        tempList := []
        candScore := ScoreSnippetCandidate(fPath, &tempList)
        if (candScore > bestScore) {
            bestScore := candScore
            bestCandidate := fPath
            bestSnippets := tempList
        }
    }

    isRecovered := false

    if (bestScore > 0 && bestSnippets.Length > 0) {
        Snippets := bestSnippets
        isRecovered := (bestCandidate != SnippetsFile)
    } else {
        ; If neither primary nor any backups contained valid snippet rows (fresh install / empty state):
        Snippets.Push({trigger: "myemail", replacement: "john.doe@example.com", enabled: true})
        Snippets.Push({trigger: "myphone", replacement: "+1 (555) 123-4567", enabled: true})
        Snippets.Push({trigger: "myaddr", replacement: "123 Main Street`nAnytown, ST 12345`nUSA", enabled: true})
        SaveSnippets()
        return
    }

    ; If we recovered from a backup file, self-heal by rewriting the primary file
    if (isRecovered && Snippets.Length > 0) {
        SaveSnippets()
        try ShowToast("🔄 Snippets auto-recovered from backup (" . Snippets.Length . " items)", 2500)
    } else if (bestCandidate == SnippetsFile && bestScore >= 1000) {
        ; Ensure Master Snapshot is initialized with this rich catalog
        MergeIntoMasterBackup(Snippets)
        if (!FileExist(SnippetsPrevBackupFile) || FileGetSize(SnippetsPrevBackupFile) == 0) {
            CreateSnippetBackup(SnippetsPrevBackupFile, true)
        } else {
            bList := []
            bScore := ScoreSnippetCandidate(SnippetsPrevBackupFile, &bList)
            if (bScore < 1000) {
                CreateSnippetBackup(SnippetsPrevBackupFile, true)
            }
        }
    }

    if FileExist(SnippetsFile)
        LastSnippetFileModTime := FileGetTime(SnippetsFile, "M")
}

SaveSnippets() {
    global Snippets, SnippetsFile, SnippetsPrevBackupFile, LastSnippetFileModTime
    local content := "trigger,replacement,enabled`n"
    local tempFile := SnippetsFile . ".tmp"
    local fileObj := ""
    local writeOk := false

    for snip in Snippets {
        local enStr := snip.enabled ? "true" : "false"
        content .= FormatCSVRow([snip.trigger, snip.replacement, enStr])
    }

    hasChanged := IsSnippetCatalogChanged(Snippets, SnippetsFile)

    try {
        if hasChanged {
            ; Rotate to Slot 1 (Previous version backup) before overwrite
            CreateSnippetBackup(SnippetsPrevBackupFile)
            ; Merge into Master Snapshot
            MergeIntoMasterBackup(Snippets)
        }

        fileObj := FileOpen(tempFile, "w", "UTF-8")
        if !IsObject(fileObj)
            throw Error("Cannot create temporary snippets file")
        fileObj.Write(content)
        writeOk := true
    } catch as err {
        try LogAppError("SaveSnippets", err)
    } finally {
        if IsObject(fileObj)
            fileObj.Close()
    }

    if writeOk {
        if FileExist(SnippetsFile)
            FileDelete(SnippetsFile)
        FileMove(tempFile, SnippetsFile)
        if FileExist(SnippetsFile)
            LastSnippetFileModTime := FileGetTime(SnippetsFile, "M")
    }
}

RegisterDynamicHotstrings() {
    global RegisteredTriggers, Snippets

    for trig in RegisteredTriggers {
        try {
            Hotstring(":X:" . trig, , 0)
        }
    }
    RegisteredTriggers.Clear()

    for snip in Snippets {
        if (snip.enabled && snip.trigger != "") {
            try {
                Hotstring(":X:" . snip.trigger, SnippetHotstringCallback.Bind(snip.replacement), 1)
                RegisteredTriggers[snip.trigger] := true
            } catch as err {
                try LogAppError("RegisterDynamicHotstrings (" . snip.trigger . ")", err)
            }
        }
    }
}

SnippetHotstringCallback(replacement, *) {
    endChar := (A_EndChar = "`n" || A_EndChar = "`r") ? "" : A_EndChar
    InsertText(replacement . endChar, false)
}

DeleteSnippet(trigger) {
    global Snippets
    trigLower := StrLower(Trim(trigger))
    newSnippets := []
    deleted := false
    
    for s in Snippets {
        if (StrLower(s.trigger) = trigLower) {
            deleted := true
            continue
        }
        newSnippets.Push(s)
    }
    
    if deleted {
        Snippets := newSnippets
        SaveSnippets()
        RegisterDynamicHotstrings()
    }
    return deleted
}

UpsertSnippetInMemory(trigger, replacement, enabled := true) {
    global Snippets
    tClean := Trim(trigger)
    if (tClean = "")
        return false
        
    tLower := StrLower(tClean)
    found := false
    
    for s in Snippets {
        if (StrLower(s.trigger) = tLower) {
            s.replacement := replacement
            s.enabled := enabled
            found := true
            break
        }
    }
    
    if !found {
        Snippets.Push({trigger: tClean, replacement: replacement, enabled: enabled})
    }
    return true
}

UpsertSnippet(trigger, replacement, enabled := true) {
    if !UpsertSnippetInMemory(trigger, replacement, enabled)
        return false
        
    SaveSnippets()
    RegisterDynamicHotstrings()
    return true
}

ImportSnippetsFromCsv(filePath) {
    global Snippets, SnippetsPreImportFile
    if !FileExist(filePath)
        return 0
        
    importedCount := 0
    try {
        content := FileRead(filePath, "UTF-8")
        rows := ParseFullCSV(content)
        
        ; Save pre-import snapshot slot before mutating
        CreateSnippetBackup(SnippetsPreImportFile)

        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "trigger")
                continue
            if (row.Length >= 2) {
                t := Trim(row[1])
                if (t = "")
                    continue
                r := StrReplace(StrReplace(row[2], "\\n", "`n"), "`r`n", "`n")
                e := (row.Length >= 3) ? (StrLower(Trim(row[3])) = "true" || Trim(row[3]) = "1") : true
                if UpsertSnippetInMemory(t, r, e)
                    importedCount++
            }
        }
        
        if (importedCount > 0) {
            SaveSnippets()
            RegisterDynamicHotstrings()
        }
    } catch as err {
        try LogAppError("ImportSnippetsFromCsv", err)
    }
    return importedCount
}

CheckExternalSnippetFileChanges() {
    global LastSnippetFileModTime, SnippetsFile, SnippetsPrevBackupFile, Snippets
    if !FileExist(SnippetsFile)
        return
        
    try {
        currentModTime := FileGetTime(SnippetsFile, "M")
        if (LastSnippetFileModTime != 0 && currentModTime != LastSnippetFileModTime) {
            LastSnippetFileModTime := currentModTime
            LoadSnippets()
            RegisterDynamicHotstrings()

            ; Snapshot external change to backup if rich catalog
            if (Snippets.Length > 0) {
                tempList := []
                if (ScoreSnippetCandidate(SnippetsFile, &tempList) >= 1000)
                    CreateSnippetBackup(SnippetsPrevBackupFile, true)
            }

            try RefreshSnippetListView()
            try ShowToast("🔄 Snippets reloaded from updated CSV", 1500)
        }
    }
}

ExportSnippetsToCsv(destPath) {
    global Snippets
    content := "trigger,replacement,enabled`n"
    for snip in Snippets {
        enStr := snip.enabled ? "true" : "false"
        content .= FormatCSVRow([snip.trigger, snip.replacement, enStr])
    }
    try {
        if FileExist(destPath)
            FileDelete(destPath)
        FileAppend(content, destPath, "UTF-8")
        return true
    } catch as err {
        try LogAppError("ExportSnippetsToCsv", err)
        return false
    }
}

CaptureSelectedTextAsSnippet() {
    global Snippets, AppTitle
    selectedText := SafeGetSelection()
    if (Trim(selectedText) = "") {
        ib := OfficeInputBox("Enter or paste snippet replacement text:", "Create New Snippet")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        selectedText := ib.Value
    }
    
    previewStr := SubStr(selectedText, 1, 100)
    ibTrigger := OfficeInputBox("Enter trigger keyword (e.g. 'supmail'):`n`nPreview: " . previewStr, "Save Snippet", "", true)
    if (ibTrigger.Result != "OK" || Trim(ibTrigger.Value) = "")
        return

    trigger := Trim(ibTrigger.Value)
    for snip in Snippets {
        if (StrLower(snip.trigger) = StrLower(trigger)) {
            MsgBox("Trigger '" . trigger . "' already exists. Please choose a unique name.", AppTitle, "Icon!")
            return
        }
    }

    UpsertSnippet(trigger, selectedText, true)
    
    try RefreshSnippetListView()
    try ShowToast("✅ Snippet '" . trigger . "' saved & active!", 2500)
}

