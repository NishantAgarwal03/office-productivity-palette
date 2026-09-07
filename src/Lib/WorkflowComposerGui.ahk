; ======================================================================================================================
; Module: WorkflowComposerGui.ahk - 2-Panel Visual Workflow Designer
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Linear Visual Model: Exposes a clear linear step sequence while supporting DAG referencing under the hood.
; 2. Auto-Wiring & Manual Override: Automatically selects the latest compatible source; allows manual changes
;    via Step Settings.
; 3. Prevalidated Saving: Enforces full schema and type validation before saving to Recipes/ catalog.
; 4. Unified Dark Theme: Built with #0A0D10, #182025, #F8FAFC, #7B909D, #CE6B40 design tokens.
; ======================================================================================================================

#Requires AutoHotkey v2.0

global WorkflowComposerGui := ""
global WcStepsListView := ""
global WcCurrentRecipe := ""
global WcSelectedStepIdx := 0
global WcStepSettingsModalGui := ""
global WcAddStepModalGui := ""
global WcOpenRecipeModalGui := ""

; Controls in Right Inspector Panel
global WcInspectorTitle := ""
global WcInspectorDesc := ""
global WcBindingDropdowns := Map()
global WcSettingEdits := Map()
global WcPreviewBox := ""
global WcStatusText := ""
global WcSampleInput := ""

ShowWorkflowComposer(recipeToEdit := "") {
    global WorkflowComposerGui, WcStepsListView, WcCurrentRecipe, WcSelectedStepIdx
    global WcInspectorTitle, WcInspectorDesc, WcPreviewBox, WcStatusText, WcSampleInput
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeBorder, ThemePrimary, ThemeAccent

    if IsObject(WorkflowComposerGui) {
        try WorkflowComposerGui.Destroy()
        WorkflowComposerGui := ""
    }

    ; Initialize recipe object
    if (IsObject(recipeToEdit)) {
        WcCurrentRecipe := recipeToEdit
    } else {
        WcCurrentRecipe := {
            id: "recipe_" . FormatTime(A_Now, "yyyyMMdd_HHmmss"),
            name: "New Workflow Recipe",
            version: 1,
            category: "🔄 Recipe",
            description: "Custom user-composed workflow recipe",
            input_source: "selection",
            sink: "clipboard",
            steps: []
        }
    }
    WcSelectedStepIdx := 0
    WcSampleInput := WcGetDefaultSampleForRecipe(WcCurrentRecipe)

    WorkflowComposerGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner", "Workflow Composer - Recipe Builder")
    WorkflowComposerGui.BackColor := ThemeBg
    WorkflowComposerGui.SetFont("s10 c" . ThemeText, "Segoe UI")

    ; ==================================================================================================================
    ; LEFT PANEL: Recipe Steps & Sequence Controls
    ; ==================================================================================================================

    ; Top Header: Recipe Name & Input Source
    WorkflowComposerGui.SetFont("s9.5 Bold c" . ThemeAccent)
    WorkflowComposerGui.Add("Text", "x20 y16 w100 h24", "Recipe Name:")
    WorkflowComposerGui.SetFont("s9.5 norm c" . ThemeText)
    editName := WorkflowComposerGui.Add("Edit", "x120 y12 w250 h26 Background" . ThemeSurface . " c" . ThemeText, WcCurrentRecipe.name)
    editName.OnEvent("Change", (ctrl, *) => (WcCurrentRecipe.name := ctrl.Value))

    WorkflowComposerGui.SetFont("s9.5 Bold c" . ThemePrimary)
    WorkflowComposerGui.Add("Text", "x390 y16 w90 h24", "Input Source:")
    WorkflowComposerGui.SetFont("s9.5 norm c" . ThemeText)
    srcDisplay := ["Selection", "Clipboard", "User Prompt", "Files", "None"]
    srcValues := ["selection", "clipboard", "prompt", "files", "none"]
    currSrcIdx := 1
    for idx, s in srcValues {
        if (s = WcCurrentRecipe.input_source)
            currSrcIdx := idx
    }
    ddlSource := WorkflowComposerGui.Add("DropDownList", "x485 y12 w140 r5 Background" . ThemeSurface . " c" . ThemeText . " Choose" . currSrcIdx, srcDisplay)
    ddlSource.OnEvent("Change", (ctrl, *) => (WcCurrentRecipe.input_source := srcValues[ctrl.Value]))

    WorkflowComposerGui.SetFont("s9.5 Bold c" . ThemePrimary)
    WorkflowComposerGui.Add("Text", "x645 y16 w50 h24", "Sink:")
    WorkflowComposerGui.SetFont("s9.5 norm c" . ThemeText)
    sinkDisplay := ["Clipboard", "Paste / Replace", "Toast HUD", "Silent"]
    sinkValues := ["clipboard", "paste", "toast", "none"]
    currSinkIdx := 1
    for idx, sk in sinkValues {
        if (sk = WcCurrentRecipe.sink)
            currSinkIdx := idx
    }
    ddlSink := WorkflowComposerGui.Add("DropDownList", "x695 y12 w125 r5 Background" . ThemeSurface . " c" . ThemeText . " Choose" . currSinkIdx, sinkDisplay)
    ddlSink.OnEvent("Change", (ctrl, *) => (WcCurrentRecipe.sink := sinkValues[ctrl.Value]))

    ; Steps ListView
    WorkflowComposerGui.SetFont("s9 c" . ThemeText)
    WcStepsListView := WorkflowComposerGui.Add("ListView", "x20 y52 w440 h370 Background" . ThemeSurface . " c" . ThemeText . " Grid -Multi", 
                                             ["#", "Status", "Step", "Tool", "Binding"])
    WcStepsListView.ModifyCol(1, "30 Center")
    WcStepsListView.ModifyCol(2, "55 Center")
    WcStepsListView.ModifyCol(3, "70")
    WcStepsListView.ModifyCol(4, "150")
    WcStepsListView.ModifyCol(5, "130")
    WcStepsListView.OnEvent("ItemSelect", (ctrl, item, selected) => (selected ? WcSelectStep(item) : ""))
    WcStepsListView.OnEvent("DoubleClick", (ctrl, item) => (item > 0 ? WcShowStepSettingsModal(item) : ""))

    ; Left Button Row
    WorkflowComposerGui.SetFont("s9 Bold")
    local wcBtnAdd := WorkflowComposerGui.Add("Button", "x20 y430 w95 h32", "➕ Add Step")
    wcBtnAdd.OnEvent("Click", (*) => WcShowAddStepModal())

    local wcBtnUp := WorkflowComposerGui.Add("Button", "x120 y430 w55 h32", "▲ Up")
    wcBtnUp.OnEvent("Click", (*) => WcMoveStep(-1))

    local wcBtnDown := WorkflowComposerGui.Add("Button", "x180 y430 w55 h32", "▼ Down")
    wcBtnDown.OnEvent("Click", (*) => WcMoveStep(1))

    local wcBtnDel := WorkflowComposerGui.Add("Button", "x240 y430 w60 h32", "🗑 Del")
    wcBtnDel.OnEvent("Click", (*) => WcDeleteStep())

    local wcBtnSettings := WorkflowComposerGui.Add("Button", "x305 y430 w155 h32", "⚙ Step Settings")
    wcBtnSettings.OnEvent("Click", (*) => WcShowStepSettingsModal(WcSelectedStepIdx))

    ; ==================================================================================================================
    ; RIGHT PANEL: Step Settings, Source Binding & Preview
    ; ==================================================================================================================

    ; Header: Step Inspector & Live Preview
    WorkflowComposerGui.SetFont("s10 Bold c" . ThemeAccent)
    WorkflowComposerGui.Add("Text", "x480 y52 w470 h20", "STEP INSPECTOR & LIVE PREVIEW")

    WorkflowComposerGui.SetFont("s10 Bold c" . ThemeText)
    WcInspectorTitle := WorkflowComposerGui.Add("Text", "x480 y74 w470 h24", "Select a step to inspect")
    WcInspectorDesc := ""

    WorkflowComposerGui.SetFont("s9 Bold c" . ThemePrimary)
    WorkflowComposerGui.Add("Text", "x480 y104 w155 h22", "Step I/O & Preview:")

    WorkflowComposerGui.SetFont("s8.5 norm")
    local btnClipSample := WorkflowComposerGui.Add("Button", "x640 y100 w90 h26", "📋 From Clip")
    btnClipSample.OnEvent("Click", (*) => WcUseClipboardSample())

    local btnCustomSample := WorkflowComposerGui.Add("Button", "x735 y100 w105 h26", "✏ Test Input")
    btnCustomSample.OnEvent("Click", (*) => WcPromptCustomSample())

    local btnResetSample := WorkflowComposerGui.Add("Button", "x845 y100 w105 h26", "↺ Default")
    btnResetSample.OnEvent("Click", (*) => WcResetDefaultSample())

    WorkflowComposerGui.SetFont("s9 c" . ThemeText, "Consolas")
    WcPreviewBox := WorkflowComposerGui.Add("Edit", "x480 y130 w470 h288 Background" . ThemeSurface . " c" . ThemeText . " ReadOnly Multi -E0x200", "")

    ; ==================================================================================================================
    ; BOTTOM STATUS & ACTION BAR
    ; ==================================================================================================================

    WorkflowComposerGui.SetFont("s9 c" . ThemeMuted, "Segoe UI")
    WcStatusText := WorkflowComposerGui.Add("Text", "x20 y472 w350 h22", "Ready. Build your recipe and click Save.")

    WorkflowComposerGui.SetFont("s9 Bold")
    btnOpen := WorkflowComposerGui.Add("Button", "x380 y466 w120 h34", "📂 Open Recipe")
    btnOpen.OnEvent("Click", (*) => WcShowOpenRecipeModal())

    btnCopyRes := WorkflowComposerGui.Add("Button", "x510 y466 w110 h34", "📋 Copy Result")
    btnCopyRes.OnEvent("Click", (*) => WcCopyLatestTestResult())

    btnTest := WorkflowComposerGui.Add("Button", "x630 y466 w140 h34", "▶ Test Run")
    btnTest.OnEvent("Click", (*) => WcTestRun())

    btnSave := WorkflowComposerGui.Add("Button", "x780 y466 w170 h34", "💾 Save Recipe")
    btnSave.OnEvent("Click", (*) => WcSaveRecipe())

    WorkflowComposerGui.OnEvent("Escape", (*) => CloseWorkflowComposer())
    WorkflowComposerGui.OnEvent("Close", (*) => CloseWorkflowComposer())

    WcRefreshStepsList()
    WorkflowComposerGui.Show("w970 h515")
}

