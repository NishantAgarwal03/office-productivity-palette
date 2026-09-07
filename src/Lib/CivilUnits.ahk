; ======================================================================================================================
; Module: CivilUnits.ahk - Canonical Physical Unit Registry & Direct Same-Dimension Converter
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

class CivilUnits {

    ; ------------------------------------------------------------------------------------------------------------------
    ; 1. Canonical Physical Unit Registry (120+ Units across 9 Physical Dimensions)
    ; ------------------------------------------------------------------------------------------------------------------
    static UnitRegistry := Map(
        ; --- LENGTH (Base Unit: metre 'm') ---
        "m", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "meter", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "metre", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "mtr", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "mts", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "metres", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "meters", {dim: "L", factor: 1.0, name: "m", label: "m"},
        "rmt", {dim: "L", factor: 1.0, name: "m", label: "rmt"},
        "running meter", {dim: "L", factor: 1.0, name: "m", label: "rmt"},
        "running metre", {dim: "L", factor: 1.0, name: "m", label: "rmt"},
        "mm", {dim: "L", factor: 0.001, name: "mm", label: "mm"},
        "millimeter", {dim: "L", factor: 0.001, name: "mm", label: "mm"},
        "millimetre", {dim: "L", factor: 0.001, name: "mm", label: "mm"},
        "cm", {dim: "L", factor: 0.01, name: "cm", label: "cm"},
        "centimeter", {dim: "L", factor: 0.01, name: "cm", label: "cm"},
        "centimetre", {dim: "L", factor: 0.01, name: "cm", label: "cm"},
        "km", {dim: "L", factor: 1000.0, name: "km", label: "km"},
        "kilometer", {dim: "L", factor: 1000.0, name: "km", label: "km"},
        "kilometre", {dim: "L", factor: 1000.0, name: "km", label: "km"},
        "inch", {dim: "L", factor: 0.0254, name: "inch", label: "in"},
        "in", {dim: "L", factor: 0.0254, name: "inch", label: "in"},
        "inches", {dim: "L", factor: 0.0254, name: "inch", label: "in"},
        '"', {dim: "L", factor: 0.0254, name: "inch", label: "in"},
        "ft", {dim: "L", factor: 0.3048, name: "ft", label: "ft"},
        "foot", {dim: "L", factor: 0.3048, name: "ft", label: "ft"},
        "feet", {dim: "L", factor: 0.3048, name: "ft", label: "ft"},
        "feets", {dim: "L", factor: 0.3048, name: "ft", label: "ft"},
        "'", {dim: "L", factor: 0.3048, name: "ft", label: "ft"},
        "rft", {dim: "L", factor: 0.3048, name: "rft", label: "rft"},
        "running ft", {dim: "L", factor: 0.3048, name: "rft", label: "rft"},
        "running feet", {dim: "L", factor: 0.3048, name: "rft", label: "rft"},
        "running foot", {dim: "L", factor: 0.3048, name: "rft", label: "rft"},
        "yd", {dim: "L", factor: 0.9144, name: "yd", label: "yd"},
        "yard", {dim: "L", factor: 0.9144, name: "yd", label: "yd"},
        "yards", {dim: "L", factor: 0.9144, name: "yd", label: "yd"},

        ; --- AREA (Base Unit: square metre 'm2') ---
        "sqm", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "sq m", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "m2", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "m²", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "sqmt", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "square meter", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "square metre", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "square meters", {dim: "L2", factor: 1.0, name: "sqm", label: "m²"},
        "sqmm", {dim: "L2", factor: 0.000001, name: "sqmm", label: "mm²"},
        "mm2", {dim: "L2", factor: 0.000001, name: "sqmm", label: "mm²"},
        "mm²", {dim: "L2", factor: 0.000001, name: "sqmm", label: "mm²"},
        "sqcm", {dim: "L2", factor: 0.0001, name: "sqcm", label: "cm²"},
        "cm2", {dim: "L2", factor: 0.0001, name: "sqcm", label: "cm²"},
        "cm²", {dim: "L2", factor: 0.0001, name: "sqcm", label: "cm²"},
        "sqft", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "sq ft", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "sft", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "ft2", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "ft²", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "square feet", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "square foot", {dim: "L2", factor: 0.09290304, name: "sqft", label: "sq ft"},
        "sqyd", {dim: "L2", factor: 0.83612736, name: "sqyd", label: "sq yd"},
        "sq yd", {dim: "L2", factor: 0.83612736, name: "sqyd", label: "sq yd"},
        "yd2", {dim: "L2", factor: 0.83612736, name: "sqyd", label: "sq yd"},
        "yd²", {dim: "L2", factor: 0.83612736, name: "sqyd", label: "sq yd"},
        "square yard", {dim: "L2", factor: 0.83612736, name: "sqyd", label: "sq yd"},
        "square yards", {dim: "L2", factor: 0.83612736, name: "sqyd", label: "sq yd"},
        "gaj", {dim: "L2", factor: 0.83612736, name: "gaj", label: "Gaj (sq yd)"},
        "gaz", {dim: "L2", factor: 0.83612736, name: "gaj", label: "Gaj (sq yd)"},
        "गज", {dim: "L2", factor: 0.83612736, name: "gaj", label: "Gaj (sq yd)"},
        "acre", {dim: "L2", factor: 4046.8564224, name: "acre", label: "acre"},
        "acres", {dim: "L2", factor: 4046.8564224, name: "acre", label: "acre"},
        "hectare", {dim: "L2", factor: 10000.0, name: "hectare", label: "ha"},
        "hectares", {dim: "L2", factor: 10000.0, name: "hectare", label: "ha"},
        "ha", {dim: "L2", factor: 10000.0, name: "hectare", label: "ha"},
        "guntha", {dim: "L2", factor: 101.17141056, name: "guntha", label: "Guntha"},
        "gunta", {dim: "L2", factor: 101.17141056, name: "guntha", label: "Guntha"},
        "गुंठा", {dim: "L2", factor: 101.17141056, name: "guntha", label: "Guntha"},
        "bigha", {dim: "L2", factor: 770.0, name: "bigha", label: "Bigha (Uttarakhand 770 m²)"},
        "beegah", {dim: "L2", factor: 770.0, name: "bigha", label: "Bigha (Uttarakhand 770 m²)"},
        "बीघा", {dim: "L2", factor: 770.0, name: "bigha", label: "Bigha (Uttarakhand 770 m²)"},
        "nali", {dim: "L2", factor: 38.5, name: "nali", label: "Nali (Uttarakhand 38.5 m²)"},
        "naali", {dim: "L2", factor: 38.5, name: "nali", label: "Nali (Uttarakhand 38.5 m²)"},
        "नाली", {dim: "L2", factor: 38.5, name: "nali", label: "Nali (Uttarakhand 38.5 m²)"},
        "katha", {dim: "L2", factor: 66.89, name: "katha", label: "Katha"},
        "कट्ठा", {dim: "L2", factor: 66.89, name: "katha", label: "Katha"},
        "brass_area", {dim: "L2", factor: 9.290304, name: "brass_area", label: "Brass (100 sq ft)"},

        ; --- VOLUME (Base Unit: cubic metre 'cum' / 'm3') ---
        "cum", {dim: "L3", factor: 1.0, name: "cum", label: "m³"},
        "cu m", {dim: "L3", factor: 1.0, name: "cum", label: "m³"},
        "m3", {dim: "L3", factor: 1.0, name: "cum", label: "m³"},
        "m³", {dim: "L3", factor: 1.0, name: "cum", label: "m³"},
        "cubic meter", {dim: "L3", factor: 1.0, name: "cum", label: "m³"},
        "cubic metre", {dim: "L3", factor: 1.0, name: "cum", label: "m³"},
        "cft", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "cuft", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "cu ft", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "ft3", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "ft³", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "cmm", {dim: "L3", factor: 0.000000001, name: "cmm", label: "mm³"},
        "mm3", {dim: "L3", factor: 0.000000001, name: "cmm", label: "mm³"},
        "mm³", {dim: "L3", factor: 0.000000001, name: "cmm", label: "mm³"},
        "cubic feet", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "cubic foot", {dim: "L3", factor: 0.028316846592, name: "cft", label: "cft"},
        "cuyd", {dim: "L3", factor: 0.764554857984, name: "cuyd", label: "cu yd"},
        "cu yd", {dim: "L3", factor: 0.764554857984, name: "cuyd", label: "cu yd"},
        "yd3", {dim: "L3", factor: 0.764554857984, name: "cuyd", label: "cu yd"},
        "yd³", {dim: "L3", factor: 0.764554857984, name: "cuyd", label: "cu yd"},
        "cubic yard", {dim: "L3", factor: 0.764554857984, name: "cuyd", label: "cu yd"},
        "litre", {dim: "L3", factor: 0.001, name: "litre", label: "L"},
        "liter", {dim: "L3", factor: 0.001, name: "litre", label: "L"},
        "ltr", {dim: "L3", factor: 0.001, name: "litre", label: "L"},
        "ltrs", {dim: "L3", factor: 0.001, name: "litre", label: "L"},
        "l", {dim: "L3", factor: 0.001, name: "litre", label: "L"},
        "लीटर", {dim: "L3", factor: 0.001, name: "litre", label: "L"},
        "ml", {dim: "L3", factor: 0.000001, name: "ml", label: "mL"},
        "millilitre", {dim: "L3", factor: 0.000001, name: "ml", label: "mL"},
        "gallon", {dim: "L3", factor: 0.003785411784, name: "gallon", label: "gal (US)"},
        "gal", {dim: "L3", factor: 0.003785411784, name: "gallon", label: "gal (US)"},
        "cuin", {dim: "L3", factor: 0.000016387064, name: "cuin", label: "cu in"},
        "in3", {dim: "L3", factor: 0.000016387064, name: "cuin", label: "cu in"},
        "in³", {dim: "L3", factor: 0.000016387064, name: "cuin", label: "cu in"},
        "brass", {dim: "L3", factor: 2.8316846592, name: "brass_vol", label: "Brass (100 cft)"},
        "brass_vol", {dim: "L3", factor: 2.8316846592, name: "brass_vol", label: "Brass (100 cft)"},

        ; --- WEIGHT / MASS (Base Unit: kg) ---
        "kg", {dim: "M", factor: 1.0, name: "kg", label: "kg"},
        "kilo", {dim: "M", factor: 1.0, name: "kg", label: "kg"},
        "kilogram", {dim: "M", factor: 1.0, name: "kg", label: "kg"},
        "kilograms", {dim: "M", factor: 1.0, name: "kg", label: "kg"},
        "kgs", {dim: "M", factor: 1.0, name: "kg", label: "kg"},
        "किलो", {dim: "M", factor: 1.0, name: "kg", label: "kg"},
        "g", {dim: "M", factor: 0.001, name: "g", label: "g"},
        "gram", {dim: "M", factor: 0.001, name: "g", label: "g"},
        "grams", {dim: "M", factor: 0.001, name: "g", label: "g"},
        "gm", {dim: "M", factor: 0.001, name: "g", label: "g"},
        "gms", {dim: "M", factor: 0.001, name: "g", label: "g"},
        "quintal", {dim: "M", factor: 100.0, name: "quintal", label: "quintal"},
        "qtl", {dim: "M", factor: 100.0, name: "quintal", label: "quintal"},
        "quintals", {dim: "M", factor: 100.0, name: "quintal", label: "quintal"},
        "क्विंटल", {dim: "M", factor: 100.0, name: "quintal", label: "quintal"},
        "tonne", {dim: "M", factor: 1000.0, name: "tonne", label: "tonne"},
        "ton", {dim: "M", factor: 1000.0, name: "tonne", label: "tonne"},
        "tonnes", {dim: "M", factor: 1000.0, name: "tonne", label: "tonne"},
        "tons", {dim: "M", factor: 1000.0, name: "tonne", label: "tonne"},
        "mt", {dim: "M", factor: 1000.0, name: "tonne", label: "MT"},
        "metric ton", {dim: "M", factor: 1000.0, name: "tonne", label: "MT"},
        "टन", {dim: "M", factor: 1000.0, name: "tonne", label: "tonne"},
        "lb", {dim: "M", factor: 0.45359237, name: "lb", label: "lb"},
        "lbs", {dim: "M", factor: 0.45359237, name: "lb", label: "lb"},
        "pound", {dim: "M", factor: 0.45359237, name: "lb", label: "lb"},
        "pounds", {dim: "M", factor: 0.45359237, name: "lb", label: "lb"},
        "bag", {dim: "M", factor: 50.0, name: "bag", label: "Bags (50kg)"},
        "bags", {dim: "M", factor: 50.0, name: "bag", label: "Bags (50kg)"},
        "cement bag", {dim: "M", factor: 50.0, name: "bag", label: "Bags (50kg)"},

        ; --- FORCE (Base Unit: Newton 'N') ---
        "n", {dim: "F", factor: 1.0, name: "n", label: "N"},
        "newton", {dim: "F", factor: 1.0, name: "n", label: "N"},
        "newtons", {dim: "F", factor: 1.0, name: "n", label: "N"},
        "kn", {dim: "F", factor: 1000.0, name: "kn", label: "kN"},
        "kilonewton", {dim: "F", factor: 1000.0, name: "kn", label: "kN"},
        "kilonewtons", {dim: "F", factor: 1000.0, name: "kn", label: "kN"},
        "kgf", {dim: "F", factor: 9.80665, name: "kgf", label: "kgf"},
        "tonne-force", {dim: "F", factor: 9806.65, name: "tonne-force", label: "tonne-force"},
        "ton-force", {dim: "F", factor: 9806.65, name: "tonne-force", label: "tonne-force"},
        "ton_force", {dim: "F", factor: 9806.65, name: "tonne-force", label: "tonne-force"},
        "ton force", {dim: "F", factor: 9806.65, name: "tonne-force", label: "tonne-force"},
        "tf", {dim: "F", factor: 9806.65, name: "tonne-force", label: "tonne-force"},
        "kip", {dim: "F", factor: 4448.2216, name: "kip", label: "kip"},
        "kips", {dim: "F", factor: 4448.2216, name: "kip", label: "kip"},

        ; --- PRESSURE / STRESS / STRENGTH (Base Unit: Pascal 'Pa') ---
        "pa", {dim: "P", factor: 1.0, name: "pa", label: "Pa"},
        "pascal", {dim: "P", factor: 1.0, name: "pa", label: "Pa"},
        "kpa", {dim: "P", factor: 1000.0, name: "kpa", label: "kPa"},
        "kilopascal", {dim: "P", factor: 1000.0, name: "kpa", label: "kPa"},
        "mpa", {dim: "P", factor: 1000000.0, name: "mpa", label: "MPa"},
        "megapascal", {dim: "P", factor: 1000000.0, name: "mpa", label: "MPa"},
        "n/mm2", {dim: "P", factor: 1000000.0, name: "n/mm2", label: "N/mm²"},
        "n/mm²", {dim: "P", factor: 1000000.0, name: "n/mm2", label: "N/mm²"},
        "n/sqmm", {dim: "P", factor: 1000000.0, name: "n/mm2", label: "N/mm²"},
        "kn/m2", {dim: "P", factor: 1000.0, name: "kn/m2", label: "kN/m²"},
        "kn/m²", {dim: "P", factor: 1000.0, name: "kn/m2", label: "kN/m²"},
        "kn/sqm", {dim: "P", factor: 1000.0, name: "kn/m2", label: "kN/m²"},
        "bar", {dim: "P", factor: 100000.0, name: "bar", label: "bar"},
        "bars", {dim: "P", factor: 100000.0, name: "bar", label: "bar"},
        "kg/cm2", {dim: "P", factor: 98066.5, name: "kg/cm2", label: "kg/cm²"},
        "kg/cm²", {dim: "P", factor: 98066.5, name: "kg/cm2", label: "kg/cm²"},
        "kgf/cm2", {dim: "P", factor: 98066.5, name: "kg/cm2", label: "kg/cm²"},
        "kgf/cm²", {dim: "P", factor: 98066.5, name: "kg/cm2", label: "kg/cm²"},
        "psi", {dim: "P", factor: 6894.757293, name: "psi", label: "psi"},
        "psf", {dim: "P", factor: 47.8802589, name: "psf", label: "psf"},

        ; --- DENSITY (Base Unit: kg/m3) ---
        "kg/m3", {dim: "D", factor: 1.0, name: "kg/m3", label: "kg/m³"},
        "kg/m³", {dim: "D", factor: 1.0, name: "kg/m3", label: "kg/m³"},
        "kg/cum", {dim: "D", factor: 1.0, name: "kg/m3", label: "kg/m³"},
        "tonne/m3", {dim: "D", factor: 1000.0, name: "tonne/m3", label: "tonne/m³"},
        "tonne/cum", {dim: "D", factor: 1000.0, name: "tonne/m3", label: "tonne/m³"},
        "ton/cum", {dim: "D", factor: 1000.0, name: "tonne/m3", label: "tonne/m³"},
        "t/m3", {dim: "D", factor: 1000.0, name: "tonne/m3", label: "tonne/m³"},
        "g/cm3", {dim: "D", factor: 1000.0, name: "g/cm3", label: "g/cm³"},
        "g/cc", {dim: "D", factor: 1000.0, name: "g/cm3", label: "g/cm³"},
        "gm/cc", {dim: "D", factor: 1000.0, name: "g/cm3", label: "g/cm³"},
        "kg/ft3", {dim: "D", factor: 35.3146667, name: "kg/ft3", label: "kg/ft³"},
        "kg/cft", {dim: "D", factor: 35.3146667, name: "kg/cft", label: "kg/cft"},
        "lb/cft", {dim: "D", factor: 16.018463, name: "lb/cft", label: "lb/cu ft"},
        "lb/ft3", {dim: "D", factor: 16.018463, name: "lb/cft", label: "lb/cu ft"},
        "lb/ft³", {dim: "D", factor: 16.018463, name: "lb/cft", label: "lb/cu ft"},
        "pcf", {dim: "D", factor: 16.018463, name: "lb/cft", label: "lb/cu ft"},

        ; --- FLOW (Base Unit: Litres per second 'L/s') ---
        "l/s", {dim: "Q", factor: 1.0, name: "l/s", label: "L/s"},
        "lps", {dim: "Q", factor: 1.0, name: "l/s", label: "L/s"},
        "litre/sec", {dim: "Q", factor: 1.0, name: "l/s", label: "L/s"},
        "litre per sec", {dim: "Q", factor: 1.0, name: "l/s", label: "L/s"},
        "l/min", {dim: "Q", factor: 1/60, name: "l/min", label: "L/min"},
        "lpm", {dim: "Q", factor: 1/60, name: "l/min", label: "L/min"},
        "litre/min", {dim: "Q", factor: 1/60, name: "l/min", label: "L/min"},
        "m3/hr", {dim: "Q", factor: 1000/3600, name: "m3/hr", label: "m³/hr"},
        "cum/hr", {dim: "Q", factor: 1000/3600, name: "m3/hr", label: "m³/hr"},
        "m³/hr", {dim: "Q", factor: 1000/3600, name: "m3/hr", label: "m³/hr"},
        "m3/min", {dim: "Q", factor: 1000/60, name: "m3/min", label: "m³/min"},
        "cum/min", {dim: "Q", factor: 1000/60, name: "m3/min", label: "m³/min"},
        "m3/s", {dim: "Q", factor: 1000.0, name: "m3/s", label: "m³/s"},
        "cum/s", {dim: "Q", factor: 1000.0, name: "m3/s", label: "m³/s"},
        "cum/sec", {dim: "Q", factor: 1000.0, name: "m3/s", label: "m³/s"},
        "cfs", {dim: "Q", factor: 28.316846592, name: "cfs", label: "cfs"},
        "cusec", {dim: "Q", factor: 28.316846592, name: "cfs", label: "cusec"},
        "cusecs", {dim: "Q", factor: 28.316846592, name: "cfs", label: "cusec"},
        "cfm", {dim: "Q", factor: 0.471947443, name: "cfm", label: "CFM"},
        "gpm", {dim: "Q", factor: 0.0630901964, name: "gpm", label: "gpm"},

        ; --- ANGLE (Base Unit: Degree 'deg') ---
        "degree", {dim: "A", factor: 1.0, name: "degree", label: "°"},
        "degrees", {dim: "A", factor: 1.0, name: "degree", label: "°"},
        "deg", {dim: "A", factor: 1.0, name: "degree", label: "°"},
        "°", {dim: "A", factor: 1.0, name: "degree", label: "°"},
        "rad", {dim: "A", factor: 57.29577951308232, name: "rad", label: "rad"},
        "radian", {dim: "A", factor: 57.29577951308232, name: "rad", label: "rad"},
        "radians", {dim: "A", factor: 57.29577951308232, name: "rad", label: "rad"}
    )

