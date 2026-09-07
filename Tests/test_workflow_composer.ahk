; ======================================================================================================================
; Zero-Trust Automated Test Suite for Workflow Composer & Pipeline Runner
; Part of Office Productivity Hub (v2.0.1)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

; Mock UI callbacks for headless test mode
ShowTextStats(*) => ""
LogAppError(*) => ""

; --- Core Test Harness & Production Libraries ---
#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\Actions_Math.ahk"
#Include "..\Lib\Actions_DateTime.ahk"
#Include "..\Lib\Actions_Text.ahk"
#Include "..\Lib\Actions_Finance.ahk"
#Include "..\Lib\Actions_Extraction.ahk"
#Include "..\Lib\DateFormatConverter.ahk"
#Include "..\Lib\Core.ahk"

; --- Workflow Suite Inclusions ---
#Include "..\Lib\JsonHelper.ahk"
#Include "..\Lib\WorkflowTypes.ahk"
#Include "..\Lib\ToolCatalog.ahk"
#Include "..\Lib\WorkflowPrimitives.ahk"
#Include "..\Lib\ToolAdapters_Builtin.ahk"
#Include "..\Lib\RecipeModel.ahk"
#Include "..\Lib\PipelineRunner.ahk"
#Include "..\Lib\RunHistory.ahk"
#Include "..\Lib\RunHistoryGui.ahk"
#Include "..\Lib\WorkflowComposerGui.ahk"
#Include "..\Lib\Actions_Workflow.ahk"

global PassCount := 0
global FailCount := 0
global TestLogs  := []
global Failures  := []
global StartTick := A_TickCount

AssertEqual(testCategory, testName, actual, expected) {
    global PassCount, FailCount, TestLogs, Failures
    actualStr := String(actual)
    expectedStr := String(expected)
    
    if (actualStr == expectedStr) {
        PassCount++
        TestLogs.Push(Format("[PASS] {1:-20} | {2:-40} -> '{3}'", testCategory, testName, actualStr))
    } else {
        FailCount++
        TestLogs.Push(Format("[FAIL] {1:-20} | {2:-40} -> Expected: '{3}', Got: '{4}'", testCategory, testName, expectedStr, actualStr))
        Failures.Push({category: testCategory, testName: testName, error: "Expected: '" . expectedStr . "', Got: '" . actualStr . "'"})
    }
}

AssertTrue(testCategory, testName, condition) {
    AssertEqual(testCategory, testName, condition ? "TRUE" : "FALSE", "TRUE")
}

AssertFalse(testCategory, testName, condition) {
    AssertEqual(testCategory, testName, condition ? "TRUE" : "FALSE", "FALSE")
}

