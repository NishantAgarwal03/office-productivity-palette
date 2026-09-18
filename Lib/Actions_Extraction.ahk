; ======================================================================================================================
; Module: Actions_Extraction.ahk - Text Mining & Data Extraction Suite
; ======================================================================================================================

#Requires AutoHotkey v2.0

; Shared regex bodies for the ID/contact formats this module recognizes — reused by both the ExtractX
; functions below (which return matches) and RedactSensitiveData() (which masks matches before RunHistory
; persists them), so the format definitions are maintained in exactly one place.
class SensitivePatterns {
    static GSTIN := "\b\d{2}[a-z]{5}\d{4}[a-z]{1}[a-z\d]{1}[z]{1}[a-z\d]{1}\b"
    static PAN := "\b[a-z]{5}\d{4}[a-z]{1}\b"
    static PHONE := "(?:\+91[\-\s]?)?[6-9]\d{9}|\b\d{3,5}[\-\s]\d{6,8}\b"
    static EMAIL := "\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b"
}

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
    while RegExMatch(text, "i)" . SensitivePatterns.EMAIL, &m, pos) {
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
    while RegExMatch(text, SensitivePatterns.PHONE, &m, pos) {
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
    while RegExMatch(text, "i)" . SensitivePatterns.GSTIN, &m, pos) {
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
    while RegExMatch(text, "i)" . SensitivePatterns.PAN, &m, pos) {
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
; SCOPE & DESIGN BOUNDARY [SENSITIVE DATA REDACTION - defense-in-depth for RunHistory persistence, DEFECT-051 / D3]:
; 1. Reuses this module's own GSTIN/PAN/phone/email detection patterns (SensitivePatterns above) to mask matches
;    with a constant [REDACTED:<TYPE>] tag before Lib\RunHistory.ahk writes run snapshots to disk.
; 2. Order matters: GSTIN is masked before PAN, since a GSTIN's 3rd-12th characters are themselves PAN-shaped —
;    masking GSTIN first prevents a leftover, still-readable PAN fragment surviving inside an already-redacted GSTIN.
; 3. Known-pattern coverage only — this is a defense-in-depth measure for the specific ID/contact formats this
;    module already recognizes, not a guarantee that all sensitive text is caught. Arbitrary clipboard text
;    (names, unlisted account formats, free-text financial figures) is NOT redacted by this function; see D3
;    in Docs/PENDING_NEXT_SESSION.md for the full acknowledged scope of this limitation.
; ======================================================================================================================
RedactSensitiveData(text) {
    if (Type(text) != "String" || text = "")
        return text
    redacted := text
    redacted := RegExReplace(redacted, "i)" . SensitivePatterns.GSTIN, "[REDACTED:GSTIN]")
    redacted := RegExReplace(redacted, "i)" . SensitivePatterns.PAN, "[REDACTED:PAN]")
    redacted := RegExReplace(redacted, SensitivePatterns.PHONE, "[REDACTED:PHONE]")
    redacted := RegExReplace(redacted, "i)" . SensitivePatterns.EMAIL, "[REDACTED:EMAIL]")
    return redacted
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

; DEFECT-050 (R6): this function used to fall back to its own independent set of date-parsing regexes
; (day-first textual, month-first textual, ISO, DD-MM-YYYY, DD-MM-YY) whenever DateFormatConverter's
; parser didn't match — a second, weaker date parser (no calendar-validity checks, no weekday-prefix
; stripping) duplicating logic DateFormatConverter.ParseIndianDate already covers as a strict superset
; (see its Patterns A-E), violating the project's "zero role duplication" standard. Delegates fully now.
ParseAnyDateToYyyyMmDd(dStr) {
    s := Trim(dStr)
    if (s == "")
        return ""

    if (IsSet(DateFormatConverter) && HasMethod(DateFormatConverter, "ParseIndianDate")) {
        p := DateFormatConverter.ParseIndianDate(s)
        if (p.valid)
            return p.yyyymmdd
    }

    return ""
}


