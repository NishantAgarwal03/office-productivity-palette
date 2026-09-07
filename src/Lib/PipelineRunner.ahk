; ======================================================================================================================
; Module: PipelineRunner.ahk - Headless Workflow Execution Engine
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Prevalidated Headless Execution: Saved recipes execute without presenting the composer UI.
; 2. Stop-on-First-Failure: Stops immediately at the first failed step, preserving inputs and all completed snapshots.
; 3. Namespaced Step Results: Every step result is immutable and isolated under results[step_id][output_name].
; 4. Symbiotic Sinks: Directs final output to Clipboard, Document Paste, or Toast without mutating source documents.
; ======================================================================================================================

#Requires AutoHotkey v2.0

class PipelineRunner {
    /**
     * Executes a validated recipe
     * @param {Object} recipe
     * @param {String} explicitInput (Optional raw input override)
     * @returns {Object} {success: Boolean, output: Any, runId: String, error: String}
     */
    static Execute(recipe, explicitInput := "", options := {}) {
        recipe := RecipeModel.Normalize(recipe)
        runId := FormatTime(A_Now, "yyyyMMdd_HHmmss") . "_" . Random(1000, 9999)
        startTime := A_TickCount

        ; Parse Execution Options
        isPreview := (IsObject(options) && options.HasOwnProp("is_preview") && options.is_preview)
        suppressSink := (IsObject(options) && options.HasOwnProp("suppress_sink")) ? options.suppress_sink : isPreview
        suppressToasts := (IsObject(options) && options.HasOwnProp("suppress_toasts")) ? options.suppress_toasts : isPreview
        recordHistory := (IsObject(options) && options.HasOwnProp("record_history")) ? options.record_history : !isPreview

        recipeId := (Type(recipe) = "Map") ? (recipe.Has("id") ? recipe["id"] : "") : (recipe.HasOwnProp("id") ? recipe.id : "")
        recipeName := (Type(recipe) = "Map") ? (recipe.Has("name") ? recipe["name"] : "Workflow Recipe") : (recipe.HasOwnProp("name") ? recipe.name : "Workflow Recipe")
        recipeVersion := (Type(recipe) = "Map") ? (recipe.Has("version") ? recipe["version"] : 1) : (recipe.HasOwnProp("version") ? recipe.version : 1)
        recipeSteps := (Type(recipe) = "Map") ? (recipe.Has("steps") ? recipe["steps"] : []) : (recipe.HasOwnProp("steps") ? recipe.steps : [])
        inpSrc := (Type(recipe) = "Map") ? (recipe.Has("input_source") ? recipe["input_source"] : "selection") : (recipe.HasOwnProp("input_source") ? recipe.input_source : "selection")
        sink := (Type(recipe) = "Map") ? (recipe.Has("sink") ? StrLower(recipe["sink"]) : "clipboard") : (recipe.HasOwnProp("sink") ? StrLower(recipe.sink) : "clipboard")
        finalOutputRef := (Type(recipe) = "Map") ? (recipe.Has("final_output_ref") ? Trim(String(recipe["final_output_ref"])) : "") : (recipe.HasOwnProp("final_output_ref") ? Trim(String(recipe.final_output_ref)) : "")

        ; 1. Capture Physical Input
        rawInput := explicitInput
        if (rawInput = "") {
            if (isPreview) {
                rawInput := ""
            } else if (inpSrc = "selection") {
                rawInput := SafeGetSelection(0.4)
            } else if (inpSrc = "clipboard") {
                rawInput := A_Clipboard
            } else if (inpSrc = "prompt" || inpSrc = "interceptor") {
                ib := OfficeInputBox("Enter input for " . recipeName . ":", recipeName)
                if (ib.Result != "OK") {
                    return {success: false, output: "", runId: runId, error: "Cancelled by user", failed_step: "", results: Map(), stepSnapshots: []}
                }
                rawInput := ib.Value
            }
        }

        ; 2. Initialize Runtime Context
        results := Map()
        results["input"] := Map("text", rawInput, "raw", rawInput, "selection", rawInput, "clipboard", rawInput)
        if (inpSrc = "files") {
            filesArr := []
            if (rawInput != "") {
                Loop Parse, rawInput, "`n", "`r" {
                    if (Trim(A_LoopField) != "")
                        filesArr.Push(Trim(A_LoopField))
                }
            }
            results["input"]["files"] := filesArr
        }
        stepSnapshots := []
        status := "success"
        errStep := ""
        errMsg := ""
        finalOutput := ""

        try {
            ; 3. Execute Steps Sequentially with Flat-Flow Loop Support
            sIdx := 1
            while (sIdx <= recipeSteps.Length) {
                currStep := recipeSteps[sIdx]
                currToolId := (Type(currStep) = "Map") ? (currStep.Has("tool_id") ? currStep["tool_id"] : "") : (currStep.HasOwnProp("tool_id") ? currStep.tool_id : "")
                isCont := (Type(currStep) = "Map") ? (currStep.Has("is_container") && currStep["is_container"]) : (currStep.HasOwnProp("is_container") && currStep.is_container)

                if (currToolId = "loop_start") {
                    endIdx := 0
                    nestLevel := 0
                    for checkIdx, stepObj in recipeSteps {
                        if (checkIdx > sIdx) {
                            tId := (Type(stepObj) = "Map") ? (stepObj.Has("tool_id") ? stepObj["tool_id"] : "") : (stepObj.HasOwnProp("tool_id") ? stepObj.tool_id : "")
                            if (tId = "loop_start")
                                nestLevel++
                            else if (tId = "loop_end") {
                                if (nestLevel = 0) {
                                    endIdx := checkIdx
                                    break
                                } else {
                                    nestLevel--
                                }
                            }
                        }
                    }

                    if (endIdx = 0)
                        throw Error("Unclosed loop_start at step " . sIdx)

                    enclosedSteps := []
                    k := sIdx + 1
                    while (k < endIdx) {
                        enclosedSteps.Push(recipeSteps[k])
                        k++
                    }

                    endStep := recipeSteps[endIdx]
                    startStepId := (Type(currStep) = "Map") ? currStep["id"] : currStep.id
                    endStepId := (Type(endStep) = "Map") ? endStep["id"] : endStep.id

                    bindingsObj := (Type(currStep) = "Map") ? (currStep.Has("bindings") ? currStep["bindings"] : Map()) : (currStep.HasOwnProp("bindings") ? currStep.bindings : Map())
                    itemsRef := (Type(bindingsObj) = "Map") ? (bindingsObj.Has("items") ? bindingsObj["items"] : "") : (bindingsObj.HasOwnProp("items") ? bindingsObj.items : "")

                    endBindings := (Type(endStep) = "Map") ? (endStep.Has("bindings") ? endStep["bindings"] : Map()) : (endStep.HasOwnProp("bindings") ? endStep.bindings : Map())
                    collectRef := (Type(endBindings) = "Map") ? (endBindings.Has("collect") ? endBindings["collect"] : "") : (endBindings.HasOwnProp("collect") ? endBindings.collect : "")

                    PipelineRunner._ExecuteLoop(endStepId, itemsRef, enclosedSteps, collectRef, results, stepSnapshots)
                    results[startStepId] := results[endStepId]

                    sIdx := endIdx + 1
                } else if isCont {
                    stepId := (Type(currStep) = "Map") ? currStep["id"] : currStep.id
                    bindingsObj := (Type(currStep) = "Map") ? (currStep.Has("bindings") ? currStep["bindings"] : Map()) : (currStep.HasOwnProp("bindings") ? currStep.bindings : Map())
                    itemsRef := (Type(bindingsObj) = "Map") ? (bindingsObj.Has("items") ? bindingsObj["items"] : "") : (bindingsObj.HasOwnProp("items") ? bindingsObj.items : "")
                    subSteps := (Type(currStep) = "Map") ? (currStep.Has("sub_steps") ? currStep["sub_steps"] : []) : (currStep.HasOwnProp("sub_steps") ? currStep.sub_steps : [])
                    retStep := (Type(currStep) = "Map") ? (currStep.Has("loop_return_step") ? currStep["loop_return_step"] : "") : (currStep.HasOwnProp("loop_return_step") ? currStep.loop_return_step : "")

                    PipelineRunner._ExecuteLoop(stepId, itemsRef, subSteps, retStep, results, stepSnapshots)
                    sIdx++
                } else {
                    PipelineRunner._ExecuteStep(currStep, results, stepSnapshots)
                    sIdx++
                }
            }

            ; 4. Resolve Final Output from designated or last step
            if (finalOutputRef != "") {
                resolvedFinal := PipelineRunner._ResolveReference(finalOutputRef, results)
                if (Type(resolvedFinal) = "Array") {
                    joinedArr := ""
                    for idx, itm in resolvedFinal {
                        valStr := IsObject(itm) ? JsonHelper.Stringify(itm) : String(itm)
                        joinedArr .= (idx > 1 ? "`n" : "") . valStr
                    }
                    finalOutput := joinedArr
                } else if IsObject(resolvedFinal) {
                    finalOutput := JsonHelper.Stringify(resolvedFinal)
                } else {
                    finalOutput := String(resolvedFinal)
                }
            } else if (recipeSteps.Length > 0) {
                lastStep := recipeSteps[recipeSteps.Length]
                lastStepId := (Type(lastStep) = "Map") ? lastStep["id"] : lastStep.id
                lastToolId := (Type(lastStep) = "Map") ? (lastStep.Has("tool_id") ? lastStep["tool_id"] : "") : (lastStep.HasOwnProp("tool_id") ? lastStep.tool_id : "")
                if results.Has(lastStepId) {
                    lastResMap := results[lastStepId]
                    ; Priority 1: Check if the tool declared a primary output
                    primaryKey := ""
                    if (lastToolId != "" && ToolCatalog.Has(lastToolId)) {
                        toolDef := ToolCatalog.Get(lastToolId)
                        if (toolDef.HasOwnProp("outputs") && IsObject(toolDef.outputs)) {
                            for outDef in toolDef.outputs {
                                if (outDef.HasOwnProp("primary") && outDef.primary) {
                                    primaryKey := outDef.name
                                    break
                                }
                            }
                        }
                    }

                    if (primaryKey != "" && lastResMap.Has(primaryKey)) {
                        val := lastResMap[primaryKey]
                        if (Type(val) = "Array") {
                            itemsArr := val
                            finalOutput := ""
                            for idx, itm in itemsArr {
                                valStr := IsObject(itm) ? JsonHelper.Stringify(itm) : String(itm)
                                finalOutput .= (idx > 1 ? "`n" : "") . valStr
                            }
                        } else if IsObject(val) {
                            finalOutput := JsonHelper.Stringify(val)
                        } else {
                            finalOutput := String(val)
                        }
                    } else if lastResMap.Has("text") {
                        v := lastResMap["text"]
                        finalOutput := IsObject(v) ? JsonHelper.Stringify(v) : String(v)
                    } else if lastResMap.Has("result") {
                        v := lastResMap["result"]
                        finalOutput := IsObject(v) ? JsonHelper.Stringify(v) : String(v)
                    } else if lastResMap.Has("summary") {
                        v := lastResMap["summary"]
                        finalOutput := IsObject(v) ? JsonHelper.Stringify(v) : String(v)
                    } else if lastResMap.Has("words") {
                        v := lastResMap["words"]
                        finalOutput := IsObject(v) ? JsonHelper.Stringify(v) : String(v)
                    } else if lastResMap.Has("items") {
                        ; Join array into newline text
                        itemsArr := lastResMap["items"]
                        finalOutput := ""
                        for idx, itm in itemsArr {
                            valStr := IsObject(itm) ? JsonHelper.Stringify(itm) : String(itm)
                            finalOutput .= (idx > 1 ? "`n" : "") . valStr
                        }
                    } else {
                        for k, v in lastResMap {
                            finalOutput := IsObject(v) ? JsonHelper.Stringify(v) : String(v)
                            break
                        }
                    }
                }
            }

            ; 5. Route to Sink
            if (sink = "none" || suppressSink) {
                ; Pure programmatic / preview return - do not touch clipboard, paste or toast
            } else if (sink = "paste") {
                InsertText(finalOutput)
                if (!suppressToasts)
                    ShowToast("✔ Recipe '" . recipeName . "' applied", 2000)
            } else if (sink = "toast") {
                if (!suppressToasts)
                    ShowToast(SubStr(finalOutput, 1, 100), 3000)
            } else {
                ; Default: Clipboard
                A_Clipboard := finalOutput
                if (!suppressToasts)
                    ShowToast("✔ Recipe '" . recipeName . "' copied to clipboard", 2200)
            }

        } catch as execErr {
            status := "failed"
            errStep := (IsObject(execErr) && execErr.HasOwnProp("stepId")) ? execErr.stepId : "unknown"
            errMsg := execErr.Message
            if (!suppressToasts)
                ShowToast("❌ Recipe Failed at " . errStep . ": " . errMsg, 3500)
            if (IsSet(LogAppError) && !isPreview)
                LogAppError("PipelineRunner (" . recipeName . ")", execErr)
        }

        durationMs := A_TickCount - startTime

        ; 6. Commit Snapshot to RunHistory
        if (recordHistory) {
            try {
                runRecord := {
                    run_id: runId,
                    timestamp: FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"),
                    recipe_id: recipeId,
                    recipe_name: recipeName,
                    recipe_version: recipeVersion,
                    status: status,
                    duration_ms: durationMs,
                    input_snapshot: rawInput,
                    output_snapshot: finalOutput,
                    failed_step: errStep,
                    error_message: errMsg,
                    step_snapshots: stepSnapshots
                }
                RunHistory.Record(runRecord)
            }
        }

        return {
            success: (status = "success"),
            output: finalOutput,
            final_output: finalOutput,
            duration_ms: durationMs,
            runId: runId,
            error: errMsg,
            failed_step: errStep,
            results: results,
            stepSnapshots: stepSnapshots
        }
    }

