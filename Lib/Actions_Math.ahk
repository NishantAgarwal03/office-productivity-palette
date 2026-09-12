; ======================================================================================================================
; Module: Actions_Math.ahk - 10 Math, Tax, Number & Conversion Tools (Self-Healing Fallbacks)
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterMathActions() {
    RegisterAction("Evaluate Math Expression", "🧮 Math", "[Needs Selection] Computes formula (e.g. 1500 * 1.18 + 450)", "calc, math, evaluate, formula, compute, scale, lakh, crore, thousand, million, billion", (*) => EvaluateMathSelection(), "c")
    RegisterAction("GST / Tax Breakdown (18%)", "🧮 Math", "[Needs Selection] Calculates Base + 18% Tax + Total on number", "gst, tax, 18%, vat, breakdown", (*) => CalculateTaxBreakdown(18))
    RegisterAction("Percentage Change & Growth Calculator", "🧮 Math", "[Needs Selection] Calculates relative change & symmetric difference between two numbers", "percent, percentage, change, growth, delta, symmetric, difference", (*) => CalculatePercentageDelta())
    RegisterAction("Generate 16-Char Secure Password", "🧮 Math", "Generates & inserts random secure password (also copied to clipboard)", "password, secure, random, pass, generate", (*) => InsertText(GenerateSecurePassword(16)), "p")
    RegisterAction("Generate UUID / GUID v4", "🧮 Math", "Generates & inserts standard UUID v4 (also copied to clipboard)", "uuid, guid, id, unique", (*) => InsertText(GenerateUUID()))
    RegisterAction("Round Number to 2 Decimals", "🧮 Math", "[Needs Selection] Rounds float number to 2 decimal places", "round, decimal, precision, float", (*) => TransformSelectedText((txt) => RoundNumber(txt, 2)))
    RegisterAction("Sum Column of Selected Numbers", "🧮 Math", "[Needs Selection] Sums all numbers in highlighted text", "sum, total, add, column, numbers", (*) => SumSelectedNumbers())
    RegisterAction("Unix Timestamp to Readable Date", "🧮 Math", "[Needs Selection] Converts Unix epoch seconds to readable date/time", "unix, epoch, convert, time, timestamp", (*) => ConvertUnixTimestamp())
    RegisterAction("Number to Words (Indian Rupees)", "🧮 Math", "[Needs Selection] Converts amount to Indian words (e.g. Rupees Two Lakh Only)", "words, indian, lakh, crore, rupees, cheque, amount, invoice, paise, tow, towards, towords, in words", (*) => ConvertSelectedNumberToIndianWords(), "w")
}

EvaluateMathSelection() {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Enter math formula (e.g. 1500*1.18+450 or 2^8):", "Math Evaluator")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    
    evalRes := SafeEvaluateMath(sel)
    if (!evalRes.success) {
        ; DEFECT-034: Sanitize error messages — never expose raw COM HRESULT codes (e.g. 0x80040154)
        ; to the user.  In v1.0.0 a missing MSScriptControl COM class produced "Class not registered"
        ; with a hex error code that was meaningless to end-users.  Guard defensively so any future
        ; regression surfaces a clear, actionable message instead of a hex code.
        errMsg := evalRes.errorMessage
        if (InStr(errMsg, "0x") || InStr(errMsg, "Class not registered") || InStr(errMsg, "MSScriptControl"))
            errMsg := "Math evaluator unavailable — expression uses unsupported syntax or a system component is missing."
        ShowToast("⚠️ " . errMsg, 2500)
        return
    }
    
    ShowCalculationResult(evalRes.displayExpr, evalRes.resultStr)
}

