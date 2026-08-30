#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)

; ======================================================================================================================
; Title:   Office Productivity Command Palette & Snippet Suite
; Version: 1.0.0 (Production Release)
; AHK Ver: v2.0+
; OS:      Windows 10 / 11
;
; Core Purpose:
; A bulletproof, keyboard-driven Windows office productivity hub that unifies 50+ essential tools,
; instant date/text/math transformations, and on-the-fly snippet expansion into a fast, non-blocking
; Command Palette and Leader-Key interface.
; ======================================================================================================================

global AppTitle          := "Office Productivity Hub"
global AppVersion        := "1.0.0"
global DataDir           := A_ScriptDir
global SnippetsFile      := DataDir . "\office_productivity_snippets.csv"
global ErrorLogFile      := DataDir . "\office_productivity_errors.log"

; In-Memory Collections
global BuiltInActions    := []
global CustomSnippets    := []
global RegisteredTriggers := Map()

; GUI Handles
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

InitApp()

InitApp() {
    try {
        BuildCatalog()
        LoadCustomSnippets()
        RegisterDynamicHotstrings()
    } catch as err {
        LogAppError("InitApp", err)
        MsgBox("Failed to initialize Office Productivity Hub:`n`n" . err.Message, AppTitle . " - Init Error", "Icon!")
    }
}

; Global Hotkeys
^Space::ShowCommandPalette()
^+h::CaptureSelectedTextAsSnippet()
#Esc::ToggleManagerGui()

#HotIf !WinActive("ahk_exe EXCEL.EXE")
^;::ActivateLeaderKey()
#HotIf

#HotIf IsPaletteActive()
    Up::PaletteNavigate(-1)
    Down::PaletteNavigate(1)
    Enter::PaletteExecuteSelection()
    Escape::CloseCommandPalette()
#HotIf

#HotIf IsManagerActive()
    Del::ManagerDeleteItem()
    F2::ManagerEditItem()
#HotIf

