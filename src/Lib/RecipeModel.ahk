; ======================================================================================================================
; Module: RecipeModel.ahk - Recipe Schema, Static Validation & Storage Engine
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Prevalidated Execution Plan: Saved recipes store stable steps, settings, explicit bindings,
;    control flow, and sink behavior. Previews and prior runtime values are not saved in the recipe.
; 2. Immutable Step Addressing: Later steps reference earlier in-scope results by exact step ID.
; 3. Self-Healing Default Seeds: Automatically ensures canonical office recipes (Numbers to Words row-by-row,
;    Normal Forward GST & Words, Clean Email List) exist on fresh or restored profiles.
; ======================================================================================================================

#Requires AutoHotkey v2.0

class RecipeModel {
    /**
     * Validates a recipe structure against ToolCatalog contracts and type compatibility
     * @param {Object} recipe
     * @returns {Object} {valid: Boolean, errors: Array}
     */
    static Validate(recipe) {
        errors := []

        if (!IsObject(recipe) || !recipe.HasOwnProp("id") || Trim(String(recipe.id)) = "")
            errors.Push("Recipe missing required string 'id'")

        if (recipe.HasOwnProp("name") && Trim(String(recipe.name)) = "")
            errors.Push("Recipe 'name' cannot be empty")

        if (recipe.HasOwnProp("version") && (!IsInteger(recipe.version) || recipe.version < 1))
            errors.Push("Recipe 'version' must be a positive integer")

        if (recipe.HasOwnProp("input_source")) {
            validSources := Map("selection", true, "clipboard", true, "prompt", true, "files", true, "none", true)
            if !validSources.Has(recipe.input_source)
                errors.Push(Format("Invalid recipe input_source '{1}'. Must be one of: selection, clipboard, prompt, files, none", recipe.input_source))
        }

        if (recipe.HasOwnProp("sink")) {
            validSinks := Map("clipboard", true, "paste", true, "toast", true, "none", true)
            if !validSinks.Has(recipe.sink)
                errors.Push(Format("Invalid recipe sink '{1}'. Must be one of: clipboard, paste, toast, none", recipe.sink))
        }

        if (!recipe.HasOwnProp("steps") || Type(recipe.steps) != "Array" || recipe.steps.Length = 0) {
            errors.Push("Recipe must have at least one step in 'steps' array")
            return {valid: false, errors: errors}
        }

        ; Track seen step IDs across entire recipe to reject duplicate IDs
        seenStepIds := Map()
        stepErrors := Map()

        ; In-scope output pool tracking: Map(sourceRef -> declaredType)
        scopeOutputs := Map()

        ; Initial physical input in scope
        inpSrc := recipe.HasOwnProp("input_source") ? recipe.input_source : "selection"
        if (inpSrc = "files") {
            scopeOutputs["input.files"] := WorkflowTypes.TYPE_ITEMS_FILE
        } else if (inpSrc != "none") {
            scopeOutputs["input.text"] := WorkflowTypes.TYPE_TEXT
            scopeOutputs["input.raw"] := WorkflowTypes.TYPE_TEXT
        }

        ; Track active loop boundaries
        loopStack := []

        ; Walk top-level steps
        for sIdx, step in recipe.steps {
            RecipeModel._ValidateStep(step, sIdx, scopeOutputs, seenStepIds, errors, stepErrors, false, loopStack)
        }

        if (loopStack.Length > 0) {
            for unclosed in loopStack {
                errors.Push(Format("Unclosed Loop: '{1}' (Step {2}) has no matching 'loop_end'", unclosed.id, unclosed.idx))
            }
        }

        ; Validate final_output_ref if specified
        if (recipe.HasOwnProp("final_output_ref") && Trim(String(recipe.final_output_ref)) != "") {
            fRef := Trim(String(recipe.final_output_ref))
            if (!scopeOutputs.Has(fRef)) {
                errors.Push(Format("Recipe final_output_ref '{1}' does not exist in recipe steps", fRef))
            }
        }

        return {
            valid: (errors.Length = 0),
            errors: errors,
            stepErrors: stepErrors
        }
    }

