; ======================================================================================================================
; Module: ActionBoardPills.ahk - Mini Floating Classifier, Prioritizer & Urgent Nudge HUDs (Unified Dark Theme)
; ======================================================================================================================

#Requires AutoHotkey v2.0

CheckPendingCommitmentClassifier() {
    global ActionTasks, LastClassifiedTime, ClassifierGui
    if IsObject(ClassifierGui)
        return
    if (A_TickCount - LastClassifiedTime < 600000)
        return
    for t in ActionTasks {
        if IsTaskUntriaged(t) {
            ShowCommitmentClassifierMiniUI(t)
            break
        }
    }
}

ShowCommitmentClassifierMiniUI(taskObj) {
    global ClassifierGui, LastClassifiedTime, ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemePrimary, ThemeSecondary, ThemeAccent
    if IsObject(ClassifierGui)
        ClassifierGui.Destroy()
        
    ClassifierGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    ClassifierGui.BackColor := ThemeBg
    ClassifierGui.OnEvent("Escape", (g) => DismissClassifier(g))
    
    cleanTask := RegExReplace(taskObj.task, "[\r\n]+", " ")
    cleanTask := RegExReplace(cleanTask, "[ \t]+", " ")
    cleanTask := RegExReplace(cleanTask, "\s*\([A-Za-z\s]+#[0-9A-Fa-f]{6}\)", "")
    prev := StrLen(cleanTask) > 250 ? SubStr(cleanTask, 1, 247) . "..." : cleanTask
    
    isSingleLine := (StrLen(prev) <= 36)
    textH := isSingleLine ? 22 : 40
    btnY1 := isSingleLine ? 38 : 56
    btnY2 := isSingleLine ? 84 : 102
    guiH  := isSingleLine ? 132 : 150
    
    ClassifierGui.SetFont("s10.5 bold c" . ThemeText, "Segoe UI")
    ClassifierGui.Add("Text", "x12 y10 w346 h" . textH, "📋 " . prev)
    
    ; Unified dark surface tiles with distinct accent text/icons (zero text on solid primary/accent fills)
    CreateClassifierTile(ClassifierGui, 12, btnY1, 110, 40, "📦", "1 Deliver", ThemeSurface, "c" . ThemePrimary, (*) => FastSetType(ClassifierGui, taskObj, "Deliverable"))
    CreateClassifierTile(ClassifierGui, 130, btnY1, 110, 40, "🤝", "2 Promise", ThemeSurface, "c" . ThemeSecondary, (*) => FastSetType(ClassifierGui, taskObj, "Promise"))
    CreateClassifierTile(ClassifierGui, 248, btnY1, 110, 40, "⏰", "3 Due", ThemeSurface, "c" . ThemeMuted, (*) => FastSetType(ClassifierGui, taskObj, "Deadline"))
    
    CreateClassifierTile(ClassifierGui, 12, btnY2, 110, 40, "🔄", "4 Follow", ThemeSurface, "c" . ThemeSecondary, (*) => FastSetType(ClassifierGui, taskObj, "Follow-Up"))
    CreateClassifierTile(ClassifierGui, 130, btnY2, 110, 40, "🔍", "5 Review", ThemeSurface, "c" . ThemePrimary, (*) => FastSetType(ClassifierGui, taskObj, "Review"))
    CreateClassifierTile(ClassifierGui, 248, btnY2, 110, 40, "⚡", "6 Quick", ThemeSurface, "c" . ThemeMuted, (*) => FastSetType(ClassifierGui, taskObj, "Quick"))
    
    MonitorGetWorkArea(1, &mL, &mT, &mR, &mB)
    posX := mL + 25
    posY := mT + 25
    ClassifierGui.Show("x" . posX . " y" . posY . " w370 h" . guiH . " NoActivate")
    
    SetTimer(() => DismissClassifier(ClassifierGui), -10000)
}

CreateClassifierTile(gui, x, y, w, h, icon, label, bgHex, textClr, callback) {
    bg := gui.Add("Text", "x" . x . " y" . y . " w" . w . " h" . h . " Background" . bgHex . " +Border", "")
    bg.OnEvent("Click", callback)
    
    gui.SetFont("s13.5 bold " . textClr, "Segoe UI Emoji")
    iCtrl := gui.Add("Text", "x" . x . " y" . (y + 3) . " w" . w . " h20 Center BackgroundTrans " . textClr . " 0x200", icon)
    iCtrl.OnEvent("Click", callback)
    
    gui.SetFont("s8 bold " . textClr, "Segoe UI")
    lCtrl := gui.Add("Text", "x" . x . " y" . (y + 22) . " w" . w . " h15 Center BackgroundTrans " . textClr, label)
    lCtrl.OnEvent("Click", callback)
}

