; ======================================================================================================================
; Production-Grade Word and Character Count Tool
;
; DESCRIPTION:
;   This script counts the words, unique words, characters, and lines of any selected text.
;   It is designed to be robust, non-destructive, and easy to maintain.
;
; HOTKEY:
;   Ctrl+Shift+C (Standalone) / Ctrl+Shift+G (Word Parity in Action Hub)
;
; FEATURES:
;   - Single-Instance: Only one copy of the script can run standalone.
;   - Full Clipboard Preservation: Safely saves and restores all clipboard content (images, files, etc.).
;   - Centralized Settings: All configurable values are at the top of the script.
;   - Accurate Counting: Properly handles various whitespace characters, unique words, and line breaks.
;   - Robust Error Handling: Provides clear feedback for failures or empty selections.
;
; REQUIREMENTS:
;   AutoHotkey v2.0 or later.
; ======================================================================================================================

; --- DIRECTIVES ---
#Requires AutoHotkey v2.0
#SingleInstance Force ; Ensures only one instance runs. 'Force' reloads the script, closing the old instance.

; --- CENTRALIZED CONFIGURATION ---
; All user-configurable settings are grouped here for easy maintenance.
class WordCountSettings {
    Static ClipTimeout := 2         ; Seconds to wait for clipboard data.
    Static TooltipDuration := 10000 ; Milliseconds to show the results tooltip.
    Static ErrorDuration := 3000    ; Milliseconds to show an error or info tooltip.
    Static WordDelimiters := [" ", "`n", "`r", "`t"] ; Characters that separate words.
}

; --- STANDALONE HOTKEY DEFINITION (Disabled: Word parity ^+g in Hub prevents collision with ColorPicker/AdvancedPaste) ---
; ^+c::ShowWordCountTooltip()

; --- CALLABLE MODULE FUNCTIONS ---
ShowTextStats(providedText := "") => ShowWordCountTooltip(providedText)

ShowWordCountTooltip(providedText := "") {
    if (providedText != "") {
        text := providedText
    } else {
        ; --- Step 1: Preserve the original clipboard content (ALL formats) ---
        prevClipboard := ClipboardAll()

        ; --- Step 2: Capture the selected text ---
        A_Clipboard := ""
        Send "^c"

        if !ClipWait(WordCountSettings.ClipTimeout) {
            if IsSet(NotifyVisualFeedbackDispatched)
                NotifyVisualFeedbackDispatched()
            ToolTip "Failed: No text selected to count text"
            SetTimer () => ToolTip(), -WordCountSettings.ErrorDuration
            A_Clipboard := prevClipboard
            return
        }
        
        text := A_Clipboard
        A_Clipboard := prevClipboard
    }

    ; --- Step 3: Analyze the captured text ---
    if (Trim(text) = "") {
        if IsSet(NotifyVisualFeedbackDispatched)
            NotifyVisualFeedbackDispatched()
        ToolTip "Selection contains no text after trimming whitespace."
        SetTimer () => ToolTip(), -WordCountSettings.ErrorDuration
        return
    }

    ; Perform the counts accurately based on the full selection.
    metrics := CalculateTextMetrics(text)

    ; --- Step 4: Display the results ---
    tooltipText := "Words: " . metrics.words . " (Unique: " . metrics.uniqueWords . ")"
                . "`nCharacters (with spaces): " . metrics.charsWithSpaces
                . "`nCharacters (no spaces): " . metrics.charsNoSpaces
                . "`nLines: " . metrics.lines
    
    if IsSet(NotifyVisualFeedbackDispatched)
        NotifyVisualFeedbackDispatched()
    ToolTip tooltipText
    SetTimer () => ToolTip(), -WordCountSettings.TooltipDuration
}

; ----------------------------------------------------------------------------------------------------------------------
; Function: CalculateTextMetrics
;   Calculates words, unique words, characters (with/without spaces), and lines.
; ----------------------------------------------------------------------------------------------------------------------
CalculateTextMetrics(text) {
    ; 1. Word and Unique Word Count
    words := StrSplit(Trim(text), WordCountSettings.WordDelimiters, " `n`r`t")
    wordCount := 0
    uniqueMap := Map()
    for word in words {
        cw := Trim(word)
        if (cw != "") {
            wordCount++
            uniqueMap[StrLower(cw)] := true
        }
    }

    ; 2. Character Counts
    charsWithSpaces := StrLen(text)
    charsNoSpaces := StrLen(RegExReplace(text, "\s", ""))

    ; 3. Line Count
    lines := StrSplit(text, "`n", "`r")
    lineCount := lines.Length

    return {
        words: wordCount,
        uniqueWords: uniqueMap.Count,
        charsWithSpaces: charsWithSpaces,
        charsNoSpaces: charsNoSpaces,
        lines: lineCount
    }
}