CloseWorkflowComposer() {
    global WorkflowComposerGui, WcStepSettingsModalGui, WcAddStepModalGui, WcOpenRecipeModalGui
    if IsObject(WcOpenRecipeModalGui) {
        try WcOpenRecipeModalGui.Destroy()
        WcOpenRecipeModalGui := ""
    }
    if IsObject(WcStepSettingsModalGui) {
        try WcStepSettingsModalGui.Destroy()
        WcStepSettingsModalGui := ""
    }
    if IsObject(WcAddStepModalGui) {
        try WcAddStepModalGui.Destroy()
        WcAddStepModalGui := ""
    }
    if IsObject(WorkflowComposerGui) {
        try WorkflowComposerGui.Destroy()
        WorkflowComposerGui := ""
    }
}

WcRefreshStepsList() {
    global WcStepsListView, WcCurrentRecipe, WcSelectedStepIdx
    if !IsObject(WcStepsListView)
        return

    WcStepsListView.Delete()
    valRes := RecipeModel.Validate(WcCurrentRecipe)

    inLoop := false
    for idx, step in WcCurrentRecipe.steps {
        stBadge := "✔"
        if (valRes.HasOwnProp("stepErrors") && IsObject(valRes.stepErrors) && valRes.stepErrors.Has(step.id)) {
            errs := valRes.stepErrors[step.id]
            isFatal := false
            for e in errs {
                if InStr(e, "not registered") || InStr(e, "Duplicate step ID") || InStr(e, "unknown source") || InStr(e, "no preceding") {
                    isFatal := true
                    break
                }
            }
            stBadge := isFatal ? "❌" : "⚠️"
        }

        toolId := step.HasOwnProp("tool_id") ? step.tool_id : ""
        toolLabel := ""
        if (toolId = "loop_start") {
            toolLabel := "🔁 LOOP START (For Each)"
            inLoop := true
        } else if (toolId = "loop_end") {
            toolLabel := "🏁 LOOP END (Collect)"
            inLoop := false
        } else if (toolId != "" && ToolCatalog.Has(toolId)) {
            tool := ToolCatalog.Get(toolId)
            toolLabel := (inLoop ? "↳ " : "") . tool.label
        } else if (toolId != "") {
            toolLabel := (inLoop ? "↳ " : "") . toolId
        }

        bindingSummary := ""
        if step.HasOwnProp("bindings") {
            if (Type(step.bindings) = "Map") {
                for inp, src in step.bindings
                    bindingSummary .= (bindingSummary != "" ? ", " : "") . inp . "←" . src
            } else {
                for inp, src in step.bindings.OwnProps()
                    bindingSummary .= (bindingSummary != "" ? ", " : "") . inp . "←" . src
            }
        }

        WcStepsListView.Add("", idx, stBadge, step.id, toolLabel, bindingSummary)
    }

    if (WcCurrentRecipe.steps.Length > 0 && WcSelectedStepIdx = 0)
        WcSelectStep(1)
}

WcFormatValueForInspector(val) {
    if !IsObject(val)
        return String(val)
    try {
        if (Type(val) = "Array") {
            if (val.Length = 0)
                return "[]"
            str := StrReplace(StrReplace(JsonHelper.Stringify(val), "`r`n", "`n"), "`n", "`r`n")
            return "Array[" . val.Length . "] " . str
        }
        if (Type(val) = "Map") {
            if (val.Count = 0)
                return "{}"
            str := StrReplace(StrReplace(JsonHelper.Stringify(val), "`r`n", "`n"), "`n", "`r`n")
            return "Map[" . val.Count . "] " . str
        }
        str := StrReplace(StrReplace(JsonHelper.Stringify(val), "`r`n", "`n"), "`n", "`r`n")
        return Type(val) . " " . str
    } catch {
        return "<" . Type(val) . ">"
    }
}

