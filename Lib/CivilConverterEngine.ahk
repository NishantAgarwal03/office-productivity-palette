; ======================================================================================================================
; Module: CivilConverterEngine.ahk - Unified Engineering Router & Normalization Facade
; Part of Office Productivity Hub (v2.0.0)
;
; ARCHITECTURAL PRINCIPLES:
; 1. Single Entry Point: Presentation layers call CivilConverterEngine.Evaluate() with zero concern for internal math.
; 2. Domain Decomposition: Logic is cleanly factored into 5 specialized domain engines:
;    - CivilUnits.ahk          : 120+ Physical Units & Cross-Dimensional Physics
;    - CivilPythagoras.ahk     : Pythagoras, 3-4-5 Guniya, Tircha & Bidirectional Inverse Solver
;    - CivilRebar.ahk          : IS 1786 Steel Unit Weights, Spacing Substitution & Stock Lengths
;    - CivilEstimator.ahk      : BOQ Rate Converter & Thumb-Rule Material Estimator
;    - CivilSurvey.ahk         : Slope (1:N), Gradient %, Fall, DMS Angles & Concrete Grades
; 3. Shared Primitives: Leverages NumberParser.ahk and ClipboardHelper.ahk across all tools.
; ======================================================================================================================

#Requires AutoHotkey v2.0

#Include "CivilUnits.ahk"
#Include "CivilCrossPhysics.ahk"
#Include "CivilPythagoras.ahk"
#Include "CivilRebar.ahk"
#Include "CivilEstimator.ahk"
#Include "CivilSurvey.ahk"

