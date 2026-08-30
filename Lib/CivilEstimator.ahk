; ======================================================================================================================
; Module: CivilEstimator.ahk - 3-Tier Verified Construction Cost & Material Quantity Estimator
; Part of Office Productivity Hub (v2.0.0)
;
; ARCHITECTURAL 3-TIER RECONCILIATION WORKFLOW:
; 1. Tier 1 (Micro Bottom-Up): Empirical Member-Wise Material & Labor Schedule (C1)
;    - Concrete m³, Steel by member (Slab 1%, Beam 2%, Col 2.5%, Footing 0.8%)
;    - Shuttering Ply Sheets (0.22x), Battens (19.82x), Nails/Wire (75g/m²), Oil (0.065 L/m²)
;    - Cement by activity (RCC, Masonry, Plaster, Flooring), Bricks, Sand, Aggregate
;    - Conduit (1.0 m/m²), Wire (10.0 m/m²), Painting & Putty (3x Carpet Area)
; 2. Tier 2 (Meso Trade-Packages): Package Unit Rates Model (C2)
;    - Civil Structure (₹751.25), Finishing (₹467.50), Electrical (₹133), Plumbing (₹126),
;      Fire Fighting (₹40), External Dev (₹94.50) + COP (10%)
; 3. Tier 3 (Macro Tier Benchmark): Standard Per-Sq-Ft Quality Tier (C3)
;    - Basic (₹1,500), Standard (₹1,800), Premium (₹2,400)
; 4. Multi-Tier Convergence Check: Verified if Max(|Cᵢ - μ| / μ) <= 5.0%
; ======================================================================================================================

#Requires AutoHotkey v2.0

; ======================================================================================================================
; DESIGN DECISION [THUMB RULE COST & MATERIAL ESTIMATOR - 2026 INDIAN PRICING & INI OVERRIDES]:
; 1. Regional Calibration: Rates and material thumb rules are calibrated specifically for Indian residential 
;    and commercial construction (2026 benchmark pricing: Basic ₹1,500/sqft, Standard ₹1,800/sqft, Premium ₹2,400/sqft).
; 2. User Customization: All unit rates, material percentages, and densities can be customized without touching code
;    via the external configuration file `CivilEngineeringDefaults.ini`.
; ======================================================================================================================
class CivilEstimator {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Request Detection Patterns
    ; ------------------------------------------------------------------------------------------------------------------
    static IsRateRequest(str) {
        if (RegExMatch(str, "i)\b(?:m3\/hr|m³\/hr|cum\/hr|m3\/s|m3\/min|cum\/min|cum\/s|cum\/sec|kg\/m3|kg\/m³|kg\/cum|g\/cc|gm\/cc|g\/cm3|n\/mm2|n\/mm²|kn\/m2|kn\/m²|kgf\/cm2|kgf\/cm²|kg\/cm2|kg\/cm²|lb\/cft|lb\/ft3|lb\/ft³|pcf)\b"))
            return false
        return RegExMatch(str, "i)(?:rs\.?|₹|\$|inr|rate|price|cost)?\s*[\d\.]+\s*(?:lakh|crore|cr|k|lac)?\s*(?:per|\/)\s*[a-z0-9²³\s]+\s*(?:to|in|into|ko|=|se)\s*(?:per|\/)?\s*[a-z0-9²³\s]+")
    }

