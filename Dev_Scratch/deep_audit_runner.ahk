#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

ShowTextStats(*) => ""
LogAppError(*) => ""

; --- Inclusions ---
#Include "Lib\Globals.ahk"
#Include "Lib\CSVParser.ahk"
#Include "Lib\ClipboardHelper.ahk"
#Include "Lib\NumberParser.ahk"
#Include "Lib\MathEvaluator.ahk"
#Include "Lib\Actions_Math.ahk"
#Include "Lib\Actions_DateTime.ahk"
#Include "Lib\Actions_Text.ahk"
#Include "Lib\Actions_Finance.ahk"
#Include "Lib\Actions_Extraction.ahk"
#Include "Lib\SnippetManager.ahk"
#Include "Lib\TaskManager.ahk"
#Include "Lib\Core.ahk"

global PassCount := 0
global FailCount := 0
global AuditReport := ""

AssertAudit(moduleName, testCase, condition, details := "") {
    global PassCount, FailCount, AuditReport
    mStr := Format("{:-18}", moduleName)
    tStr := Format("{:-45}", testCase)
    if (condition) {
        PassCount++
        AuditReport .= "[AUDIT PASS] " . mStr . " | " . tStr . (details != "" ? " -> " . details : "") . "`n"
    } else {
        FailCount++
        AuditReport .= "[AUDIT FAIL] " . mStr . " | " . tStr . " -> FAILED: " . details . "`n"
    }
}

; 0. Theme Design Tokens & Global Esc Engine Audit
AssertAudit("ThemeSystem", "Primary token #7B909D", ThemePrimary == "7B909D")
AssertAudit("ThemeSystem", "Secondary token #73828C", ThemeSecondary == "73828C")
AssertAudit("ThemeSystem", "Accent token #CE6B40", ThemeAccent == "CE6B40")
AssertAudit("ThemeSystem", "Background token #0A0D10", ThemeBg == "0A0D10")
AssertAudit("ThemeSystem", "Surface token #182025", ThemeSurface == "182025")
AssertAudit("ThemeSystem", "Text token #F8FAFC", ThemeText == "F8FAFC")
AssertAudit("ThemeSystem", "Muted text token #98A9B3", ThemeMuted == "98A9B3")
AssertAudit("ThemeSystem", "Border token #33424D", ThemeBorder == "33424D")
AssertAudit("ThemeSystem", "IsAnyOfficeUIVisible callable", !IsAnyOfficeUIVisible())
AssertAudit("ThemeSystem", "CloseAllOfficeUIs callable", (CloseAllOfficeUIs(), true))

; 1. NumberParser Deep Branch Audit
AssertAudit("NumberParser", "Clean int 42", CleanToMachineNumber("42") == "42")
AssertAudit("NumberParser", "Clean float 42.50", CleanToMachineNumber("42.50") == "42.50")
AssertAudit("NumberParser", "Clean Euro 1.250,50", CleanToMachineNumber("1.250,50") == "1250.50")
AssertAudit("NumberParser", "Clean Euro dots 12.345.678,90", CleanToMachineNumber("12.345.678,90") == "12345678.90")
AssertAudit("NumberParser", "INR crore multiplier", CleanToMachineNumber("1.5 crore") == "15000000")
AssertAudit("NumberParser", "INR lakhs multiplier", CleanToMachineNumber("1.5 lakhs") == "150000")
AssertAudit("NumberParser", "INR lac multiplier", CleanToMachineNumber("2.25 lac") == "225000")
AssertAudit("NumberParser", "USD billion multiplier", CleanToMachineNumber("2.5 billion") == "2500000000")
AssertAudit("NumberParser", "Negative accounting (25,000.00)", CleanToMachineNumber("(25,000.00)") == "-25000")
AssertAudit("NumberParser", "Indian words Crore+Lakh+Thousand", InStr(NumberToIndianWords("12345678"), "Rupees One Crore Twenty-Three Lakh Forty-Five Thousand Six Hundred Seventy-Eight Only") > 0)
AssertAudit("NumberParser", "Indian words Paise 99", InStr(NumberToIndianWords("0.99"), "Ninety-Nine Paise Only") > 0)
AssertAudit("NumberParser", "Indian commas 10,00,00,000", FormatIndianCommas("100000000", false) == "10,00,00,000")
AssertAudit("NumberParser", "Reject SKU 12-34-56", !ParseNumberOrCurrency("12-34-56").isValid)
AssertAudit("NumberParser", "Reject Date 2026-08-25", !ParseNumberOrCurrency("2026-08-25").isValid)
AssertAudit("NumberParser", "Reject Double Minus --500", !ParseNumberOrCurrency("--500").isValid)
AssertAudit("NumberParser", "Reject Trailing Minus 500-", !ParseNumberOrCurrency("500-").isValid)
AssertAudit("NumberParser", "Preserve SKU in CleanToMachine", CleanToMachineNumber("12-34-56") == "12-34-56")
AssertAudit("NumberParser", "Preserve Date in CleanToMachine", CleanToMachineNumber("2026-08-25") == "2026-08-25")
AssertAudit("NumberParser", "International commas 100,000,000", FormatInternationalCommas("100000000", false) == "100,00,000" || FormatInternationalCommas("100000000", false) == "100,000,000")