    static _ValidateStep(step, sIdx, scopeOutputs, seenStepIds, errors, stepErrors := "", loopContext := false, loopStack := "") {
        if (!IsObject(step) || !step.HasOwnProp("id") || Trim(String(step.id)) = "") {
            errors.Push(Format("Step [{1}]: Missing or empty 'id'", sIdx))
            return
        }

        stepId := step.id

        AddErr(msg) {
            errors.Push(msg)
            if (IsObject(stepErrors) && stepId != "") {
                if !stepErrors.Has(stepId)
                    stepErrors[stepId] := []
                stepErrors[stepId].Push(msg)
            }
        }

        if seenStepIds.Has(stepId) {
            AddErr(Format("Duplicate step ID '{1}'", stepId))
        } else {
            seenStepIds[stepId] := true
        }

        ; Handle Flat Loop Boundary Tracking
        if (step.HasOwnProp("tool_id") && step.tool_id = "loop_end") {
            if (!IsObject(loopStack) || loopStack.Length = 0) {
                AddErr(Format("Step [{1}]: 'loop_end' has no preceding 'loop_start'", stepId))
            } else {
                loopStack.Pop()
                if (loopStack.Length = 0) {
                    if scopeOutputs.Has("loop.item")
                        scopeOutputs.Delete("loop.item")
                    if scopeOutputs.Has("loop.index")
                        scopeOutputs.Delete("loop.index")
                    if scopeOutputs.Has("loop.count")
                        scopeOutputs.Delete("loop.count")
                }
            }
        } else if (step.HasOwnProp("tool_id") && step.tool_id = "loop_start") {
            if (IsObject(loopStack))
                loopStack.Push({id: stepId, idx: sIdx})
        }

        ; Handle Loop Container
        if (step.HasOwnProp("is_container") && step.is_container) {
            bindings := step.HasOwnProp("bindings") ? step.bindings : Map()
            hasItems := (Type(bindings) = "Map") ? bindings.Has("items") : bindings.HasOwnProp("items")
            itemsVal := hasItems ? ((Type(bindings) = "Map") ? bindings["items"] : bindings.items) : ""

            if (!hasItems || Trim(String(itemsVal)) = "") {
                AddErr(Format("Loop Step [{1}]: Missing required input binding 'items'", stepId))
            } else {
                ref := itemsVal
                if !scopeOutputs.Has(ref) {
                    AddErr(Format("Loop Step [{1}]: Binding '{2}' does not exist in scope", stepId, ref))
                } else {
                    refType := scopeOutputs[ref]
                    if (SubStr(refType, 1, 6) != "items<" && refType != "any") {
                        AddErr(Format("Loop Step [{1}]: Binding '{2}' must be Items<T>, got '{3}'", stepId, ref, refType))
                    }
                }
            }

            ; Prepare inner loop scope
            innerScope := Map()
            for k, v in scopeOutputs
                innerScope[k] := v

            innerItemType := "any"
            if (hasItems && scopeOutputs.Has(itemsVal)) {
                innerItemType := WorkflowTypes.GetItemInnerType(scopeOutputs[itemsVal])
                if (innerItemType = "")
                    innerItemType := "any"
            }

            innerScope["loop.item"] := innerItemType
            innerScope["loop.index"] := WorkflowTypes.TYPE_NUMBER
            innerScope["loop.count"] := WorkflowTypes.TYPE_NUMBER

            subSteps := step.HasOwnProp("sub_steps") ? step.sub_steps : []
            subStepIdsMap := Map()
            if (subSteps.Length = 0) {
                AddErr(Format("Loop Step [{1}]: Loop container has no sub_steps", stepId))
            } else {
                for subIdx, subStep in subSteps {
                    if (IsObject(subStep) && subStep.HasOwnProp("id"))
                        subStepIdsMap[subStep.id] := true
                    RecipeModel._ValidateStep(subStep, subIdx, innerScope, seenStepIds, errors, stepErrors, true)
                }
            }

            ; Designated return step validation
            retStep := step.HasOwnProp("loop_return_step") ? step.loop_return_step : ""
            if (retStep != "") {
                if !subStepIdsMap.Has(retStep) {
                    AddErr(Format("Loop Step [{1}]: Designated loop_return_step '{2}' is not a valid sub-step ID", stepId, retStep))
                }
            } else if (subSteps.Length > 0) {
                lastSub := subSteps[subSteps.Length]
                retStep := (Type(lastSub) = "Map") ? lastSub["id"] : lastSub.id
            }

            retType := "any"
            retKey := retStep . ".text"
            if innerScope.Has(retKey)
                retType := innerScope[retKey]
            else {
                for k, v in innerScope {
                    if (SubStr(k, 1, StrLen(retStep) + 1) = (retStep . ".")) {
                        retType := v
                        break
                    }
                }
            }

            ; Loop exposes Items<retType> and count
            scopeOutputs[stepId . ".items"] := "items<" . retType . ">"
            scopeOutputs[stepId . ".count"] := WorkflowTypes.TYPE_NUMBER
            return
        }

        ; Standard Step
        if (!step.HasOwnProp("tool_id") || !ToolCatalog.Has(step.tool_id)) {
            AddErr(Format("Step [{1}]: Tool '{2}' is not registered in ToolCatalog", stepId, step.HasOwnProp("tool_id") ? step.tool_id : ""))
            return
        }

        tool := ToolCatalog.Get(step.tool_id)

        ; Validate tool_version
        if (step.HasOwnProp("tool_version")) {
            if (step.tool_version != tool.version) {
                AddErr(Format("Step [{1}]: Tool '{2}' version mismatch. Recipe requires version {3}, but catalog provides version {4}", 
                               stepId, step.tool_id, step.tool_version, tool.version))
            }
        }

        ; Build maps for declared inputs and settings
        declaredInputs := Map()
        for inp in tool.inputs
            declaredInputs[inp.name] := inp

        declaredSettings := Map()
        for sDef in tool.settings
            declaredSettings[sDef.name] := sDef

        ; Validate bindings
        bindings := step.HasOwnProp("bindings") ? step.bindings : Map()
        boundKeys := []
        if (Type(bindings) = "Map") {
            for k, v in bindings
                boundKeys.Push({name: k, val: v})
        } else if IsObject(bindings) {
            for k, v in bindings.OwnProps()
                boundKeys.Push({name: k, val: v})
        }

        for bItem in boundKeys {
            inpName := bItem.name
            ref := bItem.val

            if !declaredInputs.Has(inpName) {
                AddErr(Format("Step [{1}]: Unknown input binding '{2}' for tool '{3}'", stepId, inpName, step.tool_id))
            } else {
                inpDef := declaredInputs[inpName]
                if (Trim(String(ref)) != "") {
                    if !scopeOutputs.Has(ref) {
                        AddErr(Format("Step [{1}]: Input '{2}' references unknown source '{3}'", stepId, inpName, ref))
                    } else {
                        srcType := scopeOutputs[ref]
                        if !WorkflowTypes.AreCompatible(srcType, inpDef.type) {
                            AddErr(Format("Step [{1}]: Type mismatch on input '{2}' — source '{3}' provides '{4}', but tool requires '{5}'", 
                                           stepId, inpName, ref, srcType, inpDef.type))
                        }
                    }
                }
            }
        }

        ; Validate required inputs presence
        for inp in tool.inputs {
            if (inp.required) {
                isBound := false
                if (Type(bindings) = "Map") {
                    if (bindings.Has(inp.name) && Trim(String(bindings[inp.name])) != "")
                        isBound := true
                } else if IsObject(bindings) {
                    if (bindings.HasOwnProp(inp.name) && Trim(String(bindings.%inp.name%)) != "")
                        isBound := true
                }
                if (!isBound)
                    AddErr(Format("Step [{1}]: Required input '{2}' is not bound", stepId, inp.name))
            }
        }

        ; Validate settings
        settings := step.HasOwnProp("settings") ? step.settings : Map()
        setEntries := []
        if (Type(settings) = "Map") {
            for k, v in settings
                setEntries.Push({name: k, val: v})
        } else if IsObject(settings) {
            for k, v in settings.OwnProps()
                setEntries.Push({name: k, val: v})
        }

        for sItem in setEntries {
            sName := sItem.name
            sVal := sItem.val

            if !declaredSettings.Has(sName) {
                AddErr(Format("Step [{1}]: Unknown setting '{2}' for tool '{3}'", stepId, sName, step.tool_id))
            } else {
                sDef := declaredSettings[sName]
                if (sDef.type = "number") {
                    if !IsNumber(sVal)
                        AddErr(Format("Step [{1}]: Setting '{2}' expects a number, got '{3}'", stepId, sName, sVal))
                } else if (sDef.type = "boolean") {
                    if (Type(sVal) != "Boolean" && sVal !== 0 && sVal !== 1 && sVal !== "true" && sVal !== "false")
                        AddErr(Format("Step [{1}]: Setting '{2}' expects a boolean, got '{3}'", stepId, sName, sVal))
                }

                if (sDef.HasOwnProp("options") && Type(sDef.options) = "Array" && sDef.options.Length > 0) {
                    optMatch := false
                    for opt in sDef.options {
                        if (String(opt) == String(sVal)) {
                            optMatch := true
                            break
                        }
                    }
                    if (!optMatch) {
                        optsStr := ""
                        for o in sDef.options
                            optsStr .= (optsStr != "" ? ", " : "") . String(o)
                        AddErr(Format("Step [{1}]: Setting '{2}' value '{3}' is not in permitted options [{4}]", 
                                       stepId, sName, sVal, optsStr))
                    }
                }
            }
        }

        ; Validate template references in primitive_template_combine or any tool setting named 'template'
        if (declaredSettings.Has("template")) {
            tmplStr := ""
            if (Type(settings) = "Map" && settings.Has("template"))
                tmplStr := String(settings["template"])
            else if (IsObject(settings) && settings.HasOwnProp("template"))
                tmplStr := String(settings.template)

            if (tmplStr != "") {
                pos := 1
                while (foundPos := RegExMatch(tmplStr, "\{([a-zA-Z0-9_\.]+)\}", &m, pos)) {
                    token := m[1]
                    if (!scopeOutputs.Has(token) && token != "loop.item" && token != "loop.index" && token != "loop.count") {
                        AddErr(Format("Step [{1}]: Template references unknown source '{{{2}}}'", stepId, token))
                    }
                    pos := foundPos + m.Len
                }
            }
        }

        ; Register outputs of this step into scope
        for toolOut in tool.outputs {
            scopeOutputs[stepId . "." . toolOut.name] := toolOut.type
        }

        if (step.tool_id = "loop_start") {
            innerItemType := "any"
            bindings := step.HasOwnProp("bindings") ? step.bindings : Map()
            hasItems := (Type(bindings) = "Map") ? bindings.Has("items") : (IsObject(bindings) && bindings.HasOwnProp("items"))
            itemsVal := hasItems ? ((Type(bindings) = "Map") ? bindings["items"] : bindings.items) : ""
            if (hasItems && scopeOutputs.Has(itemsVal)) {
                innerItemType := WorkflowTypes.GetItemInnerType(scopeOutputs[itemsVal])
                if (innerItemType = "")
                    innerItemType := "any"
            }
            scopeOutputs["loop.item"] := innerItemType
            scopeOutputs["loop.index"] := WorkflowTypes.TYPE_NUMBER
            scopeOutputs["loop.count"] := WorkflowTypes.TYPE_NUMBER
        }
    }