    static IsThumbRuleRequest(str) {
        return RegExMatch(str, "i)\b(?:thumb\s*rule|cost\s*estimate|construction\s*cost|house\s*cost|material\s*estimate|estimate\s*\d+|cost\s*\d+)\b")
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; Unified Evaluator Entry Point (Contract Uniformity)
    ; ------------------------------------------------------------------------------------------------------------------
    static Evaluate(str, cfg := "") {
        if (!IsObject(cfg)) {
            cfg := (IsSet(CivilConverterEngine) && HasMethod(CivilConverterEngine, "LoadConfig")) ? CivilConverterEngine.LoadConfig() : Map("Steel", 7850.0, "Sand_Dry", 1600.0, "Aggregate_Coarse", 1500.0, "Concrete_RCC", 2400.0, "Concrete_PCC", 2300.0, "Cement_Bulk", 1440.0, "Diesel", 840.0, "Petrol", 740.0, "Water", 1000.0, "BasicCostPerSqFt", 1500.0, "StandardCostPerSqFt", 1800.0, "PremiumCostPerSqFt", 2400.0)
        }
        if (CivilEstimator.IsThumbRuleRequest(str))
            return CivilEstimator.EvaluateThumbRuleCost(str, cfg)
        if (CivilEstimator.IsRateRequest(str))
            return CivilEstimator.EvaluateRateConversion(str, "", cfg)
        return {success: false, message: "Unrecognized estimator or rate query"}
    }


    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Enhanced Construction Rate & Unit Price Converter (Categories C, D, E & 1-Param Progressive Bridges)
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateRateConversion(str, secondaryParam := "", cfg := "") {
        if (!IsObject(cfg))
            cfg := Map("Steel", 7850.0, "Sand_Dry", 1600.0, "Aggregate_Coarse", 1500.0, "Concrete_RCC", 2400.0, "Concrete_PCC", 2300.0, "Cement_Bulk", 1440.0, "Diesel", 840.0, "Petrol", 740.0, "Water", 1000.0)

        ; Pattern: [₹] [50] [lakh] per [bigha / kg steel / cement bag] to [/] [sqft / cum / quintal]
        if (!RegExMatch(str, "i)(?:rs\.?|₹)?\s*([\d\.]+)\s*(lakh|crore|cr|k|m|lac)?\s*(?:per|\/)\s*([a-z0-9²³\s]+?)\s*\b(?:to|in|into|ko|=|se)\b\s*(?:per|\/)?\s*([a-z0-9²³\s]+)", &mRate)) {
            return {success: false, message: "Could not parse rate expression: '" . str . "'"}
        }

        rawNum := Float(mRate[1])
        multiplierStr := StrLower(Trim(mRate[2]))
        multiplier := 1.0
        if (multiplierStr == "lakh" || multiplierStr == "lac")
            multiplier := 100000.0
        else if (multiplierStr == "crore" || multiplierStr == "cr")
            multiplier := 10000000.0
        else if (multiplierStr == "k")
            multiplier := 1000.0
        else if (multiplierStr == "m")
            multiplier := 1000000.0

        rateVal := rawNum * multiplier

        ; Extract Material Keyword (Steel, Sand, Aggregate, Concrete, Diesel, Petrol, Water, Cement)
        srcRaw := StrLower(Trim(mRate[3]))
        tgtRaw := StrLower(Trim(mRate[4]))
        tgtClean := Trim(RegExReplace(tgtRaw, "i)^(?:per|\/)\s*", ""))

        material := ""
        combinedText := srcRaw . " " . tgtClean
        if (InStr(combinedText, "steel") || InStr(combinedText, "rebar") || InStr(combinedText, "tmt") || InStr(combinedText, "sariya"))
            material := "steel"
        else if (InStr(combinedText, "sand") || InStr(combinedText, "ret") || InStr(combinedText, "balu"))
            material := "sand"
        else if (InStr(combinedText, "aggregate") || InStr(combinedText, "gravel") || InStr(combinedText, "kadi") || InStr(combinedText, "rodi") || InStr(combinedText, "gitti"))
            material := "aggregate"
        else if (InStr(combinedText, "diesel"))
            material := "diesel"
        else if (InStr(combinedText, "petrol") || InStr(combinedText, "gasoline"))
            material := "petrol"
        else if (InStr(combinedText, "water") || InStr(combinedText, "pani"))
            material := "water"
        else if (InStr(combinedText, "cement") && !InStr(combinedText, "bag"))
            material := "cement"
        else if (InStr(combinedText, "rcc") || InStr(combinedText, "concrete"))
            material := "rcc"

        ; Clean source unit key
        srcClean := srcRaw
        if (material != "")
            srcClean := Trim(RegExReplace(srcClean, "i)\b" . material . "\b", ""))
        if (srcClean == "")
            srcClean := "kg"

        ; Clean target unit key
        if (material != "")
            tgtClean := Trim(RegExReplace(tgtClean, "i)\b" . material . "\b", ""))

        srcUnit := CivilUnits.ResolveUnit(srcClean)
        targetUnit := CivilUnits.ResolveUnit(tgtClean)

        if (!srcUnit || !targetUnit) {
            return {success: false, message: "Unknown unit in rate conversion: '" . srcClean . "' -> '" . tgtClean . "'"}
        }

        ; Format Helpers
        FmtRate(n) {
            if (n >= 1000)
                return IsSet(FormatIndianCommas) ? FormatIndianCommas(Round(n, 2), true) : Format("{:0.2f}", n)
            else
                return Format("{:0.2f}", n)
        }

        displaySrc := (multiplierStr != "") ? Format("{1:0.2f} {2}", rawNum, multiplierStr) : Format("{1:0.2f}", rawNum)

        ; --------------------------------------------------------------------------------------------------------------
        ; CASE 1: DIRECT SAME-DIMENSION RATE CONVERSION (Inverse Factor Relationship, 0 Params)
        ; --------------------------------------------------------------------------------------------------------------
        if (srcUnit.dim == targetUnit.dim) {
            convertedRate := rateVal * (targetUnit.factor / srcUnit.factor)
            dimNames := Map("L","Length", "L2","Area", "L3","Volume", "M","Mass/Weight", "F","Force", "P","Pressure", "D","Density", "Q","Flow", "A","Angle")
            catName := dimNames.Has(srcUnit.dim) ? ("💰 Construction Rate (" . dimNames[srcUnit.dim] . ")") : "💰 Construction Rate Conversion"

            return {
                success: true,
                category: catName,
                displayExpr: Format("₹ {1} / {2} -> ₹ ? / {3}", displaySrc, srcUnit.label, targetUnit.label),
                resultStr: Format("₹ {1} / {2}", FmtRate(convertedRate), targetUnit.label),
                val: convertedRate,
                unit: "₹ / " . targetUnit.label
            }
        }

        ; --------------------------------------------------------------------------------------------------------------
        ; CASE 2: DENSITY-AWARE MASS <-> VOLUME RATE CONVERSION (0 Params if Material Known)
        ; --------------------------------------------------------------------------------------------------------------
        if ((srcUnit.dim == "M" && targetUnit.dim == "L3") || (srcUnit.dim == "L3" && targetUnit.dim == "M")) {
            dObj := CivilCrossPhysics.ResolveMaterialDensity((material != "" ? material : "Concrete_RCC"), cfg)
            densityKgM3 := dObj.density
            matName := dObj.name

            convertedRate := 0.0

            ; Subcase 2A: Mass Rate -> Volume Rate (e.g. ₹65/kg steel -> ₹/cum or ₹/cft)
            if (srcUnit.dim == "M" && targetUnit.dim == "L3") {
                ratePerKg := rateVal / srcUnit.factor
                ratePerCum := ratePerKg * densityKgM3
                convertedRate := ratePerCum * targetUnit.factor
            }
            ; Subcase 2B: Volume Rate -> Mass Rate (e.g. ₹55/cft sand -> ₹/tonne)
            else if (srcUnit.dim == "L3" && targetUnit.dim == "M") {
                ratePerCum := rateVal / srcUnit.factor
                ratePerKg := (densityKgM3 > 0) ? (ratePerCum / densityKgM3) : 0.0
                convertedRate := ratePerKg * targetUnit.factor
            }

            return {
                success: true,
                category: Format("🏗️ Material Density Rate Conversion ({1})", matName),
                displayExpr: Format("₹ {1} / {2} ({3}) -> ₹ ? / {4}", displaySrc, srcUnit.label, matName, targetUnit.label),
                resultStr: Format("₹ {1} / {2} [{3}]", FmtRate(convertedRate), targetUnit.label, matName),
                val: convertedRate,
                unit: "₹ / " . targetUnit.label,
                density: densityKgM3
            }
        }

        ; --------------------------------------------------------------------------------------------------------------
        ; CASE 3: PROGRESSIVE 1-PARAMETER RATE CONVERSIONS
        ; --------------------------------------------------------------------------------------------------------------
        ; (A) Volume Rate <-> Area Rate (Requires Thickness / Depth 't')
        if ((srcUnit.dim == "L3" && targetUnit.dim == "L2") || (srcUnit.dim == "L2" && targetUnit.dim == "L3")) {
            if (secondaryParam == "") {
                return {
                    success: true,
                    needsParam: true,
                    paramPrompt: "Enter Slab / Layer Thickness (e.g., 125mm, 6 in):",
                    defaultApplied: "1.0 m",
                    rawQuery: str
                }
            }

            thicknessM := (secondaryParam == "DEFAULT") ? 1.0 : CivilCrossPhysics.ParseDimensionInput(secondaryParam, "L")
            if (thicknessM <= 0)
                thicknessM := 1.0

            convertedRate := 0.0
            if (srcUnit.dim == "L3" && targetUnit.dim == "L2") {
                ; Volume Rate (₹/m³) -> Area Rate (₹/m²)
                ratePerCum := rateVal / srcUnit.factor
                ratePerSqm := ratePerCum * thicknessM
                convertedRate := ratePerSqm * targetUnit.factor
            } else {
                ; Area Rate (₹/m²) -> Volume Rate (₹/m³)
                ratePerSqm := rateVal / srcUnit.factor
                ratePerCum := (thicknessM > 0) ? (ratePerSqm / thicknessM) : ratePerSqm
                convertedRate := ratePerCum * targetUnit.factor
            }

            return {
                success: true,
                category: "📐 Volume ↔ Area Rate Conversion",
                displayExpr: Format("₹ {1} / {2} (@ {3:0.3f}m thick) -> ₹ ? / {4}", displaySrc, srcUnit.label, thicknessM, targetUnit.label),
                resultStr: Format("₹ {1} / {2} [Thick: {3:0.3f}m]", FmtRate(convertedRate), targetUnit.label, thicknessM),
                val: convertedRate,
                unit: "₹ / " . targetUnit.label
            }
        }

        ; (B) Linear Rate <-> Area Rate (Requires Width / Span 'w')
        if ((srcUnit.dim == "L" && targetUnit.dim == "L2") || (srcUnit.dim == "L2" && targetUnit.dim == "L")) {
            if (secondaryParam == "") {
                return {
                    success: true,
                    needsParam: true,
                    paramPrompt: "Enter Strip / Element Width (e.g., 300mm, 1 ft):",
                    defaultApplied: "1.0 m",
                    rawQuery: str
                }
            }

            widthM := (secondaryParam == "DEFAULT") ? 1.0 : CivilCrossPhysics.ParseDimensionInput(secondaryParam, "L")
            if (widthM <= 0)
                widthM := 1.0

            convertedRate := 0.0
            if (srcUnit.dim == "L" && targetUnit.dim == "L2") {
                ; Linear Rate (₹/m) -> Area Rate (₹/m²)
                ratePerRmt := rateVal / srcUnit.factor
                ratePerSqm := (widthM > 0) ? (ratePerRmt / widthM) : ratePerRmt
                convertedRate := ratePerSqm * targetUnit.factor
            } else {
                ; Area Rate (₹/m²) -> Linear Rate (₹/m)
                ratePerSqm := rateVal / srcUnit.factor
                ratePerRmt := ratePerSqm * widthM
                convertedRate := ratePerRmt * targetUnit.factor
            }

            return {
                success: true,
                category: "📐 Linear ↔ Area Rate Conversion",
                displayExpr: Format("₹ {1} / {2} (@ {3:0.3f}m width) -> ₹ ? / {4}", displaySrc, srcUnit.label, widthM, targetUnit.label),
                resultStr: Format("₹ {1} / {2} [Width: {3:0.3f}m]", FmtRate(convertedRate), targetUnit.label, widthM),
                val: convertedRate,
                unit: "₹ / " . targetUnit.label
            }
        }

        ; (C) Area Rate <-> Weight Rate WITH MATERIAL (Density known, Requires Thickness 't')
        if (((srcUnit.dim == "L2" && targetUnit.dim == "M") || (srcUnit.dim == "M" && targetUnit.dim == "L2")) && material != "") {
            dObj := CivilCrossPhysics.ResolveMaterialDensity(material, cfg)
            densityKgM3 := dObj.density
            matName := dObj.name

            if (secondaryParam == "") {
                return {
                    success: true,
                    needsParam: true,
                    paramPrompt: Format("Enter {1} Thickness (e.g., 10mm, 125mm):", matName),
                    defaultApplied: "1.0 m",
                    rawQuery: str
                }
            }

            thicknessM := (secondaryParam == "DEFAULT") ? 1.0 : CivilCrossPhysics.ParseDimensionInput(secondaryParam, "L")
            if (thicknessM <= 0)
                thicknessM := 1.0

            massPerSqmKg := thicknessM * densityKgM3
            convertedRate := 0.0

            if (srcUnit.dim == "M" && targetUnit.dim == "L2") {
                ; Weight Rate (₹/kg) -> Area Rate (₹/m²)
                ratePerKg := rateVal / srcUnit.factor
                ratePerSqm := ratePerKg * massPerSqmKg
                convertedRate := ratePerSqm * targetUnit.factor
            } else {
                ; Area Rate (₹/m²) -> Weight Rate (₹/kg)
                ratePerSqm := rateVal / srcUnit.factor
                ratePerKg := (massPerSqmKg > 0) ? (ratePerSqm / massPerSqmKg) : ratePerSqm
                convertedRate := ratePerKg * targetUnit.factor
            }

            return {
                success: true,
                category: Format("🏗️ {1} Area ↔ Weight Rate", matName),
                displayExpr: Format("₹ {1} / {2} ({3} @ {4:0.3f}m) -> ₹ ? / {5}", displaySrc, srcUnit.label, matName, thicknessM, targetUnit.label),
                resultStr: Format("₹ {1} / {2} [{3}, {4:0.3f}m]", FmtRate(convertedRate), targetUnit.label, matName, thicknessM),
                val: convertedRate,
                unit: "₹ / " . targetUnit.label
            }
        }

        ; --------------------------------------------------------------------------------------------------------------
        ; CASE 4: 2-PARAMETER MISMATCH REJECTION OR DIMENSIONAL INFEASIBILITY
        ; --------------------------------------------------------------------------------------------------------------
        dimNames := Map("L","linear rates", "L2","area rates", "L3","volume rates", "M","weight rates", "F","force rates", "P","pressure rates", "D","density rates", "Q","flow rates", "A","angle rates")
        srcDimName := dimNames.Has(srcUnit.dim) ? dimNames[srcUnit.dim] : "rates"
        tgtDimName := dimNames.Has(targetUnit.dim) ? dimNames[targetUnit.dim] : "rates"

        reason := ""
        if ((srcUnit.dim == "L2" && targetUnit.dim == "M") || (srcUnit.dim == "M" && targetUnit.dim == "L2")) {
            reason := Format("Rate Conversion Mismatch: {1} (₹/{2}) cannot directly convert to {3} (₹/{4}); unless 2 additional parameters (element thickness & material density) are known.", srcDimName, srcUnit.label, tgtDimName, targetUnit.label)
        } else {
            reason := Format("Rate Conversion Mismatch: {1} (₹/{2}) cannot directly convert to {3} (₹/{4}); unless governing geometric or physical parameters are known.", srcDimName, srcUnit.label, tgtDimName, targetUnit.label)
        }

        return {
            success: false,
            isIncompatible: true,
            category: "⚠️ Rate Conversion Mismatch",
            srcDimension: srcDimName,
            targetDimension: tgtDimName,
            message: reason
        }
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. 3-Tier Verified Construction Cost & Material Quantity Estimator
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateThumbRuleCost(str, cfg) {
        areaVal := 0.0
        unitStr := "sqft"

        ; Extract built-up area and unit
        if (RegExMatch(str, "i)([\d\.]+)\s*([a-z0-9²³]+)?", &mArea)) {
            areaVal := Float(mArea[1])
            if (mArea.Count >= 2 && mArea[2] != "") {
                unitStr := StrLower(Trim(mArea[2]))
            }
        }

        if (areaVal <= 0) {
            return {success: false, message: "Please specify built-up area (e.g. 'cost 1500 sqft house' or 'thumb rule cost 1200 sqft')"}
        }

        ; Detect Quality Tier (Basic, Standard, Premium)
        tierName := "Standard"
        tierRate := cfg.Has("StandardCostPerSqFt") ? cfg["StandardCostPerSqFt"] : 1800.0
        if (InStr(str, "basic") || InStr(str, "economy") || InStr(str, "budget")) {
            tierName := "Basic (C-Class)"
            tierRate := cfg.Has("BasicCostPerSqFt") ? cfg["BasicCostPerSqFt"] : 1500.0
        } else if (InStr(str, "premium") || InStr(str, "luxury") || InStr(str, "elite")) {
            tierName := "Premium (A-Class)"
            tierRate := cfg.Has("PremiumCostPerSqFt") ? cfg["PremiumCostPerSqFt"] : 2400.0
        }

        ; Convert area to sq ft and sq meters
        areaSqFt := areaVal
        u := CivilUnits.ResolveUnit(unitStr)
        if (u && u.dim == "L2") {
            areaSqFt := (areaVal * u.factor) / 0.09290304
        }
        areaSqM := areaSqFt * 0.09290304

        ; ==============================================================================================================
        ; TIER 1: Micro Bottom-Up Material Quantities & Direct Component Labor Schedule (C1)
        ; ==============================================================================================================
        ; 1. Structural Concrete Volume (m³)
        concVolPerSqFt := cfg.Has("ConcreteVolPerSqFtCum") ? cfg["ConcreteVolPerSqFtCum"] : 0.038
        totalConcCum := areaSqFt * concVolPerSqFt
        concCFT := totalConcCum / 0.028316846592

        footingConc := totalConcCum * (cfg.Has("FootingConcreteRatio") ? cfg["FootingConcreteRatio"] : 0.15)
        colConc := totalConcCum * (cfg.Has("ColumnConcreteRatio") ? cfg["ColumnConcreteRatio"] : 0.15)
        beamConc := totalConcCum * (cfg.Has("BeamConcreteRatio") ? cfg["BeamConcreteRatio"] : 0.30)
        slabConc := totalConcCum * (cfg.Has("SlabConcreteRatio") ? cfg["SlabConcreteRatio"] : 0.40)

        ; 2. Member-Wise Steel Reinforcement (Density = 7850 kg/m³)
        steelDensity := cfg.Has("SteelDensityKgM3") ? cfg["SteelDensityKgM3"] : 7850.0
        steelRateKg := cfg.Has("SteelMarketRatePerKg") ? cfg["SteelMarketRatePerKg"] : 65.0

        pSlab := (cfg.Has("SteelPercent_Slab") ? cfg["SteelPercent_Slab"] : 1.0) / 100.0
        pBeam := (cfg.Has("SteelPercent_Beam") ? cfg["SteelPercent_Beam"] : 2.0) / 100.0
        pCol := (cfg.Has("SteelPercent_Column") ? cfg["SteelPercent_Column"] : 2.5) / 100.0
        pFoot := (cfg.Has("SteelPercent_Footing") ? cfg["SteelPercent_Footing"] : 0.8) / 100.0

        steelFootKg := Round(footingConc * pFoot * steelDensity)
        steelColKg := Round(colConc * pCol * steelDensity)
        steelBeamKg := Round(beamConc * pBeam * steelDensity)
        steelSlabKg := Round(slabConc * pSlab * steelDensity)
        totalSteelKg := steelFootKg + steelColKg + steelBeamKg + steelSlabKg
        totalSteelTonnes := Round(totalSteelKg / 1000.0, 2)
        costSteel := totalSteelKg * steelRateKg

        ; 3. Formwork / Shuttering Breakdown
        shutterRatio := cfg.Has("ShutteringAreaPerPlinthRatio") ? cfg["ShutteringAreaPerPlinthRatio"] : 2.4
        shutterAreaSqM := areaSqM * shutterRatio
        shutterAreaSqFt := shutterAreaSqM / 0.09290304

        plyMultiplier := cfg.Has("ShutteringPlySheetMultiplier") ? cfg["ShutteringPlySheetMultiplier"] : 0.22
        plySheets := Round(shutterAreaSqM * plyMultiplier)
        battenMultiplier := cfg.Has("ShutteringBattenPerPlyMultiplier") ? cfg["ShutteringBattenPerPlyMultiplier"] : 19.82
        battensCount := Round(plySheets * battenMultiplier)

        nailGramsSqM := cfg.Has("ShutteringNailsGramsPerSqM") ? cfg["ShutteringNailsGramsPerSqM"] : 75.0
        wireGramsSqM := cfg.Has("ShutteringBindingWireGramsPerSqM") ? cfg["ShutteringBindingWireGramsPerSqM"] : 75.0
        shutterNailsKg := Round((shutterAreaSqM * nailGramsSqM) / 1000.0, 1)
        shutterWireKg := Round((shutterAreaSqM * wireGramsSqM) / 1000.0, 1)

        oilLitersSqM := cfg.Has("ShutteringOilLitersPerSqM") ? cfg["ShutteringOilLitersPerSqM"] : 0.065
        shutterOilLiters := Round(shutterAreaSqM * oilLitersSqM, 1)
        shutterRateSqFt := cfg.Has("ShutteringRatePerSqFt") ? cfg["ShutteringRatePerSqFt"] : 60.0
        costShuttering := shutterAreaSqFt * shutterRateSqFt

        ; 4. Cement Consumption by Structural Activity (50kg Bags)
        cementBagRate := cfg.Has("CementBagMarketRate") ? cfg["CementBagMarketRate"] : 380.0
        cRCCPerCum := cfg.Has("CementBagsPerCum_RCC") ? cfg["CementBagsPerCum_RCC"] : 8.0
        cBrickPerCum := cfg.Has("CementBagsPerCum_Brickwork") ? cfg["CementBagsPerCum_Brickwork"] : 1.26
        cPlasterPerSqM := cfg.Has("CementBagsPerSqM_Plaster") ? cfg["CementBagsPerSqM_Plaster"] : 0.11
        cFloorPerSqM := cfg.Has("CementBagsPerSqM_Flooring") ? cfg["CementBagsPerSqM_Flooring"] : 0.25

        cementRCCBags := Round(totalConcCum * cRCCPerCum)
        bricksCount := Round(areaSqFt * (cfg.Has("BricksPerSqFt") ? cfg["BricksPerSqFt"] : 18.0))
        brickMasonryCum := bricksCount / 500.0
        cementBrickBags := Round(brickMasonryCum * cBrickPerCum)

        internalWallAreaMultiplier := cfg.Has("InternalWallPaintingAreaMultiplier") ? cfg["InternalWallPaintingAreaMultiplier"] : 3.0
        wallAreaSqFt := areaSqFt * internalWallAreaMultiplier
        wallAreaSqM := wallAreaSqFt * 0.09290304
        cementPlasterBags := Round(wallAreaSqM * cPlasterPerSqM)
        cementFloorBags := Round(areaSqM * cFloorPerSqM)
        totalCementBags := cementRCCBags + cementBrickBags + cementPlasterBags + cementFloorBags
        costCement := totalCementBags * cementBagRate

        ; 5. Bulk Masonry, Sand & Aggregates
        brickRate := cfg.Has("BrickMarketRate") ? cfg["BrickMarketRate"] : 9.0
        costBricks := bricksCount * brickRate

        sandCFT := Round(areaSqFt * (cfg.Has("SandCftPerSqFt") ? cfg["SandCftPerSqFt"] : 1.80))
        sandRateCFT := cfg.Has("SandRatePerCft") ? cfg["SandRatePerCft"] : 55.0
        costSand := sandCFT * sandRateCFT

        aggCFT := Round(areaSqFt * (cfg.Has("AggregateCftPerSqFt") ? cfg["AggregateCftPerSqFt"] : 1.35))
        aggRateCFT := cfg.Has("AggregateRatePerCft") ? cfg["AggregateRatePerCft"] : 45.0
        costAgg := aggCFT * aggRateCFT

        ; 6. Electrical & MEP Quantities
        conduitMetersPerSqM := cfg.Has("PVCConduitMetersPerSqM") ? cfg["PVCConduitMetersPerSqM"] : 1.0
        wireMetersPerSqM := cfg.Has("ElectricalWireMetersPerSqM") ? cfg["ElectricalWireMetersPerSqM"] : 10.0
        conduitMeters := Round(areaSqM * conduitMetersPerSqM, 1)
        conduitRFT := Round(conduitMeters * 3.28084)
        wireMeters := Round(areaSqM * wireMetersPerSqM, 1)
        wireRolls := Round(wireMeters / 90.0, 1)

        elecRateSqFt := cfg.Has("ElectricalCostPerSqFt") ? cfg["ElectricalCostPerSqFt"] : 133.0
        costElectrical := areaSqFt * elecRateSqFt
        plumbRateSqFt := cfg.Has("PlumbingCostPerSqFt") ? cfg["PlumbingCostPerSqFt"] : 126.0
        costPlumbing := areaSqFt * plumbRateSqFt

        ; 7. Painting & Putty Ratios
        puttyKgPerSqFt := cfg.Has("WallPuttyKgPerSqFtWall") ? cfg["WallPuttyKgPerSqFtWall"] : 0.055
        primerLPerSqFt := cfg.Has("WallPrimerLitersPerSqFtWall") ? cfg["WallPrimerLitersPerSqFtWall"] : 0.004
        paintLPerSqFt := cfg.Has("EmulsionPaintLitersPerSqFtWall") ? cfg["EmulsionPaintLitersPerSqFtWall"] : 0.007

        puttyKg := Round(wallAreaSqFt * puttyKgPerSqFt, 1)
        puttyBags := Round(puttyKg / 40.0, 1)
        primerLiters := Round(wallAreaSqFt * primerLPerSqFt, 1)
        paintLiters := Round(wallAreaSqFt * paintLPerSqFt, 1)
        costPainting := areaSqFt * 70.0

        ; 8. Flooring & Joinery
        flooringTileMultiplier := cfg.Has("FlooringTileAreaMultiplier") ? cfg["FlooringTileAreaMultiplier"] : 1.25
        tileAreaSqFt := Round(areaSqFt * flooringTileMultiplier)
        tileRateSqFt := cfg.Has("FlooringRatePerSqFt") ? cfg["FlooringRatePerSqFt"] : 65.0
        costFlooring := (tileAreaSqFt * tileRateSqFt) + (areaSqFt * 40.0)
        costJoinery := areaSqFt * 130.0

        ; 9. Site Structural Labor & Excavation
        costSiteLabor := areaSqFt * 377.40

        costTier1 := costSteel + costCement + costShuttering + costBricks + costSand + costAgg + costElectrical + costPlumbing + costPainting + costFlooring + costJoinery + costSiteLabor

        ; ==============================================================================================================
        ; TIER 2: Meso Work-Package Based Model (C2)
        ; ==============================================================================================================
        rateCivilStruct := cfg.Has("CivilWorkStructureCostPerSqFt") ? cfg["CivilWorkStructureCostPerSqFt"] : 751.25
        rateFinishing := cfg.Has("FinishingWorkCostPerSqFt") ? cfg["FinishingWorkCostPerSqFt"] : 467.50
        rateElec := cfg.Has("ElectricalCostPerSqFt") ? cfg["ElectricalCostPerSqFt"] : 133.00
        ratePlumb := cfg.Has("PlumbingCostPerSqFt") ? cfg["PlumbingCostPerSqFt"] : 126.00
        rateFire := cfg.Has("FireFightingCostPerSqFt") ? cfg["FireFightingCostPerSqFt"] : 40.00
        rateExtDev := cfg.Has("ExternalDevelopmentCostPerSqFt") ? cfg["ExternalDevelopmentCostPerSqFt"] : 94.50
        copPercent := cfg.Has("ContractorOverheadProfitPercent") ? cfg["ContractorOverheadProfitPercent"] : 10.0

        pkgCivilStruct := areaSqFt * rateCivilStruct
        pkgFinishing := areaSqFt * rateFinishing
        pkgElec := areaSqFt * rateElec
        pkgPlumb := areaSqFt * ratePlumb
        pkgFire := areaSqFt * rateFire
        pkgExtDev := areaSqFt * rateExtDev
        pkgDirectSubtotal := pkgCivilStruct + pkgFinishing + pkgElec + pkgPlumb + pkgFire + pkgExtDev
        pkgCOP := pkgDirectSubtotal * (copPercent / 100.0)

        costTier2 := pkgDirectSubtotal + pkgCOP

        ; ==============================================================================================================
        ; TIER 3: Macro Tier Rate Benchmark Model (C3)
        ; ==============================================================================================================
        costTier3 := areaSqFt * tierRate

        ; ==============================================================================================================
        ; MULTI-TIER RECONCILIATION & 5% VARIANCE CONVERGENCE ENGINE
        ; ==============================================================================================================
        meanBudget := (costTier1 + costTier2 + costTier3) / 3.0
        var1 := Abs(costTier1 - meanBudget) / meanBudget * 100.0
        var2 := Abs(costTier2 - meanBudget) / meanBudget * 100.0
        var3 := Abs(costTier3 - meanBudget) / meanBudget * 100.0
        maxVariance := Max(var1, Max(var2, var3))

        maxAllowedVar := cfg.Has("MaxAllowedVariancePercent") ? cfg["MaxAllowedVariancePercent"] : 5.0
        isConverged := (maxVariance <= maxAllowedVar)

        ; Format Numbers using Indian Commas (No Decimals on Integers)
        Fmt(n) => IsSet(FormatIndianCommas) ? FormatIndianCommas(Round(n), false) : Format("{:0.0f}", Round(n))

        ; Output Builder
        out := ""
        if (isConverged) {
            out .= "================================================================================`n"
            out .= "     🏗️ 3-TIER VERIFIED CIVIL COST & MATERIAL QUANTITY ESTIMATE (BOQ)           `n"
            out .= "================================================================================`n"
            out .= Format("Project Scope: {1} sq ft ({2:0.2f} m²) | Quality: {3}`n", Fmt(areaSqFt), areaSqM, tierName)
            out .= Format("3-Tier Reconciliation: C₁ (Material) ₹{1} | C₂ (Package) ₹{2} | C₃ (Macro) ₹{3}`n", Fmt(costTier1), Fmt(costTier2), Fmt(costTier3))
            out .= Format("Reconciliation Status: ✔️ VERIFIED (Max Variance = {1:0.2f}% ≤ {2:0.1f}%)`n`n", maxVariance, maxAllowedVar)
            out .= Format("💰 TOTAL ESTIMATED PROJECT BUDGET: ₹{1} (₹{2:0.0f} / sq ft)`n", Fmt(meanBudget), meanBudget / areaSqFt)
            out .= "--------------------------------------------------------------------------------`n"
            out .= Format("1. Civil Structure (Foundation, RCC, Formwork)  : ₹{1} ({2:0.1f}%)`n", Fmt(pkgCivilStruct), (pkgCivilStruct/costTier2)*100)
            out .= Format("2. Finishing (Flooring, Paint, Plaster, POP)   : ₹{1} ({2:0.1f}%)`n", Fmt(pkgFinishing), (pkgFinishing/costTier2)*100)
            out .= Format("3. Electrical Wiring, Switches & Conduit        : ₹{1} ({2:0.1f}%)`n", Fmt(pkgElec), (pkgElec/costTier2)*100)
            out .= Format("4. Plumbing, Sanitaryware & Drainage            : ₹{1} ({2:0.1f}%)`n", Fmt(pkgPlumb), (pkgPlumb/costTier2)*100)
            out .= Format("5. External Development & Landscaping           : ₹{1} ({2:0.1f}%)`n", Fmt(pkgExtDev), (pkgExtDev/costTier2)*100)
            out .= Format("6. Fire Fighting & Safety Provisions            : ₹{1} ({2:0.1f}%)`n", Fmt(pkgFire), (pkgFire/costTier2)*100)
            out .= Format("7. Contractor Overhead & Profit (COP 10%)       : ₹{1} ({2:0.1f}%)`n`n", Fmt(pkgCOP), (pkgCOP/costTier2)*100)

            out .= "📦 CRITICAL MATERIAL & COMPONENT SCHEDULE:`n"
            out .= "--------------------------------------------------------------------------------`n"
            out .= Format("• Structural Concrete (M20/M25) : {1:0.1f} m³ ({2} CFT)`n", totalConcCum, Fmt(concCFT))
            out .= Format("• Cement (50kg Bags)            : {1} Bags (RCC: {2}, Masonry: {3}, Plaster: {4}, Tile: {5})`n", Fmt(totalCementBags), cementRCCBags, cementBrickBags, cementPlasterBags, cementFloorBags)
            out .= Format("• Structural Steel (TMT Fe500)  : {1} kg ({2:0.2f} MT)`n", Fmt(totalSteelKg), totalSteelTonnes)
            out .= Format("    - Footings (0.8% vol)       : {1} kg`n", Fmt(steelFootKg))
            out .= Format("    - Columns (2.5% vol)        : {1} kg`n", Fmt(steelColKg))
            out .= Format("    - Beams (2.0% vol)          : {1} kg`n", Fmt(steelBeamKg))
            out .= Format("    - Slabs (1.0% vol)          : {1} kg`n", Fmt(steelSlabKg))
            out .= Format("• Shuttering / Formwork         : {1:0.1f} m² ({2} sqft)`n", shutterAreaSqM, Fmt(shutterAreaSqFt))
            out .= Format("    - Shuttering Ply Sheets     : {1} Sheets (2.44 x 1.22m)`n", plySheets)
            out .= Format("    - Battens (75x40mm)         : {1} Battens`n", Fmt(battensCount))
            out .= Format("    - Nails & Binding Wire      : {1:0.1f} kg Nails | {2:0.1f} kg Binding Wire`n", shutterNailsKg, shutterWireKg)
            out .= Format("    - Shuttering Oil            : {1:0.1f} Litres (1 L per 15 m²)`n", shutterOilLiters)
            out .= Format("• Masonry Bricks (Red Clay)     : {1} Bricks (or {2} AAC Blocks)`n", Fmt(bricksCount), Fmt(Round(areaSqFt * 1.2)))
            out .= Format("• Fine Sand & Aggregates        : Sand {1} CFT ({2:0.1f} Brass) | Aggregate {3} CFT ({4:0.1f} Brass)`n", Fmt(sandCFT), sandCFT/100.0, Fmt(aggCFT), aggCFT/100.0)
            out .= Format("• Flooring Tiles & Adhesive     : {1} sqft Tiles | {2} Bags Mortar/Adhesive`n", Fmt(tileAreaSqFt), Fmt(Round(areaSqFt * 0.15)))
            out .= Format("• Electrical Conduit & Wiring   : {1} RFT Conduit ({2:0.0f}m) | {3:0.1f} Rolls Wire ({4:0.0f}m)`n", Fmt(conduitRFT), conduitMeters, wireRolls, wireMeters)
            out .= Format("• Internal Painting (3x Carpet) : {1} sqft Wall Area`n", Fmt(wallAreaSqFt))
            out .= Format("    - Wall Putty (2 coats)      : {1:0.0f} kg ({2:0.1f} Bags of 40kg)`n", puttyKg, puttyBags)
            out .= Format("    - Wall Primer (1 coat)      : {1:0.1f} Litres`n", primerLiters)
            out .= Format("    - Emulsion Paint (2 coats)  : {1:0.1f} Litres`n", paintLiters)
            out .= "================================================================================"
        } else {
            out .= "================================================================================`n"
            out .= "                ⚠️ 3-TIER ESTIMATION VARIANCE AUDIT NOTICE                      `n"
            out .= "================================================================================`n"
            out .= Format("Project Scope: {1} sq ft | Status: RECONCILIATION VARIANCE EXCEEDED ({2:0.2f}% > {3:0.1f}%)`n`n", Fmt(areaSqFt), maxVariance, maxAllowedVar)
            out .= Format("• Tier 1 (Material & Labor) : ₹{1} ({2:+0.1f}% vs Mean)`n", Fmt(costTier1), ((costTier1 - meanBudget)/meanBudget)*100)
            out .= Format("• Tier 2 (Trade Packages)   : ₹{1} ({2:+0.1f}% vs Mean)`n", Fmt(costTier2), ((costTier2 - meanBudget)/meanBudget)*100)
            out .= Format("• Tier 3 (Macro Benchmark)  : ₹{1} ({2:+0.1f}% vs Mean)`n`n", Fmt(costTier3), ((costTier3 - meanBudget)/meanBudget)*100)

            out .= "🔍 DIVERGENT ITEMS IDENTIFIED:`n"
            if (var1 >= var2 && var1 >= var3) {
                out .= "1. Micro Material/Labor schedule diverges significantly from trade package rates.`n"
                out .= "2. Check individual material unit rates (Steel, Cement, Shuttering) in CivilEngineeringDefaults.ini.`n"
            } else if (var2 >= var1 && var2 >= var3) {
                out .= "1. Trade Package rates sum (Civil + Finishing + MEP + COP) diverges from macro tier target.`n"
                out .= "2. Review [EstimatorPackageRates] in CivilEngineeringDefaults.ini.`n"
            } else {
                out .= Format("1. Macro quality tier benchmark (₹{1}/sqft) diverges from calculated bottom-up schedules.`n", tierRate)
                out .= "2. Adjust [ConstructionCostTiers] per-sqft rate to align with site specifications.`n"
            }
            out .= "`nRecommended Action: Calibrate unit rates in CivilEngineeringDefaults.ini or refine site scope.`n"
            out .= "================================================================================"
        }

        return {
            success: true,
            category: isConverged ? "🏗️ 3-Tier Verified BOQ Estimate" : "⚠️ Estimator Variance Audit",
            displayExpr: Format("Built-up Area: {1} sq ft ({2})", Fmt(areaSqFt), tierName),
            resultStr: out,
            val: meanBudget,
            unit: "INR",
            isConverged: isConverged,
            maxVariance: maxVariance
        }
    }
}
