; ======================================================================================================================
; Module: CivilPythagoras.ahk - Geometry, Pythagoras, 3-4-5 Rule, Guniya & Bidirectional Inverse Solver
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

; ======================================================================================================================
; ARCHITECTURAL DESIGN INTENT: STRICT HOMOGENEOUS UNITS ONLY (NO MIXED UNITS)
; 1. Single Unit System: Civil site measurements (diagonals, plot corners, room guniya) must be 
;    expressed in a single uniform unit (e.g., both in meters or both in feet).
; 2. No Silent Cross-Unit Conversion: The tool intentionally does NOT cross-convert mixed units 
;    (e.g., '10m 20ft'). Silently mixing disparate systems risks masking site layout entry errors.
; 3. User Responsibility: Both legs/sides must be provided in the identical dimensional unit.
; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [2D PLANAR GEOMETRY ONLY - 3D SPACE DIAGONAL STRICTLY OUT OF SCOPE]:
; 1. 2D Planar Scope: Strictly designed for 2D Planar Right-Angle Geometry (Base, Height, Hypotenuse,
;    Room/Plot/Slab 2D Diagonals, and Indian Site Guniya / 3-4-5 Rule Verification).
; 2. 3D Space Diagonals Excluded: Multi-dimensional 3D box/cuboid space diagonals (√(L² + W² + H²)) are an INTENTIONAL
;    NON-GOAL and strictly OUT OF SCOPE.
; 3. Arity Enforcement: Exactly 2 leg dimensions (or 1 hypotenuse + 1 leg for inverse) are accepted. If >2 dimensions
;    are provided (e.g., '90 90 120'), the solver rejects the query with an informative arity notice rather than
;    silently dropping dimensions or guessing 3D intent.
; 4. Same-Unit Invariant: Mixed units are NOT cross-converted during diagonal calculation (e.g. '20ft 5m' will adopt
;    the first resolved unit). Both legs/sides must be provided in the same dimension unit for accurate geometry.
; ======================================================================================================================
class CivilPythagoras {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Request Detection Pattern (Root-Stem Matching & Colloquial Trigger Synonyms)
    ; ------------------------------------------------------------------------------------------------------------------
    static IsPythagorasRequest(str) {
        return RegExMatch(str, "i)\b(?:pyth[a-z]*|hypotenuse|hyp\b|diagonal|diag\b|guniya|gunia|karna|tircha|tirchi|slant[a-z]*|kona\s*se\s*kona|kone\s*se\s*kone|corner[\-\s]*to[\-\s]*corner|corner\s*diagonal|room\s*diagonal|slab\s*diagonal|floor\s*diagonal|plot\s*diagonal|right[\-\s]*(?:angle|triangle|tri|ang|calc)?|right\b|triangle|theorem|longest|90\s*(?:degree|deg|°)\s*(?:triangle|check|kona|guniya|angle)|3[\-\s]4[\-\s]5|direct\s*distance|straight\s*distance)\b")
            || RegExMatch(str, "i)(?:base|height|perpendicular|perp|rise|run|horizontal|vertical|side|missing\s*side).*?(?:base|height|perpendicular|perp|rise|run|horizontal|vertical|side|hypotenuse|diagonal|diag|karna)")
            || RegExMatch(str, "i)\b\d+\s*[xX*+]\s*\d+\s*(?:diag|diagonal|hyp|tircha|guniya|pyth[a-z]*)\b")
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Evaluation Engine
    ; ------------------------------------------------------------------------------------------------------------------
    static Evaluate(str) {
        clean := str
        clean := RegExReplace(clean, "i)(\d+)\s*[xX*]\s*(\d+)", "$1 $2")
        clean := StrReplace(clean, "right-angle", "right angle")
        clean := StrReplace(clean, "corner-to-corner", "corner to corner")
        unitLabel := "m"

        ; --------------------------------------------------------------------------------------------------------------
        ; A. Inverse Pythagoras Detection (Hypotenuse Known + 1 Leg Known => Solve Missing Leg)
        ; --------------------------------------------------------------------------------------------------------------
        isInverse := false
        hypVal := 0.0
        sideVal := 0.0

        ; Case 1A: Postfix Hypotenuse first: "5m diagonal 3m side", "5m diag 4m height", "5 diagonal 3 side", "5m tircha 3m base", "5m diagonal 3m"
        if (RegExMatch(clean, "i)([\d\.]+)\s*([a-z\x27\x22]+)?\s*(?:hypotenuse|hyp\b|diagonal|diag\b|tircha|tirchi|karna)\b(?:\s*(?:and|,|with|to))?\s*(?:side|base|height|perp|perpendicular|leg|run|rise|kona)?\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?", &mInvA) && Float(mInvA[1]) > Float(mInvA[3])) {
            hypVal := Float(mInvA[1])
            sideVal := Float(mInvA[3])
            uStr := (mInvA[2] != "") ? mInvA[2] : mInvA[4]
            if (uStr != "") {
                u := CivilUnits.ResolveUnit(StrLower(uStr))
                if (u && u.dim == "L")
                    unitLabel := u.label
            }
            if (hypVal > 0 && sideVal > 0 && hypVal > sideVal)
                isInverse := true
        }
        ; Case 1B1: Prefix Hypotenuse with explicit leg keyword: "hyp 10 base 6", "tircha 5 side 3", "hyp 10 side 6"
        else if (RegExMatch(clean, "i)(?:hypotenuse|hyp\b|tircha|tirchi|karna)\b\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?(?:\s*(?:and|,|with|to))?\s*(?:side|base|height|perp|perpendicular|leg|run|rise|kona)\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?", &mInvB1)) {
            hypVal := Float(mInvB1[1])
            sideVal := Float(mInvB1[3])
            uStr := (mInvB1[2] != "") ? mInvB1[2] : mInvB1[4]
            if (uStr != "") {
                u := CivilUnits.ResolveUnit(StrLower(uStr))
                if (u && u.dim == "L")
                    unitLabel := u.label
            }
            if (hypVal > 0 && sideVal > 0 && hypVal > sideVal)
                isInverse := true
        }
        ; Case 1B2: "diagonal 5m side 3m" or "diagonal 5m 3m side"
        else if (RegExMatch(clean, "i)\b(?:diagonal|diag)\b\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?(?:\s*(?:and|,|with|to))?\s*(?:side|base|height|perp|perpendicular|leg|run|rise|kona)\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?", &mInvB2)) {
            hypVal := Float(mInvB2[1])
            sideVal := Float(mInvB2[3])
            uStr := (mInvB2[2] != "") ? mInvB2[2] : mInvB2[4]
            if (uStr != "") {
                u := CivilUnits.ResolveUnit(StrLower(uStr))
                if (u && u.dim == "L")
                    unitLabel := u.label
            }
            if (hypVal > 0 && sideVal > 0 && hypVal > sideVal)
                isInverse := true
        }
        ; Case 1C: Leg first, then Hypotenuse (MANDATORY leg keyword): "3m side 5m diagonal", "4m height 5m diag", "3 base 5 hyp", "3 side 5 tircha"
        else if (RegExMatch(clean, "i)(?:side|base|height|perp|perpendicular|leg|run|rise|kona)?\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?\s*(?:side|base|height|perp|perpendicular|leg|run|rise|kona)\s*[:=]?\s*(?:and|,|with|to)?\s*([\d\.]+)\s*([a-z\x27\x22]+)?\s*(?:hypotenuse|hyp\b|diagonal|diag\b|tircha|tirchi|karna)\b", &mInvC)) {
            sideVal := Float(mInvC[1])
            hypVal := Float(mInvC[3])
            uStr := (mInvC[2] != "") ? mInvC[2] : mInvC[4]
            if (uStr != "") {
                u := CivilUnits.ResolveUnit(StrLower(uStr))
                if (u && u.dim == "L")
                    unitLabel := u.label
            }
            if (hypVal > 0 && sideVal > 0 && hypVal > sideVal)
                isInverse := true
        }
        ; Case 1D: Prefix Leg, then Prefix Hypotenuse: "side 3m diagonal 5m", "base 6 hyp 10", "height 4m diag 5m", "side 3 tircha 5"
        else if (RegExMatch(clean, "i)(?:side|base|height|perp|perpendicular|leg|run|rise|kona)\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?(?:\s*(?:and|,|with|to))?\s*(?:hypotenuse|hyp\b|diagonal|diag\b|tircha|tirchi|karna)\b\s*[:=]?\s*([\d\.]+)\s*([a-z\x27\x22]+)?", &mInvD)) {
            sideVal := Float(mInvD[1])
            hypVal := Float(mInvD[3])
            uStr := (mInvD[2] != "") ? mInvD[2] : mInvD[4]
            if (uStr != "") {
                u := CivilUnits.ResolveUnit(StrLower(uStr))
                if (u && u.dim == "L")
                    unitLabel := u.label
            }
            if (hypVal > 0 && sideVal > 0 && hypVal > sideVal)
                isInverse := true
        }

        if (isInverse) {
            ; Solve missing leg
            missingSide := Sqrt(hypVal*hypVal - sideVal*sideVal)
            ; Check 3-4-5 ratio
            t345 := CivilPythagoras.Detect345(sideVal, missingSide, hypVal)
            ; Build clean result
            resText := CivilPythagoras.Format345Result("Missing Side", missingSide, unitLabel, t345, true)

            return {
                success: true,
                category: "📐 Pythagoras (Missing Side / Inverse)",
                displayExpr: Format("√( {1}² - {2}² )", hypVal, sideVal),
                resultStr: resText,
                val: missingSide,
                unit: unitLabel
            }
        }

        ; --------------------------------------------------------------------------------------------------------------
        ; B. Standard 2-Leg Mode (Base + Height => Hypotenuse / Diagonal / Guniya / Tircha)
        ; 80/20 Non-Destructive Parsing: Extracts numeric & unit tokens without destroying raw input
        ; --------------------------------------------------------------------------------------------------------------
        ; Normalize non-standard delimiters (commas, pluses, @, ?, :, ~, superscripts) to whitespace
        cleanTokens := RegExReplace(clean, "[,+@?:~()²\^]", " ")

        ; Neutralize angle 90 ONLY when accompanied by degree/angle terminology (preserving bare dimensions of 90)
        cleanTokens := RegExReplace(cleanTokens, "i)\b90\s*(?:(?:°|deg|degree)(?:\s*(?:triangle|check|kona|guniya|angle))?|(?:triangle|check|kona|guniya|angle))\b", " ")
        cleanTokens := StrReplace(cleanTokens, "°", " ")

        nums := []
        pPos := 1
        ; Non-destructive token extractor: matches numeric values with optional trailing unit symbols
        while RegExMatch(cleanTokens, "i)\b([\d\.]+)\s*([a-z\x27\x22]+)?\b", &mNum, pPos) {
            val := Float(mNum[1])
            uStr := (mNum.Count >= 2 && mNum[2] != "") ? mNum[2] : ""
            if (uStr != "") {
                u := CivilUnits.ResolveUnit(StrLower(uStr))
                if (u && u.dim == "L")
                    unitLabel := u.label
            }
            nums.Push(val)
            pPos := mNum.Pos + Max(mNum.Len, 1)
        }

        ; 3-4-5 Presets (e.g., '3 4 5 rule' or '3-4-5 guniya')
        if (RegExMatch(clean, "i)\b3[\-\s]4[\-\s]5\b")) {
            if (nums.Length == 0 || (nums.Length == 3 && nums[1] == 3.0 && nums[2] == 4.0 && nums[3] == 5.0)) {
                nums := [3.0, 4.0]
            }
        }

        ; Arity Enforcement: 2 dimensions for Diagonal / Hypotenuse, or 3 dimensions for Guniya Verification
        if (nums.Length < 2) {
            return {success: false, message: "Pythagoras requires 2 dimensions for diagonal or 3 dimensions to check Guniya (e.g. '8m 10m 13.2m')"}
        }
        if (nums.Length > 3) {
            return {success: false, message: "2D planar only (maximum 3 dimensions for Guniya check)"}
        }

        ; Route 3-Dimension Inputs to Guniya Verification & 3-4-5 Alignment Engine
        if (nums.Length == 3) {
            return CivilPythagoras.EvaluateGuniyaCheck(nums, unitLabel)
        }

        ; Solve diagonal
        a := nums[1], b := nums[2]
        c := Sqrt(a*a + b*b)
        ; Check 3-4-5 ratio
        t345 := CivilPythagoras.Detect345(a, b, c)
        ; Build clean result
        resText := CivilPythagoras.Format345Result("📐 Diag", c, unitLabel, t345, false)

        return {
            success: true,
            category: "📐 Pythagoras / Diagonal (Guniya)",
            displayExpr: Format("√( {1}² + {2}² )", a, b),
            resultStr: resText,
            val: c,
            unit: unitLabel
        }
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. 3-Side Guniya Verification & 3-4-5 String-Line Benchmark Engine
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateGuniyaCheck(nums, unitLabel) {
        ; 1. Sort the 3 numbers: a = smaller leg, b = larger leg, cActual = longest side (measured diagonal)
        if (nums[1] > nums[2]) {
            tmp := nums[1], nums[1] := nums[2], nums[2] := tmp
        }
        if (nums[2] > nums[3]) {
            tmp := nums[2], nums[2] := nums[3], nums[3] := tmp
        }
        if (nums[1] > nums[2]) {
            tmp := nums[1], nums[1] := nums[2], nums[2] := tmp
        }

        a := nums[1]
        b := nums[2]
        cActual := nums[3]

        ; 2. Triangle inequality guard
        if (a + b <= cActual) {
            return {success: false, message: "Invalid triangle: two sides must sum to more than diagonal"}
        }

        ; 3. True Right-Angle Diagonal & Discrepancy
        cTrue := Sqrt(a*a + b*b)
        diffDiag := cActual - cTrue

        ; 4. Actual Corner Angle via Law of Cosines
        cosTheta := (a*a + b*b - cActual*cActual) / (2.0 * a * b)
        cosTheta := Max(-1.0, Min(1.0, cosTheta))
        thetaRad := ACos(cosTheta)
        thetaDeg := thetaRad * (180.0 / 3.141592653589793)
        angleError := thetaDeg - 90.0

        ; 5. Tolerance Check (3mm for metric, ~1/8 inch = 0.0104 ft for imperial)
        tol := (unitLabel = "ft" || unitLabel = "'") ? 0.0104 : 0.003
        if (Abs(diffDiag) <= tol) {
            outMatch := Format("✔️ 90.0° Guniya Match (Diag: {:0.2f}{})", cActual, unitLabel)
            return {
                success: true,
                category: "📐 Guniya Verification",
                displayExpr: Format("Guniya: {1}{4} × {2}{4} [Diag: {3:0.2f}{4}]", a, b, cActual, unitLabel),
                resultStr: outMatch,
                val: 90.0,
                unit: "°",
                isMatched: true
            }
        }

        ; 6. Peg Shifts at Tip of Each Leg: arc movement = length * sin(|angleError|)
        dirWord := (angleError > 0) ? "IN" : "OUT"
        absRad := Abs(thetaRad - (3.141592653589793 / 2.0))
        shiftA := a * Sin(absRad)
        shiftB := b * Sin(absRad)

        if (unitLabel = "ft" || unitLabel = "'") {
            shiftA_Str := Format("{:0.1f}in", shiftA * 12.0)
            shiftB_Str := Format("{:0.1f}in", shiftB * 12.0)
        } else {
            shiftA_Str := Format("{:0.0f}mm", Round(shiftA * 1000.0))
            shiftB_Str := Format("{:0.0f}mm", Round(shiftB * 1000.0))
        }

        ; 7. Scaled 3-4-5 Benchmark fitting within measured legs
        mult := Floor(Min(a / 3.0, b / 4.0))
        if (mult < 1)
            mult := 1
        m3 := 3 * mult
        m4 := 4 * mult
        d5 := 5 * mult

        ; 8. Formulate Concise 20-50 Char Lines
        line1 := Format("⚠️ {:0.1f}° ({:+0.1f}° OFF) | True Diag: {:0.2f}{}", thetaDeg, angleError, cTrue, unitLabel)
        line2 := Format("👉 Move {:0.0f}{} peg {} {} (or {:0.0f}{} peg {})", a, unitLabel, shiftA_Str, dirWord, b, unitLabel, shiftB_Str)
        line3 := Format("👉 3-4-5 Fix: Mark {}{} & {}{} -> Cross-tape {}{}", m3, unitLabel, m4, unitLabel, d5, unitLabel)

        outFull := line1 . "`n" . line2 . "`n" . line3

        return {
            success: true,
            category: "📐 Guniya Verification",
            displayExpr: Format("Guniya: {1}{4} × {2}{4} [Diag: {3:0.2f}{4}]", a, b, cActual, unitLabel),
            resultStr: outFull,
            val: Round(thetaDeg, 2),
            unit: "°",
            isMatched: false
        }
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 4. Modular Geometry & Formatting Primitives (DRY Invariant)
    ; ------------------------------------------------------------------------------------------------------------------
    ; Feet-inches display
    static FormatFeetInches(val, unitLabel) {
        if (unitLabel != "ft" && unitLabel != "'")
            return ""
        ; Extract ft and in
        ftPart := Floor(val)
        inPart := (val - ftPart) * 12.0
        return Format(" ({1}'-{2:0.2f}`")", ftPart, inPart)
    }

    ; Detect 3-4-5 triplet
    static Detect345(sideA, sideB, hypVal) {
        legMin := Min(sideA, sideB)
        legMax := Max(sideA, sideB)
        if (legMin <= 0 || legMax <= 0 || hypVal <= 0)
            return {is345: false}

        ; Invariant ratios: 3/4 = 0.75, 3/5 = 0.60
        if (Abs(legMin / legMax - 0.75) < 0.015 && Abs(legMin / hypVal - 0.60) < 0.015) {
            mult := Round(hypVal / 5.0, 2)
            multStr := (mult == Floor(mult)) ? Format("{:0.0f}", mult) : Format("{:0.2f}", mult)
            return {is345: true, multStr: multStr, legMin: legMin, legMax: legMax, hyp: hypVal}
        }
        return {is345: false}
    }

    ; Format 3-4-5 result
    static Format345Result(mainLabel, resultVal, unitLabel, t345, isInverse := false) {
        ; Imperial string
        extraDisplay := CivilPythagoras.FormatFeetInches(resultVal, unitLabel)
        if (!t345.is345) {
            suffix := isInverse ? " (Base/Height)" : ""
            return Format("{}{}: {:0.3f} {}{}", mainLabel, suffix, resultVal, unitLabel, extraDisplay)
        }
        ; Tail tag
        diagTag := isInverse ? " (Diag)" : ""
        return Format("{}: {:0.3f} {}{}`n(True 3-4-5 Triangle | {}x Scale)`n👉 {:0.0f}{} - {:0.0f}{} -> {:0.0f}{}{}", mainLabel, resultVal, unitLabel, extraDisplay, t345.multStr, t345.legMin, unitLabel, t345.legMax, unitLabel, t345.hyp, unitLabel, diagTag)
    }
}
