; ======================================================================================================================
; Module: Actions_Finance.ahk - Indian Fiscal Year, Reverse GST, CAGR & Number Formatting
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterFinanceActions() {
    RegisterAction("Indian Financial Year & Quarter", "💼 Finance", "[Needs Selection] Converts date to FY 2026–27 (Q2)", "fy, financial year, quarter, q1, q2, q3, q4, fiscal, tax, itr, it returns, year", (*) => ProcessIndianFY())
    RegisterAction("Percentage Change vs Point (pp) Change", "💼 Finance", "[Needs Selection] Compares two rates (e.g. 5.0% -> 6.5% gives +1.5pp / +30%)", "percentage, point, pp, change, rate, yield, compare", (*) => ProcessPctVsPp())
    RegisterAction("CAGR Growth Calculator", "💼 Finance", "[Needs Selection] Calculates CAGR from Beg Val, End Val, Years (Natural text supported)", "cagr, growth, compound, annual, investment, returns", (*) => ProcessCAGR())
    RegisterAction("Reverse GST Calculator (18%)", "💼 Finance", "[Needs Selection] Extracts Base + 18% GST from inclusive amount or sentence", "reverse, gst, 18%, tax, base, inclusive, invoice", (*) => ProcessReverseGST(18))
    RegisterAction("Reverse GST (Custom Rate)", "💼 Finance", "[Needs Selection] Extracts Base + Tax for custom rate (e.g. GST = 12%)", "reverse, gst, rate, tax, 5%, 12%, 28%, custom", (*) => ProcessReverseGSTPrompt())
    RegisterAction("Clean Number to Raw Machine Value", "💼 Finance", "[Needs Selection] Converts '1.25 Lakh' / '2.5 Cr' / '1,25,000' -> 125000", "clean, number, machine, raw, lakh, crore, euro", (*) => TransformSelectedText((txt) => CleanToMachineNumber(txt)))
    RegisterAction("Format Number: Indian Lakhs (12,34,567)", "💼 Finance", "[Needs Selection] Formats 12345678 -> 1,23,45,678 (Lakhs/Crores)", "comma, format, number, indian, lakh, crore, digits, currency", (*) => TransformSelectedText((txt) => FormatIndianCommas(txt)))
    RegisterAction("Format Number: International Millions (1,234,567)", "💼 Finance", "[Needs Selection] Formats 12345678 -> 12,345,678 (Millions/Billions)", "comma, format, number, international, million, billion, digits, standard", (*) => TransformSelectedText((txt) => FormatInternationalCommas(txt)))
}

; ======================================================================================================================
; ARCHITECTURAL INTENT [INDIAN FINANCIAL YEAR - CURRENT DATE FALLBACK]:
; Empty selection defaults to current date without prompting.
; This is intentional — the most common use case is "what FY is it NOW?"
; If text is highlighted, it resolves that specific date; otherwise it resolves today's date with zero friction.
; ======================================================================================================================
ProcessIndianFY() {
    sel := SafeGetSelection()
    res := ResolveIndianFinancialYear(Trim(sel))
    if (res = "Invalid Date") {
        ShowToast("⚠️ Invalid date format", 2000)
        return
    }
    InsertText(res)
}

ResolveIndianFinancialYear(dateStr := "") {
    if (dateStr = "")
        dt := A_Now
    else {
        rawDate := dateStr
        if RegExMatch(dateStr, "i)\b(?:\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{1,2}[-/\s]+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/\s,]+\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?,?\s*\d{2,4})\b", &m)
            rawDate := m[0]
            
        parsed := ParseAnyDateToYyyyMmDd(rawDate)
        if (parsed == "")
            return "Invalid Date"
        dt := parsed . "000000"
    }
    
    year := Integer(FormatTime(dt, "yyyy"))
    month := Integer(FormatTime(dt, "MM"))
    
    if (month >= 4) {
        fyStart := year
        fyEnd := SubStr(String(year + 1), 3, 2)
        qtr := (month <= 6) ? "Q1" : (month <= 9) ? "Q2" : "Q3"
    } else {
        fyStart := year - 1
        fyEnd := SubStr(String(year), 3, 2)
        qtr := "Q4"
    }
    
    return Format("FY {}-{} ({})", fyStart, fyEnd, qtr)
}

