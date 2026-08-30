; ======================================================================================================================
; Module: MathEvaluator.ahk - Pure-AHK Native Math Preprocessor, Expression Evaluator & Standardized Dark Math HUD
; Part of Office Productivity Hub (v2.0.0) - Zero COM Dependencies
; ======================================================================================================================

#Requires AutoHotkey v2.0

class NativeMathParser {
    tokens := []
    pos := 1
    
    static Tokenize(expr) {
        tokens := []
        i := 1
        len := StrLen(expr)
        
        while (i <= len) {
            ch := SubStr(expr, i, 1)
            
            if (ch = " " || ch = "`t" || ch = "`r" || ch = "`n") {
                i++
                continue
            }
            
            if (RegExMatch(ch, "[\d\.]")) {
                numStr := ""
                hasDot := false
                while (i <= len) {
                    c := SubStr(expr, i, 1)
                    if (c = ".") {
                        if hasDot
                            break
                        hasDot := true
                        numStr .= c
                        i++
                    } else if (RegExMatch(c, "\d")) {
                        numStr .= c
                        i++
                    } else {
                        break
                    }
                }
                if (numStr = ".")
                    throw Error("Unexpected decimal point")
                tokens.Push({type: "NUM", val: Float(numStr)})
                continue
            }
            
            if (ch = "*" && i < len && SubStr(expr, i+1, 1) = "*") {
                tokens.Push({type: "OP", val: "^"})
                i += 2
                continue
            }
            
            if (ch = "+" || ch = "-" || ch = "*" || ch = "/" || ch = "^" || ch = "(" || ch = ")") {
                tokens.Push({type: (ch = "(" || ch = ")") ? ch : "OP", val: ch})
                i++
                continue
            }
            
            throw Error("Unknown character in expression: " . ch)
        }
        tokens.Push({type: "EOF", val: ""})
        return tokens
    }
    
    static Evaluate(exprStr) {
        tokens := NativeMathParser.Tokenize(exprStr)
        parser := NativeMathParser(tokens)
        res := parser.ParseExpression()
        if (parser.Current().type != "EOF")
            throw Error("Unexpected token after expression: " . parser.Current().val)
        return res
    }
    
    __New(tokens) {
        this.tokens := tokens
        this.pos := 1
    }
    
    Current() {
        return this.tokens[this.pos]
    }
    
    Consume() {
        tok := this.tokens[this.pos]
        this.pos++
        return tok
    }
    
    ParseExpression() {
        val := this.ParseTerm()
        while (this.Current().type = "OP" && (this.Current().val = "+" || this.Current().val = "-")) {
            op := this.Consume().val
            rhs := this.ParseTerm()
            if (op = "+")
                val += rhs
            else
                val -= rhs
        }
        return val
    }
    
    ParseTerm() {
        val := this.ParsePower()
        while (this.Current().type = "OP" && (this.Current().val = "*" || this.Current().val = "/")) {
            op := this.Consume().val
            rhs := this.ParsePower()
            if (op = "*") {
                val *= rhs
            } else {
                if (rhs = 0)
                    throw Error("Division by zero")
                val /= rhs
            }
        }
        return val
    }
    
    ParsePower() {
        val := this.ParseFactor()
        if (this.Current().type = "OP" && this.Current().val = "^") {
            this.Consume()
            rhs := this.ParsePower()
            val := val ** rhs
        }
        return val
    }
    
    ParseFactor() {
        curr := this.Current()
        
        if (curr.type = "OP" && curr.val = "+") {
            this.Consume()
            return this.ParseFactor()
        }
        
        if (curr.type = "OP" && curr.val = "-") {
            this.Consume()
            return -this.ParseFactor()
        }
        
        if (curr.type = "NUM") {
            this.Consume()
            return curr.val
        }
        
        if (curr.type = "(") {
            this.Consume()
            val := this.ParseExpression()
            if (this.Current().type != ")")
                throw Error("Missing closing parenthesis")
            this.Consume()
            return val
        }
        
        throw Error("Unexpected token: " . curr.val)
    }
}

PreprocessMathExpression(rawExpr) {
    expr := Trim(rawExpr)
    if (expr == "")
        return ""

    ; 1. Clean trailing equals, question marks & whitespace
    expr := RegExReplace(expr, "\s*=\s*\??\s*$", "")
    expr := Trim(expr)
    if (expr == "")
        return ""

    ; 2. Clean currency symbols and ISO codes
    expr := RegExReplace(expr, "i)\b(?:INR|USD|EUR|GBP|JPY|Rs\.?)\b", "")
    expr := RegExReplace(expr, "[\$₹€£¥]", "")

    ; 3. Clean numeric internal grouping commas (1,25,000 -> 125000)
    expr := RegExReplace(expr, "(?<=\d),(?=\d)", "")

    ; 4. Universal Typography Normalization
    ; Brackets and braces
    expr := StrReplace(StrReplace(expr, "[", "("), "{", "(")
    expr := StrReplace(StrReplace(expr, "]", ")"), "}", ")")
    ; Unicode minuses and dashes (U+2212, U+2013, U+2014, etc.)
    expr := RegExReplace(expr, "[\x{2212}\x{2013}\x{2014}—–−]", "-")
    ; BODMAS 'of' operator
    expr := RegExReplace(expr, "i)\bof\b", " * ")
    ; Multiplications
    expr := RegExReplace(expr, "[xX×·]", " * ")
    ; Divisions
    expr := RegExReplace(expr, "[÷:]", " / ")

    ; 5. Scale Suffix Expansion (Lakh, Cr, k, M, B)
    expr := RegExReplace(expr, "i)(?<=\d)\s*(?:lakhs|lakh|lacs|lac|l)\b", " * 100000")
    expr := RegExReplace(expr, "i)(?<=\d)\s*(?:crores|crore|cr)\b", " * 10000000")
    expr := RegExReplace(expr, "i)(?<=\d)\s*(?:thousand|k)\b", " * 1000")
    expr := RegExReplace(expr, "i)(?<=\d)\s*(?:million|m)\b", " * 1000000")
    expr := RegExReplace(expr, "i)(?<=\d)\s*(?:billion|b)\b", " * 1000000000")

    ; 6. Real-World Percentage Calculations
    expr := RegExReplace(expr, "(\d+(?:\.\d+)?|\([^\(\)]+\))\s*([\+\-])\s*(\d+(?:\.\d+)?)\s*%", "$1 $2 ($1 * ($3 / 100))")
    expr := RegExReplace(expr, "(\d+(?:\.\d+)?)\s*%", "($1 / 100)")

    ; 7. Implicit Multiplication (e.g. 2(3+4) -> 2*(3+4) and (2)(3) -> (2)*(3))
    expr := RegExReplace(expr, "(?<=\d|\))\s*(?=\()", " * ")
    expr := RegExReplace(expr, "(?<=\))\s*(?=\d)", " * ")

    ; 8. Final Whitelist Filter (Only valid math tokens permitted)
    exprClean := RegExReplace(expr, "[^\d\+\-\*/\.\(\)\s\^]", "")
    exprClean := RegExReplace(exprClean, "\s+", " ")
    exprClean := Trim(exprClean)

    if (exprClean == "" || !RegExMatch(exprClean, "\d"))
        return ""

    return exprClean
}