    ; ==================================================================================================================
    ; Storage Engine
    ; ==================================================================================================================

    static GetRecipesFolder() {
        global RecipesDir, DataDir
        folder := (IsSet(RecipesDir) && RecipesDir != "") ? RecipesDir : (DataDir . "\Recipes")
        if !DirExist(folder)
            DirCreate(folder)
        return folder
    }

    static Normalize(recipe) {
        if !IsObject(recipe)
            return recipe

        if (Type(recipe) = "Map") {
            if (!recipe.Has("final_output_ref"))
                recipe["final_output_ref"] := ""
            else
                recipe["final_output_ref"] := Trim(String(recipe["final_output_ref"]))

            if (recipe.Has("steps") && Type(recipe["steps"]) = "Array") {
                for step in recipe["steps"] {
                    RecipeModel._NormalizeStep(step)
                }
            }
        } else {
            if (!recipe.HasOwnProp("final_output_ref"))
                recipe.final_output_ref := ""
            else
                recipe.final_output_ref := Trim(String(recipe.final_output_ref))

            if (recipe.HasOwnProp("steps") && Type(recipe.steps) = "Array") {
                for step in recipe.steps {
                    RecipeModel._NormalizeStep(step)
                }
            }
        }
        return recipe
    }

    static _NormalizeStep(step) {
        if !IsObject(step)
            return

        if (Type(step) = "Map") {
            if (step.Has("bindings") && Type(step["bindings"]) != "Map") {
                bMap := Map()
                for k, v in step["bindings"].OwnProps()
                    bMap[k] := v
                step["bindings"] := bMap
            }
            if (step.Has("settings") && Type(step["settings"]) != "Map") {
                sMap := Map()
                for k, v in step["settings"].OwnProps()
                    sMap[k] := v
                step["settings"] := sMap
            }
            if (step.Has("sub_steps") && Type(step["sub_steps"]) = "Array") {
                for subStep in step["sub_steps"]
                    RecipeModel._NormalizeStep(subStep)
            }
        } else {
            if (step.HasOwnProp("bindings") && Type(step.bindings) != "Map") {
                bMap := Map()
                for k, v in step.bindings.OwnProps()
                    bMap[k] := v
                step.bindings := bMap
            }
            if (step.HasOwnProp("settings") && Type(step.settings) != "Map") {
                sMap := Map()
                for k, v in step.settings.OwnProps()
                    sMap[k] := v
                step.settings := sMap
            }
            if (step.HasOwnProp("sub_steps") && Type(step.sub_steps) = "Array") {
                for subStep in step.sub_steps
                    RecipeModel._NormalizeStep(subStep)
            }
        }
    }

