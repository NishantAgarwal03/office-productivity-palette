#Requires AutoHotkey v2.0
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\Globals.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\CivilConverterEngine.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\MathEvaluator.ahk"

try {
    queries := [
        "5m diagonal 3m side",
        "5m diag 4m height",
        "tircha 5 side 3",
        "diagonal 5m 3m side",
        "hyp 5 base 3",
        "5 diagonal 3 side"
    ]

    res := ""
    for q in queries {
        r := CivilConverterEngine.Evaluate(q)
        mEv := SafeEvaluateMath(q)
        res .= "Query: [" . q . "]`n"
        res .= "  CivilEngine success: " . (r.success ? "YES" : "NO") . " -> " . (r.success ? r.resultStr : r.message) . "`n"
        res .= "  MathEval success:    " . (mEv.success ? "YES" : "NO") . " -> " . (mEv.success ? mEv.resultStr : mEv.errorMessage) . "`n`n"
    }

    FileAppend(res, "c:\Users\Admin\Documents\AutoHotkey\debug_pyth.txt", "UTF-8")
} catch as err {
    FileAppend("Error: " . err.Message . " Line: " . err.Line . "`n" . err.Stack, "c:\Users\Admin\Documents\AutoHotkey\debug_pyth.txt", "UTF-8")
}
ExitApp()
