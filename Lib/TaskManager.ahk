; ======================================================================================================================
; Module: TaskManager.ahk - Action Tasks Engine, CSV Storage, Auto-Watcher, Weekly Backup & Archiving
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

InitTaskManager() {
    global LastTaskFileModTime, ActionTasksFile
    LoadActionTasks()
    if FileExist(ActionTasksFile)
        LastTaskFileModTime := FileGetTime(ActionTasksFile, "M")
    
    PerformWeeklyTasksBackup()
    SetTimer(CheckExternalTaskFileChanges, 2000)
    
    ArchivePreviousDaysCompletedTasks()
    SetTimer(ArchivePreviousDaysCompletedTasks, 3600000)
}

LoadActionTasks() {
    global ActionTasks, ActionTasksFile
    ActionTasks := []
    
    if !FileExist(ActionTasksFile) {
        nowStr := FormatTime(A_Now, "yyyy-MM-dd HH:mm")
        ActionTasks.Push({id: 1, task: "Review and approve GST audit report by Friday 5 PM", created: nowStr, commitmentType: "Deadline", priority: "Q1", done: false})
        ActionTasks.Push({id: 2, task: "Send updated contract draft to client", created: nowStr, commitmentType: "Promise", priority: "Q2", done: false})
        ActionTasks.Push({id: 3, task: "Send Zoom invite for vendor sync", created: nowStr, commitmentType: "Quick", priority: "Q3", done: false})
        ActionTasks.Push({id: 4, task: "Read new direct tax circular", created: nowStr, commitmentType: "Review", priority: "Q4", done: false})
        SaveActionTasks()
        return
    }
    
    try {
        content := FileRead(ActionTasksFile, "UTF-8")
        rows := ParseFullCSV(content)
        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "id")
                continue
            if (row.Length >= 6) {
                idVal := Integer(Trim(row[1]))
                t := Trim(row[2])
                if (t = "")
                    continue
                c := row[3]
                ct := row[4]
                p := NormalizePriority(Trim(row[5]))
                d := (StrLower(Trim(row[6])) = "true" || Trim(row[6]) = "1")
                doneDateVal := (row.Length >= 7) ? Trim(row[7]) : ""
                ; Fix [Concern 4]: Load doneDate if present
                ActionTasks.Push({id: idVal, task: t, created: c, commitmentType: ct, priority: p, done: d, doneDate: doneDateVal})
            }
        }
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("LoadActionTasks", err)
    }
}

NormalizePriority(pStr) {
    if InStr(pStr, "1")
        return "Q1"
    if InStr(pStr, "2")
        return "Q2"
    if InStr(pStr, "3")
        return "Q3"
    return "Q4"
}

SaveActionTasks() {
    global ActionTasks, ActionTasksFile
    ; Fix [Concern 4]: Include doneDate column in CSV schema
    local content := "id,task,created,commitmentType,priority,done,doneDate`n"
    local tempFile := ActionTasksFile . ".tmp"
    local fileObj := ""
    local writeOk := false
    
    for t in ActionTasks {
        local cleanTask := StrReplace(StrReplace(t.task, "`r`n", "\n"), "`n", "\n")
        local taskEsc   := '"' . StrReplace(cleanTask, '"', '""') . '"'
        local doneStr   := t.done ? "true" : "false"
        local doneD     := (t.HasProp("doneDate") && t.doneDate != "") ? t.doneDate : ""
        content .= Format("{},{},{},{},{},{},{}`n", t.id, taskEsc, t.created, t.commitmentType, t.priority, doneStr, doneD)
    }
    
    try {
        fileObj := FileOpen(tempFile, "w", "UTF-8")
        if !IsObject(fileObj)
            throw Error("Cannot create temporary tasks file")
        fileObj.Write(content)
        writeOk := true
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("SaveActionTasks", err)
    } finally {
        if IsObject(fileObj)
            fileObj.Close()
    }
    
    if writeOk {
        if FileExist(ActionTasksFile)
            FileDelete(ActionTasksFile)
        FileMove(tempFile, ActionTasksFile)
    }
}

; --- Shared Task Lifecycle & Triage Primitives ---
IsTaskUntriaged(taskObj) {
    if !IsObject(taskObj)
        return false
    return (!taskObj.done && taskObj.priority = "Q4" && (taskObj.commitmentType = "" || taskObj.commitmentType = "Unassigned" || taskObj.commitmentType = "Task"))
}

CountUntriagedTasks() {
    global ActionTasks
    count := 0
    for t in ActionTasks {
        if IsTaskUntriaged(t)
            count++
    }
    return count
}

AddTask(taskText, priority := "Q4", commitmentType := "Unassigned") {
    global ActionTasks
    if (Trim(taskText) = "")
        return 0
    nowStr := FormatTime(A_Now, "yyyy-MM-dd HH:mm")
    newId := ActionTasks.Length > 0 ? ActionTasks[ActionTasks.Length].id + 1 : 1
    ActionTasks.Push({
        id: newId,
        task: Trim(taskText),
        created: nowStr,
        commitmentType: commitmentType,
        priority: priority,
        done: false
    })
    SaveActionTasks()
    return newId
}

AddNewTaskDirect(taskText, defaultQuadrant := "Q4") {
    global ActionTasks
    if (Trim(taskText) = "")
        return
        
    newId := AddTask(taskText, defaultQuadrant, "Unassigned")
    preview := StrLen(taskText) > 35 ? SubStr(taskText, 1, 32) . "..." : taskText
    ShowToast("📌 Added to " . defaultQuadrant . ": " . preview, 2000)
    
    if IsSet(RefreshMatrixBoard) && IsObject(ActionBoardGui)
        RefreshMatrixBoard()
}

