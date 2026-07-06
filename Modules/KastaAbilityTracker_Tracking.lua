-- =============================================================
-- KastaAbilityTracker_Tracking.lua
-- Watches the player's own combat log for a fixed set of Windwalker
-- Monk abilities and updates a single icon to show whichever one was
-- cast most recently.
--
-- Reverted: stack-count/timer overlay for the Hit Combo buff itself
-- (UnitBuff scanning + a Cooldown-swipe representing stacks toward 6)
-- was pulled back out entirely per explicit request, after it turned
-- out to be the actual cause of the icon going invisible (the swipe's
-- direction meant 0 stacks - the most common state - fully blacked out
-- the icon). Back to just the last-ability icon.
-- Depends on: KastaAbilityTracker_DB.lua
-- =============================================================

-- Legion 7.3.5 Windwalker Monk spell IDs - the standard, stable IDs
-- used since Mists/Legion (not server-specific data KastaCD already had
-- verified, since these are basic rotational abilities outside its own
-- tracked spell lists). If this private server remaps them, use
-- /katcast to find the real IDs actually logged and update
-- TRACKED_SPELLS below.
--
-- The "Yes/Generates/Benefits" abilities from the Hit Combo reference
-- table are all included below, EXCEPT Strike of the Windlord - that's
-- a Shadowlands Night Fae covenant ability that doesn't exist at all on
-- a Legion 7.3.5 client, so tracking its spellId would just never fire.
-- Touch of Death's ID (115080) is KastaCD's own already-server-verified
-- value (Core/KastaCD_SpellDB.lua), not guessed like the others.
--
-- Chi Wave (115098) isn't actually a Hit Combo-qualifying ability at
-- all (not on that reference table), but stays tracked anyway per an
-- earlier explicit request - this list is "abilities to show as my last
-- used ability", not strictly "abilities that count for Hit Combo".
--
-- Chi Wave and Crackling Jade Lightning both bounce/channel across
-- multiple targets after a single cast, generating their own
-- SPELL_HEAL/SPELL_DAMAGE combat log entries per bounce/tick - none of
-- those are SPELL_CAST_SUCCESS, so the combat log watcher below (which
-- only ever reacts to SPELL_CAST_SUCCESS, for every tracked spell, not
-- just these two) already updates the icon exactly once per cast
-- rather than flickering per bounce/tick.
TRACKED_SPELLS = {
    [100780] = "Tiger Palm",
    [100784] = "Blackout Kick",
    [107428] = "Rising Sun Kick",
    [113656] = "Fists of Fury",
    [101546] = "Spinning Crane Kick",
    [115098] = "Chi Wave",
    [117952] = "Crackling Jade Lightning",
    [101545] = "Flying Serpent Kick",
    [115080] = "Touch of Death",
}

local lastSpellId = nil
local iconFrame

-- =============================================================
-- Anchor - draggable positioning, same pattern as KastaCD's own
-- anchor frames (unlock to drag, saved position, offset sliders for
-- fine-tuning on top of a manual drag).
-- =============================================================
local function GetOrMakeIconFrame()
    if iconFrame then return iconFrame end

    local db = GetKATDB()

    local f = CreateFrame("Button", "KastaAbilityTrackerIcon", UIParent)
    f:SetSize(db.iconSize, db.iconSize)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not GetKATDB().anchorLocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db2 = GetKATDB()
        -- Must be CENTER-relative, matching how ApplyKATPosition always
        -- re-applies offsetX/offsetY (SetPoint("CENTER", UIParent,
        -- "CENTER", ...)).
        local esc = self:GetEffectiveScale()
        local usc = UIParent:GetEffectiveScale()
        local selfX, selfY = self:GetCenter()
        local uiX, uiY = UIParent:GetCenter()
        db2.offsetX = (selfX * esc - uiX * usc) / usc
        db2.offsetY = (selfY * esc - uiY * usc) / usc
    end)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Placeholder texture so the icon is always visibly populated with
    -- something from the moment it's created, instead of sitting empty
    -- until the first Hit Combo ability actually gets cast.
    tex:SetTexture((GetSpellTexture and GetSpellTexture(100780)) or 134400)
    f.tex = tex

    -- Unlocked-state highlight, matching KastaCD's anchor dot convention.
    local lockDot = f:CreateTexture(nil, "OVERLAY")
    lockDot:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
    lockDot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
    lockDot:SetColorTexture(1, 0.5, 0, 0.35)
    lockDot:Hide()
    f.lockDot = lockDot

    iconFrame = f
    return f
end

-- Icon border: full texcoord (0,1,0,1) shows the in-game border art;
-- cropped coords (0.08,0.92,...) hide it - same convention KastaCD uses.
function ApplyKATBorder()
    local db = GetKATDB()
    local f = GetOrMakeIconFrame()
    if db.showBorder then
        f.tex:SetTexCoord(0, 1, 0, 1)
    else
        f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

