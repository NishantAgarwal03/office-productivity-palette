; ======================================================================================================================
; Module: WorkflowTypes.ahk - Canonical Value Types & Strict Validation Engine
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS & DESIGN BOUNDARIES:
; 1. Explicit Type System: The initial type system consists strictly of Text, Number, Items<T>, 
;    Record, and FileReference.
; 2. No Silent Coercion: Multiline input remains Text until an explicit Split step converts it into Items<Text>.
;    Types are not silently coerced behind the scenes; conversions must use visible steps.
; 3. FileReference Security: File recipes operate ONLY on file references (path, name, stem, extension, folder, index).
;    The workflow system does NOT read file contents.
; ======================================================================================================================

#Requires AutoHotkey v2.0

class WorkflowTypes {
    static TYPE_TEXT           := "text"
    static TYPE_NUMBER         := "number"
    static TYPE_ITEMS_TEXT     := "items<text>"
    static TYPE_ITEMS_NUMBER   := "items<number>"
    static TYPE_ITEMS_RECORD   := "items<record>"
    static TYPE_ITEMS_FILE     := "items<filereference>"
    static TYPE_ITEMS_ANY      := "items<any>"
    static TYPE_RECORD         := "record"
    static TYPE_FILE_REFERENCE := "filereference"
    static TYPE_ANY            := "any"

    /**
     * Normalizes a type string to lowercase trimmed representation
     * @param {String} t
     * @returns {String}
     */
    static Normalize(t) {
        clean := StrLower(Trim(t))
        clean := StrReplace(clean, " ", "")
        return clean
    }

    /**
     * Extracts the inner type T from Items<T>
     * @param {String} t
     * @returns {String}
     */
    static GetItemInnerType(t) {
        norm := WorkflowTypes.Normalize(t)
        if RegExMatch(norm, "^items<(.+)>$", &m)
            return m[1]
        return ""
    }

    /**
     * Checks if a source type is compatible with a target required input type
     * @param {String} sourceType
     * @param {String} targetType
     * @returns {Boolean}
     */
    static AreCompatible(sourceType, targetType) {
        s := WorkflowTypes.Normalize(sourceType)
        t := WorkflowTypes.Normalize(targetType)

        if (t = WorkflowTypes.TYPE_ANY || s = WorkflowTypes.TYPE_ANY)
            return true

        if (s == t)
            return true

        ; Items<any> matches any Items<T>
        if (t = WorkflowTypes.TYPE_ITEMS_ANY && SubStr(s, 1, 6) = "items<")
            return true
        if (s = WorkflowTypes.TYPE_ITEMS_ANY && SubStr(t, 1, 6) = "items<")
            return true

        return false
    }

    /**
     * Validates that a runtime value conforms to the declared canonical type
     * @param {Any} val
     * @param {String} declaredType
     * @returns {Object} {valid: Boolean, message: String}
     */
    static ValidateValue(val, declaredType) {
        norm := WorkflowTypes.Normalize(declaredType)

        if (norm = WorkflowTypes.TYPE_ANY)
            return {valid: true, message: ""}

        if (norm = WorkflowTypes.TYPE_TEXT) {
            if (Type(val) = "String")
                return {valid: true, message: ""}
            return {valid: false, message: "Expected Text (String), got " . Type(val)}
        }

        if (norm = WorkflowTypes.TYPE_NUMBER) {
            if (IsNumber(val))
                return {valid: true, message: ""}
            return {valid: false, message: "Expected Number (Integer/Float), got " . Type(val)}
        }

        if (norm = WorkflowTypes.TYPE_RECORD) {
            if (Type(val) = "Map" || (IsObject(val) && Type(val) != "Array"))
                return {valid: true, message: ""}
            return {valid: false, message: "Expected Record (Map/Object), got " . Type(val)}
        }

        if (norm = WorkflowTypes.TYPE_FILE_REFERENCE) {
            if (IsObject(val) && val.HasOwnProp("path") && val.HasOwnProp("name"))
                return {valid: true, message: ""}
            return {valid: false, message: "Expected FileReference object with path & name"}
        }

        ; Collection: Items<T>
        if (SubStr(norm, 1, 6) = "items<") {
            if (Type(val) != "Array")
                return {valid: false, message: "Expected Items<T> (Array), got " . Type(val)}

            innerType := WorkflowTypes.GetItemInnerType(norm)
            if (innerType = "" || innerType = "any" || val.Length = 0)
                return {valid: true, message: ""}

            ; Check members
            for idx, item in val {
                itemCheck := WorkflowTypes.ValidateValue(item, innerType)
                if !itemCheck.valid {
                    return {valid: false, message: Format("Item [{1}] type mismatch: {2}", idx, itemCheck.message)}
                }
            }
            return {valid: true, message: ""}
        }

        return {valid: false, message: "Unknown canonical type: " . declaredType}
    }

    /**
     * Constructs a safe FileReference descriptor without opening or reading file content
     * @param {String} fullPath
     * @param {Integer} index
     * @returns {Object}
     */
    static CreateFileReference(fullPath, index := 1) {
        SplitPath(fullPath, &fileName, &dirPath, &ext, &stem)
        return {
            path: fullPath,
            name: fileName,
            stem: stem,
            extension: ext,
            folder: dirPath,
            index: index
        }
    }
}
