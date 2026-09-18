; ======================================================================================================================
; Module: Globals.ahk - Centralized Global State, Configuration & Unified Theme Tokens
; Part of Office Productivity Hub (v2.0.1)
; ======================================================================================================================

#Requires AutoHotkey v2.0

; --- Application Identity ---
global AppTitle           := "Office Productivity Hub"
global AppVersion         := "2.0.1"

; --- Unified Theme Design Tokens ---
global ThemePrimary       := "7B909D" ; Slate Grey / Cool Steel Blue
global ThemeSecondary     := "73828C" ; Muted Steel Slate
global ThemeAccent        := "CE6B40" ; Warm Terracotta / Burnt Amber
global ThemeBg            := "0A0D10" ; Ultra Dark Charcoal Navy
global ThemeSurface       := "182025" ; Dark Deep Slate Navy Surface
global ThemeText          := "F8FAFC" ; Crisp Off-White Text
global ThemeMuted         := "98A9B3" ; Soft Slate Grey Muted Text
global ThemeBorder        := "33424D" ; Medium Dark Slate Border

; --- Eisenhower Matrix Quadrant Design Tokens ---
global ColorQ1            := "CE6B40" ; Warm Terracotta (DO FIRST)
global ColorQ2            := "D6B656" ; Muted Gold (SCHEDULE)
global ColorQ3            := "5F8FA8" ; Muted Blue (QUICK WIN)
global ColorQ4            := "98A9B3" ; Soft Slate Grey (BACKLOG)

; --- Presentation Helper Primitive (RGB Hex -> Win32 BGR Integer) ---
HexToBGR(hexStr) {
    clean := RegExReplace(hexStr, "^(#|0x)", "")
    return (StrLen(clean) = 6)
        ? (Integer("0x" . SubStr(clean, 5, 2)) << 16) | (Integer("0x" . SubStr(clean, 3, 2)) << 8) | Integer("0x" . SubStr(clean, 1, 2))
        : 0
}

; --- Presentation Helper Primitive (Dark-mode row/header theming for a ListView control) ---
; A .BackColor/font set on the Gui or the ListView itself does not reach the native header and
; row-selection chrome Windows draws for a ListView — that still needs the Explorer dark visual
; style applied via uxtheme. Every *Gui.ahk file that adds a ListView should call this once, right
; after AddListView(), instead of repeating the DllCall inline.
ApplyDarkListViewTheme(listViewCtrl) {
    try {
        DllCall("uxtheme\SetWindowTheme", "ptr", listViewCtrl.Hwnd, "str", "DarkMode_Explorer", "str", "Explorer")
    }
}

; ======================================================================================================================
; GLOBAL STATE REGISTRY (documentation only — no declarations below add runtime state themselves)
;
; AHK v2 has one flat global namespace once a file is #Included, so "which globals exist" is not
; enforced by the language. This registry exists so a future contributor (LLM or human) can find
; every mutable global in one place without grepping the whole Lib\ tree first. This file
; (Globals.ahk) owns app-wide state (theme tokens, file paths, cross-cutting flags/handles used by
; Core.ahk, PaletteGui.ahk, ActionBoardGui.ahk, TaskManager.ahk, etc. — see the declarations below
; this block). Each GUI/engine module below owns its OWN window handles and panel-local UI state,
; declared where it's used rather than here, because moving ~30 loosely-related variables into this
; file would not make them any less globally-scoped in AHK v2 — it would just add an indirection
; without changing behavior. What DOES matter is that this list stays accurate:
;
;   Lib/WorkflowComposerGui.ahk  - WorkflowComposerGui, WcStepsListView, WcCurrentRecipe,
;                                  WcSelectedStepIdx, WcStepSettingsModalGui, WcAddStepModalGui,
;                                  WcOpenRecipeModalGui, WcInspectorTitle, WcInspectorDesc,
;                                  WcBindingDropdowns, WcSettingEdits, WcPreviewBox, WcStatusText,
;                                  WcSampleInput
;   Lib/SnippetGui.ahk           - SnippetGui, SnippetListView, SnippetSearchEdit, SnippetStatusBar,
;                                  BtnAdd, BtnEdit, BtnDelete, BtnToggle, BtnImport, BtnExport,
;                                  BtnHelp, SnippetPos
;   Lib/WindowPeekEngine.ahk     - IsWindowPeekEnabled, PeekState, CapsLockPressTick,
;                                  CapsLockChordFired, XRayState, XRayOpacityPercent, XRayAlphaValue
;   Lib/WindowPeekHotkeys.ahk    - CapsLockStuckSince, CapsLockStuckThresholdMs
;   Lib/DateFormatGui.ahk        - DateFormatGui, DateFormatListView, DateFormatCurrentItems
;   Lib/RunHistoryGui.ahk        - RunHistoryGui, HistoryListView, HistoryRunsList
;
; RULE: if you add, rename, or remove a global in one of the files above, update this list in the
; same commit. If you add a new file with its own module-owned globals, add a line here and drop
; the same one-line pointer comment ("Catalogued in the Global State Registry in Lib/Globals.ahk")
; above the declaration in that file, matching the existing files above.
;
; NAMING: unlike C:\Users\Admin\Documents\AutoHotkey\MY_CODING_STYLE_AND_STANDARDS.txt's general
; `g_` prefix rule, this codebase's globals are unprefixed project-wide (PaletteGui, ActionTasks,
; GlobalFeedbackEpoch, etc.) — this was a deliberate, consistent choice made before this registry
; existed, not an oversight, and this file is what makes an unprefixed global discoverable instead
; of the prefix. Keep it unprefixed; do not partially introduce `g_` for new code, since a mixed
; convention would be worse than either consistent one.
; ======================================================================================================================

