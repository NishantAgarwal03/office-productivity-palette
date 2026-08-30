#Requires AutoHotkey v2.0
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\Globals.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\CivilConverterEngine.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\MathEvaluator.ahk"

queries := [
    "5m diagonal 3m side",
    "5m diag 4m height",
    "tircha 5 side 3"
]

res := ""
for q in queries {
    r := CivilConverterEngine.Evaluate(q)
    mEv := SafeEvaluateMath(q)
    res .= "Query: [" . q . "]`n"
    res .= "  CivilEngine: " . (r.success ? r.resultStr : r.message) . "`n"
    res .= "  MathEval:    " . (mEv.success ? mEv.resultStr : mEv.errorMessage) . "`n`n"
}

outFile := "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\user_queries_verify.txt"
try FileDelete(outFile)
FileAppend(res, outFile, "UTF-8")
ExitApp()
