#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

outputDir := A_ScriptDir . "\UI_Screenshots"
if !DirExist(outputDir)
    DirCreate(outputDir)

global AppTitle          := "Office Productivity Hub"
global AppVersion        := "1.0.0"
global DataDir           := A_ScriptDir
global SnippetsFile      := DataDir . "\office_productivity_snippets.csv"
global ErrorLogFile      := DataDir . "\office_productivity_errors.log"

global BuiltInActions    := []
global CustomSnippets    := []
global RegisteredTriggers := Map()

global PaletteGui        := ""
global PaletteSearch     := ""
global PaletteListView   := ""
global PaletteStatus     := ""
global PaletteItems      := []
global TargetWindowHwnd  := 0

global ManagerGui        := ""
global ManagerListView   := ""
global ManagerSearch     := ""
global ManagerStatus     := ""
global ManagerPos        := {x: 100, y: 100, w: 720, h: 420}

global LeaderActive      := false
global LastShiftTime     := 0
global LastExecutedAction := ""
global LastCtrlTime      := 0

#Include "Lib\Core.ahk"
#Include "Lib\PaletteGui.ahk"
#Include "Lib\ManagerGui.ahk"
#Include "Lib\Actions_DateTime.ahk"
#Include "Lib\Actions_Text.ahk"
#Include "Lib\Actions_Email.ahk"
#Include "Lib\Actions_Math.ahk"
#Include "Lib\Actions_Utility.ahk"
#Include "Lib\Actions_Extraction.ahk"
#Include "Lib\Actions_Finance.ahk"
#Include "Lib\ActionBoardGui.ahk"

; Initialize
RegisterDateTimeActions()
RegisterTextActions()
RegisterEmailActions()
RegisterMathActions()
RegisterUtilityActions()
RegisterExtractionActions()
RegisterFinanceActions()
RegisterActionBoardActions()
LoadCustomSnippets()
InitActionBoardEngine()

; 1. Capture Default Command Palette
ShowCommandPalette()
Sleep(700)
SaveWindowScreenshot(PaletteGui.Hwnd, outputDir . "\01_Command_Palette_Default.png")
PaletteGui.Hide()
Sleep(300)

; 2. Capture Filtered Search Palette (e.g. query "gst")
ShowCommandPalette()
PaletteSearch.Value := "gst"
FilterPaletteItems("gst")
Sleep(700)
SaveWindowScreenshot(PaletteGui.Hwnd, outputDir . "\02_Command_Palette_Search_Filtered.png")
PaletteGui.Hide()
Sleep(300)

; 3. Capture Action Board (Eisenhower Matrix)
ToggleActionBoard()
Sleep(900)
SaveWindowScreenshot(ActionBoardGui.Hwnd, outputDir . "\03_Action_Board_Eisenhower_Matrix.png")
Sleep(300)

; 4. Capture Task Details Modal
ShowFullTaskViewModal()
Sleep(700)
if IsObject(TaskModalGui)
    SaveWindowScreenshot(TaskModalGui.Hwnd, outputDir . "\04_Task_Details_Modal.png")
if IsObject(TaskModalGui)
    TaskModalGui.Destroy()
ActionBoardGui.Hide()
Sleep(300)

; 5. Capture Visual Snippet Manager
ToggleManagerGui()
Sleep(900)
SaveWindowScreenshot(ManagerGui.Hwnd, outputDir . "\05_Visual_Snippet_Manager.png")
ManagerGui.Destroy()

ExitApp()

; --- Native GDI+ High-Resolution Window Capture ---
SaveWindowScreenshot(hwnd, filePath) {
    pToken := 0
    si := Buffer(16, 0)
    NumPut("uint", 1, si, 0)
    DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken, "ptr", si, "ptr", 0)
    
    rect := Buffer(16, 0)
    res := DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", rect, "uint", 16)
    if (res != 0)
        DllCall("user32\GetWindowRect", "ptr", hwnd, "ptr", rect)
        
    x := NumGet(rect, 0, "int")
    y := NumGet(rect, 4, "int")
    w := NumGet(rect, 8, "int") - x
    h := NumGet(rect, 12, "int") - y
    
    if (w <= 0 || h <= 0)
        return
        
    hDC := DllCall("user32\GetDC", "ptr", 0, "ptr")
    mDC := DllCall("gdi32\CreateCompatibleDC", "ptr", hDC, "ptr")
    hBM := DllCall("gdi32\CreateCompatibleBitmap", "ptr", hDC, "int", w, "int", h, "ptr")
    oBM := DllCall("gdi32\SelectObject", "ptr", mDC, "ptr", hBM, "ptr")
    DllCall("gdi32\BitBlt", "ptr", mDC, "int", 0, "int", 0, "int", w, "int", h, "ptr", hDC, "int", x, "int", y, "uint", 0x00CC0020)
    
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBM, "ptr", 0, "ptr*", &pBitmap)
    
    pngClsid := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", pngClsid)
    
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", filePath, "ptr", pngClsid, "ptr", 0)
    
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    DllCall("gdi32\SelectObject", "ptr", mDC, "ptr", oBM)
    DllCall("gdi32\DeleteObject", "ptr", hBM)
    DllCall("gdi32\DeleteDC", "ptr", mDC)
    DllCall("user32\ReleaseDC", "ptr", 0, "ptr", hDC)
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
}
