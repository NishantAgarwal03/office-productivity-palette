; ======================================================================================================================
; Module: Core.ahk - Action Registry, Leader-Key Engine, Global UI Visibility & Escape Dismissal Engine
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterAction(name, category, description, keywords, callback, chord := "", hotkey := "") {
    global BuiltInActions
    BuiltInActions.Push({
        name: name,
        category: category,
        description: description,
        keywords: keywords,
        callback: callback,
        chord: chord,
        hotkey: hotkey,
        isCustom: false
    })
}

FormatShortcutBadge(item) {
    if (item.HasOwnProp("isCustom") && item.isCustom)
        return "::" . item.triggerName
    if (item.HasOwnProp("hotkey") && item.hotkey != "")
        return item.hotkey
    if (item.HasOwnProp("chord") && item.chord != "")
        return "Leader, " . StrUpper(item.chord)
    return "↵"
}

ExecuteLeaderKeyChord(key) {
    global CapsLockChordFired, BuiltInActions
    CapsLockChordFired := true
    
    key := StrLower(Trim(key))
    if (key = "" || key = "`e" || key = "escape")
        return
        
    if (key = "?" || key = "space") {
        if IsSet(ShowCommandPalette)
            ShowCommandPalette()
        return
    }

    for act in BuiltInActions {
        if (act.chord != "" && StrLower(act.chord) = key) {
            try {
                act.callback.Call()
            } catch as err {
                if IsSet(LogAppError)
                    LogAppError("ExecuteLeaderKeyChord (" . act.name . ")", err)
            }
            return
        }
    }

    ShowToast("Unknown Leader Key: '" . key . "' (Press '?' for Palette)", 2000)
}

ActivateLeaderKey() {
    global LeaderActive, LeaderInputHook
    
    if IsSet(LeaderInputHook) && IsObject(LeaderInputHook) {
        try LeaderInputHook.Stop()
    }
    
    LeaderActive := true
    ToolTip("⚡ [Leader Mode]`nc: Calc  | u: Civil | t: Time | v: CleanText`ns: snake | x: Todo  | p: Pass | w: Rupees`n?: Palette (Esc to Cancel)")
    
    LeaderInputHook := InputHook("L1 T2.5 C")
    LeaderInputHook.KeyOpt("{All}", "E")
    LeaderInputHook.OnEnd := (ih) => OnLeaderHookEnd(ih)
    LeaderInputHook.Start()
}

OnLeaderHookEnd(ih) {
    global LeaderActive
    ToolTip()
    LeaderActive := false
    
    if (ih.EndReason != "EndKey" && ih.EndReason != "Max")
        return
        
    inputKey := (ih.Input != "") ? ih.Input : ih.EndKey
    ExecuteLeaderKeyChord(inputKey)
}

RepeatLastAction() {
    global LastExecutedAction
    if (!IsObject(LastExecutedAction) || !LastExecutedAction.HasOwnProp("callback")) {
        ShowToast("⚠️ No previous action to repeat", 2000)
        return
    }
    try {
        LastExecutedAction.callback.Call()
        ShowToast("🔁 Repeated: " . LastExecutedAction.name, 1500)
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("RepeatLastAction (" . LastExecutedAction.name . ")", err)
        ShowToast("Repeat Error: " . err.Message, 2500)
    }
}

; --- Global UI Visibility & Escape Key Dismissal Engine ---

SafeIsWindowVisible(guiObj) {
    if !IsObject(guiObj)
        return false
    try {
        hwnd := guiObj.Hwnd
        return (hwnd && WinExist("ahk_id " . hwnd) && DllCall("user32\IsWindowVisible", "ptr", hwnd))
    } catch {
        return false
    }
}

