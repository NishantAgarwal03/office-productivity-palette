; ======================================================================================================================
; Module: MathEvaluator.ahk - Safe Math Preprocessor, Expression Evaluator & Yellow Post-It HUD
; ======================================================================================================================

#Requires AutoHotkey v2.0

PreprocessMathExpression(rawExpr) {
    expr := Trim(rawExpr)
    if (expr == "")
        return ""

    expr := RegExReplace(expr, "\s*=\s*\??\s*$", "")
    expr := Trim(expr)
    if (expr == "")
        return ""

    expr := RegExReplace(expr, "i)\b(?:INR|USD|EUR|GBP|JPY|Rs\.?)\b", "")
    expr := RegExReplace(expr, "[\$₹€£¥]", "")

    expr := RegExReplace(expr, "(?<=\d),(?=\d)", "")

    expr := StrReplace(StrReplace(expr, "[", "("), "{", "(")
    expr := StrReplace(StrReplace(expr, "]", ")"), "}", ")")

    while RegExMatch(expr, "(\d+(?:\.\d+)?|\([^\(\)]+\))\s*(?:\^|\*\*)\s*(\d+(?:\.\d+)?|\([^\(\)]+\))", &m) {
        expr := StrReplace(expr, m[0], "Math.pow(" . m[1] . ", " . m[2] . ")", , , 1)
    }

    expr := RegExReplace(expr, "(?<=\d|\))\s*[xX×·]\s*(?=\d|\()", " * ")
    expr := RegExReplace(expr, "(?<=\d|\))\s*\*\s*(?=\d|\()", " * ")

    expr := RegExReplace(expr, "(?<=\d|\))\s*[÷\\/:]\s*(?=\d|\()", " / ")

    expr := RegExReplace(expr, "(\d+(?:\.\d+)?|\([^\(\)]+\))\s*([\+\-])\s*(\d+(?:\.\d+)?)\s*%", "$1 $2 ($1 * ($3 / 100))")

    expr := RegExReplace(expr, "(\d+(?:\.\d+)?)\s*%", "($1 / 100)")

    exprClean := RegExReplace(expr, "[^\d\+\-\*/\.\(\)\sMath\.pow,]", "")
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

    cleanExpr := PreprocessMathExpression(rawExpr)
    if (cleanExpr == "") {
        evalResult.errorMessage := "Invalid mathematical expression"
        return evalResult
    }

    doc := ""
    try {
        doc := ComObject("htmlfile")
        doc.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
        jsResult := doc.parentWindow.eval(cleanExpr)
        
        resString := String(jsResult)
        if (resString = "Infinity" || resString = "-Infinity") {
            evalResult.errorMessage := "Division by zero (Infinity)"
            return evalResult
        }
        if (resString = "NaN" || resString = "undefined") {
            evalResult.errorMessage := "Evaluation resulted in NaN"
            return evalResult
        }

        if IsNumber(jsResult) {
            resFloat := Float(jsResult)
            evalResult.result := resFloat
            
            if (Round(resFloat, 4) = Round(resFloat, 0))
                evalResult.resultStr := String(Integer(resFloat))
            else
                evalResult.resultStr := RTrim(RTrim(Format("{:0.4f}", resFloat), "0"), ".")
        } else {
            evalResult.resultStr := resString
        }

        evalResult.displayExpr := RegExReplace(Trim(rawExpr), "\s*=\s*\??\s*$", "")
        evalResult.success := true
    } catch as err {
        evalResult.errorMessage := err.Message
    } finally {
        if IsObject(doc) {
            try doc.close()
        }
    }

    return evalResult
}

ShowCalculationResult(exprStr, resultStr) {
    global YellowHudGui
    
    try A_Clipboard := resultStr

    displayMsg := (exprStr != "") ? (exprStr . " = " . resultStr) : resultStr

    if IsObject(YellowHudGui) {
ExitApp(0)
