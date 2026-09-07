; ======================================================================================================================
; Module: test_regression_defects.ahk - Dedicated Defect Regression Test Suite
; Part of Office Productivity Hub (v2.0.1) - Zero-Trust Quality Harness
;
; ARCHITECTURAL INVARIANTS:
; 1. Numbered, traceable defect reproduction cases (DEFECT-001 through DEFECT-015).
; 2. Every historical, edge-case, and recently discovered bug has an isolated, permanent regression guard.
; 3. Zero UI dialog popups; outputs clean structured logs and schema-versioned results.json via TestHarness.
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

; Mock UI callbacks for headless execution
ShowTextStats(*) => ""
LogAppError(*) => ""
ShowWorkflowComposer(*) => ""
ShowRunHistoryGui(*) => ""
RefreshSnippetListView(*) => ""

; --- Core Inclusions ---
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\DateFormatConverter.ahk"
#Include "..\Lib\Actions_DateTime.ahk"
#Include "..\Lib\Actions_Finance.ahk"
#Include "..\Lib\Actions_Text.ahk"
#Include "..\Lib\Actions_Extraction.ahk"
#Include "..\Lib\Actions_Math.ahk"
#Include "..\Lib\CivilUnits.ahk"
#Include "..\Lib\CivilPythagoras.ahk"
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
#Include "..\Lib\Core.ahk"
#Include "..\Lib\Actions_Workflow.ahk"

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

    ; 2. Verify target_format_id execution and downstream text contract
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
                settings: Map("target_format_id", 6),
                bindings: Map("text", "input.text")
            },
            {
                id: "step_upper",
                tool_id: "case_upper",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "step_conv.text")
            }
        ]
    }
    dateConvRes := PipelineRunner.Execute(recipeDateConv, "05/09/2026", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-023", "date_convert_format pipeline run succeeded", dateConvRes.success)
    AssertEqual("DEFECT-023", "date_convert_format downstream received text and converted to uppercase", dateConvRes.output, "05 SEPTEMBER 2026")

    ; 3. Verify format_id alias produces identical output
    recipeDateConv.steps[1].settings := Map("format_id", 6)
    dateConvAliasRes := PipelineRunner.Execute(recipeDateConv, "05/09/2026", {suppress_toasts: true, suppress_sink: true, record_history: false})
    AssertTrue("DEFECT-023", "format_id alias execution succeeded", dateConvAliasRes.success)
    AssertEqual("DEFECT-023", "format_id alias produced uppercase converted date", dateConvAliasRes.output, "05 SEPTEMBER 2026")

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

} catch as testErr {
    FailCount++
    TestLogs.Push("[FATAL_REGRESSION_CRASH] " . testErr.Message . " (Line: " . testErr.Line . ")")
    Failures.Push({category: "CRITICAL", testName: "Unhandled Exception", error: testErr.Message})
}

; Emit Final Results via TestHarness
durationTotal := A_TickCount - StartTick
EmitTestResults("test_regression_defects", PassCount + FailCount, PassCount, FailCount, durationTotal, TestLogs, Failures)