#Requires AutoHotkey v2.0

; ======================================================================================================================
; ARCHITECTURAL INVARIANTS & CODER DESIGN INTENT [DELIBERATE SCOPE LIMITATION - DO NOT MODIFY]:
;
; EXHAUSTIVE 9 CANONICAL FORMATS BY DESIGN:
; The 9 target formats (DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD/MM/YY, DD-MM-YY, DD Month YYYY,
; Month DD, YYYY, DD Month, YYYY, DDDD, dd Month YYYY) represent the complete, exhaustive set of verified
; Indian office standards. Custom strftime masks and American formats (MM/DD/YYYY) are DELIBERATE NON-GOALS
; to eliminate calendar ambiguity and prevent accidental day/month corruption.
; ======================================================================================================================

; ======================================================================================================================
; Title:   DateFormatConverter.ahk
; Version: 1.0.0 (Production Release)
; AHK Ver: v2.0+
; Core Purpose:
; Universal Bidirectional Date Format Converter implementing the Indian Standard (Day first, Month second, Year third).
; Ingests ANY Indian-standard date format in the wild (arbitrary delimiters, ordinals, unspaced/concatenated alphanumeric,
; connectors, weekday prefixes) and converts deterministically into any of the 9 canonical target formats.
;
; The 9 Canonical Formats:
; 1: DD/MM/YYYY        (e.g., 05/09/2026)
; 2: DD-MM-YYYY        (e.g., 05-09-2026)
; 3: DD.MM.YYYY        (e.g., 05.09.2026)
; 4: DD/MM/YY          (e.g., 05/09/26)
; 5: DD-MM-YY          (e.g., 05-09-26)
; 6: DD Month YYYY     (e.g., 05 September 2026)
; 7: Month DD, YYYY    (e.g., September 05, 2026)
; 8: DD Month, YYYY    (e.g., 05 September, 2026)
; 9: DDDD, dd Month YYYY (e.g., Saturday, 05 September 2026)
; ======================================================================================================================

class DateFormatConverter {
    static Formats := [
        { id: 1, name: "DD/MM/YYYY",        pattern: "dd/MM/yyyy",       example: "05/09/2026" },
        { id: 2, name: "DD-MM-YYYY",        pattern: "dd-MM-yyyy",       example: "05-09-2026" },
        { id: 3, name: "DD.MM.YYYY",        pattern: "dd.MM.yyyy",       example: "05.09.2026" },
        { id: 4, name: "DD/MM/YY",          pattern: "dd/MM/yy",         example: "05/09/26" },
        { id: 5, name: "DD-MM-YY",          pattern: "dd-MM-yy",         example: "05-09-26" },
        { id: 6, name: "DD Month YYYY",     pattern: "dd MMMM yyyy",     example: "05 September 2026" },
        { id: 7, name: "Month DD, YYYY",    pattern: "MMMM dd, yyyy",    example: "September 05, 2026" },
        { id: 8, name: "DD Month, YYYY",    pattern: "dd MMMM, yyyy",    example: "05 September, 2026" },
        { id: 9, name: "DDDD, dd Month YYYY", pattern: "dddd, dd MMMM yyyy", example: "Saturday, 05 September 2026" }
    ]