    static _ExecuteStep(step, results, stepSnapshots) {
        stepId := (Type(step) = "Map") ? step["id"] : step.id
        stepStart := A_TickCount
        isContainer := (Type(step) = "Map") ? (step.Has("is_container") && step["is_container"]) : (step.HasOwnProp("is_container") && step.is_container)
        stepBindings := (Type(step) = "Map") ? (step.Has("bindings") ? step["bindings"] : Map()) : (step.HasOwnProp("bindings") ? step.bindings : Map())
        stepSettings := (Type(step) = "Map") ? (step.Has("settings") ? step["settings"] : Map()) : (step.HasOwnProp("settings") ? step.settings : Map())

        ; --- Handle Loop Container ---
        if (isContainer) {
            itemsRef := (Type(stepBindings) = "Map") ? (stepBindings.Has("items") ? stepBindings["items"] : "") : (stepBindings.HasOwnProp("items") ? stepBindings.items : "")
            subSteps := (Type(step) = "Map") ? (step.Has("sub_steps") ? step["sub_steps"] : []) : (step.HasOwnProp("sub_steps") ? step.sub_steps : [])
            retStep := (Type(step) = "Map") ? (step.Has("loop_return_step") ? step["loop_return_step"] : "") : (step.HasOwnProp("loop_return_step") ? step.loop_return_step : "")
            PipelineRunner._ExecuteLoop(stepId, itemsRef, subSteps, retStep, results, stepSnapshots)
            return
        }

        ; --- Handle Standard Step ---
        stepToolId := (Type(step) = "Map") ? step["tool_id"] : step.tool_id
        tool := ToolCatalog.Get(stepToolId)

        ; Resolve inputs from bindings polymorphically (Map or Object)
        inputsMap := Map()
        if (Type(stepBindings) = "Map") {
            for inpName, refStr in stepBindings {
                val := PipelineRunner._ResolveReference(refStr, results)
                inputsMap[inpName] := val
            }
        } else if IsObject(stepBindings) {
            for inpName, refStr in stepBindings.OwnProps() {
                val := PipelineRunner._ResolveReference(refStr, results)
                inputsMap[inpName] := val
            }
        }
        inputsMap["__results"] := results.Clone()

        ; Merge settings with defaults polymorphically (Map or Object)
        settingsMap := Map()
        for s in tool.settings {
            if (Type(stepSettings) = "Map" && stepSettings.Has(s.name)) {
                settingsMap[s.name] := stepSettings[s.name]
            } else if (IsObject(stepSettings) && stepSettings.HasOwnProp(s.name)) {
                settingsMap[s.name] := stepSettings.%s.name%
            } else {
                settingsMap[s.name] := s.default
            }
        }

        ; Clean snapshot input without __results
        cleanInputs := Map()
        for k, v in inputsMap {
            if (k != "__results")
                cleanInputs[k] := v
        }

        try {
            outMap := tool.handler.Call(inputsMap, settingsMap)
            results[stepId] := outMap

            stepSnapshots.Push({
                step_id: stepId,
                status: "success",
                duration_ms: A_TickCount - stepStart,
                inputs: cleanInputs,
                outputs: outMap
            })
        } catch as stepErr {
            stepSnapshots.Push({
                step_id: stepId,
                status: "failed",
                duration_ms: A_TickCount - stepStart,
                inputs: cleanInputs,
                error: stepErr.Message
            })
            customErr := Error(stepErr.Message)
            customErr.stepId := stepId
            throw customErr
        }
    }