WcSelectStep(stepIdx) {
    global WcCurrentRecipe, WcSelectedStepIdx
    global WcInspectorTitle, WcInspectorDesc, WcPreviewBox, WcStatusText

    if (stepIdx <= 0 || stepIdx > WcCurrentRecipe.steps.Length)
        return

    WcSelectedStepIdx := stepIdx
    step := WcCurrentRecipe.steps[stepIdx]

    if (step.HasOwnProp("tool_id") && step.tool_id = "loop_start") {
        WcInspectorTitle.Text := "LOOP START (" . step.id . ")"
    } else if (step.HasOwnProp("tool_id") && step.tool_id = "loop_end") {
        WcInspectorTitle.Text := "LOOP END (" . step.id . ")"
    } else if !step.HasOwnProp("tool_id") || !ToolCatalog.Has(step.tool_id) {
        tName := step.HasOwnProp("tool_id") ? step.tool_id : "undefined"
        WcInspectorTitle.Text := "Unknown Tool: " . tName
        WcPreviewBox.Value := "Error: Tool '" . tName . "' not found in ToolCatalog."
        return
    } else {
        tool := ToolCatalog.Get(step.tool_id)
        WcInspectorTitle.Text := Format("{1} ({2})", tool.label, step.id)
    }

    ; Run isolated partial preview (Zero clipboard mutation, zero toasts, zero run history)
    try {
        subRecipe := {
            id: "preview_sub",
            name: "Preview",
            version: 1,
            input_source: "selection",
            sink: "none",
            steps: []
        }
        Loop stepIdx {
            subRecipe.steps.Push(WcCurrentRecipe.steps[A_Index])
        }

        execInput := (WcSampleInput != "") ? WcSampleInput : WcGetDefaultSampleForRecipe(WcCurrentRecipe)
        res := PipelineRunner.Execute(subRecipe, execInput, {
            is_preview: true,
            suppress_sink: true,
            suppress_toasts: true,
            record_history: false
        })

        selectedStepId := (Type(step) = "Map") ? step["id"] : step.id
        stepToolName := step.HasOwnProp("tool_id") ? step.tool_id : "Step"

        ; Find snapshot for selected step (search backwards from end of execution trace)
        selectedSnap := ""
        if (res.HasOwnProp("stepSnapshots") && IsObject(res.stepSnapshots) && res.stepSnapshots.Length > 0) {
            Loop res.stepSnapshots.Length {
                revIdx := res.stepSnapshots.Length - A_Index + 1
                snap := res.stepSnapshots[revIdx]
                snapId := (Type(snap) = "Map") ? snap["step_id"] : snap.step_id
                if (snapId = selectedStepId) {
                    selectedSnap := snap
                    break
                }
            }
        }

        previewText := "=== STEP: " . selectedStepId . " (" . stepToolName . ") ===`r`n"
        if IsObject(selectedSnap) {
            stStatus := (Type(selectedSnap) = "Map") ? selectedSnap["status"] : selectedSnap.status
            stDur := (Type(selectedSnap) = "Map") ? selectedSnap["duration_ms"] : selectedSnap.duration_ms
            previewText .= "Status: " . (stStatus = "success" ? "✔ Success" : "❌ Failed") . " (" . stDur . "ms)`r`n`r`n"

            ; Format Inputs Received
            previewText .= "[INPUTS RECEIVED]`r`n"
            inMap := (Type(selectedSnap) = "Map") ? selectedSnap["inputs"] : selectedSnap.inputs
            if (IsObject(inMap) && Type(inMap) = "Map" && inMap.Count > 0) {
                for inKey, inVal in inMap {
                    if (inKey = "__results")
                        continue
                    valStr := WcFormatValueForInspector(inVal)
                    previewText .= "  " . inKey . ": " . valStr . "`r`n"
                }
            } else {
                previewText .= "  (none)`r`n"
            }
            previewText .= "`r`n"

            ; Format Outputs Generated
            previewText .= "[OUTPUTS GENERATED]`r`n"
            outMap := (Type(selectedSnap) = "Map") ? selectedSnap["outputs"] : selectedSnap.outputs
            if (IsObject(outMap) && Type(outMap) = "Map" && outMap.Count > 0) {
                for outKey, outVal in outMap {
                    valStr := WcFormatValueForInspector(outVal)
                    previewText .= "  " . outKey . ": " . valStr . "`r`n"
                }
            } else {
                previewText .= "  (none)`r`n"
            }
            previewText .= "`r`n"
        } else if (!res.success) {
            previewText .= "Status: ❌ Execution Failed`r`n"
            previewText .= "Failed Step: " . res.failed_step . "`r`n"
            previewText .= "Error: " . res.error . "`r`n`r`n"
        }

        previewText .= "=== CHAIN OUTPUT (Up to this step) ===`r`n"
        chainOut := IsObject(res.output) ? JsonHelper.Stringify(res.output) : String(res.output)
        previewText .= (chainOut != "") ? chainOut : "(empty)"

        ; Prepend validation notices if any exist for this step
        valRes := RecipeModel.Validate(WcCurrentRecipe)
        stepErrList := (valRes.HasOwnProp("stepErrors") && valRes.stepErrors.Has(selectedStepId)) ? valRes.stepErrors[selectedStepId] : []
        
        warnPrefix := ""
        if (stepErrList.Length > 0) {
            warnPrefix := "⚠️ STEP VALIDATION NOTICES (" . stepErrList.Length . "):`r`n"
            for sErr in stepErrList {
                warnPrefix .= "  • " . sErr . "`r`n"
            }
            warnPrefix .= "--------------------------------------------------`r`n`r`n"
        }

        WcPreviewBox.Value := warnPrefix . previewText
    } catch as err {
        WcPreviewBox.Value := "Preview unavailable: " . err.Message
    }
}

WcUseClipboardSample() {
    global WcSampleInput, WcSelectedStepIdx
    clipVal := A_Clipboard
    if (clipVal != "") {
        WcSampleInput := clipVal
        ShowToast("📋 Loaded clipboard into preview input (" . StrLen(clipVal) . " chars)", 1500)
    } else {
        ShowToast("⚠️ Clipboard is currently empty", 1500)
    }
    if (WcSelectedStepIdx > 0)
        WcSelectStep(WcSelectedStepIdx)
}

WcPromptCustomSample() {
    global WcSampleInput, WcSelectedStepIdx, WcCurrentRecipe, WorkflowComposerGui
    if IsObject(WorkflowComposerGui)
        WorkflowComposerGui.Opt("+AlwaysOnTop +OwnDialogs")
    initVal := (WcSampleInput != "") ? WcSampleInput : WcGetDefaultSampleForRecipe(WcCurrentRecipe)
    ib := OfficeInputBox("Enter custom test input for live step preview:", "Workflow Test Input", initVal, true, WorkflowComposerGui)
    if (ib.Result = "OK") {
        WcSampleInput := ib.Value
        ShowToast("✔ Updated preview test input", 1500)
        if (WcSelectedStepIdx > 0)
            WcSelectStep(WcSelectedStepIdx)
    }
}

WcResetDefaultSample() {
    global WcSampleInput, WcSelectedStepIdx, WcCurrentRecipe
    WcSampleInput := WcGetDefaultSampleForRecipe(WcCurrentRecipe)
    ShowToast("↺ Reset to recipe default sample input", 1500)
    if (WcSelectedStepIdx > 0)
        WcSelectStep(WcSelectedStepIdx)
}

