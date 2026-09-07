; ======================================================================================================================
; Module: CivilSurvey.ahk - Slope, Gradient, Fall in Distance, DMS Angles & Concrete Grade Strengths
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

class CivilSurvey {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Request Detection Patterns
    ; ------------------------------------------------------------------------------------------------------------------
    static IsSlopeRequest(str) {
        return RegExMatch(str, "i)\b(?:slope|gradient|fall|rise|1:\d+|1\s*in\s*\d+)\b")
    }

    static IsAngleDmsRequest(str) {
        return RegExMatch(str, "i)(?:°|dms|bearing|azimuth|\b\d+[\- ]\d+[\- ]\d+\b)")
    }

    static IsConcreteGradeRequest(str, &mGrade) {
        return RegExMatch(str, "i)^m\s*(\d{2})\b(?:\s*(?:to|in|into|=|ko)\s*([a-z0-9²³\/]+))?", &mGrade)
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; Unified Evaluator Entry Point (Contract Uniformity)
    ; ------------------------------------------------------------------------------------------------------------------
    static Evaluate(str, param := "", cfg := "") {
        if (!IsObject(cfg)) {
            cfg := (IsSet(CivilConverterEngine) && HasMethod(CivilConverterEngine, "LoadConfig")) ? CivilConverterEngine.LoadConfig() : Map("SlopeDefaultRunM", 10.0)
        }
        if (CivilSurvey.IsAngleDmsRequest(str))
            return CivilSurvey.EvaluateAngleDms(str)
        if (CivilSurvey.IsConcreteGradeRequest(str, &mGrade))
            return CivilSurvey.EvaluateConcreteGrade(str, mGrade)
        if (CivilSurvey.IsSlopeRequest(str))
            return CivilSurvey.EvaluateSlope(str, param, cfg)
        return {success: false, message: "Unrecognized survey, slope or angle query"}
    }


    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Slope, Fall & Gradient Subsystem
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateSlope(str, param, cfg) {
        ; Case A: Fall over run (e.g. "fall 100mm in 10m", "fall 100mm to 10m", or "30mm fall in 3m")
        if (RegExMatch(str, "i)(?:fall|rise)?\s*([\d\.]+)\s*(mm|cm|m|inch)?\s*(?:fall|rise)?\s*(?:in|over|for|to|\/)\s*([\d\.]+)\s*(m|ft|mm|cm)?", &mFall)) {
            riseVal := Float(mFall[1])
            riseUnit := (mFall[2] != "") ? CivilUnits.ResolveUnit(StrLower(mFall[2])) : CivilUnits.ResolveUnit("mm")
            runVal := Float(mFall[3])
            runUnit := (mFall[4] != "") ? CivilUnits.ResolveUnit(StrLower(mFall[4])) : CivilUnits.ResolveUnit("m")

            riseM := riseVal * riseUnit.factor
            runM := runVal * runUnit.factor

            if (runM <= 0)
                return {success: false, message: "Slope run cannot be zero"}

            slopeRatio := runM / riseM
            slopePct := (riseM / runM) * 100.0
            slopeDeg := ATan(riseM / runM) * (180.0 / 3.141592653589793)

            return {
                success: true,
                category: "📐 Slope / Fall Analysis",
                displayExpr: Format("{1} {2} Fall over {3} {4} Run", riseVal, riseUnit.label, runVal, runUnit.label),
                resultStr: Format("Slope: 1 in {1:0.1f} (1:{1:0.1f}) | {2:0.2f}% | {3:0.3f}°", slopeRatio, slopePct, slopeDeg),
                val: slopePct,
                unit: "%"
            }
        }

        ; Case B: Ratio slope (e.g. "1:100 slope", "1 in 80", "1/50 gradient")
        if (RegExMatch(str, "i)(?:slope|gradient)?\s*1\s*(?::|in|\/)\s*([\d\.]+)(?:\s*(?:slope|gradient))?", &mRatio)) {
            ratioN := Float(mRatio[1])
            if (ratioN <= 0)
                return {success: false, message: "Invalid slope ratio"}

            runLength := cfg.Has("DefaultSlopeRunMeters") ? cfg["DefaultSlopeRunMeters"] : 10.0
            if (Trim(param) != "") {
                ; Fix [Concern 1]: Call CivilCrossPhysics (where ParseDimensionInput is defined, not CivilUnits)
                pRun := CivilCrossPhysics.ParseDimensionInput(param, "L")
                if (pRun > 0)
                    runLength := pRun
            }

            fallM := runLength / ratioN
            fallMM := fallM * 1000.0
            slopePct := (1.0 / ratioN) * 100.0
            slopeDeg := ATan(1.0 / ratioN) * (180.0 / 3.141592653589793)

            return {
                success: true,
                needsParam: (Trim(param) == ""),
                paramPrompt: Format("Enter Horizontal Run [Default: {:0.1f} m]", runLength),
                category: "📐 Slope Ratio -> Fall & Angle",
                displayExpr: Format("Slope 1:{1:0.0f} over {2:0.1f} m Run", ratioN, runLength),
                resultStr: Format("Fall: {1:0.1f} mm | Slope: {2:0.2f}% | Angle: {3:0.3f}°", fallMM, slopePct, slopeDeg),
                val: fallMM,
                unit: "mm fall"
            }
        }

        ; Case C: Percentage slope (e.g. "2% slope to degree" or "1.5 percent slope")
        if (RegExMatch(str, "i)([\d\.]+)\s*(?:%|percent|pct)(?:\s*(?:slope|gradient))?", &mPct)) {
            pct := Float(mPct[1])
            ratioN := (pct > 0) ? (100.0 / pct) : 0
            slopeDeg := ATan(pct / 100.0) * (180.0 / 3.141592653589793)
            fallOver10m := (pct / 100.0) * 10.0 * 1000.0

            return {
                success: true,
                category: "📐 Slope Percentage Conversion",
                displayExpr: Format("{:0.2f}% Slope", pct),
                resultStr: Format("Ratio: 1 in {:0.1f} | Angle: {:0.3f}° | Fall: {:0.0f} mm in 10m", ratioN, slopeDeg, fallOver10m),
                val: slopeDeg,
                unit: "°"
            }
        }

        return {success: false, message: "Could not parse slope expression"}
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. Angle / DMS / Radians Subsystem
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateAngleDms(str) {
        ; Case A: DMS to Decimal Degree (e.g. 45° 30' 15", 45-30-15, 45 30 15)
        if (RegExMatch(str, "i)^(\d+)(?:°|[\-\s])\s*(\d+)(?:\x27|[\-\s])\s*(\d+(?:\.\d+)?)(?:\x22|\s*)?", &mDMS)) {
            deg := Float(mDMS[1])
            minVal := Float(mDMS[2])
            sec := Float(mDMS[3])
            decDeg := deg + (minVal / 60.0) + (sec / 3600.0)
            rad := decDeg * (3.141592653589793 / 180.0)

            return {
                success: true,
                category: "🌐 Angle / Survey DMS -> Decimal",
                displayExpr: Format("{1}° {2}' {3} DMS", deg, minVal, sec),
                resultStr: Format("{:0.5f}° (Radians: {:0.6f} rad)", decDeg, rad),
                val: decDeg,
                unit: "°"
            }
        }

        ; Case B: Decimal Degree to DMS (e.g. 45.50417 deg to dms)
        if (RegExMatch(str, "i)^([\d\.]+)\s*(?:deg|degree|°)\s*(?:to|in|into|=|ko)?\s*dms", &mDec)) {
            decDeg := Float(mDec[1])
            deg := Floor(decDeg)
            remMin := (decDeg - deg) * 60.0
            minVal := Floor(remMin)
            sec := (remMin - minVal) * 60.0

            return {
                success: true,
                category: "🌐 Angle Decimal -> Survey DMS",
                displayExpr: Format("{:0.5f}° -> DMS", decDeg),
                resultStr: Format("{1}° {2}' {3:0.2f}`" (DMS)", deg, minVal, sec),
                val: decDeg,
                unit: "DMS"
            }
        }

        return {success: false, message: "Could not evaluate Angle/DMS expression"}
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 4. Concrete Grade Strength Evaluation (IS 456)
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateConcreteGrade(mGrade, cfg) {
        gradeNum := Integer(mGrade[1])
        fck := Float(gradeNum) ; IS 456 Characteristic 150mm Cube Strength in MPa / N/mm²
        targetKey := (mGrade.Count >= 2 && mGrade[2] != "") ? StrLower(Trim(mGrade[2])) : "psi"
        targetUnit := CivilUnits.ResolveUnit(targetKey)

        if (!targetUnit || targetUnit.dim != "P") {
            targetUnit := CivilUnits.ResolveUnit("psi")
        }

        strengthPa := fck * 1000000.0
        converted := strengthPa / targetUnit.factor

        return {
            success: true,
            category: "🧱 Concrete Grade Strength (IS 456)",
            displayExpr: Format("M{1} Concrete ({1} N/mm² / MPa) -> {2}", gradeNum, targetUnit.label),
            resultStr: Format("M{} Compressive Strength: {:0.2f} {}", gradeNum, converted, targetUnit.label),
            val: converted,
            unit: targetUnit.label
        }
    }
}
