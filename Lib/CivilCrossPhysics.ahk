; ======================================================================================================================
; Module: CivilCrossPhysics.ahk - Cross-Dimensional Physics, Geometry & Material Mechanics
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

class CivilCrossPhysics {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Dimension & Material Parsers
    ; ------------------------------------------------------------------------------------------------------------------
    static ParseDimensionInput(inputStr, requiredDim := "L") {
        clean := Trim(inputStr)
        if (RegExMatch(clean, "i)^([\d\.]+)\s*([a-z\x27\x22°\-]+)?$", &m)) {
            val := Float(m[1])
            unitKey := (m.Count >= 2 && m[2] != "") ? StrLower(Trim(m[2])) : "m"
            u := CivilUnits.ResolveUnit(unitKey)
            if (u && u.dim == requiredDim)
                return val * u.factor
            return val
        }
        return 0.0
    }

    static ParseCrossSectionInput(inputStr) {
        clean := Trim(inputStr)
        if (RegExMatch(clean, "i)^([\d\.]+)\s*([a-z\x27\x22°]+)?\s*(?:x|\*|by)\s*([\d\.]+)\s*([a-z\x27\x22°]+)?$", &mComp)) {
            wVal := Float(mComp[1])
            wUnit := (mComp[2] != "") ? CivilUnits.ResolveUnit(StrLower(mComp[2])) : CivilUnits.ResolveUnit("m")
            dVal := Float(mComp[3])
            dUnit := (mComp[4] != "") ? CivilUnits.ResolveUnit(StrLower(mComp[4])) : CivilUnits.ResolveUnit("m")
            return (wVal * (wUnit ? wUnit.factor : 1.0)) * (dVal * (dUnit ? dUnit.factor : 1.0))
        }
        if (RegExMatch(clean, "i)^([\d\.]+)\s*([a-z0-9²³]+)?$", &mArea)) {
            aVal := Float(mArea[1])
            aUnit := (mArea.Count >= 2 && mArea[2] != "") ? CivilUnits.ResolveUnit(StrLower(mArea[2])) : CivilUnits.ResolveUnit("sqm")
            if (aUnit && aUnit.dim == "L2")
                return aVal * aUnit.factor
            return aVal * aVal
        }
        return 0.0
    }

    static ParseAreaOrDimensions(inputStr) {
        clean := Trim(inputStr)
        if (RegExMatch(clean, "i)^([\d\.]+)\s*([a-z\x27\x22°]+)?\s*(?:x|\*|by)\s*([\d\.]+)\s*([a-z\x27\x22°]+)?$", &mComp)) {
            wVal := Float(mComp[1])
            wUnit := (mComp[2] != "") ? CivilUnits.ResolveUnit(StrLower(mComp[2])) : CivilUnits.ResolveUnit("m")
            dVal := Float(mComp[3])
            dUnit := (mComp[4] != "") ? CivilUnits.ResolveUnit(StrLower(mComp[4])) : CivilUnits.ResolveUnit("m")
            return (wVal * (wUnit ? wUnit.factor : 1.0)) * (dVal * (dUnit ? dUnit.factor : 1.0))
        }
        if (RegExMatch(clean, "i)(?:dia|diameter|d=)\s*([\d\.]+)\s*([a-z\x27\x22°]+)?", &mCirc)) {
            dVal := Float(mCirc[1])
            dUnit := (mCirc.Count >= 2 && mCirc[2] != "") ? CivilUnits.ResolveUnit(StrLower(mCirc[2])) : CivilUnits.ResolveUnit("mm")
            diaM := dVal * (dUnit ? dUnit.factor : 0.001)
            return (3.141592653589793 / 4.0) * diaM * diaM
        }
        if (RegExMatch(clean, "i)^([\d\.]+)\s*([a-z0-9²³]+)?$", &mArea)) {
            aVal := Float(mArea[1])
            aUnit := (mArea.Count >= 2 && mArea[2] != "") ? CivilUnits.ResolveUnit(StrLower(mArea[2])) : CivilUnits.ResolveUnit("sqm")
            if (aUnit && aUnit.dim == "L2")
                return aVal * aUnit.factor
            return aVal
        }
        return 0.0
    }