SafeEvaluateMath(rawExpr) {
    evalResult := {
        success: false,
        result: 0.0,
        resultStr: "",
        displayExpr: "",
        errorMessage: ""
    }

    ; Bridge: Check if expression is a Pythagoras, Diagonal, Guniya, or Inverse query
    if (IsSet(CivilConverterEngine) && CivilConverterEngine.IsPythagorasRequest(rawExpr)) {
        pythRes := CivilConverterEngine.Evaluate(rawExpr)
        if (pythRes.success) {
            evalResult.success := true
            evalResult.result := pythRes.val
            evalResult.resultStr := pythRes.resultStr
            evalResult.displayExpr := pythRes.displayExpr
            return evalResult
        }
    }

    cleanExpr := PreprocessMathExpression(rawExpr)
    if (cleanExpr == "") {
        evalResult.errorMessage := "Invalid mathematical expression"
        return evalResult
    }

    try {
        resFloat := NativeMathParser.Evaluate(cleanExpr)
        
        if (Abs(resFloat) > 1e300) {
            evalResult.errorMessage := "Number overflow or infinite value"
            return evalResult
        }
        
        evalResult.result := Float(resFloat)
        
        if (Round(resFloat, 4) = Round(resFloat, 0))
            evalResult.resultStr := String(Integer(Round(resFloat, 0)))
        else
            evalResult.resultStr := RTrim(RTrim(Format("{:0.4f}", resFloat), "0"), ".")

        evalResult.displayExpr := RegExReplace(Trim(rawExpr), "\s*=\s*\??\s*$", "")
        evalResult.success := true
    } catch as err {
        if (InStr(err.Message, "Division by zero"))
            evalResult.errorMessage := "Division by zero or undefined math"
        else
            evalResult.errorMessage := err.Message
    }

    return evalResult
}

ShowCalculationResult(exprStr, resultStr) {
    global YellowHudGui, ThemeSurface, ThemeBorder, ThemeText, ThemeAccent, ThemeMuted
    
    ; Auto-dismiss any pending toast notification to prevent visual HUD overlap
    if IsSet(DismissToastHud)
        DismissToastHud()

    try A_Clipboard := resultStr

    formattedResult := (IsSet(FormatIndianCommas) && RegExMatch(resultStr, "^-?\d+(?:\.\d+)?$")) ? FormatIndianCommas(resultStr) : resultStr
    
    ; Concise formatting: Avoid repeating long expression prefixes if resultStr already contains full sentence
    displayMsg := resultStr
    if (exprStr != "" && RegExMatch(resultStr, "^-?[\d\.,]+(?:\s*[a-zA-Z°]+)?$")) {
        displayMsg := exprStr . " = " . formattedResult
    } else if (exprStr != "" && !InStr(resultStr, exprStr) && StrLen(resultStr) < 40) {
        displayMsg := exprStr . " -> " . resultStr
    }

    if IsObject(YellowHudGui) {
        try YellowHudGui.Destroy()
    }

    YellowHudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    YellowHudGui.BackColor := ThemeSurface
    
    YellowHudGui.SetFont("s10 bold c" . ThemeAccent, "Segoe UI Emoji")
    YellowHudGui.Add("Text", "x12 y9 w24 h20", "🧮")
    
    YellowHudGui.SetFont("s10 bold c" . ThemeText, "Segoe UI")
    YellowHudGui.Add("Text", "x38 y9 w330", displayMsg)

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)

    if IsSet(PositionAndShowHud)
        PositionAndShowHud(YellowHudGui, mX, mY, 350, 45, "NoActivate AutoSize")
    else
        YellowHudGui.Show("NoActivate AutoSize")

    SetTimer(() => DismissYellowHud(), -4500)

    try InsertText(resultStr)
}

DismissYellowHud() {
    global YellowHudGui
    if IsObject(YellowHudGui) {
        try YellowHudGui.Destroy()
    }
}

IsYellowHudVisible() {
    global YellowHudGui
    return IsObject(YellowHudGui) && WinExist("ahk_id " . YellowHudGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", YellowHudGui.Hwnd)
}