WcMoveStep(delta) {
    global WcCurrentRecipe, WcSelectedStepIdx
    if (WcSelectedStepIdx <= 0)
        return

    targetIdx := WcSelectedStepIdx + delta
    if (targetIdx < 1 || targetIdx > WcCurrentRecipe.steps.Length)
        return

    tmp := WcCurrentRecipe.steps[WcSelectedStepIdx]
    WcCurrentRecipe.steps[WcSelectedStepIdx] := WcCurrentRecipe.steps[targetIdx]
    WcCurrentRecipe.steps[targetIdx] := tmp

    WcSelectedStepIdx := targetIdx
    WcRefreshStepsList()
    WcStepsListView.Modify(WcSelectedStepIdx, "Select Focus")
}

WcDeleteStep() {
    global WcCurrentRecipe, WcSelectedStepIdx
    if (WcSelectedStepIdx <= 0 || WcSelectedStepIdx > WcCurrentRecipe.steps.Length)
        return

    WcCurrentRecipe.steps.RemoveAt(WcSelectedStepIdx)
    WcSelectedStepIdx := Max(1, WcSelectedStepIdx - 1)
    WcRefreshStepsList()
    if (WcCurrentRecipe.steps.Length > 0)
        WcStepsListView.Modify(WcSelectedStepIdx, "Select Focus")
}

WcShowStepSettingsModal(stepIdx) {
    global WorkflowComposerGui, WcCurrentRecipe, WcSelectedStepIdx
    global ThemeBg, ThemeSurface, ThemeText, ThemePrimary, ThemeAccent, ThemeMuted, ThemeBorder

    if (stepIdx <= 0 || stepIdx > WcCurrentRecipe.steps.Length) {
        ShowToast("Please select a step first", 2000)
        return
    }

    step := WcCurrentRecipe.steps[stepIdx]
    if !step.HasOwnProp("tool_id") || !ToolCatalog.Has(step.tool_id) {
        ShowToast("Unknown tool: " . (step.HasOwnProp("tool_id") ? step.tool_id : "undefined"), 2500)
        return
    }

    tool := ToolCatalog.Get(step.tool_id)
    toolLabel := tool.label
    if (step.tool_id = "loop_start")
        toolDesc := "Configure loop input collection."
    else if (step.tool_id = "loop_end")
        toolDesc := "Configure value collected per item."
    else
        toolDesc := "Configure input bindings and tool settings."

    ; Compute in-scope upstream outputs available to this step
    inScopeOutputs := []
    inpSrc := WcCurrentRecipe.HasOwnProp("input_source") ? WcCurrentRecipe.input_source : "selection"
    if (inpSrc = "files") {
        inScopeOutputs.Push({sourceRef: "input.files", type: "items<file>", label: "input.files (Files)"})
    } else if (inpSrc != "none") {
        inScopeOutputs.Push({sourceRef: "input.text", type: "text", label: "input.text (Text)"})
    }

    ; If current step is inside a flat loop, inject loop variables
    inLoopScope := false
    Loop (stepIdx - 1) {
        prevStep := WcCurrentRecipe.steps[A_Index]
        pToolId := prevStep.HasOwnProp("tool_id") ? prevStep.tool_id : ""
        if (pToolId = "loop_start")
            inLoopScope := true
        else if (pToolId = "loop_end")
            inLoopScope := false
    }
    if inLoopScope {
        inScopeOutputs.Push({sourceRef: "loop.item", type: "any", label: "loop.item (Item)"})
        inScopeOutputs.Push({sourceRef: "loop.index", type: "number", label: "loop.index (Index)"})
        inScopeOutputs.Push({sourceRef: "loop.count", type: "number", label: "loop.count (Count)"})
    }

    ; Add outputs from all steps prior to stepIdx
    Loop (stepIdx - 1) {
        prevStep := WcCurrentRecipe.steps[A_Index]
        if (prevStep.HasOwnProp("tool_id") && ToolCatalog.Has(prevStep.tool_id)) {
            pTool := ToolCatalog.Get(prevStep.tool_id)
            for out in pTool.outputs {
                shortType := out.type
                if (SubStr(shortType, 1, 6) = "items<")
                    shortType := "items"
                lbl := prevStep.id . "." . out.name . " (" . shortType . ")"
                if (StrLen(lbl) > 21)
                    lbl := prevStep.id . "." . out.name
                inScopeOutputs.Push({
                    sourceRef: prevStep.id . "." . out.name,
                    type: out.type,
                    label: lbl,
                    isPrimary: (out.HasOwnProp("primary") && out.primary)
                })
            }
        }
    }

    global WcStepSettingsModalGui
    if IsObject(WcStepSettingsModalGui) {
        try WcStepSettingsModalGui.Destroy()
        WcStepSettingsModalGui := ""
    }

    modal := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner" . WorkflowComposerGui.Hwnd, Format("Step Settings - {1} ({2})", toolLabel, step.id))
    WcStepSettingsModalGui := modal
    modal.OnEvent("Escape", (*) => (WcStepSettingsModalGui := "", modal.Destroy()))
    modal.OnEvent("Close", (*) => (WcStepSettingsModalGui := "", modal.Destroy()))
    modal.BackColor := ThemeBg
    modal.SetFont("s10 c" . ThemeText, "Segoe UI")

    modal.SetFont("s10 Bold c" . ThemeAccent)
    modal.Add("Text", "x16 y12 w388 h20", Format("Step: {1} [{2}]", step.id, toolLabel))

    modal.SetFont("s8.5 c" . ThemeMuted)
    modal.Add("Text", "x16 y32 w388 h18", toolDesc)

    currY := 56

    ; --------------------------------------------------------------------------------------------------
    ; SECTION 1: Input Source Bindings
    ; --------------------------------------------------------------------------------------------------
    modal.SetFont("s9 Bold c" . ThemePrimary)
    modal.Add("Text", Format("x16 y{1} w388 h18", currY), "Input Source Bindings:")
    currY += 22

    bindingCtrls := Map()
    bindingChoicesMap := Map()

    if (tool.inputs.Length = 0) {
        modal.SetFont("s8.5 c" . ThemeMuted)
        modal.Add("Text", Format("x16 y{1} w388 h18", currY), "(No upstream inputs required)")
        currY += 22
    } else {
        for inp in tool.inputs {
            modal.SetFont("s8.5 c" . ThemeText)
            reqStar := inp.required ? " *" : " (opt)"
            modal.Add("Text", Format("x16 y{1} w120 h22", currY + 2), inp.label . reqStar . ":")

            choices := []
            displayList := []
            selectedIdx := 1
            currentBound := ""
            if step.HasOwnProp("bindings") {
                currentBound := (Type(step.bindings) = "Map") ? (step.bindings.Has(inp.name) ? step.bindings[inp.name] : "") : (step.bindings.HasOwnProp(inp.name) ? step.bindings.%inp.name% : "")
            }

            for src in inScopeOutputs {
                choices.Push(src.sourceRef)
                prefix := WorkflowTypes.AreCompatible(src.type, inp.type) ? "✔ " : "   "
                displayList.Push(prefix . src.label)
                if (src.sourceRef == currentBound)
                    selectedIdx := choices.Length
            }

            if (choices.Length = 0) {
                choices.Push("none")
                displayList.Push("(No sources in scope)")
            }

            bindingChoicesMap[inp.name] := choices
            ddl := modal.Add("DropDownList", Format("x142 y{1} w260 r5 Background{2} c{3} Choose{4}", currY, ThemeSurface, ThemeText, selectedIdx), displayList)
            bindingCtrls[inp.name] := ddl
            currY += 28
        }
    }

    currY += 6

    ; --------------------------------------------------------------------------------------------------
    ; SECTION 2: Tool Parameters & Settings
    ; --------------------------------------------------------------------------------------------------
    modal.SetFont("s9 Bold c" . ThemePrimary)
    modal.Add("Text", Format("x16 y{1} w388 h18", currY), "Tool Parameters & Settings:")
    currY += 22

    settingCtrls := Map()
    settingChoicesMap := Map()

    if (tool.settings.Length = 0) {
        modal.SetFont("s8.5 c" . ThemeMuted)
        modal.Add("Text", Format("x16 y{1} w388 h18", currY), "(No configurable parameters)")
        currY += 22
    } else {
        for set in tool.settings {
            modal.SetFont("s8.5 c" . ThemeText)
            modal.Add("Text", Format("x16 y{1} w120 h22", currY + 2), set.label . ":")

            currVal := set.default
            if step.HasOwnProp("settings") {
                if (Type(step.settings) = "Map") {
                    if step.settings.Has(set.name)
                        currVal := step.settings[set.name]
                } else if IsObject(step.settings) {
                    if step.settings.HasOwnProp(set.name)
                        currVal := step.settings.%set.name%
                }
            }

            if (set.HasOwnProp("options") && set.options.Length > 0) {
                rawOpts := []
                dispOpts := []
                chooseIdx := 1

                for o in set.options {
                    rawOpts.Push(o)
                    dispOpts.Push(WcFormatOptionLabel(step.HasOwnProp("tool_id") ? step.tool_id : "", set.name, o))
                }

                for oIdx, opt in rawOpts {
                    if (String(opt) == String(currVal)) {
                        chooseIdx := oIdx
                        break
                    }
                }

                settingChoicesMap[set.name] := rawOpts
                ddlSet := modal.Add("DropDownList", Format("x142 y{1} w260 r9 Background{2} c{3} Choose{4}", currY, ThemeSurface, ThemeText, chooseIdx), dispOpts)
                settingCtrls[set.name] := ddlSet
                currY += 28
            } else if (set.type = "boolean") {
                chk := modal.Add("CheckBox", Format("x142 y{1} w260 h22 c{2}", currY + 2, ThemeText), "Enabled")
                chk.Value := currVal ? 1 : 0
                settingCtrls[set.name] := chk
                currY += 28
            } else if (set.name = "template") {
                edt := modal.Add("Edit", Format("x142 y{1} w260 h54 Background{2} c{3} Multi", currY, ThemeSurface, ThemeText), String(currVal))
                settingCtrls[set.name] := edt
                currY += 60
            } else {
                edt := modal.Add("Edit", Format("x142 y{1} w260 h24 Background{2} c{3}", currY, ThemeSurface, ThemeText), String(currVal))
                settingCtrls[set.name] := edt
                currY += 28
            }
        }
    }

    ; --------------------------------------------------------------------------------------------------
    ; Bottom Action Row
    ; --------------------------------------------------------------------------------------------------
    currY += 10
    modal.SetFont("s9 Bold")
    btnApply := modal.Add("Button", Format("x142 y{1} w150 h28 Default", currY), "✔ Apply Changes")
    btnApply.OnEvent("Click", (*) => OnApplyStepSettings())

    modal.SetFont("s9 norm")
    btnCancel := modal.Add("Button", Format("x302 y{1} w100 h28", currY), "Cancel")
    btnCancel.OnEvent("Click", (*) => modal.Destroy())

    totalModalH := currY + 42

    OnApplyStepSettings() {
        if !step.HasOwnProp("bindings")
            step.bindings := Map()

        for inpName, ddlCtrl in bindingCtrls {
            chList := bindingChoicesMap[inpName]
            if (ddlCtrl.Value <= chList.Length) {
                chosenRef := chList[ddlCtrl.Value]
                if (chosenRef != "none") {
                    if (Type(step.bindings) = "Map")
                        step.bindings[inpName] := chosenRef
                    else
                        step.bindings.%inpName% := chosenRef
                }
            }
        }

        if !step.HasOwnProp("settings")
            step.settings := Map()

        for setName, ctrlObj in settingCtrls {
            if settingChoicesMap.Has(setName) {
                opts := settingChoicesMap[setName]
                rawVal := opts[ctrlObj.Value]
                for sDef in tool.settings {
                    if (sDef.name = setName && sDef.type = "number")
                        rawVal := Number(rawVal)
                }
                if (Type(step.settings) = "Map") {
                    step.settings[setName] := rawVal
                } else {
                    step.settings.%setName% := rawVal
                }
            } else if (Type(ctrlObj) = "Gui.Checkbox") {
                bVal := (ctrlObj.Value = 1)
                if (Type(step.settings) = "Map")
                    step.settings[setName] := bVal
                else
                    step.settings.%setName% := bVal
            } else {
                strVal := ctrlObj.Value
                for sDef in tool.settings {
                    if (sDef.name = setName && sDef.type = "number" && IsNumber(strVal))
                        strVal := Number(strVal)
                }
                if (Type(step.settings) = "Map")
                    step.settings[setName] := strVal
                else
                    step.settings.%setName% := strVal
            }
        }

        modal.Destroy()
        WcRefreshStepsList()
        WcSelectStep(stepIdx)
        ShowToast("✔ Step " . step.id . " updated", 1500)
    }

    modal.Show(Format("w420 h{1}", totalModalH))
}

