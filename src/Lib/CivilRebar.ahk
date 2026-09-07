; ======================================================================================================================
; Module: CivilRebar.ahk - Structural Steel, Rebar Unit Weights (IS 1786) & Equal-As Spacing Substitution
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

class CivilRebar {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Request Detection Pattern
    ; ------------------------------------------------------------------------------------------------------------------
    static IsRebarRequest(str) {
        ; Exclude pressure unit 'bar'
        if (RegExMatch(str, "i)^\s*[\d\.]+\s*bar\s*(?:to|in|into|ko|=|se)\b"))
            return false
        if (RegExMatch(str, "i)^\s*[\d\.]+\s*(?:deg|degree|pa|kpa|mpa|psi|n\/mm2|kn\/m2|bar)\s*(?:to|in|into|ko|=|se)\s*bar\b"))
            return false
        return RegExMatch(str, "i)(?:@|c\/c|c-c|spacing|\brebar\b|\btmt\b|\bsariya\b|\bsteel\b|\brod\b|\b\d+\s*dia\b|\b\d+\s*mm\s*bar\b|\bbar\s*(?:weight|kg|length|meter|dia|size)\b)")
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Evaluation Engine
    ; ------------------------------------------------------------------------------------------------------------------
    static Evaluate(str, param := "", cfg := "") {
        if (!IsObject(cfg)) {
            cfg := (IsSet(CivilConverterEngine) && HasMethod(CivilConverterEngine, "LoadConfig")) ? CivilConverterEngine.LoadConfig() : Map("RebarSpacingPitchRoundMM", 5.0)
        }
        ; 1. Rebar Spacing Substitution: "10mm @ 150 to 12mm", "10 dia @ 200 replace with 12 dia"
        if (RegExMatch(str, "i)(?:change|replace)?\s*(\d+)\s*(?:mm|dia|Ø)?\s*@\s*(\d+)(?:\s*(?:c\/c|c-c|spacing|mm))?\s*(?:to|by|replace\s*with|se)?\s*(\d+)?(?:\s*(?:mm|dia|Ø))?", &mSub)) {
            d1 := Float(mSub[1])
            s1 := Float(mSub[2])
            d2 := (mSub.Count >= 3 && mSub[3] != "") ? Float(mSub[3]) : 0.0

            if (d2 = 0 && Trim(param) != "") {
                d2 := Float(RegExReplace(param, "[^\d\.]", ""))
            }
            if (d2 = 0) {
                d2 := (d1 == 10) ? 12 : ((d1 == 8) ? 10 : 16)
            }

            s2Exact := s1 * ((d2 * d2) / (d1 * d1))
            pitchRound := cfg.Has("RebarSpacingPitchRoundMM") ? cfg["RebarSpacingPitchRoundMM"] : 5.0
            s2Practical := Floor(s2Exact / pitchRound) * pitchRound

            as1 := (3.14159265 * d1 * d1 / 4.0) * (1000.0 / s1)
            as2 := (3.14159265 * d2 * d2 / 4.0) * (1000.0 / s2Practical)

            return {
                success: true,
                needsParam: (mSub.Count < 3 || mSub[3] == ""),
                paramPrompt: Format("Enter Replacement Diameter [Default: {} mm]", d2),
                category: "Reinforcement Substitution (Equal As)",
                displayExpr: Format("{1}mm @ {2} c/c -> {3}mm @ ? c/c", d1, s1, d2),
                resultStr: Format("{1}mm @ {2:0.0f} mm c/c (Exact: {3:0.1f} mm, As = {4:0.0f} mm²/m)", d2, s2Practical, s2Exact, as2),
                val: s2Practical,
                unit: "mm c/c"
            }
        }

        ; 2. Straight Bar Unit Weight: "12mm bar weight", "16 dia bar kg/m"
        if (RegExMatch(str, "i)^(\d+)\s*(?:mm|dia|Ø)\s*(?:bar|steel|rebar|tmt)?(?:\s*(?:weight|kg\/m|unit\s*weight))?$", &mBarUnit)) {
            d := Float(mBarUnit[1])
            unitWeightKgM := (d * d) / 162.28
            return {
                success: true,
                category: "Rebar Unit Weight (IS 1786)",
                displayExpr: Format("{1} mm TMT Bar Unit Weight", d),
                resultStr: Format("{1} mm Dia Rebar: {:0.3f} kg/m ({:0.3f} kg/12m bar)", d, unitWeightKgM, unitWeightKgM * 12.0),
                val: unitWeightKgM,
                unit: "kg/m"
            }
        }

        ; 3. Total Weight from Length: "100m 16mm steel", "50 m of 12mm rebar"
        if (RegExMatch(str, "i)^([\d\.]+)\s*(?:m|meter|mtr|rmt)\s*(?:of\s*)?(\d+)\s*(?:mm|dia|Ø)", &mLenToWt)) {
            lenVal := Float(mLenToWt[1])
            d := Float(mLenToWt[2])
            totKg := lenVal * ((d * d) / 162.28)
            return {
                success: true,
                category: "Rebar Total Weight from Length",
                displayExpr: Format("{1}m length of {2}mm Bar", lenVal, d),
                resultStr: Format("Total Weight: {:0.2f} kg ({:0.3f} MT)", totKg, totKg / 1000.0),
                val: totKg,
                unit: "kg"
            }
        }

        ; 4. Total Length / Pieces from Weight: "500 kg 12mm bar" or "2 ton 16mm steel"
        if (RegExMatch(str, "i)^([\d\.]+)\s*(kg|tonne|ton|mt|quintal|qtl)\s*(?:of\s*)?(\d+)\s*(?:mm|dia|Ø)", &mWtToLen)) {
            wtVal := Float(mWtToLen[1])
            wtUnit := CivilUnits.ResolveUnit(StrLower(mWtToLen[2]))
            d := Float(mWtToLen[3])

            if (wtUnit && wtUnit.dim == "M") {
                totKg := wtVal * wtUnit.factor
                unitKgM := (d * d) / 162.28
                totLenM := totKg / unitKgM
                bars12m := totLenM / 12.0

                return {
                    success: true,
                    category: "Rebar Length & Count from Weight",
                    displayExpr: Format("{1} {2} of {3}mm Rebar", wtVal, wtUnit.label, d),
                    resultStr: Format("Total Length: {:0.2f} m | ~{:0.1f} Stock Bars (12m each)", totLenM, bars12m),
                    val: totLenM,
                    unit: "m"
                }
            }
        }

        ; 5. Compound Length -> Weight (alternate order): "16mm bar 100m"
        if (RegExMatch(str, "i)^(\d+)\s*(?:mm|dia|Ø)\s*(?:bar|steel|rebar|tmt)?\s*([\d\.]+)\s*(?:m|meter|mtr|rmt)$", &mAltLen)) {
            d := Float(mAltLen[1])
            lenVal := Float(mAltLen[2])
            totKg := lenVal * ((d * d) / 162.28)
            return {
                success: true,
                category: "Rebar Total Weight",
                displayExpr: Format("{1}mm Bar * {2}m", d, lenVal),
                resultStr: Format("Total Weight: {:0.2f} kg ({:0.3f} MT)", totKg, totKg / 1000.0),
                val: totKg,
                unit: "kg"
            }
        }

        return {success: false, message: "Could not evaluate rebar expression"}
    }
}
