; ======================================================================================================================
; Module: NumberParser.ahk - Strict Shared Number & Currency Parser & Indian Words Engine
; ======================================================================================================================

#Requires AutoHotkey v2.0

ParseNumberOrCurrency(rawText) {
    result := {
        isValid: false,
        value: 0.0,
        isNegative: false,
        raw: String(rawText),
        clean: "",
        unit: "",
        currency: "NONE"
    }

    txt := Trim(String(rawText))
    if (txt == "")
        return result

    ; Check accounting negative: (1,500.00) or ($1,500.00)
    isNeg := false
    hasSign := false
    if RegExMatch(txt, "^\s*\((.+)\)\s*$", &mAcc) {
        isNeg := true
        hasSign := true
        txt := Trim(mAcc[1])
    } 
    ; Check strict leading prefix sign: -1500, -$1500, +500
    else if RegExMatch(txt, "^\s*([\+\-])\s*(.*)$", &mPreSign) {
        hasSign := true
        if (mPreSign[1] == "-")
            isNeg := true
        txt := Trim(mPreSign[2])
    }

    ; Detect Currency
    if RegExMatch(txt, "i)(?:INR|Rs\.?|Rupees?)\b|₹", &mCur)
        result.currency := "INR"
    else if RegExMatch(txt, "i)USD\b|\$", &mCur)
        result.currency := "USD"
    else if RegExMatch(txt, "i)EUR\b|€", &mCur)
        result.currency := "EUR"
    else if RegExMatch(txt, "i)GBP\b|£", &mCur)
        result.currency := "GBP"
    else if RegExMatch(txt, "i)JPY\b|¥", &mCur)
        result.currency := "JPY"

    ; Strip currency words and symbols
    txt := RegExReplace(txt, "i)\b(?:INR|USD|EUR|GBP|JPY|Rs\.?|Rupees?)\b", "")
    txt := RegExReplace(txt, "[\$₹€£¥]", "")
    txt := Trim(txt)

    ; Check post-currency prefix sign (e.g. $-1500) ONLY if no prior sign was present
    if (!hasSign && RegExMatch(txt, "^\s*([\+\-])\s*(.*)$", &mPostSign)) {
        hasSign := true
        if (mPostSign[1] == "-")
            isNeg := true
        txt := Trim(mPostSign[2])
    }

    ; STRICT REJECTION: Reject any lingering internal hyphens (12-34-56), double signs (--500), or trailing hyphens (500-)
    if RegExMatch(txt, "[\+\-]")
        return result

    ; ==================================================================================================================
    ; SCOPE & DESIGN BOUNDARY [INDIAN NUMBER SYSTEM PRIORITY - INTENTIONAL NON-GOALS]:
    ; 1. System Priority: Designed primarily around the Indian numbering and financial system (Crore, Lakh, Thousand, k).
    ; 2. Scientific Notation: Formats like '1e6', '1E+06', '2.5e-3' are intentionally NOT parsed or supported.
    ; 3. Non-Standard Shorthands: Shorthands like 'mn', 'bn' are intentionally excluded in favor of explicit terms
    ;    (or standard Indian Crore/Lakh) to prevent false-positive token collisions in general office text.
    ; ==================================================================================================================
    multiplier := 1.0
    unitName := ""

    ; Check Indian Crores (12 cr, 12 crore, 12 crores, 2.5 Cr)
    if RegExMatch(txt, "i)^([\d\.,\s]+?)\s*(?:cr|crore|crores)\b", &mUnit) {
        multiplier := 10000000.0
        unitName := "Crore"
        txt := Trim(mUnit[1])
    }
    ; Check Indian Lakhs (1.25 lakh, 1.25 lakhs, 1.25 lac, 1.25 lacs, 1.25l)
    else if RegExMatch(txt, "i)^([\d\.,\s]+?)\s*(?:l|lakh|lakhs|lac|lacs)\b", &mUnit) {
        multiplier := 100000.0
        unitName := "Lakh"
        txt := Trim(mUnit[1])
    }
    ; Check Thousands (12k, 12 thousand, 12 thousands, 12.5k)
    else if RegExMatch(txt, "i)^([\d\.,\s]+?)\s*(?:k|thousand|thousands)\b", &mUnit) {
        multiplier := 1000.0
        unitName := "Thousand"
        txt := Trim(mUnit[1])
    }
    ; Check Millions (12m, 1.5 million, 1.5 millions)
    else if RegExMatch(txt, "i)^([\d\.,\s]+?)\s*(?:m|million|millions)\b", &mUnit) {
        multiplier := 1000000.0
        unitName := "Million"
        txt := Trim(mUnit[1])
    }
    ; Check Billions (1.5b, 1.5 billion, 1.5 billions)
    else if RegExMatch(txt, "i)^([\d\.,\s]+?)\s*(?:b|billion|billions)\b", &mUnit) {
        multiplier := 1000000000.0
        unitName := "Billion"
        txt := Trim(mUnit[1])
    }

    txt := StrReplace(txt, " ", "")

    ; Check European format: (1.250,50 or 12.345.678,90 or 1250,50)
    if RegExMatch(txt, "^\d{1,3}(?:\.\d{3})+,\d+$") || RegExMatch(txt, "^\d+,\d{1,2}$") {
        txt := StrReplace(txt, ".", "")
        txt := StrReplace(txt, ",", ".")
    } else {
        txt := StrReplace(txt, ",", "")
    }

    if (SubStr(txt, 1, 1) = ".")
        txt := "0" . txt

    if (txt == "" || !RegExMatch(txt, "^\d+(?:\.\d+)?$"))
        return result

    baseVal := Float(txt)
    finalVal := baseVal * multiplier

    if isNeg
        finalVal := -finalVal

    result.isValid := true
    result.value := finalVal
    result.isNegative := isNeg
    result.unit := unitName
    
    if (Round(finalVal, 4) = Round(finalVal, 0))
        result.clean := String(Integer(finalVal))
    else
        result.clean := RTrim(RTrim(Format("{:0.4f}", finalVal), "0"), ".")

    return result
}

