; ======================================================================================================================
; Title:   Office Productivity Hub & Action Board
; Version: 2.0.1 (Modular Production Release - Symbiotic Architecture & Zero-Trust Modularity Invariants)
; AHK Ver: v2.0+
; OS:      Windows 10 / 11
;
; Core Purpose:
; A keyboard-driven Windows office productivity hub that unifies 85+ essential tools,
; instant date/text/math transformations, strict number & Indian currency parsing, 4-quadrant
; Eisenhower Action Board, and on-the-fly snippet expansion into a fast, non-blocking Command Palette.
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)

; --- Modular Component Inclusions ---
#Include "Lib\Globals.ahk"
#Include "Lib\CSVParser.ahk"
#Include "Lib\ClipboardHelper.ahk"
#Include "Lib\NumberParser.ahk"
#Include "Lib\MathEvaluator.ahk"
#Include "Lib\Telemetry.ahk"
#Include "Lib\SnippetManager.ahk"
#Include "Lib\SnippetGui.ahk"
#Include "Lib\TaskManager.ahk"
#Include "Lib\ActionBoardPills.ahk"
#Include "Lib\ActionBoardGui.ahk"
#Include "Lib\PaletteGui.ahk"
#Include "Lib\Core.ahk"
#Include "Lib\DateFormatConverter.ahk"
#Include "Lib\DateFormatGui.ahk"
#Include "Lib\Actions_DateTime.ahk"
#Include "Lib\Actions_Text.ahk"
#Include "Lib\Actions_Email.ahk"
#Include "Lib\Actions_Math.ahk"
#Include "Lib\Actions_Finance.ahk"
#Include "Lib\Actions_Extraction.ahk"
#Include "Lib\Actions_Utility.ahk"
#Include "Lib\Actions_WindowPeek.ahk"
#Include "Lib\WindowPeekHotkeys.ahk"
#Include "Lib\CivilConverterEngine.ahk"
#Include "Lib\CivilConverterGui.ahk"
#Include "Lib\Actions_CivilConvert.ahk"
#Include "Lib\JsonHelper.ahk"
#Include "Lib\WorkflowTypes.ahk"
#Include "Lib\ToolCatalog.ahk"
#Include "Lib\WorkflowPrimitives.ahk"
#Include "Lib\ToolAdapters_Builtin.ahk"
#Include "Lib\RecipeModel.ahk"
#Include "Lib\PipelineRunner.ahk"
#Include "Lib\RunHistory.ahk"
#Include "Lib\RunHistoryGui.ahk"
#Include "Lib\WorkflowComposerGui.ahk"
#Include "Lib\Actions_Workflow.ahk"
#Include "..\Study_MarkdownHub v2.0\Lib\Actions_FindReplace.ahk"
#Include "..\Study_MarkdownHub v2.0\Lib\Hotstrings_Prompts.ahk"
#Include "..\Word Count Tooltip.ahk"

; Initialize App
InitApp()

InitApp() {
    InitTelemetry()
    LoadAppSettings()
    try {
        RegisterDateTimeActions()
        RegisterTextActions()
        RegisterEmailActions()
        RegisterMathActions()
        RegisterFinanceActions()
        RegisterExtractionActions()
        RegisterUtilityActions()
        RegisterActionBoardActions()
        RegisterFindReplaceActions()
        RegisterWindowPeekActions()
        RegisterCivilActions()
        InitWorkflowEngine()

        InitSnippetEngine()
        InitActionBoardEngine()
        InitWindowPeekEngine()
        InitXRayEngine()

        ; CapsLock State Protection: Never accidentally type ALL CAPS
        SetStoreCapsLockMode(false)
        SetCapsLockState("AlwaysOff")
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("InitApp", err)
        MsgBox("Failed to initialize Office Productivity Hub:`n`n" . err.Message, AppTitle . " - Init Error", "Icon!")
    }
}

; ======================================================================================================================
;                                             GLOBAL HOTKEYS & TRIGGERS
; ======================================================================================================================

; --- Ambient Selection Tooltip Watcher ---
global DragStartX := 0
global DragStartY := 0

~LButton::
{
    global DragStartX, DragStartY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&DragStartX, &DragStartY)
}

~LButton Up::
{
    global DragStartX, DragStartY
    CoordMode("Mouse", "Screen")
    MouseGetPos(&endX, &endY)
    if (Abs(endX - DragStartX) > 30 || Abs(endY - DragStartY) > 20) {
        sel := SafeGetSelection(0.2)
        sLen := StrLen(Trim(sel))
        if (sLen >= 30 && sLen <= 100) {
            ShowToast("📌 Task Detected — Double-tap Ctrl to add to Action Board", 2500)
        }
    }
}

; --- In-Selection Find & Replace (Ctrl + H / F12) ---
^h::ShowFindReplaceModal()
F12::ShowFindReplaceModal()

; --- Repeat Last Action (Win + 0 / Ctrl + 0) ---
#0::RepeatLastAction()
^0::RepeatLastAction()

