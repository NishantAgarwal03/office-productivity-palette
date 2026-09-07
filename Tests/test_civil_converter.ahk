; ======================================================================================================================
; Comprehensive Assertion Test Suite for CivilConverterEngine
; Part of Office Productivity Hub & Action Board (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

; Include Globals, Civil Engine & Math Evaluator
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CivilConverterEngine.ahk"
#Include "..\Lib\MathEvaluator.ahk"

global PassCount := 0
global FailCount := 0
global TestLogs  := []
global Failures  := []
global StartTick := A_TickCount

AssertTrue(category, name, condition) {
    global PassCount, FailCount, TestLogs, Failures
    if (condition) {
        PassCount++
        TestLogs.Push(Format("[PASS] {1:-24} | {2}", category, name))
    } else {
        FailCount++
        TestLogs.Push(Format("[FAIL] {1:-24} | {2} -> Expected TRUE, got FALSE", category, name))
        Failures.Push({category: category, testName: name, error: "Expected TRUE, got FALSE"})
    }
}

AssertNear(category, name, resultObj, expectedVal, tolerance := 0.05) {
    global PassCount, FailCount, TestLogs, Failures
    if (!IsObject(resultObj) || !resultObj.HasOwnProp("val")) {
        FailCount++
        msg := (IsObject(resultObj) && resultObj.HasOwnProp("message")) ? resultObj.message : "No val returned"
        TestLogs.Push(Format("[FAIL] {1:-24} | {2:-40} -> Error: {3}", category, name, msg))
        Failures.Push({category: category, testName: name, error: msg})
        return
    }
    actualVal := resultObj.val
    diff := Abs(Float(actualVal) - Float(expectedVal))
    if (diff <= tolerance) {
        PassCount++
        TestLogs.Push(Format("[PASS] {1:-24} | {2:-40} -> Actual: {3:0.3f}, Expected: {4:0.3f}", category, name, actualVal, expectedVal))
    } else {
        FailCount++
        TestLogs.Push(Format("[FAIL] {1:-24} | {2:-40} -> Actual: {3:0.3f}, Expected: {4:0.3f} (Diff: {5:0.4f})", category, name, actualVal, expectedVal, diff))
        Failures.Push({category: category, testName: name, error: Format("Actual: {1:0.3f}, Expected: {2:0.3f}", actualVal, expectedVal)})
    }
}

try {
    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Length Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("10 m to ft")
    AssertNear("Length", "10 m to ft", r, 32.808)

    r := CivilConverterEngine.Evaluate("2500 mm in m")
    AssertNear("Length", "2500 mm to m", r, 2.500)

    ftInStr := "5" . Chr(39) . "-6" . Chr(34) . " to mm"
    r := CivilConverterEngine.Evaluate(ftInStr)
    AssertNear("Length", "5ft-6in to mm", r, 1676.4)

    r := CivilConverterEngine.Evaluate("12.5 ft to m")
    AssertNear("Length", "12.5 ft to m", r, 3.810)

    r := CivilConverterEngine.Evaluate("1 yard in m")
    AssertNear("Length", "1 yard in m", r, 0.9144)

    r := CivilConverterEngine.Evaluate("10 mtr to ft")
    AssertNear("Length", "10 mtr to ft", r, 32.808)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Area Tests (Including Uttarakhand Bigha 770 sqm default)
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("100 sqm to sqft")
    AssertNear("Area", "100 sqm to sqft", r, 1076.39)

    r := CivilConverterEngine.Evaluate("500 sqft to sqm")
    AssertNear("Area", "500 sqft to sqm", r, 46.45)

    r := CivilConverterEngine.Evaluate("1 acre in sqft")
    AssertNear("Area", "1 acre in sqft", r, 43560.0)

    r := CivilConverterEngine.Evaluate("2 hectare to acre")
    AssertNear("Area", "2 hectare to acre", r, 4.942)

    r := CivilConverterEngine.Evaluate("500 gaj to sqft")
    AssertNear("Area", "500 gaj to sqft", r, 4500.0)

    r := CivilConverterEngine.Evaluate("1 bigha to sqm")
    AssertNear("Area", "1 bigha to sqm (Uttarakhand)", r, 770.0)

    r := CivilConverterEngine.Evaluate("1 bigha to sqft")
    AssertNear("Area", "1 bigha to sqft (Uttarakhand)", r, 8288.21)

    r := CivilConverterEngine.Evaluate("1 nali to sqft")
    AssertNear("Area", "1 nali to sqft (Uttarakhand)", r, 414.41)

    r := CivilConverterEngine.Evaluate("1 guntha to sqft")
    AssertNear("Area", "1 guntha to sqft", r, 1089.0)

    r := CivilConverterEngine.Evaluate("100 sqft to brass_area")
    AssertNear("Area", "100 sqft to brass", r, 1.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. Volume Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("10 cum to cft")
    AssertNear("Volume", "10 cum to cft", r, 353.147)

    r := CivilConverterEngine.Evaluate("100 cft to cum")
    AssertNear("Volume", "100 cft to cum", r, 2.832)

    r := CivilConverterEngine.Evaluate("5000 litre in m3")
    AssertNear("Volume", "5000 litre in m3", r, 5.0)

    r := CivilConverterEngine.Evaluate("500 gallon to litre")
    AssertNear("Volume", "500 gallon to litre", r, 1892.7)

    r := CivilConverterEngine.Evaluate("1 brass to cft")
    AssertNear("Volume", "1 brass to cft", r, 100.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 4. Weight & Mass Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("1000 kg to ton")
    AssertNear("Weight", "1000 kg to ton", r, 1.0)

    r := CivilConverterEngine.Evaluate("2 tonne in kg")
    AssertNear("Weight", "2 tonne in kg", r, 2000.0)

    r := CivilConverterEngine.Evaluate("5 quintal to kg")
    AssertNear("Weight", "5 quintal to kg", r, 500.0)

    r := CivilConverterEngine.Evaluate("20 bags to kg")
    AssertNear("Weight", "20 cement bags to kg", r, 1000.0)

    r := CivilConverterEngine.Evaluate("1 MT to kg")
    AssertNear("Weight", "1 MT to kg", r, 1000.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 5. Force Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("100 kN to ton-force")
    AssertNear("Force", "100 kN to ton-force", r, 10.197)

    r := CivilConverterEngine.Evaluate("1000 kgf to kN")
    AssertNear("Force", "1000 kgf to kN", r, 9.807)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 6. Pressure / Stress Tests & Concrete Grades
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("25 MPa to N/mm2")
    AssertNear("Pressure", "25 MPa to N/mm2", r, 25.0)

    r := CivilConverterEngine.Evaluate("200 kPa in kg/cm2")
    AssertNear("Pressure", "200 kPa in kg/cm2", r, 2.039)

    r := CivilConverterEngine.Evaluate("2 bar to kg/cm2")
    AssertNear("Pressure", "2 bar to kg/cm2", r, 2.039)

    r := CivilConverterEngine.Evaluate("25 MPa in psi")
    AssertNear("Pressure", "25 MPa in psi", r, 3625.94)

    r := CivilConverterEngine.Evaluate("M25 to psi")
    AssertNear("Pressure", "M25 concrete to psi", r, 3625.94)

    r := CivilConverterEngine.Evaluate("M30 in MPa")
    AssertNear("Pressure", "M30 concrete in MPa", r, 30.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 7. Density Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("1800 kg/m3 to tonne/m3")
    AssertNear("Density", "1800 kg/m3 to tonne/m3", r, 1.8)

    r := CivilConverterEngine.Evaluate("1.6 g/cm3 to kg/m3")
    AssertNear("Density", "1.6 g/cm3 to kg/m3", r, 1600.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 8. Flow Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("10 l/s to lpm")
    AssertNear("Flow", "10 l/s to lpm", r, 600.0)

    r := CivilConverterEngine.Evaluate("10 LPS to m3/hr")
    AssertNear("Flow", "10 LPS to m3/hr", r, 36.0)

    r := CivilConverterEngine.Evaluate("500 lpm in m3/hr")
    AssertNear("Flow", "500 lpm in m3/hr", r, 30.0)

    r := CivilConverterEngine.Evaluate("100 cfm to lps")
    AssertNear("Flow", "100 cfm to lps", r, 47.19)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 9. Slope & Gradient Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("fall 100mm in 10m")
    AssertNear("Slope", "100mm fall in 10m (% slope)", r, 1.0)

    r := CivilConverterEngine.Evaluate("1:100 slope")
    AssertNear("Slope", "1:100 slope (fall in 10m)", r, 100.0)

    ; Concern 1 regression test: 1:100 slope with secondary run parameter (20m run => 200mm fall)
    r := CivilConverterEngine.Evaluate("1:100 slope", "20m")
    AssertNear("Slope", "1:100 slope with 20m run -> 200mm fall", r, 200.0)

    r := CivilConverterEngine.Evaluate("2% slope to degree")
    AssertNear("Slope", "2% slope to angle degree", r, 1.146)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 10. Angle / DMS Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("90 degree to rad")
    AssertNear("Angle", "90 deg to rad", r, 1.5708)

    dmsStr := "45° 30" . Chr(39) . " 15" . Chr(34) . " to decimal"
    r := CivilConverterEngine.Evaluate(dmsStr)
    AssertNear("Angle", "45 deg 30 min 15 sec to decimal deg", r, 45.5042)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 11. Rebar Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("12mm bar weight")
    AssertNear("Rebar", "12mm bar kg/m (IS 1786)", r, 0.887)

    r := CivilConverterEngine.Evaluate("16 dia bar kg/m")
    AssertNear("Rebar", "16mm bar kg/m", r, 1.578)

    r := CivilConverterEngine.Evaluate("500 kg 12mm bar")
    AssertNear("Rebar", "500 kg 12mm bar length", r, 563.47)

    r := CivilConverterEngine.Evaluate("100m 16mm steel")
    AssertNear("Rebar", "100m 16mm steel weight", r, 157.75)

    r := CivilConverterEngine.Evaluate("10mm @ 150 to 12mm")
    AssertNear("Rebar", "10mm @ 150 -> 12mm practical spacing", r, 215.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 12. Compound Rectangular & 3D Volume Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("10m x 20m kitna sqft")
    AssertNear("Compound", "10m x 20m to sqft", r, 2152.78)

    r := CivilConverterEngine.Evaluate("2m x 3m x 1.5m to cft")
    AssertNear("Compound", "2m x 3m x 1.5m to cft", r, 317.83)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 13. Progressive Parameter Disclosure & Intelligent Fallbacks Tests
    ; ------------------------------------------------------------------------------------------------------------------
    ; 13.1 Length -> Area (Blank param -> Square default 10m x 10m = 100 sqm = 1076.39 sqft)
    r := CivilConverterEngine.Evaluate("10 m to sqft", "")
    AssertNear("Progressive", "10 m to sqft (Default Square)", r, 1076.39)

    ; 13.2 Length -> Area (With width param 3 m -> 10m x 3m = 30 sqm = 322.92 sqft)
    r := CivilConverterEngine.Evaluate("10 m to sqft", "3m")
    AssertNear("Progressive", "10 m to sqft (Width = 3m)", r, 322.92)

    ; 13.3 Length -> Volume (Blank param -> Cube default 10m x 10m x 10m = 1000 cum)
    r := CivilConverterEngine.Evaluate("10 m to m3", "")
    AssertNear("Progressive", "10 m to m3 (Default Cube)", r, 1000.0)

    ; 13.4 Area -> Volume (Blank param -> Cube root depth sqrt(36) = 6m => 36 * 6 = 216 cum)
    r := CivilConverterEngine.Evaluate("36 sqm to m3", "")
    AssertNear("Progressive", "36 sqm to m3 (Default Cube depth 6m)", r, 216.0)

    ; 13.5 Area -> Volume (With slab thickness param 150mm -> 36 * 0.15 = 5.4 cum)
    r := CivilConverterEngine.Evaluate("36 sqm to m3", "150mm")
    AssertNear("Progressive", "36 sqm to m3 (Depth = 150mm)", r, 5.4)

    ; 13.6 Volume -> Mass (Blank param -> RCC Concrete 2400 kg/m3 => 10 * 2400 = 24000 kg)
    r := CivilConverterEngine.Evaluate("10 cum to kg", "")
    AssertNear("Progressive", "10 cum to kg (Default Concrete 2400)", r, 24000.0)

    ; 13.7 Volume -> Mass (With sand param 1600 kg/m3 => 10 * 1600 = 16000 kg)
    r := CivilConverterEngine.Evaluate("10 cum to kg", "sand")
    AssertNear("Progressive", "10 cum to kg (Param: sand)", r, 16000.0)

    ; Concern 3 regression tests: Fluid mass conversions (1000 L = 1 m3; Diesel = 840 kg, Petrol = 740 kg)
    r := CivilConverterEngine.Evaluate("1000 litre to kg", "diesel")
    AssertNear("Progressive", "1000 L diesel -> 840 kg", r, 840.0)

    r := CivilConverterEngine.Evaluate("1000 litre to kg", "petrol")
    AssertNear("Progressive", "1000 L petrol -> 740 kg", r, 740.0)

    ; 13.8 Force -> Pressure (Blank param -> Unit area 1.0 m2 => 500 kN / 1.0 m2 = 0.5 MPa)
    r := CivilConverterEngine.Evaluate("500 kN to MPa", "")
    AssertNear("Progressive", "500 kN to MPa (Default 1.0 m2)", r, 0.50)

    ; 13.9 Force -> Pressure (With footing area 2m x 2m = 4 m2 => 500 kN / 4 m2 = 0.125 MPa)
    r := CivilConverterEngine.Evaluate("500 kN to MPa", "2m x 2m")
    AssertNear("Progressive", "500 kN to MPa (Area = 4 m2)", r, 0.125)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 14. Dimensionally Incompatible Rejection Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("10 m to kg/m3")
    AssertTrue("Incompatible", "10 m to kg/m3 rejected", !r.success && (r.HasOwnProp("isIncompatible") && r.isIncompatible))

    r := CivilConverterEngine.Evaluate("5 L/s to kg/m3")
    AssertTrue("Incompatible", "5 L/s to kg/m3 rejected", !r.success && (r.HasOwnProp("isIncompatible") && r.isIncompatible))

    r := CivilConverterEngine.Evaluate("90 degree to bar")
    AssertTrue("Incompatible", "90 deg to bar rejected", !r.success && (r.HasOwnProp("isIncompatible") && r.isIncompatible))

    r := CivilConverterEngine.Evaluate("25 MPa to degree")
    AssertTrue("Incompatible", "25 MPa to degree rejected", !r.success && (r.HasOwnProp("isIncompatible") && r.isIncompatible))

    ; ------------------------------------------------------------------------------------------------------------------
    ; 15. Pythagoras & Diagonal Tests (All 40+ Variants & Site Vocabulary)
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("pythagoras 3 4")
    AssertNear("Pythagoras", "pythagoras 3 4 -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("Pythagoras theorem 3 4")
    AssertNear("Pythagoras", "Pythagoras theorem 3 4 -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("Pythagorean theorem 6 8")
    AssertNear("Pythagoras", "Pythagorean theorem 6 8 -> 10.0", r, 10.0)

    r := CivilConverterEngine.Evaluate("Pythagorus theorem 9 12")
    AssertNear("Pythagoras", "Pythagorus theorem 9 12 -> 15.0", r, 15.0)

    r := CivilConverterEngine.Evaluate("diagonal 20ft 30ft")
    AssertNear("Pythagoras", "diagonal 20ft 30ft -> 36.056 ft", r, 36.056)

    r := CivilConverterEngine.Evaluate("right triangle 3m 4m")
    AssertNear("Pythagoras", "right triangle 3m 4m -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("right-angle triangle 3m 4m")
    AssertNear("Pythagoras", "right-angle triangle 3m 4m -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("90 degree triangle 3 4")
    AssertNear("Pythagoras", "90 degree triangle 3 4 -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("90° check 3 4")
    AssertNear("Pythagoras", "90° check 3 4 -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("right angle check 3 4")
    AssertNear("Pythagoras", "right angle check 3 4 -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("corner-to-corner 10m 8m")
    AssertNear("Pythagoras", "corner-to-corner 10m 8m -> 12.806", r, 12.806)

    r := CivilConverterEngine.Evaluate("room diagonal 12ft 15ft")
    AssertNear("Pythagoras", "room diagonal 12ft 15ft -> 19.209", r, 19.209)

    r := CivilConverterEngine.Evaluate("slab diagonal 6m 8m")
    AssertNear("Pythagoras", "slab diagonal 6m 8m -> 10.0", r, 10.0)

    r := CivilConverterEngine.Evaluate("floor diagonal 4m 5m")
    AssertNear("Pythagoras", "floor diagonal 4m 5m -> 6.403", r, 6.403)

    r := CivilConverterEngine.Evaluate("direct distance 30m 40m")
    AssertNear("Pythagoras", "direct distance 30m 40m -> 50.0", r, 50.0)

    r := CivilConverterEngine.Evaluate("straight distance 30m 40m")
    AssertNear("Pythagoras", "straight distance 30m 40m -> 50.0", r, 50.0)

    r := CivilConverterEngine.Evaluate("guniya 3m 4m")
    AssertNear("Pythagoras", "guniya 3m 4m (Indian right angle) -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("tircha 3m 4m")
    AssertNear("Pythagoras", "tircha 3m 4m -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("tirchi length 6m 8m")
    AssertNear("Pythagoras", "tirchi length 6m 8m -> 10.0", r, 10.0)

    r := CivilConverterEngine.Evaluate("kona se kona 10 8")
    AssertNear("Pythagoras", "kona se kona 10 8 -> 12.806", r, 12.806)

    r := CivilConverterEngine.Evaluate("kone se kone 10m 8m")
    AssertNear("Pythagoras", "kone se kone 10m 8m -> 12.806", r, 12.806)

    r := CivilConverterEngine.Evaluate("3m base 4m height")
    AssertNear("Pythagoras", "3m base 4m height -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("vertical 4m horizontal 3m")
    AssertNear("Pythagoras", "vertical 4m horizontal 3m -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("3-4-5")
    AssertNear("Pythagoras", "3-4-5 rule shorthand -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("3 x 4 diagonal")
    AssertNear("Pythagoras", "3 x 4 diagonal -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("3 by 4 diagonal")
    AssertNear("Pythagoras", "3 by 4 diagonal -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("10x8 diag")
    AssertNear("Pythagoras", "10x8 diag -> 12.806", r, 12.806)

    r := CivilConverterEngine.Evaluate("3x4 hyp")
    AssertNear("Pythagoras", "3x4 hyp -> 5.0", r, 5.0)

    r := CivilConverterEngine.Evaluate("12x16 diag kitna")
    AssertNear("Pythagoras", "12x16 diag kitna -> 20.0", r, 20.0)

    r := CivilConverterEngine.Evaluate("10m 8m tircha")
    AssertNear("Pythagoras", "10m 8m tircha -> 12.806", r, 12.806)

    ; Inverse Pythagoras: Known Hypotenuse + Leg -> Solve Missing Leg
    r := CivilConverterEngine.Evaluate("5m diagonal 3m side")
    AssertNear("Pythagoras", "5m diagonal 3m side (Inverse) -> 4.0", r, 4.0)
    AssertTrue("Pythagoras", "5m diagonal 3m side detects 3-4-5 (3:5)", InStr(r.resultStr, "True 3-4-5 Triangle"))

    r := CivilConverterEngine.Evaluate("hyp 10 base 6")
    AssertNear("Pythagoras", "hyp 10 base 6 (Inverse) -> 8.0", r, 8.0)
    AssertTrue("Pythagoras", "hyp 10 base 6 detects 3-4-5 (3:5)", InStr(r.resultStr, "True 3-4-5 Triangle"))

    rInv45 := CivilConverterEngine.Evaluate("5m diagonal 4m side")
    AssertNear("Pythagoras", "5m diagonal 4m side (Inverse) -> 3.0", rInv45, 3.0)
    AssertTrue("Pythagoras", "5m diagonal 4m side detects 3-4-5 (4:5)", InStr(rInv45.resultStr, "True 3-4-5 Triangle"))

    ; 80/20 Non-Destructive Parsing & Dimension 90 Preservation Tests
    r := CivilConverterEngine.Evaluate("pythagoras 90 120")
    AssertNear("Pythagoras", "pythagoras 90 120 -> 150.0", r, 150.0)

    r := CivilConverterEngine.Evaluate("diagonal 90ft 120ft")
    AssertNear("Pythagoras", "diagonal 90ft 120ft -> 150.0", r, 150.0)

    r := CivilConverterEngine.Evaluate("pyth 120 100")
    AssertNear("Pythagoras", "pyth 120 100 -> 156.205", r, 156.205)

    r := CivilConverterEngine.Evaluate("120x100 pytha")
    AssertNear("Pythagoras", "120x100 pytha -> 156.205", r, 156.205)

    r := CivilConverterEngine.Evaluate("pythag 120,100")
    AssertNear("Pythagoras", "pythag 120,100 -> 156.205", r, 156.205)

    r := CivilConverterEngine.Evaluate("120+100 pyth")
    AssertNear("Pythagoras", "120+100 pyth -> 156.205", r, 156.205)

    r := CivilConverterEngine.Evaluate("120 100 slant")
    AssertNear("Pythagoras", "120 100 slant -> 156.205", r, 156.205)

    r := CivilConverterEngine.Evaluate("right tri 120 100")
    AssertNear("Pythagoras", "right tri 120 100 -> 156.205", r, 156.205)

    ; 3-Side Guniya Verification Tests
    rGunMatch := CivilConverterEngine.Evaluate("pythagoras 3m 4m 5m")
    AssertTrue("Pythagoras", "pythagoras 3m 4m 5m is Guniya match", rGunMatch.success && rGunMatch.isMatched && InStr(rGunMatch.resultStr, "Guniya Match"))

    rGunOut := CivilConverterEngine.Evaluate("diagonal 8m 10m 13.2m")
    AssertTrue("Pythagoras", "diagonal 8m 10m 13.2m detects out-of-square", rGunOut.success && !rGunOut.isMatched && InStr(rGunOut.resultStr, "OFF") && InStr(rGunOut.resultStr, "3-4-5 Fix"))

    rGunInv := CivilConverterEngine.Evaluate("pythagoras 5000 4000 4")
    AssertTrue("Pythagoras", "pythagoras 5000 4000 4 rejected as impossible triangle", !rGunInv.success && InStr(rGunInv.message, "Invalid triangle"))

    ; >3 Dimension Rejection (>3 dimensions strictly out of scope)
    r4D := CivilConverterEngine.Evaluate("pythagoras 90 90 120 150")
    AssertTrue("Pythagoras", "pythagoras 90 90 120 150 rejected as >3D out-of-scope", !r4D.success && InStr(r4D.message, "2D planar only"))

    ; 15.1 Math Evaluator (Leader c) Compatibility Bridge Tests
    mEval := SafeEvaluateMath("pythagoras 3 4")
    AssertTrue("Leader_c_Bridge", "Leader c 'pythagoras 3 4' success", mEval.success)
    AssertTrue("Leader_c_Bridge", "Leader c 'pythagoras 3 4' val = 5", Abs(mEval.result - 5.0) <= 0.01)

    mEval2 := SafeEvaluateMath("diagonal 20ft 30ft")
    AssertTrue("Leader_c_Bridge", "Leader c 'diagonal 20ft 30ft' success", mEval2.success)
    AssertTrue("Leader_c_Bridge", "Leader c 'diagonal 20ft 30ft' val ~ 36.056", Abs(mEval2.result - 36.056) <= 0.05)

    mEval3 := SafeEvaluateMath("guniya 3m 4m")
    AssertTrue("Leader_c_Bridge", "Leader c 'guniya 3m 4m' success", mEval3.success)
    AssertTrue("Leader_c_Bridge", "Leader c 'guniya 3m 4m' val = 5", Abs(mEval3.result - 5.0) <= 0.01)

    mEval4 := SafeEvaluateMath("5m diagonal 3m side")
    AssertTrue("Leader_c_Bridge", "Leader c '5m diagonal 3m side' success", mEval4.success)
    AssertTrue("Leader_c_Bridge", "Leader c '5m diagonal 3m side' val = 4", Abs(mEval4.result - 4.0) <= 0.01)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 16. Rate Converter Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("500 per sqft to sqm")
    AssertNear("RateConverter", "Rs 500/sqft to sqm", r, 5381.96)

    r := CivilConverterEngine.Evaluate("4500 per cum to cft")
    AssertNear("RateConverter", "Rs 4500/cum to cft", r, 127.43)

    r := CivilConverterEngine.Evaluate("2500 per brass to cft")
    AssertNear("RateConverter", "Rs 2500/brass to cft", r, 25.0)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 17. Thumb Rule Cost Estimator Tests
    ; ------------------------------------------------------------------------------------------------------------------
    r := CivilConverterEngine.Evaluate("cost 1500 sqft house")
    AssertNear("CostEstimator", "cost 1500 sqft (@ 1800/sqft)", r, 2737970.89, 1.0)

} catch as err {
    FailCount++
    TestLogs.Push(Format("[FAIL] FatalException | {1} at Line {2}", err.Message, err.Line))
    Failures.Push({category: "FatalException", testName: "FatalException", error: err.Message . " (Line " . err.Line . ")"})
}

durationMs := A_TickCount - StartTick
EmitTestResults("test_civil_converter", PassCount + FailCount, PassCount, FailCount, durationMs, TestLogs, Failures)