IsAnyOfficeUIVisible() {
    global PaletteGui, ActionBoardGui, SnippetGui, ClassifierGui, PrioritizerMiniGui, NudgeHudGui, YellowHudGui, ToastHudGui, FindReplaceGui, CivilPromptGui, CivilResultHudGui, WorkflowComposerGui, RunHistoryGui, DateFormatGui
    return SafeIsWindowVisible(PaletteGui)
        || SafeIsWindowVisible(ActionBoardGui)
        || SafeIsWindowVisible(SnippetGui)
        || SafeIsWindowVisible(ClassifierGui)
        || SafeIsWindowVisible(PrioritizerMiniGui)
        || SafeIsWindowVisible(NudgeHudGui)
        || SafeIsWindowVisible(YellowHudGui)
        || SafeIsWindowVisible(ToastHudGui)
        || SafeIsWindowVisible(FindReplaceGui)
        || SafeIsWindowVisible(CivilPromptGui)
        || SafeIsWindowVisible(CivilResultHudGui)
        || SafeIsWindowVisible(WorkflowComposerGui)
        || (IsSet(WcOpenRecipeModalGui) && SafeIsWindowVisible(WcOpenRecipeModalGui))
        || SafeIsWindowVisible(RunHistoryGui)
        || SafeIsWindowVisible(DateFormatGui)
}

CloseAllOfficeUIs() {
    global PaletteGui, ActionBoardGui, SnippetGui, ClassifierGui, PrioritizerMiniGui, NudgeHudGui, YellowHudGui, ToastHudGui, FindReplaceGui, CivilPromptGui, CivilResultHudGui, WorkflowComposerGui, RunHistoryGui, DateFormatGui, WcOpenRecipeModalGui
    
    if IsSet(CloseCommandPalette)
        CloseCommandPalette()
    else if IsObject(PaletteGui)
        PaletteGui.Hide()
        
    if IsObject(ActionBoardGui) {
        try ActionBoardGui.Hide()
    }
    if IsSet(CloseSnippetGui)
        CloseSnippetGui()
    else if IsObject(SnippetGui) {
        try SnippetGui.Destroy()
        SnippetGui := ""
    }
    if IsObject(ClassifierGui) {
        try ClassifierGui.Destroy()
    }
    if IsObject(PrioritizerMiniGui) {
        try PrioritizerMiniGui.Destroy()
    }
    if IsObject(NudgeHudGui) {
        try NudgeHudGui.Destroy()
    }
    if IsObject(YellowHudGui) {
        try YellowHudGui.Destroy()
    }
    if IsObject(ToastHudGui) {
        if IsSet(DismissToastHud)
            DismissToastHud()
        else {
            try ToastHudGui.Destroy()
            ToastHudGui := ""
        }
    }
    if IsObject(FindReplaceGui) {
        try FindReplaceGui.Destroy()
    }
    if IsObject(CivilPromptGui) {
        try CivilPromptGui.Destroy()
        CivilPromptGui := ""
    }
    if IsObject(CivilResultHudGui) {
        try CivilResultHudGui.Destroy()
        CivilResultHudGui := ""
    }
    if IsSet(CloseWorkflowComposer)
        CloseWorkflowComposer()
    else if IsObject(WorkflowComposerGui) {
        try WorkflowComposerGui.Destroy()
        WorkflowComposerGui := ""
    }
    if (IsSet(WcOpenRecipeModalGui) && IsObject(WcOpenRecipeModalGui)) {
        try WcOpenRecipeModalGui.Destroy()
        WcOpenRecipeModalGui := ""
    }
    if IsObject(RunHistoryGui) {
        try RunHistoryGui.Destroy()
        RunHistoryGui := ""
    }
    if IsObject(DateFormatGui) {
        try DateFormatGui.Destroy()
        DateFormatGui := ""
    }
    if IsSet(DismissCursorTooltip)
        DismissCursorTooltip(1)
    else
        ToolTip()
}

