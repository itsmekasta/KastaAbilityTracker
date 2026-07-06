-- =============================================================
-- KastaAbilityTracker_DB.lua
-- SavedVariables defaults. GetKATDB() backfills any field missing from
-- an existing save (fresh install, or a field added in a later version)
-- BEFORE the options menu ever reads it - the same fix KastaCD needed
-- for its own "menu works for me, not for other users" bug (a nil
-- reaching an AceGUI widget's SetValue/SetChecked while the options
-- table is being built throws and aborts the whole menu silently).
-- =============================================================

local DEFAULTS = {
    iconSize      = 48,
    offsetX       = 0,
    offsetY       = 0,
    anchorLocked  = true,
    showBorder    = false,
}

function GetKATDB()
    if type(KastaAbilityTrackerDB) ~= "table" then
        KastaAbilityTrackerDB = {}
    end
    local db = KastaAbilityTrackerDB
    for key, default in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = default
        end
    end
    return db
end

-- Populate immediately so every other file can safely read
-- KastaAbilityTrackerDB.* from the moment it loads.
GetKATDB()