CleanToMachineNumber(rawText) {
    p := ParseNumberOrCurrency(rawText)
    if !p.isValid
        return String(rawText)
    
    if (Round(p.value, 2) = Round(p.value, 0))
        return String(Integer(p.value))
    return Format("{:0.2f}", p.value)
}

; ======================================================================================================================
; DESIGN DECISION [INDIAN COMMA FORMATTING - NO CURRENCY SYMBOL PREPEND]:
; Does NOT prepend the ₹ symbol. This is intentional — the user may be formatting 
; non-monetary numbers (quantities, civil engineering measurements, units, counts).
; Only standard Indian numbering grouping (12,34,567.89) is applied.
; ======================================================================================================================
FormatIndianCommas(numOrStr, includeDecimals := true) {
    p := ParseNumberOrCurrency(numOrStr)
    if !p.isValid
        return String(numOrStr)

    absVal := Abs(p.value)
    
    if (!includeDecimals) {
        intVal := Integer(Round(absVal, 0))
        intStr := String(intVal)
        len := StrLen(intStr)
        if (len <= 3)
            formattedInt := intStr
        else {
            last3 := SubStr(intStr, len - 2)
            rest := SubStr(intStr, 1, len - 3)
            formattedRest := RegExReplace(rest, "\G\d+?(?=(\d{2})+$)", "$0,")
            formattedInt := formattedRest . "," . last3
        }
        signPrefix := p.isNegative ? "-" : ""
        return signPrefix . formattedInt
    }

    ; Round whole value to 2 decimals first to correctly propagate carries (e.g. 999.999 -> 1,000.00)
    roundedStr := Format("{:0.2f}", Round(absVal, 2))
    dotPos := InStr(roundedStr, ".")
    intStr := SubStr(roundedStr, 1, dotPos - 1)
    decStr := SubStr(roundedStr, dotPos)
    
    len := StrLen(intStr)
    if (len <= 3)
        formattedInt := intStr
    else {
        last3 := SubStr(intStr, len - 2)
        rest := SubStr(intStr, 1, len - 3)
        formattedRest := RegExReplace(rest, "\G\d+?(?=(\d{2})+$)", "$0,")
        formattedInt := formattedRest . "," . last3
    }

    signPrefix := p.isNegative ? "-" : ""
    return signPrefix . formattedInt . decStr
}

