; ======================================================================================================================
; Module: Actions_WindowPeek.ahk - Window Peek & X-Ray Action Palette Registrations
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

#Include WindowPeekEngine.ahk

RegisterWindowPeekActions() {
    RegisterAction("Toggle Window Peek (CapsLock+Tab)", "⚙️ Utility", "[Toggle] Hold CapsLock+Tab to Peek Previous Window, Release to Return", "peek, glance, window, switch, previous, toggle, tab, capslock", (*) => ToggleWindowPeek(), "", "CapsLock+Tab")
    RegisterAction("X-Ray Layer Peek (Step-Down Transparency)", "⚙️ Utility", "[Hold] CapsLock+Esc ghosts top window; Down Arrow slices deeper layers", "xray, layer, transparent, ghost, peek, see through, slice, depth", (*) => StartXRayLayerPeek(), "", "CapsLock+Esc")
    RegisterAction("Configure X-Ray Layer Transparency...", "⚙️ Utility", "Set and persist custom opacity % for X-Ray Layer Peek", "xray, opacity, transparent, configure, settings, alpha, percent", (*) => ConfigureXRayTransparency())
}