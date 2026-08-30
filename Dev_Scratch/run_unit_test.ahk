#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "Lib\Telemetry.ahk"
#Include "Lib\Core.ahk"
#Include "Lib\PaletteGui.ahk"
#Include "Lib\Actions_DateTime.ahk"
#Include "Lib\Actions_Text.ahk"
#Include "Lib\Actions_Email.ahk"
#Include "Lib\Actions_Math.ahk"
#Include "Lib\Actions_Utility.ahk"
#Include "Lib\Actions_Extraction.ahk"
#Include "Lib\Actions_Finance.ahk"
#Include "..\Word Count Tooltip.ahk"

auditLog := ""

; 1. Math & Evaluations
try {
    clean1 := PreprocessMathExpression("1500 + 18%")
    doc := ComObject("htmlfile")
    doc.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
    eval1 := doc.parentWindow.eval(clean1)
    doc.close()
    auditLog .= "TEST 1 (1500+18%): " . eval1 . "`n"
} catch as err {
    auditLog .= "TEST 1 ERROR: " . err.Message . "`n"
}

; 2. Words conversion
auditLog .= "TEST 2 (12 crore): " . NumberToIndianWords("12 crore") . "`n"
auditLog .= "TEST 3 (2.5 cr): " . NumberToIndianWords("2.5 cr") . "`n"
auditLog .= "TEST 4 (1.25 lakh): " . NumberToIndianWords("1.25 lakh") . "`n"
auditLog .= "TEST 5 (INR 1.25 Lakh): " . NumberToIndianWords("INR 1.25 Lakh") . "`n"

; 3. Commas
auditLog .= "TEST 6 (123456789 Indian): " . FormatIndianCommas("123456789") . "`n"
auditLog .= "TEST 7 (12 cr Indian): " . FormatIndianCommas("12 cr") . "`n"

; 4. Extraction
auditLog .= "TEST 8 (PAN Extraction): " . ExtractPan("My PAN is ABCDE1234F and XYZPK9876Q.") . "`n"
auditLog .= "TEST 9 (GSTIN Extraction): " . ExtractGstin("GSTIN: 07AAAAA0000A1Z5.") . "`n"
auditLog .= "TEST 10 (Email Extraction): " . ExtractEmails("Email: test@example.com or hr@company.co.in") . "`n"
auditLog .= "TEST 11 (Phone Extraction): " . ExtractPhones("Call +91 9876543210 or 7983604887") . "`n"

; 5. Text Transforms
auditLog .= "TEST 12 (Bullet List):`n" . FormatBulletList("Apple`nBanana`nOrange") . "`n"
auditLog .= "TEST 13 (Numbered List):`n" . FormatNumberedList("Step 1`nStep 2`nStep 3") . "`n"
auditLog .= "TEST 14 (Checklist):`n" . FormatChecklist("Task A`nTask B") . "`n"
auditLog .= "TEST 15 (Case Cycle): " . CycleTextCase("hello") . " -> " . CycleTextCase("Hello") . " -> " . CycleTextCase("HELLO") . "`n"

; 6. Reverse GST
auditLog .= "TEST 16 (Reverse GST 18%):`n" . CalculateReverseGST(118000, 18) . "`n"

; 7. Financial Year
auditLog .= "TEST 17 (FY from date): " . ResolveIndianFinancialYear("2026-08-24") . "`n"
auditLog .= "TEST 18 (FY from Jan): " . ResolveIndianFinancialYear("2026-01-15") . "`n"

FileAppend(auditLog, "audit_summary_log.txt", "UTF-8")
ExitApp()
