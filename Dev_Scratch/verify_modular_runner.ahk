; Direct verification of the modular civil architecture
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "Lib\Globals.ahk"
#Include "Lib\CSVParser.ahk"
#Include "Lib\ClipboardHelper.ahk"
#Include "Lib\NumberParser.ahk"
#Include "Lib\MathEvaluator.ahk"
#Include "Lib\CivilConverterEngine.ahk"

out := "========================================================`n"
out .= "        MODULAR CIVIL ARCHITECTURE AUDIT REPORT          `n"
out .= "========================================================`n"

tests := [
    ; 1. CivilUnits Direct Conversions
    ["CivilUnits", "10 m to ft", CivilConverterEngine.Evaluate("10 m to ft").val, 32.808],
    ["CivilUnits", "1 bigha to sqm (Uttarakhand)", CivilConverterEngine.Evaluate("1 bigha to sqm").val, 770.0],
    ["CivilUnits", "1 nali to sqm", CivilConverterEngine.Evaluate("1 nali to sqm").val, 38.5],
    ["CivilUnits", "100 sqm to sqft", CivilConverterEngine.Evaluate("100 sqm to sqft").val, 1076.39],
    ["CivilUnits", "5 cum to cft", CivilConverterEngine.Evaluate("5 cum to cft").val, 176.57],
    ["CivilUnits", "1 brass to cft", CivilConverterEngine.Evaluate("1 brass to cft").val, 100.0],
    ["CivilUnits", "100 kg to quintal", CivilConverterEngine.Evaluate("100 kg to quintal").val, 1.0],
    ["CivilUnits", "1000 kg to tonne", CivilConverterEngine.Evaluate("1000 kg to tonne").val, 1.0],
    ["CivilUnits", "10 kN to kgf", CivilConverterEngine.Evaluate("10 kN to kgf").val, 1019.72],
    ["CivilUnits", "1 MPa to psi", CivilConverterEngine.Evaluate("1 MPa to psi").val, 145.038],

    ; 2. Cross-Dimensional Handlers
    ["CrossDim", "10m to sqft (Square)", CivilConverterEngine.Evaluate("10m to sqft").val, 1076.39],
    ["CrossDim", "2m to cft (Cube)", CivilConverterEngine.Evaluate("2m to cft").val, 282.52],
    ["CrossDim", "100 sqm to cft (Cube Root)", CivilConverterEngine.Evaluate("100 sqm to cft").val, 35314.67],
    ["CrossDim", "1 cum to kg (RCC 2400)", CivilConverterEngine.Evaluate("1 cum to kg").val, 2400.0],
    ["CrossDim", "5000 litre water to kg", CivilConverterEngine.Evaluate("5000 litre water to kg").val, 5000.0],
    ["CrossDim", "100 kN to mpa (1 m²)", CivilConverterEngine.Evaluate("100 kN to mpa").val, 0.1],

    ; 3. CivilPythagoras
    ["Pythagoras", "pythagoras 3 4 -> 5.0", CivilConverterEngine.Evaluate("pythagoras 3 4").val, 5.0],
    ["Pythagoras", "guniya 3m 4m -> 5.0", CivilConverterEngine.Evaluate("guniya 3m 4m").val, 5.0],
    ["Pythagoras", "tircha 10m 8m -> 12.806", CivilConverterEngine.Evaluate("tircha 10m 8m").val, 12.806],
    ["Pythagoras", "5m diagonal 3m side (Inverse) -> 4.0", CivilConverterEngine.Evaluate("5m diagonal 3m side").val, 4.0],
    ["Pythagoras", "3m side 5m diagonal (Inverse) -> 4.0", CivilConverterEngine.Evaluate("3m side 5m diagonal").val, 4.0],
    ["Pythagoras", "tircha 5 side 3 (Inverse) -> 4.0", CivilConverterEngine.Evaluate("tircha 5 side 3").val, 4.0],
    ["Pythagoras", "hyp 10 base 6 (Inverse) -> 8.0", CivilConverterEngine.Evaluate("hyp 10 base 6").val, 8.0],

    ; 4. CivilRebar
    ["CivilRebar", "12mm bar unit weight -> 0.887 kg/m", CivilConverterEngine.Evaluate("12mm bar weight").val, 0.887],
    ["CivilRebar", "16mm bar 100m -> 157.75 kg", CivilConverterEngine.Evaluate("100m 16mm steel").val, 157.75],
    ["CivilRebar", "10mm @ 150 to 12mm -> 215 mm", CivilConverterEngine.Evaluate("10mm @ 150 to 12mm").val, 215.0],

    ; 5. CivilEstimator & CivilSurvey
    ["Estimator", "500 per sqft to sqm -> 5381.96", CivilConverterEngine.Evaluate("Rs 500 per sqft to sqm").val, 5381.96],
    ["Survey", "1:100 slope over 10m -> 100 mm fall", CivilConverterEngine.Evaluate("1:100 slope").val, 100.0],
    ["Survey", "M25 to psi -> 3625.94 psi", CivilConverterEngine.Evaluate("M25 to psi").val, 3625.94],
    ["Survey", "45° 30' 00\" to decimal -> 45.5°", CivilConverterEngine.Evaluate("45° 30' 00\"").val, 45.5]
]

passCount := 0
failCount := 0

for item in tests {
    modName := item[1]
    desc := item[2]
    actual := item[3]
    expected := item[4]
    
    diff := Abs(Float(actual) - Float(expected))
    if (diff <= 0.05 * Float(expected) + 0.05) {
        passCount++
        out .= Format("[PASS] {1:-15} | {2:-42} -> {3:0.3f}`n", modName, desc, actual)
    } else {
        failCount++
        out .= Format("[FAIL] {1:-15} | {2:-42} -> Got: {3:0.3f}, Exp: {4:0.3f}`n", modName, desc, actual, expected)
    }
}

out .= "`n" . Format("Summary: Total = {1}, Passed = {2}, Failed = {3}, Rate = {4:0.1f}%", 
    passCount + failCount, passCount, failCount, (passCount / (passCount + failCount)) * 100)

FileAppend(out, A_ScriptDir . "\modular_audit_results.txt", "UTF-8")
ExitApp(failCount > 0 ? 1 : 0)
