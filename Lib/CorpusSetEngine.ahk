; ======================================================================================================================
; Module: CorpusSetEngine.ahk - Universal Corpus Set & Vocabulary Deviation Analyzer
; Part of Office Productivity Hub (v2.0.1) - Shared Mathematical Core
;
; DESIGN INTENT, ARCHITECTURAL CONSTRAINTS & SPECIFICATION:
;
; 1. Core Mathematical Capabilities:
;    - Universal Mutual Baseline: Identifies 100% mutual token baseline across documents to isolate shared boilerplate.
;    - 5-Tier Document Frequency Profiling (Coverage % across N documents):
;      * Common: > 75% and < 100%
;      * Moderately distinctive: > 50%
;      * Distinctive: > 20%
;      * Low distinctive: > 4%
;      * Very distinctive: <= 4%
;    - Difference Stripping: Strips universal (100%) baseline tokens via discrete boundary regex (?<!\w)\Qtoken\E(?!\w).
;    - 4-Column TSV Statistics: Formats term coverage into clean tab-delimited records for spreadsheets.
;
; 2. Engine-Level Non-Goals & Invariants (DO NOT "FIX" OR REFACTOR):
;    - Minimum Arity (N >= 2): Mathematical set comparison strictly requires at least 2 lines, paragraphs, or files.
;    - Exact Token Matching (No Fuzzy/Semantic NLP): Operates strictly via exact case-insensitive lexical matching.
;      Semantic grouping (e.g., 'RCC' vs 'reinforced concrete') and fuzzy typo matching are intentional non-goals.
;    - Token-Level Difference (No Fluent Grammar): Difference mode removes baseline tokens; output consists of
;      isolated distinctive terms/fragments, NOT grammatically reconstructed sentences.
; ======================================================================================================================

#Requires AutoHotkey v2.0

class CorpusSetEngine {
    static _Stopwords := Map()

    static __New() {
        this._Stopwords.CaseSense := false
        rawStopwords := [
            "a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", 
            "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", 
            "but", "by", "can't", "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", 
            "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", 
            "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", 
            "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll", 
            "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", 
            "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", 
            "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", 
            "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", 
            "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", 
            "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", 
            "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", 
            "we'd", "we'll", "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", 
            "where", "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", 
            "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", "your", 
            "yours", "yourself", "yourselves"
        ]
        for word in rawStopwords {
            this._Stopwords[word] := true
        }
    }

    /**
     * Checks if a word is an English stopword
     * @param {String} word
     * @returns {Boolean}
     */
    static IsStopword(word) {
        return this._Stopwords.Has(StrLower(Trim(word)))
    }

