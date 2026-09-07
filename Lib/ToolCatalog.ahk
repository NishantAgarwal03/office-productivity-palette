; ======================================================================================================================
; Module: ToolCatalog.ahk - Central Contract Registry & Auto-Wiring Engine
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Single Source of Truth: ToolCatalog is the definitive registry for pipeline-enabled tools.
; 2. Strict Typed Contracts: Every tool declares typed inputs, settings with defaults, named typed outputs,
;    and contract version.
; 3. Auto-Wiring Principle: When a step is added, the most recent compatible in-scope output is connected automatically.
;    Users change this only through explicit step settings.
; ======================================================================================================================

#Requires AutoHotkey v2.0

class ToolCatalog {
    static _Registry := Map()

    /**
     * Registers a pipeline tool contract
     * @param {Object} def
     * Expected fields:
     *   id: String (e.g. "reverse_gst")
     *   version: Integer
     *   label: String (e.g. "Reverse GST")
     *   category: String (e.g. "Finance", "Primitives", "Extraction")
     *   description: String
     *   inputs: Array of {name, type, required, label}
     *   settings: Array of {name, type, default, options, label}
     *   outputs: Array of {name, type, label}
     *   handler: Func(inputsMap, settingsMap) => outputsMap
     */
    static Register(def) {
        if (!IsObject(def) || !def.HasOwnProp("id") || Trim(def.id) = "")
            throw Error("ToolCatalog.Register: Missing required field 'id'")

        toolId := StrLower(Trim(def.id))

        ; Ensure defaults
        version := def.HasOwnProp("version") ? Integer(def.version) : 1
        label := def.HasOwnProp("label") ? def.label : toolId
        category := def.HasOwnProp("category") ? def.category : "General"
        desc := def.HasOwnProp("description") ? def.description : ""
        inputs := def.HasOwnProp("inputs") ? def.inputs : []
        settings := def.HasOwnProp("settings") ? def.settings : []
        outputs := def.HasOwnProp("outputs") ? def.outputs : []
        handler := def.HasOwnProp("handler") ? def.handler : ""

        ; Normalize input types
        normalizedInputs := []
        for inp in inputs {
            normalizedInputs.Push({
                name: StrLower(Trim(inp.name)),
                type: WorkflowTypes.Normalize(inp.type),
                required: inp.HasOwnProp("required") ? inp.required : true,
                label: inp.HasOwnProp("label") ? inp.label : inp.name
            })
        }

        ; Normalize output types
        normalizedOutputs := []
        for out in outputs {
            normalizedOutputs.Push({
                name: StrLower(Trim(out.name)),
                type: WorkflowTypes.Normalize(out.type),
                label: out.HasOwnProp("label") ? out.label : out.name
            })
        }

        ; Validate handler
        if (!HasMethod(handler))
            throw Error(Format("ToolCatalog.Register: Tool '{1}' handler must be callable", toolId))

        ToolCatalog._Registry[toolId] := {
            id: toolId,
            version: version,
            label: label,
            category: category,
            description: desc,
            inputs: normalizedInputs,
            settings: settings,
            outputs: normalizedOutputs,
            handler: handler
        }
    }

    /**
     * Retrieves a tool definition by ID
     * @param {String} toolId
     * @returns {Object}
     */
    static Get(toolId) {
        idClean := StrLower(Trim(toolId))
        if ToolCatalog._Registry.Has(idClean)
            return ToolCatalog._Registry[idClean]
        throw Error("ToolCatalog: Tool not found: " . toolId)
    }

    /**
     * Checks if a tool is registered
     * @param {String} toolId
     * @returns {Boolean}
     */
    static Has(toolId) {
        return ToolCatalog._Registry.Has(StrLower(Trim(toolId)))
    }

    /**
     * Lists all registered tools
     * @returns {Array}
     */
    static ListAll() {
        list := []
        for id, tool in ToolCatalog._Registry {
            list.Push(tool)
        }
        return list
    }

    /**
     * Finds all in-scope outputs compatible with a target input type
     * @param {String} targetType
     * @param {Array} inScopeOutputs Array of {stepId, outputName, type, label, sourceRef}
     * @returns {Array}
     */
    static GetCompatibleOutputs(targetType, inScopeOutputs) {
        compatible := []
        for item in inScopeOutputs {
            if WorkflowTypes.AreCompatible(item.type, targetType) {
                compatible.Push(item)
            }
        }
        return compatible
    }

    /**
     * Resolves default bindings for a newly added tool by picking the latest compatible output for each required input
     * @param {String} toolId
     * @param {Array} inScopeOutputs Array of {stepId, outputName, type, label, sourceRef}
     * @returns {Object} {bindings: Map, needsInput: Boolean, missingInputs: Array}
     */
    static ResolveDefaultBindings(toolId, inScopeOutputs) {
        tool := ToolCatalog.Get(toolId)
        bindings := Map()
        missing := []
        needsInput := false

        payloadWeights := Map(
            "text", 100,
            "result", 95,
            "items", 90,
            "item", 85,
            "amount", 80,
            "date", 75,
            "words", 70,
            "summary", 50,
            "format_name", 10,
            "count", 5
        )

        for inp in tool.inputs {
            candidates := ToolCatalog.GetCompatibleOutputs(inp.type, inScopeOutputs)
            if (candidates.Length > 0) {
                chosen := candidates[candidates.Length]
                bestScore := -1

                latestRef := candidates[candidates.Length].sourceRef
                dotPos := InStr(latestRef, ".")
                latestStepPrefix := (dotPos > 0) ? SubStr(latestRef, 1, dotPos) : ""

                for cand in candidates {
                    score := 0
                    cRef := cand.sourceRef
                    dotIdx := InStr(cRef, ".")
                    field := (dotIdx > 0) ? SubStr(cRef, dotIdx + 1) : cRef
                    pfx := (dotIdx > 0) ? SubStr(cRef, 1, dotIdx) : ""

                    if (pfx != "" && pfx = latestStepPrefix)
                        score += 1000

                    if payloadWeights.Has(field)
                        score += payloadWeights[field]
                    else
                        score += 40

                    if (score > bestScore) {
                        bestScore := score
                        chosen := cand
                    }
                }

                bindings[inp.name] := chosen.sourceRef
            } else if (inp.required) {
                needsInput := true
                missing.Push(inp.name)
            }
        }

        return {
            bindings: bindings,
            needsInput: needsInput,
            missingInputs: missing
        }
    }
}
