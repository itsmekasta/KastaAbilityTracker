-- =============================================================
-- KastaAbilityTracker_Options.lua
-- AceConfig-3.0 options table for the /kat settings menu - one flat
-- window, no tabs/categories, since this is a small single-purpose
-- addon. Depends on KastaAbilityTracker_DB.lua and the tracking
-- module's exposed Apply*/SetKATUnlocked globals.
-- =============================================================

function BuildKastaAbilityTrackerOptions()
    local args = {
        unlocked = {
            type = "toggle", order = 2, name = "Unlock to Drag", width = "full",
            desc = "While unlocked, click and drag the icon to reposition it. Turning this back off locks it where you dropped it.",
            get = function() return not GetKATDB().anchorLocked end,
            set = function(_, v) SetKATUnlocked(v) end,
        },
        showBorder = {
            type = "toggle", order = 3, name = "Icon Border", width = "full",
            desc = "Shows the in-game icon border art instead of a cropped, borderless icon.",
            get = function() return GetKATDB().showBorder end,
            set = function(_, v)
                GetKATDB().showBorder = v and true or false
                if type(ApplyKATBorder) == "function" then ApplyKATBorder() end
            end,
        },

        positionHeader = { type = "header", order = 10, name = "Position & Size" },
        iconSize = {
            type = "range", order = 20, name = "Icon Size", min = 16, max = 96, step = 1,
            get = function() return GetKATDB().iconSize end,
            set = function(_, v)
                GetKATDB().iconSize = v
                if type(ApplyKATSize) == "function" then ApplyKATSize() end
            end,
        },
        offsetX = {
            type = "range", order = 30, name = "Offset X", min = -1000, max = 1000, step = 1,
            get = function() return GetKATDB().offsetX end,
            set = function(_, v)
                GetKATDB().offsetX = v
                if type(ApplyKATPosition) == "function" then ApplyKATPosition() end
            end,
        },
        offsetY = {
            type = "range", order = 40, name = "Offset Y", min = -1000, max = 1000, step = 1,
            get = function() return GetKATDB().offsetY end,
            set = function(_, v)
                GetKATDB().offsetY = v
                if type(ApplyKATPosition) == "function" then ApplyKATPosition() end
            end,
        },
        resetBtn = {
            type = "execute", order = 50, name = "Reset Position", width = "full",
            func = function()
                local db = GetKATDB()
                db.offsetX, db.offsetY = 0, 0
                if type(ApplyKATPosition) == "function" then ApplyKATPosition() end
                if type(NotifyKATOptionsChange) == "function" then NotifyKATOptionsChange() end
            end,
        },
    }

    return { type = "group", name = "KastaAbilityTracker", args = args }
end
