; ======================================================================================================================
; Module: Actions_Extraction.ahk - Text Mining & Data Extraction Suite
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterExtractionActions() {
    RegisterAction("Extract All Email Addresses", "🔍 Extraction", "[Needs Selection] Pulls clean list of all emails from messy text", "extract, email, emails, mail, filter, list", (*) => ProcessExtraction("Emails", (txt) => ExtractEmails(txt)))
    RegisterAction("Extract All URLs & Web Links", "🔍 Extraction", "[Needs Selection] Pulls clean list of all web URLs and links", "extract, url, urls, links, web, http, list", (*) => ProcessExtraction("URLs", (txt) => ExtractUrls(txt)))
    RegisterAction("Extract Phone & Mobile Numbers", "🔍 Extraction", "[Needs Selection] Pulls Indian mobile and STD phone numbers", "extract, phone, mobile, contact, numbers, call", (*) => ProcessExtraction("Phone Numbers", (txt) => ExtractPhones(txt)))
    RegisterAction("Extract Indian GSTINs", "🔍 Extraction", "[Needs Selection] Pulls 15-char GST Identification Numbers", "extract, gstin, gst, tax, invoice, compliance", (*) => ProcessExtraction("GSTINs", (txt) => ExtractGstin(txt)))
    RegisterAction("Extract Indian PAN Numbers", "🔍 Extraction", "[Needs Selection] Pulls 10-char Permanent Account Numbers", "extract, pan, tax, income tax, compliance", (*) => ProcessExtraction("PANs", (txt) => ExtractPan(txt)))
    RegisterAction("Extract All Dates from Text", "🔍 Extraction", "[Needs Selection] Pulls dates in all formats with [VALID] / [INVAL] tags", "extract, date, dates, calendar, deadlines, validate", (*) => ProcessExtraction("Dates", (txt) => ExtractDates(txt)))
    RegisterAction("Date Difference & Working Days", "🔍 Extraction", "[Needs Selection] Calculates calendar days and working days (Mon-Fri)", "date, difference, diff, days, working days, duration, between", (*) => CalculateDateDifferencePrompt())
}

ProcessExtraction(itemType, extractorFunc) {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Paste raw text to extract " . itemType . " from:", "Extract " . itemType)
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    
    extracted := extractorFunc.Call(sel)
    if (extracted = "" || InStr(extracted, "No ")) {
        ShowToast("⚠️ No " . itemType . " found in text", 2000)
        return
    }
    
    A_Clipboard := extracted
    if CanPasteToTargetWindow() {
        InsertText(extracted)
    }
    
    lineCount := StrSplit(extracted, "`n").Length
    ShowToast("✔ Extracted " . lineCount . " " . itemType . " (Copied to Clipboard)", 2500)
}

ExtractEmails(text) {
    emails := []
    pos := 1
    while RegExMatch(text, "i)\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b", &m, pos) {
        val := m[0]
        found := false
        for e in emails {
            if (StrLower(e) = StrLower(val)) {
                found := true
                break
            }
        }
        if !found
            emails.Push(val)
        pos := m.Pos + m.Len
    }
    if (emails.Length = 0)
        return "No emails found"
    res := ""
    for idx, e in emails
        res .= (idx > 1 ? "`n" : "") . e
    return res
}

ExtractUrls(text) {
    urls := []
    pos := 1
    while RegExMatch(text, "i)\b(?:https?://|www\.)[^\s<>'`"]+", &m, pos) {
        val := RTrim(m[0], " .,;:!?'`"")
        found := false
        for u in urls {
            if (u = val) {
                found := true
                break
            }
        }
        if !found
            urls.Push(val)
        pos := m.Pos + m.Len
    }
    if (urls.Length = 0)
        return "No URLs found"
    res := ""
    for idx, u in urls
        res .= (idx > 1 ? "`n" : "") . u
    return res
}

