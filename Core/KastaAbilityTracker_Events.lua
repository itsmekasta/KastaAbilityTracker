-- =============================================================
-- KastaAbilityTracker_Events.lua
-- Slash command. Loaded last - depends on UI/KastaAbilityTracker_UI.lua.
-- =============================================================

SLASH_KASTAABILITYTRACKER1 = "/kat"
SlashCmdList["KASTAABILITYTRACKER"] = function()
    CreateKATMenu()
    if katMenu:IsShown() then
        katMenu:Hide()
    else
        katMenu:Show()
    end
end