class CivilConverterEngine {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Configuration Loader & Defaults Manager
    ; ------------------------------------------------------------------------------------------------------------------
    static LoadConfig() {
        iniPath := A_ScriptDir . "\CivilEngineeringDefaults.ini"
        cfg := Map()

        ; Fallback base defaults
        cfg["Steel"] := 7850.0
        cfg["Concrete_RCC"] := 2400.0
        cfg["Concrete_PCC"] := 2300.0
        cfg["Cement_Bulk"] := 1440.0
        cfg["Sand_Dry"] := 1600.0
        cfg["Sand_River"] := 1750.0
        cfg["Aggregate_Coarse"] := 1500.0
        ; Fix [Concern 3]: Standardize fluid densities in kg/m³ to align with solid materials
        cfg["Water"] := 1000.0        ; kg/m³
        cfg["Diesel"] := 840.0        ; kg/m³
        cfg["Petrol"] := 740.0        ; kg/m³
        cfg["DefaultLoadedAreaSqMeters"] := 1.0
        cfg["DefaultSlopeRunMeters"] := 10.0
        cfg["RebarSpacingPitchRoundMM"] := 5.0
        cfg["ConstructionCostPerSqFt"] := 1800.0
        cfg["BasicCostPerSqFt"] := 1500.0
        cfg["StandardCostPerSqFt"] := 1800.0
        cfg["PremiumCostPerSqFt"] := 2400.0
        cfg["RegionalBighaSqMeters"] := 770.0
        cfg["RegionalNaliSqMeters"] := 38.5

        ; Estimator Defaults
        cfg["CivilWorkStructureCostPerSqFt"] := 751.25
        cfg["FinishingWorkCostPerSqFt"] := 467.50
        cfg["ElectricalCostPerSqFt"] := 133.00
        cfg["PlumbingCostPerSqFt"] := 126.00
        cfg["FireFightingCostPerSqFt"] := 40.00
        cfg["ExternalDevelopmentCostPerSqFt"] := 94.50
        cfg["ContractorOverheadProfitPercent"] := 10.0

        cfg["SteelPercent_Slab"] := 1.0
        cfg["SteelPercent_Beam"] := 2.0
        cfg["SteelPercent_Column"] := 2.5
        cfg["SteelPercent_Footing"] := 0.8
        cfg["SteelDensityKgM3"] := 7850.0
        cfg["SteelMarketRatePerKg"] := 65.0

        cfg["ConcreteVolPerSqFtCum"] := 0.038
        cfg["FootingConcreteRatio"] := 0.15
        cfg["ColumnConcreteRatio"] := 0.15
        cfg["BeamConcreteRatio"] := 0.30
        cfg["SlabConcreteRatio"] := 0.40
        cfg["CementBagsPerCum_RCC"] := 8.0
        cfg["CementBagsPerCum_Brickwork"] := 1.26
        cfg["CementBagsPerSqM_Plaster"] := 0.11
        cfg["CementBagsPerSqM_Flooring"] := 0.25
        cfg["CementBagMarketRate"] := 380.0

        cfg["ShutteringAreaPerPlinthRatio"] := 2.4
        cfg["ShutteringPlySheetMultiplier"] := 0.22
        cfg["ShutteringBattenPerPlyMultiplier"] := 19.82
        cfg["ShutteringNailsGramsPerSqM"] := 75.0
        cfg["ShutteringBindingWireGramsPerSqM"] := 75.0
        cfg["ShutteringOilLitersPerSqM"] := 0.065
        cfg["ShutteringRatePerSqFt"] := 60.0

        cfg["BricksPerSqFt"] := 18.0
        cfg["AACBlocksPerSqFt"] := 1.20
        cfg["BrickMarketRate"] := 9.0
        cfg["SandCftPerSqFt"] := 1.80
        cfg["SandRatePerCft"] := 55.0
        cfg["AggregateCftPerSqFt"] := 1.35
        cfg["AggregateRatePerCft"] := 45.0

        cfg["PVCConduitMetersPerSqM"] := 1.0
        cfg["ElectricalWireMetersPerSqM"] := 10.0
        cfg["InternalWallPaintingAreaMultiplier"] := 3.0
        cfg["WallPuttyKgPerSqFtWall"] := 0.055
        cfg["WallPrimerLitersPerSqFtWall"] := 0.004
        cfg["EmulsionPaintLitersPerSqFtWall"] := 0.007
        cfg["FlooringTileAreaMultiplier"] := 1.25
        cfg["FlooringRatePerSqFt"] := 65.0
        cfg["MaxAllowedVariancePercent"] := 5.0

        if (FileExist(iniPath)) {
            try {
                sectionNames := IniRead(iniPath)
                Loop Parse, sectionNames, "`n", "`r" {
                    sec := Trim(A_LoopField)
                    if (sec == "")
                        continue
                    sectionContent := IniRead(iniPath, sec)
                    Loop Parse, sectionContent, "`n", "`r" {
                        line := Trim(A_LoopField)
                        if (line == "" || SubStr(line, 1, 1) == ";")
                            continue
                        eqPos := InStr(line, "=")
                        if (eqPos > 1) {
                            k := Trim(SubStr(line, 1, eqPos - 1))
                            v := Trim(SubStr(line, eqPos + 1))
                            if (v != "") {
                                cfg[k] := IsNumber(v) ? Float(v) : v
                            }
                        }
                    }
                }
            }
        }
        return cfg
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Backward-Compatible Delegator Facades
    ; ------------------------------------------------------------------------------------------------------------------
    static IsPythagorasRequest(str) => CivilPythagoras.IsPythagorasRequest(str)
    static IsRebarRequest(str) => CivilRebar.IsRebarRequest(str)
    static IsSlopeRequest(str) => CivilSurvey.IsSlopeRequest(str)
    static IsAngleDmsRequest(str) => CivilSurvey.IsAngleDmsRequest(str)
    static ResolveUnit(unitStr) => CivilUnits.ResolveUnit(unitStr)

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. Main Unified Evaluation & Routing Pipeline
    ; ------------------------------------------------------------------------------------------------------------------
    static Evaluate(rawText, secondaryParam := "") {
        cfg := this.LoadConfig()
        cleaned := Trim(rawText)
        if (cleaned == "")
            return {success: false, message: "Empty input text"}

        ; Normalize input (Hinglish terms, arrows, symbols)
        normalized := this.NormalizeInput(cleaned)

        ; (A) Pythagoras & Diagonal Calculation (40+ variants, Guniya, Tircha & Inverse solving)
        if (CivilPythagoras.IsPythagorasRequest(normalized)) {
            return CivilPythagoras.Evaluate(normalized)
        }

        ; (B) Construction Rate Converter (e.g. Rs 500 per sqft to sqm, 4500 per cum to cft, 65 per kg steel to cum)
        if (CivilEstimator.IsRateRequest(normalized)) {
            return CivilEstimator.EvaluateRateConversion(normalized, secondaryParam, cfg)
        }

        ; (C) Thumb Rule Cost & Material Estimator (e.g. cost 1500 sqft house)
        if (CivilEstimator.IsThumbRuleRequest(normalized)) {
            return CivilEstimator.EvaluateThumbRuleCost(normalized, cfg)
        }

        ; (D) Concrete Grade Designations (e.g. M25 to psi, M30 in N/mm2)
        if (CivilSurvey.IsConcreteGradeRequest(normalized, &mGrade)) {
            return CivilSurvey.EvaluateConcreteGrade(mGrade, cfg)
        }

        ; (E) Rebar Calculations & Spacing Replacements (e.g. 10mm @ 150 to 12mm, 100m 16mm weight)
        if (CivilRebar.IsRebarRequest(normalized)) {
            return CivilRebar.Evaluate(normalized, secondaryParam, cfg)
        }

        ; (F) Slope & Gradient (e.g. 1:100 slope, fall 100mm in 10m, 2% slope to degree)
        if (CivilSurvey.IsSlopeRequest(normalized)) {
            return CivilSurvey.EvaluateSlope(normalized, secondaryParam, cfg)
        }

        ; (G) Angle DMS Conversion (e.g. 45° 30' 15" to decimal, 45.5 deg to DMS)
        if (CivilSurvey.IsAngleDmsRequest(normalized)) {
            return CivilSurvey.EvaluateAngleDms(normalized)
        }

        ; (H) Physical Transformation Engine (Direct vs Conditional Cross-Dimensional vs Incompatible)
        return CivilCrossPhysics.EvaluatePhysicalTransformation(normalized, secondaryParam, cfg)
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 4. Input Normalization & Cleaning Primitive
    ; ------------------------------------------------------------------------------------------------------------------
    static NormalizeInput(str) {
        s := StrLower(Trim(str))

        ; Convert Hindi / Hinglish terms to canonical units
        s := StrReplace(s, "मीटर", "m")
        s := StrReplace(s, "लीटर", "litre")
        s := StrReplace(s, "किलो", "kg")
        s := StrReplace(s, "टन", "tonne")
        s := StrReplace(s, "क्विंटल", "quintal")
        s := StrReplace(s, "गज", "gaj")
        s := StrReplace(s, "गुंठा", "guntha")
        s := StrReplace(s, "बीघा", "bigha")
        s := StrReplace(s, "नाली", "nali")
        s := StrReplace(s, "कट्ठा", "katha")
        s := StrReplace(s, "पानी", "water")
        s := StrReplace(s, "सरिया", "rebar")
        s := StrReplace(s, "तिरछा", "tircha")
        s := StrReplace(s, "तिरछी", "tirchi")
        s := StrReplace(s, "गुनिया", "guniya")
        s := StrReplace(s, "कर्ण", "karna")

        ; Clean punctuation and mathematical arrows
        s := StrReplace(s, "->", " to ")
        s := StrReplace(s, "=>", " to ")
        s := StrReplace(s, "→", " to ")
        s := StrReplace(s, " into ", " to ")
        s := RegExReplace(s, "i)\b([a-z0-9²³\x27\x22°\-\/_]+)\s+in\s+(?!to\b)([a-z0-9²³\x27\x22°\-\/_]+)\b", "$1 to $2")
        s := StrReplace(s, " ko ", " to ")
        s := StrReplace(s, " me ", " to ")
        s := StrReplace(s, " mein ", " to ")
        s := StrReplace(s, " convert ", " ")
        s := StrReplace(s, " calculate ", " ")
        s := StrReplace(s, " kitna ", " ")
        s := StrReplace(s, " batao ", " ")
        s := StrReplace(s, " nikalo ", " ")

        ; Normalize multiple spaces
        s := RegExReplace(s, "\s+", " ")
        return Trim(s)
    }
}