CalculateTaxBreakdown(taxRatePercent) {
    sel := SafeGetSelection()
    p := ParseNumberOrCurrency(sel)
    if (!p.isValid || p.value <= 0) {
        ib := OfficeInputBox("Enter base amount (e.g. 1000 or 1.25 Lakh):", "GST " . taxRatePercent . "% Calculator")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        p := ParseNumberOrCurrency(ib.Value)
        if (!p.isValid || p.value <= 0) {
            ShowToast("⚠️ Invalid base amount entered", 2000)
            return
        }
    }
    
    base := p.value
    tax := base * (taxRatePercent / 100)
    total := base + tax
    out := Format("Base: ₹{} | Tax ({}%): ₹{} | Total: ₹{}", FormatIndianCommas(base), taxRatePercent, FormatIndianCommas(tax), FormatIndianCommas(total))
    ShowCalculationResult("GST " . taxRatePercent . "% (" . FormatIndianCommas(base) . ")", out)
}

CalculatePercentageDelta() {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Enter two numbers (e.g. 100 125 or 1L 1.25L):", "Percentage Delta")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    res := ComputePercentageChange(sel)
    ShowCalculationResult("Percentage Change & Growth", res["summary"])
}

ComputePercentageChange(text) {
    nums := ExtractAllNumbers(text)
    if (nums.Length < 2)
        throw Error("Percentage Change: Expected 2 numbers in input text (e.g. '100 to 125')")
    oldVal := nums[1]
    newVal := nums[2]
    if (oldVal = 0 && newVal = 0)
        throw Error("Percentage Change: Both values cannot be 0")

    relPct := (oldVal != 0) ? (((newVal - oldVal) / oldVal) * 100) : 0.0
    avgVal := (Abs(oldVal) + Abs(newVal)) / 2.0
    symmDiff := (avgVal > 0) ? (Abs(newVal - oldVal) / avgVal) * 100 : 0.0

    relStr := (oldVal != 0) ? Format("Change ({:0.2f} -> {:0.2f}): {:+0.2f}%", oldVal, newVal, relPct) : Format("Change ({:0.2f} -> {:0.2f}): N/A (Base is 0)", oldVal, newVal)
    symmStr := Format("Symm Difference: {:0.2f}% (|A-B| / Avg)", symmDiff)
    summary := relStr . "`n" . symmStr

    return Map(
        "relative_change", relPct,
        "symmetric_change", symmDiff,
        "summary", summary,
        "result", summary,
        "text", summary
    )
}

GenerateSecurePassword(length := 16) {
    static defaultWords := [
        "above", "across", "after", "against", "also", "among", "ancient", "another", "artists", "awaken",
        "banks", "before", "began", "bells", "best", "better", "borders", "breezes", "builders", "campus",
        "campuses", "care", "careful", "carried", "cattle", "channels", "character", "clean", "clouds", "collect",
        "common", "computers", "connect", "cooks", "crafts", "create", "crops", "cultures", "curiosity", "daily",
        "develop", "difficult", "discover", "drains", "drawing", "dryness", "during", "effort", "elders", "encourage",
        "enrich", "equal", "even", "every", "explain", "fair", "fairness", "fallen", "faraway", "farming",
        "farms", "fertile", "fields", "filled", "flowers", "food", "forest", "forms", "fresh", "fruits",
        "games", "gardeners", "gentle", "gives", "ground", "group", "growers", "growing", "grows", "guards",
        "guides", "habits", "harvest", "healthy", "heat", "heavy", "helps", "herbs", "history", "hold",
        "homes", "honest", "household", "households", "ideas", "improve", "insects", "inspire", "kind", "laborers",
        "lamps", "lands", "later", "layers", "learn", "learning", "leaves", "lessons", "libraries", "life",
        "lifelong", "light", "local", "losing", "losses", "makers", "manage", "manuals", "mapping", "maps",
        "markets", "meals", "measuring", "mentors", "might", "millet", "minds", "modern", "months", "morning",
        "music", "narrow", "nature", "nearby", "needs", "neighbors", "numbers", "patience", "patient", "pests",
        "pillar", "planning", "planted", "plants", "ponds", "power", "precious", "prepare", "prices", "progress",
        "protect", "protects", "provide", "pulses", "quiet", "rainfall", "rainwater", "rainy", "readers", "reading",
        "records", "reduce", "reduces", "region", "remains", "renowned", "repair", "respect", "respects", "rested",
        "reveal", "reward", "riders", "ridges", "river", "roads", "room", "roots", "rotate", "safe",
        "save", "schoolers", "science", "seasons", "security", "seeds", "select", "service", "settlement", "shade",
        "shared", "shelters", "shelves", "shops", "silver", "simple", "single", "skilled", "skills", "slowly",
        "small", "soil", "spaces", "sparrows", "steady", "storage", "storms", "storybooks", "streams", "strong",
        "studying", "such", "summer", "supplies", "support", "tables", "tanks", "teach", "teamwork", "tools",
        "toward", "trade", "traders", "trees", "useful", "valleys", "varied", "vegetables", "villagers", "walkers",
        "waste", "water", "weather", "wellness", "wells", "wheat", "when", "while", "wildlife", "with",
        "within", "without", "young", "youngsters"
    ]
    static substitutions := Map(
        "g", "9", "b", "8", "z", "2", "x", "*", "o", "0", 
        "i", "!", "e", "3", "a", "@", "s", "$", "l", "1"
    )

    baseWord := defaultWords[Random(1, defaultWords.Length)]

    transformed := ""
    loop parse baseWord {
        ch := A_LoopField
        chLower := StrLower(ch)
        
        if substitutions.Has(chLower) {
            transformed .= substitutions[chLower]
        } else if (chLower = "c" || chLower = "v" || chLower = "u" || chLower = "n") {
            transformed .= StrUpper(chLower)
        } else {
            transformed .= ch
        }
    }

    tLen := StrLen(transformed)
    if (tLen >= length) {
        transformed := SubStr(transformed, 1, length - 2)
        tLen := StrLen(transformed)
    }

    remLen := length - tLen
    prefixLen := Random(0, remLen)
    suffixLen := remLen - prefixLen

    prefixPad := GenerateRandomChars(prefixLen)
    suffixPad := GenerateRandomChars(suffixLen)

    return prefixPad . transformed . suffixPad
}