ResolveCurrentFilePath() {
    global TargetWindowHwnd
    hwnd := TargetWindowHwnd ? TargetWindowHwnd : WinActive("A")
    
    if (hwnd) {
        try {
            wClass := WinGetClass(hwnd)
            if (wClass = "CabinetWClass" || wClass = "ExploreWClass") {
                shellApp := ComObject("Shell.Application")
                for window in shellApp.Windows {
                    try {
                        if (window && window.HWND = hwnd) {
                            sel := window.Document.SelectedItems
                            if (sel && sel.Count > 0) {
                                res := ""
                                for item in sel
                                    res .= (A_Index > 1 ? "`n" : "") . item.Path
                                if (res != "")
                                    return res
                            }
                            if IsObject(window.Document.Folder) {
                                dirPath := window.Document.Folder.Self.Path
                                if (dirPath != "")
                                    return dirPath
                            }
                        }
                    }
                }
            }
        }
    }
    
    try {
        shellApp := ComObject("Shell.Application")
        for window in shellApp.Windows {
            try {
                if (window && window.Visible && IsObject(window.Document.Folder)) {
                    sel := window.Document.SelectedItems
                    if (sel && sel.Count > 0) {
                        res := ""
                        for item in sel
                            res .= (A_Index > 1 ? "`n" : "") . item.Path
                        if (res != "")
                            return res
                    }
                    dirPath := window.Document.Folder.Self.Path
                    if (dirPath != "")
                        return dirPath
                }
            }
        }
    }
    
    if (hwnd) {
        try {
            wClass := WinGetClass(hwnd)
            if (wClass = "Progman" || wClass = "WorkerW")
                return A_Desktop
        }
    }
    
    sel := SafeGetSelection()
    if (Trim(sel) != "" && (InStr(sel, "\\") || InStr(sel, "/")))
        return Trim(sel)
        
    if (Trim(A_Clipboard) != "" && (InStr(A_Clipboard, "\\") || InStr(A_Clipboard, "/")))
        return Trim(A_Clipboard)
        
    return ""
}

GetActionUsageCount(actName) {
    global TelemetryStatsFile
    try {
        return Integer(IniRead(TelemetryStatsFile, "ToolFrequency", actName, "0"))
    } catch {
        return 0
    }
}

GetTopUsedOfficeActions(maxCount := 5) {
    global BuiltInActions
    ranked := []
    for act in BuiltInActions {
        count := GetActionUsageCount(act.name)
        ranked.Push({act: act, count: count})
    }
    
    loop ranked.Length {
        i := A_Index
        loop ranked.Length - i {
            j := A_Index
            if (ranked[j].count < ranked[j + 1].count) {
                temp := ranked[j]
                ranked[j] := ranked[j + 1]
                ranked[j + 1] := temp
            }
        }
    }
    
    topList := []
    for item in ranked {
        topList.Push(item.act)
        if (topList.Length >= maxCount)
            break
    }
    return topList
}

ShowProductivityHelp() {
    help := "
    (
Office Productivity Command Palette & Snippet Suite
====================================================

PRIMARY ACCESS SHORTCUTS:
- Double-Tap Shift : Universal Command Palette (Search all 50+ tools).
- Ctrl + Space     : Fallback shortcut for Command Palette.
- Win + Shift + ;  : Leader Key mode (tap key chord: d, t, u, c, v, etc.).
- Ctrl + Shift + H : Highlight & Save instant snippet capture.
- Win + Esc        : Snippet & Text Replacement Manager GUI.
- Win + T          : 4-Quadrant Action Board (Eisenhower Matrix).
- Double-Tap Ctrl  : Instant Task / Commitment Capture.
- Shift + F3       : 3-State Case Cycler (lower -> Title -> UPPER).
- Esc              : Instant Dismissal of any active Office UI window.
    )"
    MsgBox(help, AppTitle . " - User Guide", "Iconi")
}

InsertStudyText(txt) => InsertText(txt)
RegisterStudyAction(name, cat, desc, kw, cb, chord := "") => RegisterAction(name, cat, desc, kw, cb, chord)
ShowStudyToast(msg, dur := 1500) => ShowToast(msg, dur)
DismissHUD() => CloseAllOfficeUIs()