    static Save(recipe) {
        valRes := RecipeModel.Validate(recipe)
        if !valRes.valid {
            throw Error("Cannot save invalid recipe:`n• " . valRes.errors[1])
        }

        folder := RecipeModel.GetRecipesFolder()
        fPath := folder . "\" . recipe.id . ".json"

        jsonStr := JsonHelper.Stringify(recipe)
        tempPath := fPath . ".tmp"

        fileObj := FileOpen(tempPath, "w", "UTF-8")
        if (!fileObj)
            throw Error("Failed to open file for writing: " . tempPath)
        fileObj.Write(jsonStr)
        fileObj.Close()

        if FileExist(fPath)
            FileDelete(fPath)
        FileMove(tempPath, fPath)
        return true
    }

    static Load(recipeId) {
        folder := RecipeModel.GetRecipesFolder()
        fPath := folder . "\" . recipeId . ".json"
        if !FileExist(fPath)
            throw Error("Recipe not found: " . recipeId)

        content := FileRead(fPath, "UTF-8")
        parsedRecipe := JsonHelper.Parse(content, false)
        return RecipeModel.Normalize(parsedRecipe)
    }

    static ListAll() {
        RecipeModel.EnsureDefaultSeedRecipes()
        folder := RecipeModel.GetRecipesFolder()
        recipesList := []

        Loop Files, folder . "\*.json" {
            try {
                content := FileRead(A_LoopFileFullPath, "UTF-8")
                rObj := JsonHelper.Parse(content, false)
                if (IsObject(rObj) && (Type(rObj) = "Map" ? rObj.Has("id") : rObj.HasOwnProp("id"))) {
                    recipesList.Push(RecipeModel.Normalize(rObj))
                }
            }
        }
        return recipesList
    }