WcShowAddStepModal(customCallback := "") {
    global WorkflowComposerGui, WcCurrentRecipe, WcAddStepModalGui
    global ThemeBg, ThemeSurface, ThemeText, ThemePrimary, ThemeAccent, ThemeMuted

    if IsObject(WcAddStepModalGui) {
        try WcAddStepModalGui.Destroy()
        WcAddStepModalGui := ""
    }

    modal := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner" . WorkflowComposerGui.Hwnd, "Add Step to Recipe")
    WcAddStepModalGui := modal
    modal.OnEvent("Escape", (*) => (WcAddStepModalGui := "", modal.Destroy()))
    modal.OnEvent("Close", (*) => (WcAddStepModalGui := "", modal.Destroy()))
    modal.BackColor := ThemeBg
    modal.SetFont("s10 c" . ThemeText, "Segoe UI")

    ; Category Filter Row
    modal.SetFont("s9.5 Bold c" . ThemeAccent)
    modal.Add("Text", "x20 y16 w80 h24", "Category:")

    categories := [
        "All Categories",
        "✔ Compatible Only",
        "🔁 Structural Containers",
        "🧩 Universal Primitives",
        "⚡ Finance & Math",
        "⚡ Text",
        "⚡ Extraction",
        "⚡ Date & Time"
    ]

    modal.SetFont("s9.5 norm c" . ThemeText)
    ddlFilter := modal.Add("DropDownList", "x105 y12 w250 r9 Background" . ThemeSurface . " c" . ThemeText . " Choose1", categories)

    modal.SetFont("s9 c" . ThemeMuted)
    modal.Add("Text", "x375 y16 w50 h24", "Search:")
    editSearch := modal.Add("Edit", "x430 y12 w250 h26 Background" . ThemeSurface . " c" . ThemeText, "")

    ; Tools & Primitives ListView with Compatibility Communication
    modal.SetFont("s9 c" . ThemeText)
    lvTools := modal.Add("ListView", "x20 y48 w660 h280 Background" . ThemeSurface . " c" . ThemeText . " Grid -Multi", 
                         ["Tool ID", "Label", "Compatibility", "Category", "Description"])
    lvTools.ModifyCol(1, "115")
    lvTools.ModifyCol(2, "150")
    lvTools.ModifyCol(3, "130")
    lvTools.ModifyCol(4, "125")
    lvTools.ModifyCol(5, "130")

    ; Compute currently available in-scope outputs for compatibility analysis
    currentScopeOutputs := []
    inpSrc := WcCurrentRecipe.HasOwnProp("input_source") ? WcCurrentRecipe.input_source : "selection"
    if (inpSrc = "files") {
        currentScopeOutputs.Push({sourceRef: "input.files", type: "items<file>", label: "Initial Files (input.files)"})
    } else if (inpSrc != "none") {
        currentScopeOutputs.Push({sourceRef: "input.text", type: "text", label: "Initial Text (input.text)"})
    }

    for s in WcCurrentRecipe.steps {
        if (s.HasOwnProp("tool_id") && ToolCatalog.Has(s.tool_id)) {
            tObj := ToolCatalog.Get(s.tool_id)
            for out in tObj.outputs {
                currentScopeOutputs.Push({sourceRef: s.id . "." . out.name, type: out.type, label: s.id . "." . out.name})
            }
        }
    }

    ; Build Master List of Addable Items
    allToolsList := []

    ; 1. Structural Containers (Flat Loop) - Top priority (only for top-level)
    if (!IsObject(customCallback)) {
        hasArrayInput := false
        for outRef in currentScopeOutputs {
            if (SubStr(outRef.type, 1, 6) = "items<" || outRef.type = "any") {
                hasArrayInput := true
                break
            }
        }
        loopCompat := hasArrayInput ? "✔ Ready to wire" : "⚠️ Needs: Items<T>"

        allToolsList.Push({
            id: "loop_pair",
            label: "Loop Block (Start ➔ End)",
            category: "🔁 Structural Containers",
            description: "Inserts matching LOOP START and LOOP END boundary steps directly in the workflow",
            compat: loopCompat,
            isCompat: hasArrayInput
        })
    }

    ; 2. Registered Tools & Primitives
    rawTools := ToolCatalog.ListAll()
    for t in rawTools {
        catDisplay := t.category
        if (t.id = "loop_start" || t.id = "loop_end")
            catDisplay := "🔁 Structural Containers"
        else if (t.category = "Primitives")
            catDisplay := "🧩 Universal Primitives"
        else if InStr(t.category, "Finance") || InStr(t.category, "Math")
            catDisplay := "⚡ Finance & Math"
        else if InStr(t.category, "Text")
            catDisplay := "⚡ Text"
        else if InStr(t.category, "Extraction")
            catDisplay := "⚡ Extraction"
        else if InStr(t.category, "Date")
            catDisplay := "⚡ Date & Time"
        else
            catDisplay := "⚡ " . t.category

        toolCompat := "✔ Ready to wire"
        toolIsCompat := true
        wireRes := ToolCatalog.ResolveDefaultBindings(t.id, currentScopeOutputs)
        if (wireRes.needsInput && wireRes.missingInputs.Length > 0) {
            toolIsCompat := false
            missingType := ""
            for inp in t.inputs {
                if (inp.name = wireRes.missingInputs[1]) {
                    missingType := inp.type
                    break
                }
            }
            toolCompat := Format("⚠️ Needs: {1}", missingType != "" ? missingType : wireRes.missingInputs[1])
        }

        allToolsList.Push({
            id: t.id,
            label: t.label,
            category: catDisplay,
            description: t.description,
            compat: toolCompat,
            isCompat: toolIsCompat
        })
    }

    PopulateAddStepList() {
        lvTools.Delete()
        filterCat := categories[ddlFilter.Value]
        searchQuery := StrLower(Trim(editSearch.Value))

        for item in allToolsList {
            if (filterCat = "✔ Compatible Only" && !item.isCompat)
                continue
            if (filterCat != "All Categories" && filterCat != "✔ Compatible Only" && item.category != filterCat)
                continue

            if (searchQuery != "") {
                targetStr := StrLower(item.id . " " . item.label . " " . item.compat . " " . item.category . " " . item.description)
                if !InStr(targetStr, searchQuery)
                    continue
            }

            lvTools.Add("", item.id, item.label, item.compat, item.category, item.description)
        }

        if (lvTools.GetCount() > 0)
            lvTools.Modify(1, "Select Focus")
    }

    ddlFilter.OnEvent("Change", (*) => PopulateAddStepList())
    editSearch.OnEvent("Change", (*) => PopulateAddStepList())
    lvTools.OnEvent("DoubleClick", (*) => OnAddToolConfirm())

    PopulateAddStepList()

    modal.SetFont("s9.5 Bold")
    btnAddTool := modal.Add("Button", "x20 y340 w180 h34 Default", "➕ Add Selected Step")
    btnAddTool.OnEvent("Click", (*) => OnAddToolConfirm())

    modal.SetFont("s9.5 norm")
    btnCancel := modal.Add("Button", "x550 y340 w130 h34", "Cancel")
    btnCancel.OnEvent("Click", (*) => modal.Destroy())

    OnAddToolConfirm() {
        row := lvTools.GetNext()
        if (row <= 0)
            return

        chosenId := lvTools.GetText(row, 1)

        ; Sub-step callback mode
        if IsObject(customCallback) {
            modal.Destroy()
            customCallback(chosenId)
            return
        }

        ; Flat Loop Pair Addition
        if (chosenId = "loop_pair") {
            stepStartId := WcGetNextUniqueStepId(WcCurrentRecipe)
            tempSteps := WcCurrentRecipe.steps.Clone()
            tempSteps.Push({id: stepStartId})
            stepEndId := WcGetNextUniqueStepId({steps: tempSteps})
            idxStart := WcCurrentRecipe.steps.Length + 1

            itemsSrc := "input.text"
            for s in WcCurrentRecipe.steps {
                if (s.HasOwnProp("tool_id") && ToolCatalog.Has(s.tool_id)) {
                    tObj := ToolCatalog.Get(s.tool_id)
                    for out in tObj.outputs {
                        if (SubStr(out.type, 1, 6) = "items<" || out.type = "any")
                            itemsSrc := s.id . "." . out.name
                    }
                }
            }

            stepStart := {
                id: stepStartId,
                tool_id: "loop_start",
                tool_version: 1,
                settings: Map(),
                bindings: Map("items", itemsSrc)
            }
            stepEnd := {
                id: stepEndId,
                tool_id: "loop_end",
                tool_version: 1,
                settings: Map(),
                bindings: Map("collect", stepStartId . ".item")
            }

            WcCurrentRecipe.steps.Push(stepStart)
            WcCurrentRecipe.steps.Push(stepEnd)
            modal.Destroy()
            WcRefreshStepsList()
            WcSelectStep(idxStart)
            ShowToast("✔ Flat Loop added (" . stepStartId . " ... " . stepEndId . ")", 2000)
            return
        }

        tool := ToolCatalog.Get(chosenId)

        ; Compute in-scope outputs from current steps
        inScopeOutputs := []
        inpSrc := WcCurrentRecipe.HasOwnProp("input_source") ? WcCurrentRecipe.input_source : "selection"
        if (inpSrc = "files")
            inScopeOutputs.Push({sourceRef: "input.files", type: "items<file>", label: "Initial Files"})
        else if (inpSrc != "none")
            inScopeOutputs.Push({sourceRef: "input.text", type: "text", label: "Initial Text"})

        for s in WcCurrentRecipe.steps {
            if (s.HasOwnProp("tool_id") && ToolCatalog.Has(s.tool_id)) {
                tObj := ToolCatalog.Get(s.tool_id)
                for out in tObj.outputs {
                    inScopeOutputs.Push({
                        sourceRef: s.id . "." . out.name,
                        type: out.type,
                        label: s.id . " " . out.label,
                        isPrimary: (out.HasOwnProp("primary") && out.primary)
                    })
                }
            }
        }

        bindingsRes := ToolCatalog.ResolveDefaultBindings(chosenId, inScopeOutputs)

        newStepId := WcGetNextUniqueStepId(WcCurrentRecipe)
        createdStep := {
            id: newStepId,
            tool_id: chosenId,
            tool_version: tool.version,
            settings: Map(),
            bindings: bindingsRes.bindings
        }

        WcCurrentRecipe.steps.Push(createdStep)
        modal.Destroy()
        WcRefreshStepsList()
        WcSelectStep(WcCurrentRecipe.steps.Length)
        ShowToast("✔ Added: " . tool.label, 1800)
    }

    modal.Show("w700 h390")
}

