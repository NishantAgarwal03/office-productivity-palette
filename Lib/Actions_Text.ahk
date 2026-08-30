; ======================================================================================================================
; Module: Actions_Text.ahk - 15 Text Formatting, Case Transformation & List Tools
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterTextActions() {
    RegisterAction("Word & Character Statistics", "🔤 Transform", "[Needs Selection] Shows Words, Characters with/without spaces & Lines", "count, words, characters, stats, length", (*) => (IsSet(ShowTextStats) ? ShowTextStats() : ""), "", "Ctrl+Shift+G")
    RegisterAction("Cycle Text Case (Word Standard)", "🔤 Transform", "[Needs Selection] Cycles lower -> Title -> UPPER -> lower", "cycle, case, word, shift, f3, toggle", (*) => TransformSelectedText((txt) => CycleTextCase(txt)), "", "Shift+F3")
    RegisterAction("Paste Clean Plain Text", "🔤 Transform", "[Cleans Selection] Strips HTML, font styles & excess whitespace", "plain, clean, strip, paste, unformat", (*) => TransformSelectedText((txt) => CleanPlainText(txt)), "v")
    RegisterAction("Convert to UPPERCASE", "🔤 Transform", "[Needs Selection] Converts highlighted text to ALL CAPS", "upper, caps, case, uppercase", (*) => TransformSelectedText((txt) => StrUpper(txt)))
    RegisterAction("Convert to lowercase", "🔤 Transform", "[Needs Selection] Converts highlighted text to all lowercase", "lower, case, lowercase", (*) => TransformSelectedText((txt) => StrLower(txt)))
    RegisterAction("Convert to Title Case", "🔤 Transform", "[Needs Selection] Capitalizes The First Letter Of Every Word", "title, capitalize, case, headline", (*) => TransformSelectedText((txt) => StrTitle(txt)))
    RegisterAction("Convert to Sentence case", "🔤 Transform", "[Needs Selection] Capitalizes the first letter of each sentence", "sentence, case, grammar", (*) => TransformSelectedText((txt) => ToSentenceCase(txt)))
    RegisterAction("Convert to snake_case", "🔤 Transform", "[Needs Selection] Converts highlighted text to snake_case", "snake, case, underscore, code", (*) => TransformSelectedText((txt) => ToDelimitedCase(txt, "_")), "s")
    RegisterAction("Convert to kebab-case", "🔤 Transform", "[Needs Selection] Converts highlighted text to kebab-case", "kebab, case, dash, slug", (*) => TransformSelectedText((txt) => ToDelimitedCase(txt, "-")))
    RegisterAction("Convert to camelCase", "🔤 Transform", "[Needs Selection] Converts highlighted text to camelCase", "camel, case, identifier, code", (*) => TransformSelectedText((txt) => ToCamelCase(txt)))
    RegisterAction("Quote Lines (SQL IN format)", "🔤 Transform", "[Needs Selection] Wraps each line in ('item1', 'item2')", "sql, quote, in, list, csv", (*) => TransformSelectedText((txt) => FormatSqlInList(txt)))
    RegisterAction("Join Lines into Single Paragraph", "🔤 Transform", "[Needs Selection] Merges PDF/web linebreaks into single paragraph", "join, unwrapper, paragraph, pdf, single line", (*) => TransformSelectedText((txt) => JoinLinesIntoParagraph(txt)))
    RegisterAction("Convert Lines to Bulleted List (•)", "🔤 Transform", "[Needs Selection] Adds bullet point (• ) to every line", "bullet, bullets, bul, list, point, unordered, dots", (*) => TransformSelectedText((txt) => FormatBulletList(txt)))
    RegisterAction("Convert Lines to Numbered List (1, 2, 3)", "🔤 Transform", "[Needs Selection] Adds sequential numbers (1. 2. 3.) to lines", "numbered, numbers, num, list, ordered, sequence", (*) => TransformSelectedText((txt) => FormatNumberedList(txt)))
    RegisterAction("Convert Lines to Checklist ([ ])", "🔤 Transform", "[Needs Selection] Formats lines as markdown checkbox items", "check, checkbox, checklist, task, box, todo", (*) => TransformSelectedText((txt) => FormatChecklist(txt)), "x")
}