    ; ------------------------------------------------------------------------------------------------------------------
    ; 2. Unit Resolution Helpers
    ; ------------------------------------------------------------------------------------------------------------------
    static ResolveUnit(unitStr) {
        clean := StrLower(Trim(unitStr, " .,;:"))
        if (this.UnitRegistry.Has(clean))
            return this.UnitRegistry[clean]

        cleanPlural := RegExReplace(clean, "s$", "")
        if (this.UnitRegistry.Has(cleanPlural))
            return this.UnitRegistry[cleanPlural]

        return ""
    }

    static GetDefaultTargetUnit(dim) {
        defaults := Map(
            "L", "ft",
            "L2", "sqft",
            "L3", "cft",
            "M", "tonne",
            "F", "tonne-force",
            "P", "psi",
            "D", "kg/m3",
            "Q", "lpm",
            "A", "rad"
        )
        return defaults.Has(dim) ? defaults[dim] : "m"
    }

    ; ------------------------------------------------------------------------------------------------------------------
    ; 3. Pure Direct 1D Same-Dimension Conversion
    ; ------------------------------------------------------------------------------------------------------------------
    static EvaluateDirect(val, srcUnit, targetUnit) {
        baseSI := val * srcUnit.factor
        converted := baseSI / targetUnit.factor
        dimNames := Map("L","Length", "L2","Area", "L3","Volume", "M","Mass/Weight", "F","Force", "P","Pressure", "D","Density", "Q","Flow", "A","Angle")
        catName := dimNames.Has(srcUnit.dim) ? ("Direct Conversion (" . dimNames[srcUnit.dim] . ")") : "Direct Conversion"

        return {
            success: true,
            category: catName,
            displayExpr: Format("{1} {2} -> {3}", val, srcUnit.label, targetUnit.label),
            resultStr: Format("{:0.3f} {}", converted, targetUnit.label),
            val: converted,
            unit: targetUnit.label
        }
    }
}