WcTestRun() {
    global WcCurrentRecipe, WcStatusText, WcSampleInput, WcLatestTestResult
    valRes := RecipeModel.Validate(WcCurrentRecipe)
    if !valRes.valid {
        ShowToast("❌ Recipe Invalid: " . valRes.errors[1], 3000)
        WcStatusText.Text := "Validation Error: " . valRes.errors[1]
        return
    }

    WcStatusText.Text := "Running recipe test..."
    sampleTxt := (IsSet(WcSampleInput) && WcSampleInput != "") ? WcSampleInput : WcGetDefaultSampleForRecipe(WcCurrentRecipe)
    res := PipelineRunner.Execute(WcCurrentRecipe, sampleTxt)
    if res.success {
        outText := res.HasOwnProp("output") ? res.output : (res.HasOwnProp("final_output") ? res.final_output : "")
        outText := IsObject(outText) ? JsonHelper.Stringify(outText) : String(outText)
        WcLatestTestResult := outText
        try A_Clipboard := outText
        durMs := res.HasOwnProp("duration_ms") ? res.duration_ms : 0
        WcStatusText.Text := Format("✔ Test run succeeded! Output copied to clipboard ({1}ms)", durMs)
        ShowToast(Format("✔ Test Run Complete! Result copied to clipboard ({1}ms)", durMs), 2500)
    } else {
        WcStatusText.Text := "❌ Test run failed: " . res.error
        ShowToast("❌ Test run failed: " . res.error, 3000)
    }
}

