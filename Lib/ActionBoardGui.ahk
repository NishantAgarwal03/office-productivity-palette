; ======================================================================================================================
; Module: ActionBoardGui.ahk - 4-Quadrant Spatial Eisenhower Matrix Board (Color-Coded Label System)
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterActionBoardActions() {
    RegisterAction("Open Action Board (Eisenhower Grid)", "📋 Tasks", "Opens the 4-Quadrant visual matrix board", "task, board, matrix, eisenhower, grid, 4 quadrant, todo", (*) => ToggleActionBoard(), "", "Win+T")
    RegisterAction("Capture Selected Text as Task", "📋 Tasks", "Saves highlighted text as a pending action item", "task, add, new, commitment, capture, todo", (*) => CaptureSelectedTextAsTask(), "", "Ctrl+Shift+T")
    RegisterAction("Export Tasks to CSV / Backup", "📋 Tasks", "Creates a timestamped backup snapshot of tasks.csv", "export, backup, tasks, csv, save, snapshot", (*) => ExportTasksManually())
    RegisterAction("Import Tasks from External CSV", "📋 Tasks", "Imports and merges tasks from any external CSV file", "import, load, tasks, csv, merge, restore", (*) => ImportTasksPrompt())
}

InitActionBoardEngine() {
    InitTaskManager()
    
    OnMessage(0x004E, MatrixOnWmNotify)
    OnMessage(0x0201, ActionBoardOnLButtonDown)
    
    SetTimer(CheckPendingCommitmentClassifier, 7200000)
    SetTimer(CheckPendingPrioritizerMini, 10800000)
    SetTimer(CheckHighPriorityNudges, 1800000)
}

ToggleActionBoard() {
    global ActionBoardGui
    if IsObject(ActionBoardGui) {
        if WinActive(ActionBoardGui.Hwnd) {
            ActionBoardGui.Hide()
            return
        }
        ActionBoardGui.Show()
        RefreshMatrixBoard()
        if IsObject(InputTaskBox)
            InputTaskBox.Focus()
        return
    }
    CreateActionBoardGui()
}