CaptureSelectedTextAsTask() {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Enter task description (added to Q4):", "Quick Add Task")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    
    AddNewTaskDirect(Trim(sel), "Q4")
}

ToggleTaskDone(taskId) {
    global ActionTasks
    todayStr := FormatTime(A_Now, "yyyy-MM-dd")
    for t in ActionTasks {
        if (t.id = taskId) {
            t.done := !t.done
            ; Fix [Concern 4]: Record completion date so tasks completed today aren't archived immediately
            t.doneDate := t.done ? todayStr : ""
            SaveActionTasks()
            return t.done
        }
    }
    return false
}

DeleteTaskById(taskId) {
    global ActionTasks
    newTasks := []
    deleted := false
    for t in ActionTasks {
        if (t.id = taskId) {
            deleted := true
            continue
        }
        newTasks.Push(t)
    }
    if deleted {
        ActionTasks := newTasks
        SaveActionTasks()
    }
    return deleted
}

CheckExternalTaskFileChanges() {
    global LastTaskFileModTime, ActionTasksFile
    if !FileExist(ActionTasksFile)
        return
        
    try {
        currentModTime := FileGetTime(ActionTasksFile, "M")
        if (LastTaskFileModTime != 0 && currentModTime != LastTaskFileModTime) {
            LastTaskFileModTime := currentModTime
            LoadActionTasks()
            if IsSet(RefreshMatrixBoard) && IsObject(ActionBoardGui)
                RefreshMatrixBoard()
            ShowToast("🔄 Tasks automatically reloaded from updated CSV", 1500)
        }
    }
}

PerformWeeklyTasksBackup() {
    global ActionTasksFile, DataDir
    if !FileExist(ActionTasksFile)
        return
        
    backupDir := DataDir . "\Backups"
    if !DirExist(backupDir)
        DirCreate(backupDir)
        
    weekNum := FormatTime(A_Now, "YWeek")
    weekStr := SubStr(weekNum, 1, 4) . "_W" . SubStr(weekNum, 5)
    backupTarget := backupDir . "\tasks_backup_" . weekStr . ".csv"
    
    if !FileExist(backupTarget) {
        try {
            FileCopy(ActionTasksFile, backupTarget, 1)
        }
    }
}

ExportTasksManually() {
    global ActionTasksFile, DataDir
    if !FileExist(ActionTasksFile) {
        ShowToast("⚠️ No tasks file to export", 1500)
        return
    }
    
    backupDir := DataDir . "\Backups"
    if !DirExist(backupDir)
        DirCreate(backupDir)
        
    timeStr := FormatTime(A_Now, "yyyyMMdd_HHmmss")
    targetFile := backupDir . "\tasks_export_" . timeStr . ".csv"
    
    try {
        FileCopy(ActionTasksFile, targetFile, 1)
        ShowToast("✔ Exported snapshot to:`n" . targetFile, 3000)
    } catch as err {
        ShowToast("⚠️ Export failed: " . err.Message, 2000)
    }
}

ImportTasksPrompt() {
    global ActionTasks, ActionTasksFile
    selectedFile := FileSelect(3,, "Select CSV file to import tasks from", "CSV Files (*.csv)")
    if (selectedFile = "")
        return
        
    try {
        content := FileRead(selectedFile, "UTF-8")
        rows := ParseFullCSV(content)
        importedCount := 0
        
        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "id")
                continue
            if (row.Length >= 6) {
                t := Trim(row[2])
                if (t = "")
                    continue
                c := row[3]
                ct := row[4]
                p := NormalizePriority(Trim(row[5]))
                d := (StrLower(Trim(row[6])) = "true" || Trim(row[6]) = "1")
                
                exists := false
                for existing in ActionTasks {
                    if (existing.task = t) {
                        exists := true
                        break
                    }
                }
                
                if !exists {
                    newId := ActionTasks.Length > 0 ? ActionTasks[ActionTasks.Length].id + 1 : 1
                    ActionTasks.Push({id: newId, task: t, created: c, commitmentType: ct, priority: p, done: d})
                    importedCount++
                }
            }
        }
        
        SaveActionTasks()
        if IsSet(RefreshMatrixBoard) && IsObject(ActionBoardGui)
            RefreshMatrixBoard()
        ShowToast("✔ Successfully imported & merged " . importedCount . " new tasks!", 2500)
    } catch as err {
        ShowToast("⚠️ Import error: " . err.Message, 2500)
    }
}

ArchivePreviousDaysCompletedTasks() {
    global ActionTasks, ActionArchiveFile
    todayStr := FormatTime(A_Now, "yyyy-MM-dd")
    
    remainingTasks := []
    archivedTasks := []
    
    for t in ActionTasks {
        ; Fix [Concern 4]: Use doneDate when available so older tasks completed today remain visible until EOD/next day
        taskDate := (t.HasProp("doneDate") && t.doneDate != "") ? t.doneDate : SubStr(t.created, 1, 10)
        if (t.done && taskDate != todayStr) {
            archivedTasks.Push(t)
        } else {
            remainingTasks.Push(t)
        }
    }
    
    if (archivedTasks.Length > 0) {
        if !FileExist(ActionArchiveFile)
            FileAppend("id,task,created,commitmentType,priority,done,archivedDate`n", ActionArchiveFile, "UTF-8")
            
        for at in archivedTasks {
            cleanTask := '"' . StrReplace(at.task, '"', '""') . '"'
            line := Format("{},{},{},{},{},true,{}`n", at.id, cleanTask, at.created, at.commitmentType, at.priority, todayStr)
            FileAppend(line, ActionArchiveFile, "UTF-8")
        }
        
        ActionTasks := remainingTasks
        SaveActionTasks()
        if IsSet(RefreshMatrixBoard) && IsObject(ActionBoardGui)
            RefreshMatrixBoard()
    }
}