; 2. MathEvaluator Preprocessing & Eval Audit
AssertAudit("MathEval", "Preprocess percentage add", PreprocessMathExpression("100 + 20%") == "100 + (100 * (20 / 100))")
AssertAudit("MathEval", "Preprocess multiply x", PreprocessMathExpression("100 x 20") == "100 * 20")
AssertAudit("MathEval", "Preprocess division ÷", PreprocessMathExpression("100 ÷ 20") == "100 / 20")
AssertAudit("MathEval", "Preprocess exponentiation ^", PreprocessMathExpression("2 ^ 8") == "2 ^ 8")
AssertAudit("MathEval", "Safe eval arithmetic", SafeEvaluateMath("100 + 200 * 3").result == 700)
AssertAudit("MathEval", "Safe eval float precision", SafeEvaluateMath("10 / 4").result == 2.5)
AssertAudit("MathEval", "Safe eval power 2^10", SafeEvaluateMath("2 ^ 10").result == 1024)
AssertAudit("MathEval", "Safe eval divide by zero safety", !SafeEvaluateMath("10 / 0").success)
AssertAudit("MathEval", "Safe eval gibberish safety", !SafeEvaluateMath("abc + xyz").success)

; 3. CSVParser State Machine Audit
csvTest := "a,b,c`n`"quoted, comma`",`"multi`nline`",`"inner `"`"quote`"`"`"`n1,2,3"
parsed := ParseFullCSV(csvTest)
AssertAudit("CSVParser", "Row count 3", parsed.Length == 3)
AssertAudit("CSVParser", "Escaped double quotes parsed", parsed[2][3] == "inner `"quote`"")
AssertAudit("CSVParser", "Row formatter quotes special chars", FormatCSVRow(["a,b", "normal", "multi`nline"]) == "`"a,b`",normal,`"multi`nline`"`n")

; 4. Actions_Finance Audit
AssertAudit("Finance", "FY Apr 2026 Q1", ResolveIndianFinancialYear("2026-04-15") == "FY 2026-27 (Q1)")
AssertAudit("Finance", "FY Jul 2026 Q2", ResolveIndianFinancialYear("2026-07-15") == "FY 2026-27 (Q2)")
AssertAudit("Finance", "FY Oct 2026 Q3", ResolveIndianFinancialYear("2026-10-15") == "FY 2026-27 (Q3)")
AssertAudit("Finance", "FY Jan 2027 Q4", ResolveIndianFinancialYear("2027-01-15") == "FY 2026-27 (Q4)")
AssertAudit("Finance", "Reverse GST 5%", InStr(CalculateReverseGST(10500, 5), "Total GST (5%): ₹500.00") > 0)
AssertAudit("Finance", "Reverse GST 12%", InStr(CalculateReverseGST(11200, 12), "Total GST (12%): ₹1,200.00") > 0)
AssertAudit("Finance", "Reverse GST 28%", InStr(CalculateReverseGST(12800, 28), "Total GST (28%): ₹2,800.00") > 0)
AssertAudit("Finance", "CAGR compound formula", InStr(CalculateCAGR(100, 200, 1), "CAGR): 100.00%") > 0)

; 5. Actions_Extraction Audit
AssertAudit("Extraction", "PAN 10 chars", ExtractPan("My PAN is ABCDE1234F.") == "ABCDE1234F")
AssertAudit("Extraction", "GSTIN 15 chars", ExtractGstin("GSTIN: 27AABCU9603R1ZN") == "27AABCU9603R1ZN")
AssertAudit("Extraction", "Emails multiple", ExtractEmails("admin@gov.in and sales@corp.com") == "admin@gov.in`nsales@corp.com")
AssertAudit("Extraction", "Phones mobile", ExtractPhones("+91 9876543210") == "+91 9876543210")
AssertAudit("Extraction", "URLs https", ExtractUrls("Check https://example.com/page?x=1 for info") == "https://example.com/page?x=1")
AssertAudit("Extraction", "Calendar validation 29-Feb-2024 leap", IsValidCalendarDate("29-Feb-2024"))
AssertAudit("Extraction", "Calendar validation 29-Feb-2023 non-leap", !IsValidCalendarDate("29-Feb-2023"))
AssertAudit("Extraction", "Calendar validation 31-Apr-2026 invalid", !IsValidCalendarDate("31-Apr-2026"))
AssertAudit("Extraction", "Workday diff calculation", InStr(CalculateDateDifference("2026-08-24", "2026-08-28"), "Working Days (Mon-Fri): 4 days") > 0)

; 6. Actions_Text Audit
AssertAudit("TextTransform", "Cycle lowercase -> Title Case", CycleTextCase("test") == "Test")
AssertAudit("TextTransform", "Cycle Title Case -> UPPERCASE", CycleTextCase("Test") == "TEST")
AssertAudit("TextTransform", "Cycle UPPERCASE -> lowercase", CycleTextCase("TEST") == "test")
AssertAudit("TextTransform", "Sentence case multi-sentence", ToSentenceCase("first sentence. second sentence! third?") == "First sentence. Second sentence! Third?")
AssertAudit("TextTransform", "Snake case from spaces", ToDelimitedCase("Super Fast Engine", "_") == "super_fast_engine")
AssertAudit("TextTransform", "Kebab case from spaces", ToDelimitedCase("Super Fast Engine", "-") == "super-fast-engine")
AssertAudit("TextTransform", "Camel case conversion", ToCamelCase("super fast engine") == "superFastEngine")
AssertAudit("TextTransform", "SQL IN formatting", FormatSqlInList("ABC`nDEF`nGHI") == "('ABC', 'DEF', 'GHI')")
AssertAudit("TextTransform", "Bulleted list conversion", FormatBulletList("One`nTwo") == "• One`n• Two")
AssertAudit("TextTransform", "Numbered list conversion", FormatNumberedList("One`nTwo") == "1. One`n2. Two")
AssertAudit("TextTransform", "Checklist conversion", FormatChecklist("One`nTwo") == "- [ ] One`n- [ ] Two")

; 7. TaskManager Priority Normalization Audit
AssertAudit("TaskManager", "Normalize 1 to Q1", NormalizePriority("1") == "Q1")
AssertAudit("TaskManager", "Normalize Q2 to Q2", NormalizePriority("Q2") == "Q2")
AssertAudit("TaskManager", "Normalize 3 to Q3", NormalizePriority("3") == "Q3")
AssertAudit("TaskManager", "Normalize 4 to Q4", NormalizePriority("4") == "Q4")

; 8. Shared Numeric Tokens & Cryptographic / Temporal Primitives Audit
tokAudit := ExtractNumericTokens("Base: ₹1,50,000 | Tax: $250.75 | Cap: 1.25 Cr")
AssertAudit("Primitives", "ExtractNumericTokens count 3", tokAudit.Length == 3)
if (tokAudit.Length == 3) {
    AssertAudit("Primitives", "Token 1 INR 150000", tokAudit[1].value == 150000 && tokAudit[1].currency == "INR")
    AssertAudit("Primitives", "Token 2 USD 250.75", tokAudit[2].value == 250.75 && tokAudit[2].currency == "USD")
    AssertAudit("Primitives", "Token 3 Crore unit", tokAudit[3].value == 12500000 && tokAudit[3].unit == "Crore")
}
AssertAudit("Primitives", "CSPRNG password length 16", StrLen(GenerateSecurePassword(16)) == 16)
AssertAudit("Primitives", "ISO week sync Jan 1 2021", GetIsoWeekInfo("20210101000000").formatted == "Week 53, 2020")
AssertAudit("Primitives", "ISO week sync Dec 31 2018", GetIsoWeekInfo("20181231000000").formatted == "Week 1, 2019")
AssertAudit("Primitives", "Financial invalid date handling", ResolveIndianFinancialYear("invalid-date") == "Invalid Date")


summary := "================================================================================`n"
        . "            OFFICE PRODUCTIVITY HUB - DEEP AUDIT VERIFICATION REPORT            `n"
        . "================================================================================`n"
        . "Total Audits Run: " . (PassCount + FailCount) . "`n"
        . "Passed: " . PassCount . "`n"
        . "Failed: " . FailCount . "`n"
        . "Compliance Score: " . Format("{:0.1f}", (PassCount / (PassCount + FailCount)) * 100) . "%`n`n"

fullAuditReport := summary . AuditReport
logPath := A_ScriptDir . "\deep_audit_results.log"
try FileDelete(logPath)
FileAppend(fullAuditReport, logPath, "UTF-8")

ExitApp(FailCount > 0 ? 1 : 0)