BuildCatalog() {
    global BuiltInActions := []

    ; Category 1: Date & Time (10)
    RegisterAction("Today's ISO Date", "Date/Time", "Inserts YYYY-MM-DD (e.g. " . FormatTime(A_Now, "yyyy-MM-dd") . ")", "date, today, iso", (*) => InsertText(FormatTime(A_Now, "yyyy-MM-dd")), "d")
    RegisterAction("Compact File Timestamp", "Date/Time", "Inserts YYMMDD_HHMMSS (e.g. " . FormatTime(A_Now, "yyMMdd_HHmmss") . ")", "timestamp, time, compact, file", (*) => InsertText(FormatTime(A_Now, "yyMMdd_HHmmss")), "t")
    RegisterAction("Formal Long Date", "Date/Time", "Inserts full day and date (e.g. " . FormatTime(A_Now, "dddd, MMMM d, yyyy") . ")", "long, date, formal, day", (*) => InsertText(FormatTime(A_Now, "dddd, MMMM d, yyyy")))
    RegisterAction("Current Time (12-Hour AM/PM)", "Date/Time", "Inserts 12-hour time (e.g. " . FormatTime(A_Now, "hh:mm tt") . ")", "time, 12h, clock, am, pm", (*) => InsertText(FormatTime(A_Now, "hh:mm tt")))
    RegisterAction("Current Time (24-Hour with Seconds)", "Date/Time", "Inserts 24-hour time (e.g. " . FormatTime(A_Now, "HH:mm:ss") . ")", "time, 24h, clock, seconds", (*) => InsertText(FormatTime(A_Now, "HH:mm:ss")))
    RegisterAction("Tomorrow's Date", "Date/Time", "Calculates and inserts tomorrow's date", "tomorrow, future, next, date", (*) => InsertText(GetOffsetDate(1)))
    RegisterAction("Yesterday's Date", "Date/Time", "Calculates and inserts yesterday's date", "yesterday, past, prev, date", (*) => InsertText(GetOffsetDate(-1)))
    RegisterAction("Current ISO Week Number", "Date/Time", "Inserts Week number & Year (e.g. Week " . FormatTime(A_Now, "YWeek") . ")", "week, iso, sprint, workweek", (*) => InsertText("Week " . SubStr(FormatTime(A_Now, "YWeek"), 5) . ", " . FormatTime(A_Now, "yyyy")))
    RegisterAction("Current Month & Year", "Date/Time", "Inserts Month Year (e.g. " . FormatTime(A_Now, "MMMM yyyy") . ")", "month, year, period", (*) => InsertText(FormatTime(A_Now, "MMMM yyyy")))
    RegisterAction("Work Week Date Range", "Date/Time", "Inserts Monday to Friday range for current week", "range, week, monday, friday", (*) => InsertText(GetCurrentWorkWeekRange()))

    ; Category 2: Text Transformations (10)
    RegisterAction("Paste Clean Plain Text", "Transform", "Strips HTML, colors, font sizes, and trims excess whitespace", "plain, clean, strip, paste, unformat", (*) => TransformSelectedText((txt) => Trim(txt)), "v")
    RegisterAction("Convert to UPPERCASE", "Transform", "Converts selected text to ALL CAPS", "upper, caps, case, uppercase", (*) => TransformSelectedText((txt) => StrUpper(txt)), "u")
    RegisterAction("Convert to lowercase", "Transform", "Converts selected text to all lowercase", "lower, case, lowercase", (*) => TransformSelectedText((txt) => StrLower(txt)), "l")
    RegisterAction("Convert to Title Case", "Transform", "Capitalizes The First Letter Of Every Word", "title, capitalize, case, headline", (*) => TransformSelectedText((txt) => StrTitle(txt)))
    RegisterAction("Convert to Sentence case", "Transform", "Capitalizes the first letter of each sentence", "sentence, case, grammar", (*) => TransformSelectedText((txt) => ToSentenceCase(txt)))
    RegisterAction("Convert to snake_case", "Transform", "Converts text to snake_case_format", "snake, case, underscore, code", (*) => TransformSelectedText((txt) => ToDelimitedCase(txt, "_")))
    RegisterAction("Convert to kebab-case", "Transform", "Converts text to kebab-case-format", "kebab, case, dash, slug", (*) => TransformSelectedText((txt) => ToDelimitedCase(txt, "-")))
    RegisterAction("Convert to camelCase", "Transform", "Converts text to camelCaseFormat", "camel, case, identifier, code", (*) => TransformSelectedText((txt) => ToCamelCase(txt)))
    RegisterAction("Quote Every Line (SQL IN format)", "Transform", "Wraps each line in 'quotes' separated by commas", "sql, quote, in, list, csv", (*) => TransformSelectedText((txt) => FormatSqlInList(txt)))
    RegisterAction("Join Lines into Single Paragraph", "Transform", "Removes hard PDF/web line breaks into a clean paragraph", "join, unwrapper, paragraph, pdf, single line", (*) => TransformSelectedText((txt) => RegExReplace(txt, "\R+", " ")))

    ; Category 3: Professional Email (10)
    RegisterAction("Email: Please Find Attached (PFA)", "Email", "Please find the requested file(s) attached for your review.", "pfa, attach, attachment, email, review", (*) => InsertText("Please find the requested file(s) attached for your review."))
    RegisterAction("Email: Acknowledgment & Follow-Up", "Email", "Acknowledged with thanks. I am reviewing this and will update you shortly.", "ack, acknowledge, thanks, email, received", (*) => InsertText("Acknowledged with thanks. I am reviewing this and will update you shortly."))
    RegisterAction("Email: Meeting Availability Request", "Email", "Could you please share your availability for a brief sync this week?", "meeting, sync, call, availability, schedule", (*) => InsertText("Could you please share your availability for a brief sync this week?"))
    RegisterAction("Email: Gentle Follow-Up / Reminder", "Email", "Just following up on my previous note to check if there are any updates.", "followup, reminder, ping, gentle, status", (*) => InsertText("Just following up on my previous note to check if there are any updates on this."))
    RegisterAction("Email: Out of Office Notice", "Email", "Standard professional out-of-office message template", "ooo, out of office, vacation, leave, away", (*) => InsertText("Thank you for your email. I am currently out of the office with limited access to email. I will respond to your message as soon as possible upon my return."))
    RegisterAction("Email: Formal Business Greeting", "Email", "Inserts 'Dear [Name],' greeting", "greeting, dear, hello, salutation", (*) => InsertText("Dear [Name],`n`n"))
    RegisterAction("Email: Formal Sign-Off", "Email", "Inserts 'Best regards,' with signature placeholder", "regards, signoff, closing, signature", (*) => InsertText("Best regards,`n`n[Your Name]`n[Your Title]"))
    RegisterAction("Email: Action Required Notice", "Email", "ACTION REQUIRED: Please review and approve by EOD.", "action, required, urgent, approve, eod", (*) => InsertText("ACTION REQUIRED: Please review and confirm by EOD."))
    RegisterAction("Email: Handover / Delegation Note", "Email", "I am looping in [Name] who will assist you further with this request.", "handover, loop, delegate, introduce", (*) => InsertText("I am looping in [Name] who will assist you further with this request."))
    RegisterAction("Email: Appreciation Note", "Email", "Thank you for your prompt assistance and support on this matter.", "appreciation, thank you, gratitude, support", (*) => InsertText("Thank you for your prompt assistance and support on this matter."))

    ; Category 4: Math & Conversions (10)
    RegisterAction("Evaluate Math Expression", "Math", "Evaluates selected math formula (e.g. 1500 * 1.18 + 450)", "calc, math, evaluate, formula, compute", (*) => EvaluateMathSelection(), "c")
    RegisterAction("GST / Tax Breakdown (18%)", "Math", "Calculates Base + 18% Tax + Total for selected number", "gst, tax, 18%, vat, breakdown", (*) => CalculateTaxBreakdown(18))
    RegisterAction("Percentage Difference Calculator", "Math", "Calculates % change between two selected numbers", "percent, percentage, change, growth, delta", (*) => CalculatePercentageDelta())
    RegisterAction("Generate 16-Char Secure Password", "Math", "Generates and inserts a high-entropy random password", "password, secure, random, pass, generate", (*) => InsertText(GenerateSecurePassword(16)))
    RegisterAction("Generate UUID / GUID v4", "Math", "Generates a standard UUID v4 string", "uuid, guid, id, unique", (*) => InsertText(GenerateUUID()))
    RegisterAction("Word & Character Counter", "Math", "Shows word, character, and line count for selected text", "count, words, characters, stats, length", (*) => ShowTextStats())
    RegisterAction("Format Number with Commas", "Math", "Formats selected digits with standard comma thousands separators", "comma, format, number, digits, currency", (*) => TransformSelectedText((txt) => FormatNumberCommas(txt)))
    RegisterAction("Round Number to 2 Decimals", "Math", "Rounds selected float number to 2 decimal places", "round, decimal, precision, float", (*) => TransformSelectedText((txt) => RoundNumber(txt, 2)))
    RegisterAction("Sum Column of Selected Numbers", "Math", "Calculates total sum of all numbers in selected text", "sum, total, add, column, numbers", (*) => SumSelectedNumbers())
    RegisterAction("Unix Timestamp to Readable Date", "Math", "Converts selected Unix epoch seconds to human date/time", "unix, epoch, convert, time, timestamp", (*) => ConvertUnixTimestamp())

    ; Category 5: File & System Utilities (10)
    RegisterAction("Copy Clean File Path (Forward Slashes)", "Utility", "Converts clipboard/selection file path to C:/Folder/File format", "path, forward, slash, url, linux, copy", (*) => ConvertClipboardPath("/"))
    RegisterAction("Copy Clean File Path (Escaped Slashes)", "Utility", "Converts clipboard/selection file path to C:\\Folder\\File format", "path, escaped, double, backslash, json, code", (*) => ConvertClipboardPath("\\"))
    RegisterAction("Prefix Selected File with Timestamp", "Utility", "Renames selected file in Explorer with YYMMDD_ prefix", "rename, prefix, explorer, file, timestamp", (*) => PrefixExplorerSelectedFile())
    RegisterAction("Google Search Selected Text", "Utility", "Opens default browser searching selected term", "search, google, web, query, lookup", (*) => SearchWebSelection("https://www.google.com/search?q="))
    RegisterAction("Google Translate Selected Text", "Utility", "Opens Google Translate for selected text", "translate, language, dict, meaning", (*) => SearchWebSelection("https://translate.google.com/?text="))
    RegisterAction("Toggle Window Always-on-Top", "Utility", "Pins or unpins active window to always stay visible", "pin, top, always on top, float, window", (*) => ToggleAlwaysOnTop())
    RegisterAction("Toggle Window Transparency (75%)", "Utility", "Toggles semi-transparency on active window for comparing docs", "transparent, opacity, ghost, trace, window", (*) => ToggleWindowTransparency())
    RegisterAction("Open Today's Daily Scratchpad Notes", "Utility", "Opens a timestamped daily text file for notes", "scratchpad, notes, daily, journal, memo", (*) => OpenDailyScratchpad())
    RegisterAction("Empty Windows Recycle Bin", "Utility", "Silently purges all items from Windows Recycle Bin", "recycle, bin, trash, clean, empty, purge", (*) => SilentEmptyRecycleBin())
    RegisterAction("Quick Privacy Screen / Lock", "Utility", "Instantly locks the Windows workstation", "lock, privacy, screen, secure, workstation", (*) => DllCall("LockWorkStation"))
}

