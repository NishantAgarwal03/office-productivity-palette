; ======================================================================================================================
; Module: Actions_DateTime.ahk - 10 Essential Date & Time Master Tools
; ARCHITECTURAL INVARIANT & SCOPE LIMITATION [DO NOT MODIFY]:
; 1. All tools output formatted local system time (IST) directly. UTC is not a choice. Only IST / Local Time.
; 2. Sub-second milliseconds, UTC flags, and multi-timezone offsets are intentional non-goals to maintain lightweight, 
;    1-click clipboard insertion.
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterDateTimeActions() {
    RegisterAction("Today's ISO Date", "📅 Date/Time", "Inserts " . FormatTime(A_Now, "yyyy-MM-dd"), "date, today, iso", (*) => InsertText(FormatTime(A_Now, "yyyy-MM-dd")), "", "Alt+Shift+D")
    RegisterAction("Compact File Timestamp", "📅 Date/Time", "Inserts " . FormatTime(A_Now, "yyMMdd_HHmmss") . " (YYMMDD_HHMMSS)", "timestamp, time, compact, file", (*) => InsertText(FormatTime(A_Now, "yyMMdd_HHmmss")), "t")
    RegisterAction("Formal Long Date", "📅 Date/Time", "Inserts " . FormatTime(A_Now, "dddd, MMMM d, yyyy"), "long, date, formal, day", (*) => InsertText(FormatTime(A_Now, "dddd, MMMM d, yyyy")))
    RegisterAction("Current Time (12-Hour AM/PM)", "📅 Date/Time", "Inserts " . FormatTime(A_Now, "hh:mm tt"), "time, 12h, clock, am, pm", (*) => InsertText(FormatTime(A_Now, "hh:mm tt")), "", "Alt+Shift+T")
    RegisterAction("Current Time (24-Hour with Seconds)", "📅 Date/Time", "Inserts " . FormatTime(A_Now, "HH:mm:ss"), "time, 24h, clock, seconds", (*) => InsertText(FormatTime(A_Now, "HH:mm:ss")))
    RegisterAction("Tomorrow's Date", "📅 Date/Time", "Inserts tomorrow's date: " . GetOffsetDate(1), "tomorrow, future, next, date", (*) => InsertText(GetOffsetDate(1)))
    RegisterAction("Yesterday's Date", "📅 Date/Time", "Inserts yesterday's date: " . GetOffsetDate(-1), "yesterday, past, prev, date", (*) => InsertText(GetOffsetDate(-1)))
    RegisterAction("Current ISO Week Number", "📅 Date/Time", "Inserts " . GetIsoWeekInfo().formatted, "week, iso, sprint, workweek", (*) => InsertText(GetIsoWeekInfo().formatted))
    RegisterAction("Current Month & Year", "📅 Date/Time", "Inserts " . FormatTime(A_Now, "MMMM yyyy"), "month, year, period", (*) => InsertText(FormatTime(A_Now, "MMMM yyyy")))
    RegisterAction("Work Week Date Range", "📅 Date/Time", "Inserts Monday to Friday: " . GetCurrentWorkWeekRange(), "range, week, monday, friday", (*) => InsertText(GetCurrentWorkWeekRange()))
}

GetIsoWeekInfo(dt := "") {
    timestamp := (dt != "") ? dt : A_Now
    yw := FormatTime(timestamp, "YWeek")
    isoYear := SubStr(yw, 1, 4)
    isoWkNum := Integer(SubStr(yw, 5, 2))
    return {
        year: isoYear,
        week: isoWkNum,
        formatted: "Week " . isoWkNum . ", " . isoYear,
        isoString: isoYear . "-W" . SubStr(yw, 5, 2)
    }
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
