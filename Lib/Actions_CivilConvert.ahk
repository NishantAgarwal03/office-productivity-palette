; ======================================================================================================================
; Module: Actions_CivilConvert.ahk - Civil Engineering, Rate, Pythagoras & Thumb Rule Cost Actions
; Part of Office Productivity Hub & Action Board (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterCivilActions() {
    RegisterAction(
        "Civil & Construction Instant Converter",
        "🏗️ Civil",
        "[Needs Selection or Prompts] Multi-unit converter for Length, Area, Volume, Weight, Force, Pressure, Rebar, Density & Flow",
        "civil, convert, convertor, units, construction, sqft, sqm, cft, m3, cum, ft, meter, inch, rebar, bigha, gaj, mpa, kn, slope, steel, cement",
        (*) => ShowCivilConverter(),
        "u",
        "^+u"
    )

    RegisterAction(
        "Pythagoras & Plot Diagonal Calculator",
        "🏗️ Civil",
        "[Needs Selection or Prompts] Solves 3-4-5 rule, right triangles, plot corners & diagonals (e.g. 20ft 30ft)",
        "pythagoras, diagonal, hypotenuse, 3-4-5, 345, guniya, gunia, 90, 90 degree, tircha, karna, right angle, corner, survey, triangle",
        (*) => PromptPythagorasCalculator()
    )

    RegisterAction(
        "Construction Rate & Unit Price Converter",
        "🏗️ Civil",
        "[Needs Selection or Prompts] Converts unit rates (e.g. Rs 500/sqft to sqm, 4500/cum to cft, 2500/brass to cft)",
        "rate, price, per sqft, per cum, per cft, per brass, unit price, cost per, boq, estimate, convert, convertor, converter",
        (*) => PromptRateConverter()
    )

    RegisterAction(
        "Thumb Rule Cost & Material Estimator",
        "🏗️ Civil",
        "[Needs Selection or Prompts] Estimates construction cost, materials (Cement, Steel, Bricks) & deep manpower from area",
        "cost, estimate, thumb rule, material, manpower, labor, mandays, wages, mason, barbender, carpenter, cement bags, steel kg, bricks, builtup area, house cost, boq",
        (*) => PromptThumbRuleEstimator()
    )

    RegisterAction(
        "Configure Civil Converter Defaults",
        "🏗️ Civil",
        "Opens CivilEngineeringDefaults.ini to customize material densities, geometric fallback rules, and rebar defaults",
        "configure, civil, defaults, engineering, convert, convertor, settings, density, rebar, slope, bigha",
        (*) => OpenCivilDefaultsFile()
    )
}

OpenCivilDefaultsFile() {
    global CivilEngineeringDefaultsFile
    if !FileExist(CivilEngineeringDefaultsFile) {
        ShowToast("⚠️ Defaults configuration file not found", 2000)
        return
    }
    Run('notepad.exe "' . CivilEngineeringDefaultsFile . '"')
    ShowToast("⚙️ Opened Civil Converter Defaults", 1800)
}

PromptPythagorasCalculator() {
    sel := SafeGetSelection(0.2)
    if (Trim(sel) == "" || !RegExMatch(sel, "[\d\.]+")) {
        ib := OfficeInputBox("Enter 2 sides for diagonal (e.g. '20ft 30ft') or 3 sides to check Guniya (e.g. '8m 10m 13.2m'):", "📐 Pythagoras & Guniya Check")
        if (ib.Result != "OK" || Trim(ib.Value) == "")
            return
        sel := ib.Value
    }
    query := (InStr(sel, "pythagoras") || InStr(sel, "diagonal") || InStr(sel, "hyp") || InStr(sel, "guniya")) ? sel : ("diagonal " . sel)
    ShowCivilConverter(query)
}

PromptRateConverter() {
    sel := SafeGetSelection(0.2)
    if (Trim(sel) == "" || !RegExMatch(sel, "(?:per|\/)")) {
        ib := OfficeInputBox("Enter unit rate conversion (e.g. '500 per sqft to sqm' or '4500 per cum to cft'):", "💰 Construction Rate Converter")
        if (ib.Result != "OK" || Trim(ib.Value) == "")
            return
        sel := ib.Value
    }
    ShowCivilConverter(sel)
}

PromptThumbRuleEstimator() {
    sel := SafeGetSelection(0.2)
    if (Trim(sel) == "" || !RegExMatch(sel, "[\d\.]+")) {
        ib := OfficeInputBox("Enter built-up area for cost estimation (e.g. '1500 sqft' or '120 sqm'):", "🏗️ Thumb Rule Cost Estimator")
        if (ib.Result != "OK" || Trim(ib.Value) == "")
            return
        sel := ib.Value
    }
    query := InStr(sel, "cost") ? sel : ("cost " . sel)
    ShowCivilConverter(query)
}