RegisterAction(name, category, description, keywords, callback, chord := "") {
    BuiltInActions.Push({
        name: name,
        category: category,
        description: description,
        keywords: keywords,
        callback: callback,
        chord: chord,
        isCustom: false
    })
}

ShowCommandPalette() {
    global PaletteGui, PaletteSearch, PaletteListView, PaletteStatus, TargetWindowHwnd
    TargetWindowHwnd := WinActive("A")

    if IsObject(PaletteGui) {
        PaletteSearch.Value := ""
        FilterPaletteItems("")
        CenterGuiOnActiveMonitor(PaletteGui, 680, 420)
        PaletteGui.Show()
        PaletteSearch.Focus()
        return
    }

    PaletteGui := Gui("+AlwaysOnTop -Caption +Border +ToolWindow")
    PaletteGui.Title := "Command Palette"
    PaletteGui.BackColor := "0x1E1E1E"
    PaletteGui.SetFont("s11 cWhite", "Segoe UI")

    PaletteSearch := PaletteGui.Add("Edit", "x12 y12 w656 h32 Background2D2D2D cFFFFFF -E0x200")
    PaletteSearch.OnEvent("Change", (ctrl, *) => FilterPaletteItems(ctrl.Value))

    PaletteGui.SetFont("s10 cWhite", "Segoe UI")
    PaletteListView := PaletteGui.AddListView("x12 y52 w656 h320 Background252526 cFFFFFF -Multi -Hdr +LV0x14000", ["Name", "Category", "Description", "Chord"])
    PaletteListView.OnEvent("DoubleClick", (*) => PaletteExecuteSelection())

    PaletteGui.SetFont("s9 c888888", "Segoe UI")
    PaletteStatus := PaletteGui.Add("Text", "x14 y380 w650 h24", "Arrows: Navigate | Enter: Execute | Esc: Dismiss | Ctrl+N: Add Snippet")

    FilterPaletteItems("")
    CenterGuiOnActiveMonitor(PaletteGui, 680, 412)
    PaletteGui.Show()
    PaletteSearch.Focus()
}

FilterPaletteItems(query) {
    global BuiltInActions, CustomSnippets, PaletteListView, PaletteItems, PaletteStatus
    if !IsObject(PaletteListView)
        return

    PaletteListView.Delete()
    PaletteItems := []
    qLower := StrLower(Trim(query))

    Matches(item) {
        if (qLower = "")
            return true
        return InStr(StrLower(item.name), qLower) 
            || InStr(StrLower(item.category), qLower) 
            || InStr(StrLower(item.description), qLower)
            || (item.HasOwnProp("keywords") && InStr(StrLower(item.keywords), qLower))
    }

    for act in BuiltInActions {
        if Matches(act) {
            PaletteItems.Push(act)
            chordDisplay := act.chord ? ("[" . act.chord . "]") : ""
            PaletteListView.Add("", act.name, act.category, act.description, chordDisplay)
        }
    }

    for snip in CustomSnippets {
        if (snip.enabled) {
            snipObj := {
                name: "Snippet: " . snip.trigger,
                category: "Snippet",
                description: StrReplace(SubStr(snip.replacement, 1, 60), "`n", " \ "),
                keywords: snip.trigger . " snippet " . snip.replacement,
                callback: ((r) => (*) => InsertText(r))(snip.replacement),
                chord: "",
                isCustom: true
            }
            if Matches(snipObj) {
                PaletteItems.Push(snipObj)
                PaletteListView.Add("", snipObj.name, snipObj.category, snipObj.description, "")
            }
        }
    }

    if (PaletteItems.Length > 0)
        PaletteListView.Modify(1, "Select Focus")

    try {
        PaletteListView.ModifyCol(1, 230)
        PaletteListView.ModifyCol(2, 100)
        PaletteListView.ModifyCol(3, 275)
        PaletteListView.ModifyCol(4, 45)
    }

    if IsObject(PaletteStatus)
        PaletteStatus.Text := "Showing " . PaletteItems.Length . " tools | Enter to Execute | Esc to Dismiss"
}

PaletteNavigate(direction) {
    global PaletteListView, PaletteItems
    if (!IsObject(PaletteListView) || PaletteItems.Length = 0)
        return
    cur := PaletteListView.GetNext()
    nextRow := cur = 0 ? 1 : (cur + direction)
    if (nextRow < 1)
        nextRow := PaletteItems.Length
    else if (nextRow > PaletteItems.Length)
        nextRow := 1
    PaletteListView.Modify(0, "-Select -Focus")
    PaletteListView.Modify(nextRow, "Select Focus Vis")
}

PaletteExecuteSelection() {
    global PaletteListView, PaletteItems, PaletteGui, TargetWindowHwnd
    if (!IsObject(PaletteListView) || PaletteItems.Length = 0)
        return
    selectedRow := PaletteListView.GetNext()
    if (!selectedRow || selectedRow > PaletteItems.Length)
        return

    item := PaletteItems[selectedRow]
    PaletteGui.Hide()

    if (TargetWindowHwnd && WinExist(TargetWindowHwnd)) {
        WinActivate(TargetWindowHwnd)
        Sleep(40)
    }

    try {
        item.callback.Call()
    } catch as err {
        LogAppError("PaletteExecuteSelection (" . item.name . ")", err)
        ShowToast("Action Error: " . err.Message, 2500)
    }
}

CloseCommandPalette() {
    global PaletteGui, TargetWindowHwnd
    if IsObject(PaletteGui)
        PaletteGui.Hide()
    if (TargetWindowHwnd && WinExist(TargetWindowHwnd))
        WinActivate(TargetWindowHwnd)
}

IsPaletteActive() {
    global PaletteGui
    try {
        if IsObject(PaletteGui) && WinActive(PaletteGui.Hwnd)
            return true
    }
    return false
}

