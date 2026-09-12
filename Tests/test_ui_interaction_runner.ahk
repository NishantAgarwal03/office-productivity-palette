; ======================================================================================================================
; Module: test_ui_interaction_runner.ahk - Synthetic UI Focus, Hotkey Independence & Multi-Window Lifecycle Tests
; Part of Office Productivity Hub (v2.0.1) - Zero-Trust Verification Framework
;
; Tests real GUI instantiation, control focus verification (ControlGetFocus), keyboard navigation handoffs,
; modal dialog lifecycles, and global Escape dismissal (IsAnyOfficeUIVisible(), CloseAllOfficeUIs())
; without interactive user prompts.
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

; --- Mute External UI Messages & Shell Overrides ---
ShowTextStats(*) => ""
LogAppError(*) => ""
LogToolExecution(*) => ""
LogZeroMatchQuery(*) => ""
ExportDiagnosticsReport(*) => ""

; --- Pure Logic & Global Inclusions ---
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\SnippetManager.ahk"
#Include "..\Lib\SnippetGui.ahk"
#Include "..\Lib\TaskManager.ahk"
#Include "..\Lib\ActionBoardPills.ahk"
#Include "..\Lib\ActionBoardGui.ahk"
#Include "..\Lib\PaletteGui.ahk"
#Include "..\Lib\Core.ahk"
#Include "..\Lib\DateFormatConverter.ahk"
#Include "..\Lib\DateFormatGui.ahk"
#Include "..\Lib\Actions_DateTime.ahk"
#Include "..\Lib\Actions_Text.ahk"
#Include "..\Lib\Actions_Email.ahk"
#Include "..\Lib\Actions_Math.ahk"
#Include "..\Lib\Actions_Finance.ahk"
#Include "..\Lib\Actions_Extraction.ahk"
#Include "..\Lib\Actions_Utility.ahk"
#Include "..\Lib\Actions_WindowPeek.ahk"
#Include "..\Lib\CivilConverterEngine.ahk"
#Include "..\Lib\CivilConverterGui.ahk"
#Include "..\Lib\Actions_CivilConvert.ahk"
#Include "..\Lib\JsonHelper.ahk"
#Include "..\Lib\WorkflowTypes.ahk"
#Include "..\Lib\ToolCatalog.ahk"
#Include "..\Lib\WorkflowPrimitives.ahk"
#Include "..\Lib\ToolAdapters_Builtin.ahk"
#Include "..\Lib\RecipeModel.ahk"
#Include "..\Lib\PipelineRunner.ahk"
#Include "..\Lib\RunHistory.ahk"
#Include "..\Lib\RunHistoryGui.ahk"
#Include "..\Lib\WorkflowComposerGui.ahk"
#Include "..\Lib\Actions_Workflow.ahk"

global UiTestsTotal  := 0
global UiTestsPassed := 0
global UiTestsFailed := 0
global UiLogLines    := []
global Failures      := []
global StartTick     := A_TickCount

AssertUI(suite, testName, condition, actualVal := "") {
    global UiTestsTotal, UiTestsPassed, UiTestsFailed, UiLogLines, Failures
    UiTestsTotal++
    if (condition) {
        UiTestsPassed++
        UiLogLines.Push("[UI PASS] " . suite . " | " . testName . " -> OK")
    } else {
        UiTestsFailed++
        UiLogLines.Push("[UI FAIL] " . suite . " | " . testName . " -> FAILED (Got: '" . String(actualVal) . "')")
        Failures.Push({category: suite, testName: testName, error: "Got: '" . String(actualVal) . "'"})
    }
}