; --- 1. Universal Command Palette: Double-Shift (JetBrains / IntelliJ Style) ---
~LShift Up::
~RShift Up::
{
    global LastShiftTime
    if (A_PriorKey = "LShift" || A_PriorKey = "RShift") {
        if (A_TickCount - LastShiftTime < 350) {
            LastShiftTime := 0
            ShowCommandPalette()
            return
        }
        LastShiftTime := A_TickCount
    } else {
        LastShiftTime := 0
    }
}

; Fallback Hotkey for Palette
^Space::ShowCommandPalette()

; --- Double-Ctrl: Instant Task / Commitment Capture ---
~LCtrl Up::
~RCtrl Up::
{
    global LastCtrlTime
    diff := A_TickCount - LastCtrlTime
    if (diff > 50 && diff < 450) {
        LastCtrlTime := 0
        CaptureSelectedTextAsTask()
    } else {
        LastCtrlTime := A_TickCount
    }
}

; --- Action Board Hotkeys (Win + T / Ctrl + Shift + T) ---
#t::ToggleActionBoard()
#+t::ToggleActionBoard()
^+t::CaptureSelectedTextAsTask()

; --- 2. Instant Highlight & Save Snippet (Ctrl + Shift + H) ---
^+h::CaptureSelectedTextAsSnippet()

; --- Civil & Construction Converter (Ctrl + Shift + U) ---
^+u::ShowCivilConverter()

; --- 3. Visual Snippet Manager (Win + Esc) ---
#Esc::ShowSnippetManagerGui()

; --- 4. Leader Key Chords (Win + Shift + ; / Win + Shift + Space) ---
#+;::ActivateLeaderKey()
#+Space::ActivateLeaderKey()

; --- 5. Word 2016 Parity Hotkeys (Active everywhere EXCEPT Microsoft Word) ---
#HotIf !WinActive("ahk_exe WINWORD.EXE")
!+d::InsertText(FormatTime(A_Now, "yyyy-MM-dd"))       ; Alt + Shift + D -> ISO Date
!+t::InsertText(FormatTime(A_Now, "hh:mm tt"))          ; Alt + Shift + T -> 12-Hour Time
^+g::ShowTextStats()                                     ; Ctrl + Shift + G -> Word & Char Statistics
+F3::TransformSelectedText((txt) => CycleTextCase(txt)) ; Shift + F3 -> Word 3-State Case Cycler
#HotIf

; ======================================================================================================================
;                                          GLOBAL & CONTEXTUAL ESCAPE DISMISSAL
; ======================================================================================================================

; --- Global Escape Dismissal: Closes ALL open Office Hub UIs even when focus is elsewhere ---
#HotIf IsAnyOfficeUIVisible()
    ~Esc::CloseAllOfficeUIs()
#HotIf

#HotIf HasPaletteResults()
    !1::PaletteExecuteSelection(1)
    !2::PaletteExecuteSelection(2)
    !3::PaletteExecuteSelection(3)
    !4::PaletteExecuteSelection(4)
    !5::PaletteExecuteSelection(5)
    !6::PaletteExecuteSelection(6)
    !7::PaletteExecuteSelection(7)
    !8::PaletteExecuteSelection(8)
    !9::PaletteExecuteSelection(9)

    !Numpad1::PaletteExecuteSelection(1)
    !Numpad2::PaletteExecuteSelection(2)
    !Numpad3::PaletteExecuteSelection(3)
    !Numpad4::PaletteExecuteSelection(4)
    !Numpad5::PaletteExecuteSelection(5)
    !Numpad6::PaletteExecuteSelection(6)
    !Numpad7::PaletteExecuteSelection(7)
    !Numpad8::PaletteExecuteSelection(8)
    !Numpad9::PaletteExecuteSelection(9)
#HotIf

#HotIf IsPaletteActive()
    Up::PaletteNavigate(-1)
    Down::PaletteNavigate(1)
    Enter::PaletteExecuteSelection()
#HotIf

#HotIf IsSnippetListViewFocused()
    Space::ToggleSelectedSnippet()
    Del::DeleteSelectedSnippet()
    F2::EditSelectedSnippet()
    Enter::EditSelectedSnippet()
    Esc::CloseAllOfficeUIs()
#HotIf

#HotIf IsActionBoardActive() && !IsInputTaskBoxFocused()
    1::MatrixMoveSelectedTask("Q1")
    2::MatrixMoveSelectedTask("Q2")
    3::MatrixMoveSelectedTask("Q3")
    4::MatrixMoveSelectedTask("Q4")
    Space::MatrixToggleDone()
    v::ShowFullTaskViewModal()
    Del::MatrixDeleteSelectedTask()
#HotIf

#HotIf IsInputTaskBoxFocused()
    Enter::HandleMatrixEnterKey()
    Down:: {
        global LastActiveLV, LV_Q1
        targetLV := IsObject(LastActiveLV) ? LastActiveLV : LV_Q1
        if IsObject(targetLV) {
            targetLV.Focus()
            if (targetLV.GetNext() == 0 && targetLV.GetCount() > 0)
                targetLV.Modify(1, "Select Focus")
        }
    }
#HotIf