ActivateLeaderKey() {
    global LeaderActive, BuiltInActions
    LeaderActive := true

    ToolTip("[Leader Mode] Press: d=Date | t=Time | u=Upper | l=Lower | c=Calc | v=PasteRaw | ?=Help")
    
    ih := InputHook("L1 T1.5 C")
    ih.Start()
    ih.Wait()
    
    ToolTip()
    LeaderActive := false

    if (ih.EndReason != "EndKey" && ih.EndReason != "Max")
        return

    key := StrLower(ih.Input)
    if (key = "" || key = "`e")
        return

    if (key = "?") {
        ShowCommandPalette()
        return
    }

    for act in BuiltInActions {
        if (act.chord != "" && StrLower(act.chord) = key) {
            try {
                act.callback.Call()
            } catch as err {
                LogAppError("LeaderChord (" . act.name . ")", err)
            }
            return
        }
    }

    ShowToast("Unknown Leader Key: '" . key . "' (Press '?' for Palette)", 2000)
}

CaptureSelectedTextAsSnippet() {
    global CustomSnippets

    selectedText := SafeGetSelection()
    if (Trim(selectedText) = "") {
        MsgBox("Please highlight/select the text snippet you want to save first.", AppTitle, "Icon!")
        return
    }

    inputBox := InputBox("Enter a short trigger keyword for this snippet (e.g. 'supmail'):`n`nSnippet Preview:`n" . SubStr(selectedText, 1, 100) . "...", "Save Snippet As Hotstring", "w420 h220")
    if (inputBox.Result != "OK" || Trim(inputBox.Value) = "")
        return

    trigger := Trim(inputBox.Value)

    for snip in CustomSnippets {
        if (StrLower(snip.trigger) = StrLower(trigger)) {
            MsgBox("Trigger '" . trigger . "' already exists. Please choose a unique name.", AppTitle, "Icon!")
            return
        }
    }

    CustomSnippets.Push({trigger: trigger, replacement: selectedText, enabled: true})
    SaveCustomSnippets()
    RegisterDynamicHotstrings()
    ShowToast("Snippet '" . trigger . "' saved & active!", 2500)
}

ToggleManagerGui() {
    global ManagerGui
    if IsObject(ManagerGui) {
        if WinActive(ManagerGui.Hwnd) {
            ManagerGuiClose(ManagerGui)
            return
        }
        ManagerGui.Show()
        return
    }
    CreateManagerGui()
}

CreateManagerGui() {
    global ManagerGui, ManagerListView, ManagerSearch, ManagerStatus, ManagerPos

    ManagerGui := Gui("+Resize +MinSize680x360")
    ManagerGui.Title := "Text Replacement & Snippet Manager"
    ManagerGui.SetFont("s9", "Segoe UI")
    
    ManagerGui.OnEvent("Close", (g) => ManagerGuiClose(g))
    ManagerGui.OnEvent("Size", (g, m, w, h) => ManagerGuiSize(g, m, w, h))

    ManagerGui.Add("Text", "x12 y12 w55", "Filter:")
    ManagerSearch := ManagerGui.Add("Edit", "x72 y9 w596 h24 vSearchFilter", "")
    ManagerSearch.OnEvent("Change", (ctrl, *) => RefreshManagerListView(ctrl.Value))

    ManagerListView := ManagerGui.AddListView("x12 y40 w656 h280 Grid -Multi", ["Trigger", "Replacement Text", "Enabled"])
    ManagerListView.OnEvent("DoubleClick", (*) => ManagerEditItem())

    ManagerGui.AddButton("x12 y335 w75 h30 vBtnAdd", "Add").OnEvent("Click", (*) => ManagerAddItem())
    ManagerGui.AddButton("x92 y335 w75 h30 vBtnEdit", "Edit").OnEvent("Click", (*) => ManagerEditItem())
    ManagerGui.AddButton("x172 y335 w75 h30 vBtnDel", "Delete").OnEvent("Click", (*) => ManagerDeleteItem())
    ManagerGui.AddButton("x252 y335 w75 h30 vBtnToggle", "Toggle").OnEvent("Click", (*) => ManagerToggleItem())

    ManagerGui.AddButton("x435 y335 w75 h30 vBtnImport", "Import").OnEvent("Click", (*) => ManagerImportData())
    ManagerGui.AddButton("x515 y335 w75 h30 vBtnExport", "Export").OnEvent("Click", (*) => ManagerExportData())
    ManagerGui.AddButton("x595 y335 w75 h30 vBtnHelp", "Help").OnEvent("Click", (*) => ShowProductivityHelp())

    ManagerStatus := ManagerGui.Add("StatusBar",, "Ready")

    RefreshManagerListView()

    w := Max(680, ManagerPos.w)
    h := Max(360, ManagerPos.h)
    CenterGuiOnActiveMonitor(ManagerGui, w, h)
    ManagerGui.Show("w" . w . " h" . h)
}

ManagerGuiClose(TheGui) {
    global ManagerPos
    local x, y, w, h
    TheGui.GetPos(&x, &y, &w, &h)
    ManagerPos.x := x
    ManagerPos.y := y
    ManagerPos.w := w
    ManagerPos.h := h
    TheGui.Hide()
}

ManagerGuiSize(TheGui, MinMax, Width, Height) {
    global ManagerListView, ManagerSearch, ManagerStatus
    if MinMax = -1
        return
    
    if IsObject(ManagerSearch)
        ManagerSearch.Move(,, Width - 84)
    
    if IsObject(ManagerListView) {
        ManagerListView.Move(,, Width - 24, Max(80, Height - 125))
        try {
            col1W := 95
            col3W := 65
            col2W := Max(120, Width - 24 - col1W - col3W - 28)
            ManagerListView.ModifyCol(1, col1W)
            ManagerListView.ModifyCol(3, col3W)
            ManagerListView.ModifyCol(2, col2W)
        }
    }

    btnY := Height - 65
    try {
        TheGui["BtnAdd"].Move(12, btnY)
        TheGui["BtnEdit"].Move(92, btnY)
        TheGui["BtnDel"].Move(172, btnY)
        TheGui["BtnToggle"].Move(252, btnY)

        TheGui["BtnImport"].Move(Width - 245, btnY)
        TheGui["BtnExport"].Move(Width - 165, btnY)
        TheGui["BtnHelp"].Move(Width - 85, btnY)
    }
}

RefreshManagerListView(filter := "") {
    global ManagerListView, ManagerSearch, CustomSnippets, ManagerStatus
    if !IsObject(ManagerListView)
        return

    ManagerListView.Delete()
    filterLower := StrLower(Trim(filter))
    matchCount := 0

    for Item in CustomSnippets {
        if (filterLower != "") {
            if (!InStr(StrLower(Item.trigger), filterLower) && !InStr(StrLower(Item.replacement), filterLower))
                continue
        }
        matchCount++
        enText := Item.enabled ? "Yes" : "No"
        prev := StrLen(Item.replacement) > 70 ? SubStr(Item.replacement, 1, 67) . "..." : Item.replacement
        prev := StrReplace(prev, "`n", " \ ")
        ManagerListView.Add("", Item.trigger, prev, enText)
    }

    if IsObject(ManagerStatus) {
        if (filterLower != "")
            ManagerStatus.SetText("Filter: '" . filter . "' - Showing " . matchCount . " of " . CustomSnippets.Length . " snippets")
        else
            ManagerStatus.SetText("Ready - Total snippets: " . CustomSnippets.Length)
    }
}