FormatInternationalCommas(numOrStr, includeDecimals := true) {
    p := ParseNumberOrCurrency(numOrStr)
    if !p.isValid
        return String(numOrStr)

    absVal := Abs(p.value)
    
    if (!includeDecimals) {
        intVal := Integer(Round(absVal, 0))
        intStr := String(intVal)
        formattedInt := RegExReplace(intStr, "\G\d+?(?=(\d{3})+$)", "$0,")
        signPrefix := p.isNegative ? "-" : ""
        return signPrefix . formattedInt
    }

    ; Round whole value to 2 decimals first to correctly propagate carries (e.g. 999.999 -> 1,000.00)
    roundedStr := Format("{:0.2f}", Round(absVal, 2))
    dotPos := InStr(roundedStr, ".")
    intStr := SubStr(roundedStr, 1, dotPos - 1)
    decStr := SubStr(roundedStr, dotPos)
    
    formattedInt := RegExReplace(intStr, "\G\d+?(?=(\d{3})+$)", "$0,")
    signPrefix := p.isNegative ? "-" : ""
    return signPrefix . formattedInt . decStr
}

NumberToIndianWords(rawText) {
    p := ParseNumberOrCurrency(rawText)
    if (!p.isValid || p.isNegative) {
        if (!p.isValid)
            return "Invalid Number"
        if (p.isNegative)
            return "Negative Amounts Not Supported"
    }

    val := p.value
    intVal := Integer(val)
    
    paiseVal := Integer(Round((val - intVal) * 100))
    if (paiseVal = 100) {
        intVal += 1
        paiseVal := 0
    }

    if (intVal = 0 && paiseVal = 0)
        return "Rupees Zero Only"

    words := ""
    if (intVal > 0)
        words := ConvertIntToIndianWords(intVal)

    res := ""
    if (words != "")
        res := "Rupees " . words

    if (paiseVal > 0) {
        paiseWords := ConvertTwoDigits(paiseVal)
        if (res != "")
            res .= " and " . paiseWords . " Paise"
        else
            res := paiseWords . " Paise"
    }

    return res . " Only"
}

ConvertIntToIndianWords(num) {
    if (num = 0)
        return "Zero"

    units := ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", 
              "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"]

    out := ""

    if (num >= 10000000) {
        croreVal := num // 10000000
        num := Mod(num, 10000000)
        out .= ConvertIntToIndianWords(croreVal) . " Crore"
    }

    if (num >= 100000) {
        lakhVal := num // 100000
        num := Mod(num, 100000)
        out .= (out != "" ? " " : "") . ConvertTwoDigits(lakhVal) . " Lakh"
    }

    if (num >= 1000) {
        thousandVal := num // 1000
        num := Mod(num, 1000)
        out .= (out != "" ? " " : "") . ConvertTwoDigits(thousandVal) . " Thousand"
    }

    if (num >= 100) {
        hundredVal := num // 100
        num := Mod(num, 100)
        out .= (out != "" ? " " : "") . units[hundredVal] . " Hundred"
    }

    if (num > 0) {
        out .= (out != "" ? " " : "") . ConvertTwoDigits(num)
    }

    return out
}

ConvertTwoDigits(num) {
    units := ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", 
              "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
    tens := ["Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]

    if (num <= 0)
        return ""
    if (num < 20)
        return units[num]

    t := num // 10
    u := Mod(num, 10)
    res := tens[t - 1]
    if (u > 0)
        res .= "-" . units[u]
    return res
}

ExtractNumericTokens(text) {
    tokens := []
    for line in StrSplit(text, ["`r`n", "`n", "`r", "`t", ";"]) {
        trimmed := Trim(line)
        if (trimmed == "")
            continue
        pPos := 1
        ; Unified pattern preserving currency signs, commas, decimals, and scale suffixes
        pattern := "i)(?:\([-+]?(?:₹|INR|Rs\.?|USD|\$|EUR|€|GBP|£|JPY|¥)?\s*[\d,]+(?:\.\d+)?\s*(?:cr|crore|crores|lakh|lakhs|lac|lacs|k|thousand|thousands|m|million|millions|b|billion|billions)?\)|[-+]?(?:₹|INR|Rs\.?|USD|\$|EUR|€|GBP|£|JPY|¥)?\s*[\d,]+(?:\.\d+)?\s*(?:cr|crore|crores|lakh|lakhs|lac|lacs|k|thousand|thousands|m|million|millions|b|billion|billions)?)"
        while RegExMatch(trimmed, pattern, &m, pPos) {
            valStr := Trim(m[0])
            p := ParseNumberOrCurrency(valStr)
            if (p.isValid) {
                tokens.Push(p)
            }
            pPos := m.Pos + Max(m.Len, 1)
            if (pPos > StrLen(trimmed))
                break
        }
    }
    return tokens
}

ExtractAllNumbers(text) {
    tokens := ExtractNumericTokens(text)
    nums := []
    for tok in tokens {
        nums.Push(tok.value)
    }
    return nums
}

