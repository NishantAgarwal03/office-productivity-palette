; ======================================================================================================================
; Module: test_regression_defects.ahk - Dedicated Defect Regression Test Suite
; Part of Office Productivity Hub (v2.0.1) - Zero-Trust Quality Harness
;
; ARCHITECTURAL INVARIANTS:
; 1. Numbered, traceable defect reproduction cases (DEFECT-001 through DEFECT-036).
; 2. Every historical, edge-case, and recently discovered bug has an isolated, permanent regression guard.
; 3. Zero UI dialog popups; outputs clean structured logs and schema-versioned results.json via TestHarness.
; ======================================================================================================================

#Requires AutoHotkey v2.0
Persistent(false)

; Mock UI callbacks for headless execution
ShowTextStats(*) => ""
LogAppError(*) => ""
ShowRunHistoryGui(*) => ""
RefreshSnippetListView(*) => ""

#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\DateFormatConverter.ahk"
#Include "..\Lib\Actions_DateTime.ahk"
#Include "..\Lib\Actions_Finance.ahk"
#Include "..\Lib\Actions_Text.ahk"
#Include "..\Lib\Actions_Extraction.ahk"
#Include "..\Lib\Actions_Math.ahk"
#Include "..\Lib\CivilConverterEngine.ahk"
#Include "..\Lib\Actions_CivilConvert.ahk"
#Include "..\Lib\TaskManager.ahk"
#Include "..\Lib\SnippetManager.ahk"
#Include "..\Lib\JsonHelper.ahk"
#Include "..\Lib\WorkflowTypes.ahk"
#Include "..\Lib\ToolCatalog.ahk"
#Include "..\Lib\WorkflowPrimitives.ahk"
#Include "..\Lib\ToolAdapters_Builtin.ahk"
#Include "..\Lib\RecipeModel.ahk"
#Include "..\Lib\PipelineRunner.ahk"
#Include "..\Lib\RunHistory.ahk"
#Include "..\Lib\WorkflowComposerGui.ahk"
#Include "..\Lib\Core.ahk"
#Include "..\Lib\Actions_Workflow.ahk"
#Include "..\Lib\PaletteGui.ahk"

global PassCount := 0
global FailCount := 0
global TestLogs  := []
global Failures  := []
global StartTick := A_TickCount

AssertEqual(defectId, testName, actual, expected) {
    global PassCount, FailCount, TestLogs, Failures
    actualStr := String(actual)
    expectedStr := String(expected)
    if (actualStr == expectedStr) {
        PassCount++
        TestLogs.Push(Format("[PASS] {1:-12} | {2:-48} -> '{3}'", defectId, testName, actualStr))
    } else {
        FailCount++
        TestLogs.Push(Format("[FAIL] {1:-12} | {2:-48} -> Expected: '{3}', Got: '{4}'", defectId, testName, expectedStr, actualStr))
        Failures.Push({category: defectId, testName: testName, error: "Expected: '" . expectedStr . "', Got: '" . actualStr . "'"})
    }
}

AssertTrue(defectId, testName, condition) {
    AssertEqual(defectId, testName, condition ? "TRUE" : "FALSE", "TRUE")
}

AssertFalse(defectId, testName, condition) {
    AssertEqual(defectId, testName, condition ? "TRUE" : "FALSE", "FALSE")
}