ManagerAddItem() {
    global ManagerSearch, CustomSnippets
    res := ShowSnippetEditDialog()
    if (res.OK) {
        for Item in CustomSnippets {
            if (StrLower(Item.trigger) = StrLower(res.Trigger)) {
                MsgBox("Trigger '" . res.Trigger . "' already exists. Choose a unique one.", AppTitle, "Icon!")
                return
            }
        }
        CustomSnippets.Push({trigger: res.Trigger, replacement: res.Replacement, enabled: res.Enabled})
        SaveCustomSnippets()
        RegisterDynamicHotstrings()
        RefreshManagerListView(IsObject(ManagerSearch) ? ManagerSearch.Value : "")
    }
}

ManagerEditItem() {
    global ManagerListView, ManagerSearch, CustomSnippets
    selRow := ManagerListView.GetNext()
    if (!selRow) {
        MsgBox("Please select an item to edit.", AppTitle, "Icon!")
        return
    }

    triggerText := ManagerListView.GetText(selRow, 1)
    targetIdx := 0
    for idx, Item in CustomSnippets {
        if (Item.trigger = triggerText) {
            targetIdx := idx
            break
        }
    }
    if (targetIdx = 0)
        targetIdx := selRow

    item := CustomSnippets[targetIdx]
    res := ShowSnippetEditDialog(item.trigger, item.replacement, item.enabled)

    if (res.OK) {
        for idx, chk in CustomSnippets {
            if (idx != targetIdx && StrLower(chk.trigger) = StrLower(res.Trigger)) {
                MsgBox("Trigger '" . res.Trigger . "' already exists. Choose a unique one.", AppTitle, "Icon!")
                return
            }
        }
        CustomSnippets[targetIdx] := {trigger: res.Trigger, replacement: res.Replacement, enabled: res.Enabled}
        SaveCustomSnippets()
        RegisterDynamicHotstrings()
        RefreshManagerListView(IsObject(ManagerSearch) ? ManagerSearch.Value : "")
    }
}

ManagerDeleteItem() {
    global ManagerListView, ManagerSearch, CustomSnippets
    selRow := ManagerListView.GetNext()
    if (!selRow) {
        MsgBox("Please select an item to delete.", AppTitle, "Icon!")
        return
    }

    triggerText := ManagerListView.GetText(selRow, 1)
    targetIdx := 0
    for idx, Item in CustomSnippets {
        if (Item.trigger = triggerText) {
            targetIdx := idx
            break
        }
    }
    if (targetIdx = 0)
        targetIdx := selRow

    if (MsgBox("Are you sure you want to delete trigger '" . CustomSnippets[targetIdx].trigger . "'?", "Confirm Delete", "YesNo Default2 Icon?") = "Yes") {
        CustomSnippets.RemoveAt(targetIdx)
        SaveCustomSnippets()
        RegisterDynamicHotstrings()
        RefreshManagerListView(IsObject(ManagerSearch) ? ManagerSearch.Value : "")
    }
}

ManagerToggleItem() {
    global ManagerListView, CustomSnippets
    selRow := ManagerListView.GetNext()
    if (!selRow) {
        MsgBox("Please select an item to toggle.", AppTitle, "Icon!")
        return
    }

    triggerText := ManagerListView.GetText(selRow, 1)
    targetIdx := 0
    for idx, Item in CustomSnippets {
        if (Item.trigger = triggerText) {
            targetIdx := idx
            break
        }
    }
    if (targetIdx = 0)
        targetIdx := selRow

    item := CustomSnippets[targetIdx]
    item.enabled := !item.enabled

    SaveCustomSnippets()
    RegisterDynamicHotstrings()

    enText := item.enabled ? "Yes" : "No"
    prev := StrLen(item.replacement) > 70 ? SubStr(item.replacement, 1, 67) . "..." : item.replacement
    prev := StrReplace(prev, "`n", " \ ")
    ManagerListView.Modify(selRow, "", item.trigger, prev, enText)
}

ShowSnippetEditDialog(initTrigger := "", initReplacement := "", initEnabled := true) {
    global ManagerGui
    ownerParam := IsObject(ManagerGui) ? ("+Owner" . ManagerGui.Hwnd) : ""
    editG := Gui(ownerParam)
    editG.Title := initTrigger ? "Edit Snippet" : "Add Snippet"
    editG.SetFont("s9", "Segoe UI")

    editG.AddText("x12 y10", "Trigger keyword (case-insensitive whole word):")
    trigCtrl := editG.AddEdit("x12 y30 w396 r1", initTrigger)

    editG.AddText("x12 y70", "Replacement Text (multi-line supported):")
    repCtrl := editG.AddEdit("x12 y90 w396 h130 VScroll", initReplacement)

    enCtrl := editG.AddCheckbox("x12 y230 Checked" . initEnabled, "Enabled")

    btnOk := editG.AddButton("x242 y260 w80 h30 Default", "OK")
    btnCancel := editG.AddButton("x328 y260 w80 h30", "Cancel")

    result := {OK: false, Trigger: "", Replacement: "", Enabled: true}

    OnOk(*) {
        if Trim(trigCtrl.Value) = "" {
            MsgBox("Trigger keyword cannot be empty.", AppTitle, "Icon!")
            return
        }
        result.OK := true
        result.Trigger := Trim(trigCtrl.Value)
        result.Replacement := repCtrl.Value
        result.Enabled := !!enCtrl.Value
        editG.Destroy()
    }

    OnCancel(*) => editG.Destroy()

    btnOk.OnEvent("Click", OnOk)
    btnCancel.OnEvent("Click", OnCancel)
    editG.OnEvent("Close", OnCancel)

    if IsObject(ManagerGui)
        ManagerGui.Opt("+Disabled")

    editG.Show("w420 h305")
    WinWaitClose(editG)

    if IsObject(ManagerGui) {
        ManagerGui.Opt("-Disabled")
        ManagerGui.Show()
    }

    return result
}

