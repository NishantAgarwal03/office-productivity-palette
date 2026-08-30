; ======================================================================================================================
; Module: Actions_Email.ahk - 10 Professional Email & Communication Templates
; ======================================================================================================================

#Requires AutoHotkey v2.0

RegisterEmailActions() {
    RegisterAction("Email: Please Find Attached (PFA)", "✉️ Email", "Inserts: Please find the requested file(s) attached for your review.", "pfa, attach, attachment, email, review", (*) => InsertText("Please find the requested file(s) attached for your review."))
    RegisterAction("Email: Acknowledgment & Follow-Up", "✉️ Email", "Inserts: Acknowledged with thanks. I am reviewing this and will update...", "ack, acknowledge, thanks, email, received", (*) => InsertText("Acknowledged with thanks. I am reviewing this and will update you shortly."))
    RegisterAction("Email: Meeting Availability Request", "✉️ Email", "Inserts: Could you please share your availability for a brief sync...", "meeting, sync, call, availability, schedule", (*) => InsertText("Could you please share your availability for a brief sync this week?"))
    RegisterAction("Email: Gentle Follow-Up / Reminder", "✉️ Email", "Inserts: Just following up on my previous note to check if there are any...", "followup, reminder, ping, gentle, status", (*) => InsertText("Just following up on my previous note to check if there are any updates on this."))
    RegisterAction("Email: Out of Office Notice", "✉️ Email", "Inserts professional out-of-office response template", "ooo, out of office, vacation, leave, away", (*) => InsertText("Thank you for your email. I am currently out of the office with limited access to email. I will respond to your message as soon as possible upon my return."))
    RegisterAction("Email: Formal Business Greeting", "✉️ Email", "Inserts: Dear [Name],", "greeting, dear, hello, salutation", (*) => InsertText("Dear [Name],`n`n"))
    RegisterAction("Email: Formal Sign-Off", "✉️ Email", "Inserts: Best regards, [Your Name] [Your Title]", "regards, signoff, closing, signature", (*) => InsertText("Best regards,`n`n[Your Name]`n[Your Title]"))
    RegisterAction("Email: Action Required Notice", "✉️ Email", "Inserts: ACTION REQUIRED: Please review and confirm by EOD.", "action, required, urgent, approve, eod", (*) => InsertText("ACTION REQUIRED: Please review and confirm by EOD."))
    RegisterAction("Email: Handover / Delegation Note", "✉️ Email", "Inserts: I am looping in [Name] who will assist you further...", "handover, loop, delegate, introduce", (*) => InsertText("I am looping in [Name] who will assist you further with this request."))
    RegisterAction("Email: Appreciation Note", "✉️ Email", "Inserts: Thank you for your prompt assistance and support on this matter.", "appreciation, thank you, gratitude, support", (*) => InsertText("Thank you for your prompt assistance and support on this matter."))
}
