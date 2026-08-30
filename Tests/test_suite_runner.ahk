; ======================================================================================================================
; Comprehensive Assertion-Based Test Runner for Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

ShowTextStats(*) => ""
LogAppError(*) => ""
ShowCivilConverter(*) => ""

; --- Pure Logic & Global Inclusions ---
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\Actions_Math.ahk"
#Include "..\Lib\Actions_DateTime.ahk"
#Include "..\Lib\Actions_Text.ahk"
#Include "..\Lib\Actions_Finance.ahk"
#Include "..\Lib\Actions_Extraction.ahk"
#Include "..\Lib\Actions_WindowPeek.ahk"
#Include "..\Lib\CivilConverterEngine.ahk"
#Include "..\Lib\Actions_CivilConvert.ahk"
#Include "..\Lib\Actions_Utility.ahk"
#Include "..\Lib\Core.ahk"

global PassCount := 0
global FailCount := 0
global TestLogs  := []
global Failures  := []
global StartTick := A_TickCount

AssertEqual(testCategory, testName, actual, expected) {
    global PassCount, FailCount, TestLogs, Failures
    actualStr := String(actual)
    expectedStr := String(expected)
    
    if (actualStr == expectedStr) {
        PassCount++
        TestLogs.Push(Format("[PASS] {1:-20} | {2:-38} -> '{3}'", testCategory, testName, actualStr))
    } else {
        FailCount++
        TestLogs.Push(Format("[FAIL] {1:-20} | {2:-38} -> Expected: '{3}', Got: '{4}'", testCategory, testName, expectedStr, actualStr))
        Failures.Push({category: testCategory, testName: testName, error: "Expected: '" . expectedStr . "', Got: '" . actualStr . "'"})
    }
}

AssertTrue(testCategory, testName, condition) {
    AssertEqual(testCategory, testName, condition ? "TRUE" : "FALSE", "TRUE")
}

AssertFalse(testCategory, testName, condition) {
    AssertEqual(testCategory, testName, condition ? "TRUE" : "FALSE", "FALSE")
}

AssertNear(testCategory, testName, resultObj, expectedVal, tolerance := 0.05) {
    global PassCount, FailCount, TestLogs, Failures
    if (!IsObject(resultObj) || !resultObj.HasOwnProp("val")) {
        FailCount++
        msg := (IsObject(resultObj) && resultObj.HasOwnProp("message")) ? resultObj.message : "No val returned"
        TestLogs.Push(Format("[FAIL] {1:-20} | {2:-38} -> Error: {3}", testCategory, testName, msg))
        Failures.Push({category: testCategory, testName: testName, error: msg})
        return
    }
    actualVal := resultObj.val
    diff := Abs(Float(actualVal) - Float(expectedVal))
    if (diff <= tolerance) {
        PassCount++
        TestLogs.Push(Format("[PASS] {1:-20} | {2:-38} -> Actual: {3:0.3f}, Expected: {4:0.3f}", testCategory, testName, actualVal, expectedVal))
    } else {
        FailCount++
        TestLogs.Push(Format("[FAIL] {1:-20} | {2:-38} -> Actual: {3:0.3f}, Expected: {4:0.3f} (Diff: {5:0.4f})", testCategory, testName, actualVal, expectedVal, diff))
        Failures.Push({category: testCategory, testName: testName, error: Format("Actual: {1:0.3f}, Expected: {2:0.3f}", actualVal, expectedVal)})
    }
}