ProcessPctVsPp() {
    sel := SafeGetSelection()
    nums := ExtractAllNumbers(sel)
    if (nums.Length < 2) {
        ib := OfficeInputBox("Enter initial & final rate (e.g. 5.0 6.5 or 100 125):", "Percentage vs pp Change")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        nums := ExtractAllNumbers(ib.Value)
        if (nums.Length < 2)
            return
    }
    report := CalculatePercentageVsPercentagePoints(nums[1], nums[2])
    MsgBox(report, "Percentage Change vs Percentage-Point Change", "Iconi")
}

CalculatePercentageVsPercentagePoints(val1, val2) {
    v1 := Float(val1)
    v2 := Float(val2)
    
    ppDiff := v2 - v1
    if (v1 = 0)
        relPct := 0.0
    else
        relPct := ((v2 - v1) / v1) * 100
        
    return Format("{:0.2f}% -> {:0.2f}%:`n• Percentage-Point (pp) Change: {:+0.2f} pp`n• Relative Percentage Change: {:+0.2f}%", v1, v2, ppDiff, relPct)
}

ProcessCAGR() {
    sel := SafeGetSelection()
    begVal := 0.0, endVal := 0.0, numYears := 0.0
    
    if (Trim(sel) != "") {
        tokens := ExtractNumericTokens(sel)
        if (tokens.Length >= 3) {
            begVal := tokens[1].value
            endVal := tokens[2].value
            numYears := tokens[3].value
        }
    }
    
    if (begVal <= 0 || endVal <= 0 || numYears <= 0) {
        ib := OfficeInputBox("Enter Start, End & Years (e.g. 10L 20L 5 or 1,25,000 2,50,000 3):", "CAGR Calculator")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
            
        tokens := ExtractNumericTokens(ib.Value)
        if (tokens.Length >= 3) {
            begVal := tokens[1].value
            endVal := tokens[2].value
            numYears := tokens[3].value
        }
        if (begVal <= 0 || endVal <= 0 || numYears <= 0) {
            ShowToast("⚠️ Invalid CAGR parameters entered", 2000)
            return
        }
    }
    
    report := CalculateCAGR(begVal, endVal, numYears)
    MsgBox(report, "CAGR Growth Calculator", "Iconi")
}

CalculateCAGR(begVal, endVal, numYears) {
    b := Float(begVal)
    e := Float(endVal)
    y := Float(numYears)
    
    if (b <= 0 || e <= 0 || y <= 0)
        return "Invalid parameters for CAGR"
        
    cagr := ((e / b) ** (1 / y) - 1) * 100
    absReturn := ((e - b) / b) * 100
    multiple := e / b
    
    res := Format("Investment Growth (CAGR):`n• Beginning Value: ₹{}`n• Ending Value: ₹{}`n• Investment Period: {:0.1f} Years`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n➜ Compound Annual Growth Rate (CAGR): {:0.2f}%`n• Absolute Return: {:+0.2f}% (₹{})`n• Growth Multiple: {:0.2f}x", 
                  FormatIndianCommas(b), FormatIndianCommas(e), y, cagr, absReturn, FormatIndianCommas(e - b), multiple)
    return res
}