CycleTextCase(text) {
    if (Trim(text) = "")
        return text
        
    lettersOnly := RegExReplace(text, "[^a-zA-Z]", "")
    if (lettersOnly = "")
        return text
        
    if (lettersOnly == StrUpper(lettersOnly))
        return StrLower(text)
        
    if (lettersOnly == StrLower(lettersOnly))
        return StrTitle(text)
        
    return StrUpper(text)
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [SIMPLE REGEX-BASED SENTENCE CASE - INTENTIONAL NON-GOAL]:
; Does NOT handle abbreviations (Mr., e.g., i.e., Dr.) — this is intentionally simple regex-based.
; Full NLP-aware sentence case or heavy linguistic dictionary lookups are deliberate non-goals 
; to keep the tool instant, lightweight, and zero-dependency.
; ======================================================================================================================
ToSentenceCase(text) {
    lower := StrLower(text)
    return RegExReplace(lower, "((?:^|[\.!\?]\s+))([a-z])", "$1$U2")
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [DELIMITED & SNAKE/KEBAB CASE - INTENTIONAL NON-GOALS]:
; 1. Input Intent: Designed specifically for converting SPACE/DASH/UNDERSCORE-separated words into snake_case/kebab-case.
; 2. Camel Splitting: Does NOT split on camelCase boundaries (e.g. 'camelCase' is not split into 'camel_case').
;    Refactoring existing camelCase identifiers, complex punctuation boundary policies, and Unicode transliteration
;    are deliberate non-goals to keep this office text transformation simple, fast, and non-destructive.
; ======================================================================================================================
ToDelimitedCase(text, delimiter) {
    clean := RegExReplace(text, "[^\w\s-]", "")
    clean := RegExReplace(clean, "[\s_-]+", delimiter)
    return StrLower(Trim(clean, delimiter))
}

ToCamelCase(text) {
    clean := RegExReplace(text, "[^\w\s-]", " ")
    words := StrSplit(clean, [" ", "_", "-"])
    out := ""
    for idx, w in words {
        if (w = "")
            continue
        if (out = "")
            out .= StrLower(w)
        else
            out .= StrUpper(SubStr(w, 1, 1)) . StrLower(SubStr(w, 2))
    }
    return out
}

FormatSqlInList(text) {
    lines := StrSplit(text, "`n", "`r")
    items := []
    for l in lines {
        t := Trim(l)
        if (t != "")
            items.Push("'" . StrReplace(t, "'", "''") . "'")
    }
    if (items.Length = 0)
        return text
    joined := ""
    for idx, item in items {
        joined .= (idx > 1 ? ", " : "") . item
    }
    return "(" . joined . ")"
}

FormatBulletList(text) {
    lines := StrSplit(text, ["`r`n", "`n", "`r"])
    out := ""
    for l in lines {
        t := Trim(l)
        if (t = "")
            continue
        t := RegExReplace(t, "^[\s•\-\*]+", "")
        out .= (out != "" ? "`n" : "") . "• " . t
    }
    return out
}

FormatNumberedList(text) {
    lines := StrSplit(text, ["`r`n", "`n", "`r"])
    out := ""
    idx := 1
    for l in lines {
        t := Trim(l)
        if (t = "")
            continue
        t := RegExReplace(t, "^\s*\d+[\.\)]\s*", "")
        out .= (out != "" ? "`n" : "") . idx . ". " . t
        idx++
    }
    return out
}

FormatChecklist(text) {
    lines := StrSplit(text, ["`r`n", "`n", "`r"])
    out := ""
    for l in lines {
        t := Trim(l)
        if (t = "")
            continue
        t := RegExReplace(t, "^\s*(\[\s*\]|\[x\]|•|\-|\*|\d+[\.\)])\s*", "")
        out .= (out != "" ? "`n" : "") . "- [ ] " . t
    }
    return out
}

; ======================================================================================================================
; SCOPE & DESIGN BOUNDARY [JOIN LINES INTO SINGLE PARAGRAPH - INTENTIONAL AGGRESSIVE REGEX]:
; 1. Uses aggressive regex — ALL newlines (\R+) become spaces. This is the desired behavior for PDF text extraction.
; 2. Dehyphenation, paragraph/bullet/table detection, and final trimming are intentional non-goals
;    to keep line merging fast, predictable, and simple.
; ======================================================================================================================
JoinLinesIntoParagraph(text) {
    return RegExReplace(RegExReplace(text, "\R+", " "), "\h{2,}", " ")
}

; ======================================================================================================================
; ARCHITECTURAL INTENT [PROGRESSIVE 2-PASS TRANSFORMATION - DO NOT REMOVE]:
; 2-pass behavior is intentional:
; - Pass 1: Cleans Unicode artifacts, strips trailing spaces, normalizes CRLF, and collapses excessive whitespace.
; - Pass 2 (Repeated invocation on already-clean text): Un-wraps single line breaks into a flowing paragraph
;   while preserving double line breaks (paragraphs).
; Toggling between structured lines and flowing paragraphs on repeated execution is a core design feature.
; ======================================================================================================================
CleanPlainText(text) {
    if (text == "")
        return ""
    
    ; 1. Normalize Unicode non-breaking & zero-width spaces to ASCII space
    t := RegExReplace(text, "[\x{00A0}\x{200B}\x{200C}\x{200D}\x{FEFF}]", " ")
    
    ; 2. Normalize linebreaks to Windows CRLF standard
    t := RegExReplace(t, "\R", "`r`n")
    
    ; 3. Strip trailing spaces/tabs from every individual line
    t := RegExReplace(t, "m)[ \t]+$", "")
    
    ; 4. Collapse 3+ consecutive newlines to double newlines (paragraph break)
    t := RegExReplace(t, "(`r?`n){3,}", "`r`n`r`n")
    
    ; 5. Collapse multiple horizontal spaces and tabs into a single space
    t := RegExReplace(t, "[ \t]{2,}", " ")
    
    cleanT := Trim(t)

    ; Pass 2: If text was already clean multiline text, repeating action unwraps single linebreaks into a flowing paragraph
    if (cleanT == text && InStr(cleanT, "`n")) {
        cleanT := RegExReplace(cleanT, "(?<![\r\n])\R(?![\r\n])", " ")
        cleanT := RegExReplace(cleanT, "[ \t]{2,}", " ")
    }
    
    return cleanT
}

