; ======================================================================================================================
; Module: CSVParser.ahk - RFC-Compliant Full-Stream CSV Parser & Formatter State Machine
; ======================================================================================================================

#Requires AutoHotkey v2.0

ParseFullCSV(csvContent) {
    if (csvContent = "")
        return []

    ; Strip UTF-8 BOM if present
    if (SubStr(csvContent, 1, 1) = Chr(0xFEFF) || SubStr(csvContent, 1, 1) = Chr(65279))
        csvContent := SubStr(csvContent, 2)

    local rows         := []
    local currentRow   := []
    local currentField := ""
    local inQuotes     := false
    local chars        := StrSplit(csvContent)
    local i            := 1
    local len          := chars.Length

    while i <= len {
        local ch := chars[i]
        if (ch = '"') {
            if (inQuotes && i < len && chars[i + 1] = '"') {
                currentField .= '"'   ; Escaped quote ("") -> literal quote
                i++
            } else {
                inQuotes := !inQuotes
            }
        } else if (ch = ',' && !inQuotes) {
            currentRow.Push(currentField)
            currentField := ""
        } else if ((ch = "`n" || ch = "`r") && !inQuotes) {
            if (ch = "`r" && i < len && chars[i + 1] = "`n")
                i++
            currentRow.Push(currentField)
            if (currentRow.Length > 0 && (currentRow.Length > 1 || currentRow[1] != ""))
                rows.Push(currentRow)
            currentRow := []
            currentField := ""
        } else {
            currentField .= ch
        }
        i++
    }
    if (currentField != "" || currentRow.Length > 0) {
        currentRow.Push(currentField)
        if (currentRow.Length > 1 || currentRow[1] != "")
            rows.Push(currentRow)
    }
    return rows
}

FormatCSVField(val) {
    strVal := String(val)
    if (InStr(strVal, '"') || InStr(strVal, ',') || InStr(strVal, "`n") || InStr(strVal, "`r")) {
        return '"' . StrReplace(strVal, '"', '""') . '"'
    }
    return strVal
}

FormatCSVRow(fields) {
    line := ""
    for idx, f in fields {
        line .= (idx > 1 ? "," : "") . FormatCSVField(f)
    }
    return line . "`n"
}
