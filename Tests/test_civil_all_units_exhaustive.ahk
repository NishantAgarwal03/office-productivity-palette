; ======================================================================================================================
; Comprehensive Exhaustive Unit & Alias Test Suite for CivilUnits & CivilConverterEngine
; Validates every canonical unit key, regional alias, Hindi script, rebar sizes, rates, and formulas.
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\CivilConverterEngine.ahk"

global TestsPassed := 0
global TestsFailed := 0
global TestLogs := []
global Failures := []
global StartTick := A_TickCount

AssertEqual(suite, testName, actual, expected, tolerance := 0.005) {
    global TestsPassed, TestsFailed, TestLogs, Failures
    if (IsNumber(actual) && IsNumber(expected)) {
        diff := Abs(Float(actual) - Float(expected))
        if (diff <= tolerance) {
            TestsPassed++
            TestLogs.Push("[PASS] " . suite . " | " . testName . " -> " . actual . " (expected: " . expected . ")")
            return
        }
    } else if (actual == expected) {
        TestsPassed++
        TestLogs.Push("[PASS] " . suite . " | " . testName . " -> " . String(actual))
        return
    }
    TestsFailed++
    TestLogs.Push("[FAIL] " . suite . " | " . testName . " -> Got: '" . String(actual) . "', Expected: '" . String(expected) . "'")
    Failures.Push({category: suite, testName: testName, error: "Got: '" . String(actual) . "', Expected: '" . String(expected) . "'"})
}

AssertEvaluates(suite, query, expectedVal, tolerance := 0.05) {
    global TestsPassed, TestsFailed, TestLogs
    res := CivilConverterEngine.Evaluate(query)
    if (!IsObject(res) || !res.HasOwnProp("val")) {
        TestsFailed++
        TestLogs.Push("[FAIL] " . suite . " | Query: '" . query . "' -> Returned invalid object")
        return
    }
    AssertEqual(suite, query, res.val, expectedVal, tolerance)
}