    /**
     * Ingests arbitrary input into an Array of document strings
     * Handles multiline text, arrays, and existing file paths safely.
     * @param {Any} inputVal
     * @returns {Array<String>}
     */
    static Ingest(inputVal) {
        docs := []

        if (Type(inputVal) == "Array") {
            ; Check if all elements are valid existing file paths with path separators
            allFiles := (inputVal.Length >= 2)
            for item in inputVal {
                s := Trim(String(item))
                if (!(InStr(s, "\") || InStr(s, "/")) || !FileExist(s)) {
                    allFiles := false
                    break
                }
            }

            if (allFiles) {
                for item in inputVal {
                    docs.Push(FileRead(Trim(String(item)), "UTF-8"))
                }
            } else {
                for item in inputVal {
                    s := Trim(String(item))
                    if (s != "")
                        docs.Push(s)
                }
            }
        } else {
            text := String(inputVal)
            rawLines := StrSplit(text, "`n", "`r")
            
            ; Check if lines represent newline-delimited file paths
            allFiles := (rawLines.Length >= 2)
            for line in rawLines {
                s := Trim(line)
                if (s == "")
                    continue
                if (!(InStr(s, "\") || InStr(s, "/")) || !FileExist(s)) {
                    allFiles := false
                    break
                }
            }

            if (allFiles) {
                for line in rawLines {
                    s := Trim(line)
                    if (s != "" && FileExist(s))
                        docs.Push(FileRead(s, "UTF-8"))
                }
            } else {
                for line in rawLines {
                    s := Trim(line)
                    if (s != "")
                        docs.Push(s)
                }
            }
        }

        if (docs.Length < 2)
            throw Error("CorpusSetEngine requires at least 2 documents, lines, or files to compare.")

        return docs
    }

    /**
     * Clean and tokenize a text document into discrete terms
     * Strips leading and trailing punctuation while preserving internal hyphens/symbols (e.g., M-25, 1:2:4).
     * @param {String} text
     * @returns {Array<String>}
     */
    static Tokenize(text) {
        tokens := []
        normalized := RegExReplace(text, "[\r\n\t]+", " ")
        words := StrSplit(normalized, " ")
        
        for w in words {
            t := Trim(w)
            if (t == "")
                continue
            ; Strip outer non-word characters while preserving internal characters
            cleaned := RegExReplace(t, "^[^\w]+|[^\w]+$", "")
            if (cleaned != "")
                tokens.Push(cleaned)
        }
        return tokens
    }

    /**
     * Analyzes corpus vocabulary and computes set intersections and document frequencies
     * @param {Array<String>} documents
     * @param {Object} options - { filterStopwords: true }
     * @returns {Object} AnalysisResult
     */
    static Analyze(documents, options := {}) {
        if (!IsObject(documents) || documents.Length < 2)
            throw Error("CorpusSetEngine requires at least 2 documents to analyze.")

        filterStopwords := (!options.HasOwnProp("filterStopwords") || options.filterStopwords)
        totalDocs := documents.Length

        dfMap := Map()      ; key -> doc frequency (count of docs containing word)
        dfMap.CaseSense := false
        tfMap := Map()      ; key -> total frequency across all docs
        tfMap.CaseSense := false
        displayMap := Map() ; key -> original casing of first appearance
        displayMap.CaseSense := false

        ; First Pass: Document-level frequency
        for doc in documents {
            tokens := this.Tokenize(doc)
            seenInDoc := Map()
            seenInDoc.CaseSense := false

            for tok in tokens {
                key := StrLower(tok)
                if (filterStopwords && this.IsStopword(key))
                    continue

                ; Track term frequency
                tfMap[key] := (tfMap.Has(key) ? tfMap[key] + 1 : 1)
                if (!displayMap.Has(key))
                    displayMap[key] := tok

                ; Track document frequency (counted once per document)
                if (!seenInDoc.Has(key)) {
                    seenInDoc[key] := true
                    dfMap[key] := (dfMap.Has(key) ? dfMap[key] + 1 : 1)
                }
            }
        }

        universalTokens := Map()
        universalTokens.CaseSense := false
        wordsMap := Map()
        wordsMap.CaseSense := false

        tierCounts := {
            common: 0,
            moderate: 0,
            distinctive: 0,
            low: 0,
            veryLow: 0
        }

        ; Second Pass: Classification
        for key, df in dfMap {
            disp := displayMap[key]
            cov := df / totalDocs

            if (df == totalDocs) {
                universalTokens[key] := disp
            }

            tier := ""
            if (cov > 0.75) {
                tier := "Common"
                tierCounts.common++
            } else if (cov > 0.50) {
                tier := "Moderately distinctive"
                tierCounts.moderate++
            } else if (cov > 0.20) {
                tier := "Distinctive"
                tierCounts.distinctive++
            } else if (cov > 0.04) {
                tier := "Low distinctive"
                tierCounts.low++
            } else {
                tier := "Very distinctive"
                tierCounts.veryLow++
            }

            wordsMap[key] := {
                term: disp,
                df: df,
                tf: tfMap[key],
                coverage: cov,
                tier: tier
            }
        }

        return {
            documents: documents,
            totalDocs: totalDocs,
            dfMap: dfMap,
            tfMap: tfMap,
            displayMap: displayMap,
            universalTokens: universalTokens,
            words: wordsMap,
            tierCounts: tierCounts
        }
    }

    /**
     * Extracts 100% mutual tokens across all documents (set intersection)
     * @param {Array<String>} documents
     * @param {Object} options
     * @returns {Array<String>}
     */
    static ComputeIntersection(documents, options := {}) {
        analysis := this.Analyze(documents, options)
        result := []
        for key, disp in analysis.universalTokens
            result.Push(disp)
        return result
    }

    /**
     * Strips universal 100% boilerplate tokens non-destructively from a single document string
     * Preserves casing, internal punctuation, and intra-sentence duplicate words.
     * Uses lookaround boundary matching (?<!\w)\Qtoken\E(?!\w) for safe symbol/hyphen isolation.
     * @param {String} rawDoc
     * @param {Map} universalTokens
     * @returns {String}
     */
    static StripUniversalTokens(rawDoc, universalTokens) {
        if (universalTokens.Count == 0)
            return rawDoc

        cleanText := rawDoc
        for key, disp in universalTokens {
            ; Robust regex with lookarounds and \Q...\E literal escape
            pattern := "i)(?<!\w)\Q" . key . "\E(?!\w)\s*"
            cleanText := RegExReplace(cleanText, pattern, "")
        }

        ; Post-strip cleanup pass
        ; 1. Collapse consecutive horizontal whitespace
        cleanText := RegExReplace(cleanText, "[ \t]{2,}", " ")
        ; 2. Fix orphaned commas or punctuation before spaces
        cleanText := RegExReplace(cleanText, "\s+([,\.;:])", "$1")
        ; 3. Trim line edges while preserving paragraph structure
        lines := StrSplit(cleanText, "`n", "`r")
        outLines := []
        for l in lines
            outLines.Push(Trim(l))
            
        res := ""
        for idx, l in outLines
            res .= (idx > 1 ? "`r`n" : "") . l

        return Trim(res)
    }

    /**
     * Computes unique differences (deviations) per document by stripping universal baseline tokens
     * @param {Array<String>} documents
     * @param {Object} options
     * @returns {Array<String>}
     */
    static ComputeDifferences(documents, options := {}) {
        analysis := this.Analyze(documents, options)
        differences := []
        for doc in documents {
            diffDoc := this.StripUniversalTokens(doc, analysis.universalTokens)
            differences.Push(diffDoc)
        }
        return differences
    }

    /**
     * Generates distinctive keyword tags for a document
     * @param {String} rawDoc
     * @param {Object} analysisResult
     * @param {Integer} maxTags
     * @returns {String}
     */
    static GenerateDistinctiveTags(rawDoc, analysisResult, maxTags := 5) {
        tokens := this.Tokenize(rawDoc)
        candidateTags := []
        seenTags := Map()
        seenTags.CaseSense := false

        for tok in tokens {
            key := StrLower(tok)
            if (analysisResult.words.Has(key)) {
                wObj := analysisResult.words[key]
                if ((wObj.tier == "Very distinctive" || wObj.tier == "Distinctive") && !seenTags.Has(key)) {
                    seenTags[key] := true
                    candidateTags.Push({term: wObj.term, cov: wObj.coverage})
                }
            }
        }

        if (candidateTags.Length == 0)
            return ""

        ; Pick up to maxTags
        tagTerms := []
        for idx, item in candidateTags {
            if (idx > maxTags)
                break
            tagTerms.Push(item.term)
        }

        tagStr := ""
        for idx, term in tagTerms
            tagStr .= (idx > 1 ? ", " : "") . term

        return "[Tags: " . tagStr . "]"
    }

    /**
     * Formats vocabulary analysis into a clean 4-column TSV string
     * Solves the comma-separated single cell overflow defect.
     * @param {Object} analysisResult
     * @returns {String}
     */
    static FormatStatsTable(analysisResult) {
        out := "Term`tDoc Count`tCoverage %`tTier`r`n"
        
        ; Collect word records
        records := []
        for key, obj in analysisResult.words {
            records.Push(obj)
        }

        ; Sort by coverage descending
        if (records.Length > 1) {
            loop records.Length - 1 {
                i := A_Index
                loop records.Length - i {
                    j := A_Index
                    if (records[j].coverage < records[j + 1].coverage) {
                        tmp := records[j]
                        records[j] := records[j + 1]
                        records[j + 1] := tmp
                    }
                }
            }
        }

        for r in records {
            covPct := Format("{1:0.1f}%", r.coverage * 100)
            docRatio := Format("{1}/{2}", r.df, analysisResult.totalDocs)
            out .= r.term . "`t" . docRatio . "`t" . covPct . "`t" . r.tier . "`r`n"
        }

        return out
    }

    /**
     * Formats sovereign toast message containing the 5 corpus vocabulary tiers
     * @param {Object} tierCounts
     * @returns {String}
     */
    static FormatToastMessage(tierCounts) {
        return "📊 Common: " . tierCounts.common 
             . " · Moderate: " . tierCounts.moderate 
             . " · Distinctive: " . tierCounts.distinctive 
             . " · Low: " . tierCounts.low 
             . " · Very Distinct: " . tierCounts.veryLow
    }

    /**
     * Detects the natural inter-document delimiter of the raw text
     * Preserves Excel/table row structure (single newline) vs paragraph structure (double newline)
     * @param {String} rawText
     * @returns {String}
     */
    static DetectDelimiter(rawText) {
        crlf := InStr(rawText, "`r`n")
        if (InStr(rawText, "`r`n`r`n") || InStr(rawText, "`n`n"))
            return crlf ? "`r`n`r`n" : "`n`n"
        return crlf ? "`r`n" : "`n"
    }

    /**
     * Pipeline execution adapter for Workflow Composer
     * @param {Map|Object} inputs
     * @param {Map|Object} settings
     * @returns {Map}
     */
    static ExecutePipeline(inputs, settings) {
        local source := (IsObject(inputs) && inputs.Has("source")) ? inputs["source"] : ""
        local op := (IsObject(settings) && settings.Has("operation")) ? StrLower(Trim(settings["operation"])) : "difference"
        local filterStopwords := (!IsObject(settings) || !settings.Has("filter_stopwords") || settings["filter_stopwords"])

        local docs := this.Ingest(source)
        local analysis := this.Analyze(docs, {filterStopwords: filterStopwords})
        local delim := this.DetectDelimiter(source)

        resultText := ""
        if (op == "intersection") {
            commonList := []
            for key, disp in analysis.universalTokens
                commonList.Push(disp)
            for idx, w in commonList
                resultText .= (idx > 1 ? ", " : "") . w
        } else if (op == "tags") {
            for idx, d in docs {
                tags := this.GenerateDistinctiveTags(d, analysis)
                lineOut := (tags != "") ? tags . " " . d : d
                resultText .= (idx > 1 ? delim : "") . lineOut
            }
        } else if (op == "stats_table") {
            resultText := this.FormatStatsTable(analysis)
        } else {
            ; Default: "difference"
            diffs := this.ComputeDifferences(docs, {filterStopwords: filterStopwords})
            for idx, diff in diffs
                resultText .= (idx > 1 ? delim : "") . diff
        }

        local outMap := Map()
        outMap["result"] := resultText
        outMap["stats_table"] := this.FormatStatsTable(analysis)
        
        intersectionArr := []
        for key, disp in analysis.universalTokens
            intersectionArr.Push(disp)
        outMap["intersection"] := intersectionArr

        diffsArr := this.ComputeDifferences(docs, {filterStopwords: filterStopwords})
        outMap["differences"] := diffsArr

        return outMap
    }
}
