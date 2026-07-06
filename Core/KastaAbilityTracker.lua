-- =============================================================
-- KastaAbilityTracker.lua  –  Entry point
-- Shows a single icon for the last Hit Combo-qualifying ability the
-- player cast (Windwalker Monk), plus the current Hit Combo stack
-- count (0-6) - existing WeakAuras attempts at this only ever showed
-- one static icon and never actually refreshed per-cast, hence a
-- dedicated addon instead.
-- =============================================================

KASTAABILITYTRACKER_VERSION = "1.0.0"
KASTAABILITYTRACKER_NAME    = "KastaAbilityTracker"

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self)
    print("Thanks for using |cffff7f00[KastaAbilityTracker v" .. KASTAABILITYTRACKER_VERSION .. "]|r |cffffffffType |r|cff71d5ff/kat|r |cffffffffto open settings.|r")
    self:UnregisterAllEvents()
end)