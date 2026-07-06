-- =============================================================
-- KastaAbilityTracker_Events.lua
-- Slash command + ESC/Game Menu button injection (same pattern as
-- KastaUI_Events.lua). Loaded last - depends on
-- UI/KastaAbilityTracker_UI.lua.
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

-- =============================================================
-- ESC / Game Menu Button
-- =============================================================
local katGameMenuButtonInjected = false

local function InjectKATGameMenuButton()
    if katGameMenuButtonInjected then return end
    if not GameMenuFrame then return end
    katGameMenuButtonInjected = true

    local btnW = (GameMenuButtonHelp and GameMenuButtonHelp:GetWidth()) or 160
    local btnH = 30

    local w, h = GameMenuFrame:GetSize()
    GameMenuFrame:SetSize(w, h + btnH + 4)

    local point, relativeTo, relativePoint, x, y = GameMenuFrame:GetPoint(1)
    if point and y then
        GameMenuFrame:SetPoint(point, relativeTo, relativePoint, x, y + (btnH + 4))
    end

    local katBtn = CreateFrame("Button", "GameMenuButtonKastaAbilityTracker", GameMenuFrame, "GameMenuButtonTemplate")
    katBtn:SetSize(btnW, btnH)
    katBtn:SetFrameLevel(GameMenuFrame:GetFrameLevel() + 10)
    katBtn:EnableMouse(true)
    katBtn:SetToplevel(true)

    -- Stack above whichever Kasta addon (if any) already injected its
    -- own button first, instead of always anchoring straight to
    -- GameMenuButtonHelp - see KastaUI_Events.lua's own injection for
    -- the same shared _G.KASTA_GAMEMENU_LAST_BUTTON convention.
    local anchor = _G.KASTA_GAMEMENU_LAST_BUTTON or GameMenuButtonHelp
    if anchor then
        katBtn:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
    else
        katBtn:SetPoint("TOP", GameMenuFrame, "TOP", 0, -40)
    end
    _G.KASTA_GAMEMENU_LAST_BUTTON = katBtn

    katBtn:SetText("Kasta|cffff7f00AbilityTracker|r Options")
    katBtn:SetScript("OnClick", function()
        HideUIPanel(GameMenuFrame)
        CreateKATMenu()
        if katMenu:IsShown() then
            katMenu:Hide()
        else
            katMenu:Show()
        end
    end)
end

local escHookFrame = CreateFrame("Frame")
escHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
escHookFrame:SetScript("OnEvent", function(self)
    C_Timer.After(0, function()
        if GameMenuFrame then
            GameMenuFrame:HookScript("OnShow", InjectKATGameMenuButton)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)
end)