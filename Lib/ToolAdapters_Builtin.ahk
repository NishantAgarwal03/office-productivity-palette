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
            {name: "number", type: "number", label: "Parsed Number"},
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
            {name: "text", type: "text", label: "Formatted Currency"}
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
            {name: "base", type: "number", label: "Taxable Base"},
            {name: "gst", type: "number", label: "Total GST Amount"},
            {name: "cgst", type: "number", label: "CGST Amount"},
            {name: "sgst", type: "number", label: "SGST Amount"},
            {name: "total", type: "number", label: "Total Invoice Amount"},
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
            {name: "original", type: "number", label: "Original Inclusive Amount"},
            {name: "base", type: "number", label: "Taxable Base"},
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
            {name: "words", type: "text", label: "Amount in Words"},
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
            {name: "sum", type: "number", label: "Total Sum"},
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
            {name: "average", type: "number", label: "Average"},
            {name: "count", type: "number", label: "Item Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteAverageNumbers(inputs, settings)
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
            {name: "items", type: "items<text>", label: "Extracted Emails"},
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
            {name: "items", type: "items<text>", label: "Extracted URLs"},
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
            {name: "items", type: "items<text>", label: "Extracted Phones"},
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
            {name: "items", type: "items<text>", label: "Extracted GSTINs"},
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
            {name: "items", type: "items<text>", label: "Extracted Dates"},
            {name: "count", type: "number", label: "Date Count"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteExtractDates(inputs, settings)
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
            {name: "date", type: "text", label: "Formatted Date"}
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
            {name: "format_id", type: "number", default: 1, options: [1, 2, 3, 4, 5, 6, 7, 8, 9], label: "Target Format ID (1-9)"},
            {name: "target_format_id", type: "number", default: 1, options: [1, 2, 3, 4, 5, 6, 7, 8, 9], label: "Target Format ID (1-9)"}
        ],
        outputs: [
            {name: "result", type: "text", label: "Converted Date or Text"},
            {name: "text", type: "text", label: "Converted Text Output"},
            {name: "format_name", type: "text", label: "Target Format Name"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteConvertDateFormat(inputs, settings)
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
            {name: "text", type: "text", label: "Cleaned Text"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCleanText(inputs, settings)
    })

    ; --- Convert to UPPERCASE ---
    ToolCatalog.Register({
        id: "case_upper",
        version: 1,
        label: "Convert to UPPERCASE",
        category: "Text",
        description: "Converts all characters to uppercase",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", label: "Uppercase Text"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCaseTransform(inputs, settings, "upper")
    })

    ; --- Convert to lowercase ---
    ToolCatalog.Register({
        id: "case_lower",
        version: 1,
        label: "Convert to lowercase",
        category: "Text",
        description: "Converts all characters to lowercase",
        inputs: [
            {name: "text", type: "text", required: true, label: "Input Text"}
        ],
        settings: [],
        outputs: [
            {name: "text", type: "text", label: "Lowercase Text"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteCaseTransform(inputs, settings, "lower")
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
            {name: "path", type: "text", label: "Full Path"},
            {name: "name", type: "text", label: "Filename"},
            {name: "stem", type: "text", label: "Filename Stem"},
            {name: "extension", type: "text", label: "Extension"},
            {name: "folder", type: "text", label: "Folder Path"},
            {name: "index", type: "number", label: "File Index"},
            {name: "record", type: "record", label: "Metadata Record"}
        ],
        handler: (inputs, settings) => ToolAdapters.ExecuteFileMetadata(inputs, settings)
    })
}

class ToolAdapters {
    ; --- Finance & Math Handlers ---
    static ExecuteParseNumber(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        p := ParseNumberOrCurrency(txt)
        if (p.isValid) {
            res := Map()
            res["number"] := p.value
            res["is_valid"] := true
            return res
        }

        cleanMach := CleanToMachineNumber(txt)
        if (cleanMach != "" && IsNumber(cleanMach)) {
            res := Map()
            res["number"] := Number(cleanMach)
            res["is_valid"] := true
            return res
        }

        throw Error(Format("Parse Number: Unable to parse numeric value from '{1}'", txt))
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
            else if settings.Has("target_format_id")
                targetFmt := Integer(settings["target_format_id"])
        } else if IsObject(settings) {
            if settings.HasOwnProp("format_id")
                targetFmt := Integer(settings.format_id)
            else if settings.HasOwnProp("target_format_id")
                targetFmt := Integer(settings.target_format_id)
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

    ; --- Text Transformation Handlers ---
    static ExecuteCleanText(inputs, settings) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        res := Map()
        res["text"] := CleanPlainText(txt)
        return res
    }

    static ExecuteCaseTransform(inputs, settings, targetCase) {
        txt := inputs.Has("text") ? String(inputs["text"]) : ""
        res := Map()
        if (targetCase = "upper")
            res["text"] := StrUpper(txt)
        else if (targetCase = "lower")
            res["text"] := StrLower(txt)
        else
            res["text"] := txt
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