function ApplyKATPosition()
    local db = GetKATDB()
    local f = GetOrMakeIconFrame()
    -- Self-heal an offset saved by the older, buggy TOPLEFT-relative
    -- drag math - that could persist a value far outside any real
    -- screen, permanently placing the icon off-screen even after the
    -- drag math itself was fixed. Anything beyond a generous +/-2000px
    -- is treated as corrupt and reset to center.
    if math.abs(db.offsetX) > 2000 or math.abs(db.offsetY) > 2000 then
        db.offsetX, db.offsetY = 0, 0
    end
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", db.offsetX, db.offsetY)
end

function ApplyKATSize()
    local db = GetKATDB()
    local f = GetOrMakeIconFrame()
    f:SetSize(db.iconSize, db.iconSize)
end

function ApplyKATLockState()
    local db = GetKATDB()
    local f = GetOrMakeIconFrame()
    f.lockDot:SetShown(not db.anchorLocked)
end

function SetKATUnlocked(unlocked)
    GetKATDB().anchorLocked = not unlocked
    ApplyKATLockState()
end

-- =============================================================
-- Spec gate - the icon only ever means anything for Windwalker (Hit
-- Combo/these specific abilities aren't relevant to Brewmaster or
-- Mistweaver), so it's hidden entirely outside that spec instead of
-- sitting there showing a stale/irrelevant last ability.
-- =============================================================
local WINDWALKER_SPEC_ID = 269

local function IsWindwalker()
    local _, class = UnitClass("player")
    if class ~= "MONK" then return false end
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then return false end
    local specId = GetSpecializationInfo and GetSpecializationInfo(specIndex)
    return specId == WINDWALKER_SPEC_ID
end

function ApplyKATSpecVisibility()
    local f = GetOrMakeIconFrame()
    f:SetShown(IsWindwalker())
end

local function ApplyLastAbility(spellId)
    lastSpellId = spellId
    local f = GetOrMakeIconFrame()
    local tex = GetSpellTexture and GetSpellTexture(spellId)
    if tex then
        f.tex:SetTexture(tex)
        f.tex:Show()
    end
end

-- =============================================================
-- Combat log watcher
-- =============================================================
local combatLogFrame = CreateFrame("Frame")
combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatLogFrame:SetScript("OnEvent", function(self, event, ...)
    local subEvent, sourceGUID, spellId

    if CombatLogGetCurrentEventInfo then
        local _, se, _, sGUID, _, _, _, _, _, _, _, sId =
            CombatLogGetCurrentEventInfo()
        subEvent, sourceGUID, spellId = se, sGUID, sId
    end

    -- Fallback: some private-server clients pass combat log args
    -- directly via the event instead of through
    -- CombatLogGetCurrentEventInfo.
    if not subEvent then
        local _, se, _, sGUID, _, _, _, _, _, _, _, sId = ...
        subEvent, sourceGUID, spellId = se, sGUID, sId
    end

    if subEvent ~= "SPELL_CAST_SUCCESS" then return end
    if sourceGUID ~= UnitGUID("player") then return end
    if not spellId or not TRACKED_SPELLS[spellId] then return end

    ApplyLastAbility(spellId)
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
-- Fallback for private-server clients where PLAYER_SPECIALIZATION_CHANGED
-- doesn't fire reliably - same dual-event approach KastaCD uses for its
-- own spec-dependent gating.
pcall(function() eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE") end)
eventFrame:SetScript("OnEvent", function()
    ApplyKATPosition()
    ApplyKATSize()
    ApplyKATLockState()
    ApplyKATBorder()
    ApplyKATSpecVisibility()
end)

-- -------------------------------------------------------------
-- /katcast - dumps every SPELL_CAST_SUCCESS the player triggers
-- (spellId + name), regardless of TRACKED_SPELLS membership. Private
-- servers frequently remap spell IDs - this is the fastest way to
-- confirm the real IDs logged for Tiger Palm/Blackout Kick/Rising Sun
-- Kick/Fists of Fury/Spinning Crane Kick on this specific server if the
-- icon isn't updating.
-- -------------------------------------------------------------
local castLogFrame
SLASH_KATCAST1 = "/katcast"
SlashCmdList["KATCAST"] = function()
    if not castLogFrame then
        castLogFrame = CreateFrame("Frame")
        castLogFrame:SetScript("OnEvent", function(self, event, ...)
            local subEvent, sourceGUID, spellId, spellName

            if CombatLogGetCurrentEventInfo then
                local _, se, _, sGUID, _, _, _, _, _, _, _, sId, sName =
                    CombatLogGetCurrentEventInfo()
                subEvent, sourceGUID, spellId, spellName = se, sGUID, sId, sName
            end
            if not subEvent then
                local _, se, _, sGUID, _, _, _, _, _, _, _, sId, sName = ...
                subEvent, sourceGUID, spellId, spellName = se, sGUID, sId, sName
            end

            if subEvent == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") and spellId then
                print(string.format("|cffff7f00[KAT]|r cast log: [%d] %s", spellId, tostring(spellName)))
            end
        end)
    end

    if castLogFrame:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
        castLogFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        print("|cffff7f00[KAT]|r cast log OFF")
    else
        castLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        print("|cffff7f00[KAT]|r cast log ON - cast your Hit Combo abilities to confirm their real spell IDs.")
    end
end