    static Delete(recipeId) {
        folder := RecipeModel.GetRecipesFolder()
        fPath := folder . "\" . recipeId . ".json"
        if FileExist(fPath) {
            FileDelete(fPath)
            return true
        }
        return false
    }

    ; ==================================================================================================================
    ; Canonical Seed Recipes Initialization
    ; ==================================================================================================================

    static EnsureDefaultSeedRecipes() {
        folder := RecipeModel.GetRecipesFolder()

        ; Seed 1: Numbers to Words (Row by Row)
        f1 := folder . "\recipe_numbers_to_words.json"
        if !FileExist(f1) {
            seed1 := {
                id: "recipe_numbers_to_words",
                name: "Numbers to Words (Row by Row)",
                version: 1,
                category: "🔄 Recipe",
                description: "Takes multiline numbers from selection, converts each to words, and outputs row-by-row",
                input_source: "selection",
                sink: "clipboard",
                steps: [
                    {
                        id: "step_1",
                        tool_id: "primitive_split",
                        tool_version: 1,
                        settings: Map("delimiter", "\n"),
                        bindings: Map("text", "input.text")
                    },
                    {
                        id: "step_2",
                        tool_id: "loop_start",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("items", "step_1.items")
                    },
                    {
                        id: "step_3",
                        tool_id: "parse_number",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("text", "loop.item")
                    },
                    {
                        id: "step_4",
                        tool_id: "number_to_words",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("number", "step_3.number")
                    },
                    {
                        id: "step_5",
                        tool_id: "primitive_template_combine",
                        tool_version: 1,
                        settings: Map("template", "{loop.item} : {step_4.words}"),
                        bindings: Map()
                    },
                    {
                        id: "step_6",
                        tool_id: "loop_end",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("collect", "step_5.text")
                    },
                    {
                        id: "step_7",
                        tool_id: "primitive_join",
                        tool_version: 1,
                        settings: Map("delimiter", "\n"),
                        bindings: Map("items", "step_6.items")
                    }
                ]
            }
            try RecipeModel.Save(seed1)
        }

        ; Seed 2: Normal Forward GST & Words
        f2 := folder . "\recipe_forward_gst_words.json"
        if !FileExist(f2) {
            seed2 := {
                id: "recipe_forward_gst_words",
                name: "Normal Forward GST & Words",
                version: 1,
                category: "🔄 Recipe",
                description: "Calculates standard forward GST on base amount(s) and converts total amount to words",
                input_source: "selection",
                sink: "clipboard",
                steps: [
                    {
                        id: "step_1",
                        tool_id: "primitive_split",
                        tool_version: 1,
                        settings: Map("delimiter", "\n"),
                        bindings: Map("text", "input.text")
                    },
                    {
                        id: "step_2",
                        tool_id: "loop_start",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("items", "step_1.items")
                    },
                    {
                        id: "step_3",
                        tool_id: "parse_number",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("text", "loop.item")
                    },
                    {
                        id: "step_4",
                        tool_id: "normal_gst",
                        tool_version: 1,
                        settings: Map("rate", 18),
                        bindings: Map("amount", "step_3.number")
                    },
                    {
                        id: "step_5",
                        tool_id: "number_to_words",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("number", "step_4.total")
                    },
                    {
                        id: "step_6",
                        tool_id: "primitive_template_combine",
                        tool_version: 1,
                        settings: Map("template", "{step_4.summary}`nAmount in Words: {step_5.words}"),
                        bindings: Map()
                    },
                    {
                        id: "step_7",
                        tool_id: "loop_end",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("collect", "step_6.text")
                    },
                    {
                        id: "step_8",
                        tool_id: "primitive_join",
                        tool_version: 1,
                        settings: Map("delimiter", "\n\n"),
                        bindings: Map("items", "step_7.items")
                    }
                ]
            }
            try RecipeModel.Save(seed2)
        }

        ; Seed 3: Extract & Clean Email List
        f3 := folder . "\recipe_extract_clean_emails.json"
        if !FileExist(f3) {
            seed3 := {
                id: "recipe_extract_clean_emails",
                name: "Extract & Clean Email List",
                version: 1,
                category: "🔄 Recipe",
                description: "Extracts all emails from messy text or logs, removes duplicates, and joins with newlines",
                input_source: "selection",
                sink: "clipboard",
                steps: [
                    {
                        id: "step_1",
                        tool_id: "extract_emails",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("text", "input.text")
                    },
                    {
                        id: "step_2",
                        tool_id: "primitive_dedupe",
                        tool_version: 1,
                        settings: Map("match_case", false),
                        bindings: Map("items", "step_1.items")
                    },
                    {
                        id: "step_3",
                        tool_id: "primitive_join",
                        tool_version: 1,
                        settings: Map("delimiter", "\n"),
                        bindings: Map("items", "step_2.items")
                    }
                ]
            }
            try RecipeModel.Save(seed3)
        }
    }
}