IsActionBoardVisible() {
    global ActionBoardGui
    return IsObject(ActionBoardGui) && WinExist("ahk_id " . ActionBoardGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", ActionBoardGui.Hwnd)
}

CreateActionBoardGui() {
    global ActionBoardGui, InputTaskBox, LV_Q1, LV_Q2, LV_Q3, LV_Q4, PreviewTaskTextCtrl, PreviewMetaCtrl, ActionStatusText, LastActiveLV, Header_Q4
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemePrimary, ThemeSecondary, ThemeBorder
    global ColorQ1, ColorQ2, ColorQ3, ColorQ4
    
    ActionBoardGui := Gui("+AlwaysOnTop -Caption +Border +Owner")
    ActionBoardGui.BackColor := ThemeBg
    ActionBoardGui.SetFont("s10 c" . ThemeText, "Segoe UI")
    
    ActionBoardGui.OnEvent("Escape", (g) => g.Hide())
    
    InputTaskBox := ActionBoardGui.Add("Edit", "x15 y10 w820 h28 c" . ThemeText . " Background" . ThemeSurface . " -E0x200 vTaskInput", "")
    DllCall("user32\SendMessage", "ptr", InputTaskBox.Hwnd, "uint", 0x1501, "ptr", 1, "wstr", "➕ Type a new task and press Enter (or search to filter)...")
    
    ; Q1: DO FIRST (Accent #CE6B40)
    ActionBoardGui.SetFont("s9.5 bold c" . ColorQ1, "Segoe UI")
    ActionBoardGui.Add("Text", "x15 y48 w390", "🔥 Q1: DO FIRST (Urgent && Important)")
    
    ; Q2: SCHEDULE (Muted Gold #D6B656)
    ActionBoardGui.SetFont("s9.5 bold c" . ColorQ2, "Segoe UI")
    ActionBoardGui.Add("Text", "x445 y48 w390", "📅 Q2: SCHEDULE (Important, Not Urgent)")
    
    ActionBoardGui.SetFont("s9.5 c" . ThemeText, "Segoe UI")
    LV_Q1 := ActionBoardGui.AddListView("x15 y70 w390 h148 Background" . ThemeSurface . " c" . ColorQ1 . " -Hdr -Multi +Report -Theme +LV0x10000", ["Display", "ID"])
    LV_Q2 := ActionBoardGui.AddListView("x445 y70 w390 h148 Background" . ThemeSurface . " c" . ColorQ2 . " -Hdr -Multi +Report -Theme +LV0x10000", ["Display", "ID"])
    
    ; Q3: QUICK WIN (Muted Blue #5F8FA8)
    ActionBoardGui.SetFont("s9.5 bold c" . ColorQ3, "Segoe UI")
    ActionBoardGui.Add("Text", "x15 y226 w390", "⚡ Q3: QUICK WIN (<5m / Delegate)")
    
    ; Q4: BACKLOG (Muted #98A9B3)
    ActionBoardGui.SetFont("s9.5 bold c" . ColorQ4, "Segoe UI")
    Header_Q4 := ActionBoardGui.Add("Text", "x445 y226 w390", "⏳ Q4: BACKLOG / LATER (Low Priority)")
    
    ActionBoardGui.SetFont("s9.5 c" . ThemeText, "Segoe UI")
    LV_Q3 := ActionBoardGui.AddListView("x15 y248 w390 h148 Background" . ThemeSurface . " c" . ColorQ3 . " -Hdr -Multi +Report -Theme +LV0x10000", ["Display", "ID"])
    LV_Q4 := ActionBoardGui.AddListView("x445 y248 w390 h148 Background" . ThemeSurface . " c" . ColorQ4 . " -Hdr -Multi +Report -Theme +LV0x10000", ["Display", "ID"])
    
    LV_Q1.OnEvent("ItemSelect", (ctrl, item, selected) => OnTaskItemSelect(LV_Q1, item, selected))
    LV_Q2.OnEvent("ItemSelect", (ctrl, item, selected) => OnTaskItemSelect(LV_Q2, item, selected))
    LV_Q3.OnEvent("ItemSelect", (ctrl, item, selected) => OnTaskItemSelect(LV_Q3, item, selected))
    LV_Q4.OnEvent("ItemSelect", (ctrl, item, selected) => OnTaskItemSelect(LV_Q4, item, selected))
    
    LV_Q1.OnEvent("Click", (ctrl, *) => ctrl.Focus())
    LV_Q2.OnEvent("Click", (ctrl, *) => ctrl.Focus())
    LV_Q3.OnEvent("Click", (ctrl, *) => ctrl.Focus())
    LV_Q4.OnEvent("Click", (ctrl, *) => ctrl.Focus())

    LV_Q1.OnEvent("DoubleClick", (*) => MatrixViewOrToggle(LV_Q1))
    LV_Q2.OnEvent("DoubleClick", (*) => MatrixViewOrToggle(LV_Q2))
    LV_Q3.OnEvent("DoubleClick", (*) => MatrixViewOrToggle(LV_Q3))
    LV_Q4.OnEvent("DoubleClick", (*) => MatrixViewOrToggle(LV_Q4))
    
    ActionBoardGui.SetFont("s9 c" . ThemeText, "Segoe UI")
    PreviewTaskTextCtrl := ActionBoardGui.Add("Edit", "x15 y404 w820 h26 ReadOnly Background" . ThemeSurface . " c" . ThemeText . " -E0x200 -Wrap", "Select any task above to view its continuous text...")
    
    ActionBoardGui.SetFont("s9 bold c" . ThemeMuted, "Segoe UI")
    PreviewMetaCtrl := ActionBoardGui.Add("Text", "x15 y434 w820 h18 c" . ThemeMuted, "[Status: Ready  |  Quadrant: -  |  Created: -]")
    
    ActionBoardGui.SetFont("s8.5 c" . ThemeMuted, "Segoe UI")
    ActionStatusText := ActionBoardGui.Add("Text", "x15 y458 w820 h18", "[Enter] Add Task  •  [1-4] Move Quadrant  •  [Space] Toggle Done  •  [V] Full Editor  •  [Del] Delete  •  [Esc] Close")
    
    CenterGuiOnActiveMonitor(ActionBoardGui, 850, 485)
    ActionBoardGui.Show("w850 h485")
    RefreshMatrixBoard()
    if IsObject(InputTaskBox)
        InputTaskBox.Focus()
}

RefreshMatrixBoard(filter := "") {
    global LV_Q1, LV_Q2, LV_Q3, LV_Q4, ActionTasks, Header_Q4
    if !IsObject(LV_Q1) || !IsObject(LV_Q2) || !IsObject(LV_Q3) || !IsObject(LV_Q4)
        return
        
    LV_Q1.Delete()
    LV_Q2.Delete()
    LV_Q3.Delete()
    LV_Q4.Delete()
    
    fLower := StrLower(Trim(filter))
    q4Untriaged := []
    q4Triaged := []
    
    for t in ActionTasks {
        if (fLower != "" && !InStr(StrLower(t.task), fLower) && !InStr(StrLower(t.commitmentType), fLower))
            continue
            
        cleanText := RegExReplace(t.task, "[\r\n]+", " ")
        cleanText := RegExReplace(cleanText, "\s*\([A-Za-z\s]+#[0-9A-Fa-f]{6}\)", "")
        statusPrefix := t.done ? "✔ " : "○ "
        typeBadge := (t.commitmentType != "" && t.commitmentType != "Unassigned" && t.commitmentType != "Task") ? ("[" . t.commitmentType . "] ") : ""
        
        if (t.priority = "Q1") {
            LV_Q1.Add("", statusPrefix . typeBadge . cleanText, String(t.id))
        } else if (t.priority = "Q2") {
            LV_Q2.Add("", statusPrefix . typeBadge . cleanText, String(t.id))
        } else if (t.priority = "Q3") {
            LV_Q3.Add("", statusPrefix . typeBadge . cleanText, String(t.id))
        } else {
            ; Q4: Distinguish untriaged inbox from triaged backlog
            if IsTaskUntriaged(t)
                q4Untriaged.Push({task: t, clean: cleanText})
            else
                q4Triaged.Push({task: t, clean: cleanText, prefix: statusPrefix, badge: typeBadge})
        }
    }
    
    ; Render Untriaged Inbox items at the top of Q4
    for item in q4Untriaged {
        LV_Q4.Add("", "📥[INBOX] " . item.clean, String(item.task.id))
;        LV_Q4.Add("", "[📥]" . item.clean, String(item.task.id))

    }
    
    ; Render Triaged Q4 items below
    for item in q4Triaged {
        LV_Q4.Add("", item.prefix . item.badge . item.clean, String(item.task.id))
    }
    
    ; Update Q4 Header with Untriaged counter
    if IsObject(Header_Q4) {
        untriagedCount := q4Untriaged.Length
        Header_Q4.Value := (untriagedCount > 0)
            ? ("⏳ Q4: BACKLOG  •  📥 " . untriagedCount . " to Triage")
            : "⏳ Q4: BACKLOG / LATER (Low Priority)"
    }
    
    try {
        LV_Q1.ModifyCol(1, 380)
        LV_Q2.ModifyCol(1, 380)
        LV_Q3.ModifyCol(1, 380)
        LV_Q4.ModifyCol(1, 380)
        LV_Q1.ModifyCol(2, 0)
        LV_Q2.ModifyCol(2, 0)
        LV_Q3.ModifyCol(2, 0)
        LV_Q4.ModifyCol(2, 0)
    }
}

OnTaskItemSelect(lvCtrl, itemIndex, isSelected) {
    global LastActiveLV, PreviewTaskTextCtrl, PreviewMetaCtrl, ActionTasks
    if !isSelected
        return
        
    lvCtrl.Focus()
    LastActiveLV := lvCtrl
    taskId := Integer(lvCtrl.GetText(itemIndex, 2))
    
    for t in ActionTasks {
        if (t.id = taskId) {
            PreviewTaskTextCtrl.Value := t.task
            isUntriaged := IsTaskUntriaged(t)
            stat := t.done ? "Completed" : (isUntriaged ? "📥 Untriaged (Inbox)" : "Pending")
            typeStr := isUntriaged ? "Unassigned (Needs Triage)" : (t.commitmentType ? t.commitmentType : "General Task")
            PreviewMetaCtrl.Text := Format("[Status: {}  |  Quadrant: {}  |  Type: {}  |  Created: {}]", stat, t.priority, typeStr, t.created)
            break
        }
    }
}

MatrixOnWmNotify(wParam, lParam, msg, hwnd) {
    global LV_Q1, LV_Q2, LV_Q3, LV_Q4, ThemeSurface, ThemeText, ColorQ1, ColorQ2, ColorQ3, ColorQ4
    static NM_CUSTOMDRAW := -12
    static CDDS_PREPAINT := 0x00000001
    static CDDS_ITEMPREPAINT := 0x00010001
    static CDRF_NOTIFYITEMDRAW := 0x00000020
    static CDRF_DODEFAULT := 0x00000000
    
    code := NumGet(lParam, A_PtrSize * 2, "Int")
    if (code = NM_CUSTOMDRAW) {
        ctlHwnd := NumGet(lParam, 0, "UPtr")
        
        isQ1 := (IsObject(LV_Q1) && ctlHwnd = LV_Q1.Hwnd)
        isQ2 := (IsObject(LV_Q2) && ctlHwnd = LV_Q2.Hwnd)
        isQ3 := (IsObject(LV_Q3) && ctlHwnd = LV_Q3.Hwnd)
        isQ4 := (IsObject(LV_Q4) && ctlHwnd = LV_Q4.Hwnd)
        
        if (isQ1 || isQ2 || isQ3 || isQ4) {
            drawStage := NumGet(lParam, A_PtrSize * 3, "UInt")
            if (drawStage = CDDS_PREPAINT)
                return CDRF_NOTIFYITEMDRAW
                
            if (drawStage = CDDS_ITEMPREPAINT) {
                clrOffset := (A_PtrSize == 8) ? 80 : 48
                clrBkOffset := (A_PtrSize == 8) ? 84 : 52
                
                clrTextBk := HexToBGR(ThemeSurface)
                
                ; Quadrant specific label text colors dynamically converted to BGR format
                if isQ1
                    clrText := HexToBGR(ColorQ1)
                else if isQ2
                    clrText := HexToBGR(ColorQ2)
                else if isQ3
                    clrText := HexToBGR(ColorQ3)
                else {
                    ; In Q4: untriaged Inbox items render in crisp bright white, confirmed backlog in soft grey
                    rowIdx := NumGet(lParam, (A_PtrSize == 8) ? 56 : 36, "UPtr") + 1
                    rowText := (rowIdx > 0 && IsObject(LV_Q4)) ? LV_Q4.GetText(rowIdx, 1) : ""
                    if InStr(rowText, "[INBOX]")
                        clrText := HexToBGR(ThemeText) ; Crisp bright white (#F8FAFC)
                    else
                        clrText := HexToBGR(ColorQ4) ; Soft Slate Grey (#98A9B3)
                }
                
                NumPut("UInt", clrText, lParam, clrOffset)
                NumPut("UInt", clrTextBk, lParam, clrBkOffset)
                return CDRF_DODEFAULT
            }
        }
    }
}

ActionBoardOnLButtonDown(wParam, lParam, msg, hwnd) {
    global ActionBoardGui
    if IsObject(ActionBoardGui) && hwnd = ActionBoardGui.Hwnd {
        PostMessage(0xA1, 2,,, "ahk_id " . ActionBoardGui.Hwnd) ; WM_NCLBUTTONDOWN -> HTCAPTION
    }
}

MatrixViewOrToggle(lvCtrl) {
    row := lvCtrl.GetNext()
    if (row <= 0)
        return
    taskId := Integer(lvCtrl.GetText(row, 2))
    ToggleTaskDone(taskId)
    RefreshMatrixBoard()
}

MatrixMoveSelectedTask(newQuadrant) {
    global LastActiveLV, ActionTasks
    if !IsObject(LastActiveLV)
        return
    row := LastActiveLV.GetNext()
    if (row <= 0)
        return
    taskId := Integer(LastActiveLV.GetText(row, 2))
    for t in ActionTasks {
        if (t.id = taskId) {
            t.priority := newQuadrant
            if (t.commitmentType = "Unassigned" || t.commitmentType = "Task" || t.commitmentType = "") {
                t.commitmentType := (newQuadrant = "Q4") ? "Backlog" : "Task"
            }
            SaveActionTasks()
            RefreshMatrixBoard()
            ShowToast("✔ Moved to " . newQuadrant, 1200)
            break
        }
    }
}

MatrixToggleDone() {
    global LastActiveLV
    if !IsObject(LastActiveLV)
        return
    row := LastActiveLV.GetNext()
    if (row <= 0)
        return
    taskId := Integer(LastActiveLV.GetText(row, 2))
    ToggleTaskDone(taskId)
    RefreshMatrixBoard()
}

MatrixDeleteSelectedTask() {
    global LastActiveLV
    if !IsObject(LastActiveLV)
        return
    row := LastActiveLV.GetNext()
    if (row <= 0)
        return
    taskId := Integer(LastActiveLV.GetText(row, 2))
    DeleteTaskById(taskId)
    RefreshMatrixBoard()
    ShowToast("🗑️ Task Deleted", 1200)
}

HandleMatrixEnterKey() {
    global InputTaskBox, ActionTasks
    if !IsObject(InputTaskBox)
        return
    raw := Trim(InputTaskBox.Value)
    if (raw = "")
        return
    
    AddTask(raw, "Q4", "Unassigned")
    InputTaskBox.Value := ""
    RefreshMatrixBoard()
    ShowToast("📥 Task Added to Inbox (Q4)", 1200)
}

ShowFullTaskViewModal() {
    global LastActiveLV, ActionTasks, ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent
    if !IsObject(LastActiveLV)
        return
    row := LastActiveLV.GetNext()
    if (row <= 0)
        return
        
    taskId := Integer(LastActiveLV.GetText(row, 2))
    taskObj := ""
    for t in ActionTasks {
        if (t.id = taskId) {
            taskObj := t
            break
        }
    }
    if !IsObject(taskObj)
        return
        
    editorModal := Gui("+Owner" . ActionBoardGui.Hwnd . " +ToolWindow -Caption +Border")
    editorModal.BackColor := ThemeBg
    editorModal.SetFont("s10 bold c" . ThemeAccent, "Segoe UI")
    editorModal.Add("Text", "x15 y12 w570", "📝 Edit Task Details")
    
    editorModal.SetFont("s10 norm c" . ThemeText, "Segoe UI")
    editCtrl := editorModal.Add("Edit", "x15 y38 w570 h180 Background" . ThemeSurface . " c" . ThemeText . " -E0x200", taskObj.task)
    
    editorModal.SetFont("s9 bold c" . ThemeMuted, "Segoe UI")
    editorModal.Add("Text", "x15 y230 w80", "Quadrant:")
    prioDDL := editorModal.Add("DropDownList", "x95 y226 w100 Background" . ThemeSurface . " c" . ThemeText, ["Q1", "Q2", "Q3", "Q4"])
    prioDDL.Choose((taskObj.priority = "Q1") ? 1 : (taskObj.priority = "Q2") ? 2 : (taskObj.priority = "Q3") ? 3 : 4)
    
    editorModal.Add("Text", "x220 y230 w60", "Type:")
    typeDDL := editorModal.Add("DropDownList", "x270 y226 w120 Background" . ThemeSurface . " c" . ThemeText, ["Deliverable", "Promise", "Deadline", "Follow-Up", "Review", "Quick", "Task"])
    typeChoice := 7
    for idx, opt in ["Deliverable", "Promise", "Deadline", "Follow-Up", "Review", "Quick", "Task"] {
        if (opt = taskObj.commitmentType) {
            typeChoice := idx
            break
        }
    }
    typeDDL.Choose(typeChoice)
    
    chkDone := editorModal.Add("CheckBox", "x410 y228 w100 c" . ThemeText . (taskObj.done ? " Checked" : ""), "Completed")
    
    btnSave := editorModal.Add("Button", "x410 y265 w85 h30 Default", "Save")
    btnSave.OnEvent("Click", (*) => SaveTaskEdit(editorModal, taskObj, editCtrl.Value, prioDDL.Text, typeDDL.Text, chkDone.Value))
    
    btnCancel := editorModal.Add("Button", "x505 y265 w80 h30", "Cancel")
    btnCancel.OnEvent("Click", (*) => editorModal.Destroy())
    
    editorModal.OnEvent("Escape", (g) => g.Destroy())
    CenterGuiOnActiveMonitor(editorModal, 600, 310)
    editorModal.Show("w600 h310")
}

SaveTaskEdit(modalGui, taskObj, newText, newPrio, newType, isDone) {
    taskObj.task := Trim(newText)
    taskObj.priority := newPrio
    taskObj.commitmentType := newType
    taskObj.done := isDone
    SaveActionTasks()
    modalGui.Destroy()
    RefreshMatrixBoard()
    ShowToast("✔ Task Updated", 1200)
}

IsActionBoardActive() {
    global ActionBoardGui
    return IsObject(ActionBoardGui) && WinActive("ahk_id " . ActionBoardGui.Hwnd)
}

IsInputTaskBoxFocused() {
    global InputTaskBox
    return IsObject(InputTaskBox) && WinActive("ahk_id " . InputTaskBox.Gui.Hwnd) && (InputTaskBox.Hwnd = ControlGetFocus(InputTaskBox.Gui.Hwnd))
}
