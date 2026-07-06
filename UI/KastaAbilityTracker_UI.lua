-- =============================================================
-- KastaAbilityTracker_UI.lua
-- Settings menu bootstrap - same pattern as KastaCD_UI.lua/KastaUI_UI.lua:
-- GetKATDB() (KastaAbilityTracker_DB.lua) already backfills every field
-- before this file ever builds the options table, so a fresh install or
-- an old save missing a newer field can never hand an AceGUI widget a
-- nil value mid-build and silently abort the whole menu - the exact
-- "menu works for me, not for other users" bug KastaCD hit once.
-- Depends on: KastaAbilityTracker_DB.lua, KastaAbilityTracker_Options.lua,
-- KastaAbilityTracker_libs.xml
-- =============================================================

katMenu = nil

local optionsRegistered = false
local function EnsureOptionsRegistered()
    if optionsRegistered then return end
    optionsRegistered = true

    GetKATDB()

    local AceConfig       = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    AceConfig:RegisterOptionsTable("KastaAbilityTracker", BuildKastaAbilityTrackerOptions())
    AceConfigDialog:SetDefaultSize("KastaAbilityTracker", 460, 420)
    AceConfigDialog:AddToBlizOptions("KastaAbilityTracker", "KastaAbilityTracker")
end

-- Rebuilds the registered options table and forces any open dialog to
-- re-render - needed after something changes a value the options table
-- itself doesn't own (e.g. "Reset Position" zeroing offsetX/offsetY),
-- so the sliders visually reflect it immediately. Same distinction
-- KastaCD/KastaUI's own options menus draw.
function NotifyKATOptionsChange()
    if not optionsRegistered then return end
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    AceConfigRegistry:NotifyChange("KastaAbilityTracker")
end

-- =============================================================
-- Compact chrome for the standalone dialog: a small top-right X instead
-- of AceGUI's stock bottom-right "Close" button + the dark statusbar
-- strip next to it (unused - this addon never sets status text).
--
-- IMPORTANT: this does NOT patch the shared AceGUIContainer-Frame.lua
-- widget file - that's exactly the mistake that once made a KastaCD
-- widget patch leak into every other addon's Ace3 dialogs (the vendored
-- "Frame" container is a pooled, version-raced singleton shared by
-- every addon that opens a standalone AceConfigDialog window, not a
-- per-addon copy). Instead, every time THIS addon's dialog is shown,
-- its own pooled widget instance is reached from the outside and
-- customized directly, and - critically - restored back to stock
-- appearance the moment it's hidden, so if AceGUI later recycles that
-- same physical frame for a completely different addon's dialog, that
-- addon still sees the normal, unmodified chrome.
-- =============================================================
local function FindFrameChromeButtons(frame)
    local close, statusbg
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.GetObjectType and child:GetObjectType() == "Button" then
            if child.GetText and child:GetText() == CLOSE then
                close = child
            elseif not statusbg then
                statusbg = child
            end
        end
    end
    return close, statusbg
end

local function ApplyCompactChrome(widget)
    local frame = widget.frame
    local close, statusbg = FindFrameChromeButtons(frame)
    if close then close:Hide() end
    if statusbg then statusbg:Hide() end

    if not frame.katCloseButton then
        local x = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        x:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -6)
        frame.katCloseButton = x
    end
    frame.katCloseButton:Show()
    frame.katCloseButton:SetScript("OnClick", function() widget:Hide() end)

    if not frame.katChromeHookInstalled then
        frame.katChromeHookInstalled = true
        frame:HookScript("OnHide", function(self)
            local c, s = FindFrameChromeButtons(self)
            if c then c:Show() end
            if s then s:Show() end
            if self.katCloseButton then self.katCloseButton:Hide() end
        end)
    end
end

function CreateKATMenu()
    if katMenu then return end

    EnsureOptionsRegistered()

    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    -- Thin shim over AceConfigDialog's Open/Close API rather than
    -- holding a raw widget reference - see KastaCD_UI.lua's
    -- CreateKastaCDMenu for why (the standalone frame widget gets
    -- released back into a shared pool on hide, so a held reference
    -- isn't safe across repeated show/hide cycles).
    katMenu = {
        IsShown = function() return AceConfigDialog.OpenFrames["KastaAbilityTracker"] ~= nil end,
        Show = function()
            AceConfigDialog:Open("KastaAbilityTracker")
            local widget = AceConfigDialog.OpenFrames["KastaAbilityTracker"]
            if widget then ApplyCompactChrome(widget) end
        end,
        Hide = function() AceConfigDialog:Close("KastaAbilityTracker") end,
    }
end

-- Registers the options table (and the Interface Options AddOns-list
-- entry) immediately, so the category exists even if /kat is never typed.
EnsureOptionsRegistered()