    static ResolveMaterialDensity(inputStr, cfg) {
        s := StrLower(Trim(inputStr))
        if (InStr(s, "steel") || InStr(s, "rebar") || InStr(s, "tmt"))
            return {density: cfg["Steel"], name: "Steel (7850 kg/m³)"}
        if (InStr(s, "sand"))
            return {density: cfg["Sand_Dry"], name: "Sand Dry (1600 kg/m³)"}
        if (InStr(s, "aggregate") || InStr(s, "gravel") || InStr(s, "kadi"))
            return {density: cfg["Aggregate_Coarse"], name: "Coarse Aggregate (1500 kg/m³)"}
        if (InStr(s, "pcc"))
            return {density: cfg["Concrete_PCC"], name: "Plain Concrete PCC (2300 kg/m³)"}
        if (InStr(s, "concrete") || InStr(s, "rcc"))
            return {density: cfg["Concrete_RCC"], name: "Reinforced Concrete RCC (2400 kg/m³)"}
        if (InStr(s, "cement"))
            return {density: cfg["Cement_Bulk"], name: "Bulk Cement (1440 kg/m³)"}
        ; Fix [Concern 3]: Fluid densities in cfg are in kg/m³, removing 1000x multiplication
        if (InStr(s, "diesel"))
            return {density: cfg["Diesel"], name: "Diesel (840 kg/m³)"}
        if (InStr(s, "petrol") || InStr(s, "gasoline"))
            return {density: cfg["Petrol"], name: "Petrol (740 kg/m³)"}
        if (InStr(s, "water") || InStr(s, "pani"))
            return {density: cfg["Water"], name: "Water (1000 kg/m³)"}

        if (RegExMatch(s, "i)^([\d\.]+)\s*([a-z0-9²³\/]+)?$", &mD)) {
            val := Float(mD[1])
            uKey := (mD.Count >= 2 && mD[2] != "") ? StrLower(mD[2]) : "kg/m3"
            u := CivilUnits.ResolveUnit(uKey)
            if (u && u.dim == "D")
                return {density: val * u.factor, name: Format("{:0.0f} kg/m³", val * u.factor)}
            return {density: val, name: Format("{:0.0f} kg/m³", val)}
        }

        return {density: cfg["Concrete_RCC"], name: "Concrete RCC (2400 kg/m³)"}
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; Unified Evaluator Entry Point (Contract Uniformity)
    ; ------------------------------------------------------------------------------------------------------------------
    static Evaluate(str, secondaryParam := "", cfg := "") {
        if (!IsObject(cfg)) {
            cfg := (IsSet(CivilConverterEngine) && HasMethod(CivilConverterEngine, "LoadConfig")) ? CivilConverterEngine.LoadConfig() : Map("Steel", 7850.0, "Concrete_RCC", 2400.0, "Water", 1000.0)
        }
        return this.EvaluatePhysicalTransformation(str, secondaryParam, cfg)
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Transformation Dispatcher Pipeline
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluatePhysicalTransformation(str, secondaryParam, cfg) {
        ; 2D Dimension Pair: 10m x 20m kitna sqft
        if (RegExMatch(str, "i)^([\d\.]+)\s*([a-z\x27\x22]+)?\s*(?:x|\*|by)\s*([\d\.]+)\s*([a-z\x27\x22]+)?(?:\s*(?:to|in|into|=)?\s*([a-z0-9²³]+))?$", &mDim2)) {
            return this.EvaluateRectangularArea(mDim2, cfg)
        }

        ; 3D Volume Triplet: 2m x 3m x 1.5m to cft
        if (RegExMatch(str, "i)^([\d\.]+)\s*([a-z\x27\x22]+)?\s*(?:x|\*|by)\s*([\d\.]+)\s*([a-z\x27\x22]+)?\s*(?:x|\*|by)\s*([\d\.]+)\s*([a-z\x27\x22]+)?(?:\s*(?:to|in|into|=)?\s*([a-z0-9²³]+))?$", &mDim3)) {
            return this.Evaluate3DVolume(mDim3, cfg)
        }

        ; Compound feet-inches: e.g. 5'-6" to mm, 5 ft 6 inch to mm
        if (RegExMatch(str, "i)^(\d+)(?:\x27|\s*ft|\s*foot)[\s\-]*(\d+(?:\.\d+)?)(?:\x22|\s*in|\s*inch)?(?:\s*(?:to)\s*([a-z0-9²³]+))?", &mFtIn)) {
            ftVal := Float(mFtIn[1])
            inVal := Float(mFtIn[2])
            totalMeters := (ftVal * 0.3048) + (inVal * 0.0254)
            targetUnitKey := (mFtIn.Count >= 3 && mFtIn[3] != "") ? StrLower(mFtIn[3]) : "mm"
            targetUnit := CivilUnits.ResolveUnit(targetUnitKey)
            if (targetUnit && targetUnit.dim == "L") {
                resVal := totalMeters / targetUnit.factor
                return {
                    success: true,
                    category: "Direct Conversion (Length)",
                    displayExpr: Format("{1} ft {2} in -> {3}", ftVal, inVal, targetUnit.label),
                    resultStr: Format("{:0.3f} {}", resVal, targetUnit.label),
                    val: resVal,
                    unit: targetUnit.label
                }
            }
        }

        ; Standard Single-Value with optional material keyword (supports multi-word units & unicode script)
        pattern := "i)^(?:\w+\s+)?([\d\.\/]+)\s+(.+?)(?:\s+(?:water|steel|sand|diesel|petrol|cement))?(?:\s+(?:to)\s+(.+))?$"
        if (!RegExMatch(str, pattern, &m)) {
            pattern := "i)^(?:\w+\s+)?([\d\.\/]+)\s*([^\s]+)(?:\s+(?:water|steel|sand|diesel|petrol|cement))?(?:\s+(?:to)\s+(.+))?$"
            if (!RegExMatch(str, pattern, &m))
                return {success: false, message: "Could not parse conversion pattern: '" . str . "'"}
        }

        valStr := m[1]
        srcUnitKey := StrLower(Trim(m[2]))
        targetUnitKey := (m.Count >= 3 && m[3] != "") ? StrLower(Trim(m[3])) : ""

        val := 0.0
        if (InStr(valStr, "/")) {
            parts := StrSplit(valStr, "/")
            if (parts.Length = 2 && Float(parts[2]) != 0)
                val := Float(parts[1]) / Float(parts[2])
        } else {
            val := Float(valStr)
        }

        srcUnit := CivilUnits.ResolveUnit(srcUnitKey)
        if (!srcUnit) {
            return {success: false, message: "Unknown source unit: '" . srcUnitKey . "'"}
        }

        if (targetUnitKey == "") {
            targetUnitKey := CivilUnits.GetDefaultTargetUnit(srcUnit.dim)
        }

        targetUnit := CivilUnits.ResolveUnit(targetUnitKey)
        if (!targetUnit) {
            return {success: false, message: "Unknown target unit: '" . targetUnitKey . "'"}
        }

        ; Direct 1D Same-Dimension
        if (srcUnit.dim == targetUnit.dim) {
            return CivilUnits.EvaluateDirect(val, srcUnit, targetUnit)
        }

        ; Cross-Dimensional Physics
        if (srcUnit.dim == "L" && targetUnit.dim == "L2")
            return this.HandleLengthToArea(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "L" && targetUnit.dim == "L3")
            return this.HandleLengthToVolume(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "L2" && targetUnit.dim == "L3")
            return this.HandleAreaToVolume(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "L3" && targetUnit.dim == "L2")
            return this.HandleVolumeToArea(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "L3" && (targetUnit.dim == "M") && (InStr(str, "water") || InStr(str, "diesel") || InStr(str, "petrol") || InStr(str, "pani") || InStr(str, "liquid") || InStr(srcUnit.name, "litre") || InStr(srcUnit.name, "ml") || InStr(srcUnit.name, "gallon")))
            return this.HandleLiquidToMass(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "L3" && targetUnit.dim == "M")
            return this.HandleVolumeToMass(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "F" && targetUnit.dim == "P")
            return this.HandleForceToPressure(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "P" && targetUnit.dim == "F")
            return this.HandlePressureToForce(val, srcUnit, targetUnit, secondaryParam, cfg)
        if (srcUnit.dim == "Q" && targetUnit.dim == "M")
            return this.HandleFlowToMass(val, srcUnit, targetUnit, secondaryParam, cfg)

        ; Dimensionally Incompatible Rejection
        return this.GenerateIncompatibleRejection(srcUnit, targetUnit)
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. Cross-Dimensional Handlers
    ; ------------------------------------------------------------------------------------------------------------------
    static HandleLengthToArea(val, srcUnit, targetUnit, param, cfg) {
        lengthM := val * srcUnit.factor
        widthM := lengthM
        appliedDesc := "Assumed Square (Width = " . Format("{:0.2f}m", lengthM) . ")"

        if (Trim(param) != "") {
            parsedW := this.ParseDimensionInput(param, "L")
            if (parsedW > 0) {
                widthM := parsedW
                appliedDesc := "Width = " . Trim(param)
            }
        }

        areaSqM := lengthM * widthM
        converted := areaSqM / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: Format("Enter Width [Default: {:0.2f} {} (Square)]", val, srcUnit.label),
            defaultApplied: appliedDesc,
            category: "Geometry (Length -> Area)",
            displayExpr: Format("{1} {2} * {3} -> {4}", val, srcUnit.label, (widthM = lengthM ? val . " " . srcUnit.label : Trim(param)), targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, appliedDesc),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleLengthToVolume(val, srcUnit, targetUnit, param, cfg) {
        lengthM := val * srcUnit.factor
        sectionSqM := lengthM * lengthM
        appliedDesc := "Assumed Cube (" . Format("{:0.2f}m x {:0.2f}m", lengthM, lengthM) . ")"

        if (Trim(param) != "") {
            parsedSec := this.ParseCrossSectionInput(param)
            if (parsedSec > 0) {
                sectionSqM := parsedSec
                appliedDesc := "Section = " . Trim(param)
            }
        }

        volCum := lengthM * sectionSqM
        converted := volCum / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: "Enter Cross-Section Area or WxD [Default: Square Cube]",
            defaultApplied: appliedDesc,
            category: "Geometry (Length -> Volume)",
            displayExpr: Format("{1} {2} * {3} -> {4}", val, srcUnit.label, appliedDesc, targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, appliedDesc),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleAreaToVolume(val, srcUnit, targetUnit, param, cfg) {
        areaSqM := val * srcUnit.factor
        heightM := Sqrt(areaSqM)
        appliedDesc := "Cube Depth (" . Format("{:0.2f}m", heightM) . ")"

        if (Trim(param) != "") {
            parsedH := this.ParseDimensionInput(param, "L")
            if (parsedH > 0) {
                heightM := parsedH
                appliedDesc := "Thickness/Depth = " . Trim(param)
            }
        }

        volCum := areaSqM * heightM
        converted := volCum / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: Format("Enter Thickness / Height [Default: {:0.2f} m (Cube Root)]", Sqrt(areaSqM)),
            defaultApplied: appliedDesc,
            category: "Geometry (Area -> Volume)",
            displayExpr: Format("{1} {2} * {3} -> {4}", val, srcUnit.label, appliedDesc, targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, appliedDesc),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleVolumeToArea(val, srcUnit, targetUnit, param, cfg) {
        volCum := val * srcUnit.factor
        heightM := (volCum > 0) ? (volCum ** (1/3)) : 1.0
        appliedDesc := "Cube Root Depth (" . Format("{:0.2f}m", heightM) . ")"

        if (Trim(param) != "") {
            parsedH := this.ParseDimensionInput(param, "L")
            if (parsedH > 0) {
                heightM := parsedH
                appliedDesc := "Depth = " . Trim(param)
            }
        }

        areaSqM := (heightM > 0) ? (volCum / heightM) : 0
        converted := areaSqM / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: Format("Enter Thickness / Depth [Default: {:0.2f} m (Cube Root)]", volCum ** (1/3)),
            defaultApplied: appliedDesc,
            category: "Geometry (Volume -> Area)",
            displayExpr: Format("{1} {2} / {3} -> {4}", val, srcUnit.label, appliedDesc, targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, appliedDesc),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleVolumeToMass(val, srcUnit, targetUnit, param, cfg) {
        volCum := val * srcUnit.factor
        densityKgM3 := cfg["Concrete_RCC"]
        materialName := "Concrete RCC (2400 kg/m³)"

        if (Trim(param) != "") {
            dObj := this.ResolveMaterialDensity(param, cfg)
            densityKgM3 := dObj.density
            materialName := dObj.name
        }

        massKg := volCum * densityKgM3
        converted := massKg / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: "Enter Material Type (e.g. Steel, Sand, Cement, Water) or Density (kg/m³)",
            defaultApplied: materialName,
            category: "Material Transformation (Volume -> Mass)",
            displayExpr: Format("{1} {2} * {3} -> {4}", val, srcUnit.label, materialName, targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, materialName),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleLiquidToMass(val, srcUnit, targetUnit, param, cfg) {
        volCum := val * srcUnit.factor
        ; Fix [Concern 3]: cfg["Water"] is already in kg/m³
        densityKgM3 := cfg["Water"]
        materialName := "Water (1000 kg/m³)"

        if (Trim(param) != "") {
            dObj := this.ResolveMaterialDensity(param, cfg)
            densityKgM3 := dObj.density
            materialName := dObj.name
        }

        massKg := volCum * densityKgM3
        converted := massKg / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: "Enter Liquid Type (Water, Diesel, Petrol) or Density [Default: Water]",
            defaultApplied: materialName,
            category: "Fluid Mass (Liquid -> Weight)",
            displayExpr: Format("{1} {2} * {3} -> {4}", val, srcUnit.label, materialName, targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, materialName),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleForceToPressure(val, srcUnit, targetUnit, param, cfg) {
        forceN := val * srcUnit.factor
        areaSqM := cfg["DefaultLoadedAreaSqMeters"]
        appliedDesc := "Unit Area (1.0 m²)"

        if (Trim(param) != "") {
            parsedA := this.ParseAreaOrDimensions(param)
            if (parsedA > 0) {
                areaSqM := parsedA
                appliedDesc := "Area = " . Trim(param)
            }
        }

        pressurePa := (areaSqM > 0) ? (forceN / areaSqM) : 0
        converted := pressurePa / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: "Enter Loaded Area or LxB [Default: 1.0 m²]",
            defaultApplied: appliedDesc,
            category: "Structural Mechanics (Force -> Pressure)",
            displayExpr: Format("{1} {2} / {3} -> {4}", val, srcUnit.label, appliedDesc, targetUnit.label),
            resultStr: Format("{:0.3f} {} [{}]", converted, targetUnit.label, appliedDesc),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandlePressureToForce(val, srcUnit, targetUnit, param, cfg) {
        pressurePa := val * srcUnit.factor
        areaSqM := cfg["DefaultLoadedAreaSqMeters"]
        appliedDesc := "Unit Area (1.0 m²)"

        if (Trim(param) != "") {
            parsedA := this.ParseAreaOrDimensions(param)
            if (parsedA > 0) {
                areaSqM := parsedA
                appliedDesc := "Area = " . Trim(param)
            }
        }

        forceN := pressurePa * areaSqM
        converted := forceN / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: "Enter Loaded Area or LxB [Default: 1.0 m²]",
            defaultApplied: appliedDesc,
            category: "Structural Mechanics (Pressure -> Force)",
            displayExpr: Format("{1} {2} * {3} -> {4}", val, srcUnit.label, appliedDesc, targetUnit.label),
            resultStr: Format("{:0.2f} {} [{}]", converted, targetUnit.label, appliedDesc),
            val: converted,
            unit: targetUnit.label
        }
    }

    static HandleFlowToMass(val, srcUnit, targetUnit, param, cfg) {
        flowLps := val * srcUnit.factor
        ; Fix [Concern 3]: Convert cfg["Water"] (kg/m³) to kg/L for L/s flow calculations
        fluidDensityKgL := cfg["Water"] / 1000.0
        fluidName := "Water (1.0 kg/L)"

        if (Trim(param) != "") {
            dObj := this.ResolveMaterialDensity(param, cfg)
            fluidDensityKgL := dObj.density / 1000.0
            fluidName := dObj.name
        }

        massKgSec := flowLps * fluidDensityKgL
        converted := massKgSec / targetUnit.factor
        return {
            success: true,
            needsParam: (Trim(param) == ""),
            paramPrompt: "Enter Fluid Type or Density [Default: Water (1.0 kg/L)]",
            defaultApplied: fluidName,
            category: "Hydraulics (Flow -> Mass Discharge)",
            displayExpr: Format("{1} {2} ({3}) -> {4}/s", val, srcUnit.label, fluidName, targetUnit.label),
            resultStr: Format("{:0.3f} {}/s [{}]", converted, targetUnit.label, fluidName),
            val: converted,
            unit: targetUnit.label . "/s"
        }
    }

    static GenerateIncompatibleRejection(srcUnit, targetUnit) {
        dimNames := Map("L","Length", "L2","Area", "L3","Volume", "M","Mass/Weight", "F","Force/Load", "P","Pressure/Stress", "D","Density", "Q","Volumetric Flow Rate", "A","Angle/Geometry")
        srcDimName := dimNames.Has(srcUnit.dim) ? dimNames[srcUnit.dim] : srcUnit.dim
        tgtDimName := dimNames.Has(targetUnit.dim) ? dimNames[targetUnit.dim] : targetUnit.dim

        reason := Format("Cannot convert {1} ({2}) directly to {3} ({4}). These represent different physical dimensions with no direct governing relation.",
            srcDimName, srcUnit.label, tgtDimName, targetUnit.label)

        if (srcUnit.dim == "L" && targetUnit.dim == "D")
            reason := "Length is a 1D spatial span, whereas Density is an intrinsic volumetric mass property (kg/m³). They are physically incompatible."
        else if (srcUnit.dim == "Q" && targetUnit.dim == "D")
            reason := "Flow rate (L/s) is a kinematic discharge rate; Density (kg/m³) is mass per volume. Flow rate cannot determine density."
        else if (srcUnit.dim == "A" && targetUnit.dim == "P")
            reason := "Geometric angle (degrees/radians) has no physical relationship with Pressure/Stress."
        else if (srcUnit.dim == "Q" && targetUnit.dim == "P")
            reason := "Flow rate cannot be converted to static pressure without a complete hydraulic piping/pump loss model."

        return {
            success: false,
            isIncompatible: true,
            category: "Dimensionally Incompatible",
            srcDimension: srcDimName,
            targetDimension: tgtDimName,
            message: reason
        }
    }

    static EvaluateRectangularArea(mDim2, cfg) {
        lVal := Float(mDim2[1])
        wVal := Float(mDim2[3])

        ; Smart unit inheritance: e.g. 5000x5000 mm -> both mm
        lUnitKey := (mDim2[2] != "") ? StrLower(Trim(mDim2[2])) : ""
        wUnitKey := (mDim2[4] != "") ? StrLower(Trim(mDim2[4])) : ""

        if (lUnitKey == "" && wUnitKey != "")
            lUnitKey := wUnitKey
        else if (wUnitKey == "" && lUnitKey != "")
            wUnitKey := lUnitKey
        else if (lUnitKey == "" && wUnitKey == "") {
            lUnitKey := "m"
            wUnitKey := "m"
        }

        lUnit := CivilUnits.ResolveUnit(lUnitKey)
        wUnit := CivilUnits.ResolveUnit(wUnitKey)
        targetKey := (mDim2.Count >= 5 && mDim2[5] != "") ? StrLower(Trim(mDim2[5])) : "sqft"
        targetUnit := CivilUnits.ResolveUnit(targetKey)
        if (!targetUnit || targetUnit.dim != "L2")
            targetUnit := CivilUnits.ResolveUnit("sqft")

        lM := lVal * (lUnit ? lUnit.factor : 1.0)
        wM := wVal * (wUnit ? wUnit.factor : 1.0)
        areaSqM := lM * wM
        converted := areaSqM / targetUnit.factor

        return {
            success: true,
            category: "📐 Rectangular Area Calculation",
            displayExpr: Format("{1} {2} * {3} {4} -> {5}", lVal, (lUnit ? lUnit.label : "m"), wVal, (wUnit ? wUnit.label : "m"), targetUnit.label),
            resultStr: Format("Area: {:0.3f} {} ({:0.2f} m²)", converted, targetUnit.label, areaSqM),
            val: converted,
            unit: targetUnit.label
        }
    }

    static Evaluate3DVolume(mDim3, cfg) {
        lVal := Float(mDim3[1])
        wVal := Float(mDim3[3])
        hVal := Float(mDim3[5])

        lUnitKey := (mDim3[2] != "") ? StrLower(Trim(mDim3[2])) : ""
        wUnitKey := (mDim3[4] != "") ? StrLower(Trim(mDim3[4])) : ""
        hUnitKey := (mDim3[6] != "") ? StrLower(Trim(mDim3[6])) : ""

        ; Find shared trailing or leading unit
        sharedUnit := (hUnitKey != "") ? hUnitKey : ((wUnitKey != "") ? wUnitKey : ((lUnitKey != "") ? lUnitKey : "m"))
        if (lUnitKey == "")
            lUnitKey := sharedUnit
        if (wUnitKey == "")
            wUnitKey := sharedUnit
        if (hUnitKey == "")
            hUnitKey := sharedUnit

        lUnit := CivilUnits.ResolveUnit(lUnitKey)
        wUnit := CivilUnits.ResolveUnit(wUnitKey)
        hUnit := CivilUnits.ResolveUnit(hUnitKey)

        targetKey := (mDim3.Count >= 7 && mDim3[7] != "") ? StrLower(Trim(mDim3[7])) : "cum"
        targetUnit := CivilUnits.ResolveUnit(targetKey)
        if (!targetUnit || targetUnit.dim != "L3")
            targetUnit := CivilUnits.ResolveUnit("cum")

        lM := lVal * (lUnit ? lUnit.factor : 1.0)
        wM := wVal * (wUnit ? wUnit.factor : 1.0)
        hM := hVal * (hUnit ? hUnit.factor : 1.0)
        volCum := lM * wM * hM
        converted := volCum / targetUnit.factor

        return {
            success: true,
            category: "📦 3D Element Volume Calculation",
            displayExpr: Format("{1} {2} * {3} {4} * {5} {6} -> {7}", lVal, (lUnit ? lUnit.label : "m"), wVal, (wUnit ? wUnit.label : "m"), hVal, (hUnit ? hUnit.label : "m"), targetUnit.label),
            resultStr: Format("Volume: {:0.3f} {} ({:0.2f} CFT)", converted, targetUnit.label, volCum / 0.0283168),
            val: converted,
            unit: targetUnit.label
        }
    }
}