; ======================================================================================================================
; FILE NAMING & MODULE ORGANIZATION CONVENTION
;
; Lib/ files follow one of three patterns, chosen by what the file does:
;   Actions_<Domain>.ahk   - Hotkey-facing action registries: RegisterXActions() + the palette
;                            action callbacks themselves (Actions_Text.ahk, Actions_Math.ahk,
;                            Actions_Finance.ahk, Actions_Extraction.ahk, Actions_DateTime.ahk,
;                            Actions_Email.ahk, Actions_Utility.ahk, Actions_WindowPeek.ahk,
;                            Actions_CivilConvert.ahk, Actions_Workflow.ahk).
;   <Domain>Engine.ahk /    - Pure computational/parsing logic with no hotkey wiring and no GUI code,
;   <Domain>.ahk (bare)      almost always class-based (CorpusSetEngine.ahk, MathEvaluator.ahk,
;                            NumberParser.ahk, DateFormatConverter.ahk, CivilConverterEngine.ahk and
;                            the other Civil*.ahk engines, RecipeModel.ahk, PipelineRunner.ahk,
;                            WorkflowPrimitives.ahk, ToolAdapters_Builtin.ahk). Also covers
;                            stateful-but-non-GUI managers (TaskManager.ahk, SnippetManager.ahk,
;                            RunHistory.ahk, Telemetry.ahk) and the flat cross-cutting modules
;                            (Core.ahk, ClipboardHelper.ahk, Globals.ahk itself).
;   <Domain>Gui.ahk         - Everything that builds a Gui() window: PaletteGui.ahk, SnippetGui.ahk,
;                            ActionBoardGui.ahk, DateFormatGui.ahk, CivilConverterGui.ahk,
;                            WorkflowComposerGui.ahk, RunHistoryGui.ahk.
;
; This mirrors a real architectural split, not just a naming habit: computational/engine code is
; almost always class-based (static methods, no globals of its own beyond what's cataloged above),
; while GUI and hotkey-dispatch code stays flat-function-with-globals, because that's the natural
; shape of an AHK v2 GUI callback graph. Pick the pattern that matches what the new file actually
; does; don't invent a fourth naming scheme.
; ======================================================================================================================


; --- Core Directories & File Paths ---
global IsTestMode         := (EnvGet("OPH_TEST_MODE") == "1")
global DataDir            := (IsTestMode && EnvGet("OPH_TEST_DATA_DIR") != "") ? EnvGet("OPH_TEST_DATA_DIR") : A_ScriptDir
global SnippetsFile           := DataDir . "\office_productivity_snippets.csv"
global SnippetsMasterBackupFile := DataDir . "\Backups\snippets_backup_master.csv"
global SnippetsPrevBackupFile := DataDir . "\Backups\snippets_backup_previous.csv"
global SnippetsPreImportFile  := DataDir . "\Backups\snippets_backup_pre_import.csv"
global ActionTasksFile        := DataDir . "\office_productivity_tasks.csv"
global ActionArchiveFile      := DataDir . "\office_tasks_archive.csv"
global CivilEngineeringDefaultsFile := DataDir . "\CivilEngineeringDefaults.ini"
global SettingsFile           := DataDir . "\office_productivity_settings.ini"
global DefaultDateFormatId    := 6
global RecipesDir             := DataDir . "\Recipes"
global RunHistoryFile         := DataDir . "\Logs\WorkflowRunHistory.json"
global TelemetryDir           := IsTestMode ? (DataDir . "\Telemetry") : (A_AppData . "\OfficeProductivityHub")
global TelemetryStatsFile     := TelemetryDir . "\usage_analytics.ini"
global TelemetryErrorLog      := TelemetryDir . "\error_telemetry.log"
global TelemetryMissLog       := TelemetryDir . "\zero_result_searches.log"

LoadAppSettings() {
    global SettingsFile, DefaultDateFormatId
    try {
        val := Integer(IniRead(SettingsFile, "DateFormat", "DefaultFormatId", "6"))
        if (val >= 1 && val <= 9)
            DefaultDateFormatId := val
        else
            DefaultDateFormatId := 6
    } catch {
        DefaultDateFormatId := 6
    }
    return DefaultDateFormatId
}

SaveDefaultDateFormat(formatId) {
    global SettingsFile, DefaultDateFormatId
    idNum := Integer(formatId)
    if (idNum < 1 || idNum > 9)
        return false
    DefaultDateFormatId := idNum
    try {
        IniWrite(String(idNum), SettingsFile, "DateFormat", "DefaultFormatId")
        return true
    } catch {
        return false
    }
}

GetDefaultDateFormatName() {
    global DefaultDateFormatId
    names := [
        "DD/MM/YYYY",
        "DD-MM-YYYY",
        "DD.MM.YYYY",
        "DD/MM/YY",
        "DD-MM-YY",
        "DD Month YYYY",
        "Month DD, YYYY",
        "DD Month, YYYY",
        "DDDD, dd Month YYYY"
    ]
    idx := (DefaultDateFormatId >= 1 && DefaultDateFormatId <= 9) ? DefaultDateFormatId : 6
    return names[idx]
}

; --- Workflow Composer & Diagnostics ---
global WorkflowComposerGui    := ""
global RunHistoryGui          := ""

; --- Central Action & Snippet Registry ---
global BuiltInActions         := []          ; Array of registered tool objects: {name, category, description, keywords, callback, chord, isCustom}
global Snippets               := []          ; Unified array of snippet objects: {trigger, replacement, enabled}
global RegisteredTriggers     := Map()      ; Map of currently active hotstring triggers
global LastSnippetFileModTime := 0          ; Last modified timestamp for snippets auto-watcher

; --- Action Board Tasks Registry ---
global ActionTasks        := []          ; Unified array of task objects: {id, task, created, commitmentType, priority, done}
global LastTaskFileModTime:= 0          ; Last modified timestamp for auto-watcher

; --- Command Palette GUI State ---
global PaletteGui         := ""
global PaletteSearch      := ""
global PalettePlaceholder := ""
global PaletteListView    := ""
global PaletteStatus      := ""
global PaletteItems       := []
global IsPaletteExpanded  := false

; --- Visual Snippet Manager GUI State ---
global SnippetGui         := ""
global SnippetListView    := ""
global SnippetSearchEdit  := ""
global SnippetStatusBar   := ""
global SnippetPos         := {x: 100, y: 100, w: 720, h: 420}

; --- Action Board Matrix GUI State ---
global ActionBoardGui     := ""
global InputTaskBox       := ""
global LV_Q1              := ""
global LV_Q2              := ""
global LV_Q3              := ""
global LV_Q4              := ""
global Header_Q4          := ""
global LastActiveLV       := ""
global PreviewTaskTextCtrl:= ""
global PreviewMetaCtrl    := ""
global ActionStatusText   := ""

; --- Action Board Floating Mini-Pills & HUDs ---
global ClassifierGui      := ""
global PrioritizerMiniGui := ""
global NudgeHudGui        := ""
global YellowHudGui       := ""
global ToastHudGui        := ""
global ToastTextCtrl      := ""
global FindReplaceGui     := ""
global CivilPromptGui     := ""
global CivilResultHudGui  := ""
global DateFormatGui      := ""

global LastClassifiedTime := 0
global LastPrioritizedTime:= 0

; --- Interaction & Timing State ---
global TargetWindowHwnd   := 0
global LeaderActive       := false
global LastShiftTime      := 0
global LastCtrlTime       := 0
global LastExecutedAction := ""
global GlobalFeedbackEpoch := 0
global SessionStartTime   := A_Now