try {
; 0. Unified Theme Tokens & Global Esc Engine Assertions
AssertEqual("ThemeTokens", "ThemePrimary #7B909D", ThemePrimary, "7B909D")
AssertEqual("ThemeTokens", "ThemeSecondary #73828C", ThemeSecondary, "73828C")
AssertEqual("ThemeTokens", "ThemeAccent #CE6B40", ThemeAccent, "CE6B40")
AssertEqual("ThemeTokens", "ThemeBg #0A0D10", ThemeBg, "0A0D10")
AssertEqual("ThemeTokens", "ThemeSurface #182025", ThemeSurface, "182025")
AssertEqual("ThemeTokens", "ThemeText #F8FAFC", ThemeText, "F8FAFC")
AssertEqual("ThemeTokens", "ThemeMuted #98A9B3", ThemeMuted, "98A9B3")
AssertEqual("ThemeTokens", "ThemeBorder #33424D", ThemeBorder, "33424D")

AssertFalse("UiEscapeEngine", "No UI visible initially", IsAnyOfficeUIVisible())
CloseAllOfficeUIs()
AssertFalse("UiEscapeEngine", "No UI visible after CloseAll", IsAnyOfficeUIVisible())

; 1. Number & Currency Parser Tests
AssertEqual("NumberParser", "Standard Integer", CleanToMachineNumber("100"), "100")
AssertEqual("NumberParser", "Signed Negative", CleanToMachineNumber("-500"), "-500")
AssertEqual("NumberParser", "Zero", CleanToMachineNumber("0"), "0")
AssertEqual("NumberParser", "Decimal Value", CleanToMachineNumber("125.50"), "125.50")
AssertEqual("NumberParser", "Leading Dot", CleanToMachineNumber(".75"), "0.75")
AssertEqual("NumberParser", "Accounting Negative", CleanToMachineNumber("(1,500.00)"), "-1500")

AssertEqual("NumberParser", "Indian Crore (12 cr)", CleanToMachineNumber("12 cr"), "120000000")
AssertEqual("NumberParser", "Indian Crore (2.5 Cr)", CleanToMachineNumber("2.5 Cr"), "25000000")
AssertEqual("NumberParser", "Indian Lakh (1.25 Lakh)", CleanToMachineNumber("1.25 Lakh"), "125000")
AssertEqual("NumberParser", "Indian Lakh (12 lakh)", CleanToMachineNumber("12 lakh"), "1200000")
AssertEqual("NumberParser", "Indian Lac (1.25 lac)", CleanToMachineNumber("1.25 lac"), "125000")
AssertEqual("NumberParser", "Thousand (12k)", CleanToMachineNumber("12k"), "12000")
AssertEqual("NumberParser", "Thousand (12.5k)", CleanToMachineNumber("12.5k"), "12500")

AssertEqual("NumberParser", "Million (12m)", CleanToMachineNumber("12m"), "12000000")
AssertEqual("NumberParser", "Million (1.5 million)", CleanToMachineNumber("1.5 million"), "1500000")
AssertEqual("NumberParser", "Billion (1.5b)", CleanToMachineNumber("1.5b"), "1500000000")

AssertEqual("NumberParser", "Rupees Symbol (₹1,25,000)", CleanToMachineNumber("₹1,25,000"), "125000")
AssertEqual("NumberParser", "INR Prefix (INR 2.5 Cr)", CleanToMachineNumber("INR 2.5 Cr"), "25000000")
AssertEqual("NumberParser", "USD ($1,500.50)", CleanToMachineNumber("$1,500.50"), "1500.50")
AssertEqual("NumberParser", "European Format (1.250,50)", CleanToMachineNumber("1.250,50"), "1250.50")

AssertFalse("NumberParser", "Empty String Invalid", ParseNumberOrCurrency("").isValid)
AssertFalse("NumberParser", "Pure Text Invalid", ParseNumberOrCurrency("hello world").isValid)
AssertFalse("NumberParser", "Multiple Dots Invalid", ParseNumberOrCurrency("1.2.3").isValid)
AssertFalse("NumberParser", "SKU 12-34-56 Invalid", ParseNumberOrCurrency("12-34-56").isValid)
AssertFalse("NumberParser", "Date 2026-08-25 Invalid", ParseNumberOrCurrency("2026-08-25").isValid)
AssertFalse("NumberParser", "Double Negative --500 Invalid", ParseNumberOrCurrency("--500").isValid)
AssertFalse("NumberParser", "Trailing Hyphen 500- Invalid", ParseNumberOrCurrency("500-").isValid)
AssertFalse("NumberParser", "Expression 100 - 50 Invalid", ParseNumberOrCurrency("100 - 50").isValid)
AssertEqual("NumberParser", "CleanToMachine preserves SKU 12-34-56", CleanToMachineNumber("12-34-56"), "12-34-56")
AssertEqual("NumberParser", "CleanToMachine preserves Date 2026-08-25", CleanToMachineNumber("2026-08-25"), "2026-08-25")

; 2. Number to Indian Words Tests
AssertEqual("IndianWords", "Zero", NumberToIndianWords("0"), "Rupees Zero Only")
AssertEqual("IndianWords", "Zero Decimal (0.00)", NumberToIndianWords("0.00"), "Rupees Zero Only")
AssertEqual("IndianWords", "Paise Only (0.50)", NumberToIndianWords("0.50"), "Fifty Paise Only")
AssertEqual("IndianWords", "Single Digit", NumberToIndianWords("1"), "Rupees One Only")
AssertEqual("IndianWords", "Teens (15)", NumberToIndianWords("15"), "Rupees Fifteen Only")
AssertEqual("IndianWords", "Tens (99)", NumberToIndianWords("99"), "Rupees Ninety-Nine Only")
AssertEqual("IndianWords", "Hundreds (100)", NumberToIndianWords("100"), "Rupees One Hundred Only")
AssertEqual("IndianWords", "Hundreds with units (105)", NumberToIndianWords("105"), "Rupees One Hundred Five Only")
AssertEqual("IndianWords", "Thousands (1000)", NumberToIndianWords("1000"), "Rupees One Thousand Only")
AssertEqual("IndianWords", "Thousands with units (1005)", NumberToIndianWords("1005"), "Rupees One Thousand Five Only")
AssertEqual("IndianWords", "Lakh (100000)", NumberToIndianWords("100000"), "Rupees One Lakh Only")
AssertEqual("IndianWords", "Crore (10000000)", NumberToIndianWords("10000000"), "Rupees One Crore Only")
AssertEqual("IndianWords", "Unit Word (1.25 lakh)", NumberToIndianWords("1.25 lakh"), "Rupees One Lakh Twenty-Five Thousand Only")
AssertEqual("IndianWords", "Unit Word (2.5 cr)", NumberToIndianWords("2.5 cr"), "Rupees Two Crore Fifty Lakh Only")
AssertEqual("IndianWords", "Unit Word (12 crore)", NumberToIndianWords("12 crore"), "Rupees Twelve Crore Only")
AssertEqual("IndianWords", "Amount with paise (154320.50)", NumberToIndianWords("154320.50"), "Rupees One Lakh Fifty-Four Thousand Three Hundred Twenty and Fifty Paise Only")
AssertEqual("IndianWords", "INR Prefix (INR 1.25 Lakh)", NumberToIndianWords("INR 1.25 Lakh"), "Rupees One Lakh Twenty-Five Thousand Only")

; 3. Commas Formatting Tests
AssertEqual("Commas", "Indian 1000", FormatIndianCommas("1000"), "1,000.00")
AssertEqual("Commas", "Indian 10000", FormatIndianCommas("10000"), "10,000.00")
AssertEqual("Commas", "Indian 100000", FormatIndianCommas("100000"), "1,00,000.00")
AssertEqual("Commas", "Indian 12345678", FormatIndianCommas("12345678"), "1,23,45,678.00")
AssertEqual("Commas", "Indian Unit (12 cr)", FormatIndianCommas("12 cr"), "12,00,00,000.00")
AssertEqual("Commas", "Indian Unit (1.25 lakh)", FormatIndianCommas("1.25 lakh"), "1,25,000.00")
AssertEqual("Commas", "Indian Negative (-5000)", FormatIndianCommas("-5000"), "-5,000.00")
AssertEqual("Commas", "Indian No Decimals", FormatIndianCommas("12345678", false), "1,23,45,678")
AssertEqual("Commas", "Indian Carry (999.999)", FormatIndianCommas("999.999"), "1,000.00")
AssertEqual("Commas", "Indian Carry (99999.996)", FormatIndianCommas("99999.996"), "1,00,000.00")

AssertEqual("Commas", "International 1000000", FormatInternationalCommas("1000000"), "1,000,000.00")
AssertEqual("Commas", "International 12345678", FormatInternationalCommas("12345678"), "12,345,678.00")
AssertEqual("Commas", "International Unit (1.5m)", FormatInternationalCommas("1.5m"), "1,500,000.00")
AssertEqual("Commas", "International Carry (999.999)", FormatInternationalCommas("999.999"), "1,000.00")
AssertEqual("Commas", "International Carry (999999.999)", FormatInternationalCommas("999999.999"), "1,000,000.00")

; 4. Math Preprocessing & Evaluation Tests
AssertEqual("MathEval", "Arithmetic (1500*1.18+450)", SafeEvaluateMath("1500 * 1.18 + 450").resultStr, "2220")
AssertEqual("MathEval", "Percentage Add (1500 + 18%)", SafeEvaluateMath("1500 + 18%").resultStr, "1770")
AssertEqual("MathEval", "Percentage Sub (1500 - 10%)", SafeEvaluateMath("1500 - 10%").resultStr, "1350")
AssertEqual("MathEval", "Percentage Mult (500 * 20%)", SafeEvaluateMath("500 * 20%").resultStr, "100")
AssertEqual("MathEval", "Exponentiation (2 ^ 3)", SafeEvaluateMath("2 ^ 3").resultStr, "8")
AssertEqual("MathEval", "Power (2 ** 4)", SafeEvaluateMath("2 ** 4").resultStr, "16")
AssertEqual("MathEval", "Multiply x notation (1500x300x87)", SafeEvaluateMath("1500x300x87").resultStr, "39150000")
AssertEqual("MathEval", "Division Symbol (100 ÷ 4)", SafeEvaluateMath("100 ÷ 4").resultStr, "25")
AssertEqual("MathEval", "Brackets ([10 + 20] * {5 - 2})", SafeEvaluateMath("[10 + 20] * {5 - 2}").resultStr, "90")
AssertEqual("MathEval", "Currency Stripping (₹1500 + $500)", SafeEvaluateMath("₹1500 + $500").resultStr, "2000")
AssertEqual("MathEval", "Trailing Equals (1500 + 500 = ?)", SafeEvaluateMath("1500 + 500 = ?").resultStr, "2000")
AssertEqual("MathEval", "Multi-group commas (1,000,000 / 2)", SafeEvaluateMath("1,000,000 / 2").resultStr, "500000")

; --- Advanced Nested, Unicode & Scale Math Tests ---
AssertEqual("MathEval", "Nested Braces & Implicit Mult (12- [20 ÷{8-2(9-5-2)}])", SafeEvaluateMath("12- [20 ÷{8-2(9-5-2)}]").resultStr, "7")
AssertEqual("MathEval", "Unicode Times & Minus (15×[(12÷3)+(4×2)]−9)", SafeEvaluateMath("15×[(12÷3)+(4×2)]−9").resultStr, "171")
AssertEqual("MathEval", "Unicode Division & Minus with Equals (36÷6+[8×(5+3)]−10=)", SafeEvaluateMath("36÷6+[8×(5+3)]−10=").resultStr, "60")
AssertEqual("MathEval", "Nested Braces with Unicode Minus (50−{20÷[2×(3+2)]}+18 =)", SafeEvaluateMath("50−{20÷[2×(3+2)]}+18 =").resultStr, "66")
AssertEqual("MathEval", "Nested Brackets with Unicode Minus (50−{20÷[2×5]}+18)", SafeEvaluateMath("50−{20÷[2×5]}+18").resultStr, "66")
AssertEqual("MathEval", "BODMAS 'of' Keyword (7823-128 ÷16 of 4 -3973)", SafeEvaluateMath("7823-128 ÷16 of 4 -3973").resultStr, "3818")
AssertEqual("MathEval", "Scale Suffix Lakh & k (1.5 Lakh * 12 - 20k)", SafeEvaluateMath("1.5 Lakh * 12 - 20k").resultStr, "1780000")
AssertEqual("MathEval", "Percentage 'of' Keyword (18% of 50000)", SafeEvaluateMath("18% of 50000").resultStr, "9000")
AssertEqual("MathEval", "Scale Suffix Crore (2.5 Cr / 5)", SafeEvaluateMath("2.5 Cr / 5").resultStr, "5000000")

AssertFalse("MathEval", "Division by zero fails safely", SafeEvaluateMath("100 / 0").success)
AssertFalse("MathEval", "Invalid string fails safely", SafeEvaluateMath("invalid text expression").success)

; 5. Indian Financial Year Tests
AssertEqual("Finance", "FY Aug 2026 (Q2)", ResolveIndianFinancialYear("2026-08-24"), "FY 2026-27 (Q2)")
AssertEqual("Finance", "FY Jan 2026 (Q4)", ResolveIndianFinancialYear("2026-01-15"), "FY 2025-26 (Q4)")
AssertEqual("Finance", "FY Apr 2026 (Q1)", ResolveIndianFinancialYear("2026-04-01"), "FY 2026-27 (Q1)")
AssertEqual("Finance", "FY Mar 2026 (Q4)", ResolveIndianFinancialYear("2026-03-31"), "FY 2025-26 (Q4)")
AssertEqual("Finance", "FY Nov 2026 (Q3)", ResolveIndianFinancialYear("2026-11-15"), "FY 2026-27 (Q3)")

; 6. Reverse GST & CAGR Tests
revGst := CalculateReverseGST(118000, 18)
AssertTrue("Finance", "Reverse GST Base 1,00,000", InStr(revGst, "Taxable Base: ₹1,00,000.00"))
AssertTrue("Finance", "Reverse GST Total GST 18,000", InStr(revGst, "Total GST (18%): ₹18,000.00"))
AssertEqual("Finance", "Reverse GST -100% Rate Safe", CalculateReverseGST(10000, -100), "Invalid GST rate (rate must be greater than -100%)")
AssertEqual("Finance", "Reverse GST -150% Rate Safe", CalculateReverseGST(10000, -150), "Invalid GST rate (rate must be greater than -100%)")

cagrReport := CalculateCAGR(1000000, 2000000, 5)
AssertTrue("Finance", "CAGR rate 14.87%", InStr(cagrReport, "CAGR): 14.87%"))
AssertTrue("Finance", "CAGR absolute return +100%", InStr(cagrReport, "Absolute Return: +100.00%"))

; 7. Data Extraction Tests
AssertEqual("Extraction", "PAN Extraction", ExtractPan("My PAN is ABCDE1234F and XYZPK9876Q."), "ABCDE1234F`nXYZPK9876Q")
AssertEqual("Extraction", "GSTIN Extraction", ExtractGstin("GSTIN: 07AAAAA0000A1Z5."), "07AAAAA0000A1Z5")
AssertEqual("Extraction", "Email Extraction", ExtractEmails("test@example.com and support@company.co.in"), "test@example.com`nsupport@company.co.in")
AssertEqual("Extraction", "Phone Extraction", ExtractPhones("Call +91 9876543210 or 7983604887"), "+91 9876543210`n7983604887")
AssertEqual("Extraction", "URL Extraction", ExtractUrls("Visit https://google.com and http://example.com/test?q=1."), "https://google.com`nhttp://example.com/test?q=1")

AssertTrue("Extraction", "Valid Calendar Date (21-Aug-2026)", IsValidCalendarDate("21-Aug-2026"))
AssertTrue("Extraction", "Valid Leap Date (29-Feb-2024)", IsValidCalendarDate("29-Feb-2024"))
AssertFalse("Extraction", "Invalid Non-Leap Date (29-Feb-2025)", IsValidCalendarDate("29-Feb-2025"))
AssertFalse("Extraction", "Invalid Date (31/02/2026)", IsValidCalendarDate("31/02/2026"))
AssertFalse("Extraction", "Invalid Date (99/99/9999)", IsValidCalendarDate("99/99/9999"))

; 8. Text Transformation & List Formatting Tests
AssertEqual("TextTransform", "Case Cycle lower->Title", CycleTextCase("hello"), "Hello")
AssertEqual("TextTransform", "Case Cycle Title->UPPER", CycleTextCase("Hello"), "HELLO")
AssertEqual("TextTransform", "Case Cycle UPPER->lower", CycleTextCase("HELLO"), "hello")
AssertEqual("TextTransform", "Sentence Case", ToSentenceCase("hello world. this is a test."), "Hello world. This is a test.")
AssertEqual("TextTransform", "Snake Case", ToDelimitedCase("Hello World Test", "_"), "hello_world_test")
AssertEqual("TextTransform", "Kebab Case", ToDelimitedCase("Hello World Test", "-"), "hello-world-test")
AssertEqual("TextTransform", "Camel Case", ToCamelCase("hello world test"), "helloWorldTest")
AssertEqual("TextTransform", "SQL IN List", FormatSqlInList("101`n102`n103"), "('101', '102', '103')")
AssertEqual("TextTransform", "Bullet List", FormatBulletList("Apple`nBanana"), "• Apple`n• Banana")
AssertEqual("TextTransform", "Numbered List", FormatNumberedList("Apple`nBanana"), "1. Apple`n2. Banana")
AssertEqual("TextTransform", "Checklist", FormatChecklist("Apple`nBanana"), "- [ ] Apple`n- [ ] Banana")
AssertEqual("TextTransform", "Clean Multi Spaces", CleanPlainText("Invoice    No:   123"), "Invoice No: 123")
AssertEqual("TextTransform", "Clean Excessive Newlines", CleanPlainText("Line 1`n`n`n`n`nLine 2"), "Line 1`r`n`r`nLine 2")
AssertEqual("TextTransform", "Clean Trailing Spaces", CleanPlainText("Line 1   `nLine 2   "), "Line 1`r`nLine 2")

; Progressive Pass 2 Soft-Break Unwrapping Test
pass1Text := CleanPlainText("Algorithmic Leverage:`nO`n(`nN`n2`n)`nO(N 2)")
AssertEqual("TextTransform", "CleanPlainText Pass 1 preserves lines", pass1Text, "Algorithmic Leverage:`r`nO`r`n(`r`nN`r`n2`r`n)`r`nO(N 2)")
pass2Text := CleanPlainText(pass1Text)
AssertEqual("TextTransform", "CleanPlainText Pass 2 unwraps lines", pass2Text, "Algorithmic Leverage: O ( N 2 ) O(N 2)")
AssertEqual("TextTransform", "CleanPlainText Pass 2 preserves paragraphs", CleanPlainText("Line 1`r`nLine 2`r`n`r`nParagraph 2"), "Line 1 Line 2`r`n`r`nParagraph 2")

; 9. CSV Streaming Parser Tests
csvSample := "id,task,created`n1,`"Review contract, sign and send`",2026-08-24`n2,`"Line 1`nLine 2`",2026-08-24"
parsedRows := ParseFullCSV(csvSample)
AssertEqual("CSVParser", "Row Count", parsedRows.Length, 3)
AssertEqual("CSVParser", "Quoted Comma Field", parsedRows[2][2], "Review contract, sign and send")
AssertEqual("CSVParser", "Multiline Field", parsedRows[3][2], "Line 1`nLine 2")

; 10. Shared Numeric Tokens & Cryptographic / Temporal Primitives Tests
toks := ExtractNumericTokens("Base: ₹1,50,000 | Tax: $250.75 | Cap: 1.25 Cr")
AssertEqual("Primitives", "ExtractNumericTokens count 3", toks.Length, 3)
if (toks.Length == 3) {
    AssertTrue("Primitives", "Token 1 INR 150000", toks[1].value == 150000 && toks[1].currency == "INR")
    AssertTrue("Primitives", "Token 2 USD 250.75", toks[2].value == 250.75 && toks[2].currency == "USD")
    AssertTrue("Primitives", "Token 3 Crore unit", toks[3].value == 12500000 && toks[3].unit == "Crore")
}
AssertEqual("Primitives", "CSPRNG password length 16", StrLen(GenerateSecurePassword(16)), 16)
loop 10 {
    pwd := GenerateSecurePassword(16)
    AssertEqual("Primitives", "CSPRNG password length loop " . A_Index, StrLen(pwd), 16)
}
AssertEqual("Primitives", "GenerateRandomChars length 5", StrLen(GenerateRandomChars(5)), 5)
AssertEqual("Primitives", "GenerateRandomChars length 0", StrLen(GenerateRandomChars(0)), 0)
AssertEqual("Primitives", "Unix 10-digit equals 13-digit ms", FormatUnixTimestamp("1787385200"), FormatUnixTimestamp("1787385200000"))
AssertTrue("Primitives", "Unix Timestamp format valid", RegExMatch(FormatUnixTimestamp("1787385200"), "^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}$") > 0)
AssertEqual("Primitives", "Unix Timestamp invalid string", FormatUnixTimestamp("invalid"), "")
AssertEqual("Primitives", "ISO week sync Jan 1 2021", GetIsoWeekInfo("20210101000000").formatted, "Week 53, 2020")
AssertEqual("Primitives", "ISO week sync Dec 31 2018", GetIsoWeekInfo("20181231000000").formatted, "Week 1, 2019")
AssertEqual("Primitives", "ISO week sync Aug 25 2026", GetIsoWeekInfo("20260825000000").formatted, "Week 35, 2026")
AssertEqual("Primitives", "Financial invalid date handling", ResolveIndianFinancialYear("invalid-date"), "Invalid Date")

; 11. Action Schema & Shortcut Badge Formatter Tests
RegisterDateTimeActions()
RegisterTextActions()

itemIso := BuiltInActions[1]
AssertEqual("ShortcutSchema", "Today's ISO Date hotkey field", itemIso.hotkey, "Alt+Shift+D")

itemClean := ""
for act in BuiltInActions {
    if (act.name == "Paste Clean Plain Text")
        itemClean := act
}
AssertEqual("ShortcutSchema", "Clean Plain Text chord field", IsObject(itemClean) ? itemClean.chord : "", "v")

RegisterAction("Custom Test Tool", "Custom", "Custom Desc", "test", (*) => "", "t", "Ctrl+Alt+T")
customItem := BuiltInActions[BuiltInActions.Length]
AssertEqual("ShortcutSchema", "Custom tool hotkey field", customItem.hotkey, "Ctrl+Alt+T")
AssertEqual("ShortcutSchema", "Custom tool chord field", customItem.chord, "t")

; 12. Window Peek FSM & Win32 Filter Primitives Tests
InitWindowPeekEngine()
AssertEqual("WindowPeek", "Initial FSM State is IDLE", PeekState.status, "IDLE")
AssertEqual("WindowPeek", "Zero HWND is not activatable", IsActivatableAppWindow(0), false)
progmanHwnd := WinExist("ahk_class Progman")
if progmanHwnd
    AssertEqual("WindowPeek", "Progman shell is filtered out", IsActivatableAppWindow(progmanHwnd), false)

RegisterWindowPeekActions()
peekAction := ""
xrayAction := ""
xrayConfigAction := ""
for act in BuiltInActions {
    if (act.name == "Toggle Window Peek (CapsLock+Tab)")
        peekAction := act
    if (act.name == "X-Ray Layer Peek (Step-Down Transparency)")
        xrayAction := act
    if (act.name == "Configure X-Ray Layer Transparency...")
        xrayConfigAction := act
}
AssertEqual("WindowPeek", "Peek tool registered in BuiltInActions", IsObject(peekAction), true)
AssertEqual("WindowPeek", "Peek tool hotkey is CapsLock+Tab", IsObject(peekAction) ? peekAction.hotkey : "", "CapsLock+Tab")

; 13. X-Ray Layer Peek Engine & Persistence Tests
InitXRayEngine()
AssertEqual("XRayPeek", "Initial XRayState is IDLE", XRayState.status, "IDLE")
AssertEqual("XRayPeek", "Default XRayOpacityPercent is valid (5-90)", XRayOpacityPercent >= 5 && XRayOpacityPercent <= 90, true)
AssertEqual("XRayPeek", "Default XRayAlphaValue matches percent", XRayAlphaValue == Integer((XRayOpacityPercent / 100.0) * 255), true)
AssertEqual("XRayPeek", "X-Ray tool registered in BuiltInActions", IsObject(xrayAction), true)
AssertEqual("XRayPeek", "X-Ray tool hotkey is CapsLock+Esc", IsObject(xrayAction) ? xrayAction.hotkey : "", "CapsLock+Esc")
; 14. Civil & Construction Tool Suite & Pythagoras Variants (All 40+ Variants & Inverse Solving)
RegisterCivilActions()
civilAction := ""
pythAction := ""
for act in BuiltInActions {
    if (act.name == "Civil & Construction Instant Converter")
        civilAction := act
    if (act.name == "Pythagoras & Plot Diagonal Calculator")
        pythAction := act
}
AssertEqual("CivilConverter", "Civil Converter registered in BuiltInActions", IsObject(civilAction), true)
AssertEqual("CivilConverter", "Civil Converter hotkey is Ctrl+Shift+U", IsObject(civilAction) ? civilAction.hotkey : "", "^+u")
AssertEqual("CivilConverter", "Pythagoras action registered in BuiltInActions", IsObject(pythAction), true)

; Core Physical Units (Length, Area, Volume, Weight, Force, Pressure, Flow, Slope, Rebar)
AssertNear("CivilLength", "10 m to ft", CivilConverterEngine.Evaluate("10 m to ft"), 32.808)
AssertNear("CivilArea", "100 sqm to sqft", CivilConverterEngine.Evaluate("100 sqm to sqft"), 1076.39)
AssertNear("CivilArea", "1 bigha to sqm (Uttarakhand 770 default)", CivilConverterEngine.Evaluate("1 bigha to sqm"), 770.0)
AssertNear("CivilArea", "1 nali to sqft (Uttarakhand 414.41)", CivilConverterEngine.Evaluate("1 nali to sqft"), 414.41)
AssertNear("CivilVolume", "10 cum to cft", CivilConverterEngine.Evaluate("10 cum to cft"), 353.147)
AssertNear("CivilRebar", "12mm bar kg/m (IS 1786)", CivilConverterEngine.Evaluate("12mm bar weight"), 0.887)
AssertNear("CivilRebar", "10mm @ 150 to 12mm", CivilConverterEngine.Evaluate("10mm @ 150 to 12mm"), 215.0)

; All 40+ Pythagoras, Diagonal, Guniya, Indian site shorthand & Inverse variants
AssertNear("Pythagoras", "pythagoras 3 4", CivilConverterEngine.Evaluate("pythagoras 3 4"), 5.0)
AssertNear("Pythagoras", "Pythagoras theorem 3 4", CivilConverterEngine.Evaluate("Pythagoras theorem 3 4"), 5.0)
AssertNear("Pythagoras", "Pythagorean theorem 6 8", CivilConverterEngine.Evaluate("Pythagorean theorem 6 8"), 10.0)
AssertNear("Pythagoras", "Pythagorus theorem 9 12", CivilConverterEngine.Evaluate("Pythagorus theorem 9 12"), 15.0)
AssertNear("Pythagoras", "diagonal 20ft 30ft", CivilConverterEngine.Evaluate("diagonal 20ft 30ft"), 36.056)
AssertNear("Pythagoras", "right triangle 3m 4m", CivilConverterEngine.Evaluate("right triangle 3m 4m"), 5.0)
AssertNear("Pythagoras", "right-angle triangle 3m 4m", CivilConverterEngine.Evaluate("right-angle triangle 3m 4m"), 5.0)
AssertNear("Pythagoras", "90 degree triangle 3 4", CivilConverterEngine.Evaluate("90 degree triangle 3 4"), 5.0)
AssertNear("Pythagoras", "90° check 3 4", CivilConverterEngine.Evaluate("90° check 3 4"), 5.0)
AssertNear("Pythagoras", "right angle check 3 4", CivilConverterEngine.Evaluate("right angle check 3 4"), 5.0)
AssertNear("Pythagoras", "corner-to-corner 10m 8m", CivilConverterEngine.Evaluate("corner-to-corner 10m 8m"), 12.806)
AssertNear("Pythagoras", "corner diagonal 12 16", CivilConverterEngine.Evaluate("corner diagonal 12 16"), 20.0)
AssertNear("Pythagoras", "room diagonal 12ft 15ft", CivilConverterEngine.Evaluate("room diagonal 12ft 15ft"), 19.209)
AssertNear("Pythagoras", "slab diagonal 6m 8m", CivilConverterEngine.Evaluate("slab diagonal 6m 8m"), 10.0)
AssertNear("Pythagoras", "floor diagonal 4m 5m", CivilConverterEngine.Evaluate("floor diagonal 4m 5m"), 6.403)
AssertNear("Pythagoras", "direct distance 30m 40m", CivilConverterEngine.Evaluate("direct distance 30m 40m"), 50.0)
AssertNear("Pythagoras", "straight distance 30m 40m", CivilConverterEngine.Evaluate("straight distance 30m 40m"), 50.0)
AssertNear("Pythagoras", "guniya 3m 4m (Indian right angle)", CivilConverterEngine.Evaluate("guniya 3m 4m"), 5.0)
AssertNear("Pythagoras", "tircha 3m 4m", CivilConverterEngine.Evaluate("tircha 3m 4m"), 5.0)
AssertNear("Pythagoras", "tirchi length 6m 8m", CivilConverterEngine.Evaluate("tirchi length 6m 8m"), 10.0)
AssertNear("Pythagoras", "kona se kona 10 8", CivilConverterEngine.Evaluate("kona se kona 10 8"), 12.806)
AssertNear("Pythagoras", "kone se kone 10m 8m", CivilConverterEngine.Evaluate("kone se kone 10m 8m"), 12.806)
AssertNear("Pythagoras", "3m base 4m height", CivilConverterEngine.Evaluate("3m base 4m height"), 5.0)
AssertNear("Pythagoras", "vertical 4m horizontal 3m", CivilConverterEngine.Evaluate("vertical 4m horizontal 3m"), 5.0)
AssertNear("Pythagoras", "3-4-5 rule shorthand", CivilConverterEngine.Evaluate("3-4-5"), 5.0)
AssertNear("Pythagoras", "3 x 4 diagonal", CivilConverterEngine.Evaluate("3 x 4 diagonal"), 5.0)
AssertNear("Pythagoras", "3 by 4 diagonal", CivilConverterEngine.Evaluate("3 by 4 diagonal"), 5.0)
AssertNear("Pythagoras", "10x8 diag", CivilConverterEngine.Evaluate("10x8 diag"), 12.806)
AssertNear("Pythagoras", "3x4 hyp", CivilConverterEngine.Evaluate("3x4 hyp"), 5.0)
AssertNear("Pythagoras", "12x16 diag kitna", CivilConverterEngine.Evaluate("12x16 diag kitna"), 20.0)
AssertNear("Pythagoras", "10m 8m tircha", CivilConverterEngine.Evaluate("10m 8m tircha"), 12.806)

; Inverse Pythagoras: Known Hypotenuse + Leg -> Solve Missing Leg
AssertNear("Pythagoras", "5m diagonal 3m side (Inverse) -> 4.0", CivilConverterEngine.Evaluate("5m diagonal 3m side"), 4.0)
AssertNear("Pythagoras", "hyp 10 base 6 (Inverse) -> 8.0", CivilConverterEngine.Evaluate("hyp 10 base 6"), 8.0)
AssertNear("Pythagoras", "5m diag 4m height (Inverse) -> 3.0", CivilConverterEngine.Evaluate("5m diag 4m height"), 3.0)
AssertNear("Pythagoras", "tircha 5 side 3 (Inverse) -> 4.0", CivilConverterEngine.Evaluate("tircha 5 side 3"), 4.0)
AssertNear("Pythagoras", "3m side 5m diagonal (Inverse) -> 4.0", CivilConverterEngine.Evaluate("3m side 5m diagonal"), 4.0)
AssertNear("Pythagoras", "side 3m diagonal 5m (Inverse) -> 4.0", CivilConverterEngine.Evaluate("side 3m diagonal 5m"), 4.0)

; Leader c Math Evaluator Bridge Tests
mEv1 := SafeEvaluateMath("pythagoras 3 4")
AssertTrue("Leader_c_Bridge", "Leader c 'pythagoras 3 4' success", mEv1.success)
AssertTrue("Leader_c_Bridge", "Leader c 'pythagoras 3 4' val = 5", Abs(mEv1.result - 5.0) <= 0.01)

mEv2 := SafeEvaluateMath("diagonal 20ft 30ft")
AssertTrue("Leader_c_Bridge", "Leader c 'diagonal 20ft 30ft' success", mEv2.success)
AssertTrue("Leader_c_Bridge", "Leader c 'diagonal 20ft 30ft' val ~ 36.056", Abs(mEv2.result - 36.056) <= 0.05)

mEv3 := SafeEvaluateMath("guniya 3m 4m")
AssertTrue("Leader_c_Bridge", "Leader c 'guniya 3m 4m' success", mEv3.success)
AssertTrue("Leader_c_Bridge", "Leader c 'guniya 3m 4m' val = 5", Abs(mEv3.result - 5.0) <= 0.01)

mEv4 := SafeEvaluateMath("5m diagonal 3m side")
AssertTrue("Leader_c_Bridge", "Leader c '5m diagonal 3m side' success", mEv4.success)
AssertTrue("Leader_c_Bridge", "Leader c '5m diagonal 3m side' val = 4", Abs(mEv4.result - 4.0) <= 0.01)

mEv5 := SafeEvaluateMath("5m diag 4m height")
AssertTrue("Leader_c_Bridge", "Leader c '5m diag 4m height' success", mEv5.success)
AssertTrue("Leader_c_Bridge", "Leader c '5m diag 4m height' val = 3", Abs(mEv5.result - 3.0) <= 0.01)

mEv6 := SafeEvaluateMath("tircha 5 side 3")
AssertTrue("Leader_c_Bridge", "Leader c 'tircha 5 side 3' success", mEv6.success)
AssertTrue("Leader_c_Bridge", "Leader c 'tircha 5 side 3' val = 4", Abs(mEv6.result - 4.0) <= 0.01)

mEv7 := SafeEvaluateMath("3m side 5m diagonal")
AssertTrue("Leader_c_Bridge", "Leader c '3m side 5m diagonal' success", mEv7.success)
AssertTrue("Leader_c_Bridge", "Leader c '3m side 5m diagonal' val = 4", Abs(mEv7.result - 4.0) <= 0.01)
} catch as globalErr {
    FailCount++
    TestLogs.Push(Format("[FAIL] GlobalFatalException | {1} at Line {2}", globalErr.Message, globalErr.Line))
    Failures.Push({category: "GlobalFatalException", testName: "GlobalFatalException", error: globalErr.Message . " (Line " . globalErr.Line . ")"})
}

durationMs := A_TickCount - StartTick
EmitTestResults("test_suite_runner", PassCount + FailCount, PassCount, FailCount, durationMs, TestLogs, Failures)
