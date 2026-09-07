; ======================================================================================================================
; Module: RunHistoryGui.ahk - Workflow Run History & Diagnostics Inspector
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; DESIGN & UX:
; 1. Unified Dark Mode Theme: Strict adherence to #0A0D10, #182025, #F8FAFC, #7B909D, #CE6B40 tokens.
; 2. Global Esc Dismissal: Closes immediately on Esc key.
; 3. Inspection & Replay: Detailed per-step snapshot inspector and 1-click rerun capability.
; ======================================================================================================================

#Requires AutoHotkey v2.0

global RunHistoryGui := ""
global HistoryListView := ""
global HistoryRunsList := []

ShowRunHistoryGui() {
    global RunHistoryGui, HistoryListView, HistoryRunsList
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeBorder, ThemePrimary, ThemeAccent

    if IsObject(RunHistoryGui) {
        try RunHistoryGui.Destroy()
        RunHistoryGui := ""
    }

    RunHistoryGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner", "Workflow Run History & Diagnostics")
    RunHistoryGui.BackColor := ThemeBg
    RunHistoryGui.SetFont("s10 c" . ThemeText, "Segoe UI")

    ; Title Header
    RunHistoryGui.Add("Text", "x20 y16 w600 h24 c" . ThemeAccent . " +0x200", "⚡ Workflow Execution History & Snapshot Ledger")
    RunHistoryGui.SetFont("s9 c" . ThemeMuted)
    RunHistoryGui.Add("Text", "x20 y42 w700 h20", "Inspect complete step-by-step snapshots, rerun previous inputs, or copy outputs.")

    ; ListView
    RunHistoryGui.SetFont("s9 c" . ThemeText)
    HistoryListView := RunHistoryGui.Add("ListView", "x20 y70 w840 h360 Background" . ThemeSurface . " c" . ThemeText . " Grid -Multi", 
                                        ["Status", "Timestamp", "Recipe Name", "Duration", "Input Preview", "Output Preview"])
    HistoryListView.ModifyCol(1, "55 Center")
    HistoryListView.ModifyCol(2, 135)
    HistoryListView.ModifyCol(3, 180)
    HistoryListView.ModifyCol(4, "75 Right")
    HistoryListView.ModifyCol(5, 195)
    HistoryListView.ModifyCol(6, 180)

    ; Bottom Buttons
    RunHistoryGui.SetFont("s9 Bold")
    btnInspect := RunHistoryGui.Add("Button", "x20 y445 w130 h32", "🔍 Inspect Step")
    btnInspect.OnEvent("Click", (*) => HistoryInspectSelected())

    btnRerun := RunHistoryGui.Add("Button", "x160 y445 w140 h32", "▶ Rerun with Input")
    btnRerun.OnEvent("Click", (*) => HistoryRerunSelected())

    btnCopy := RunHistoryGui.Add("Button", "x310 y445 w120 h32", "📋 Copy Output")
    btnCopy.OnEvent("Click", (*) => HistoryCopyOutput())

    btnDel := RunHistoryGui.Add("Button", "x600 y445 w110 h32", "🗑 Delete Run")
    btnDel.OnEvent("Click", (*) => HistoryDeleteSelected())

    btnClose := RunHistoryGui.Add("Button", "x720 y445 w140 h32", "Close [Esc]")
    btnClose.OnEvent("Click", (*) => CloseRunHistoryGui())

    RunHistoryGui.OnEvent("Escape", (*) => CloseRunHistoryGui())
    RunHistoryGui.OnEvent("Close", (*) => CloseRunHistoryGui())

    RefreshHistoryList()
    RunHistoryGui.Show("w880 h495")
}

CloseRunHistoryGui() {
    global RunHistoryGui
    if IsObject(RunHistoryGui) {
        try RunHistoryGui.Destroy()
        RunHistoryGui := ""
    }
}