ManagerImportData() {
    global SnippetsFile, CustomSnippets
    importPath := FileSelect(1, , "Import Snippets from CSV", "CSV Files (*.csv)")
    if !importPath
        return

    try {
        backup := CustomSnippets.Clone()
        content := FileRead(importPath, "UTF-8")
        rows := ParseFullCSV(content)
        imported := []

        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "trigger")
                continue
            if (row.Length >= 3) {
                t := Trim(row[1])
                if (t = "")
                    continue
                r := StrReplace(row[2], "\n", "`n")
                e := (StrLower(Trim(row[3])) = "true" || Trim(row[3]) = "1")
                imported.Push({trigger: t, replacement: r, enabled: e})
            }
        }

        CustomSnippets := imported
        SaveCustomSnippets()
        RegisterDynamicHotstrings()
        RefreshManagerListView()
        MsgBox("Successfully imported " . imported.Length . " snippets!", AppTitle, "Iconi")
    } catch as err {
        CustomSnippets := backup
        LogAppError("ManagerImportData", err)
        MsgBox("Import failed: " . err.Message, AppTitle . " - Import Error", "Icon!")
    }
}

ManagerExportData() {
    global SnippetsFile
    exportPath := FileSelect("S", "office_snippets_backup_" . FormatTime(A_Now, "yyMMdd") . ".csv", "Export Snippets to CSV", "CSV Files (*.csv)")
    if !exportPath
        return
    try {
        FileCopy(SnippetsFile, exportPath, 1)
        MsgBox("Data exported successfully to:`n" . exportPath, AppTitle, "Iconi")
    } catch as err {
        LogAppError("ManagerExportData", err)
        MsgBox("Export error: " . err.Message, AppTitle . " - Export Error", "Icon!")
    }
}

IsManagerActive() {
    global ManagerGui
    try {
        if IsObject(ManagerGui) && WinActive(ManagerGui.Hwnd)
            return true
    }
    return false
}

InsertText(text) {
    if (text = "")
        return
    try {
        Sleep(30)
        clipBackup := ClipboardAll()
        
        A_Clipboard := text
        if ClipWait(0.6) {
            SendInput("{Shift Down}{Insert}{Shift Up}")
            Sleep(120)
        }
        A_Clipboard := clipBackup
    } catch as err {
        LogAppError("InsertText", err)
        SendText(text)
    }
}

TransformSelectedText(transformerFunc) {
    selText := SafeGetSelection()
    if (selText = "") {
        ShowToast("No text highlighted to transform!", 2000)
        return
    }
    try {
        newText := transformerFunc.Call(selText)
        InsertText(newText)
    } catch as err {
        LogAppError("TransformSelectedText", err)
        ShowToast("Transformation Error: " . err.Message, 2500)
    }
}

SafeGetSelection() {
    clipBackup := ClipboardAll()
    A_Clipboard := ""
    
    SendInput("^{vk43}") ; Ctrl + C
    
    if !ClipWait(0.4) {
        A_Clipboard := clipBackup
        return ""
    }
    
    sel := A_Clipboard
    A_Clipboard := clipBackup
    return sel
}

LoadCustomSnippets() {
    global CustomSnippets, SnippetsFile
    CustomSnippets := []

    if !FileExist(SnippetsFile) {
        CustomSnippets.Push({trigger: "myemail", replacement: "john.doe@example.com", enabled: true})
        CustomSnippets.Push({trigger: "myphone", replacement: "+1 (555) 123-4567", enabled: true})
        CustomSnippets.Push({trigger: "myaddr", replacement: "123 Main Street`nAnytown, ST 12345`nUSA", enabled: true})
        SaveCustomSnippets()
        return
    }

    try {
        content := FileRead(SnippetsFile, "UTF-8")
        rows := ParseFullCSV(content)

        for rIdx, row in rows {
            if (rIdx = 1 && row.Length >= 1 && StrLower(Trim(row[1])) = "trigger")
                continue
            if (row.Length >= 3) {
                t := Trim(row[1])
                if (t = "")
                    continue
                r := StrReplace(row[2], "\n", "`n")
                e := (StrLower(Trim(row[3])) = "true" || Trim(row[3]) = "1")
                CustomSnippets.Push({trigger: t, replacement: r, enabled: e})
            }
        }
    } catch as err {
        LogAppError("LoadCustomSnippets", err)
    }
}

SaveCustomSnippets() {
    global CustomSnippets, SnippetsFile
    local content := "trigger,replacement,enabled`n"
    local tempFile := SnippetsFile . ".tmp"
    local fileObj := ""
    local writeOk := false

    for snip in CustomSnippets {
        local trigEsc := '"' . StrReplace(snip.trigger, '"', '""') . '"'
        local repEsc := '"' . StrReplace(StrReplace(snip.replacement, '"', '""'), "`n", "\n") . '"'
        local enStr := snip.enabled ? "true" : "false"
        content .= trigEsc . "," . repEsc . "," . enStr . "`n"
    }

    try {
        fileObj := FileOpen(tempFile, "w", "UTF-8")
        if !IsObject(fileObj)
            throw Error("Cannot create temporary snippets file")
        fileObj.Write(content)
        writeOk := true
    } catch as err {
        LogAppError("SaveCustomSnippets", err)
    } finally {
        if IsObject(fileObj)
            fileObj.Close()
    }

    if writeOk {
        if FileExist(SnippetsFile)
            FileDelete(SnippetsFile)
        FileMove(tempFile, SnippetsFile)
    }
}

ParseFullCSV(csvContent) {
    local rows := []
    local curRow := []
    local curField := ""
    local inQuotes := false
    local chars := StrSplit(csvContent)
    local i := 1
    local len := chars.Length

    while i <= len {
        local ch := chars[i]
        if (ch = '"') {
            if (inQuotes && i < len && chars[i + 1] = '"') {
                curField .= '"'
                i++
            } else {
                inQuotes := !inQuotes
            }
        } else if (ch = ',' && !inQuotes) {
            curRow.Push(curField)
            curField := ""
        } else if ((ch = "`n" || ch = "`r") && !inQuotes) {
            if (ch = "`r" && i < len && chars[i + 1] = "`n")
                i++
            curRow.Push(curField)
            if (curRow.Length > 0 && (curRow.Length > 1 || curRow[1] != ""))
                rows.Push(curRow)
            curRow := []
            curField := ""
        } else {
            curField .= ch
        }
        i++
    }
    if (curField != "" || curRow.Length > 0) {
        curRow.Push(curField)
        if (curRow.Length > 1 || curRow[1] != "")
            rows.Push(curRow)
    }
    return rows
}

