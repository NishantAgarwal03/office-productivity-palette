; ======================================================================================================================
; Module: WorkflowPrimitives.ahk - Generic Pipeline Primitives
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; PRIMITIVES IMPLEMENTED:
; 1. primitive_split             - Converts Text to Items<Text> by delimiter
; 2. primitive_join              - Converts Items<T> to Text with configured separator
; 3. primitive_filter            - Filter Items<T> by query / regex (Keep or Exclude)
; 4. primitive_dedupe            - Case-insensitive / Case-sensitive deduplication retaining order
; 5. primitive_slice             - Slice Items<T> by Top-N, Range, or Last-N
; 6. primitive_interceptor       - Deliberate pause to collect / confirm interactive value
; 7. primitive_template_combine  - Formatted text assembly referencing named outputs
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterWorkflowPrimitives() {
    ; --- 1. Split Primitive ---
    ToolCatalog.Register({
        id: "primitive_split",
        version: 1,
        label: "Split Lines / Delimiter",
        category: "Primitives",
        description: "Tokenizes Text into Items<Text> using newline or custom separator",
        inputs: [
            {name: "text", type: "text", required: true, label: "Source Text"}
        ],
        settings: [
            {name: "delimiter", type: "text", default: "\n", options: ["\n", "\n\n", ",", ";", "\t"], label: "Delimiter"}
        ],
        outputs: [
            {name: "items", type: "items<text>", label: "Extracted Items"},
            {name: "count", type: "number", label: "Item Count"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteSplit(inputs, settings)
    })

    ; --- 2. Join Primitive ---
    ToolCatalog.Register({
        id: "primitive_join",
        version: 1,
        label: "Join Items",
        category: "Primitives",
        description: "Renders an Items<T> collection as a single continuous Text string",
        inputs: [
            {name: "items", type: "items<any>", required: true, label: "Items to Join"}
        ],
        settings: [
            {name: "delimiter", type: "text", default: "\n", options: ["\n", "\n\n", ", ", "; ", "\t", " "], label: "Separator"}
        ],
        outputs: [
            {name: "text", type: "text", label: "Joined Text"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteJoin(inputs, settings)
    })

    ; --- 3. Filter Primitive ---
    ToolCatalog.Register({
        id: "primitive_filter",
        version: 1,
        label: "Filter Items",
        category: "Primitives",
        description: "Filters Items<T> by text search or regular expression (Keep / Exclude)",
        inputs: [
            {name: "items", type: "items<any>", required: true, label: "Items"}
        ],
        settings: [
            {name: "query", type: "text", default: "", label: "Filter Pattern"},
            {name: "mode", type: "text", default: "keep", options: ["keep", "exclude"], label: "Mode"},
            {name: "is_regex", type: "boolean", default: false, label: "Use Regular Expression"},
            {name: "match_case", type: "boolean", default: false, label: "Case Sensitive"}
        ],
        outputs: [
            {name: "items", type: "items<any>", label: "Filtered Items"},
            {name: "count", type: "number", label: "Result Count"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteFilter(inputs, settings)
    })

    ; --- 4. Dedupe Primitive ---
    ToolCatalog.Register({
        id: "primitive_dedupe",
        version: 1,
        label: "Deduplicate Items",
        category: "Primitives",
        description: "Removes duplicate items while strictly preserving original order",
        inputs: [
            {name: "items", type: "items<any>", required: true, label: "Items"}
        ],
        settings: [
            {name: "match_case", type: "boolean", default: false, label: "Case Sensitive"}
        ],
        outputs: [
            {name: "items", type: "items<any>", label: "Unique Items"},
            {name: "count", type: "number", label: "Unique Count"},
            {name: "removed_count", type: "number", label: "Duplicates Removed"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteDedupe(inputs, settings)
    })

    ; --- 5. Slice Primitive ---
    ToolCatalog.Register({
        id: "primitive_slice",
        version: 1,
        label: "Slice / Limit Items",
        category: "Primitives",
        description: "Extracts top N, last N, or an indexed range of items",
        inputs: [
            {name: "items", type: "items<any>", required: true, label: "Items"}
        ],
        settings: [
            {name: "mode", type: "text", default: "top_n", options: ["top_n", "last_n", "range"], label: "Slice Mode"},
            {name: "count", type: "number", default: 10, label: "Count (Top/Last)"},
            {name: "start", type: "number", default: 1, label: "Start Index"},
            {name: "end", type: "number", default: 10, label: "End Index"}
        ],
        outputs: [
            {name: "items", type: "items<any>", label: "Sliced Items"},
            {name: "count", type: "number", label: "Slice Count"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteSlice(inputs, settings)
    })

    ; --- 6. Interactive Interceptor Primitive ---
    ToolCatalog.Register({
        id: "primitive_interceptor",
        version: 1,
        label: "Interactive Interceptor",
        category: "Primitives",
        description: "Pauses recipe execution to prompt the user for manual input or confirmation",
        inputs: [],
        settings: [
            {name: "title", type: "text", default: "Workflow Input Needed", label: "Dialog Title"},
            {name: "prompt", type: "text", default: "Enter required input value:", label: "Prompt Message"},
            {name: "default_value", type: "text", default: "", label: "Default Value"},
            {name: "output_type", type: "text", default: "text", options: ["text", "number"], label: "Output Type"}
        ],
        outputs: [
            {name: "value", type: "any", label: "User Input"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteInterceptor(inputs, settings)
    })

    ; --- 7. Template / Combine Primitive ---
    ToolCatalog.Register({
        id: "primitive_template_combine",
        version: 1,
        label: "Template / Combine",
        category: "Primitives",
        description: "Assembles formatted text by substituting named outputs into a template string",
        inputs: [
            {name: "context", type: "any", required: false, label: "Current Record / Context"}
        ],
        settings: [
            {name: "template", type: "text", default: "{item}", label: "Template String"}
        ],
        outputs: [
            {name: "text", type: "text", label: "Formatted Text"}
        ],
        handler: (inputs, settings) => WorkflowPrimitives.ExecuteTemplate(inputs, settings)
    })

    ; --- 8. Loop Start (Structural Boundary) ---
    ToolCatalog.Register({
        id: "loop_start",
        version: 1,
        label: "Loop Start (For Each)",
        category: "Primitives",
        description: "Marks beginning of an iterative loop over an Items<T> collection",
        inputs: [
            {name: "items", type: "items<any>", required: true, label: "Items to Loop"}
        ],
        settings: [],
        outputs: [
            {name: "item", type: "any", label: "Current Iteration Item"},
            {name: "index", type: "number", label: "Current Index"},
            {name: "count", type: "number", label: "Total Count"}
        ],
        handler: (inputs, settings) => Map("item", "", "index", 0, "count", 0)
    })

    ; --- 9. Loop End (Structural Boundary) ---
    ToolCatalog.Register({
        id: "loop_end",
        version: 1,
        label: "Loop End (Collect)",
        category: "Primitives",
        description: "Marks end of loop, collects results, and aggregates into collection",
        inputs: [
            {name: "collect", type: "any", required: false, label: "Result to Collect"}
        ],
        settings: [],
        outputs: [
            {name: "items", type: "items<any>", label: "Collected Items Array"},
            {name: "count", type: "number", label: "Total Items Processed"},
            {name: "text", type: "text", label: "Newline Joined Text"}
        ],
        handler: (inputs, settings) => Map("items", [], "count", 0, "text", "")
    })
}

class WorkflowPrimitives {
    static ExecuteSplit(inputs, settings) {
        rawText := inputs.Has("text") ? String(inputs["text"]) : ""
        delimSetting := settings.Has("delimiter") ? settings["delimiter"] : "\n"

        actualDelim := WorkflowPrimitives._ResolveDelimiter(delimSetting)
        
        items := []
        if (actualDelim = "`n") {
            Loop Parse, rawText, "`n", "`r" {
                t := Trim(A_LoopField)
                if (t != "")
                    items.Push(t)
            }
        } else {
            rawItems := StrSplit(rawText, actualDelim)
            for item in rawItems {
                t := Trim(item)
                if (t != "")
                    items.Push(t)
            }
        }

        res := Map()
        res["items"] := items
        res["count"] := items.Length
        return res
    }

    static ExecuteJoin(inputs, settings) {
        items := inputs.Has("items") ? inputs["items"] : []
        if (Type(items) != "Array")
            items := [String(items)]

        delimSetting := settings.Has("delimiter") ? settings["delimiter"] : "\n"
        actualDelim := WorkflowPrimitives._ResolveDelimiter(delimSetting)

        out := ""
        for idx, item in items {
            valStr := (Type(item) = "Map") ? JsonHelper.Stringify(item) : String(item)
            out .= (idx > 1 ? actualDelim : "") . valStr
        }

        res := Map()
        res["text"] := out
        return res
    }

    static ExecuteFilter(inputs, settings) {
        items := inputs.Has("items") ? inputs["items"] : []
        if (Type(items) != "Array")
            items := [items]

        query := settings.Has("query") ? String(settings["query"]) : ""
        mode := StrLower(settings.Has("mode") ? settings["mode"] : "keep")
        isRegex := settings.Has("is_regex") ? settings["is_regex"] : false
        matchCase := settings.Has("match_case") ? settings["match_case"] : false

        filtered := []
        for item in items {
            itemStr := String(item)
            matched := false

            if (query = "") {
                matched := true
            } else if isRegex {
                pattern := (matchCase ? "" : "i)") . query
                matched := (RegExMatch(itemStr, pattern) > 0)
            } else {
                if matchCase
                    matched := (InStr(itemStr, query, true) > 0)
                else
                    matched := (InStr(itemStr, query, false) > 0)
            }

            if (mode = "keep" && matched) || (mode = "exclude" && !matched)
                filtered.Push(item)
        }

        res := Map()
        res["items"] := filtered
        res["count"] := filtered.Length
        return res
    }

    static ExecuteDedupe(inputs, settings) {
        items := inputs.Has("items") ? inputs["items"] : []
        if (Type(items) != "Array")
            items := [items]

        matchCase := settings.Has("match_case") ? settings["match_case"] : false

        unique := []
        seen := Map()
        duplicates := 0

        for item in items {
            key := matchCase ? String(item) : StrLower(String(item))
            if seen.Has(key) {
                duplicates++
            } else {
                seen[key] := true
                unique.Push(item)
            }
        }

        res := Map()
        res["items"] := unique
        res["count"] := unique.Length
        res["removed_count"] := duplicates
        return res
    }

    static ExecuteSlice(inputs, settings) {
        items := inputs.Has("items") ? inputs["items"] : []
        if (Type(items) != "Array")
            items := [items]

        total := items.Length
        mode := settings.Has("mode") ? settings["mode"] : "top_n"
        sliced := []

        if (total = 0) {
            res := Map()
            res["items"] := []
            res["count"] := 0
            return res
        }

        if (mode = "top_n") {
            count := Max(0, Min(total, Integer(settings.Has("count") ? settings["count"] : 10)))
            Loop count {
                sliced.Push(items[A_Index])
            }
        } else if (mode = "last_n") {
            count := Max(0, Min(total, Integer(settings.Has("count") ? settings["count"] : 10)))
            startIdx := total - count + 1
            idx := startIdx
            while (idx <= total) {
                sliced.Push(items[idx])
                idx++
            }
        } else if (mode = "range") {
            startIdx := Max(1, Integer(settings.Has("start") ? settings["start"] : 1))
            endIdx := Min(total, Integer(settings.Has("end") ? settings["end"] : total))
            idx := startIdx
            while (idx <= endIdx) {
                sliced.Push(items[idx])
                idx++
            }
        }

        res := Map()
        res["items"] := sliced
        res["count"] := sliced.Length
        return res
    }

    static ExecuteInterceptor(inputs, settings) {
        title := settings.Has("title") ? settings["title"] : "Workflow Input"
        prompt := settings.Has("prompt") ? settings["prompt"] : "Enter value:"
        defaultVal := settings.Has("default_value") ? settings["default_value"] : ""
        outType := StrLower(settings.Has("output_type") ? settings["output_type"] : "text")

        ib := OfficeInputBox(prompt, title, defaultVal)
        if (ib.Result != "OK")
            throw Error("Workflow Interceptor: User cancelled input")

        val := ib.Value
        if (outType = "number") {
            if !IsNumber(val)
                throw Error(Format("Workflow Interceptor: Expected numeric input, got '{1}'", val))
            val := Number(val)
        }

        res := Map()
        res["value"] := val
        return res
    }

    static ExecuteTemplate(inputs, settings) {
        tmpl := settings.Has("template") ? settings["template"] : "{item}"
        outStr := tmpl

        ; 1. Context from input (if provided)
        if (inputs.Has("context") && inputs["context"] != "") {
            contextVal := inputs["context"]
            valStr := (Type(contextVal) = "Map") ? JsonHelper.Stringify(contextVal) : String(contextVal)
            outStr := StrReplace(outStr, "{item}", valStr)
            outStr := StrReplace(outStr, "{loop.item}", valStr)

            ; If record, replace fields
            if (Type(contextVal) = "Map") {
                for k, v in contextVal {
                    outStr := StrReplace(outStr, "{" . k . "}", String(v))
                    outStr := StrReplace(outStr, "{item." . k . "}", String(v))
                }
            }
        }

        ; 2. Interpolate named references from runtime results
        if inputs.Has("__results") {
            resultsMap := inputs["__results"]
            pos := 1
            while RegExMatch(outStr, "\{([a-zA-Z0-9_\.]+)\}", &m, pos) {
                token := m[1]
                dotPos := InStr(token, ".")
                ns := dotPos ? SubStr(token, 1, dotPos - 1) : token
                fld := dotPos ? SubStr(token, dotPos + 1) : ""

                if (resultsMap.Has(ns) && (dotPos = 0 || (Type(resultsMap[ns]) = "Map" && resultsMap[ns].Has(fld)))) {
                    val := PipelineRunner._ResolveReference(token, resultsMap)
                    valStr := (Type(val) = "Map") ? JsonHelper.Stringify(val) : String(val)
                    outStr := StrReplace(outStr, "{" . token . "}", valStr)
                    pos := 1
                } else {
                    pos := m.Pos + m.Len
                }
            }
        }

        res := Map()
        res["text"] := outStr
        return res
    }

    static _ResolveDelimiter(d) {
        ; Handle three forms: literal escape sequences from code ("\\n"), JSON-parsed strings ("\n"), and actual AHK chars (`n)
        if (d = "`n" || d = "\\n" || d = "\n")
            return "`n"
        if (d = "`r`n" || d = "\\r\\n" || d = "\r\n")
            return "`r`n"
        if (d = "`t" || d = "\\t" || d = "\t")
            return "`t"
        if (d = "`n`n" || d = "\\n\\n" || d = "\n\n")
            return "`n`n"
        return d
    }
}
