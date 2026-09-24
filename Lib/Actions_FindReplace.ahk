; ======================================================================================================================
; Module: Actions_FindReplace.ahk - In-Selection Find & Replace GUI (F12)
; ======================================================================================================================

global StudyFindReplaceGui := ""

RegisterFindReplaceActions() {
    RegisterStudyAction("Find & Replace in Selection", "🔍 Search/Replace", "Opens GUI to perform search-and-replace exclusively inside selected text", "find, replace, selection, search, f12", (*) => ShowFindReplaceModal(), "F12")
}

ShowFindReplaceModal(providedSel := "", targetWinId := 0) {
    global StudyFindReplaceGui
    DismissHUD()
    
    if (targetWinId == 0)
        targetWinId := WinExist("A")
        
    static lastFind := ""
    static lastReplace := ""
    
    sel := (providedSel != "") ? providedSel : SafeGetSelection(0.4)
    if (Trim(sel) == "") {
        ShowStudyToast("⚠️ Please select text first before pressing Find & Replace", 2000)
        return
    }
    
    if IsObject(StudyFindReplaceGui) {
        try StudyFindReplaceGui.Destroy()
    }
    
    StudyFindReplaceGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "Replace in Selection")
    StudyFindReplaceGui.BackColor := "181818"
    StudyFindReplaceGui.SetFont("s10 bold cFFFFFF", "Segoe UI")
    
    StudyFindReplaceGui.Add("Text", "x15 y12 w270 cFFFFFF", "🔍 Replace in Highlighted Selection")
    StudyFindReplaceGui.SetFont("s9 norm cAAAAAA", "Segoe UI")
    StudyFindReplaceGui.Add("Text", "x15 y36 w270", "Find text:")
    findEdit := StudyFindReplaceGui.Add("Edit", "x15 y56 w290 h26 Background222222 cFFFFFF -E0x200", lastFind)
    
    StudyFindReplaceGui.Add("Text", "x15 y90 w270 cAAAAAA", "Replace with:")
    replaceEdit := StudyFindReplaceGui.Add("Edit", "x15 y110 w290 h26 Background222222 cFFFFFF -E0x200", lastReplace)
    
    StudyFindReplaceGui.SetFont("s9 bold cFFFFFF", "Segoe UI")
    btnOk := StudyFindReplaceGui.AddButton("x15 y150 w140 h32 Default", "✔ Replace")
    StudyFindReplaceGui.SetFont("s9 norm cFFFFFF", "Segoe UI")
    btnCancel := StudyFindReplaceGui.AddButton("x165 y150 w140 h32", "Cancel")
    
    btnOk.OnEvent("Click", (*) => ExecuteFindReplace(StudyFindReplaceGui, targetWinId, sel, findEdit.Value, replaceEdit.Value))
    btnCancel.OnEvent("Click", (*) => (StudyFindReplaceGui.Destroy(), StudyFindReplaceGui := ""))
    StudyFindReplaceGui.OnEvent("Escape", (g) => (g.Destroy(), StudyFindReplaceGui := ""))
    StudyFindReplaceGui.OnEvent("Close", (g) => (g.Destroy(), StudyFindReplaceGui := ""))
    
    StudyFindReplaceGui.Show("w320 h196")
}

ExecuteFindReplace(guiObj, targetWinId, originalSelText, findStr, replaceStr) {
    global StudyFindReplaceGui
    if (findStr == "") {
        ShowStudyToast("⚠️ Find string cannot be empty", 1500)
        return
    }
    
    if IsObject(guiObj) {
        guiObj.Destroy()
        StudyFindReplaceGui := ""
    }
    
    if (targetWinId && WinExist("ahk_id " . targetWinId)) {
        WinActivate("ahk_id " . targetWinId)
        Sleep(60)
    }
    
    newText := StrReplace(originalSelText, findStr, replaceStr)
    InsertStudyText(newText)
    ShowStudyToast("✔ Replaced all occurrences in selection!", 1500)
}

IsFindReplaceActive() {
    global StudyFindReplaceGui
    return IsObject(StudyFindReplaceGui) && WinActive(StudyFindReplaceGui.Hwnd)
}