try {
    ; Initialize Action Registries
    RegisterDateTimeActions()
    RegisterTextActions()
    RegisterEmailActions()
    RegisterMathActions()
    RegisterFinanceActions()
    RegisterExtractionActions()
    RegisterUtilityActions()
    RegisterActionBoardActions()
    RegisterWindowPeekActions()
    RegisterCivilActions()
    InitWorkflowEngine()
    InitTaskManager()

    ; ==================================================================================================
    ; 1. Palette GUI Focus & Lifecycle Tests
    ; ==================================================================================================
    AssertUI("Palette_Lifecycle", "Palette initial state is not visible", !IsPaletteVisible(), IsPaletteVisible())
    AssertUI("Palette_Lifecycle", "No office UI initially visible", !IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())

    ; Open Command Palette
    ShowCommandPalette()
    Sleep(50)

    AssertUI("Palette_Lifecycle", "Palette visible after ShowCommandPalette", IsPaletteVisible(), IsPaletteVisible())
    AssertUI("Palette_Lifecycle", "IsAnyOfficeUIVisible is true when Palette open", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("Palette_Lifecycle", "PaletteGui object created", IsObject(PaletteGui), IsObject(PaletteGui))
    AssertUI("Palette_Lifecycle", "PaletteSearch control exists", IsObject(PaletteSearch), IsObject(PaletteSearch))

    ; Focus Verification
    focusedCtrlName := ControlGetFocus("ahk_id " . PaletteGui.Hwnd)
    focusedCtrlHwnd := ControlGetHwnd(focusedCtrlName, "ahk_id " . PaletteGui.Hwnd)
    AssertUI("Palette_Focus", "PaletteSearch Edit control has active focus", focusedCtrlHwnd == PaletteSearch.Hwnd, "focused=" . focusedCtrlName)
    AssertUI("Palette_Focus", "Initial placeholder is visible", PalettePlaceholder.Visible, PalettePlaceholder.Visible)

    ; Search Query Filtering
    PaletteSearch.Value := "GST"
    OnPaletteSearchChange("GST")
    Sleep(20)
    AssertUI("Palette_Search", "PaletteItems populated for 'GST'", PaletteItems.Length > 0, PaletteItems.Length)
    AssertUI("Palette_Search", "PaletteListView visible on search results", PaletteListView.Visible, PaletteListView.Visible)
    AssertUI("Palette_Search", "PaletteListView has 5 columns", PaletteListView.GetCount("Column") == 5, PaletteListView.GetCount("Column"))
    AssertUI("Palette_Search", "Placeholder hidden when typing", !PalettePlaceholder.Visible, PalettePlaceholder.Visible)

    ; Alt+Digit Badge Formatting (Items 1-9 get A+1..A+9 badges)
    badgeText := PaletteListView.GetText(1, 1)
    AssertUI("Palette_Search", "First result has A+1 badge", badgeText == "A+1", badgeText)

    ; Zero Results Handling
    OnPaletteSearchChange("zzzz_nonexistent_tool_query_999")
    Sleep(20)
    AssertUI("Palette_Search", "Zero matches for invalid query", PaletteItems.Length == 0, PaletteItems.Length)
    AssertUI("Palette_Search", "PaletteListView hidden on zero matches", !PaletteListView.Visible, PaletteListView.Visible)
    AssertUI("Palette_Search", "Status displays zero matches message", InStr(PaletteStatus.Text, "No matching tools found"), PaletteStatus.Text)

    ; Navigation & Focus Handoff
    OnPaletteSearchChange("date")
    Sleep(20)
    prevIndex := PaletteListView.GetNext()
    PaletteNavigate(1)
    newIndex := PaletteListView.GetNext()
    AssertUI("Palette_Navigation", "PaletteNavigate down selects item", newIndex >= 1, newIndex)

    ; Dismissal
    CloseCommandPalette()
    Sleep(20)
    AssertUI("Palette_Lifecycle", "Palette closed after CloseCommandPalette", !IsPaletteVisible(), IsPaletteVisible())

    ; ==================================================================================================
    ; 2. Action Board GUI Focus, Quadrants & Task Lifecycle Tests
    ; ==================================================================================================
    AssertUI("ActionBoard_Lifecycle", "Action Board initial state is not visible", !IsActionBoardVisible(), IsActionBoardVisible())

    ; Toggle Action Board
    ToggleActionBoard()
    Sleep(50)

    AssertUI("ActionBoard_Lifecycle", "Action Board visible after ToggleActionBoard", IsActionBoardVisible(), IsActionBoardVisible())
    AssertUI("ActionBoard_Lifecycle", "IsAnyOfficeUIVisible true when Action Board open", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("ActionBoard_Lifecycle", "ActionBoardGui object created", IsObject(ActionBoardGui), IsObject(ActionBoardGui))
    AssertUI("ActionBoard_Lifecycle", "InputTaskBox exists", IsObject(InputTaskBox), IsObject(InputTaskBox))

    ; Focus Verification: InputTaskBox has immediate focus upon open
    focusedAbCtrlName := ControlGetFocus("ahk_id " . ActionBoardGui.Hwnd)
    focusedAbHwnd := ControlGetHwnd(focusedAbCtrlName, "ahk_id " . ActionBoardGui.Hwnd)
    AssertUI("ActionBoard_Focus", "InputTaskBox has immediate keyboard focus", focusedAbHwnd == InputTaskBox.Hwnd, "focused=" . focusedAbCtrlName)

    ; Verify Quadrant ListViews & Design Token Color Palette
    AssertUI("ActionBoard_Quadrants", "LV_Q1 exists", IsObject(LV_Q1), IsObject(LV_Q1))
    AssertUI("ActionBoard_Quadrants", "LV_Q2 exists", IsObject(LV_Q2), IsObject(LV_Q2))
    AssertUI("ActionBoard_Quadrants", "LV_Q3 exists", IsObject(LV_Q3), IsObject(LV_Q3))
    AssertUI("ActionBoard_Quadrants", "LV_Q4 exists", IsObject(LV_Q4), IsObject(LV_Q4))

    AssertUI("ActionBoard_Tokens", "Q1 Color is Warm Terracotta (#CE6B40)", ColorQ1 == "CE6B40", ColorQ1)
    AssertUI("ActionBoard_Tokens", "Q2 Color is Muted Gold (#D6B656)", ColorQ2 == "D6B656", ColorQ2)
    AssertUI("ActionBoard_Tokens", "Q3 Color is Muted Blue (#5F8FA8)", ColorQ3 == "5F8FA8", ColorQ3)
    AssertUI("ActionBoard_Tokens", "Q4 Color is Soft Slate Grey (#98A9B3)", ColorQ4 == "98A9B3", ColorQ4)

    ; 4-Quadrant Partitioning Test
    savedTasks := ActionTasks.Clone()
    ActionTasks := []
    AddTask("Critical Production Bug", "Q1", "Task")
    AddTask("Strategic Architecture Plan", "Q2", "Task")
    AddTask("Quick Vendor Call", "Q3", "Task")
    AddTask("Untriaged Ideas Note", "Q4", "Task")
    RefreshMatrixBoard()

    AssertUI("ActionBoard_Partition", "LV_Q1 displays Q1 task", LV_Q1.GetCount() == 1, LV_Q1.GetCount())
    AssertUI("ActionBoard_Partition", "LV_Q2 displays Q2 task", LV_Q2.GetCount() == 1, LV_Q2.GetCount())
    AssertUI("ActionBoard_Partition", "LV_Q3 displays Q3 task", LV_Q3.GetCount() == 1, LV_Q3.GetCount())
    AssertUI("ActionBoard_Partition", "LV_Q4 displays Q4 task", LV_Q4.GetCount() == 1, LV_Q4.GetCount())

    ; Focus Transfer to ListView
    LV_Q1.Focus()
    Sleep(20)
    focusedQ1Name := ControlGetFocus("ahk_id " . ActionBoardGui.Hwnd)
    focusedQ1Hwnd := ControlGetHwnd(focusedQ1Name, "ahk_id " . ActionBoardGui.Hwnd)
    AssertUI("ActionBoard_Focus", "Focus transfers smoothly to LV_Q1", focusedQ1Hwnd == LV_Q1.Hwnd, "focused=" . focusedQ1Name)

    ; Restore tasks and close Action Board
    ActionTasks := savedTasks
    ActionBoardGui.Hide()
    Sleep(20)
    AssertUI("ActionBoard_Lifecycle", "Action Board hidden after Hide()", !IsActionBoardVisible(), IsActionBoardVisible())

    ; ==================================================================================================
    ; 3. Toast HUD Notification Lifecycle Tests
    ; ==================================================================================================
    ShowToast("UI Test Runner Toast Notification", 10000)
    Sleep(50)
    AssertUI("ToastHUD_Lifecycle", "Toast HUD visible after ShowToast", IsToastHudVisible(), IsToastHudVisible())
    AssertUI("ToastHUD_Lifecycle", "IsAnyOfficeUIVisible true when Toast HUD open", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())

    DismissToastHud()
    Sleep(20)
    AssertUI("ToastHUD_Lifecycle", "Toast HUD hidden after DismissToastHud", !IsToastHudVisible(), IsToastHudVisible())

    ; ==================================================================================================
    ; 4. Workflow Composer GUI Lifecycle Tests
    ; ==================================================================================================
    ShowWorkflowComposer()
    Sleep(50)
    AssertUI("WorkflowComposer_Lifecycle", "WorkflowComposerGui visible after Show", SafeIsWindowVisible(WorkflowComposerGui), SafeIsWindowVisible(WorkflowComposerGui))
    AssertUI("WorkflowComposer_Lifecycle", "IsAnyOfficeUIVisible true when Composer open", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("WorkflowComposer_Lifecycle", "Steps ListView created", IsObject(WcStepsListView), IsObject(WcStepsListView))
    AssertUI("WorkflowComposer_Lifecycle", "Steps ListView has 5 columns", WcStepsListView.GetCount("Column") == 5, WcStepsListView.GetCount("Column"))
    AssertUI("WorkflowComposer_Lifecycle", "Inspector title control exists", IsObject(WcInspectorTitle), IsObject(WcInspectorTitle))

    ; Test Add Step Modal lifecycle with loop container
    WcShowAddStepModal()
    Sleep(50)
    addModalHwnd := WinExist("Add Step to Recipe ahk_class AutoHotkeyGUI")
    AssertUI("WorkflowComposer_Lifecycle", "Add Step Modal opened", addModalHwnd > 0, addModalHwnd)
    if IsObject(WcAddStepModalGui) {
        try WcAddStepModalGui.Destroy()
        WcAddStepModalGui := ""
        Sleep(20)
    }

    ; Add a test step and verify Step Settings Modal opens and closes cleanly
    uiTestStepObj := {
        id: "step_1",
        tool_id: "parse_number",
        tool_version: 1,
        settings: Map(),
        bindings: Map("text", "input.text")
    }
    WcCurrentRecipe.steps.Push(uiTestStepObj)
    WcRefreshStepsList()
    AssertUI("WorkflowComposer_Lifecycle", "Steps list populated with 1 step", WcStepsListView.GetCount() == 1, WcStepsListView.GetCount())

    WcShowStepSettingsModal(1)
    Sleep(50)
    settingsModalHwnd := WinExist("Step Settings - Parse Number / Amount (step_1) ahk_class AutoHotkeyGUI")
    AssertUI("WorkflowComposer_Lifecycle", "Step Settings Modal opened for step_1", settingsModalHwnd > 0, settingsModalHwnd)
    if IsObject(WcStepSettingsModalGui) {
        try WcStepSettingsModalGui.Destroy()
        WcStepSettingsModalGui := ""
        Sleep(20)
    }

    CloseWorkflowComposer()
    DismissToastHud()
    Sleep(20)
    AssertUI("WorkflowComposer_Lifecycle", "Workflow Composer closed after Close", !SafeIsWindowVisible(WorkflowComposerGui), SafeIsWindowVisible(WorkflowComposerGui))

    ; ==================================================================================================
    ; 5. Workflow Run History GUI Lifecycle Tests
    ; ==================================================================================================
    ShowRunHistoryGui()
    Sleep(50)
    AssertUI("RunHistory_Lifecycle", "RunHistoryGui visible after Show", SafeIsWindowVisible(RunHistoryGui), SafeIsWindowVisible(RunHistoryGui))
    AssertUI("RunHistory_Lifecycle", "IsAnyOfficeUIVisible true when History open", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("RunHistory_Lifecycle", "History ListView created", IsObject(HistoryListView), IsObject(HistoryListView))
    AssertUI("RunHistory_Lifecycle", "History ListView has 6 columns", HistoryListView.GetCount("Column") == 6, HistoryListView.GetCount("Column"))

    CloseRunHistoryGui()
    Sleep(20)
    AssertUI("RunHistory_Lifecycle", "Run History closed after Close", !SafeIsWindowVisible(RunHistoryGui), SafeIsWindowVisible(RunHistoryGui))

    ; ==================================================================================================
    ; 5B. DateFormatGui Settings Modal Lifecycle & Quick-Key Auto-Dismiss Tests
    ; ==================================================================================================
    ShowDateFormatSettingsGui()
    Sleep(50)
    AssertUI("DateFormatGui_Lifecycle", "DateFormatGui visible after Show", SafeIsWindowVisible(DateFormatGui), SafeIsWindowVisible(DateFormatGui))
    AssertUI("DateFormatGui_Lifecycle", "IsAnyOfficeUIVisible true when DateFormatGui open", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("DateFormatGui_Lifecycle", "DateFormat ListView created", IsObject(DateFormatListView), IsObject(DateFormatListView))
    AssertUI("DateFormatGui_Lifecycle", "DateFormat ListView has 9 rows", DateFormatListView.GetCount() == 9, DateFormatListView.GetCount())

    ; Test quick-key instant save and auto-dismiss
    OnQuickKeyDateFormatSetting(2)
    Sleep(30)
    AssertUI("DateFormatGui_Lifecycle", "DateFormatGui auto-dismissed after quick-key", !SafeIsWindowVisible(DateFormatGui), SafeIsWindowVisible(DateFormatGui))
    AssertUI("DateFormatGui_Lifecycle", "DefaultDateFormatId set to 2 via quick-key", DefaultDateFormatId == 2, DefaultDateFormatId)
    DismissToastHud()
    Sleep(20)

    ; Re-open and dismiss via Escape
    ShowDateFormatSettingsGui()
    Sleep(50)
    AssertUI("DateFormatGui_Lifecycle", "DateFormatGui visible on second open", SafeIsWindowVisible(DateFormatGui), SafeIsWindowVisible(DateFormatGui))
    DismissDateFormatSettingsGui()
    Sleep(60)
    AssertUI("DateFormatGui_Lifecycle", "DateFormatGui closed after Dismiss", !SafeIsWindowVisible(DateFormatGui), SafeIsWindowVisible(DateFormatGui))
    AssertUI("DateFormatGui_Lifecycle", "IsAnyOfficeUIVisible false after Dismiss", !IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    SaveDefaultDateFormat(6) ; Restore default to 6

    ; ==================================================================================================
    ; 6. Global Escape Dismissal Engine Multi-Window Tests
    ; ==================================================================================================
    ; Open multiple independent office UIs simultaneously
    ShowCommandPalette()
    ShowToast("Simultaneous UI Test Toast", 10000)
    ShowWorkflowComposer()
    Sleep(50)

    AssertUI("EscapeDismissal", "Multiple UIs open simultaneously", IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("EscapeDismissal", "Palette is open in multi-UI state", IsPaletteVisible(), IsPaletteVisible())
    AssertUI("EscapeDismissal", "Toast is open in multi-UI state", IsToastHudVisible(), IsToastHudVisible())
    AssertUI("EscapeDismissal", "Composer is open in multi-UI state", SafeIsWindowVisible(WorkflowComposerGui), SafeIsWindowVisible(WorkflowComposerGui))

    ; CloseAllOfficeUIs dismissal
    CloseAllOfficeUIs()
    Sleep(50)

    AssertUI("EscapeDismissal", "All UIs dismissed by CloseAllOfficeUIs", !IsAnyOfficeUIVisible(), IsAnyOfficeUIVisible())
    AssertUI("EscapeDismissal", "Palette closed after CloseAllOfficeUIs", !IsPaletteVisible(), IsPaletteVisible())
    AssertUI("EscapeDismissal", "Toast closed after CloseAllOfficeUIs", !IsToastHudVisible(), IsToastHudVisible())
    AssertUI("EscapeDismissal", "Composer closed after CloseAllOfficeUIs", !SafeIsWindowVisible(WorkflowComposerGui), SafeIsWindowVisible(WorkflowComposerGui))

    ; ==================================================================================================
    ; 7. Hotkey Interception Independence & Shortcut Catalog Audit
    ; ==================================================================================================
    ; Verify Search Edit Box digit neutrality: Typing raw numbers 1-9 does not trigger actions
    ShowCommandPalette()
    Sleep(50)
    PaletteSearch.Value := "1234567890"
    OnPaletteSearchChange(PaletteSearch.Value)
    AssertUI("Hotkey_Independence", "PaletteSearch accepts digits without hotkey interception", PaletteSearch.Value == "1234567890", PaletteSearch.Value)
    CloseCommandPalette()

    ; Audit BuiltInActions chord catalog: No collisions among registered chords
    chordMap := Map()
    duplicateChords := []
    for uiAct in BuiltInActions {
        if (uiAct.HasOwnProp("chord") && uiAct.chord != "") {
            cLower := StrLower(uiAct.chord)
            if (chordMap.Has(cLower)) {
                duplicateChords.Push(cLower . " (" . uiAct.name . " vs " . chordMap[cLower] . ")")
            } else {
                chordMap[cLower] := uiAct.name
            }
        }
    }
    AssertUI("Shortcut_Audit", "BuiltInActions contains zero duplicate chords", duplicateChords.Length == 0, duplicateChords.Length)

    ; Audit Leader Keys: Exactly 8 user-selected leader chords must exist and map to callable actions
    expectedLeaders := ["t", "v", "s", "x", "c", "p", "w", "n"]
    missingLeaders := []
    for uiLeaderKey in expectedLeaders {
        uiFound := false
        for uiAct in BuiltInActions {
            if (uiAct.HasOwnProp("chord") && StrLower(uiAct.chord) == uiLeaderKey) {
                if (HasMethod(uiAct.callback, "Call"))
                    uiFound := true
                break
            }
        }
        if (!uiFound)
            missingLeaders.Push(uiLeaderKey)
    }
    AssertUI("Shortcut_Audit", "All 8 Leader chords map to valid callable actions", missingLeaders.Length == 0, missingLeaders.Length)

    ; --------------------------------------------------------------------------------------------------
    ; Inspector Output Formatting: Map, Array, Object and empty types (DEFECT-032)
    ; --------------------------------------------------------------------------------------------------
    testMap := Map("key1", "val1", "key2", 42)
    fmtMap := WcFormatValueForInspector(testMap)
    AssertUI("Inspector_Formatting", "WcFormatValueForInspector handles Map without ToString error", InStr(fmtMap, "Map[2]") > 0, fmtMap)

    testObj := {prop1: "hello", prop2: 99}
    fmtObj := WcFormatValueForInspector(testObj)
    AssertUI("Inspector_Formatting", "WcFormatValueForInspector handles Object without ToString error", InStr(fmtObj, "hello") > 0, fmtObj)

    testArr := [1, 2, 3]
    fmtArr := WcFormatValueForInspector(testArr)
    AssertUI("Inspector_Formatting", "WcFormatValueForInspector handles Array", InStr(fmtArr, "Array[3]") > 0, fmtArr)

    fmtEmptyMap := WcFormatValueForInspector(Map())
    AssertUI("Inspector_Formatting", "Empty Map formats cleanly", fmtEmptyMap == "{}", fmtEmptyMap)

    fmtEmptyArr := WcFormatValueForInspector([])
    AssertUI("Inspector_Formatting", "Empty Array formats cleanly", fmtEmptyArr == "[]", fmtEmptyArr)

    ; --------------------------------------------------------------------------------------------------
    ; 8. Workflow Composer Open / Edit Recipe Flow Tests
    ; --------------------------------------------------------------------------------------------------
    ; Verify Workflow: Edit Saved Recipe... action registration in Command Palette
    editRecipeActionFound := false
    for act in BuiltInActions {
        if (act.name = "Workflow: Edit Saved Recipe...") {
            editRecipeActionFound := true
            AssertUI("Workflow_EditAction", "Workflow: Edit Saved Recipe... action is callable", HasMethod(act.callback, "Call"), "")
            break
        }
    }
    AssertUI("Workflow_EditAction", "Workflow: Edit Saved Recipe... registered in BuiltInActions", editRecipeActionFound, "")

    ; Test WcShowOpenRecipeModal lifecycle
    WcShowOpenRecipeModal()
    Sleep(50)
    AssertUI("OpenRecipeModal_Lifecycle", "WcOpenRecipeModalGui is open", SafeIsWindowVisible(WcOpenRecipeModalGui), "")
    AssertUI("OpenRecipeModal_Lifecycle", "IsAnyOfficeUIVisible detects OpenRecipe modal", IsAnyOfficeUIVisible(), "")

    ; Dismiss Open Recipe modal
    CloseAllOfficeUIs()
    Sleep(50)
    AssertUI("OpenRecipeModal_Lifecycle", "WcOpenRecipeModalGui dismissed by CloseAllOfficeUIs", !SafeIsWindowVisible(WcOpenRecipeModalGui), "")

    ; Verify loading a specific saved recipe into ShowWorkflowComposer
    seedRecipes := RecipeModel.ListAll()
    AssertUI("OpenRecipe_Load", "RecipeModel.ListAll returns recipes", seedRecipes.Length > 0, seedRecipes.Length)

    if (seedRecipes.Length > 0) {
        testRecipeToLoad := seedRecipes[1]
        ShowWorkflowComposer(testRecipeToLoad)
        Sleep(50)
        AssertUI("OpenRecipe_Load", "WorkflowComposerGui is visible after loading recipe", SafeIsWindowVisible(WorkflowComposerGui), "")
        AssertUI("OpenRecipe_Load", "WcCurrentRecipe has loaded recipe ID", WcCurrentRecipe.id == testRecipeToLoad.id, WcCurrentRecipe.id)
        AssertUI("OpenRecipe_Load", "WcCurrentRecipe has matching steps", WcCurrentRecipe.steps.Length == testRecipeToLoad.steps.Length, WcCurrentRecipe.steps.Length)
        CloseWorkflowComposer()
        Sleep(30)
        AssertUI("OpenRecipe_Load", "WorkflowComposerGui closed cleanly", !SafeIsWindowVisible(WorkflowComposerGui), "")
    }

} catch as testErr {
    UiTestsFailed++
    UiLogLines.Push("[UI FATAL] " . testErr.Message . " at Line " . testErr.Line)
    Failures.Push({category: "UIFatalException", testName: "FatalException", error: testErr.Message . " (Line " . testErr.Line . ")"})
} finally {
    ; Clean up any surviving test windows to guarantee zero GUI leaks
    try CloseAllOfficeUIs()
    try {
        if IsObject(PaletteGui)
            PaletteGui.Destroy()
        if IsObject(ActionBoardGui)
            ActionBoardGui.Destroy()
        if IsObject(WorkflowComposerGui)
            WorkflowComposerGui.Destroy()
        if (IsSet(WcOpenRecipeModalGui) && IsObject(WcOpenRecipeModalGui))
            WcOpenRecipeModalGui.Destroy()
        if IsObject(RunHistoryGui)
            RunHistoryGui.Destroy()
        if IsObject(ToastHudGui)
            ToastHudGui.Destroy()
        if IsObject(DateFormatGui)
            DateFormatGui.Destroy()
    }
}

testDurationMs := A_TickCount - StartTick
EmitTestResults("test_ui_interaction_runner", UiTestsTotal, UiTestsPassed, UiTestsFailed, testDurationMs, UiLogLines, Failures)