RefreshHistoryList() {
    global HistoryListView, HistoryRunsList
    if !IsObject(HistoryListView)
        return

    HistoryRunsList := RunHistory.LoadAll()
    HistoryListView.Delete()

    for idx, runItem in HistoryRunsList {
        stBadge := (runItem.status = "success") ? "✔ Pass" : "❌ Fail"
        durStr := (runItem.HasOwnProp("duration_ms") ? runItem.duration_ms : 0) . " ms"
        ts := runItem.HasOwnProp("timestamp") ? runItem.timestamp : ""
        rName := runItem.HasOwnProp("recipe_name") ? runItem.recipe_name : "Recipe"
        inPrev := runItem.HasOwnProp("input_snapshot") ? StrReplace(SubStr(String(runItem.input_snapshot), 1, 40), "`n", " ↵ ") : ""
        outPrev := runItem.HasOwnProp("output_snapshot") ? StrReplace(SubStr(String(runItem.output_snapshot), 1, 40), "`n", " ↵ ") : ""

        HistoryListView.Add("", stBadge, ts, rName, durStr, inPrev, outPrev)
    }
}

HistoryInspectSelected() {
    global HistoryListView, HistoryRunsList
    row := HistoryListView.GetNext()
    if (row <= 0 || row > HistoryRunsList.Length) {
        ShowToast("⚠️ Select a run to inspect", 1800)
        return
    }

    runItem := HistoryRunsList[row]
    details := Format("Run ID: {1}`nRecipe: {2} (v{3})`nTimestamp: {4}`nStatus: {5} ({6} ms)`n`n",
                      runItem.run_id, runItem.recipe_name, runItem.recipe_version, runItem.timestamp, runItem.status, runItem.duration_ms)

    if (runItem.status != "success") {
        details .= Format("❌ Failure at step: {1}`nError: {2}`n`n", runItem.failed_step, runItem.error_message)
    }

    details .= "--- Original Input Snapshot ---`n" . String(runItem.input_snapshot) . "`n`n"
    details .= "--- Final Output Snapshot ---`n" . String(runItem.output_snapshot) . "`n`n"

    if (runItem.HasOwnProp("step_snapshots") && Type(runItem.step_snapshots) = "Array") {
        details .= "--- Step-by-Step Snapshots ---`n"
        for s in runItem.step_snapshots {
            details .= Format("[{1}] Step {2} ({3} ms)`n", s.status = "success" ? "✔" : "❌", s.step_id, s.duration_ms)
            if s.HasOwnProp("outputs") && Type(s.outputs) = "Map" {
                for k, v in s.outputs
                    details .= Format("   • {1}: {2}`n", k, (Type(v) = "Array" ? "[Array " . v.Length . "]" : String(v)))
            }
            if s.HasOwnProp("error")
                details .= Format("   • Error: {1}`n", s.error)
        }
    }

    MsgBox(details, "Workflow Step Snapshot Inspector", "Iconi")
}

HistoryRerunSelected() {
    global HistoryListView, HistoryRunsList
    row := HistoryListView.GetNext()
    if (row <= 0 || row > HistoryRunsList.Length) {
        ShowToast("⚠️ Select a run to rerun", 1800)
        return
    }

    runItem := HistoryRunsList[row]
    recipeId := runItem.recipe_id
    rawInput := runItem.HasOwnProp("input_snapshot") ? String(runItem.input_snapshot) : ""

    try {
        recipe := RecipeModel.Load(recipeId)
        CloseRunHistoryGui()
        PipelineRunner.Execute(recipe, rawInput)
    } catch as err {
        ShowToast("❌ Rerun Error: " . err.Message, 2500)
    }
}

HistoryCopyOutput() {
    global HistoryListView, HistoryRunsList
    row := HistoryListView.GetNext()
    if (row <= 0 || row > HistoryRunsList.Length) {
        ShowToast("⚠️ Select a run to copy", 1800)
        return
    }

    runItem := HistoryRunsList[row]
    outText := runItem.HasOwnProp("output_snapshot") ? String(runItem.output_snapshot) : ""
    if (outText != "") {
        A_Clipboard := outText
        ShowToast("✔ Output copied to clipboard", 2000)
    } else {
        ShowToast("⚠️ No output found in this run", 2000)
    }
}

HistoryDeleteSelected() {
    global HistoryListView, HistoryRunsList
    row := HistoryListView.GetNext()
    if (row <= 0 || row > HistoryRunsList.Length)
        return

    runItem := HistoryRunsList[row]
    RunHistory.Delete(runItem.run_id)
    RefreshHistoryList()
    ShowToast("✔ Run record deleted", 1800)
}
