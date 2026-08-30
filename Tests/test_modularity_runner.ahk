; ======================================================================================================================
; Comprehensive Modularity & Symbiotic Architecture Test Suite
; Part of Office Productivity Hub & Action Board (v2.0.1)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

; --- Core Test Harness & Production Libraries ---
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\CivilUnits.ahk"
#Include "..\Lib\CivilCrossPhysics.ahk"
#Include "..\Lib\CivilPythagoras.ahk"
#Include "..\Lib\CivilRebar.ahk"
#Include "..\Lib\CivilSurvey.ahk"
#Include "..\Lib\CivilEstimator.ahk"
#Include "..\Lib\CivilConverterEngine.ahk"

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
        Failures.Push({category: category, testName: name, error: Format("Expected {1:0.3f}, got {2:0.3f}", expectedVal, actualVal)})
    }
}

try {
    ; ==================================================================================================================
    ; 1. Contract Uniformity Tests (All domain engines implement .Evaluate returning standard object)
    ; ==================================================================================================================
    rPyth := CivilPythagoras.Evaluate("pythagoras 3 4")
    AssertTrue("Contract_Uniformity", "CivilPythagoras returns object", IsObject(rPyth))
    AssertTrue("Contract_Uniformity", "CivilPythagoras schema success prop", rPyth.HasOwnProp("success") && rPyth.success == true)
    AssertTrue("Contract_Uniformity", "CivilPythagoras schema val prop", rPyth.HasOwnProp("val") && rPyth.val == 5.0)
    AssertTrue("Contract_Uniformity", "CivilPythagoras schema unit prop", rPyth.HasOwnProp("unit") && rPyth.unit == "m")
    AssertTrue("Contract_Uniformity", "CivilPythagoras schema resultStr prop", rPyth.HasOwnProp("resultStr") && StrLen(rPyth.resultStr) > 0)
    AssertTrue("Contract_Uniformity", "CivilPythagoras schema displayExpr prop", rPyth.HasOwnProp("displayExpr") && StrLen(rPyth.displayExpr) > 0)

    rEst := CivilEstimator.Evaluate("1000 sqft construction cost")
    AssertTrue("Contract_Uniformity", "CivilEstimator returns object", IsObject(rEst))
    AssertTrue("Contract_Uniformity", "CivilEstimator schema success prop", rEst.HasOwnProp("success") && rEst.success == true)
    AssertTrue("Contract_Uniformity", "CivilEstimator schema val prop", rEst.HasOwnProp("val") && rEst.val > 0)
    AssertTrue("Contract_Uniformity", "CivilEstimator schema unit prop", rEst.HasOwnProp("unit") && rEst.unit == "INR")
    AssertTrue("Contract_Uniformity", "CivilEstimator schema resultStr prop", rEst.HasOwnProp("resultStr") && StrLen(rEst.resultStr) > 0)

    rRebar := CivilRebar.Evaluate("12mm bar weight")
    AssertTrue("Contract_Uniformity", "CivilRebar returns object", IsObject(rRebar))
    AssertTrue("Contract_Uniformity", "CivilRebar schema success prop", rRebar.HasOwnProp("success") && rRebar.success == true)
    AssertTrue("Contract_Uniformity", "CivilRebar schema val prop", rRebar.HasOwnProp("val") && Abs(rRebar.val - 0.887) <= 0.01)
    AssertTrue("Contract_Uniformity", "CivilRebar schema unit prop", rRebar.HasOwnProp("unit") && rRebar.unit == "kg/m")

    rCross := CivilCrossPhysics.Evaluate("10 m to sqft")
    AssertTrue("Contract_Uniformity", "CivilCrossPhysics returns object", IsObject(rCross))
    AssertTrue("Contract_Uniformity", "CivilCrossPhysics schema success prop", rCross.HasOwnProp("success") && rCross.success == true)
    AssertTrue("Contract_Uniformity", "CivilCrossPhysics schema val prop", rCross.HasOwnProp("val") && Abs(rCross.val - 1076.391) <= 0.05)
    AssertTrue("Contract_Uniformity", "CivilCrossPhysics schema unit prop", rCross.HasOwnProp("unit") && rCross.unit == "sq ft")


    rConv := CivilConverterEngine.Evaluate("10 m to ft")
    AssertTrue("Contract_Uniformity", "CivilConverterEngine returns object", IsObject(rConv))
    AssertTrue("Contract_Uniformity", "CivilConverterEngine schema success prop", rConv.HasOwnProp("success") && rConv.success == true)
    AssertTrue("Contract_Uniformity", "CivilConverterEngine schema val prop", rConv.HasOwnProp("val") && Abs(rConv.val - 32.808) <= 0.01)
    AssertTrue("Contract_Uniformity", "CivilConverterEngine schema unit prop", rConv.HasOwnProp("unit") && rConv.unit == "ft")

    rMath := SafeEvaluateMath("1500 * 1.18 + 450")
    AssertTrue("Contract_Uniformity", "SafeEvaluateMath returns object", IsObject(rMath))
    AssertTrue("Contract_Uniformity", "SafeEvaluateMath schema success prop", rMath.HasOwnProp("success") && rMath.success == true)
    AssertTrue("Contract_Uniformity", "SafeEvaluateMath schema result prop", rMath.HasOwnProp("result") && Abs(rMath.result - 2220.0) <= 0.01)
    AssertTrue("Contract_Uniformity", "SafeEvaluateMath schema resultStr prop", rMath.HasOwnProp("resultStr") && rMath.resultStr == "2220")

    ; Standard error rejection contract
    rErrPyth := CivilPythagoras.Evaluate("single_word_invalid")
    AssertTrue("Contract_Uniformity", "Invalid Pythagoras returns success=false", rErrPyth.HasOwnProp("success") && rErrPyth.success == false)
    AssertTrue("Contract_Uniformity", "Invalid Pythagoras provides explanatory message", rErrPyth.HasOwnProp("message") && StrLen(rErrPyth.message) > 0)

    ; ==================================================================================================================
    ; 2. Side-Effect Freedom Tests (Pure Compute Invariant: Zero clipboard/GUI side-effects)
    ; ==================================================================================================================
    originalClipboard := "MODULARITY_PURE_COMPUTE_GUARD_TOKEN_" . A_TickCount
    A_Clipboard := originalClipboard
    Sleep(20)

    ; Execute battery of domain engine queries
    _ := CivilPythagoras.Evaluate("120 100 hyp")
    _ := CivilEstimator.Evaluate("cost 1500 sqft house")
    _ := CivilRebar.Evaluate("16mm bar weight")
    _ := CivilConverterEngine.Evaluate("10 cum to cft")
    _ := SafeEvaluateMath("2500 * 18% + 1200")
    _ := CivilSurvey.Evaluate("1:100 slope 20m run")
    Sleep(20)

    AssertTrue("Side_Effect_Freedom", "Engines preserve clipboard during evaluation", A_Clipboard == originalClipboard)

    ; ==================================================================================================================
    ; 3. Symbiotic Cross-Tool Bridge Tests (Engines delegate to each other instead of duplicating)
    ; ==================================================================================================================
    ; MathEvaluator delegates Pythagoras to CivilPythagoras
    mPythBridge := SafeEvaluateMath("pythagoras 3 4")
    AssertTrue("Symbiotic_Bridges", "MathEvaluator bridges to CivilPythagoras", mPythBridge.success && Abs(mPythBridge.result - 5.0) <= 0.01)

    mInvBridge := SafeEvaluateMath("5m diagonal 3m side")
    AssertTrue("Symbiotic_Bridges", "MathEvaluator bridges to Inverse Pythagoras", mInvBridge.success && Abs(mInvBridge.result - 4.0) <= 0.01)

    mColloqBridge := SafeEvaluateMath("120 100 diag")
    AssertTrue("Symbiotic_Bridges", "MathEvaluator bridges to Colloquial Pythagoras", mColloqBridge.success && Abs(mColloqBridge.result - 156.205) <= 0.05)

    ; CivilPythagoras uses CivilUnits for canonical unit parsing
    rFtPyth := CivilPythagoras.Evaluate("diagonal 20ft 30ft")
    AssertTrue("Symbiotic_Bridges", "CivilPythagoras inherits unit 'ft' via CivilUnits", rFtPyth.success && rFtPyth.unit == "ft")

    ; CivilEstimator uses CivilUnits for area dimension parsing
    rEstSqft := CivilEstimator.Evaluate("1200 sqft house cost")
    AssertTrue("Symbiotic_Bridges", "CivilEstimator inherits area unit via CivilUnits", rEstSqft.success && rEstSqft.val > 0)

    ; ==================================================================================================================
    ; 4. Shared Primitive Reuse & Anti-Duplication Tests
    ; ==================================================================================================================
    tokens := ExtractNumericTokens("Payment of INR 1,25,000.50 received, balance $500.75 and 2.5 Cr pending")
    AssertTrue("Primitive_Reuse", "ExtractNumericTokens extracts all 3 multi-currency tokens", tokens.Length == 3)
    AssertTrue("Primitive_Reuse", "Token 1 parsed with INR currency", tokens[1].currency == "INR" && Abs(tokens[1].value - 125000.50) <= 0.01)
    AssertTrue("Primitive_Reuse", "Token 2 parsed with USD currency", tokens[2].currency == "USD" && Abs(tokens[2].value - 500.75) <= 0.01)
    AssertTrue("Primitive_Reuse", "Token 3 parsed with Indian Crore multiplier", Abs(tokens[3].value - 25000000.0) <= 0.01)

    ; Indian comma formatting primitive
    commaStr := FormatIndianCommas("12345678.50")
    AssertTrue("Primitive_Reuse", "FormatIndianCommas formats standard Indian grouping", commaStr == "1,23,45,678.50")

    ; CleanToMachineNumber primitive preserves non-number strings safely
    skuPreserved := CleanToMachineNumber("SKU-12-34-56")
    AssertTrue("Primitive_Reuse", "CleanToMachineNumber preserves alphanumeric data", skuPreserved == "SKU-12-34-56")

    ; ==================================================================================================================
    ; 5. Presentation Decoupling Tests (Pure numeric .val separated from localized .resultStr)
    ; ==================================================================================================================
    rDecouple := CivilPythagoras.Evaluate("30ft 40ft diagonal")
    AssertTrue("Presentation_Decoupling", "Raw numeric val is pure float (50.0)", IsFloat(rDecouple.val) && rDecouple.val == 50.0)
    AssertTrue("Presentation_Decoupling", "Formatted resultStr contains ft unit and imperial display", InStr(rDecouple.resultStr, "50.000 ft") && InStr(rDecouple.resultStr, "(50'-0.00`")"))
    AssertTrue("Presentation_Decoupling", "Display expression preserves mathematical formula", InStr(rDecouple.displayExpr, "30") && InStr(rDecouple.displayExpr, "40") && InStr(rDecouple.displayExpr, "²"))


} catch as err {
    FailCount++
    TestLogs.Push(Format("[FAIL] FatalException | {1} at Line {2}", err.Message, err.Line))
    Failures.Push({category: "FatalException", testName: "FatalException", error: err.Message . " (Line " . err.Line . ")"})
}

durationMs := A_TickCount - StartTick
EmitTestResults("test_modularity_runner", PassCount + FailCount, PassCount, FailCount, durationMs, TestLogs, Failures)
