; ======================================================================================================================
; Module: JsonHelper.ahk - Lightweight JSON Parser & Serializer for AHK v2
; Part of Office Productivity Hub (v2.0.1)
; ======================================================================================================================

#Requires AutoHotkey v2.0

class JsonHelper {
    ; --- JSON Deserializer (Parse) ---
    static Parse(jsonStr, asMap := false) {
        if (Trim(jsonStr) = "")
            return ""
            
        try {
            html := ComObject("HTMLFile")
            html.write("<meta http-equiv='X-UA-Compatible' content='IE=edge'>")
            jsObj := html.parentWindow.JSON.parse(jsonStr)
            return JsonHelper._ConvertJsObject(jsObj, html.parentWindow, asMap)
        } catch as parseErr {
            throw Error("JSON Parse Error: " . parseErr.Message)
        }
    }

    static _ConvertJsObject(jsObj, pw, asMap := false) {
        if !IsObject(jsObj)
            return jsObj

        ; Detect Arrays
        isArr := false
        try {
            isArr := pw.Array.isArray(jsObj)
        } catch {
            try {
                isArr := (pw.Object.prototype.toString.call(jsObj) = "[object Array]")
            }
        }

        if (isArr) {
            arr := []
            len := jsObj.length
            Loop len {
                arr.Push(JsonHelper._ConvertJsObject(jsObj.%A_Index - 1%, pw, asMap))
            }
            return arr
        }

        ; Object or Map
        try {
            keys := pw.Object.keys(jsObj)
            kLen := keys.length
            if (asMap) {
                resMap := Map()
                Loop kLen {
                    k := keys.%A_Index - 1%
                    resMap[k] := JsonHelper._ConvertJsObject(jsObj.%k%, pw, asMap)
                }
                return resMap
            } else {
                resObj := {}
                Loop kLen {
                    k := keys.%A_Index - 1%
                    resObj.DefineProp(k, {value: JsonHelper._ConvertJsObject(jsObj.%k%, pw, asMap)})
                }
                return resObj
            }
        } catch {
            return jsObj
        }
    }

    ; --- JSON Serializer (Stringify) ---
    static Stringify(val, indent := "  ", level := 0) {
        if (val = "" && Type(val) != "String")
            return "null"

        vType := Type(val)

        if (vType = "Integer" || vType = "Float")
            return String(val)

        if (vType = "Boolean")
            return val ? "true" : "false"

        if (vType = "String")
            return '"' . JsonHelper.EscapeString(val) . '"'

        prefix := ""
        Loop level
            prefix .= indent
        nextPrefix := prefix . indent

        if (vType = "Array") {
            if (val.Length = 0)
                return "[]"
            lines := []
            for item in val {
                lines.Push(nextPrefix . JsonHelper.Stringify(item, indent, level + 1))
            }
            return "[`n" . JsonHelper._JoinStrings(",`n", lines) . "`n" . prefix . "]"
        }

        if (vType = "Map") {
            if (val.Count = 0)
                return "{}"
            lines := []
            for k, v in val {
                kEsc := '"' . JsonHelper.EscapeString(String(k)) . '"'
                lines.Push(nextPrefix . kEsc . ": " . JsonHelper.Stringify(v, indent, level + 1))
            }
            return "{`n" . JsonHelper._JoinStrings(",`n", lines) . "`n" . prefix . "}"
        }

        ; Generic Object with properties
        if IsObject(val) {
            if (vType = "ComObject")
                return '"{ComObject}"'
            props := []
            for prop in val.OwnProps() {
                pEsc := '"' . JsonHelper.EscapeString(String(prop)) . '"'
                props.Push(nextPrefix . pEsc . ": " . JsonHelper.Stringify(val.%prop%, indent, level + 1))
            }
            if (props.Length = 0)
                return "{}"
            return "{`n" . JsonHelper._JoinStrings(",`n", props) . "`n" . prefix . "}"
        }

        return '"' . JsonHelper.EscapeString(String(val)) . '"'
    }

    static EscapeString(str) {
        s := String(str)
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`t", "\t")
        return s
    }

    static _JoinStrings(sep, arr) {
        res := ""
        for i, item in arr {
            res .= item . (i < arr.Length ? sep : "")
        }
        return res
    }
}
