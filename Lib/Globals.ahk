; ======================================================================================================================
; Module: Globals.ahk - Centralized Global State, Configuration & Unified Theme Tokens
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

; --- Application Identity ---
global AppTitle           := "Office Productivity Hub"
global AppVersion         := "2.0.0"

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
global TelemetryDir           := IsTestMode ? (DataDir . "\Telemetry") : (A_AppData . "\OfficeProductivityHub")
global TelemetryStatsFile     := TelemetryDir . "\usage_analytics.ini"
global TelemetryErrorLog      := TelemetryDir . "\error_telemetry.log"
global TelemetryMissLog       := TelemetryDir . "\zero_result_searches.log"

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
global FindReplaceGui     := ""
global CivilPromptGui     := ""
global CivilResultHudGui  := ""

global LastClassifiedTime := 0
global LastPrioritizedTime:= 0

; --- Interaction & Timing State ---
global TargetWindowHwnd   := 0
global LeaderActive       := false
global LastShiftTime      := 0
global LastCtrlTime       := 0
global LastExecutedAction := ""
global SessionStartTime   := A_Now