WcCopyLatestTestResult() {
    global WcLatestTestResult
    if (IsSet(WcLatestTestResult) && WcLatestTestResult != "") {
        try A_Clipboard := WcLatestTestResult
        ShowToast("📋 Copied test run output to clipboard", 2000)
    } else {
        ShowToast("⚠️ No test result available to copy", 2000)
    }
}

WcGetNextUniqueStepId(recipe) {
    if (!IsObject(recipe) || !recipe.HasOwnProp("steps") || recipe.steps.Length = 0)
        return "step_1"

    existingIds := Map()
    maxIdx := 0
    for s in recipe.steps {
        sId := (Type(s) = "Map") ? (s.Has("id") ? String(s["id"]) : "") : (s.HasOwnProp("id") ? String(s.id) : "")
        if (sId != "") {
            existingIds[sId] := true
            if RegExMatch(sId, "^(?:step_|s)(\d+)$", &m) {
                val := Integer(m[1])
                if (val > maxIdx)
                    maxIdx := val
            }
        }
    }

    candidate := maxIdx + 1
    while existingIds.Has("step_" . candidate) {
        candidate++
    }
    return "step_" . candidate
}

WcGetDefaultSampleForRecipe(recipe) {
    if !IsObject(recipe) || !recipe.HasOwnProp("steps") || recipe.steps.Length = 0
        return "50000"

    hasLoop := false
    hasDateDiff := false
    hasDate := false
    hasCivilPyth := false
    hasCivilUnit := false
    hasPan := false
    hasGstin := false
    hasMath := false
    hasListOrText := false

    for s in recipe.steps {
        tId := s.HasOwnProp("tool_id") ? s.tool_id : ""
        if (tId = "loop_start")
            hasLoop := true
        else if (tId = "date_difference")
            hasDateDiff := true
        else if (tId = "date_convert_format" || tId = "date_financial_year")
            hasDate := true
        else if (tId = "civil_pythagoras")
            hasCivilPyth := true
        else if (tId = "civil_unit_convert")
            hasCivilUnit := true
        else if (tId = "extract_pan")
            hasPan := true
        else if (tId = "extract_gstin")
            hasGstin := true
        else if (tId = "math_evaluate" || tId = "math_percentage_change")
            hasMath := true
        else if (tId = "convert_case" || tId = "format_list" || tId = "clean_text_unwrap")
            hasListOrText := true
    }

    if hasDateDiff
        return "15/08/2026`n25/08/2026"
    if hasDate
        return "15/08/2026"
    if hasCivilPyth
        return "20ft 30ft"
    if hasCivilUnit
        return "100 sqft to sqm"
    if hasPan
        return "Vendor ABCDE1234F ref 99"
    if hasGstin
        return "Supplier GSTIN: 27ABCDE1234F1Z5"
    if hasMath
        return "1500 * 1.18 + 450"
    if hasListOrText
        return "Apple`nBanana`nOrange"
    if hasLoop
        return "50000`n12500`n75000"
    return "50000"
}

WcSaveRecipe() {
    global WcCurrentRecipe, WcStatusText
    valRes := RecipeModel.Validate(WcCurrentRecipe)
    if !valRes.valid {
        ShowToast("❌ Cannot Save: " . valRes.errors[1], 3000)
        WcStatusText.Text := "Cannot Save: " . valRes.errors[1]
        return
    }

    try {
        RecipeModel.Save(WcCurrentRecipe)
        ShowToast("✔ Recipe '" . WcCurrentRecipe.name . "' saved successfully!", 2500)
        WcStatusText.Text := "Saved to Recipes/" . WcCurrentRecipe.id . ".json"
        
        ; Refresh Palette dynamic registration if active
        if IsSet(LoadAndRegisterSavedRecipes)
            LoadAndRegisterSavedRecipes()
    } catch as err {
        ShowToast("❌ Save Failed: " . err.Message, 3000)
    }
}

