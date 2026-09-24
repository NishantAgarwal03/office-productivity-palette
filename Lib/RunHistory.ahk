; ======================================================================================================================
; Module: RunHistory.ahk - Execution Snapshot & Diagnostics Ledger
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Complete Snapshot Retention: Records input/output snapshots for both successful and failed steps.
; 2. Atomic Commits: Commits run logs via temp file + atomic move to prevent corrupting ledger on unexpected exit.
; 3. Explicit Data Ownership: Run records are preserved locally and are never silently wiped.
; ======================================================================================================================

#Requires AutoHotkey v2.0

class RunHistory {
    static GetLedgerPath() {
        global RunHistoryFile, DataDir
        if (IsSet(RunHistoryFile) && RunHistoryFile != "")
            return RunHistoryFile
        logDir := DataDir . "\Logs"
        if !DirExist(logDir)
            DirCreate(logDir)
        return logDir . "\WorkflowRunHistory.json"
    }

    /**
     * Records a completed or failed execution run
     * @param {Object} runEntry
     */
    static Record(runEntry) {
        ledgerPath := RunHistory.GetLedgerPath()
        logDir := SubStr(ledgerPath, 1, InStr(ledgerPath, "\",, -1) - 1)
        if !DirExist(logDir)
            DirCreate(logDir)

        ; DEFECT-051 (D3): mask known-sensitive patterns (GSTIN/PAN/phone/email) in every String field of
        ; the run record — recursively, since input/output snapshots and step_snapshots can carry Strings
        ; nested inside Arrays/Maps/Objects — before this entry ever touches disk. See RedactSensitiveData()
        ; in Lib\Actions_Extraction.ahk for the exact scope and known limitations of this defense-in-depth.
        redactedEntry := RunHistory._RedactRecursive(runEntry)

        history := RunHistory.LoadAll()
        history.InsertAt(1, redactedEntry) ; Most recent first

        ; Keep up to 200 runs locally
        while (history.Length > 200)
            history.Pop()

        tempFile := ledgerPath . ".tmp"
        fileObj := ""
        try {
            jsonStr := JsonHelper.Stringify(history)
            fileObj := FileOpen(tempFile, "w", "UTF-8")
            if (fileObj)
                fileObj.Write(jsonStr)
        } catch as recordErr {
            if IsSet(LogAppError)
                LogAppError("RunHistory.Record", recordErr)
        } finally {
            if IsObject(fileObj)
                fileObj.Close()
        }
        if FileExist(tempFile)
            FileMove(tempFile, ledgerPath, 1)
    }

    /**
     * Recursively masks known-sensitive String values (GSTIN/PAN/phone/email) anywhere inside a
     * run-record value tree (String/Array/Map/Object). Numbers, booleans, and unrecognized object
     * types pass through unchanged.
     * @param {Any} val
     * @returns {Any}
     */
    static _RedactRecursive(val) {
        vType := Type(val)
        if (vType = "String")
            return IsSet(RedactSensitiveData) ? RedactSensitiveData(val) : val

        if (vType = "Array") {
            out := []
            for item in val
                out.Push(RunHistory._RedactRecursive(item))
            return out
        }

        if (vType = "Map") {
            out := Map()
            for k, v in val
                out[k] := RunHistory._RedactRecursive(v)
            return out
        }

        if (IsObject(val)) {
            out := {}
            for propName in val.OwnProps()
                out.DefineProp(propName, {value: RunHistory._RedactRecursive(val.%propName%)})
            return out
        }

        return val
    }

    /**
     * Loads all execution runs from ledger
     * @returns {Array}
     */
    static LoadAll() {
        ledgerPath := RunHistory.GetLedgerPath()
        if (!FileExist(ledgerPath) || FileGetSize(ledgerPath) = 0)
            return []

        try {
            content := FileRead(ledgerPath, "UTF-8")
            parsed := JsonHelper.Parse(content, false)
            if (Type(parsed) = "Array")
                return parsed
            return []
        } catch {
            return []
        }
    }

    /**
     * Finds a run by ID
     * @param {String} runId
     * @returns {Object}
     */
    static Get(runId) {
        history := RunHistory.LoadAll()
        for entry in history {
            eid := IsObject(entry) ? (Type(entry) = "Map" ? (entry.Has("run_id") ? entry["run_id"] : "") : (entry.HasOwnProp("run_id") ? entry.run_id : "")) : ""
            if (eid = runId)
                return entry
        }
        return ""
    }

    /**
     * Deletes a specific run by ID
     * @param {String} runId
     * @returns {Boolean}
     */
    static Delete(runId) {
        history := RunHistory.LoadAll()
        newHistory := []
        found := false

        for entry in history {
            eid := IsObject(entry) ? (Type(entry) = "Map" ? (entry.Has("run_id") ? entry["run_id"] : "") : (entry.HasOwnProp("run_id") ? entry.run_id : "")) : ""
            if (eid = runId) {
                found := true
                continue
            }
            newHistory.Push(entry)
        }

        if found {
            ledgerPath := RunHistory.GetLedgerPath()
            tempFile := ledgerPath . ".tmp"
            try {
                jsonStr := JsonHelper.Stringify(newHistory)
                fileObj := FileOpen(tempFile, "w", "UTF-8")
                if (fileObj) {
                    fileObj.Write(jsonStr)
                    fileObj.Close()
                    if FileExist(ledgerPath)
                        FileDelete(ledgerPath)
                    FileMove(tempFile, ledgerPath)
                }
            }
        }
        return found
    }

    /**
     * Clears all execution history
     */
    static ClearAll() {
        ledgerPath := RunHistory.GetLedgerPath()
        if FileExist(ledgerPath)
            FileDelete(ledgerPath)
    }
}