GenerateRandomChars(len) {
    chars := "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*()-_"
    cLen := StrLen(chars)
    if (len <= 0)
        return ""
        
    buf := Buffer(len, 0)
    ; Win32 RtlGenRandom (SystemFunction036) provides cryptographically secure hardware/OS entropy
    if (DllCall("advapi32\SystemFunction036", "Ptr", buf.Ptr, "UInt", len)) {
        pass := ""
        loop len {
            byteVal := NumGet(buf, A_Index - 1, "UChar")
            idx := Mod(byteVal, cLen) + 1
            pass .= SubStr(chars, idx, 1)
        }
        return pass
    }
    
    ; Fail-safe PRNG fallback
    cArr := StrSplit(chars)
    pass := ""
    Loop len {
        pass .= cArr[Random(1, cArr.Length)]
    }
    return pass
}

GenerateUUID() {
    guid := Buffer(16, 0)
    if DllCall("ole32\\CoCreateGuid", "Ptr", guid.Ptr) = 0 {
        return Format("{:08X}-{:04X}-{:04X}-{:02X}{:02X}-{:02X}{:02X}{:02X}{:02X}{:02X}{:02X}",
            NumGet(guid, 0, "UInt"),
            NumGet(guid, 4, "UShort"),
            NumGet(guid, 6, "UShort"),
            NumGet(guid, 8, "UChar"), NumGet(guid, 9, "UChar"),
            NumGet(guid, 10, "UChar"), NumGet(guid, 11, "UChar"), NumGet(guid, 12, "UChar"),
            NumGet(guid, 13, "UChar"), NumGet(guid, 14, "UChar"), NumGet(guid, 15, "UChar"))
    }
    return ""
}

RoundNumber(text, decimals := 2) {
    p := ParseNumberOrCurrency(text)
    if (p.isValid)
        return Format("{:0." . decimals . "f}", Round(p.value, decimals))
    return String(text)
}

