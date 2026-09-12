; ======================================================================================================================
; Module: Actions_Workflow.ahk - Workflow Engine Initialization & Dynamic Recipe Registration
; Part of Office Productivity Hub (v2.0.1) - Workflow Composer Suite
;
; ARCHITECTURAL INVARIANTS:
; 1. Palette-Only Invocation: Strictly registered into the Command Palette without assigning global hotkeys.
; 2. Dynamic Recipe Registration: Automatically registers all validated saved recipes under category '🔄 Recipe'.
; 3. Non-Breaking & Symbiotic: Seamlessly integrates with BuiltInActions and PaletteGui without altering existing tools.
; ======================================================================================================================

#Requires AutoHotkey v2.0

InitWorkflowEngine() {
    try {
        ; Register primitives and adapters into ToolCatalog
        RegisterWorkflowPrimitives()
        RegisterBuiltinToolAdapters()

        ; Ensure default seed recipes exist in Recipes/ folder
        RecipeModel.EnsureDefaultSeedRecipes()

        ; Register Workflow Hub management actions
        RegisterAction("Workflow: Open Composer", "⚡ Workflow", 
                       "Visually design, test, and save multi-step automated recipes", 
                       "workflow, composer, builder, recipe, create, automate, chain, pipeline, edit, edit recipe, modify recipe, open recipe, load recipe", 
                       (*) => ShowWorkflowComposer())

        RegisterAction("Workflow: Edit Saved Recipe...", "⚡ Workflow", 
                       "Choose and open any saved workflow recipe in the visual composer", 
                       "workflow, edit, open, recipe, load, modify, composer", 
                       (*) => WcShowOpenRecipeModal())

        RegisterAction("Workflow: Run History & Diagnostics", "⚡ Workflow", 
                       "Inspect step-by-step execution snapshots, error logs, and rerun previous inputs", 
                       "workflow, history, logs, runs, inspect, debug, snapshot, ledger, error", 
                       (*) => ShowRunHistoryGui())

        ; Load and register saved recipes into palette under '🔄 Recipe'
        LoadAndRegisterSavedRecipes()

    } catch as err {
        if IsSet(LogAppError)
            LogAppError("InitWorkflowEngine", err)
    }
}

LoadAndRegisterSavedRecipes() {
    global BuiltInActions
    
    recipes := RecipeModel.ListAll()
    for r in recipes {
        valRes := RecipeModel.Validate(r)
        if (!valRes.valid)
            continue

        recipeName := r.HasOwnProp("name") ? r.name : r.id
        recipeDesc := r.HasOwnProp("description") ? r.description : "Workflow Recipe"
        keywords := "recipe, workflow, " . recipeName . ", " . r.id

        ; Closure capture of recipe definition
        RegisterAction("Recipe: " . recipeName, "🔄 Recipe", 
                       recipeDesc, keywords, 
                       ((savedRecipe) => (*) => PipelineRunner.Execute(savedRecipe))(r))
    }
}