    static MonthNames := [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    static DayNames := [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    static MonthMap := Map(
        "jan", 1, "january", 1,
        "feb", 2, "february", 2,
        "mar", 3, "march", 3,
        "apr", 4, "april", 4,
        "may", 5,
        "jun", 6, "june", 6,
        "jul", 7, "july", 7,
        "aug", 8, "august", 8,
        "sep", 9, "sept", 9, "september", 9,
        "oct", 10, "october", 10,
        "nov", 11, "november", 11,
        "dec", 12, "december", 12
    )

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Universal Indian-Standard Date Parser
    ; ------------------------------------------------------------------------------------------------------------------
    static ParseIndianDate(dStr) {
        if (Trim(dStr) = "")
            return { valid: false, error: "Empty input" }

        s := Trim(dStr)
        s := Trim(s, " `t`r`n'<>[]{}()")
        s := Trim(s, '`"')

        ; Strip optional leading weekday name (e.g. 'Saturday, ', 'Sat, ', 'Saturday ')
        s := RegExReplace(s, "i)^(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*", "")
        s := Trim(s)

        day := 0
        month := 0
        year := 0
        matched := false

        ; Pattern A: Day-First Textual (e.g. '5sept2026', '5sept26', '05 September 2026', '5th of Sep 2026', '05-Sep-2026')
        ; Zero-space transitions between digit and letter are valid natural boundaries (\d <-> [a-z])
        if RegExMatch(s, "i)^(\d{1,2})(?:st|nd|rd|th)?(?:[-/\s._\\]*(?:of\s+)?)([a-z]{3,9})[-/\s,\._\\]*(\d{2,4})$", &m) {
            monStr := StrLower(m[2])
            if this.MonthMap.Has(monStr) {
                day := Integer(m[1])
                month := this.MonthMap[monStr]
                year := Integer(m[3])
                matched := true
            }
        }

        ; Pattern B: Month-First Textual (e.g. 'September 05, 2026', 'september5 26', 'sept5 2026', 'Sep 5 2026')
        ; Enforces AT LEAST ONE separator before year ([-/\s,\._\\]+), strictly rejecting ambiguous 'sept526'
        if (!matched && RegExMatch(s, "i)^([a-z]{3,9})[-/\s._\\]*(\d{1,2})(?:st|nd|rd|th)?[-/\s,\._\\]+(\d{2,4})$", &m)) {
            monStr := StrLower(m[1])
            if this.MonthMap.Has(monStr) {
                month := this.MonthMap[monStr]
                day := Integer(m[2])
                year := Integer(m[3])
                matched := true
            }
        }

        ; Pattern C: ISO Format (YYYY-MM-DD / YYYY/MM/DD / YYYY.MM.DD)
        if (!matched && RegExMatch(s, "^(\d{4})[-/\s._\\](\d{1,2})[-/\s._\\](\d{1,2})$", &m)) {
            year := Integer(m[1])
            month := Integer(m[2])
            day := Integer(m[3])
            matched := true
        }

        ; Pattern D: Strict Indian Numeric (DD then MM then YY/YYYY: e.g. 05/09/2026, 5-9-26, 05.09.2026, 5 9 2026, 05_09_2026)
        if (!matched && RegExMatch(s, "^(\d{1,2})[-/\s._\\](\d{1,2})[-/\s._\\](\d{2,4})$", &m)) {
            day := Integer(m[1])
            month := Integer(m[2])
            year := Integer(m[3])
            matched := true
        }

        ; Pattern E: Compact 8-digit ISO (YYYYMMDD) or Indian (DDMMYYYY)
        if (!matched && RegExMatch(s, "^(\d{4})(\d{2})(\d{2})$", &m)) {
            yCandidate := Integer(m[1])
            mCandidate := Integer(m[2])
            dCandidate := Integer(m[3])
            if (mCandidate >= 1 && mCandidate <= 12 && dCandidate >= 1 && dCandidate <= 31 && yCandidate >= 1900 && yCandidate <= 2100) {
                year := yCandidate
                month := mCandidate
                day := dCandidate
                matched := true
            }
        }
        if (!matched && RegExMatch(s, "^(\d{2})(\d{2})(\d{4})$", &m)) {
            dCandidate := Integer(m[1])
            mCandidate := Integer(m[2])
            yCandidate := Integer(m[3])
            if (mCandidate >= 1 && mCandidate <= 12 && dCandidate >= 1 && dCandidate <= 31) {
                day := dCandidate
                month := mCandidate
                year := yCandidate
                matched := true
            }
        }

        if (!matched)
            return { valid: false, error: "Unrecognized date format" }

        ; Expand 2-digit years via century pivot (00-99 -> 2000-2099)
        if (year < 100)
            year += 2000

        ; Calendar Validity Guard
        if (year < 1900 || year > 2100 || month < 1 || month > 12)
            return { valid: false, error: "Out-of-bounds calendar values" }

        isLeap := ((Mod(year, 4) = 0 && Mod(year, 100) != 0) || (Mod(year, 400) = 0))
        maxDays := [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]

        if (day < 1 || day > maxDays)
            return { valid: false, error: "Invalid day for specified month/year" }

        yyyymmdd := Format("{:04d}{:02d}{:02d}", year, month, day)
        ts := yyyymmdd . "000000"
        wdayNum := Integer(FormatTime(ts, "WDay"))
        dayName := this.DayNames[wdayNum]
        monthName := this.MonthNames[month]

        return {
            valid: true,
            day: day,
            month: month,
            year: year,
            wday: wdayNum,
            dayName: dayName,
            monthName: monthName,
            yyyymmdd: yyyymmdd
        }
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Canonical Format Builder
    ; ------------------------------------------------------------------------------------------------------------------
    static Format(parsedObj, targetFormatId) {
        if (!parsedObj || !parsedObj.valid)
            return ""

        d := parsedObj.day
        m := parsedObj.month
        y := parsedObj.year
        monName := parsedObj.monthName
        dName := parsedObj.dayName
        yy := Mod(y, 100)

        switch targetFormatId {
            case 1: ; DD/MM/YYYY
                return Format("{:02d}/{:02d}/{:04d}", d, m, y)
            case 2: ; DD-MM-YYYY
                return Format("{:02d}-{:02d}-{:04d}", d, m, y)
            case 3: ; DD.MM.YYYY
                return Format("{:02d}.{:02d}.{:04d}", d, m, y)
            case 4: ; DD/MM/YY
                return Format("{:02d}/{:02d}/{:02d}", d, m, yy)
            case 5: ; DD-MM-YY
                return Format("{:02d}-{:02d}-{:02d}", d, m, yy)
            case 6: ; DD Month YYYY
                return Format("{:02d} {} {:04d}", d, monName, y)
            case 7: ; Month DD, YYYY
                return Format("{} {:02d}, {:04d}", monName, d, y)
            case 8: ; DD Month, YYYY
                return Format("{:02d} {}, {:04d}", d, monName, y)
            case 9: ; DDDD, dd Month YYYY
                return Format("{}, {:02d} {} {:04d}", dName, d, monName, y)
            default:
                return Format("{:02d}/{:02d}/{:04d}", d, m, y)
        }
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. Atomic Conversion & Format Detection
    ; ------------------------------------------------------------------------------------------------------------------
    static Convert(dateStr, targetFormatId) {
        parsed := this.ParseIndianDate(dateStr)
        if (!parsed.valid)
            return "Invalid Date"
        return this.Format(parsed, targetFormatId)
    }

    static DetectFormat(dateStr) {
        s := Trim(dateStr)
        if RegExMatch(s, "i)^[a-z]+,\s*\d{1,2}\s+[a-z]+\s+\d{4}$")
            return 9 ; DDDD, dd Month YYYY
        if RegExMatch(s, "i)^\d{1,2}\s+[a-z]+,\s*\d{4}$")
            return 8 ; DD Month, YYYY
        if RegExMatch(s, "i)^[a-z]+\s+\d{1,2},\s*\d{4}$")
            return 7 ; Month DD, YYYY
        if RegExMatch(s, "i)^\d{1,2}\s+[a-z]+\s+\d{4}$")
            return 6 ; DD Month YYYY
        if RegExMatch(s, "^\d{1,2}-\d{1,2}-\d{2}$")
            return 5 ; DD-MM-YY
        if RegExMatch(s, "^\d{1,2}/\d{1,2}/\d{2}$")
            return 4 ; DD/MM/YY
        if RegExMatch(s, "^\d{1,2}\.\d{1,2}\.\d{4}$")
            return 3 ; DD.MM.YYYY
        if RegExMatch(s, "^\d{1,2}-\d{1,2}-\d{4}$")
            return 2 ; DD-MM-YYYY
        if RegExMatch(s, "^\d{1,2}/\d{1,2}/\d{4}$")
            return 1 ; DD/MM/YYYY
        return 0 ; Other / Wild
    }

    static Cycle(dateStr) {
        parsed := this.ParseIndianDate(dateStr)
        if (!parsed.valid)
            return dateStr

        curFmt := this.DetectFormat(dateStr)
        nextFmt := (curFmt >= 1 && curFmt <= 8) ? (curFmt + 1) : 1
        return this.Format(parsed, nextFmt)
    }

    static GetAllFormats(dateInput, activeFmtId := 0) {
        if (IsObject(dateInput) && dateInput.HasOwnProp("valid") && dateInput.valid) {
            parsed := dateInput
            curFmt := (activeFmtId > 0) ? activeFmtId : 0
        } else {
            parsed := this.ParseIndianDate(String(dateInput))
            curFmt := (activeFmtId > 0) ? activeFmtId : this.DetectFormat(String(dateInput))
        }
        if (!parsed.valid)
            return []

        results := []
        for fmt in this.Formats {
            val := this.Format(parsed, fmt.id)
            results.Push(Map(
                "id", fmt.id,
                "name", fmt.name,
                "value", val,
                "isCurrent", (fmt.id = curFmt)
            ))
        }
        return results
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 4. Batch Text Conversion (In-Text Replacements)
    ; ------------------------------------------------------------------------------------------------------------------
    static ConvertAllInText(text, targetFormatId) {
        if (Trim(text) = "")
            return text

        ; Comprehensive pattern matching Indian standard dates in text
        pattern := "i)\b(?:(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*)?(?:\d{1,2}(?:st|nd|rd|th)?(?:[-/\s._\\]*(?:of\s+)?)[a-z]{3,9}[-/\s,\._\\]*\d{2,4}|[a-z]{3,9}[-/\s._\\]*\d{1,2}(?:st|nd|rd|th)?[-/\s,\._\\]+\d{2,4}|\d{4}[-/\s._\\]\d{1,2}[-/\s._\\]\d{1,2}|\d{1,2}[-/\s._\\]\d{1,2}[-/\s._\\]\d{2,4})\b"
        
        pos := 1
        outText := ""
        lastIdx := 1
        while RegExMatch(text, pattern, &m, pos) {
            rawMatch := m[0]
            parsed := this.ParseIndianDate(rawMatch)
            outText .= SubStr(text, lastIdx, m.Pos - lastIdx)
            if (parsed.valid) {
                outText .= this.Format(parsed, targetFormatId)
            } else {
                outText .= rawMatch
            }
            lastIdx := m.Pos + m.Len
            pos := m.Pos + m.Len
        }
        outText .= SubStr(text, lastIdx)
        return outText
    }
}