; ======================================================================================================================
; Presentation Decorator: WcFormatOptionLabel
; Maps raw contract option values to concise, human-readable display labels.
; Falls back to String(rawVal) for any unrecognized combination — new tools work without GUI changes.
; ======================================================================================================================
WcFormatOptionLabel(toolId, settingName, rawVal) {
    static _labels := ""
    if (_labels = "") {
        _labels := Map()

        ; Date format IDs (shared across date_convert_format)
        _labels["format_id"] := Map(
            1, "1: DD/MM/YYYY",
            2, "2: DD-MM-YYYY",
            3, "3: DD.MM.YYYY",
            4, "4: DD/MM/YY",
            5, "5: DD-MM-YY",
            6, "6: DD Month YYYY",
            7, "7: Month DD, YYYY",
            8, "8: DD Month, YYYY",
            9, "9: DDDD, dd Month YYYY"
        )

        ; Case modes (convert_case)
        _labels["case_mode"] := Map(
            "upper", "UPPERCASE",
            "lower", "lowercase",
            "title", "Title Case",
            "sentence", "Sentence case",
            "snake", "snake_case",
            "kebab", "kebab-case",
            "camel", "camelCase"
        )

        ; List types (format_list)
        _labels["list_type"] := Map(
            "checklist", "Checklist ([ ])",
            "bullet", "Bullet List (• )",
            "numbered", "Numbered List (1. 2. 3.)",
            "sql", "SQL IN ('a', 'b')"
        )

        ; GST rate labels
        _labels["rate"] := Map(
            5, "5% GST",
            12, "12% GST",
            18, "18% GST (Standard)",
            28, "28% GST"
        )

        ; Delimiter labels (shared across split/join)
        _labels["delimiter"] := Map(
            "\n", "\n (Newlines)",
            "\n\n", "\n\n (Double Newline)",
            ",", ", (Comma)",
            ", ", ", (Comma + Space)",
            ";", "; (Semicolon)",
            "; ", "; (Semicolon + Space)",
            "\t", "\t (Tab)",
            " ", "  (Space)"
        )

        ; Filter mode labels
        _labels["mode:primitive_filter"] := Map(
            "keep", "keep (Keep Matches)",
            "exclude", "exclude (Exclude Matches)"
        )

        ; Slice mode labels
        _labels["mode:primitive_slice"] := Map(
            "top_n", "top_n (First N)",
            "last_n", "last_n (Last N)",
            "range", "range (Index Range)"
        )

        ; Output type labels
        _labels["output_type"] := Map(
            "text", "text (Text)",
            "number", "number (Number)"
        )

        ; Date format choices
        _labels["format"] := Map(
            "yyyy-MM-dd", "yyyy-MM-dd (ISO)",
            "dd-MMM-yyyy", "dd-MMM-yyyy",
            "dd/MM/yyyy", "dd/MM/yyyy",
            "MMMM d, yyyy", "MMMM d, yyyy"
        )
    }

    ; Try tool-specific key first (e.g., "mode:primitive_filter"), then generic key (e.g., "mode")
    toolKey := settingName . ":" . toolId
    if (_labels.Has(toolKey) && _labels[toolKey].Has(rawVal))
        return _labels[toolKey][rawVal]
    if (_labels.Has(settingName) && _labels[settingName].Has(rawVal))
        return _labels[settingName][rawVal]

    return String(rawVal)
}

; ======================================================================================================================
; Modal Dialog: WcShowOpenRecipeModal
; Allows browsing, selecting, and loading any saved recipe from Recipes/ catalog directly into Workflow Composer.
; ======================================================================================================================
WcShowOpenRecipeModal() {
    global WcOpenRecipeModalGui, WcCurrentRecipe
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeBorder, ThemePrimary, ThemeAccent

    if IsObject(WcOpenRecipeModalGui) {
        try WcOpenRecipeModalGui.Destroy()
        WcOpenRecipeModalGui := ""
    }

    allRecipes := RecipeModel.ListAll()
    if (allRecipes.Length = 0) {
        ShowToast("⚠️ No saved recipes found", 2000)
        return
    }

    WcOpenRecipeModalGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner", "Open Saved Recipe")
    WcOpenRecipeModalGui.BackColor := ThemeBg
    WcOpenRecipeModalGui.SetFont("s10 c" . ThemeText, "Segoe UI")

    ; Title Header
    WcOpenRecipeModalGui.SetFont("s10 Bold c" . ThemeAccent)
    WcOpenRecipeModalGui.Add("Text", "x20 y16 w580 h22", "📂 Saved Workflow Recipes")
    WcOpenRecipeModalGui.SetFont("s9 c" . ThemeMuted)
    WcOpenRecipeModalGui.Add("Text", "x20 y38 w580 h20", "Select a workflow recipe to open and edit in Composer.")

    ; ListView
    WcOpenRecipeModalGui.SetFont("s9 c" . ThemeText)
    lvRecipes := WcOpenRecipeModalGui.Add("ListView", "x20 y65 w580 h230 Background" . ThemeSurface . " c" . ThemeText . " Grid -Multi", 
                                        ["#", "Recipe Name", "Steps", "Input", "Sink", "Recipe ID"])
    lvRecipes.ModifyCol(1, "35 Center")
    lvRecipes.ModifyCol(2, 175)
    lvRecipes.ModifyCol(3, "50 Center")
    lvRecipes.ModifyCol(4, 75)
    lvRecipes.ModifyCol(5, 75)
    lvRecipes.ModifyCol(6, 150)

    currSelectedRow := 1
    for idx, r in allRecipes {
        rName := r.HasOwnProp("name") ? r.name : r.id
        numSteps := (r.HasOwnProp("steps") && Type(r.steps) = "Array") ? r.steps.Length : 0
        src := r.HasOwnProp("input_source") ? r.input_source : "selection"
        snk := r.HasOwnProp("sink") ? r.sink : "clipboard"
        lvRecipes.Add("", idx, rName, numSteps, src, snk, r.id)
        if (IsObject(WcCurrentRecipe) && WcCurrentRecipe.HasOwnProp("id") && WcCurrentRecipe.id = r.id)
            currSelectedRow := idx
    }
    lvRecipes.Modify(currSelectedRow, "Select Focus")

    ; Double-click to load
    lvRecipes.OnEvent("DoubleClick", (ctrl, row) => (row > 0 ? WcDoLoadSelected(row) : ""))

    ; Bottom Buttons
    WcOpenRecipeModalGui.SetFont("s9 Bold")
    btnLoad := WcOpenRecipeModalGui.Add("Button", "x20 y305 w140 h32 Default", "📂 Load Recipe")
    btnLoad.OnEvent("Click", (*) => WcDoLoadSelected(lvRecipes.GetNext()))

    btnCancel := WcOpenRecipeModalGui.Add("Button", "x480 y305 w120 h32", "Cancel [Esc]")
    btnCancel.OnEvent("Click", (*) => CloseOpenRecipeModal())

    CloseOpenRecipeModal() {
        global WcOpenRecipeModalGui
        if IsObject(WcOpenRecipeModalGui) {
            try WcOpenRecipeModalGui.Destroy()
            WcOpenRecipeModalGui := ""
        }
    }

    WcDoLoadSelected(rowIdx) {
        if (rowIdx <= 0 || rowIdx > allRecipes.Length) {
            ShowToast("⚠️ Please select a recipe from the list", 2000)
            return
        }
        chosenRecipe := allRecipes[rowIdx]
        CloseOpenRecipeModal()
        ShowWorkflowComposer(chosenRecipe)
        ShowToast("📂 Loaded: " . (chosenRecipe.HasOwnProp("name") ? chosenRecipe.name : chosenRecipe.id), 2000)
    }

    WcOpenRecipeModalGui.OnEvent("Escape", (*) => CloseOpenRecipeModal())
    WcOpenRecipeModalGui.OnEvent("Close", (*) => CloseOpenRecipeModal())
    WcOpenRecipeModalGui.Show("w620 h350")
}