try {
    ; ==================================================================================================================
    ; 1. JsonHelper Tests
    ; ==================================================================================================================
    testMap := Map("key1", "value1", "count", 42, "enabled", true)
    jsonOutput := JsonHelper.Stringify(testMap)
    parsedMap := JsonHelper.Parse(jsonOutput, true)
    AssertTrue("JsonHelper", "Map roundtrip is Map", Type(parsedMap) = "Map")
    AssertEqual("JsonHelper", "Map key1 preserved", parsedMap["key1"], "value1")
    AssertEqual("JsonHelper", "Map count preserved", parsedMap["count"], 42)
    AssertEqual("JsonHelper", "Map boolean preserved", parsedMap["enabled"], true)

    testObj := {key1: "value1", count: 42, enabled: true}
    jsonObjStr := JsonHelper.Stringify(testObj)
    parsedObj := JsonHelper.Parse(jsonObjStr)
    AssertTrue("JsonHelper", "Object roundtrip is Object", Type(parsedObj) = "Object")
    AssertEqual("JsonHelper", "Object key1 preserved", parsedObj.key1, "value1")
    AssertEqual("JsonHelper", "Object count preserved", parsedObj.count, 42)
    AssertEqual("JsonHelper", "Object boolean preserved", parsedObj.enabled, true)

    testArr := ["first", "second", 100]
    jsonArrStr := JsonHelper.Stringify(testArr)
    parsedArr := JsonHelper.Parse(jsonArrStr)
    AssertTrue("JsonHelper", "Array roundtrip is Array", Type(parsedArr) = "Array")
    AssertEqual("JsonHelper", "Array length preserved", parsedArr.Length, 3)
    AssertEqual("JsonHelper", "Array item 1 preserved", parsedArr[1], "first")

    ; Escapes test
    escapedJson := JsonHelper.Stringify("Line 1`nLine 2`t`"Quote`"")
    parsedEscaped := JsonHelper.Parse(escapedJson)
    AssertEqual("JsonHelper", "Escaped string roundtrip", parsedEscaped, "Line 1`nLine 2`t`"Quote`"")

    ; ==================================================================================================================
    ; 2. WorkflowTypes Validation & Security Boundaries
    ; ==================================================================================================================
    AssertTrue("WorkflowTypes", "Validate Text", WorkflowTypes.ValidateValue("hello world", "text").valid)
    AssertFalse("WorkflowTypes", "Reject non-text as Text", WorkflowTypes.ValidateValue(12345, "text").valid)
    AssertTrue("WorkflowTypes", "Validate Number", WorkflowTypes.ValidateValue(12345, "number").valid)
    AssertTrue("WorkflowTypes", "Validate Items<Text>", WorkflowTypes.ValidateValue(["a", "b", "c"], "items<text>").valid)
    AssertFalse("WorkflowTypes", "Reject non-array as Items", WorkflowTypes.ValidateValue("not an array", "items<text>").valid)
    AssertFalse("WorkflowTypes", "Reject wrong item type", WorkflowTypes.ValidateValue(["a", 123], "items<text>").valid)

    ; Compatibility Matrix
    AssertTrue("WorkflowTypes", "Exact type compatibility", WorkflowTypes.AreCompatible("number", "number"))
    AssertTrue("WorkflowTypes", "Any targets accept anything", WorkflowTypes.AreCompatible("text", "any"))
    AssertTrue("WorkflowTypes", "Items<text> compatible with Items<any>", WorkflowTypes.AreCompatible("items<text>", "items<any>"))
    AssertFalse("WorkflowTypes", "Number incompatible with Text", WorkflowTypes.AreCompatible("number", "text"))
    AssertFalse("WorkflowTypes", "Items incompatible with scalar", WorkflowTypes.AreCompatible("items<text>", "text"))

    ; FileReference Security Invariant (Zero file reading)
    fileRef := WorkflowTypes.CreateFileReference("C:\test\sample_document.pdf", 5)
    AssertTrue("WorkflowTypes", "FileReference conforms", WorkflowTypes.ValidateValue(fileRef, "filereference").valid)
    AssertEqual("WorkflowTypes", "FileReference name", fileRef.name, "sample_document.pdf")
    AssertEqual("WorkflowTypes", "FileReference stem", fileRef.stem, "sample_document")
    AssertEqual("WorkflowTypes", "FileReference extension", fileRef.extension, "pdf")
    AssertEqual("WorkflowTypes", "FileReference index", fileRef.index, 5)

    ; ==================================================================================================================
    ; 3. ToolCatalog & Registration Engine
    ; ==================================================================================================================
    InitWorkflowEngine()

    AssertTrue("ToolCatalog", "ToolCatalog has primitive_split", ToolCatalog.Has("primitive_split"))
    AssertTrue("ToolCatalog", "ToolCatalog has primitive_join", ToolCatalog.Has("primitive_join"))
    AssertTrue("ToolCatalog", "ToolCatalog has normal_gst", ToolCatalog.Has("normal_gst"))
    AssertTrue("ToolCatalog", "ToolCatalog has date_convert_format", ToolCatalog.Has("date_convert_format"))
    AssertTrue("ToolCatalog", "ToolCatalog has number_to_words", ToolCatalog.Has("number_to_words"))
    AssertTrue("ToolCatalog", "ToolCatalog has extract_emails", ToolCatalog.Has("extract_emails"))

    toolGst := ToolCatalog.Get("normal_gst")
    AssertEqual("ToolCatalog", "normal_gst category", toolGst.category, "Finance & Math")
    AssertEqual("ToolCatalog", "normal_gst version", toolGst.version, 1)

    ; Auto-Wiring Resolution
    availableOutputs := [
        {sourceRef: "input.text", type: "text", label: "Raw Input"},
        {sourceRef: "step_1.number", type: "number", label: "Step 1 Number"}
    ]
    autoWire := ToolCatalog.ResolveDefaultBindings("normal_gst", availableOutputs)
    AssertFalse("ToolCatalog", "normal_gst needsInput false", autoWire.needsInput)
    AssertEqual("ToolCatalog", "Auto-wired to latest number", autoWire.bindings["amount"], "step_1.number")

    ; ==================================================================================================================
    ; 4. Workflow Primitives
    ; ==================================================================================================================
    ; Split
    splitRes := WorkflowPrimitives.ExecuteSplit(Map("text", "Row1`nRow2`nRow3"), Map("delimiter", "\n"))
    AssertEqual("Primitives", "Split count", splitRes["count"], 3)
    AssertEqual("Primitives", "Split item 2", splitRes["items"][2], "Row2")

    ; Join
    joinRes := WorkflowPrimitives.ExecuteJoin(Map("items", ["Alpha", "Beta", "Gamma"]), Map("delimiter", ", "))
    AssertEqual("Primitives", "Join result", joinRes["text"], "Alpha, Beta, Gamma")

    ; Dedupe
    dedupeRes := WorkflowPrimitives.ExecuteDedupe(Map("items", ["cat", "dog", "CAT", "bird", "dog"]), Map("match_case", false))
    AssertEqual("Primitives", "Dedupe count", dedupeRes["count"], 3)
    AssertEqual("Primitives", "Dedupe duplicates removed", dedupeRes["removed_count"], 2)
    AssertEqual("Primitives", "Dedupe item 1", dedupeRes["items"][1], "cat")

    ; Slice
    sliceRes := WorkflowPrimitives.ExecuteSlice(Map("items", [10, 20, 30, 40, 50]), Map("mode", "top_n", "count", 2))
    AssertEqual("Primitives", "Slice top 2 count", sliceRes["count"], 2)
    AssertEqual("Primitives", "Slice item 2", sliceRes["items"][2], 20)

    ; Template Combine
    tmplRes := WorkflowPrimitives.ExecuteTemplate(Map("context", "12500"), Map("template", "Invoice: ₹{item}"))
    AssertEqual("Primitives", "Template combine simple", tmplRes["text"], "Invoice: ₹12500")

    ; ==================================================================================================================
    ; 5. Tool Adapters
    ; ==================================================================================================================
    ; Normal Forward GST: Base 50,000 @ 18% -> CGST 4,500, SGST 4,500, Total 59,000
    gstRes := ToolAdapters.ExecuteNormalGst(Map("amount", 50000), Map("rate", 18))
    AssertEqual("ToolAdapters", "Normal GST Base", gstRes["base"], 50000)
    AssertEqual("ToolAdapters", "Normal GST Tax", gstRes["gst"], 9000)
    AssertEqual("ToolAdapters", "Normal GST CGST", gstRes["cgst"], 4500)
    AssertEqual("ToolAdapters", "Normal GST SGST", gstRes["sgst"], 4500)
    AssertEqual("ToolAdapters", "Normal GST Total", gstRes["total"], 59000)

    ; Number to Words
    wordsRes := ToolAdapters.ExecuteNumberToWords(Map("number", 59000), Map())
    AssertEqual("ToolAdapters", "Number to Words 59000", wordsRes["words"], "Rupees Fifty-Nine Thousand Only")

    ; Email extraction
    emailText := "Contact admin@example.com or support@office.org for queries."
    emailsRes := ToolAdapters.ExecuteExtractEmails(Map("text", emailText), Map())
    AssertEqual("ToolAdapters", "Extract Emails count", emailsRes["count"], 2)
    AssertEqual("ToolAdapters", "Extract Email 1", emailsRes["items"][1], "admin@example.com")

    ; Convert Date Format Adapter
    dateConv1 := ToolAdapters.ExecuteConvertDateFormat(Map("text", "5sept2026"), Map("format_id", 1))
    AssertEqual("ToolAdapters", "ExecuteConvertDateFormat 5sept2026 to F1", dateConv1["result"], "05/09/2026")
    AssertEqual("ToolAdapters", "ExecuteConvertDateFormat F1 name", dateConv1["format_name"], "DD/MM/YYYY")

    dateConvBatch := ToolAdapters.ExecuteConvertDateFormat(Map("text", "Meeting on 05.09.2026"), Map("format_id", 6))
    AssertEqual("ToolAdapters", "ExecuteConvertDateFormat batch to F6", dateConvBatch["result"], "Meeting on 05 September 2026")

    ; ==================================================================================================================
    ; 6. RecipeModel Validation & Seed Storage
    ; ==================================================================================================================
    RecipeModel.EnsureDefaultSeedRecipes()
    allRecipes := RecipeModel.ListAll()
    AssertTrue("RecipeModel", "Seed recipes loaded", allRecipes.Length >= 3)

    ; Test invalid recipe rejection
    invalidRecipe := {
        id: "recipe_broken",
        name: "Broken Recipe",
        input_source: "selection",
        steps: [
            {
                id: "step_1",
                tool_id: "normal_gst",
                bindings: Map("amount", "step_nonexistent.output")
            }
        ]
    }
    valInvalid := RecipeModel.Validate(invalidRecipe)
    AssertFalse("RecipeModel", "Reject recipe with non-existent source", valInvalid.valid)
    AssertTrue("RecipeModel", "Validation returns error message", valInvalid.errors.Length > 0)

    ; ==================================================================================================================
    ; 7. Canonical Recipe 1 Execution: Numbers to Words (Row by Row)
    ; ==================================================================================================================
    rNumWords := RecipeModel.Load("recipe_numbers_to_words")
    inputNumbers := "12500`n45000`n999"
    runNumRes := PipelineRunner.Execute(rNumWords, inputNumbers)
    AssertTrue("PipelineRunner", "Numbers to Words recipe success", runNumRes.success)

    expectedNumWordsOutput := "12500 : Rupees Twelve Thousand Five Hundred Only`n45000 : Rupees Forty-Five Thousand Only`n999 : Rupees Nine Hundred Ninety-Nine Only"
    AssertEqual("PipelineRunner", "Numbers to Words row-by-row output", runNumRes.output, expectedNumWordsOutput)

    ; ==================================================================================================================
    ; 8. Canonical Recipe 2 Execution: Normal Forward GST & Words
    ; ==================================================================================================================
    rForwardGst := RecipeModel.Load("recipe_forward_gst_words")
    inputGst := "50000"
    runGstRes := PipelineRunner.Execute(rForwardGst, inputGst)
    AssertTrue("PipelineRunner", "Forward GST recipe success", runGstRes.success)
    AssertTrue("PipelineRunner", "GST output contains Base 50,000", InStr(runGstRes.output, "Base: ₹50,000") > 0)
    AssertTrue("PipelineRunner", "GST output contains Total 59,000", InStr(runGstRes.output, "Total: ₹59,000") > 0)
    AssertTrue("PipelineRunner", "GST output contains words", InStr(runGstRes.output, "Rupees Fifty-Nine Thousand Only") > 0)

    ; ==================================================================================================================
    ; 9. Canonical Recipe 3 Execution: Extract & Clean Email List
    ; ==================================================================================================================
    rEmails := RecipeModel.Load("recipe_extract_clean_emails")
    inputMessyEmails := "Reach out to admin@example.com, support@company.com, or ADMIN@EXAMPLE.COM."
    runEmailRes := PipelineRunner.Execute(rEmails, inputMessyEmails)
    AssertTrue("PipelineRunner", "Clean Email List recipe success", runEmailRes.success)

    expectedEmailsOutput := "admin@example.com`nsupport@company.com"
    AssertEqual("PipelineRunner", "Clean Email List deduplicated output", runEmailRes.output, expectedEmailsOutput)

    ; ==================================================================================================================
    ; 10. Failure Policy & Run History Snapshot Integrity
    ; ==================================================================================================================
    historyBefore := RunHistory.LoadAll().Length
    AssertTrue("RunHistory", "RunHistory recorded executions", historyBefore >= 3)

    lastRun := RunHistory.LoadAll()[1]
    AssertTrue("RunHistory", "Last run has run_id", lastRun.HasOwnProp("run_id") && StrLen(lastRun.run_id) > 0)
    AssertEqual("RunHistory", "Last run status is success", lastRun.status, "success")
    AssertTrue("RunHistory", "Last run has snapshots", lastRun.HasOwnProp("step_snapshots") && lastRun.step_snapshots.Length > 0)

    ; Stop-on-First-Failure verification
    failingRecipe := {
        id: "recipe_failing_test",
        name: "Failing Test Recipe",
        version: 1,
        input_source: "none",
        steps: [
            {
                id: "step_1",
                tool_id: "parse_number",
                tool_version: 1,
                settings: Map(),
                bindings: Map("text", "input.text") ; text is empty, should fail
            },
            {
                id: "step_2",
                tool_id: "number_to_words",
                tool_version: 1,
                settings: Map(),
                bindings: Map("number", "step_1.number")
            }
        ]
    }
    failRunRes := PipelineRunner.Execute(failingRecipe, "not a valid number")
    AssertFalse("PipelineRunner", "Invalid input fails execution", failRunRes.success)

    failHistoryRecord := RunHistory.LoadAll()[1]
    AssertEqual("RunHistory", "Failure recorded in history", failHistoryRecord.status, "failed")
    AssertEqual("RunHistory", "Failed step identified", failHistoryRecord.failed_step, "step_1")

} catch as testErr {
    FailCount++
    TestLogs.Push("[FATAL_TEST_CRASH] " . testErr.Message . " (Line: " . testErr.Line . ")")
    Failures.Push({category: "CRITICAL", testName: "Unhandled Test Exception", error: testErr.Message})
}

; Emit Final Results via TestHarness
durationTotal := A_TickCount - StartTick
EmitTestResults("test_workflow_composer", PassCount + FailCount, PassCount, FailCount, durationTotal, TestLogs, Failures)