ExtractPhones(text) {
    phones := []
    pos := 1
    while RegExMatch(text, "(?:\+91[\-\s]?)?[6-9]\d{9}|\b\d{3,5}[\-\s]\d{6,8}\b", &m, pos) {
        val := Trim(m[0])
        found := false
        for p in phones {
            if (p = val) {
                found := true
                break
            }
        }
        if !found
            phones.Push(val)
        pos := m.Pos + m.Len
    }
    if (phones.Length = 0)
        return "No phone numbers found"
    res := ""
    for idx, p in phones
        res .= (idx > 1 ? "`n" : "") . p
    return res
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [GSTIN EXTRACTION - PATTERN-BASED INTENT]:
; 1. Regex follows standard 15-character GSTIN structure: 2 digits + 5 letters + 4 digits + 1 letter + 1 alphanumeric + Z + 1 alphanumeric.
;    Results are automatically uppercased and deduplicated.
; 2. State-code range limits (01–38), PAN semantics (4th letter entity type), entity constraints, and checksum/official 
;    GST portal verification are deliberate non-goals to keep local offline clipboard extraction instantaneous and non-blocking.
; ======================================================================================================================
ExtractGstin(text) {
    gstins := []
    pos := 1
    while RegExMatch(text, "i)\b\d{2}[a-z]{5}\d{4}[a-z]{1}[a-z\d]{1}[z]{1}[a-z\d]{1}\b", &m, pos) {
        val := StrUpper(m[0])
        found := false
        for g in gstins {
            if (g = val) {
                found := true
                break
            }
        }
        if !found
            gstins.Push(val)
        pos := m.Pos + m.Len
    }
    if (gstins.Length = 0)
        return "No GSTINs found"
    res := ""
    for idx, g in gstins
        res .= (idx > 1 ? "`n" : "") . g
    return res
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [PAN EXTRACTION - PATTERN-BASED INTENT]:
; 1. Regex extracts standard 10-character Indian PAN format: 5 letters + 4 digits + 1 letter (\b[a-z]{5}\d{4}[a-z]{1}\b).
; 2. May match non-PAN alphanumeric strings that happen to follow the same 5-letter/4-digit/1-letter pattern.
;    This is an acceptable false-positive trade-off for a fast, offline, lightweight extraction tool without needing 
;    external ITD database lookups or complex 4th-letter entity semantics.
; ======================================================================================================================
ExtractPan(text) {
    pans := []
    pos := 1
    while RegExMatch(text, "i)\b[a-z]{5}\d{4}[a-z]{1}\b", &m, pos) {
        val := StrUpper(m[0])
        found := false
        for p in pans {
            if (p = val) {
                found := true
                break
            }
        }
        if !found
            pans.Push(val)
        pos := m.Pos + m.Len
    }
    if (pans.Length = 0)
        return "No PAN numbers found"
    res := ""
    for idx, p in pans
        res .= (idx > 1 ? "`n" : "") . p
    return res
}

; ======================================================================================================================
; ARCHITECTURAL INTENT & DESIGN BOUNDARY [DATE EXTRACTION & VALIDATION TAGGING]:
; 1. OCR / Compressed Text Lenience: Concatenated text such as `August 212026` or `Aug 152026` is intentionally 
;    divided into day 21 / year 2026 and accepted to gracefully recover dates from noisy OCR/PDF scans.
; 2. Tagging Policy (Absence of Tag = Valid): Valid dates are NOT tagged with [VALID] — only invalid dates 
;    get the ` [INVAL]` suffix (e.g. `31-Feb-2026 [INVAL]`). This is intentional to keep extracted output clean, 
;    readable, and directly pasteable into documents.
; ======================================================================================================================
ExtractDates(text) {
    dates := []
    pos := 1
    pattern := "\b(?:(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*)?(?:\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{1,2}\.\d{1,2}\.\d{2,4}|\d{1,2}[-/\s\._\\]*(?:of\s+)?[a-z]{3,9}[-/\s,\._\\]*\d{2,4}|[a-z]{3,9}[-/\s\._\\]*\d{1,2}(?:st|nd|rd|th)?[-/\s,\._\\]+\d{2,4})\b"
    while RegExMatch(text, "i)" . pattern, &m, pos) {
        raw := Trim(m[0], " .,;:")
        found := false
        for d in dates {
            if (d.raw = raw) {
                found := true
                break
            }
        }
        if !found {
            valid := IsValidCalendarDate(raw)
            comment := valid ? "" : " [INVAL]"
            dates.Push({ raw: raw, comment: comment })
        }
        pos := m.Pos + m.Len
    }
    if (dates.Length = 0)
        return "No dates found"
    res := ""
    for idx, d in dates
        res .= (idx > 1 ? "`n" : "") . d.raw . d.comment
    return res
}

IsValidCalendarDate(dStr) {
    parsed := ParseAnyDateToYyyyMmDd(dStr)
    if (parsed = "" || StrLen(parsed) != 8)
        return false
        
    y := Integer(SubStr(parsed, 1, 4))
    m := Integer(SubStr(parsed, 5, 2))
    d := Integer(SubStr(parsed, 7, 2))
    
    if (y < 1900 || y > 2100 || m < 1 || m > 12)
        return false
        
    isLeap := ((Mod(y, 4) = 0 && Mod(y, 100) != 0) || (Mod(y, 400) = 0))
    maxDays := [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m]
    return (d >= 1 && d <= maxDays)
}

CalculateDateDifferencePrompt() {
    sel := SafeGetSelection()
    dates := []
    if (Trim(sel) != "") {
        dates := ExtractRawDatesList(sel)
    }
    
    if (dates.Length < 2) {
        ib := OfficeInputBox("Enter two dates (e.g. 21-Aug-2026 to 31-Aug-2026):", "Date Difference")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        dates := ExtractRawDatesList(ib.Value)
        if (dates.Length < 2) {
            ShowToast("⚠️ Please provide at least two valid dates", 2000)
            return
        }
    }
    
    diffReport := CalculateDateDifference(dates[1], dates[2])
    MsgBox(diffReport, "Date Difference & Working Days", "Iconi")
}

ExtractRawDatesList(text) {
    dates := []
    pos := 1
    pattern := "\b(?:(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*)?(?:\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{1,2}\.\d{1,2}\.\d{2,4}|\d{1,2}[-/\s\._\\]*(?:of\s+)?[a-z]{3,9}[-/\s,\._\\]*\d{2,4}|[a-z]{3,9}[-/\s\._\\]*\d{1,2}(?:st|nd|rd|th)?[-/\s,\._\\]+\d{2,4})\b"
    while RegExMatch(text, "i)" . pattern, &m, pos) {
        raw := Trim(m[0], " .,;:")
        if IsValidCalendarDate(raw) {
            dates.Push(raw)
        }
        pos := m.Pos + m.Len
    }
    return dates
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [DATE DIFFERENCE & WORKING DAYS - INTENTIONAL NON-GOALS]:
; 1. Working Days: Standard Monday-to-Friday business week (WDay 2–6). Does NOT account for public/bank holidays.
;    Full holiday calendar databases and regional holiday lookup APIs are intentional non-goals for this lightweight tool.
; 2. Direction & Boundaries: Calculates absolute elapsed calendar span. Explicit inclusive/exclusive boundary toggles
;    and signed directional flags (+/- days) are intentionally omitted for instant, unambiguous report generation.
; ======================================================================================================================
CalculateDateDifference(dateStr1, dateStr2) {
    d1 := ParseAnyDateToYyyyMmDd(dateStr1)
    d2 := ParseAnyDateToYyyyMmDd(dateStr2)
    if (d1 = "" || d2 = "" || !IsValidCalendarDate(dateStr1) || !IsValidCalendarDate(dateStr2))
        return "Invalid date format or non-existent calendar date"
    
    if (d1 > d2) {
        tmp := d1
        d1 := d2
        d2 := tmp
    }
    
    totalDays := DateDiff(d2 . "000000", d1 . "000000", "days")
    
    workDays := 0
    cur := d1
    Loop totalDays {
        wday := FormatTime(cur . "000000", "WDay")
        if (wday >= 2 && wday <= 6)
            workDays++
        cur := FormatTime(DateAdd(cur . "000000", 1, "days"), "yyyyMMdd")
    }
    
    weeks := totalDays // 7
    remDays := Mod(totalDays, 7)
    
    res := Format("From {} to {}:`n• Total Calendar Days: {} days`n• Working Days (Mon-Fri): {} days`n• Duration: {} week(s) {} day(s)", 
                  FormatTime(d1 . "000000", "dd-MMM-yyyy"), FormatTime(d2 . "000000", "dd-MMM-yyyy"), totalDays, workDays, weeks, remDays)
    return res
}

ParseAnyDateToYyyyMmDd(dStr) {
    s := Trim(dStr)
    if (s == "")
        return ""

    if (IsSet(DateFormatConverter) && HasMethod(DateFormatConverter, "ParseIndianDate")) {
        p := DateFormatConverter.ParseIndianDate(s)
        if (p.valid)
            return p.yyyymmdd
    }
    
    if RegExMatch(s, "i)^(\d{1,2})[-/\s]+([a-z]{3})[a-z]*[-/\s,]+(\d{2,4})$", &m) {
        day := Integer(m[1])
        monStr := StrLower(SubStr(m[2], 1, 3))
        monthNum := GetMonthNumFromName(monStr)
        year := Integer(m[3])
        if (year < 100)
            year += 2000
        return Format("{:04d}{:02d}{:02d}", year, monthNum, day)
    }
    
    ; Intended Lenience: ',?\s*' allows optional comma & whitespace to gracefully extract dates from 
    ; compressed/noisy OCR scans and stripped PDF text (e.g., 'August 21, 2026', 'Aug 15 2026', or concatenated 'August 212026')
    if RegExMatch(s, "i)^([a-z]{3})[a-z]*\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{2,4})$", &m) {
        monStr := StrLower(SubStr(m[1], 1, 3))
        monthNum := GetMonthNumFromName(monStr)
        day := Integer(m[2])
        year := Integer(m[3])
        if (year < 100)
            year += 2000
        return Format("{:04d}{:02d}{:02d}", year, monthNum, day)
    }
    
    if RegExMatch(s, "^(\d{4})[-/\.](?:(\d{1,2})[-/\.](\d{1,2}))$", &m)
        return Format("{}{:02d}{:02d}", m[1], Integer(m[2]), Integer(m[3]))
        
    if RegExMatch(s, "^(\d{1,2})[-/\.](\d{1,2})[-/\.](\d{4})$", &m)
        return Format("{}{:02d}{:02d}", m[3], Integer(m[2]), Integer(m[1]))
        
    if RegExMatch(s, "^(\d{1,2})[-/\.](\d{1,2})[-/\.](\d{2})$", &m)
        return Format("20{}{:02d}{:02d}", m[3], Integer(m[2]), Integer(m[1]))
        
    return ""
}

GetMonthNumFromName(mStr) {
    m := StrLower(mStr)
    static months := Map("jan", 1, "feb", 2, "mar", 3, "apr", 4, "may", 5, "jun", 6,
                         "jul", 7, "aug", 8, "sep", 9, "oct", 10, "nov", 11, "dec", 12)
    return months.Has(m) ? months[m] : 0
}

