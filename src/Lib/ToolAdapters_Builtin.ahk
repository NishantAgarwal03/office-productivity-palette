; ======================================================================================================================
; Module: ToolAdapters_Builtin.ahk - Symbiotic Tool Adapters for Workflow Pipeline
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Symbiotic Delegation (Zero Duplication): Does NOT re-implement parsing, regex, or math.
;    Directly delegates to NumberParser, Actions_Finance, Actions_Extraction, Actions_DateTime, Actions_Text.
; 2. Pure Compute Invariant: Adapters perform pure data transformation with zero clipboard or UI side effects.
; 3. Explicit Typed Contracts: Every adapted tool produces strictly typed named outputs.
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterBuiltinToolAdapters() {
    ; ==================================================================================================================
    ; 1. Finance & Math Adapters
    ; ==================================================================================================================

    ; --- Parse Number ---
    ToolCatalog.Register({
        id: "parse_number",
        version: 1,
        label: "Parse Number / Amount",
        category: "Finance & Math",
        description: "Parses text string into validated numeric scalar (supports Indian notation, lakh, cr, commas)",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [],
        outputs: [
            {name: "number", type: "number", primary: true, label: "Parsed Number"},
            {name: "text", type: "text", label: "Number Text"},
            {name: "is_valid", type: "boolean", label: "Is Valid Number"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteParseNumber(inputs, settings)
    })

    ; --- Format Indian Currency ---
    ToolCatalog.Register({
        id: "format_currency_inr",
        version: 1,
        label: "Format Indian Currency (₹)",
        category: "Finance & Math",
        description: "Formats numeric amount with Indian grouped commas and rupee symbol",
        inputs: [
            {name: "amount", type: "number", required: true, label: "Amount"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Formatted Currency"},
            {name: "result", type: "text", label: "Formatted Currency"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteFormatCurrencyInr(inputs, settings)
    })

    ; --- Normal Forward GST (Base + Tax) ---
    ToolCatalog.Register({
        id: "normal_gst",
        version: 1,
        label: "Normal Forward GST",
        category: "Finance & Math",
        description: "Calculates standard forward GST on base amount (Base + GST% -> CGST + SGST + Total)",
        inputs: [
            {name: "amount", type: "number", required: true, label: "Taxable Base Amount"}
        ],
        settings: [
            {name: "rate", type: "number", default: 18, options: [5, 12, 18, 28], label: "GST Rate %"}
        ],
        outputs: [
            {name: "total", type: "number", primary: true, label: "Total Invoice Amount"},
            {name: "base", type: "number", label: "Taxable Base"},
            {name: "gst", type: "number", label: "Total GST Amount"},
            {name: "cgst", type: "number", label: "CGST Amount"},
            {name: "sgst", type: "number", label: "SGST Amount"},
            {name: "summary", type: "text", label: "Formatted GST Summary"},
            {name: "text", type: "text", label: "Default Text Output"},
            {name: "record", type: "record", label: "Complete GST Record"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteNormalGst(inputs, settings)
    })

    ; --- Reverse GST ---
    ToolCatalog.Register({
        id: "reverse_gst",
        version: 1,
        label: "Reverse GST Calculator",
        category: "Finance & Math",
        description: "Extracts Taxable Base and GST from tax-inclusive total amount",
        inputs: [
            {name: "amount", type: "number", required: true, label: "Total Inclusive Amount"}
        ],
        settings: [
            {name: "rate", type: "number", default: 18, options: [5, 12, 18, 28], label: "GST Rate %"}
        ],
        outputs: [
            {name: "base", type: "number", primary: true, label: "Taxable Base"},
            {name: "original", type: "number", label: "Original Inclusive Amount"},
            {name: "gst", type: "number", label: "Total GST Amount"},
            {name: "cgst", type: "number", label: "CGST Amount"},
            {name: "sgst", type: "number", label: "SGST Amount"},
            {name: "summary", type: "text", label: "Formatted GST Breakdown"},
            {name: "text", type: "text", label: "Default Text Output"},
            {name: "record", type: "record", label: "Complete GST Record"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteReverseGst(inputs, settings)
    })

    ; --- Number to Words (Indian Rupees) ---
    ToolCatalog.Register({
        id: "number_to_words",
        version: 1,
        label: "Number to Words (Indian Rupees)",
        category: "Finance & Math",
        description: "Converts numeric amount into formal Indian English words (Rupees ... Only)",
        inputs: [
            {name: "number", type: "number", required: true, label: "Amount"}
        ],
        settings: [],
        outputs: [
            {name: "words", type: "text", primary: true, label: "Amount in Words"},
            {name: "text", type: "text", label: "Default Text Output"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteNumberToWords(inputs, settings)
    })

    ; --- Sum Numbers ---
    ToolCatalog.Register({
        id: "sum_numbers",
        version: 1,
        label: "Sum Numbers",
        category: "Finance & Math",
        description: "Calculates mathematical sum of all numeric items",
        inputs: [
            {name: "items", type: "items<number>", required: true, label: "Numeric Items"}
        ],
        settings: [],
        outputs: [
            {name: "sum", type: "number", primary: true, label: "Total Sum"},
            {name: "count", type: "number", label: "Item Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteSumNumbers(inputs, settings)
    })

    ; --- Average Numbers ---
    ToolCatalog.Register({
        id: "average_numbers",
        version: 1,
        label: "Average Numbers",
        category: "Finance & Math",
        description: "Calculates arithmetic mean of numeric items",
        inputs: [
            {name: "items", type: "items<number>", required: true, label: "Numeric Items"}
        ],
        settings: [],
        outputs: [
            {name: "average", type: "number", primary: true, label: "Average"},
            {name: "count", type: "number", label: "Item Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteAverageNumbers(inputs, settings)
    })

    ; --- Evaluate Math Expression ---
    ToolCatalog.Register({
        id: "math_evaluate",
        version: 1,
        label: "Evaluate Math Expression",
        category: "Finance & Math",
        description: "Computes mathematical expressions and formulas with Indian scale words (lakh, cr)",
        inputs: [
            {name: "text", type: "text", required: true, label: "Formula / Expression"}
        ],
        settings: [],
        outputs: [
            {name: "result", type: "number", primary: true, label: "Evaluated Result"},
            {name: "number", type: "number", label: "Evaluated Number"},
            {name: "text", type: "text", label: "Result Text"},
            {name: "display", type: "text", label: "Display Formula"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteMathEvaluate(inputs, settings)
    })

    ; --- Percentage Change & Growth ---
    ToolCatalog.Register({
        id: "math_percentage_change",
        version: 1,
        label: "Percentage Change Calculator",
        category: "Finance & Math",
        description: "Calculates relative percentage change and symmetric difference between two numbers",
        inputs: [
            {name: "text", type: "text", required: true, label: "Text with Two Numbers"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Calculation Summary"},
            {name: "relative_change", type: "number", label: "Relative Change %"},
            {name: "symmetric_change", type: "number", label: "Symmetric Difference %"},
            {name: "summary", type: "text", label: "Calculation Summary"},
            {name: "result", type: "text", label: "Calculation Summary"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecutePercentageChange(inputs, settings)
    })

    ; ==================================================================================================================
    ; 2. Text Extraction Adapters
    ; ==================================================================================================================

    ; --- Extract All Email Addresses ---
    ToolCatalog.Register({
        id: "extract_emails",
        version: 1,
        label: "Extract All Email Addresses",
        category: "Extraction",
        description: "Scrapes and extracts all unique email addresses from raw text",
        inputs: [
            {name: "text", type: "text", required: true, label: "Raw Text"}
        ],
        settings: [],
        outputs: [
            {name: "items", type: "items<text>", primary: true, label: "Extracted Emails"},
            {name: "count", type: "number", label: "Email Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractEmails(inputs, settings)
    })

    ; --- Extract URLs ---
    ToolCatalog.Register({
        id: "extract_urls",
        version: 1,
        label: "Extract All Web URLs",
        category: "Extraction",
        description: "Scrapes and extracts all web URLs and links from raw text",
        inputs: [
            {name: "text", type: "text", required: true, label: "Raw Text"}
        ],
        settings: [],
        outputs: [
            {name: "items", type: "items<text>", primary: true, label: "Extracted URLs"},
            {name: "count", type: "number", label: "URL Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractUrls(inputs, settings)
    })

    ; --- Extract Phone Numbers ---
    ToolCatalog.Register({
        id: "extract_phones",
        version: 1,
        label: "Extract Phone Numbers",
        category: "Extraction",
        description: "Extracts Indian mobile and STD telephone numbers",
        inputs: [
            {name: "text", type: "text", required: true, label: "Raw Text"}
        ],
        settings: [],
        outputs: [
            {name: "items", type: "items<text>", primary: true, label: "Extracted Phones"},
            {name: "count", type: "number", label: "Phone Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractPhones(inputs, settings)
    })

    ; --- Extract GSTINs ---
    ToolCatalog.Register({
        id: "extract_gstin",
        version: 1,
        label: "Extract Indian GSTINs",
        category: "Extraction",
        description: "Extracts 15-character GST Identification Numbers",
        inputs: [
            {name: "text", type: "text", required: true, label: "Raw Text"}
        ],
        settings: [],
        outputs: [
            {name: "items", type: "items<text>", primary: true, label: "Extracted GSTINs"},
            {name: "count", type: "number", label: "GSTIN Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractGstin(inputs, settings)
    })

    ; --- Extract Dates ---
    ToolCatalog.Register({
        id: "extract_dates",
        version: 1,
        label: "Extract Dates from Text",
        category: "Extraction",
        description: "Extracts all calendar dates from text",
        inputs: [
            {name: "text", type: "text", required: true, label: "Raw Text"}
        ],
        settings: [],
        outputs: [
            {name: "items", type: "items<text>", primary: true, label: "Extracted Dates"},
            {name: "count", type: "number", label: "Date Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractDates(inputs, settings)
    })

    ; --- Extract PAN Numbers ---
    ToolCatalog.Register({
        id: "extract_pan",
        version: 1,
        label: "Extract Indian PAN Numbers",
        category: "Extraction",
        description: "Extracts 10-character Permanent Account Numbers (PAN)",
        inputs: [
            {name: "text", type: "text", required: true, label: "Raw Text"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "PAN Text"},
            {name: "result", type: "text", label: "PAN Text"},
            {name: "items", type: "items<text>", label: "Extracted PANs"},
            {name: "count", type: "number", label: "PAN Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractPan(inputs, settings)
    })

    ; ==================================================================================================================
    ; 3. Date / Time Adapters
    ; ==================================================================================================================

    ; --- Today's Date Generator ---
    ToolCatalog.Register({
        id: "date_today",
        version: 1,
        label: "Today's Date",
        category: "Date / Time",
        description: "Generates formatted current date string (valid starting step with no required input)",
        inputs: [],
        settings: [
            {name: "format", type: "text", default: "yyyy-MM-dd", options: ["yyyy-MM-dd", "dd-MMM-yyyy", "dd/MM/yyyy", "MMMM d, yyyy"], label: "Date Format"}
        ],
        outputs: [
            {name: "date", type: "text", primary: true, label: "Formatted Date"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteDateToday(inputs, settings)
    })

    ; --- Convert Date Format (Universal Indian Standard) ---
    ToolCatalog.Register({
        id: "date_convert_format",
        version: 1,
        label: "Convert Date Format",
        category: "Date / Time",
        description: "Converts Indian or standard dates into one of the 9 canonical date formats",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text or Date"}
        ],
        settings: [
            {name: "format_id", type: "number", default: 1, options: [1, 2, 3, 4, 5, 6, 7, 8, 9], label: "Target Format ID (1-9)"}
        ],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Converted Text Output"},
            {name: "result", type: "text", label: "Converted Date or Text"},
            {name: "format_name", type: "text", label: "Target Format Name"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteConvertDateFormat(inputs, settings)
    })

    ; --- Date Difference & Working Days ---
    ToolCatalog.Register({
        id: "date_difference",
        version: 1,
        label: "Date Difference & Working Days",
        category: "Date / Time",
        description: "Calculates total calendar days and working days (Mon-Fri) between two dates",
        inputs: [
            {name: "text", type: "text", required: true, label: "Text with Two Dates"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Difference Report"},
            {name: "summary", type: "text", label: "Difference Report"},
            {name: "result", type: "text", label: "Difference Report"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteDateDifference(inputs, settings)
    })

    ; --- Indian Financial Year & Quarter ---
    ToolCatalog.Register({
        id: "date_financial_year",
        version: 1,
        label: "Indian Financial Year & Quarter",
        category: "Date / Time",
        description: "Resolves date into Indian Financial Year and Quarter (e.g. FY 2026-27 (Q2))",
        inputs: [
            {name: "text", type: "text", required: true, label: "Date Text"}
        ],
        settings: [],
        outputs: [
            {name: "fy", type: "text", primary: true, label: "Fiscal Year and Quarter"},
            {name: "result", type: "text", label: "Fiscal Year and Quarter"},
            {name: "text", type: "text", label: "Fiscal Year and Quarter"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteFinancialYear(inputs, settings)
    })

    ; ==================================================================================================================
    ; 4. Text Transformation Adapters
    ; ==================================================================================================================

    ; --- Clean Plain Text ---
    ToolCatalog.Register({
        id: "clean_whitespace",
        version: 1,
        label: "Clean Plain Text",
        category: "Text",
        description: "Normalizes Unicode whitespace, line endings, and extra spaces",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Cleaned Text"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCleanText(inputs, settings)
    })

    ; --- Unwrap Text Paragraphs ---
    ToolCatalog.Register({
        id: "clean_text_unwrap",
        version: 1,
        label: "Unwrap Text Paragraphs",
        category: "Text",
        description: "Unwraps hard line breaks within paragraphs into single flowing lines",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Unwrapped Text"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCleanTextUnwrap(inputs, settings)
    })

    ; --- Change Text Case (Consolidated) ---
    ToolCatalog.Register({
        id: "convert_case",
        version: 1,
        label: "Change Text Case",
        category: "Text",
        description: "Converts text case (UPPERCASE, lowercase, Title Case, Sentence case, snake_case, kebab-case, camelCase)",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [
            {name: "case_mode", type: "text", default: "upper", options: ["upper", "lower", "title", "sentence", "snake", "kebab", "camel"], label: "Target Case"}
        ],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Converted Text"},
            {name: "result", type: "text", label: "Converted Text"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteConvertCase(inputs, settings)
    })

    ; --- Format Lines as List (Consolidated) ---
    ToolCatalog.Register({
        id: "format_list",
        version: 1,
        label: "Format Lines as List",
        category: "Text",
        description: "Formats each line as a checklist, bullet list, numbered list, or SQL IN clause",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [
            {name: "list_type", type: "text", default: "checklist", options: ["checklist", "bullet", "numbered", "sql"], label: "List Type"}
        ],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Formatted List"},
            {name: "result", type: "text", label: "Formatted List"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteFormatList(inputs, settings)
    })

    ; --- Word & Character Statistics ---
    ToolCatalog.Register({
        id: "text_statistics",
        version: 1,
        label: "Count Words & Statistics",
        category: "Text",
        description: "Calculates character, word, line counts, and summary statistics",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Statistics Summary"},
            {name: "summary", type: "text", label: "Statistics Summary"},
            {name: "result", type: "text", label: "Statistics Summary"},
            {name: "words", type: "number", label: "Word Count"},
            {name: "chars", type: "number", label: "Character Count"},
            {name: "chars_no_spaces", type: "number", label: "Character Count (No Spaces)"},
            {name: "lines", type: "number", label: "Line Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteTextStatistics(inputs, settings)
    })

    ; ==================================================================================================================
    ; 5. File Reference Metadata Adapters (Strictly Zero File Reading)
    ; ==================================================================================================================

    ; --- File Metadata ---
    ToolCatalog.Register({
        id: "file_metadata",
        version: 1,
        label: "Extract File Metadata",
        category: "Files",
        description: "Extracts path, filename, stem, extension, and folder without reading file contents",
        inputs: [
            {name: "file", type: "filereference", required: true, label: "File Reference"}
        ],
        settings: [],
        outputs: [
            {name: "record", type: "record", primary: true, label: "Metadata Record"},
            {name: "path", type: "text", label: "Full Path"},
            {name: "name", type: "text", label: "Filename"},
            {name: "stem", type: "text", label: "Filename Stem"},
            {name: "extension", type: "text", label: "Extension"},
            {name: "folder", type: "text", label: "Folder Path"},
            {name: "index", type: "number", label: "File Index"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteFileMetadata(inputs, settings)
    })

    ; ==================================================================================================================
    ; 6. Civil Engineering Adapters
    ; ==================================================================================================================

    ; --- Civil Unit Converter ---
    ToolCatalog.Register({
        id: "civil_unit_convert",
        version: 1,
        label: "Convert Civil Engineering Units",
        category: "🏗️ Civil",
        description: "Converts length, area, volume, and weight between Metric, Imperial, and Indian units",
        inputs: [
            {name: "text", type: "text", required: true, label: "Value and Units (e.g. '100 sqft to sqm')"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Conversion Result"},
            {name: "summary", type: "text", label: "Conversion Result"},
            {name: "result", type: "text", label: "Conversion Result"},
            {name: "value", type: "number", label: "Converted Number"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCivilUnitConvert(inputs, settings)
    })

    ; --- Civil Pythagoras & 3-4-5 Triangle Solver ---
    ToolCatalog.Register({
        id: "civil_pythagoras",
        version: 1,
        label: "Pythagoras & 3-4-5 Triangle Solver",
        category: "🏗️ Civil",
        description: "Calculates hypotenuse, missing leg, or validates right-angle squareness (e.g. '3m 4m')",
        inputs: [
            {name: "text", type: "text", required: true, label: "Dimensions (e.g. '20ft 30ft' or '8m 10m 13.2m')"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", primary: true, label: "Solution Report"},
            {name: "summary", type: "text", label: "Solution Report"},
            {name: "result", type: "text", label: "Solution Report"},
            {name: "value", type: "number", label: "Calculated Dimension"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCivilPythagoras(inputs, settings)
    })
}

class ToolAdapters {
    ; --- Finance & Math Handlers ---
    static ExecuteParseNumber(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        p := ParseNumberOrCurrency(txt)
        if (p.isValid) {
            val := (Round(p.value, 6) = Round(p.value, 0)) ? Integer(Round(p.value, 0)) : p.value
            res := Map()
            res["number"] := val
            res["text"] := String(val)
            res["is_valid"] := true
            return res
        }

        cleanMach := CleanToMachineNumber(txt)
        if (cleanMach != "" && IsNumber(cleanMach)) {
            valNum := Number(cleanMach)
            val := (Round(valNum, 6) = Round(valNum, 0)) ? Integer(Round(valNum, 0)) : valNum
            res := Map()
            res["number"] := val
            res["text"] := String(val)
            res["is_valid"] := true
            return res
        }

        ; In multiline input, check line-by-line for primary standalone number or currency
        lines := StrSplit(txt, ["`r`n", "`n", "`r"])
        for line in lines {
            lineTrim := Trim(line)
            if (lineTrim == "" || InStr(lineTrim, "@"))
                continue
            ; Skip date-only lines (e.g. 15/08/2026)
            if RegExMatch(lineTrim, "^\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}$")
                continue
            pLine := ParseNumberOrCurrency(lineTrim)
            if (pLine.isValid) {
                val := (Round(pLine.value, 6) = Round(pLine.value, 0)) ? Integer(Round(pLine.value, 0)) : pLine.value
                res := Map()
                res["number"] := val
                res["text"] := String(val)
                res["is_valid"] := true
                return res
            }
        }

        ; In multiline input, check tokens on non-date lines
        for line in lines {
            lineTrim := Trim(line)
            if (lineTrim == "" || InStr(lineTrim, "@"))
                continue
            if RegExMatch(lineTrim, "^\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}$")
                continue
            toks := ExtractNumericTokens(lineTrim)
            if (toks.Length > 0) {
                valNum := toks[1].value
                val := (Round(valNum, 6) = Round(valNum, 0)) ? Integer(Round(valNum, 0)) : valNum
                res := Map()
                res["number"] := val
                res["text"] := String(val)
                res["is_valid"] := true
                return res
            }
        }

        tokens := ExtractNumericTokens(txt)
        if (tokens.Length > 0) {
            valNum := tokens[1].value
            val := (Round(valNum, 6) = Round(valNum, 0)) ? Integer(Round(valNum, 0)) : valNum
            res := Map()
            res["number"] := val
            res["text"] := String(val)
            res["is_valid"] := true
            return res
        }

        throw Error(Format("Parse Number: No numeric value found in '{1}'", SubStr(txt, 1, 60)))
    }

    static ExecuteFormatCurrencyInr(inputs, settings) {
        amt := inputs.Has("amount") ? Float(inputs["amount"]) : 0.0
        res := Map()
        res["text"] := "₹" . FormatIndianCommas(amt)
        return res
    }

    static ExecuteNormalGst(inputs, settings) {
        base := inputs.Has("amount") ? Float(inputs["amount"]) : 0.0
        rate := settings.Has("rate") ? Float(settings["rate"]) : 18.0

        if (rate <= -100 || rate > 500)
            throw Error(Format("Normal GST: Invalid rate '{1}%'", rate))

        gst := Round(base * (rate / 100), 2)
        cgst := Round(gst / 2, 2)
        sgst := Round(gst / 2, 2)
        total := Round(base + gst, 2)

        base := (base = Integer(base)) ? Integer(base) : base
        gst := (gst = Integer(gst)) ? Integer(gst) : gst
        cgst := (cgst = Integer(cgst)) ? Integer(cgst) : cgst
        sgst := (sgst = Integer(sgst)) ? Integer(sgst) : sgst
        total := (total = Integer(total)) ? Integer(total) : total

        rateStr := (Round(rate, 2) = Integer(rate)) ? String(Integer(rate)) : String(rate)
        summary := Format("Base: ₹{} | GST ({}%): ₹{} (CGST: ₹{} | SGST: ₹{}) | Total: ₹{}", 
                          FormatIndianCommas(base), rateStr, FormatIndianCommas(gst), 
                          FormatIndianCommas(cgst), FormatIndianCommas(sgst), FormatIndianCommas(total))

        rec := Map(
            "base", base,
            "gst", gst,
            "cgst", cgst,
            "sgst", sgst,
            "total", total,
            "rate", rate,
            "summary", summary
        )

        res := Map()
        res["base"] := base
        res["gst"] := gst
        res["cgst"] := cgst
        res["sgst"] := sgst
        res["total"] := total
        res["summary"] := summary
        res["text"] := summary
        res["record"] := rec
        return res
    }

    static ExecuteReverseGst(inputs, settings) {
        tot := inputs.Has("amount") ? Float(inputs["amount"]) : 0.0
        rate := settings.Has("rate") ? Float(settings["rate"]) : 18.0

        if (rate <= -100 || rate > 500)
            throw Error(Format("Reverse GST: Invalid rate '{1}%'", rate))

        base := Round(tot / (1 + (rate / 100)), 2)
        gst := Round(tot - base, 2)
        cgst := Round(gst / 2, 2)
        sgst := Round(gst / 2, 2)

        tot := (tot = Integer(tot)) ? Integer(tot) : tot
        base := (base = Integer(base)) ? Integer(base) : base
        gst := (gst = Integer(gst)) ? Integer(gst) : gst
        cgst := (cgst = Integer(cgst)) ? Integer(cgst) : cgst
        sgst := (sgst = Integer(sgst)) ? Integer(sgst) : sgst

        rateStr := (Round(rate, 2) = Integer(rate)) ? String(Integer(rate)) : String(rate)
        summary := Format("Total (Incl. {}% GST): ₹{} | Base: ₹{} | GST: ₹{} (CGST: ₹{} | SGST: ₹{})", 
                          rateStr, FormatIndianCommas(tot), FormatIndianCommas(base), 
                          FormatIndianCommas(gst), FormatIndianCommas(cgst), FormatIndianCommas(sgst))

        rec := Map(
            "original", tot,
            "base", base,
            "gst", gst,
            "cgst", cgst,
            "sgst", sgst,
            "total", tot,
            "rate", rate,
            "summary", summary
        )

        res := Map()
        res["original"] := tot
        res["base"] := base
        res["gst"] := gst
        res["cgst"] := cgst
        res["sgst"] := sgst
        res["summary"] := summary
        res["text"] := summary
        res["record"] := rec
        return res
    }

    static ExecuteNumberToWords(inputs, settings) {
        numVal := inputs.Has("number") ? inputs["number"] : 0
        words := NumberToIndianWords(String(numVal))
        res := Map()
        res["words"] := words
        res["text"] := words
        return res
    }

    static ExecuteSumNumbers(inputs, settings) {
        items := inputs.Has("items") ? inputs["items"] : []
        total := 0.0
        for item in items {
            if IsNumber(item)
                total += Float(item)
        }
        res := Map()
        res["sum"] := total
        res["count"] := items.Length
        return res
    }

    static ExecuteAverageNumbers(inputs, settings) {
        items := inputs.Has("items") ? inputs["items"] : []
        total := 0.0
        validCount := 0
        for item in items {
            if IsNumber(item) {
                total += Float(item)
                validCount++
            }
        }
        avg := (validCount > 0) ? (total / validCount) : 0.0
        res := Map()
        res["average"] := avg
        res["count"] := items.Length
        return res
    }

    ; --- Extraction Handlers ---
    static ExecuteExtractEmails(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        emails := []
        pos := 1
        while RegExMatch(txt, "i)\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b", &m, pos) {
            val := m[0]
            found := false
            for e in emails {
                if (StrLower(e) = StrLower(val)) {
                    found := true
                    break
                }
            }
            if !found
                emails.Push(val)
            pos := m.Pos + m.Len
        }

        res := Map()
        res["items"] := emails
        res["count"] := emails.Length
        return res
    }

    static ExecuteExtractUrls(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        urls := []
        pos := 1
        while RegExMatch(txt, "i)\b(?:https?://|www\.)[^\s<>'`"]+", &m, pos) {
            val := RTrim(m[0], " .,;:!?'`"")
            found := false
            for u in urls {
                if (u = val) {
                    found := true
                    break
                }
            }
            if !found
                urls.Push(val)
            pos := m.Pos + m.Len
        }

        res := Map()
        res["items"] := urls
        res["count"] := urls.Length
        return res
    }

    static ExecuteExtractPhones(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        phones := []
        pos := 1
        while RegExMatch(txt, "(?:\+91[\-\s]?)?[6-9]\d{9}|\b\d{3,5}[\-\s]\d{6,8}\b", &m, pos) {
            val := Trim(m[0])
            found := false
            for p in phones {
                if (p = val) {
                    found := true
                    break
                }
            }
            if !found
                phones.Push(val)
            pos := m.Pos + m.Len
        }

        res := Map()
        res["items"] := phones
        res["count"] := phones.Length
        return res
    }

    static ExecuteExtractGstin(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        gstins := []
        pos := 1
        while RegExMatch(txt, "i)\b\d{2}[a-z]{5}\d{4}[a-z]{1}[a-z\d]{1}[z]{1}[a-z\d]{1}\b", &m, pos) {
            val := StrUpper(m[0])
            found := false
            for g in gstins {
                if (g = val) {
                    found := true
                    break
                }
            }
            if !found
                gstins.Push(val)
            pos := m.Pos + m.Len
        }

        res := Map()
        res["items"] := gstins
        res["count"] := gstins.Length
        return res
    }

    static ExecuteExtractDates(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        dates := []
        pos := 1
        pattern := "\b(?:\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{1,2}[-/\s]+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/\s,]+\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?,?\s*\d{2,4})\b"
        while RegExMatch(txt, "i)" . pattern, &m, pos) {
            raw := Trim(m[0], " .,;:")
            found := false
            for d in dates {
                if (d = raw) {
                    found := true
                    break
                }
            }
            if !found {
                dates.Push(raw)
            }
            pos := m.Pos + m.Len
        }

        res := Map()
        res["items"] := dates
        res["count"] := dates.Length
        return res
    }

    ; --- Date / Time Handlers ---
    static ExecuteDateToday(inputs, settings) {
        fmt := settings.Has("format") ? settings["format"] : "yyyy-MM-dd"
        res := Map()
        res["date"] := FormatTime(A_Now, fmt)
        return res
    }

    static ExecuteConvertDateFormat(inputs, settings) {
        txt := ""
        if (Type(inputs) = "Map") {
            txt := inputs.Has("text") ? String(inputs["text"]) : (inputs.Has("date") ? String(inputs["date"]) : "")
        } else if IsObject(inputs) {
            txt := inputs.HasOwnProp("text") ? String(inputs.text) : (inputs.HasOwnProp("date") ? String(inputs.date) : "")
        }

        targetFmt := 1
        if (Type(settings) = "Map") {
            if settings.Has("format_id")
                targetFmt := Integer(settings["format_id"])
        } else if IsObject(settings) {
            if settings.HasOwnProp("format_id")
                targetFmt := Integer(settings.format_id)
        }

        if (targetFmt < 1 || targetFmt > 9)
            targetFmt := 1

        conv := ""
        if (IsSet(DateFormatConverter)) {
            p := DateFormatConverter.ParseIndianDate(txt)
            if (p.valid) {
                conv := DateFormatConverter.Format(p, targetFmt)
            } else {
                rawDates := ExtractRawDatesList(txt)
                if (rawDates.Length > 0) {
                    conv := txt
                    for dStr in rawDates {
                        subP := DateFormatConverter.ParseIndianDate(dStr)
                        if (subP.valid) {
                            subConv := DateFormatConverter.Format(subP, targetFmt)
                            conv := StrReplace(conv, dStr, subConv)
                        }
                    }
                } else {
                    conv := DateFormatConverter.Convert(txt, targetFmt)
                }
            }
        } else {
            conv := txt
        }

        fmtName := (IsSet(DateFormatConverter) && targetFmt >= 1 && targetFmt <= 9) ? DateFormatConverter.Formats[targetFmt].name : "Format " . targetFmt
        res := Map()
        res["result"] := conv
        res["text"] := conv
        res["format_name"] := fmtName
        return res
    }

    static ExecuteDateDifference(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        dates := ExtractRawDatesList(txt)
        if (dates.Length < 2)
            throw Error("Date Difference: Requires at least 2 valid dates in input text")
        diffReport := CalculateDateDifference(dates[1], dates[2])
        res := Map()
        res["summary"] := diffReport
        res["result"] := diffReport
        res["text"] := diffReport
        return res
    }

    static ExecuteFinancialYear(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        fyStr := ResolveIndianFinancialYear(txt)
        if (fyStr = "Invalid Date")
            throw Error(Format("Indian Financial Year: Unable to resolve financial year from '{1}'", SubStr(txt, 1, 40)))
        res := Map()
        res["fy"] := fyStr
        res["result"] := fyStr
        res["text"] := fyStr
        return res
    }

    static ExecuteExtractPan(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        pans := []
        pos := 1
        while RegExMatch(txt, "i)\b[a-z]{5}\d{4}[a-z]{1}\b", &m, pos) {
            val := StrUpper(m[0])
            found := false
            for p in pans {
                if (p = val) {
                    found := true
                    break
                }
            }
            if !found
                pans.Push(val)
            pos := m.Pos + m.Len
        }
        resText := ""
        for idx, p in pans
            resText .= (idx > 1 ? "`n" : "") . p
        res := Map()
        res["text"] := resText
        res["result"] := resText
        res["items"] := pans
        return res
    }

    static ExecuteMathEvaluate(inputs, settings) {
        expr := inputs.Has("expression") ? String(inputs["expression"]) : (inputs.Has("text") ? String(inputs["text"]) : "")
        if (!IsSet(SafeEvaluateMath))
            throw Error("Math Evaluator engine is not loaded")
        resObj := SafeEvaluateMath(expr)
        if (!resObj.success)
            throw Error(resObj.HasOwnProp("errorMessage") ? resObj.errorMessage : "Math evaluation failed")
        numVal := (Round(resObj.result) == resObj.result) ? Integer(Round(resObj.result)) : resObj.result
        res := Map()
        res["result"] := numVal
        res["number"] := numVal
        res["text"] := resObj.resultStr
        res["display"] := resObj.displayExpr
        return res
    }

    static ExecutePercentageChange(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        return ComputePercentageChange(txt)
    }

    ; --- Text Transformation Handlers ---
    static ExecuteCleanText(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        res := Map()
        res["text"] := CleanPlainText(txt)
        res["result"] := res["text"]
        return res
    }

    static ExecuteCleanTextUnwrap(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        res := Map()
        res["text"] := JoinLinesIntoParagraph(txt)
        res["result"] := res["text"]
        return res
    }

    static ExecuteConvertCase(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        mode := "upper"
        if (Type(settings) = "Map") {
            if settings.Has("case_mode")
                mode := StrLower(String(settings["case_mode"]))
            else if settings.Has("mode")
                mode := StrLower(String(settings["mode"]))
        } else if IsObject(settings) {
            if settings.HasOwnProp("case_mode")
                mode := StrLower(String(settings.case_mode))
            else if settings.HasOwnProp("mode")
                mode := StrLower(String(settings.mode))
        }

        converted := ""
        switch mode {
            case "upper": converted := StrUpper(txt)
            case "lower": converted := StrLower(txt)
            case "title": converted := StrTitle(txt)
            case "sentence": converted := ToSentenceCase(txt)
            case "snake": converted := ToDelimitedCase(txt, "_")
            case "kebab": converted := ToDelimitedCase(txt, "-")
            case "camel": converted := ToCamelCase(txt)
            default: converted := StrUpper(txt)
        }
        res := Map()
        res["text"] := converted
        res["result"] := converted
        return res
    }

    static ExecuteFormatList(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        listType := "checklist"
        if (Type(settings) = "Map") {
            if settings.Has("list_type")
                listType := StrLower(String(settings["list_type"]))
            else if settings.Has("list_mode")
                listType := StrLower(String(settings["list_mode"]))
            else if settings.Has("type")
                listType := StrLower(String(settings["type"]))
        } else if IsObject(settings) {
            if settings.HasOwnProp("list_type")
                listType := StrLower(String(settings.list_type))
            else if settings.HasOwnProp("list_mode")
                listType := StrLower(String(settings.list_mode))
            else if settings.HasOwnProp("type")
                listType := StrLower(String(settings.type))
        }

        formatted := ""
        switch listType {
            case "checklist": formatted := FormatChecklist(txt)
            case "bullet": formatted := FormatBulletList(txt)
            case "numbered": formatted := FormatNumberedList(txt)
            case "sql": formatted := FormatSqlInList(txt)
            default: formatted := FormatChecklist(txt)
        }
        res := Map()
        res["text"] := formatted
        res["result"] := formatted
        return res
    }

    static ExecuteTextStatistics(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        stats := GetTextStatistics(txt)
        res := Map()
        res["summary"] := stats["summary"]
        res["result"] := stats["summary"]
        res["text"] := stats["summary"]
        res["words"] := stats["words"]
        res["chars"] := stats["characters"]
        res["chars_no_spaces"] := stats["characters_no_space"]
        res["lines"] := stats["lines"]
        return res
    }

    ; --- Civil Engineering Handlers ---
    static ExecuteCivilUnitConvert(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        if (!IsSet(CivilConverterEngine))
            throw Error("CivilConverterEngine is not loaded")
        resObj := CivilConverterEngine.Evaluate(txt)
        if (!resObj.success)
            throw Error(resObj.HasOwnProp("message") ? resObj.message : "Unit conversion failed")
        res := Map()
        outStr := resObj.HasOwnProp("resultStr") ? resObj.resultStr : (resObj.HasOwnProp("displayExpr") ? resObj.displayExpr : String(resObj.val))
        res["summary"] := outStr
        res["result"] := outStr
        res["text"] := outStr
        if (resObj.HasOwnProp("val"))
            res["value"] := resObj.val
        return res
    }

    static ExecuteCivilPythagoras(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        resObj := CivilPythagoras.Evaluate(txt)
        if (!resObj.success)
            throw Error(resObj.HasOwnProp("message") ? resObj.message : "Pythagoras calculation failed")
        res := Map()
        res["summary"] := resObj.resultStr
        res["result"] := resObj.resultStr
        res["text"] := resObj.resultStr
        if (resObj.HasOwnProp("val"))
            res["value"] := resObj.val
        return res
    }

    ; --- File Reference Metadata Handlers ---
    static ExecuteFileMetadata(inputs, settings) {
        fileObj := inputs.Has("file") ? inputs["file"] : ""
        if (!IsObject(fileObj) || !fileObj.HasOwnProp("path"))
            throw Error("File Metadata: Expected FileReference object")

        rec := Map(
            "path", fileObj.path,
            "name", fileObj.name,
            "stem", fileObj.stem,
            "extension", fileObj.extension,
            "folder", fileObj.folder,
            "index", fileObj.index
        )

        res := Map()
        res["path"] := fileObj.path
        res["name"] := fileObj.name
        res["stem"] := fileObj.stem
        res["extension"] := fileObj.extension
        res["folder"] := fileObj.folder
        res["index"] := fileObj.index
        res["record"] := rec
        return res
    }
}