try {
    ; 1. Exhaustive Registry Completeness
    allKeysCount := 0
    for k, v in CivilUnits.UnitRegistry {
        allKeysCount++
        if (!v.HasOwnProp("dim") || !v.HasOwnProp("factor") || v.factor <= 0) {
            TestsFailed++
            TestLogs.Push("[FAIL] Registry | Key '" . k . "' missing dim/factor")
        }
    }
    AssertEqual("Registry", "Total Registered Unit Keys >= 120", allKeysCount >= 120, true)

    ; 2. Length Dimension Aliases to Metres
    AssertEvaluates("Length", "10 m to m", 10.0)
    AssertEvaluates("Length", "10 meter to m", 10.0)
    AssertEvaluates("Length", "10 metre to m", 10.0)
    AssertEvaluates("Length", "10 mtr to m", 10.0)
    AssertEvaluates("Length", "10 mts to m", 10.0)
    AssertEvaluates("Length", "10 metres to m", 10.0)
    AssertEvaluates("Length", "10 meters to m", 10.0)
    AssertEvaluates("Length", "10 rmt to m", 10.0)
    AssertEvaluates("Length", "10 running meter to m", 10.0)
    AssertEvaluates("Length", "10 running metre to m", 10.0)
    AssertEvaluates("Length", "1000 mm to m", 1.0)
    AssertEvaluates("Length", "1000 millimeter to m", 1.0)
    AssertEvaluates("Length", "1000 millimetre to m", 1.0)
    AssertEvaluates("Length", "100 cm to m", 1.0)
    AssertEvaluates("Length", "100 centimeter to m", 1.0)
    AssertEvaluates("Length", "100 centimetre to m", 1.0)
    AssertEvaluates("Length", "1 km to m", 1000.0)
    AssertEvaluates("Length", "1 kilometer to m", 1000.0)
    AssertEvaluates("Length", "1 kilometre to m", 1000.0)
    AssertEvaluates("Length", "100 inch to in", 100.0)
    AssertEvaluates("Length", "100 in to in", 100.0)
    AssertEvaluates("Length", "100 inches to in", 100.0)
    AssertEvaluates("Length", '100 " to in', 100.0)
    AssertEvaluates("Length", "10 ft to ft", 10.0)
    AssertEvaluates("Length", "10 foot to ft", 10.0)
    AssertEvaluates("Length", "10 feet to ft", 10.0)
    AssertEvaluates("Length", "10 feets to ft", 10.0)
    AssertEvaluates("Length", "10 ' to ft", 10.0)
    AssertEvaluates("Length", "10 rft to ft", 10.0)
    AssertEvaluates("Length", "10 running ft to ft", 10.0)
    AssertEvaluates("Length", "10 running feet to ft", 10.0)
    AssertEvaluates("Length", "10 running foot to ft", 10.0)
    AssertEvaluates("Length", "10 yd to m", 9.144)
    AssertEvaluates("Length", "10 yard to m", 9.144)
    AssertEvaluates("Length", "10 yards to m", 9.144)

    ; 3. Area Dimension Aliases & Regional Land Units
    AssertEvaluates("Area", "100 sqm to sqft", 1076.39)
    AssertEvaluates("Area", "100 sq m to sqft", 1076.39)
    AssertEvaluates("Area", "100 m2 to sqft", 1076.39)
    AssertEvaluates("Area", "100 m² to sqft", 1076.39)
    AssertEvaluates("Area", "100 sqmt to sqft", 1076.39)
    AssertEvaluates("Area", "100 square meter to sqft", 1076.39)
    AssertEvaluates("Area", "100 square metre to sqft", 1076.39)
    AssertEvaluates("Area", "100 square meters to sqft", 1076.39)
    AssertEvaluates("Area", "1000000 sqmm to sqm", 1.0)
    AssertEvaluates("Area", "1000000 mm2 to sqm", 1.0)
    AssertEvaluates("Area", "1000000 mm² to sqm", 1.0)
    AssertEvaluates("Area", "10000 sqcm to sqm", 1.0)
    AssertEvaluates("Area", "10000 cm2 to sqm", 1.0)
    AssertEvaluates("Area", "10000 cm² to sqm", 1.0)
    AssertEvaluates("Area", "100 sqft to sqft", 100.0)
    AssertEvaluates("Area", "100 sq ft to sqft", 100.0)
    AssertEvaluates("Area", "100 sft to sqft", 100.0)
    AssertEvaluates("Area", "100 ft2 to sqft", 100.0)
    AssertEvaluates("Area", "100 ft² to sqft", 100.0)
    AssertEvaluates("Area", "100 square feet to sqft", 100.0)
    AssertEvaluates("Area", "100 square foot to sqft", 100.0)
    AssertEvaluates("Area", "100 sqyd to sqft", 900.0)
    AssertEvaluates("Area", "100 sq yd to sqft", 900.0)
    AssertEvaluates("Area", "100 yd2 to sqft", 900.0)
    AssertEvaluates("Area", "100 yd² to sqft", 900.0)
    AssertEvaluates("Area", "100 square yard to sqft", 900.0)
    AssertEvaluates("Area", "100 square yards to sqft", 900.0)
    AssertEvaluates("Area", "100 gaj to sqft", 900.0)
    AssertEvaluates("Area", "100 gaz to sqft", 900.0)
    AssertEvaluates("Area", "100 गज to sqft", 900.0)
    AssertEvaluates("Area", "1 acre in sqft", 43560.0)
    AssertEvaluates("Area", "1 acres in sqft", 43560.0)
    AssertEvaluates("Area", "1 hectare in sqm", 10000.0)
    AssertEvaluates("Area", "1 hectares in sqm", 10000.0)
    AssertEvaluates("Area", "1 ha in sqm", 10000.0)
    AssertEvaluates("Area", "1 guntha in sqft", 1089.0)
    AssertEvaluates("Area", "1 gunta in sqft", 1089.0)
    AssertEvaluates("Area", "1 गुंठा in sqft", 1089.0)
    AssertEvaluates("Area", "1 bigha to sqm", 770.0)
    AssertEvaluates("Area", "1 beegah to sqm", 770.0)
    AssertEvaluates("Area", "1 बीघा to sqm", 770.0)
    AssertEvaluates("Area", "1 nali to sqm", 38.5)
    AssertEvaluates("Area", "1 naali to sqm", 38.5)
    AssertEvaluates("Area", "1 नाली to sqm", 38.5)
    AssertEvaluates("Area", "1 katha to sqm", 66.89)
    AssertEvaluates("Area", "1 कट्ठा to sqm", 66.89)
    AssertEvaluates("Area", "1 brass_area in sqft", 100.0)

    ; 4. Volume Dimension Aliases & Construction Bulk Units
    AssertEvaluates("Volume", "10 cum to cft", 353.147)
    AssertEvaluates("Volume", "10 m3 to cft", 353.147)
    AssertEvaluates("Volume", "10 m³ to cft", 353.147)
    AssertEvaluates("Volume", "10 cubic meter to cft", 353.147)
    AssertEvaluates("Volume", "10 cubic metre to cft", 353.147)
    AssertEvaluates("Volume", "1000000 cmm to cum", 0.001)
    AssertEvaluates("Volume", "100 cft to cft", 100.0)
    AssertEvaluates("Volume", "100 cuft to cft", 100.0)
    AssertEvaluates("Volume", "100 ft3 to cft", 100.0)
    AssertEvaluates("Volume", "100 ft³ to cft", 100.0)
    AssertEvaluates("Volume", "100 cubic feet to cft", 100.0)
    AssertEvaluates("Volume", "100 cubic foot to cft", 100.0)
    AssertEvaluates("Volume", "1 brass to cft", 100.0)
    AssertEvaluates("Volume", "1 brass_vol to cft", 100.0)
    AssertEvaluates("Volume", "1 cuyd to cft", 27.0)
    AssertEvaluates("Volume", "1 yd3 to cft", 27.0)
    AssertEvaluates("Volume", "1 yd³ to cft", 27.0)
    AssertEvaluates("Volume", "1000 litre to cum", 1.0)
    AssertEvaluates("Volume", "1000 ltr to cum", 1.0)
    AssertEvaluates("Volume", "1000 l to cum", 1.0)
    AssertEvaluates("Volume", "100 gallon to litre", 378.541)
    AssertEvaluates("Volume", "100 gal to litre", 378.541)

    ; 5. Mass / Weight Dimension Aliases
    AssertEvaluates("Weight", "100 kg to kg", 100.0)
    AssertEvaluates("Weight", "1000 gm to kg", 1.0)
    AssertEvaluates("Weight", "1 tonne to kg", 1000.0)
    AssertEvaluates("Weight", "1 ton to kg", 1000.0)
    AssertEvaluates("Weight", "1 mt to kg", 1000.0)
    AssertEvaluates("Weight", "1 metric ton to kg", 1000.0)
    AssertEvaluates("Weight", "1 quintal to kg", 100.0)
    AssertEvaluates("Weight", "1 qtl to kg", 100.0)
    AssertEvaluates("Weight", "100 lb to kg", 45.359)
    AssertEvaluates("Weight", "100 lbs to kg", 45.359)
    AssertEvaluates("Weight", "100 pound to kg", 45.359)
    AssertEvaluates("Weight", "1 bags to kg", 50.0)
    AssertEvaluates("Weight", "1 cement bag to kg", 50.0)

    ; 6. Force & Structural Units
    AssertEvaluates("Force", "10 kn to n", 10000.0)
    AssertEvaluates("Force", "1000 n to kn", 1.0)
    AssertEvaluates("Force", "1000 kgf to kn", 9.80665)
    AssertEvaluates("Force", "1 tf to kn", 9.80665)
    AssertEvaluates("Force", "1 ton_force to kn", 9.80665)
    AssertEvaluates("Force", "10 kip to kn", 44.482)

    ; 7. Pressure & Stress Units
    AssertEvaluates("Pressure", "1 mpa to n/mm2", 1.0)
    AssertEvaluates("Pressure", "1 mpa to n/mm²", 1.0)
    AssertEvaluates("Pressure", "1000 kpa to mpa", 1.0)
    AssertEvaluates("Pressure", "1000000 pa to mpa", 1.0)
    AssertEvaluates("Pressure", "10 bar to mpa", 1.0)
    AssertEvaluates("Pressure", "1 mpa to psi", 145.038)
    AssertEvaluates("Pressure", "1 mpa to psf", 20885.43)
    AssertEvaluates("Pressure", "10 kgf/cm2 to mpa", 0.980665)
    AssertEvaluates("Pressure", "10 kgf/cm² to mpa", 0.980665)
    AssertEvaluates("Pressure", "1000 kn/m2 to mpa", 1.0)
    AssertEvaluates("Pressure", "1000 kn/m² to mpa", 1.0)

    ; 8. Density Units
    AssertEvaluates("Density", "2400 kg/cum to kg/cum", 2400.0)
    AssertEvaluates("Density", "2400 kg/m3 to kg/cum", 2400.0)
    AssertEvaluates("Density", "2400 kg/m³ to kg/cum", 2400.0)
    AssertEvaluates("Density", "2.4 g/cc to kg/cum", 2400.0)
    AssertEvaluates("Density", "2.4 gm/cc to kg/cum", 2400.0)
    AssertEvaluates("Density", "100 pcf to kg/cum", 1601.85)
    AssertEvaluates("Density", "100 lb/cft to kg/cum", 1601.85)
    AssertEvaluates("Density", "100 lb/ft3 to kg/cum", 1601.85)
    AssertEvaluates("Density", "100 lb/ft³ to kg/cum", 1601.85)

    ; 9. Flow Rate Units
    AssertEvaluates("Flow", "3600 cum/hr to lps", 1000.0)
    AssertEvaluates("Flow", "3600 m3/hr to lps", 1000.0)
    AssertEvaluates("Flow", "3600 m³/hr to lps", 1000.0)
    AssertEvaluates("Flow", "1 cum/sec to lps", 1000.0)
    AssertEvaluates("Flow", "1 m3/s to lps", 1000.0)
    AssertEvaluates("Flow", "1000 lps to cum/hr", 3600.0)
    AssertEvaluates("Flow", "1000 l/s to cum/hr", 3600.0)
    AssertEvaluates("Flow", "60000 lpm to lps", 1000.0)
    AssertEvaluates("Flow", "60000 l/min to lps", 1000.0)
    AssertEvaluates("Flow", "100 cfs to lps", 2831.68)
    AssertEvaluates("Flow", "100 cusec to lps", 2831.68)
    AssertEvaluates("Flow", "100 gpm to lps", 6.309)

    ; 10. Rebar Engineering & Diameters
    AssertEvaluates("Rebar", "6mm bar weight", 0.222)
    AssertEvaluates("Rebar", "8mm bar weight", 0.395)
    AssertEvaluates("Rebar", "10mm bar weight", 0.617)
    AssertEvaluates("Rebar", "12mm bar weight", 0.888)
    AssertEvaluates("Rebar", "16mm bar weight", 1.578)
    AssertEvaluates("Rebar", "20mm bar weight", 2.466)
    AssertEvaluates("Rebar", "25mm bar weight", 3.853)
    AssertEvaluates("Rebar", "32mm bar weight", 6.313)
    AssertEvaluates("Rebar", "100m 12mm steel", 88.74)
    AssertEvaluates("Rebar", "10mm @ 150 to 12mm", 215.0)

    ; 11. Pythagoras Calculations & Natural Site Queries
    AssertEvaluates("Pythagoras", "pythagoras 3 4", 5.0)
    AssertEvaluates("Pythagoras", "pythagoras 30ft 40ft", 50.0)
    AssertEvaluates("Pythagoras", "guniya 3m 4m", 5.0)
    AssertEvaluates("Pythagoras", "karna 6 8", 10.0)
    AssertEvaluates("Pythagoras", "कर्ण 6 8", 10.0)
    AssertEvaluates("Pythagoras", "tircha 10m 8m", 12.806)
    AssertEvaluates("Pythagoras", "hyp 10 base 6", 8.0)
    AssertEvaluates("Pythagoras", "5m diagonal 3m side", 4.0)

    ; 12. Rates & Thumb Rule Estimators
    AssertEvaluates("Rates", "Rs 500 per sqft to sqm", 5381.96)
    AssertEvaluates("Rates", "4500 per cum to cft", 127.43)
    AssertEvaluates("Estimator", "1000 sqft construction cost", 1813305.0)
    AssertEvaluates("Estimator", "cost 1000 sqft house", 1813305.0)
    AssertEvaluates("Estimator", "thumb rule 1000 sqft", 1813305.0)
} catch as err {
    TestsFailed++
    TestLogs.Push("[FATAL] Execution Error: " . err.Message . " at Line " . err.Line)
    Failures.Push({category: "FatalException", testName: "FatalException", error: err.Message . " (Line " . err.Line . ")"})
}

durationMs := A_TickCount - StartTick
EmitTestResults("test_civil_all_units_exhaustive", TestsPassed + TestsFailed, TestsPassed, TestsFailed, durationMs, TestLogs, Failures)