    static _ExecuteLoop(loopId, itemsRef, subSteps, returnRef, results, stepSnapshots) {
        stepStart := A_TickCount
        items := PipelineRunner._ResolveReference(itemsRef, results)
        if (Type(items) != "Array")
            throw Error(Format("Loop step '{1}' expects Items<T>, got '{2}'", loopId, Type(items)))

        collected := []
        iterationRecords := []

        for idx, item in items {
            ; Shallow clone is safe: sub-steps create NEW result keys, never mutate existing inner Maps
            iterResults := results.Clone()
            iterResults["loop"] := Map(
                "item", item,
                "index", idx,
                "count", items.Length,
                "is_first", (idx = 1),
                "is_last", (idx = items.Length)
            )

            iterSnapshots := []
            try {
                for subStep in subSteps {
                    PipelineRunner._ExecuteStep(subStep, iterResults, iterSnapshots)
                }
            } catch as loopStepErr {
                iterationRecords.Push({
                    iteration: idx,
                    item: item,
                    snapshots: iterSnapshots,
                    error: loopStepErr.Message
                })
                stepSnapshots.Push({
                    step_id: loopId,
                    status: "failed",
                    duration_ms: A_TickCount - stepStart,
                    inputs: Map("items_count", items.Length, "failed_iteration", idx),
                    iterations: iterationRecords,
                    error: loopStepErr.Message
                })
                throw loopStepErr
            }

            retVal := ""
            if (returnRef != "" && InStr(returnRef, ".")) {
                retVal := PipelineRunner._ResolveReference(returnRef, iterResults)
            } else {
                targetStepId := (returnRef != "") ? returnRef : ""
                if (targetStepId = "" && subSteps.Length > 0) {
                    lastSub := subSteps[subSteps.Length]
                    targetStepId := (Type(lastSub) = "Map") ? lastSub["id"] : lastSub.id
                }

                if (targetStepId != "" && iterResults.Has(targetStepId)) {
                    sMap := iterResults[targetStepId]

                    ; Check primary first if subStep declares one
                    targetToolId := ""
                    for sub in subSteps {
                        sId := (Type(sub) = "Map") ? sub["id"] : sub.id
                        if (sId = targetStepId) {
                            targetToolId := (Type(sub) = "Map") ? (sub.Has("tool_id") ? sub["tool_id"] : "") : (sub.HasOwnProp("tool_id") ? sub.tool_id : "")
                            break
                        }
                    }
                    primaryKey := ""
                    if (targetToolId != "" && ToolCatalog.Has(targetToolId)) {
                        toolDef := ToolCatalog.Get(targetToolId)
                        if (toolDef.HasOwnProp("outputs") && IsObject(toolDef.outputs)) {
                            for outDef in toolDef.outputs {
                                if (outDef.HasOwnProp("primary") && outDef.primary) {
                                    primaryKey := outDef.name
                                    break
                                }
                            }
                        }
                    }

                    if (Type(sMap) = "Map") {
                        if (primaryKey != "" && sMap.Has(primaryKey))
                            retVal := sMap[primaryKey]
                        else if sMap.Has("text")
                            retVal := sMap["text"]
                        else if sMap.Has("result")
                            retVal := sMap["result"]
                        else if sMap.Has("words")
                            retVal := sMap["words"]
                        else if sMap.Has("summary")
                            retVal := sMap["summary"]
                        else {
                            for k, v in sMap {
                                retVal := v
                                break
                            }
                        }
                    } else if IsObject(sMap) {
                        if (primaryKey != "" && sMap.HasOwnProp(primaryKey))
                            retVal := sMap.%primaryKey%
                        else if sMap.HasOwnProp("text")
                            retVal := sMap.text
                        else if sMap.HasOwnProp("result")
                            retVal := sMap.result
                        else if sMap.HasOwnProp("words")
                            retVal := sMap.words
                        else if sMap.HasOwnProp("summary")
                            retVal := sMap.summary
                        else {
                            for k, v in sMap.OwnProps() {
                                retVal := v
                                break
                            }
                        }
                    } else {
                        retVal := sMap
                    }
                }
            }

            collected.Push(retVal)
            iterationRecords.Push({
                iteration: idx,
                item: item,
                snapshots: iterSnapshots,
                return_value: retVal
            })
        }

        joinedText := ""
        for cIdx, cVal in collected {
            valStr := IsObject(cVal) ? JsonHelper.Stringify(cVal) : String(cVal)
            joinedText .= (cIdx > 1 ? "`n" : "") . valStr
        }

        loopOut := Map(
            "items", collected,
            "count", collected.Length,
            "text", joinedText
        )

        results[loopId] := loopOut
        if results.Has("loop")
            results.Delete("loop")

        stepSnapshots.Push({
            step_id: loopId,
            status: "success",
            duration_ms: A_TickCount - stepStart,
            inputs: Map("items_count", items.Length),
            iterations: iterationRecords,
            outputs: loopOut
        })
    }

    static _ResolveReference(refStr, results) {
        clean := Trim(refStr)
        dotPos := InStr(clean, ".")
        if (dotPos = 0) {
            if results.Has(clean)
                return results[clean]
            return ""
        }

        namespace := SubStr(clean, 1, dotPos - 1)
        fieldName := SubStr(clean, dotPos + 1)

        if !results.Has(namespace)
            return ""

        nsMap := results[namespace]
        if (Type(nsMap) = "Map" && nsMap.Has(fieldName))
            return nsMap[fieldName]
        if (IsObject(nsMap) && nsMap.HasOwnProp(fieldName))
            return nsMap.%fieldName%

        return ""
    }
}
