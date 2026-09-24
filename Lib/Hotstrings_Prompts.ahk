; ======================================================================================================================
; Module: Hotstrings_Prompts.ahk - Academic Prompts & Dynamic Office Expansion Engine
; Shared cross-suite module (Study & Markdown Hub + Office Productivity Hub)
; ======================================================================================================================

; --- 1. Academic & AI Markdown Prompts ---
:T:gmd::generate markdown code for content below as per instruction provided
::fif::follow exact instruction as in file provided
:T:srt1::Strategically integrate specific dynamic elements, extracted from the transcript—including the lecturer's analogies, framing questions, thought processes, and emphasized points—directly into the technical explanations. Place these elements at logical points (e.g., analogies following definitions, questions introducing concepts) to enhance clarity, engaging style, and significantly boost readability and learner connection, always without sacrificing technical accuracy. the quote should be with clarifications in brackets and ellipses ("...") where parts are not essential to convey the core idea.
:T:sqlbot::Follow this order: Core Area 4, then Core Area 2, Core Area 1, Core Area 3, and finally Core Area 5. Finally Ensuring the formating (h3,h4 etc, numbering etc, markdown, etc) of notes are aligned closely with the example given in the instruction file give the result detailed notes Include the main and subtopic index, as well as keywords. Each subtopic should have relevant headings, such as 'Additional Points' and 'Pitfalls,'etc  where applicable and conclude the notes with concluding elements such as 'Lecture Highlights' etc.
::inkpost1::I have an image or "article 1" and a "article 2". I need help writing a LinkedIn post that creatively integrates the idea of the image or "article 1" into the "article 2",  the image or "article 1" won't be posted so integrate the idea such that its explicit mention is not required. The post should resonate with a general audience, not just domain experts. Please also suggest 10 relevant tags to help spread the post effectively.
::inkpost::Create a LinkedIn post between 150 and 220 words that explains an intuition/concept behind a unique formula from a Civil Engineering B.Tech course using an analogy (80% of the content). The formula should be selected based on the event (on this day). The formula introduced on that historical date is the one to be explained. The remaining 20% of the post should relate this explanation to a current trending topic on LinkedIn to make the content engaging and beneficial for readers. Include relevant hashtags. The generated article should use a temperature setting of 0.
::sqlrev::Please verify that my notes meet the following criteria based on a given transcript: Ensure that the notes cover 100% of the transcript without missing any part related to subject, including questions discussed, shortcuts,  notes, discussions, queries, examples, and other relevant details. Check that the notes are clear, accurate, and that the examples discussed effectively illustrate the concepts as outlined in the transcript. Also rate notes given above in terms of content cover, explanation, clarity, accuracy, etc out of 20. Confirm that no additional information beyond the transcript’s content is included; only explanations, analogy and examples necessary for clarity may be added. Avoid introducing any new terms or concepts not present in the transcript. Retain the original structure (such as heading h3 , h4 etc) of my notes. I will share both my notes and the transcript with you, and you may begin the evaluation once you have both documents.

; --- 2. Dynamic Date & Time Expansions ---
::ldt:: {
    InsertStudyText(FormatTime(A_Now, "dddd, d MMMM yyyy 'Time:' hh:mm tt"))
}

::tndate:: {
    InsertStudyText(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"))
}

; --- 3. Dynamic Context & Smart Office Expansions ---

; egreet: Context-aware email greeting based on system clock
::egreet:: {
    hour := Integer(FormatTime(A_Now, "H"))
    if (hour < 12)
        greeting := "Good morning,"
    else if (hour < 17)
        greeting := "Good afternoon,"
    else
        greeting := "Good evening,"
    InsertStudyText(greeting)
}

; inwords: Converts number/words (e.g. 1.25 Lakh, 2.5 Crore, 12500) from clipboard into formal Indian Currency Words
::inwords:: {
    clipVal := Trim(A_Clipboard)
    if (clipVal == "") {
        ib := InputBox("Please enter the number or amount to convert into Indian Currency words (e.g. '1.25 Lakh', '2.5 Crore', 125000):", "Convert Number to Words", "w460 h150")
        if (ib.Result != "OK" || Trim(ib.Value) == "")
            return
        clipVal := Trim(ib.Value)
    }
    
    words := NumberToIndianWords(clipVal)
    if (words != "Invalid Number") {
        InsertStudyText(words)
    } else {
        ShowStudyToast("⚠️ Invalid number for Indian Currency conversion", 2000)
    }
}

; cbwrap: Wraps clipboard content in quotation marks
::cbwrap:: {
    clipVal := Trim(A_Clipboard)
    if (clipVal != "")
        InsertStudyText('"' . clipVal . '"')
}

; cblist: Converts multi-line clipboard text into a numbered list
::cblist:: {
    clipVal := Trim(A_Clipboard)
    if (clipVal == "")
        return
    lines := StrSplit(clipVal, "`n", "`r")
    outList := ""
    idx := 1
    for line in lines {
        l := Trim(line)
        if (l != "") {
            outList .= (idx > 1 ? "`n" : "") . idx . ". " . l
            idx++
        }
    }
    InsertStudyText(outList)
}

; lipsum: Standard 2-paragraph placeholder filler text
:T:lipsum::Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.`n`nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
