; Safe verification of the modular civil architecture
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\Globals.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\CSVParser.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\ClipboardHelper.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\NumberParser.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\MathEvaluator.ahk"
#Include "c:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\Lib\CivilConverterEngine.ahk"

out := "========================================================`n"
out .= "        MODULAR CIVIL ARCHITECTURE AUDIT REPORT          `n"
out .= "========================================================`n"

testCases := [
    ; 1. CivilUnits Direct Conversions
    ["CivilUnits", "10 m to ft", "10 m to ft", 32.808],
    ["CivilUnits", "1 bigha to sqm (Uttarakhand)", "1 bigha to sqm", 770.0],
    ["CivilUnits", "1 nali to sqm", "1 nali to sqm", 38.5],
    ["CivilUnits", "100 sqm to sqft", "100 sqm to sqft", 1076.39],
    ["CivilUnits", "5 cum to cft", "5 cum to cft", 176.57],
    ["CivilUnits", "1 brass to cft", "1 brass to cft", 100.0],
    ["CivilUnits", "100 kg to quintal", "100 kg to quintal", 1.0],
    ["CivilUnits", "1000 kg to tonne", "1000 kg to tonne", 1.0],
    ["CivilUnits", "10 kN to kgf", "10 kN to kgf", 1019.72],
    ["CivilUnits", "1 MPa to psi", "1 MPa to psi", 145.038],

    ; 2. Cross-Dimensional Handlers
    ["CrossDim", "10m to sqft (Square)", "10m to sqft", 1076.39],
    ["CrossDim", "2m to cft (Cube)", "2m to cft", 282.52],
    ["CrossDim", "100 sqm to cft (Cube Root)", "100 sqm to cft", 35314.67],
    ["CrossDim", "1 cum to kg (RCC 2400)", "1 cum to kg", 2400.0],
    ["CrossDim", "5000 litre water to kg", "5000 litre water to kg", 5000.0],
    ["CrossDim", "100 kN to mpa (1 m²)", "100 kN to mpa", 0.1],

    ; 3. CivilPythagoras
    ["Pythagoras", "pythagoras 3 4 -> 5.0", "pythagoras 3 4", 5.0],
    ["Pythagoras", "guniya 3m 4m -> 5.0", "guniya 3m 4m", 5.0],
    ["Pythagoras", "tircha 10m 8m -> 12.806", "tircha 10m 8m", 12.806],
    ["Pythagoras", "5m diagonal 3m side (Inverse) -> 4.0", "5m diagonal 3m side", 4.0],
    ["Pythagoras", "3m side 5m diagonal (Inverse) -> 4.0", "3m side 5m diagonal", 4.0],
    ["Pythagoras", "tircha 5 side 3 (Inverse) -> 4.0", "tircha 5 side 3", 4.0],
    ["Pythagoras", "hyp 10 base 6 (Inverse) -> 8.0", "hyp 10 base 6", 8.0],

    ; 4. CivilRebar
    ["CivilRebar", "12mm bar unit weight -> 0.887 kg/m", "12mm bar weight", 0.887],
    ["CivilRebar", "16mm bar 100m -> 157.75 kg", "100m 16mm steel", 157.75],
    ["CivilRebar", "10mm @ 150 to 12mm -> 215 mm", "10mm @ 150 to 12mm", 215.0],

    ; 5. CivilEstimator & CivilSurvey
    ["Estimator", "500 per sqft to sqm -> 5381.96", "Rs 500 per sqft to sqm", 5381.96],
    ["Survey", "1:100 slope over 10m -> 100 mm fall", "1:100 slope", 100.0],
    ["Survey", "M25 to psi -> 3625.94 psi", "M25 to psi", 3625.94],
    ["Survey", "45° 30' 00`" to decimal -> 45.5°", "45° 30' 00", 45.5]
]

passCount := 0
failCount := 0

for item in testCases {
    modName := item[1]
    desc := item[2]
    query := item[3]
    expected := item[4]
    
    try {
        res := CivilConverterEngine.Evaluate(query)
        if (IsObject(res) && res.HasOwnProp("val")) {
            actual := res.val
            diff := Abs(Float(actual) - Float(expected))
            tol := 0.05 * Float(expected) + 0.05
            if (diff <= tol) {
                passCount++
                out .= Format("[PASS] {1:-15} | {2:-42} -> {3:0.3f}`n", modName, desc, actual)
            } else {
                failCount++
                out .= Format("[FAIL] {1:-15} | {2:-42} -> Got: {3:0.3f}, Exp: {4:0.3f}`n", modName, desc, actual, expected)
            }
        } else {
            failCount++
            errMsg := (IsObject(res) && res.HasOwnProp("message")) ? res.message : "No val property"
            out .= Format("[FAIL] {1:-15} | {2:-42} -> Error: {3}`n", modName, desc, errMsg)
        }
    } catch as err {
        failCount++
        out .= Format("[FAIL] {1:-15} | {2:-42} -> Exception: {3}`n", modName, desc, err.Message)
    }
}

out .= "`n" . Format("Summary: Total = {1}, Passed = {2}, Failed = {3}, Rate = {4:0.1f}%`n", 
    passCount + failCount, passCount, failCount, (passCount / (passCount + failCount)) * 100)

FileAppend(out, "C:\Users\Admin\.gemini\antigravity\brain\74aecdd3-3a4b-4626-96ff-0f2be091f3a1\scratch\safe_output.txt", "UTF-8")
ExitApp(failCount > 0 ? 1 : 0)
