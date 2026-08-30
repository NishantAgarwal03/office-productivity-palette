#Requires AutoHotkey v2.0
#Include "Lib\CSVParser.ahk"

csvTest := "a,b,c`n`"quoted, comma`",`"multi`nline`",`"inner `"`"quote`"`"`n1,2,3"
parsed := ParseFullCSV(csvTest)

out := "Rows: " . parsed.Length . "`n"
for rIdx, row in parsed {
    out .= "Row " . rIdx . " (" . row.Length . " cols): "
    for cIdx, col in row {
        out .= "[" . StrReplace(col, "`n", "\n") . "] "
    }
    out .= "`n"
}

logPath := A_ScriptDir . "\csv_diag.log"
try FileDelete(logPath)
FileAppend(out, logPath, "UTF-8")
ExitApp(0)