RegisterDynamicHotstrings() {
    global RegisteredTriggers, CustomSnippets
    Hotstring("Reset")

    for trig in RegisteredTriggers {
        try {
            Hotstring(":X C0:" . trig, , 0)
        }
    }
    RegisteredTriggers.Clear()

    for snip in CustomSnippets {
        if (snip.enabled && snip.trigger != "") {
            try {
                Hotstring(":X C0:" . snip.trigger, HotstringCallback.Bind(snip.replacement), 1)
                RegisteredTriggers[snip.trigger] := true
            } catch as err {
                LogAppError("RegisterDynamicHotstrings (" . snip.trigger . ")", err)
            }
        }
    }
}

HotstringCallback(replacement, *) {
    InsertText(replacement . A_EndChar)
}

GetOffsetDate(offsetDays) {
    targetTime := DateAdd(A_Now, offsetDays, "days")
    return FormatTime(targetTime, "yyyy-MM-dd")
}

GetCurrentWorkWeekRange() {
    dayOfWeek := FormatTime(A_Now, "WDay")
    mondayOffset := (dayOfWeek = 1) ? -6 : (2 - dayOfWeek)
    fridayOffset := mondayOffset + 4
    
    mon := DateAdd(A_Now, mondayOffset, "days")
    fri := DateAdd(A_Now, fridayOffset, "days")
    return FormatTime(mon, "yyyy-MM-dd") . " to " . FormatTime(fri, "yyyy-MM-dd")
}

ToSentenceCase(text) {
    lower := StrLower(text)
    return RegExReplace(lower, "(?:^|[\.!\?]\s+)([a-z])", "$U1")
}

ToDelimitedCase(text, delimiter) {
    clean := RegExReplace(text, "[^\w\s-]", "")
    clean := RegExReplace(clean, "[\s_-]+", delimiter)
    return StrLower(Trim(clean, delimiter))
}

ToCamelCase(text) {
    clean := RegExReplace(text, "[^\w\s-]", " ")
    words := StrSplit(clean, [" ", "_", "-"])
    out := ""
    for idx, w in words {
        if (w = "")
            continue
        if (out = "")
            out .= StrLower(w)
        else
            out .= StrUpper(SubStr(w, 1, 1)) . StrLower(SubStr(w, 2))
    }
    return out
}

FormatSqlInList(text) {
    lines := StrSplit(text, "`n", "`r")
    items := []
    for l in lines {
        t := Trim(l)
        if (t != "")
            items.Push("'" . StrReplace(t, "'", "''") . "'")
    }
    if (items.Length = 0)
        return text
    joined := ""
    for idx, item in items {
        joined .= (idx > 1 ? ", " : "") . item
    }
    return "(" . joined . ")"
}

EvaluateMathSelection() {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ShowToast("Highlight a math expression first (e.g. 1500 * 1.18)", 2500)
        return
    }
    try {
        expr := Trim(sel)
        exprClean := RegExReplace(expr, "[^\d\+\-\*/\.\(\)\s\^%]", "")
        if (exprClean = "")
            throw Error("Invalid mathematical expression")
        
        js := ComObject("MSScriptControl.ScriptControl")
        js.Language := "JScript"
        result := js.Eval(exprClean)
        
        if IsNumber(result)
            resultStr := String(Round(result, 4))
        else
            resultStr := String(result)
            
        InsertText(expr . " = " . resultStr)
    } catch as err {
        LogAppError("EvaluateMathSelection", err)
        ShowToast("Math Eval Error: " . err.Message, 2500)
    }
}

CalculateTaxBreakdown(taxRatePercent) {
    sel := SafeGetSelection()
    num := RegExReplace(sel, "[^\d\.]", "")
    if (!IsNumber(num) || num <= 0) {
        ShowToast("Highlight a valid base number first", 2500)
        return
    }
    base := Float(num)
    tax := base * (taxRatePercent / 100)
    total := base + tax
    
    out := Format("Base: {:0.2f} | Tax ({}%): {:0.2f} | Total: {:0.2f}", base, taxRatePercent, tax, total)
    InsertText(out)
}

CalculatePercentageDelta() {
    sel := SafeGetSelection()
    nums := []
    for match in StrSplit(RegExReplace(sel, "[^\d\.\s,]", " "), [" ", "`n", "`r", ","]) {
        if (Trim(match) != "" && IsNumber(match))
            nums.Push(Float(match))
    }
    if (nums.Length < 2) {
        ShowToast("Highlight two numbers (e.g. 100 125)", 2500)
        return
    }
    oldVal := nums[1]
    newVal := nums[2]
    if (oldVal = 0) {
        ShowToast("Initial value cannot be 0", 2500)
        return
    }
    delta := ((newVal - oldVal) / oldVal) * 100
    out := Format("{:0.2f} -> {:0.2f} ({:+0.2f}%)", oldVal, newVal, delta)
    InsertText(out)
}

GenerateSecurePassword(length := 16) {
    chars := "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*()-_=+"
    cArr := StrSplit(chars)
    pass := ""
    Loop length {
        pass .= cArr[Random(1, cArr.Length)]
    }
    return pass
}

GenerateUUID() {
    guid := Buffer(16, 0)
    if DllCall("ole32\CoCreateGuid", "Ptr", guid.Ptr) = 0 {
        return Format("{:08X}-{:04X}-{:04X}-{:02X}{:02X}-{:02X}{:02X}{:02X}{:02X}{:02X}{:02X}",
            NumGet(guid, 0, "UInt"),
            NumGet(guid, 4, "UShort"),
            NumGet(guid, 6, "UShort"),
            NumGet(guid, 8, "UChar"), NumGet(guid, 9, "UChar"),
            NumGet(guid, 10, "UChar"), NumGet(guid, 11, "UChar"), NumGet(guid, 12, "UChar"),
            NumGet(guid, 13, "UChar"), NumGet(guid, 14, "UChar"), NumGet(guid, 15, "UChar"))
    }
    return ""
}

ShowTextStats() {
    sel := SafeGetSelection()
    if (sel = "") {
        ShowToast("Highlight text first to count stats", 2000)
        return
    }
    charCount := StrLen(sel)
    charNoSpace := StrLen(RegExReplace(sel, "\s", ""))
    words := StrSplit(RegExReplace(sel, "\s+", " "), " ")
    wordCount := words.Length
    lines := StrSplit(sel, "`n", "`r")
    lineCount := lines.Length
    
    stats := Format("Selection Stats:`n- Words: {}`n- Characters: {} (No Spaces: {})`n- Lines: {}", wordCount, charCount, charNoSpace, lineCount)
    MsgBox(stats, "Text Statistics", "Iconi")
}