FastSetType(guiObj, taskObj, typeName) {
    global LastClassifiedTime
    taskObj.commitmentType := typeName
    SaveActionTasks()
    LastClassifiedTime := A_TickCount
    if IsObject(guiObj)
        guiObj.Destroy()
    if IsSet(RefreshMatrixBoard) && IsObject(ActionBoardGui)
        RefreshMatrixBoard()
    ShowToast("✔ " . typeName, 1000)
}

DismissClassifier(guiObj) {
    global LastClassifiedTime
    LastClassifiedTime := A_TickCount
    if IsObject(guiObj) {
        try guiObj.Destroy()
    }
}

IsClassifierVisible() {
    global ClassifierGui
    return IsObject(ClassifierGui) && WinExist("ahk_id " . ClassifierGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", ClassifierGui.Hwnd)
}

CheckPendingPrioritizerMini() {
    global ActionTasks, LastPrioritizedTime, PrioritizerMiniGui
    if IsObject(PrioritizerMiniGui)
        return
    if (A_TickCount - LastPrioritizedTime < 3600000)
        return
    for t in ActionTasks {
        if (!t.done && t.priority = "Q4" && t.commitmentType != "" && t.commitmentType != "Unassigned" && t.commitmentType != "Task" && t.commitmentType != "Backlog") {
            ShowPrioritizerMiniUI(t)
            break
        }
    }
}

ShowPrioritizerMiniUI(taskObj) {
    global PrioritizerMiniGui, LastPrioritizedTime, ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemePrimary, ThemeSecondary, ThemeAccent
    global ColorQ1, ColorQ2, ColorQ3, ColorQ4
    if IsObject(PrioritizerMiniGui)
        PrioritizerMiniGui.Destroy()
        
    PrioritizerMiniGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    PrioritizerMiniGui.BackColor := ThemeBg
    PrioritizerMiniGui.OnEvent("Escape", (g) => DismissPrioritizerMini(g))
    
    cleanTask := RegExReplace(taskObj.task, "[\r\n]+", " ")
    cleanTask := RegExReplace(cleanTask, "[ \t]+", " ")
    cleanTask := RegExReplace(cleanTask, "\s*\([A-Za-z\s]+#[0-9A-Fa-f]{6}\)", "")
    prev := StrLen(cleanTask) > 250 ? SubStr(cleanTask, 1, 247) . "..." : cleanTask
    
    isSingleLine := (StrLen(prev) <= 32)
    textH := isSingleLine ? 22 : 40
    btnY1 := isSingleLine ? 38 : 56
    btnY2 := isSingleLine ? 84 : 102
    guiH  := isSingleLine ? 132 : 150
    
    typeBadge := "[" . taskObj.commitmentType . "]"
    PrioritizerMiniGui.SetFont("s10.5 bold c" . ThemeText, "Segoe UI")
    PrioritizerMiniGui.Add("Text", "x12 y10 w346 h" . textH, "🎯 " . typeBadge . " " . prev)
    
    CreatePrioritizerTile(PrioritizerMiniGui, 12, btnY1, 168, 40, "🔥", "1 DO FIRST", ThemeSurface, "c" . ColorQ1, (*) => FastSetPrioMini(PrioritizerMiniGui, taskObj, "Q1"))
    CreatePrioritizerTile(PrioritizerMiniGui, 190, btnY1, 168, 40, "📅", "2 SCHEDULE", ThemeSurface, "c" . ColorQ2, (*) => FastSetPrioMini(PrioritizerMiniGui, taskObj, "Q2"))
    
    CreatePrioritizerTile(PrioritizerMiniGui, 12, btnY2, 168, 40, "⚡", "3 QUICK WIN", ThemeSurface, "c" . ColorQ3, (*) => FastSetPrioMini(PrioritizerMiniGui, taskObj, "Q3"))
    CreatePrioritizerTile(PrioritizerMiniGui, 190, btnY2, 168, 40, "⏳", "4 BACKLOG", ThemeSurface, "c" . ColorQ4, (*) => FastSetPrioMini(PrioritizerMiniGui, taskObj, "Q4"))
    
    MonitorGetWorkArea(1, &mL, &mT, &mR, &mB)
    posX := mL + 25
    posY := mT + 25
    PrioritizerMiniGui.Show("x" . posX . " y" . posY . " w370 h" . guiH . " NoActivate")
    
    SetTimer(() => DismissPrioritizerMini(PrioritizerMiniGui), -10000)
}

CreatePrioritizerTile(gui, x, y, w, h, icon, label, bgHex, textClr, callback) {
    bg := gui.Add("Text", "x" . x . " y" . y . " w" . w . " h" . h . " Background" . bgHex . " +Border", "")
    bg.OnEvent("Click", callback)
    
    gui.SetFont("s13.5 bold " . textClr, "Segoe UI Emoji")
    iCtrl := gui.Add("Text", "x" . x . " y" . (y + 3) . " w" . w . " h20 Center BackgroundTrans " . textClr . " 0x200", icon)
    iCtrl.OnEvent("Click", callback)
    
    gui.SetFont("s8.5 bold " . textClr, "Segoe UI")
    lCtrl := gui.Add("Text", "x" . x . " y" . (y + 22) . " w" . w . " h15 Center BackgroundTrans " . textClr, label)
    lCtrl.OnEvent("Click", callback)
}

FastSetPrioMini(guiObj, taskObj, prioName) {
    global LastPrioritizedTime
    taskObj.priority := prioName
    if (taskObj.commitmentType = "Unassigned" || taskObj.commitmentType = "Task" || taskObj.commitmentType = "") {
        taskObj.commitmentType := (prioName = "Q4") ? "Backlog" : "Task"
    }
    SaveActionTasks()
    LastPrioritizedTime := A_TickCount
    if IsObject(guiObj)
        guiObj.Destroy()
    if IsSet(RefreshMatrixBoard) && IsObject(ActionBoardGui)
        RefreshMatrixBoard()
    ShowToast("✔ Moved to " . prioName, 1000)
}

DismissPrioritizerMini(guiObj) {
    global LastPrioritizedTime
    LastPrioritizedTime := A_TickCount
    if IsObject(guiObj) {
        try guiObj.Destroy()
    }
}

IsPrioritizerMiniVisible() {
    global PrioritizerMiniGui
    return IsObject(PrioritizerMiniGui) && WinExist("ahk_id " . PrioritizerMiniGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", PrioritizerMiniGui.Hwnd)
}

CheckHighPriorityNudges() {
    global ActionTasks, NudgeHudGui, ThemeSurface, ThemeBorder, ThemeText, ThemeMuted, ThemeAccent
    highTasks := []
    for t in ActionTasks {
        if (!t.done && t.priority = "Q1")
            highTasks.Push(t)
    }
    
    if (highTasks.Length = 0)
        return
        
    if IsObject(NudgeHudGui)
        NudgeHudGui.Destroy()
        
    NudgeHudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    NudgeHudGui.BackColor := ThemeSurface
    
    NudgeHudGui.SetFont("s8.5 bold c" . ThemeAccent, "Segoe UI")
    NudgeHudGui.Add("Text", "x14 y8 w430 h16", "🔥 Q1 URGENT (" . highTasks.Length . " Active)")
    
    NudgeHudGui.SetFont("s11 bold c" . ThemeText, "Segoe UI")
    item1Text := "1. " . (StrLen(highTasks[1].task) > 42 ? SubStr(highTasks[1].task, 1, 39) . "..." : highTasks[1].task)
    NudgeHudGui.Add("Text", "x14 y26 w430 h24", item1Text)
    
    hudWidth := 460
    hudHeight := 58
    if (highTasks.Length >= 2) {
        item2Text := "2. " . (StrLen(highTasks[2].task) > 42 ? SubStr(highTasks[2].task, 1, 39) . "..." : highTasks[2].task)
        NudgeHudGui.Add("Text", "x14 y52 w430 h24", item2Text)
        hudHeight := 84
    }
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&curX, &curY)
    
    offsetDist := 260
    posX := curX + offsetDist
    posY := curY - 40
    
    monIdx := 1
    try {
        monCount := MonitorGetCount()
        loop monCount {
            MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
            if (curX >= mLeft && curX <= mRight && curY >= mTop && curY <= mBottom) {
                monIdx := A_Index
                break
            }
        }
    }
    MonitorGetWorkArea(monIdx, &mL, &mT, &mR, &mB)
    
    if (posX + hudWidth > mR - 20)
        posX := curX - offsetDist - hudWidth
    if (posX < mL + 20)
        posX := mL + 20
        
    if (posY + hudHeight > mB - 20)
        posY := mB - hudHeight - 20
    if (posY < mT + 20)
        posY := mT + 20
        
    NudgeHudGui.Show("x" . posX . " y" . posY . " w" . hudWidth . " h" . hudHeight . " NoActivate")
    SetTimer(() => DismissNudgeHud(NudgeHudGui), -2500)
}

DismissNudgeHud(guiObj) {
    if IsObject(guiObj) {
        try guiObj.Destroy()
    }
}

IsNudgeHudVisible() {
    global NudgeHudGui
    return IsObject(NudgeHudGui) && WinExist("ahk_id " . NudgeHudGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", NudgeHudGui.Hwnd)
}
