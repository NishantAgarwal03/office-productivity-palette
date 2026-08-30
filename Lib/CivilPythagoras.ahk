; ======================================================================================================================
; Module: CivilPythagoras.ahk - Geometry, Pythagoras, 3-4-5 Rule, Guniya & Bidirectional Inverse Solver
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

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
            missingSide := Sqrt(hypVal*hypVal - sideVal*sideVal)
            extraDisplay := ""
            if (unitLabel = "ft" || unitLabel = "'") {
                ftPart := Floor(missingSide)
                inPart := (missingSide - ftPart) * 12
                extraDisplay := Format(" ({1}\x27-{2:0.2f}\x22)", ftPart, inPart)
                extraDisplay := StrReplace(StrReplace(extraDisplay, "\x27", "'"), "\x22", '"')
            }

            return {
                success: true,
                category: "📐 Pythagoras (Missing Side / Inverse)",
                displayExpr: Format("√( {1}² - {2}² )", hypVal, sideVal),
                resultStr: Format("Missing Side (Base/Height): {:0.3f} {}{}", missingSide, unitLabel, extraDisplay),
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

        ; Arity Enforcement: Exactly 2 dimensions required for 2D planar geometry
        if (nums.Length < 2) {
            return {success: false, message: "Pythagoras / Diagonal requires 2 dimensions (e.g. 'pythagoras 3 4', '10x8 diag', 'diagonal 20ft 30ft', '3m base 4m height', '3m side 5m diagonal')"}
        }
        if (nums.Length > 2) {
            return {success: false, message: "2D planar only"}
        }

        a := nums[1]
        b := nums[2]
        c := Sqrt(a*a + b*b)

        is345 := false
        if (a > 0 && b > 0) {
            ratio1 := a / b
            ratio2 := b / a
            if (Abs(ratio1 - 0.75) < 0.01 || Abs(ratio2 - 0.75) < 0.01)
                is345 := true
        }

        extraDisplay := ""
        if (unitLabel = "ft" || unitLabel = "'") {
            ftPart := Floor(c)
            inPart := (c - ftPart) * 12
            extraDisplay := Format(" ({1}\x27-{2:0.2f}\x22)", ftPart, inPart)
            extraDisplay := StrReplace(StrReplace(extraDisplay, "\x27", "'"), "\x22", '"')
        }

        guniyaTag := is345 ? " [📐 3-4-5 Right-Angle / Guniya Match]" : ""

        return {
            success: true,
            category: "📐 Pythagoras / Diagonal (Guniya)",
            displayExpr: Format("√( {1}² + {2}² )", a, b),
            resultStr: Format("Diagonal / Hypotenuse (Guniya): {:0.3f} {}{}{}", c, unitLabel, extraDisplay, guniyaTag),
            val: c,
            unit: unitLabel
        }
    }
}