FormatSumOutput(nums) {
    if (nums.Length = 0)
        return ""

    total := 0.0
    for val in nums {
        total += val
    }

    itemsExpr := ""
    for numIdx, val in nums {
        valStr := (Round(val, 2) = Round(val, 0)) ? String(Integer(Round(val, 0))) : RTrim(RTrim(Format("{:0.2f}", val), "0"), ".")
        if (numIdx == 1) {
            itemsExpr := valStr
        } else if (val < 0) {
            itemsExpr .= " - " . SubStr(valStr, 2)
        } else {
            itemsExpr .= " + " . valStr
        }
    }

    itemsLabel := Format("Items ({}):", nums.Length)
    padCount := Max(1, StrLen(itemsLabel) - StrLen("Total") - 1)
    padSpaces := ""
    loop padCount
        padSpaces .= " "
    totalLabel := "Total" . padSpaces . ":"

    totalFormatted := (total < 0) ? "-₹" . FormatIndianCommas(Abs(total)) : "₹" . FormatIndianCommas(total)
    totalPlain := Format("{:0.2f}", total)

    return itemsLabel . " " . itemsExpr . "`n" . totalLabel . " " . totalFormatted . " (" . totalPlain . ")"
}

SumSelectedNumbers() {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Enter numbers to sum (space, comma, or newline):", "Sum Numbers")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    nums := ExtractAllNumbers(sel)
    if (nums.Length = 0) {
        ShowToast("⚠️ No valid numbers found", 2000)
        return
    }
    out := FormatSumOutput(nums)
    ShowCalculationResult("", out)
}

; ======================================================================================================================
; ARCHITECTURAL INVARIANT & SCOPE BOUNDARY [DO NOT MODIFY / DO NOT "FIX" TO UTC]:
; 1. Timezone: Strictly hard-targeted to the user's Local System Time (IST). Custom timezone selection
;    or UTC conversion toggles are deliberately excluded to keep the tool fast and zero-friction.
;    UTC is not a choice. Only IST / Local System Time is intended. The addition of DateDiff(A_Now, A_NowUTC, "seconds")
;    is a deliberate project design requirement, NOT an oversight or miss.
; 2. Milliseconds: Sub-second precision (.SSS) is intentionally truncated. Output is always standard
;    second-level resolution (yyyy-MM-dd HH:mm:ss).
; 3. Offset Arithmetic: Complex daylight saving / custom time offset parameters are intentionally omitted.
; ======================================================================================================================
FormatUnixTimestamp(rawVal) {
    num := RegExReplace(String(rawVal), "[^\d]", "")
    if (!IsNumber(num) || StrLen(num) < 9)
        return ""
    epochSecs := (StrLen(num) >= 12) ? Integer(SubStr(num, 1, 10)) : Integer(num)
    tzOffset := DateDiff(A_Now, A_NowUTC, "seconds")
    localDt := DateAdd("19700101000000", epochSecs + tzOffset, "seconds")
    return FormatTime(localDt, "yyyy-MM-dd HH:mm:ss")
}

ConvertUnixTimestamp() {
    sel := SafeGetSelection()
    num := RegExReplace(sel, "[^\d]", "")
    if (!IsNumber(num) || StrLen(num) < 9) {
        ib := OfficeInputBox("Enter Unix epoch timestamp (e.g. 1787385200):", "Unix Timestamp")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        num := RegExReplace(ib.Value, "[^\d]", "")
        if (!IsNumber(num) || StrLen(num) < 9) {
            ShowToast("⚠️ Invalid timestamp entered", 2500)
            return
        }
    }
    res := FormatUnixTimestamp(num)
    if (res != "")
        InsertText(res)
    else
        ShowToast("⚠️ Invalid timestamp entered", 2500)
}

ConvertSelectedNumberToIndianWords() {
    sel := SafeGetSelection()
    if (Trim(sel) = "") {
        ib := OfficeInputBox("Enter amount in digits (e.g. 1.25 Lakh or 125000):", "Number to Words")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        sel := ib.Value
    }
    
    words := NumberToIndianWords(sel)
    if (words = "Invalid Number" || words = "Negative Amounts Not Supported") {
        ShowToast("⚠️ " . words, 2000)
        return
    }
    
    ShowCalculationResult(Trim(sel), words)
}