ProcessReverseGST(defaultRate := 18) {
    sel := SafeGetSelection()
    extractedAmt := 0.0
    extractedRate := defaultRate
    
    if (Trim(sel) != "") {
        if RegExMatch(sel, "i)(?:GST\s*=?\s*|including\s+)(\d+(?:\.\d+)?)\s*%", &mRate) {
            extractedRate := Float(mRate[1])
        }
        
        tokens := ExtractNumericTokens(sel)
        if (tokens.Length > 0) {
            ; If multiple tokens and first token was the rate, use second token for amount
            if (tokens.Length >= 2 && tokens[1].value = extractedRate)
                extractedAmt := tokens[2].value
            else
                extractedAmt := tokens[1].value
        }
    }
    
    if (extractedAmt <= 0) {
        ib := OfficeInputBox("Enter total GST amount (e.g. 1.18 Lakh or 1,18,000):", "Reverse GST (" . extractedRate . "%)")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
            
        if RegExMatch(ib.Value, "i)(?:GST\s*=?\s*|including\s+)(\d+(?:\.\d+)?)\s*%", &mRate) {
            extractedRate := Float(mRate[1])
        }
        tokens := ExtractNumericTokens(ib.Value)
        if (tokens.Length > 0) {
            if (tokens.Length >= 2 && tokens[1].value = extractedRate)
                extractedAmt := tokens[2].value
            else
                extractedAmt := tokens[1].value
        }
            
        if (extractedAmt <= 0) {
            ShowToast("⚠️ Invalid GST amount", 2000)
            return
        }
    }
    
    report := CalculateReverseGST(extractedAmt, extractedRate)
    InsertText(report)
}

; ======================================================================================================================
; ARCHITECTURAL INTENT [REVERSE GST (CUSTOM RATE) - RATE AUTO-DETECTION]:
; Auto-detects rate from text like "including 12% GST" or "GST = 28%". Falls back to prompt if not found.
; If an amount and rate are already detected in selected text, calculations execute directly without popup modals.
; ======================================================================================================================
ProcessReverseGSTPrompt() {
    sel := SafeGetSelection()
    detectedRate := 18.0
    detectedAmt := 0.0
    
    if (Trim(sel) != "") {
        if RegExMatch(sel, "i)(?:GST\s*=?\s*|including\s+)(\d+(?:\.\d+)?)\s*%", &mRate) {
            detectedRate := Float(mRate[1])
        }
        tokens := ExtractNumericTokens(sel)
        if (tokens.Length > 0) {
            if (tokens.Length >= 2 && tokens[1].value = detectedRate)
                detectedAmt := tokens[2].value
            else
                detectedAmt := tokens[1].value
        }
    }
    
    if (detectedAmt > 0) {
        report := CalculateReverseGST(detectedAmt, detectedRate)
        InsertText(report)
        return
    }
    
    ibRate := OfficeInputBox("Enter GST Rate % (5, 12, 18, 28):", "Select GST Rate", String(detectedRate))
    if (ibRate.Result != "OK" || Trim(ibRate.Value) = "" || !IsNumber(Trim(ibRate.Value)))
        return
    rate := Float(Trim(ibRate.Value))
    if (rate <= -100 || rate > 500) {
        ShowToast("⚠️ GST rate must be greater than -100%", 2500)
        return
    }
    ProcessReverseGST(rate)
}

CalculateReverseGST(totalAmount, gstRate := 18) {
    p := ParseNumberOrCurrency(totalAmount)
    tot := p.isValid ? p.value : Float(totalAmount)
    if (tot <= 0)
        return "Invalid amount"
        
    fRate := Float(gstRate)
    if (fRate <= -100 || fRate > 500)
        return "Invalid GST rate (rate must be greater than -100%)"

    rateDisplay := (Round(fRate, 2) = Integer(fRate)) ? String(Integer(fRate)) : String(fRate)
    base := tot / (1 + (fRate / 100))
    tax := tot - base
    halfTax := tax / 2
    
    res := Format("Total (Incl. {}% GST): ₹{}`n• Taxable Base: ₹{}`n• Total GST ({}%): ₹{} (CGST: ₹{} | SGST: ₹{})", 
                  rateDisplay, FormatIndianCommas(tot), FormatIndianCommas(base), rateDisplay, FormatIndianCommas(tax), FormatIndianCommas(halfTax), FormatIndianCommas(halfTax))
    return res
}