FormatNumberCommas(text) {
    clean := RegExReplace(text, "[^\d\.]", "")
    if (!IsNumber(clean))
        return text
    parts := StrSplit(clean, ".")
    intPart := parts[1]
    decPart := parts.Length > 1 ? ("." . parts[2]) : ""
    
    formatted := RegExReplace(intPart, "\G\d+?(?=(\d{3})+$)", "$0,")
    return formatted . decPart
}

RoundNumber(text, decimals := 2) {
    clean := RegExReplace(text, "[^\d\.-]", "")
    if (IsNumber(clean))
        return String(Round(Float(clean), decimals))
    return text
}

SumSelectedNumbers() {
    sel := SafeGetSelection()
    if (sel = "") {
        ShowToast("Highlight numbers to sum", 2000)
        return
    }
    total := 0.0
    count := 0
    for match in StrSplit(RegExReplace(sel, "[^\d\.\-\s,]", " "), [" ", "`n", "`r", ","]) {
        if (Trim(match) != "" && IsNumber(match)) {
            total += Float(match)
            count++
        }
    }
    if (count = 0) {
        ShowToast("No valid numbers found in selection", 2000)
        return
    }
    out := Format("Sum ({} numbers): {:0.2f}", count, total)
    InsertText(out)
}

ConvertUnixTimestamp() {
    sel := SafeGetSelection()
    num := RegExReplace(sel, "[^\d]", "")
    if (!IsNumber(num) || StrLen(num) < 9) {
        ShowToast("Highlight a valid Unix epoch timestamp", 2500)
        return
    }
    epochSecs := Integer(num)
    dt := DateAdd("19700101000000", epochSecs, "seconds")
    InsertText(FormatTime(dt, "yyyy-MM-dd HH:mm:ss"))
}

ConvertClipboardPath(slashType) {
    sel := SafeGetSelection()
    path := sel != "" ? sel : A_Clipboard
    if (slashType = "/")
        clean := StrReplace(path, "\", "/")
    else if (slashType = "\\")
        clean := StrReplace(StrReplace(path, "\\", "\"), "\", "\\")
    else
        clean := path
    InsertText(clean)
}

PrefixExplorerSelectedFile() {
    if !WinActive("ahk_class CabinetWClass") {
        ShowToast("Open File Explorer and select a file first", 2500)
        return
    }
    SendInput("{F2}")
    Sleep(50)
    prefix := FormatTime(A_Now, "yyMMdd_")
    SendInput("{Home}" . prefix)
}

SearchWebSelection(urlPrefix) {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ShowToast("Highlight text to search", 2000)
        return
    }
    Run(urlPrefix . EncodeUriComponent(Trim(sel)))
}

EncodeUriComponent(str) {
    try {
        js := ComObject("MSScriptControl.ScriptControl")
        js.Language := "JScript"
        return js.Run("encodeURIComponent", str)
    }
    return str
}

ToggleAlwaysOnTop() {
    hwnd := WinActive("A")
    if !hwnd
        return
    exStyle := WinGetExStyle(hwnd)
    isTop := (exStyle & 0x8)
    if isTop {
        WinSetAlwaysOnTop(0, hwnd)
        ShowToast("Window Unpinned (Normal)", 1500)
    } else {
        WinSetAlwaysOnTop(1, hwnd)
        ShowToast("Window Pinned (Always on Top)", 1500)
    }
}

ToggleWindowTransparency() {
    hwnd := WinActive("A")
    if !hwnd
        return
    curTrans := WinGetTransparent(hwnd)
    if (curTrans = 190) {
        WinSetTransparent(255, hwnd)
        ShowToast("Window Opacity: 100% (Solid)", 1500)
    } else {
        WinSetTransparent(190, hwnd)
        ShowToast("Window Opacity: 75% (Semi-Transparent)", 1500)
    }
}

OpenDailyScratchpad() {
    scratchPath := DataDir . "\Scratchpad_" . FormatTime(A_Now, "yyyy_MM_dd") . ".txt"
    if !FileExist(scratchPath) {
        header := "========================================================`n"
            . "Daily Scratchpad: " . FormatTime(A_Now, "dddd, MMMM d, yyyy") . "`n"
            . "========================================================`n`n"
        FileAppend(header, scratchPath, "UTF-8")
    }
    Run('notepad.exe "' . scratchPath . '"')
}

SilentEmptyRecycleBin() {
    DllCall("Shell32\SHEmptyRecycleBin", "Ptr", 0, "Ptr", 0, "UInt", 7)
    ShowToast("Recycle Bin Emptied", 1500)
}

ShowProductivityHelp() {
    help := "
    (
Office Productivity Command Palette & Snippet Suite
====================================================

PRIMARY ACCESS SHORTCUTS:
- Ctrl + Space     : Universal Command Palette (Search all 50+ tools).
- Ctrl + ;         : Leader Key mode (tap Ctrl+; then tap d, t, u, c, v).
- Ctrl + Shift + H : Highlight & Save instant snippet capture.
- Win + Esc        : Snippet & Text Replacement Manager GUI.

50 BUILT-IN TOOL CATEGORIES:
- Date & Time   : ISO Dates, timestamps, tomorrow, work-week ranges.
- Transform     : Plain text paste, UPPER, lower, Title, snake_case.
- Email         : PFA, Out of office, meeting requests, sign-offs.
- Math & Data   : In-line formula eval, GST 18%, percentage delta, UUID.
- Utilities     : Path converters, Always-on-Top, web search, scratchpad.
    )"
    MsgBox(help, AppTitle . " - User Guide", "Iconi")
}

ShowToast(msg, durationMs := 2000) {
    ToolTip("⚡ " . msg)
    SetTimer(() => ToolTip(), -durationMs)
}

CenterGuiOnActiveMonitor(guiObj, width, height) {
    try {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY)
        monCount := MonitorGetCount()
        targetMon := 1
        Loop monCount {
            MonitorGetWorkArea(A_Index, &mL, &mT, &mR, &mB)
            if (mX >= mL && mX <= mR && mY >= mT && mY <= mB) {
                targetMon := A_Index
                break
            }
        }
        MonitorGetWorkArea(targetMon, &mL, &mT, &mR, &mB)
        posX := mL + ((mR - mL - width) // 2)
        posY := mT + ((mB - mT - height) // 2)
        guiObj.Move(posX, posY, width, height)
    }
}

LogAppError(context, errObj) {
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        entry := Format("[{}] [{}] Error in {}: {} (Line {})`n", timestamp, AppVersion, context, errObj.Message, errObj.Line)
        FileAppend(entry, ErrorLogFile, "UTF-8")
    }
}