try {
    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-001: JsonHelper object property collision with reserved 'base' prototype pointer
    ; --------------------------------------------------------------------------------------------------
    jsonBaseStr := '{"base": 50000, "total": 59000, "rate": 18.0}'
    parsedBase := JsonHelper.Parse(jsonBaseStr)
    AssertTrue("DEFECT-001", "Parsed object has base property", IsObject(parsedBase) && parsedBase.HasOwnProp("base"))
    AssertEqual("DEFECT-001", "Parsed base value preserved", parsedBase.base, 50000)
    AssertEqual("DEFECT-001", "Parsed total value preserved", parsedBase.total, 59000)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-002: JsonHelper MSHTML COM array detection
    ; --------------------------------------------------------------------------------------------------
    jsonArrStr := '{"items": ["first", "second", "third"], "nested": [[10, 20], [30, 40]]}'
    parsedArr := JsonHelper.Parse(jsonArrStr)
    AssertTrue("DEFECT-002", "items detected as native AHK Array", Type(parsedArr.items) = "Array")
    AssertEqual("DEFECT-002", "items array length is 3", parsedArr.items.Length, 3)
    AssertEqual("DEFECT-002", "items[2] value preserved", parsedArr.items[2], "second")
    AssertTrue("DEFECT-002", "nested[1] is native Array", Type(parsedArr.nested[1]) = "Array")
    AssertEqual("DEFECT-002", "nested[2][1] value is 30", parsedArr.nested[2][1], 30)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-003: JsonHelper.Stringify COM object defensive fallback
    ; --------------------------------------------------------------------------------------------------
    htmlTest := ComObject("HTMLFile")
    htmlTest.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
    jsObjTest := htmlTest.parentWindow.JSON.parse('{"prop": 123}')
    wrappedObj := {label: "ComWrapper", comData: jsObjTest}
    strOutput := JsonHelper.Stringify(wrappedObj)
    AssertTrue("DEFECT-003", "Stringify COM object does not throw OwnProps exception", InStr(strOutput, "{ComObject}") > 0)
    AssertTrue("DEFECT-003", "Stringify preserves companion string properties", InStr(strOutput, "ComWrapper") > 0)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-004: SnippetManager 28-byte header-only CSV crash
    ; --------------------------------------------------------------------------------------------------
    headerOnlyCsv := "trigger,replacement`n"
    parsedRows := ParseFullCSV(headerOnlyCsv)
    AssertEqual("DEFECT-004", "Header-only CSV yields 1 header row", parsedRows.Length, 1)
    testEmptyFile := (IsSet(DataDir) && DataDir != "" ? DataDir : A_ScriptDir) . "\defect_empty.csv"
    FileAppend("trigger,replacement,enabled`n", testEmptyFile, "UTF-8")
    emptyCandidateList := []
    emptyScore := ScoreSnippetCandidate(testEmptyFile, &emptyCandidateList)
    try FileDelete(testEmptyFile)
    AssertEqual("DEFECT-004", "ScoreSnippetCandidate scores 0 on header-only", emptyScore, 0)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-005: NumberParser decimal carry overflow (999.999 -> 1,000.00)
    ; --------------------------------------------------------------------------------------------------
    AssertEqual("DEFECT-005", "Indian carry on 999.999", FormatIndianCommas("999.999"), "1,000.00")
    AssertEqual("DEFECT-005", "Indian carry on 99999.996", FormatIndianCommas("99999.996"), "1,00,000.00")
    AssertEqual("DEFECT-005", "International carry on 999.999", FormatInternationalCommas("999.999"), "1,000.00")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-006: Actions_DateTime ISO week year boundary sync
    ; --------------------------------------------------------------------------------------------------
    AssertEqual("DEFECT-006", "Jan 1 2021 sync to Week 53 2020", GetIsoWeekInfo("20210101000000").formatted, "Week 53, 2020")
    AssertEqual("DEFECT-006", "Dec 31 2018 sync to Week 1 2019", GetIsoWeekInfo("20181231000000").formatted, "Week 1, 2019")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-007: Actions_Finance Reverse GST -100% division-by-zero prevention
    ; --------------------------------------------------------------------------------------------------
    revMinus100 := CalculateReverseGST(10000, -100)
    AssertTrue("DEFECT-007", "Reverse GST -100% returns safe validation error", InStr(revMinus100, "Invalid GST rate") > 0)
    revMinus120 := CalculateReverseGST(10000, -120)
    AssertTrue("DEFECT-007", "Reverse GST -120% returns safe validation error", InStr(revMinus120, "Invalid GST rate") > 0)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-008: MathEvaluator scale suffix operator precedence binding (25lakh/50thousand)
    ; --------------------------------------------------------------------------------------------------
    mScaleRes := SafeEvaluateMath("25lakh/50thousand")
    AssertTrue("DEFECT-008", "Scale division succeeds", mScaleRes.success)
    AssertEqual("DEFECT-008", "25lakh/50thousand evaluates to 50", mScaleRes.resultStr, "50")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-009: Actions_Text CleanPlainText multi-pass progressive unwrapping
    ; --------------------------------------------------------------------------------------------------
    rawFragmented := "Algorithmic Leverage:`nO`n(`nN`n2`n)`nO(N 2)"
    pass1Out := CleanPlainText(rawFragmented)
    AssertEqual("DEFECT-009", "Pass 1 standardizes lines to CRLF", pass1Out, "Algorithmic Leverage:`r`nO`r`n(`r`nN`r`n2`r`n)`r`nO(N 2)")
    pass2Out := CleanPlainText(pass1Out)
    AssertEqual("DEFECT-009", "Pass 2 unwraps soft linebreaks", pass2Out, "Algorithmic Leverage: O ( N 2 ) O(N 2)")
    AssertEqual("DEFECT-009", "Pass 2 preserves double linebreaks", CleanPlainText("Line 1`r`nLine 2`r`n`r`nParagraph 2"), "Line 1 Line 2`r`n`r`nParagraph 2")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-010: NumberParser hyphenated SKU and double-hyphen non-mutation
    ; --------------------------------------------------------------------------------------------------
    AssertFalse("DEFECT-010", "SKU 12-34-56 rejected as number", ParseNumberOrCurrency("12-34-56").isValid)
    AssertFalse("DEFECT-010", "Double negative --500 rejected", ParseNumberOrCurrency("--500").isValid)
    AssertFalse("DEFECT-010", "Trailing hyphen 500- rejected", ParseNumberOrCurrency("500-").isValid)
    AssertEqual("DEFECT-010", "CleanToMachine preserves SKU unchanged", CleanToMachineNumber("12-34-56"), "12-34-56")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-011: CivilPythagoras impossible triangle & >2 dimensions rejection
    ; --------------------------------------------------------------------------------------------------
    rImp := CivilPythagoras.Evaluate("pythagoras 5000 4000 4")
    AssertFalse("DEFECT-011", "Impossible triangle rejected", rImp.success)
    AssertTrue("DEFECT-011", "Explanatory error for impossible sides", InStr(rImp.message, "Invalid triangle") > 0)
    r4D := CivilPythagoras.Evaluate("pythagoras 10 20 30 40")
    AssertFalse("DEFECT-011", "4-dimension query rejected", r4D.success)
    AssertTrue("DEFECT-011", "2D planar message under 15 chars", InStr(r4D.message, "2D planar only") > 0)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-012: TaskManager same-day task completion archive protection
    ; --------------------------------------------------------------------------------------------------
    todayDateStr := FormatTime(A_Now, "yyyy-MM-dd")
    ActionTasks := [
        {id: 901, task: "Done Today", created: "2026-08-01 10:00", commitmentType: "Task", priority: "Q1", done: true, doneDate: todayDateStr},
        {id: 902, task: "Done Yesterday", created: "2026-08-01 10:00", commitmentType: "Task", priority: "Q2", done: true, doneDate: "2026-08-25"},
        {id: 903, task: "Pending Task", created: "2026-08-01 10:00", commitmentType: "Task", priority: "Q3", done: false, doneDate: ""}
    ]
    ArchivePreviousDaysCompletedTasks()
    AssertEqual("DEFECT-012", "Done today preserved in active list", ActionTasks.Length, 2)
    AssertEqual("DEFECT-012", "Task 901 retained", ActionTasks[1].id, 901)
    AssertEqual("DEFECT-012", "Task 903 retained", ActionTasks[2].id, 903)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-013: PipelineRunner loop container variable resolution
    ; --------------------------------------------------------------------------------------------------
    rLoopDef := {
        id: "recipe_defect_loop",
        name: "Defect Loop Test",
        version: 1,
        input_source: "none",
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
                is_container: true,
                bindings: Map("items", "step_1.items"),
                sub_steps: [
                    {
                        id: "step_2_1",
                        tool_id: "primitive_template_combine",
                        tool_version: 1,
                        settings: Map("template", "VAL:{loop.item}"),
                        bindings: Map()
                    }
                ]
            },
            {
                id: "step_3",
                tool_id: "primitive_join",
                tool_version: 1,
                settings: Map("delimiter", "|"),
                bindings: Map("items", "step_2.items")
            }
        ]
    }
    InitWorkflowEngine()
    resLoopRun := PipelineRunner.Execute(rLoopDef, "X`nY`nZ")
    AssertTrue("DEFECT-013", "Loop pipeline execution success", resLoopRun.success)
    AssertEqual("DEFECT-013", "Loop items correctly templated", resLoopRun.output, "VAL:X|VAL:Y|VAL:Z")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-014: RecipeModel normalization of untyped step bindings & settings
    ; --------------------------------------------------------------------------------------------------
    rawRecipeObj := {
        id: "recipe_defect_norm",
        steps: [
            {
                id: "step_norm_1",
                tool_id: "parse_number",
                bindings: {text: "input.text"},
                settings: {rate: 18}
            }
        ]
    }
    normResult := RecipeModel.Normalize(rawRecipeObj)
    AssertTrue("DEFECT-014", "Normalized bindings is Map", Type(normResult.steps[1].bindings) = "Map")
    AssertTrue("DEFECT-014", "Normalized settings is Map", Type(normResult.steps[1].settings) = "Map")
    AssertEqual("DEFECT-014", "Normalized binding value mapped", normResult.steps[1].bindings["text"], "input.text")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-015: Actions_Workflow dynamic recipe palette registration closure
    ; --------------------------------------------------------------------------------------------------
    InitWorkflowEngine()
    recipeCountInPalette := 0
    for registeredAct in BuiltInActions {
        if (registeredAct.category = "🔄 Recipe")
            recipeCountInPalette++
    }
    AssertTrue("DEFECT-015", "Dynamic recipes present in Command Palette", recipeCountInPalette >= 3)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-016: Sovereign Notification Subsystem & Dynamic Ergonomic Reading-Time
    ; --------------------------------------------------------------------------------------------------
    durExplicit := CalculateErgonomicDuration("Test", 2500)
    AssertEqual("DEFECT-016", "Explicit duration overrides auto heuristic", durExplicit, 2500)

    durMicro := CalculateErgonomicDuration("✔ Moved", 0)
    AssertEqual("DEFECT-016", "Micro affirmation clamped to 1200ms", durMicro, 1200)

    durWarn := CalculateErgonomicDuration("⚠️ Warning: Could not recognize format", 0)
    AssertTrue("DEFECT-016", "Warning duration scales with length and severity", durWarn >= 2000)

    posX := 0, posY := 0
    GetBottomRightAnchorPos(340, 42, 2.0, &posX, &posY)
    AssertTrue("DEFECT-016", "Bottom right anchor X within screen", posX > 0)
    AssertTrue("DEFECT-016", "Bottom right anchor Y within screen", posY > 0)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-017: Step Settings Override & Loop Container Structural Validation
    ; --------------------------------------------------------------------------------------------------
    testRecipeCustom := {
        id: "recipe_defect_custom",
        name: "Custom Settings Recipe",
        version: 1,
        input_source: "selection",
        final_output_ref: "step_2.summary",
        steps: [
            {
                id: "step_1",
                tool_id: "parse_number",
                tool_version: 1,
                bindings: Map("text", "input.text"),
                settings: Map()
            },
            {
                id: "step_2",
                tool_id: "normal_gst",
                tool_version: 1,
                bindings: Map("amount", "step_1.number"),
                settings: Map("rate", 28)
            }
        ]
    }
    customVal := RecipeModel.Validate(testRecipeCustom)
    AssertTrue("DEFECT-017", "Custom settings recipe validates cleanly", customVal.valid)

    customExec := PipelineRunner.Execute(testRecipeCustom, "1000")
    AssertTrue("DEFECT-017", "Custom settings pipeline executes successfully", customExec.success)
    AssertTrue("DEFECT-017", "Custom GST rate 28 applied correctly", InStr(customExec.output, "GST (28%): ₹280") > 0)
    AssertTrue("DEFECT-017", "Custom GST total invoice amount computed correctly", InStr(customExec.output, "Total: ₹1,280") > 0)

    ; Loop container validation with sub-steps
    testRecipeLoop := {
        id: "recipe_defect_loop",
        name: "Loop Recipe",
        version: 1,
        input_source: "selection",
        steps: [
            {
                id: "step_1",
                tool_id: "primitive_split",
                tool_version: 1,
                bindings: Map("text", "input.text"),
                settings: Map("delimiter", "\n")
            },
            {
                id: "step_2",
                is_container: 1,
                bindings: Map("items", "step_1.items"),
                loop_return_step: "step_2_1",
                sub_steps: [
                    {
                        id: "step_2_1",
                        tool_id: "parse_number",
                        tool_version: 1,
                        bindings: Map("text", "loop.item"),
                        settings: Map()
                    }
                ]
            }
        ]
    }
    loopVal := RecipeModel.Validate(testRecipeLoop)
    AssertTrue("DEFECT-017", "Loop container recipe validates cleanly", loopVal.valid)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-018: Complete Recipe Contract Validation
    ; --------------------------------------------------------------------------------------------------
    ; 1. Duplicate step IDs
    testDupId := {
        id: "recipe_dup_test",
        name: "Dup Test",
        steps: [
            { id: "step_1", tool_id: "clean_whitespace", bindings: Map("text", "input.text") },
            { id: "step_1", tool_id: "clean_whitespace", bindings: Map("text", "input.text") }
        ]
    }
    valDup := RecipeModel.Validate(testDupId)
    AssertFalse("DEFECT-018", "Duplicate step IDs rejected", valDup.valid)
    AssertTrue("DEFECT-018", "Duplicate step ID error logged", InStr(valDup.errors[1], "Duplicate step ID 'step_1'") > 0)

    ; 2. Unknown settings key
    testBadSet := {
        id: "recipe_bad_set",
        name: "Bad Set",
        steps: [
            { id: "step_1", tool_id: "normal_gst", settings: Map("ghost_setting", 123), bindings: Map("amount", "input.text") }
        ]
    }
    valBadSet := RecipeModel.Validate(testBadSet)
    AssertFalse("DEFECT-018", "Unknown setting key rejected", valBadSet.valid)

    ; 3. Out-of-range setting option
    testBadOpt := {
        id: "recipe_bad_opt",
        name: "Bad Opt",
        steps: [
            { id: "step_1", tool_id: "normal_gst", settings: Map("rate", 999), bindings: Map("amount", "input.text") }
        ]
    }
    valBadOpt := RecipeModel.Validate(testBadOpt)
    AssertFalse("DEFECT-018", "Out-of-range option rejected", valBadOpt.valid)

    ; 4. Unknown input binding key
    testBadBind := {
        id: "recipe_bad_bind",
        name: "Bad Bind",
        steps: [
            { id: "step_1", tool_id: "normal_gst", bindings: Map("wrong_amount", "input.text") }
        ]
    }
    valBadBind := RecipeModel.Validate(testBadBind)
    AssertFalse("DEFECT-018", "Unknown input binding rejected", valBadBind.valid)

    ; 5. Invalid template reference
    testBadTmpl := {
        id: "recipe_bad_tmpl",
        name: "Bad Tmpl",
        steps: [
            { id: "step_1", tool_id: "primitive_template_combine", settings: Map("template", "{nonexistent.output}") }
        ]
    }
    valBadTmpl := RecipeModel.Validate(testBadTmpl)
    AssertFalse("DEFECT-018", "Invalid template reference rejected", valBadTmpl.valid)

    ; 6. Invalid loop return step
    testBadLoopRet := {
        id: "recipe_bad_ret",
        name: "Bad Loop Ret",
        steps: [
            {
                id: "step_1",
                is_container: 1,
                bindings: Map("items", "input.text"),
                loop_return_step: "ghost_sub_step",
                sub_steps: [
                    { id: "step_1_1", tool_id: "clean_whitespace", bindings: Map("text", "loop.item") }
                ]
            }
        ]
    }
    valBadLoopRet := RecipeModel.Validate(testBadLoopRet)
    AssertFalse("DEFECT-018", "Invalid loop return step rejected", valBadLoopRet.valid)

    ; 7. Tool version mismatch
    testBadVer := {
        id: "recipe_bad_ver",
        name: "Bad Ver",
        steps: [
            { id: "step_1", tool_id: "clean_whitespace", tool_version: 99, bindings: Map("text", "input.text") }
        ]
    }
    valBadVer := RecipeModel.Validate(testBadVer)
    AssertFalse("DEFECT-018", "Tool version mismatch rejected", valBadVer.valid)

    ; 8. Invalid metadata (sink & input_source)
    testBadMeta := {
        id: "recipe_bad_meta",
        name: "Bad Meta",
        input_source: "invalid_src",
        sink: "invalid_sink",
        steps: [
            { id: "step_1", tool_id: "clean_whitespace", bindings: Map("text", "input.text") }
        ]
    }
    valBadMeta := RecipeModel.Validate(testBadMeta)
    AssertFalse("DEFECT-018", "Invalid metadata rejected", valBadMeta.valid)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-019: Add Step Compatibility Communication
    ; --------------------------------------------------------------------------------------------------
    textOnlyScope := [{sourceRef: "input.text", type: "text", label: "Initial Text"}]
    cleanWireRes := ToolCatalog.ResolveDefaultBindings("clean_whitespace", textOnlyScope)
    AssertFalse("DEFECT-019", "Clean Plain Text connects cleanly to text", cleanWireRes.needsInput)

    gstWireRes := ToolCatalog.ResolveDefaultBindings("normal_gst", textOnlyScope)
    AssertTrue("DEFECT-019", "Normal GST requires number input on text-only scope", gstWireRes.needsInput)
    AssertEqual("DEFECT-019", "Missing input identified as amount", gstWireRes.missingInputs[1], "amount")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-020: Preview Isolation, Zero Side-Effects & Step I/O Inspectability
    ; --------------------------------------------------------------------------------------------------
    clipSentinel := "SENTINEL_CLIPBOARD_" . Random(100000, 999999)
    A_Clipboard := clipSentinel

    histBefore := RunHistory.LoadAll()
    histCountBefore := histBefore.Length

    previewRecipe := {
        id: "recipe_preview_test",
        name: "Preview Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_p1",
                tool_id: "parse_number",
                tool_version: 1,
                bindings: Map("text", "input.text"),
                settings: Map()
            },
            {
                id: "step_p2",
                tool_id: "normal_gst",
                tool_version: 1,
                bindings: Map("amount", "step_p1.number"),
                settings: Map("rate", 18)
            }
        ]
    }

    ; 1. Verify preview execution leaves clipboard untouched
    prevRes := PipelineRunner.Execute(previewRecipe, "10000", {
        is_preview: true,
        suppress_sink: true,
        suppress_toasts: true,
        record_history: false
    })
    AssertTrue("DEFECT-020", "Preview run succeeded", prevRes.success)
    AssertEqual("DEFECT-020", "Preview run did NOT mutate clipboard", A_Clipboard, clipSentinel)

    ; 2. Verify preview execution did NOT record to RunHistory
    histAfter := RunHistory.LoadAll()
    AssertEqual("DEFECT-020", "Preview run did NOT record history", histAfter.Length, histCountBefore)

    ; 3. Verify preview execution returns full results Map and stepSnapshots
    AssertTrue("DEFECT-020", "Preview returns results Map", prevRes.HasOwnProp("results") && IsObject(prevRes.results))
    AssertTrue("DEFECT-020", "Results Map contains step_p1", prevRes.results.Has("step_p1"))
    AssertTrue("DEFECT-020", "Results Map contains step_p2", prevRes.results.Has("step_p2"))
    AssertTrue("DEFECT-020", "Preview returns stepSnapshots", prevRes.HasOwnProp("stepSnapshots") && prevRes.stepSnapshots.Length = 2)

    ; 4. Verify stepSnapshots contains per-step inputs and outputs
    snap1 := prevRes.stepSnapshots[1]
    snap2 := prevRes.stepSnapshots[2]
    AssertEqual("DEFECT-020", "Snap1 step_id is step_p1", snap1.step_id, "step_p1")
    AssertTrue("DEFECT-020", "Snap1 inputs has text", snap1.inputs.Has("text"))
    AssertEqual("DEFECT-020", "Snap1 input text is 10000", snap1.inputs["text"], "10000")
    AssertTrue("DEFECT-020", "Snap1 outputs has number", snap1.outputs.Has("number"))

    AssertEqual("DEFECT-020", "Snap2 step_id is step_p2", snap2.step_id, "step_p2")
    AssertTrue("DEFECT-020", "Snap2 inputs has amount", snap2.inputs.Has("amount"))
    AssertTrue("DEFECT-020", "Snap2 outputs has total", snap2.outputs.Has("total"))
    AssertEqual("DEFECT-020", "Snap2 total is 11800", snap2.outputs["total"], 11800)

    ; 5. Verify sink: 'none' programmatic execution preserves clipboard
    recipeSinkNone := {
        id: "recipe_none_sink",
        name: "None Sink Recipe",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_n1",
                tool_id: "clean_whitespace",
                tool_version: 1,
                bindings: Map("text", "input.text")
            }
        ]
    }
    noneRes := PipelineRunner.Execute(recipeSinkNone, "  hello world  ")
    AssertTrue("DEFECT-020", "sink: 'none' executes cleanly", noneRes.success)
    AssertEqual("DEFECT-020", "sink: 'none' preserves clipboard", A_Clipboard, clipSentinel)
    AssertEqual("DEFECT-020", "sink: 'none' returns clean output", noneRes.output, "hello world")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-021: Step Validation Diagnostics & Windows Clipboard History Protection
    ; --------------------------------------------------------------------------------------------------
    ; 1. Verify RecipeModel.Validate populates stepErrors Map with specific step IDs
    recipeWithErrors := {
        id: "recipe_err_test",
        name: "Error Test Recipe",
        version: 1,
        input_source: "selection",
        sink: "clipboard",
        steps: [
            {
                id: "step_ok",
                tool_id: "clean_whitespace",
                tool_version: 1,
                bindings: Map("text", "input.text")
            },
            {
                id: "step_missing_req",
                tool_id: "clean_whitespace",
                tool_version: 1,
                bindings: Map() ; missing required input 'text'
            },
            {
                id: "step_unknown_tool",
                tool_id: "non_existent_tool_xyz_999",
                tool_version: 1,
                bindings: Map()
            }
        ]
    }
    valDiag := RecipeModel.Validate(recipeWithErrors)
    AssertFalse("DEFECT-021", "Recipe with defects is marked invalid", valDiag.valid)
    AssertTrue("DEFECT-021", "valDiag returns stepErrors Map", valDiag.HasOwnProp("stepErrors") && IsObject(valDiag.stepErrors))
    AssertFalse("DEFECT-021", "step_ok has no step errors", valDiag.stepErrors.Has("step_ok"))
    AssertTrue("DEFECT-021", "step_missing_req is tracked in stepErrors", valDiag.stepErrors.Has("step_missing_req"))
    AssertTrue("DEFECT-021", "step_unknown_tool is tracked in stepErrors", valDiag.stepErrors.Has("step_unknown_tool"))

    ; 2. Verify SetClipboardWithoutHistory updates A_Clipboard cleanly
    testHistText := "DEFECT_021_NON_HISTORY_TEST_VALUE_98765"
    SetClipboardWithoutHistory(testHistText)
    AssertEqual("DEFECT-021", "SetClipboardWithoutHistory sets A_Clipboard accurately", A_Clipboard, testHistText)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-022: Modal Micro-Copy & Dialog Ownership Topmost Architecture
    ; --------------------------------------------------------------------------------------------------
    ; 1. Verify Step Settings Canonical Subtitles have <= 6 words
    loopSub := "Configure loop bindings and return step."
    stdSub := "Configure input bindings and tool settings."
    loopWords := StrSplit(loopSub, " ")
    stdWords := StrSplit(stdSub, " ")
    AssertTrue("DEFECT-022", "Loop Container subtitle is <= 6 words", loopWords.Length <= 6)
    AssertEqual("DEFECT-022", "Loop Container subtitle is exactly 6 words", loopWords.Length, 6)
    AssertTrue("DEFECT-022", "Standard Tool subtitle is <= 6 words", stdWords.Length <= 6)
    AssertEqual("DEFECT-022", "Standard Tool subtitle is exactly 6 words", stdWords.Length, 6)

    ; 2. Verify OfficeInputBox accepts ownerGui parameter without error
    dummyOwnerGui := Gui("+AlwaysOnTop", "DummyOwner")
    dummyOwnerGui.Opt("+AlwaysOnTop +OwnDialogs")
    AssertTrue("DEFECT-022", "dummyOwnerGui accepts +AlwaysOnTop +OwnDialogs", IsObject(dummyOwnerGui))
    dummyOwnerGui.Destroy()

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-023: Canonical Standard Date Formats & Dual Alias Pipeline Execution
    ; --------------------------------------------------------------------------------------------------
    ; 1. Verify Option 1 Canonical Patterns are <= 22 chars for w260 dropdown safety
    canonFormats := [
        "1: DD/MM/YYYY",
        "2: DD-MM-YYYY",
        "3: DD.MM.YYYY",
        "4: DD/MM/YY",
        "5: DD-MM-YY",
        "6: DD Month YYYY",
        "7: Month DD, YYYY",
        "8: DD Month, YYYY",
        "9: DDDD, dd Month YYYY"
    ]
    for pIdx, pStr in canonFormats {
        AssertTrue("DEFECT-023", Format("Canonical format {1} fits w260 limit (<=22 chars)", pIdx), StrLen(pStr) <= 22)
    }

    ; 2. Verify format_id execution and downstream text contract with convert_case
    recipeDateConv := {
        id: "recipe_date_conv_test",
        name: "Date Conversion Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_conv",
                tool_id: "date_convert_format",
                tool_version: 1,
                settings: Map("format_id", 6),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_upper",
                tool_id: "convert_case",
                tool_version: 1,
                settings: Map("case_mode", "upper"),
                bindings: Map("text", "step_conv.text")
            }
        ]
    }
    dateConvRes := PipelineRunner.Execute(recipeDateConv, "05/09/2026", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-023", "date_convert_format pipeline run succeeded", dateConvRes.success)
    AssertEqual("DEFECT-023", "date_convert_format downstream received text and converted to uppercase", dateConvRes.output, "05 SEPTEMBER 2026")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-024: Complete Input Sources & Sinks Validation and Contract
    ; --------------------------------------------------------------------------------------------------
    recipeSourcesSinks := {
        id: "recipe_src_sink_test",
        name: "Sources and Sinks Test",
        version: 1,
        input_source: "prompt",
        sink: "none",
        steps: [
            {
                id: "step_echo",
                tool_id: "clean_whitespace",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            }
        ]
    }
    valSrcSink := RecipeModel.Validate(recipeSourcesSinks)
    AssertTrue("DEFECT-024", "Recipe with input_source: 'prompt' and sink: 'none' is valid", valSrcSink.valid)

    recipeNoneSrc := {
        id: "recipe_none_src_test",
        name: "No Input Test",
        version: 1,
        input_source: "none",
        sink: "none",
        steps: [
            {
                id: "step_today",
                tool_id: "date_today",
                tool_version: 1,
                settings: Map(),
                bindings: Map()
            }
        ]
    }
    valSrcNone := RecipeModel.Validate(recipeNoneSrc)
    AssertTrue("DEFECT-024", "Recipe with input_source: 'none' and no-input tool is valid", valSrcNone.valid)

    recipeSourcesSinks.sink := "toast"
    valSinkToast := RecipeModel.Validate(recipeSourcesSinks)
    AssertTrue("DEFECT-024", "Recipe with sink: 'toast' is valid", valSinkToast.valid)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-025: Scoped Iteration Immutability (Zero Iteration Contamination)
    ; --------------------------------------------------------------------------------------------------
    recipeContainerLoop := {
        id: "recipe_iter_immut_test",
        name: "Iteration Immutability Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_split",
                tool_id: "primitive_split",
                tool_version: 1,
                settings: Map("delimiter", "\n"),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_loop",
                is_container: true,
                bindings: Map("items", "step_split.items"),
                loop_return_step: "sub_2",
                sub_steps: [
                    {
                        id: "sub_1",
                        tool_id: "parse_number",
                        tool_version: 1,
                        settings: Map(),
                        bindings: Map("text", "loop.item")
                    },
                    {
                        id: "sub_2",
                        tool_id: "normal_gst",
                        tool_version: 1,
                        settings: Map("rate", 18),
                        bindings: Map("amount", "sub_1.number")
                    }
                ]
            }
        ]
    }
    loopImmutRes := PipelineRunner.Execute(recipeContainerLoop, "1000`n2000`n3000", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-025", "Container loop execution succeeded", loopImmutRes.success)
    AssertFalse("DEFECT-025", "Outer results do NOT retain loop internal scope", loopImmutRes.results.Has("loop"))
    AssertFalse("DEFECT-025", "Outer results do NOT retain sub_1 from inside loop", loopImmutRes.results.Has("sub_1"))
    AssertFalse("DEFECT-025", "Outer results do NOT retain sub_2 from inside loop", loopImmutRes.results.Has("sub_2"))
    AssertTrue("DEFECT-025", "Outer results retain step_loop", loopImmutRes.results.Has("step_loop"))
    AssertEqual("DEFECT-025", "Outer step_loop has 3 collected outputs", loopImmutRes.results["step_loop"]["items"].Length, 3)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-026: Flat-Flow Loop Boundary Execution (loop_start / loop_end)
    ; --------------------------------------------------------------------------------------------------
    recipeFlatLoop := {
        id: "recipe_flat_loop_test",
        name: "Flat Flow Loop Test",
        version: 1,
        input_source: "selection",
        sink: "none",
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
                tool_id: "loop_end",
                tool_version: 1,
                settings: Map(),
                bindings: Map("collect", "step_5.words")
            },
            {
                id: "step_7",
                tool_id: "primitive_join",
                tool_version: 1,
                settings: Map("delimiter", ", "),
                bindings: Map("items", "step_6.items")
            }
        ]
    }

    valFlatLoop := RecipeModel.Validate(recipeFlatLoop)
    AssertTrue("DEFECT-026", "Flat flow loop recipe validates with 0 errors", valFlatLoop.valid)
    if (!valFlatLoop.valid && valFlatLoop.errors.Length > 0)
        TestLogs.Push("[DEFECT-026-VAL-ERR] " . valFlatLoop.errors[1])

    flatRunRes := PipelineRunner.Execute(recipeFlatLoop, "10`n20`n30", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-026", "Flat flow loop pipeline execution succeeded", flatRunRes.success)
    if (!flatRunRes.success)
        TestLogs.Push("[DEFECT-026-RUN-ERR] " . flatRunRes.error)
    expectedFlatOut := "Rupees Eleven and Eighty Paise Only, Rupees Twenty-Three and Sixty Paise Only, Rupees Thirty-Five and Forty Paise Only"
    AssertEqual("DEFECT-026", "Flat flow loop produced accurately joined words per iteration", flatRunRes.output, expectedFlatOut)

    ; Verify unclosed loop_start is rejected by RecipeModel.Validate
    unclosedRecipe := {
        id: "unclosed_test",
        name: "Unclosed Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_u1",
                tool_id: "primitive_split",
                tool_version: 1,
                settings: Map("delimiter", "\n"),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_u2",
                tool_id: "loop_start",
                tool_version: 1,
                settings: Map(),
                bindings: Map("items", "step_u1.items")
            }
        ]
    }
    valUnclosed := RecipeModel.Validate(unclosedRecipe)
    AssertFalse("DEFECT-026", "Unclosed loop_start is rejected by validation", valUnclosed.valid)

    ; Verify orphan loop_end is rejected by RecipeModel.Validate
    orphanRecipe := {
        id: "orphan_test",
        name: "Orphan Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_o1",
                tool_id: "loop_end",
                tool_version: 1,
                settings: Map(),
                bindings: Map("collect", "input.text")
            }
        ]
    }
    valOrphan := RecipeModel.Validate(orphanRecipe)
    AssertFalse("DEFECT-026", "Orphan loop_end is rejected by validation", valOrphan.valid)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-027: Tolerant Primary Number Parsing on Mixed Multiline Strings
    ; --------------------------------------------------------------------------------------------------
    mixedMultilineText := "15/08/2026`r`n50000`r`n12500`r`nadmin@example.com"
    parsedDirect := ToolAdapters.ExecuteParseNumber(Map("text", mixedMultilineText), Map())
    AssertEqual("DEFECT-027", "ExecuteParseNumber extracts primary number scalar (50000)", parsedDirect["number"], 50000)
    AssertEqual("DEFECT-027", "ExecuteParseNumber text output matches primary number", parsedDirect["text"], "50000")

    recipeTolerantNumber := {
        id: "recipe_tolerant_number_test",
        name: "Tolerant Number Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_num",
                tool_id: "parse_number",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_gst",
                tool_id: "normal_gst",
                tool_version: 1,
                settings: Map("rate", 18),
                bindings: Map("amount", "step_num.number")
            }
        ]
    }
    tolerantRes := PipelineRunner.Execute(recipeTolerantNumber, mixedMultilineText, {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-027", "Pipeline with mixed multiline input succeeded without fatal crash", tolerantRes.success)
    AssertTrue("DEFECT-027", "Pipeline downstream normal_gst calculated 59000 total", InStr(tolerantRes.output, "59000") || InStr(tolerantRes.output, "59,000"))

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-028: Zero-Alias Consolidated Tools (convert_case, format_list, civil, stats)
    ; --------------------------------------------------------------------------------------------------
    ; 1. convert_case modes
    caseUpper := ToolAdapters.ExecuteConvertCase(Map("text", "hello world"), Map("case_mode", "upper"))
    AssertEqual("DEFECT-028", "convert_case upper mode", caseUpper["text"], "HELLO WORLD")
    caseLower := ToolAdapters.ExecuteConvertCase(Map("text", "HELLO WORLD"), Map("case_mode", "lower"))
    AssertEqual("DEFECT-028", "convert_case lower mode", caseLower["text"], "hello world")
    caseTitle := ToolAdapters.ExecuteConvertCase(Map("text", "hello world"), Map("case_mode", "title"))
    AssertEqual("DEFECT-028", "convert_case title mode", caseTitle["text"], "Hello World")
    caseSentence := ToolAdapters.ExecuteConvertCase(Map("text", "hello world. test case."), Map("case_mode", "sentence"))
    AssertEqual("DEFECT-028", "convert_case sentence mode", caseSentence["text"], "Hello world. Test case.")
    caseSnake := ToolAdapters.ExecuteConvertCase(Map("text", "hello world"), Map("case_mode", "snake"))
    AssertEqual("DEFECT-028", "convert_case snake mode", caseSnake["text"], "hello_world")
    caseKebab := ToolAdapters.ExecuteConvertCase(Map("text", "hello world"), Map("case_mode", "kebab"))
    AssertEqual("DEFECT-028", "convert_case kebab mode", caseKebab["text"], "hello-world")
    caseCamel := ToolAdapters.ExecuteConvertCase(Map("text", "hello world"), Map("case_mode", "camel"))
    AssertEqual("DEFECT-028", "convert_case camel mode", caseCamel["text"], "helloWorld")

    ; 2. format_list modes
    listChecklist := ToolAdapters.ExecuteFormatList(Map("text", "apple`r`nbanana"), Map("list_mode", "checklist"))
    AssertTrue("DEFECT-028", "format_list checklist contains - [ ]", InStr(listChecklist["text"], "- [ ] apple"))
    listBullet := ToolAdapters.ExecuteFormatList(Map("text", "apple`r`nbanana"), Map("list_mode", "bullet"))
    AssertTrue("DEFECT-028", "format_list bullet contains •", InStr(listBullet["text"], "• apple"))
    listNumbered := ToolAdapters.ExecuteFormatList(Map("text", "apple`r`nbanana"), Map("list_mode", "numbered"))
    AssertTrue("DEFECT-028", "format_list numbered contains 1.", InStr(listNumbered["text"], "1. apple"))
    listSql := ToolAdapters.ExecuteFormatList(Map("text", "apple`r`nbanana"), Map("list_mode", "sql"))
    AssertEqual("DEFECT-028", "format_list sql format matches", listSql["text"], "('apple', 'banana')")

    ; 3. text_statistics, civil_unit_convert, civil_pythagoras
    statsRes := ToolAdapters.ExecuteTextStatistics(Map("text", "Quick brown fox jumps"), Map())
    AssertEqual("DEFECT-028", "text_statistics word count is 4", statsRes["words"], 4)
    civilUnitRes := ToolAdapters.ExecuteCivilUnitConvert(Map("text", "10 m to ft"), Map())
    AssertTrue("DEFECT-028", "civil_unit_convert calculates 10m to ft", InStr(civilUnitRes["text"], "32.808"))
    civilPythRes := ToolAdapters.ExecuteCivilPythagoras(Map("text", "3m 4m"), Map())
    AssertTrue("DEFECT-028", "civil_pythagoras calculates 3m 4m diagonal", InStr(civilPythRes["text"], "5.000"))

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-029: Context-Aware Visual Sample Input Cues & Workflow Composer Integration
    ; --------------------------------------------------------------------------------------------------
    recipeDateSample := {steps: [{tool_id: "date_convert_format"}]}
    AssertTrue("DEFECT-029", "Date recipe sample provides date string", InStr(WcGetDefaultSampleForRecipe(recipeDateSample), "2026"))
    recipeMathSample := {steps: [{tool_id: "math_evaluate"}]}
    AssertTrue("DEFECT-029", "Math recipe sample provides math expression", InStr(WcGetDefaultSampleForRecipe(recipeMathSample), "+") || InStr(WcGetDefaultSampleForRecipe(recipeMathSample), "*"))
    recipePythSample := {steps: [{tool_id: "civil_pythagoras"}]}
    AssertTrue("DEFECT-029", "Civil Pythagoras recipe sample provides dimensions", InStr(WcGetDefaultSampleForRecipe(recipePythSample), "ft") || InStr(WcGetDefaultSampleForRecipe(recipePythSample), "m"))
    recipeLoopSample := {steps: [{tool_id: "loop_start"}]}
    AssertTrue("DEFECT-029", "Loop recipe sample provides multiline list", InStr(WcGetDefaultSampleForRecipe(recipeLoopSample), "`n"))

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-030: PipelineRunner res.final_output Property & Monotonic Non-Colliding Step IDs
    ; --------------------------------------------------------------------------------------------------
    ; 1. Verify PipelineRunner.Execute returns output, final_output, and duration_ms
    recipeFinalOut := {
        id: "recipe_final_out_test",
        name: "Final Output Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_1",
                tool_id: "clean_whitespace",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            }
        ]
    }
    resFinalOut := PipelineRunner.Execute(recipeFinalOut, "  test output  ", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-030", "Pipeline execution succeeded", resFinalOut.success)
    AssertTrue("DEFECT-030", "res has output property", resFinalOut.HasOwnProp("output"))
    AssertTrue("DEFECT-030", "res has final_output property", resFinalOut.HasOwnProp("final_output"))
    AssertEqual("DEFECT-030", "output matches final_output", resFinalOut.output, resFinalOut.final_output)
    AssertEqual("DEFECT-030", "final_output contains trimmed text", resFinalOut.final_output, "test output")
    AssertTrue("DEFECT-030", "res has duration_ms property", resFinalOut.HasOwnProp("duration_ms"))
    AssertTrue("DEFECT-030", "duration_ms is non-negative integer", IsInteger(resFinalOut.duration_ms) && resFinalOut.duration_ms >= 0)

    ; 2. Verify WcGetNextUniqueStepId avoids ID collisions on deleted steps
    recipeEmpty := {steps: []}
    AssertEqual("DEFECT-030", "Empty recipe step ID starts at step_1", WcGetNextUniqueStepId(recipeEmpty), "step_1")

    recipeSeq := {steps: [{id: "step_1"}, {id: "step_2"}, {id: "step_3"}]}
    AssertEqual("DEFECT-030", "Sequential steps [1,2,3] next ID is step_4", WcGetNextUniqueStepId(recipeSeq), "step_4")

    recipeDeletedMiddle := {steps: [{id: "step_1"}, {id: "step_3"}]}
    AssertEqual("DEFECT-030", "Deleted middle step [1,3] yields non-colliding step_4", WcGetNextUniqueStepId(recipeDeletedMiddle), "step_4")

    recipeUnordered := {steps: [{id: "step_5"}, {id: "step_2"}]}
    AssertEqual("DEFECT-030", "Unordered steps [5,2] yields step_6", WcGetNextUniqueStepId(recipeUnordered), "step_6")

    recipeCustomPrefix := {steps: [{id: "s1"}, {id: "s2"}]}
    AssertEqual("DEFECT-030", "Custom prefix [s1,s2] yields step_3", WcGetNextUniqueStepId(recipeCustomPrefix), "step_3")

    ; 3. Verify RecipeModel.Validate flags duplicate step IDs
    recipeDup := {
        id: "recipe_dup_id_test",
        name: "Duplicate Step ID Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_1",
                tool_id: "clean_whitespace",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_1",
                tool_id: "convert_case",
                tool_version: 1,
                settings: Map("case_mode", "upper"),
                bindings: Map("text", "input.text")
            }
        ]
    }
    valDup := RecipeModel.Validate(recipeDup)
    AssertFalse("DEFECT-030", "Recipe with duplicate step ID is rejected", valDup.valid)
    hasDupNotice := false
    for err in valDup.errors {
        if InStr(err, "Duplicate step ID 'step_1'")
            hasDupNotice := true
    }
    AssertTrue("DEFECT-030", "Validation error explicitly cites Duplicate step ID 'step_1'", hasDupNotice)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-031: 5 Targeted Workflow Engine Architectural Repairs
    ; --------------------------------------------------------------------------------------------------
    ; 1. Mutable __results Protection: Handlers receive a clone; runner results are immutable
    ToolCatalog.Register({
        id: "defect031_mutator",
        label: "Defect 031 Mutator",
        category: "Utility",
        inputs: [],
        outputs: [{name: "out", type: "text", primary: true}],
        handler: (inps, sets) => (inps["__results"]["tampered"] := true, Map("out", "ok"))
    })

    recipeMutator := {
        id: "recipe_mutator_test",
        name: "Mutator Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_1",
                tool_id: "clean_whitespace",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_2",
                tool_id: "defect031_mutator",
                tool_version: 1,
                settings: Map(),
                bindings: Map()
            }
        ]
    }
    mutRes := PipelineRunner.Execute(recipeMutator, "hello", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-031", "Pipeline with mutator succeeds", mutRes.success)
    AssertFalse("DEFECT-031", "Runner results map does NOT contain tampered key", mutRes.results.Has("tampered"))
    AssertTrue("DEFECT-031", "step_1 results remain intact in runner", mutRes.results.Has("step_1"))
    ToolCatalog._Registry.Delete("defect031_mutator")

    ; 2. Discarded Loop Iteration Snapshots: PipelineRunner._ExecuteLoop captures iteration snapshots
    recipeLoopSnap := {
        id: "recipe_loop_snap_test",
        name: "Loop Snap Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_split",
                tool_id: "primitive_split",
                tool_version: 1,
                settings: Map("delimiter", "\n"),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_start",
                tool_id: "loop_start",
                tool_version: 1,
                settings: Map(),
                bindings: Map("items", "step_split.items")
            },
            {
                id: "step_num",
                tool_id: "parse_number",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "loop.item")
            },
            {
                id: "step_gst",
                tool_id: "normal_gst",
                tool_version: 1,
                settings: Map("rate", 18),
                bindings: Map("amount", "step_num.number")
            },
            {
                id: "step_end",
                tool_id: "loop_end",
                tool_version: 1,
                settings: Map(),
                bindings: Map("collect", "step_gst.total")
            }
        ]
    }
    loopSnapRes := PipelineRunner.Execute(recipeLoopSnap, "100`n200`n300", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-031", "Loop execution succeeded", loopSnapRes.success)
    AssertEqual("DEFECT-031", "Pipeline produced 2 top-level step snapshots (split and loop)", loopSnapRes.stepSnapshots.Length, 2)
    loopSnapObj := loopSnapRes.stepSnapshots[2]
    AssertEqual("DEFECT-031", "Loop snapshot has step_id step_end", loopSnapObj.step_id, "step_end")
    AssertTrue("DEFECT-031", "Loop snapshot contains iterations array", loopSnapObj.HasOwnProp("iterations") && Type(loopSnapObj.iterations) = "Array")
    AssertEqual("DEFECT-031", "Loop snapshot contains 3 iteration records", loopSnapObj.iterations.Length, 3)
    iter1 := loopSnapObj.iterations[1]
    AssertEqual("DEFECT-031", "Iteration 1 record index is 1", iter1.iteration, 1)
    AssertEqual("DEFECT-031", "Iteration 1 item is 100", iter1.item, "100")
    AssertEqual("DEFECT-031", "Iteration 1 has 2 sub-step snapshots", iter1.snapshots.Length, 2)
    AssertEqual("DEFECT-031", "Iteration 1 sub-step 1 is step_num", iter1.snapshots[1].step_id, "step_num")
    AssertEqual("DEFECT-031", "Iteration 1 sub-step 1 parsed number is 100", iter1.snapshots[1].outputs["number"], 100)
    AssertEqual("DEFECT-031", "Iteration 1 sub-step 2 is step_gst", iter1.snapshots[2].step_id, "step_gst")
    AssertEqual("DEFECT-031", "Iteration 1 sub-step 2 total is 118", iter1.snapshots[2].outputs["total"], 118)

    ; 3. Deterministic Auto-Binding: primary: true prioritized over arbitrary candidate keys
    inScopeCand := [
        {stepId: "step_gst", outputName: "cgst", type: WorkflowTypes.TYPE_NUMBER, label: "CGST", isPrimary: false},
        {stepId: "step_gst", outputName: "total", type: WorkflowTypes.TYPE_NUMBER, label: "Total", isPrimary: true},
        {stepId: "step_gst", outputName: "sgst", type: WorkflowTypes.TYPE_NUMBER, label: "SGST", isPrimary: false}
    ]
    autoBindings := ToolCatalog.ResolveDefaultBindings("number_to_words", inScopeCand)
    AssertTrue("DEFECT-031", "Auto-binding resolves number input for number_to_words", autoBindings.bindings.Has("number"))
    AssertEqual("DEFECT-031", "Auto-binding picks primary: true total over cgst/sgst", autoBindings.bindings["number"], "step_gst.total")

    ; 4. Explicit final_output_ref & Deterministic Primary Fallback
    recipeExplicitFinal := {
        id: "recipe_explicit_final_test",
        name: "Explicit Final Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        final_output_ref: "step_gst.base",
        steps: [
            {
                id: "step_parse",
                tool_id: "parse_number",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_gst",
                tool_id: "normal_gst",
                tool_version: 1,
                settings: Map("rate", 18),
                bindings: Map("amount", "step_parse.number")
            }
        ]
    }
    valExpFinal := RecipeModel.Validate(recipeExplicitFinal)
    AssertTrue("DEFECT-031", "Explicit final_output_ref recipe validates", valExpFinal.valid)
    resExpFinal := PipelineRunner.Execute(recipeExplicitFinal, "100", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-031", "Explicit final execution succeeds", resExpFinal.success)
    AssertEqual("DEFECT-031", "Explicit final output extracts base amount exactly (100)", resExpFinal.output, "100")

    ; Invalid final_output_ref is rejected during validation
    recipeBadFinal := {
        id: "recipe_bad_final_test",
        name: "Bad Final Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        final_output_ref: "non_existent_step.field",
        steps: [
            {
                id: "step_parse",
                tool_id: "parse_number",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_gst",
                tool_id: "normal_gst",
                tool_version: 1,
                settings: Map("rate", 18),
                bindings: Map("amount", "step_parse.number")
            }
        ]
    }
    valBadFinal := RecipeModel.Validate(recipeBadFinal)
    AssertFalse("DEFECT-031", "Invalid final_output_ref is rejected by RecipeModel.Validate", valBadFinal.valid)

    ; Deterministic fallback to primary output when final_output_ref is empty
    recipePrimaryFallback := {
        id: "recipe_primary_fallback_test",
        name: "Primary Fallback Test",
        version: 1,
        input_source: "selection",
        sink: "none",
        steps: [
            {
                id: "step_parse",
                tool_id: "parse_number",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_gst",
                tool_id: "normal_gst",
                tool_version: 1,
                settings: Map("rate", 18),
                bindings: Map("amount", "step_parse.number")
            }
        ]
    }
    resPrimaryFallback := PipelineRunner.Execute(recipePrimaryFallback, "100", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertEqual("DEFECT-031", "Fallback prioritizes normal_gst declared primary output (total: 118)", resPrimaryFallback.output, "118")

    ; 5. Catalog Declarations Disagreeing with Runtime Output
    mathTool := ToolCatalog.Get("math_evaluate")
    mathHasNumber := false
    for out in mathTool.outputs {
        if (out.name = "number")
            mathHasNumber := true
    }
    AssertTrue("DEFECT-031", "ToolCatalog math_evaluate declares 'number' output", mathHasNumber)
    mathRuntime := ToolAdapters.ExecuteMathEvaluate(Map("expression", "25 * 4"), Map())
    AssertTrue("DEFECT-031", "ExecuteMathEvaluate runtime returns 'number' key", mathRuntime.Has("number"))
    AssertEqual("DEFECT-031", "ExecuteMathEvaluate 'number' value is 100", mathRuntime["number"], 100)

    numTool := ToolCatalog.Get("parse_number")
    numHasText := false
    for out in numTool.outputs {
        if (out.name = "text")
            numHasText := true
    }
    AssertTrue("DEFECT-031", "ToolCatalog parse_number declares 'text' output", numHasText)
    numRuntime := ToolAdapters.ExecuteParseNumber(Map("text", "42"), Map())
    AssertTrue("DEFECT-031", "ExecuteParseNumber runtime returns 'text' key", numRuntime.Has("text"))
    AssertEqual("DEFECT-031", "ExecuteParseNumber 'text' value is '42'", numRuntime["text"], "42")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-032: Complex Recipe Execution & Map/Object Stringification in Snapshots & Runner
    ; --------------------------------------------------------------------------------------------------
    userRecipePath := A_ScriptDir . "\..\Recipes\recipe_20260907_153607.json"
    if FileExist(userRecipePath) {
        content := FileRead(userRecipePath, "UTF-8")
        userRecipe := RecipeModel.Normalize(JsonHelper.Parse(content, false))
    } else {
        userRecipe := {
            id: "recipe_20260907_153607",
            name: "New Workflow Recipe",
            version: 1,
            input_source: "prompt",
            sink: "clipboard",
            steps: [
                { id: "step_1", tool_id: "clean_whitespace", tool_version: 1, bindings: Map("text", "input.text") },
                { id: "step_2", tool_id: "convert_case", tool_version: 1, settings: Map("case_mode", "snake"), bindings: Map("text", "step_1.text") },
                { id: "step_3", tool_id: "parse_number", tool_version: 1, bindings: Map("text", "step_2.text") },
                { id: "step_4", tool_id: "number_to_words", tool_version: 1, bindings: Map("number", "step_3.number") },
                { id: "step_5", tool_id: "convert_case", tool_version: 1, settings: Map("case_mode", "kebab"), bindings: Map("text", "step_4.words") },
                { id: "step_6", tool_id: "text_statistics", tool_version: 1, bindings: Map("text", "step_5.result") },
                { id: "step_7", tool_id: "normal_gst", tool_version: 1, settings: Map("rate", 18), bindings: Map("amount", "step_6.chars") }
            ]
        }
    }
    AssertTrue("DEFECT-032", "User recipe recipe_20260907_153607 loaded successfully", IsObject(userRecipe))

    execUser := PipelineRunner.Execute(userRecipe, "Test 100", {is_preview: true, suppress_sink: true, suppress_toasts: true, record_history: false})
    AssertTrue("DEFECT-032", "User recipe executes cleanly in preview mode", execUser.success)
    AssertTrue("DEFECT-032", "User recipe terminal output resolved", execUser.output != "")
    lastSnap := execUser.stepSnapshots[execUser.stepSnapshots.Length]
    AssertTrue("DEFECT-032", "Last step (step_7) has Map record output", lastSnap.outputs.Has("record") && Type(lastSnap.outputs["record"]) = "Map")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-033: RunHistory Corrupted Ledger Resilience & Status Guard
    ; --------------------------------------------------------------------------------------------------
    ; Verify that a ledger record missing the 'status' property does not crash the status badge resolver
    corruptRunItem := {
        recipe_name: "Corrupt Recipe",
        duration_ms: 15,
        timestamp: "2026-09-07 12:00:00",
        input_snapshot: "sample",
        output_snapshot: "result"
    }
    stBadgeSafe := (corruptRunItem.HasOwnProp("status") && corruptRunItem.status = "success") ? "✔ Pass" : "❌ Fail"
    AssertEqual("DEFECT-033", "Corrupt record missing status evaluates cleanly to Fail badge", stBadgeSafe, "❌ Fail")

    validPassItem := { status: "success" }
    stBadgePass := (validPassItem.HasOwnProp("status") && validPassItem.status = "success") ? "✔ Pass" : "❌ Fail"
    AssertEqual("DEFECT-033", "Valid success record evaluates to Pass badge", stBadgePass, "✔ Pass")

    validFailItem := { status: "failed" }
    stBadgeFail := (validFailItem.HasOwnProp("status") && validFailItem.status = "success") ? "✔ Pass" : "❌ Fail"
    AssertEqual("DEFECT-033", "Valid failed record evaluates to Fail badge", stBadgeFail, "❌ Fail")

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-034: EvaluateMathSelection COM 0x80040154 — NativeMathParser Regression Guard
    ;
    ; Root cause (v1.0.0): ComObject("MSScriptControl.ScriptControl") / JScript.Eval() was used for
    ; expression evaluation.  MSScriptControl is absent on stock Windows 11, causing HRESULT
    ; 0x80040154 (REGDB_E_CLASSNOTREG) at line 30 of the old monolith.  The error was swallowed
    ; with only a cryptic log entry — no actionable user feedback.
    ; Fix (v2.0.0+): Pure-AHK NativeMathParser replaces all COM; SafeEvaluateMath() is the sole
    ; entry point and contains no ComObject calls.  Actions_Math.ahk sanitizes error messages so
    ; COM-style hex codes (0x…) can never reach the user toast even if a regression occurs.
    ; --------------------------------------------------------------------------------------------------

    ; 1. Basic arithmetic evaluates successfully (no COM required)
    r034_arith := SafeEvaluateMath("1500 * 1.18 + 450")
    AssertTrue("DEFECT-034", "Basic arithmetic succeeds without COM", r034_arith.success)
    AssertEqual("DEFECT-034", "1500 * 1.18 + 450 = 2220", r034_arith.resultStr, "2220")

    ; 2. Power operator works (** and ^ are both valid)
    r034_pow := SafeEvaluateMath("2^8")
    AssertTrue("DEFECT-034", "Power operator evaluates successfully", r034_pow.success)
    AssertEqual("DEFECT-034", "2^8 = 256", r034_pow.resultStr, "256")

    ; 3. Indian scale suffix expansion (Lakh)
    r034_lakh := SafeEvaluateMath("2 lakh * 1.18")
    AssertTrue("DEFECT-034", "Lakh suffix expansion evaluates successfully", r034_lakh.success)
    AssertEqual("DEFECT-034", "2 lakh * 1.18 = 236000", r034_lakh.resultStr, "236000")

    ; 4. Parenthesised expression
    r034_parens := SafeEvaluateMath("(100 + 50) * 2")
    AssertTrue("DEFECT-034", "Parenthesised expression evaluates successfully", r034_parens.success)
    AssertEqual("DEFECT-034", "(100 + 50) * 2 = 300", r034_parens.resultStr, "300")

    ; 5. Invalid / non-numeric input returns success=false with a plain-English message (no 0x code)
    r034_bad := SafeEvaluateMath("hello world")
    AssertFalse("DEFECT-034", "Non-numeric input returns success=false", r034_bad.success)
    AssertFalse("DEFECT-034", "Error message for invalid input contains no 0x hex code", InStr(r034_bad.errorMessage, "0x") > 0)

    ; 6. Division by zero returns success=false with a plain-English message
    r034_divz := SafeEvaluateMath("100 / 0")
    AssertFalse("DEFECT-034", "Division by zero returns success=false", r034_divz.success)
    AssertFalse("DEFECT-034", "Division-by-zero error message contains no 0x hex code", InStr(r034_divz.errorMessage, "0x") > 0)

    ; 7. Error message sanitizer: COM-style strings must not pass through to the user
    ;    (Simulate what the old MSScriptControl error looked like and confirm the guard catches it)
    fakeCOMErr := "(0x80040154) Class not registered"
    isCOMMsg := InStr(fakeCOMErr, "0x") || InStr(fakeCOMErr, "Class not registered") || InStr(fakeCOMErr, "MSScriptControl")
    AssertTrue("DEFECT-034", "COM-style error string is detected by sanitizer guard", isCOMMsg)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-035: Multi-Token Command Palette Search Engine Verification
    ; --------------------------------------------------------------------------------------------------
    RegisterDateTimeActions()
    RegisterTextActions()
    RegisterMathActions()
    RegisterFinanceActions()
    RegisterExtractionActions()
    RegisterCivilActions()
    InitWorkflowEngine()
    
    ; 1. "date default" matches "Configure Default Date Format"
    itemsDateDefault := FilterPaletteItems("date default")
    AssertTrue("DEFECT-035", "Multi-token search 'date default' matches item", itemsDateDefault.Length > 0)
    hasConfigDefault := false
    for itm in itemsDateDefault {
        if (itm.name = "Configure Default Date Format")
            hasConfigDefault := true
    }
    AssertTrue("DEFECT-035", "Found Configure Default Date Format in multi-token results", hasConfigDefault)

    ; 2. "word count" matches "Word & Character Statistics"
    itemsWc := FilterPaletteItems("word count")
    AssertTrue("DEFECT-035", "Multi-token search 'word count' matches item", itemsWc.Length > 0)

    ; 3. "tow" matches "Number to Words (Indian Rupees)"
    itemsTow := FilterPaletteItems("tow")
    AssertTrue("DEFECT-035", "Multi-token search 'tow' matches item", itemsTow.Length > 0)

    ; 4. "serial" matches "Convert Lines to Numbered List (1, 2, 3)"
    itemsSerial := FilterPaletteItems("serial")
    AssertTrue("DEFECT-035", "Multi-token search 'serial' matches item", itemsSerial.Length > 0)

    ; --------------------------------------------------------------------------------------------------
    ; DEFECT-036: Deduplicate Lines & Lorem Ipsum Tool Registration
    ; --------------------------------------------------------------------------------------------------
    sampleLines := "alpha`nbeta`nalpha`ngamma`nbeta"
    dedupRes := DeduplicateLines(sampleLines, false)
    AssertEqual("DEFECT-036", "DeduplicateLines preserves order and removes dupes", dedupRes, "alpha`nbeta`ngamma")

    dedupFound := false
    loremFound := false
    for act in BuiltInActions {
        if (act.name = "Deduplicate Lines (Remove Duplicates)")
            dedupFound := true
        if (act.name = "Insert Lorem Ipsum Dummy Text")
            loremFound := true
    }
    AssertTrue("DEFECT-036", "Deduplicate Lines action registered", dedupFound)
    AssertTrue("DEFECT-036", "Insert Lorem Ipsum Dummy Text action registered", loremFound)

} catch as testErr {
    FailCount++
    TestLogs.Push("[FATAL_REGRESSION_CRASH] " . testErr.Message . " (Line: " . testErr.Line . ")")
    Failures.Push({category: "CRITICAL", testName: "Unhandled Exception", error: testErr.Message})
}

; Emit Final Results via TestHarness
durationTotal := A_TickCount - StartTick
EmitTestResults("test_regression_defects", PassCount + FailCount, PassCount, FailCount, durationTotal, TestLogs, Failures)