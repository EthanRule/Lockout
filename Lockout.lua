local LSM = LibStub("LibSharedMedia-3.0")

local LSM = LibStub("LibSharedMedia-3.0")

-- Create a custom casting bar
local customCastBar = CreateFrame("StatusBar", nil, UIParent)
customCastBar:SetSize(206, 7)
customCastBar:SetPoint("CENTER", 0, -326)
customCastBar:SetFrameStrata("TOOLTIP")
customCastBar:SetFrameLevel(100)
customCastBar:SetMinMaxValues(0, 1)
local background = customCastBar:CreateTexture(nil, "BACKGROUND")
background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
background:SetAllPoints(customCastBar)
background:SetVertexColor(0, 0, 0, 0.25)
customCastBar:Show()
local texture = LSM:Fetch("statusbar", "Interface\\TargetingFrame\\UI-StatusBar")
if texture then
    customCastBar:SetStatusBarTexture(texture)
    customCastBar:SetStatusBarColor(0.8, 0.5, 1)  -- Set the color to purple
else
    print("Texture not found")
end


-- Create interrupt Mark
local interruptMark = CreateFrame("Frame", nil, customCastBar, "BackdropTemplate")
interruptMark:SetSize(2, 15)
interruptMark:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
interruptMark:SetBackdropColor(1, 0, 0)
interruptMark:SetAlpha(0.5)

-- idk what this is used for lol
local textFrame = CreateFrame("Frame", nil, UIParent)
textFrame:SetSize(200, 100)
textFrame:SetPoint("CENTER", 0, -315)
local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetAllPoints(textFrame)

-- Create a frame to handle hiding and showing cast bar.
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        background:Hide()
        interruptMark:Hide()
    elseif event == "PLAYER_REGEN_DISABLED" then
        background:Show()
        interruptMark:Show()
    end
end)

-- Initially hide the background and interruptMark if not in combat
if not InCombatLockdown() then
    background:Hide()
    interruptMark:Hide()
end

-- Frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Script to determine if you were interrupted by an enemy spell, and when
local spellInterruptedTime, combatLogEventTime, interruptedUnit, interruptedStartTime, interruptedEndTime
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit = ...
        if unit == "player" then
            spellInterruptedTime = GetTime()
            interruptedUnit = unit
            local name, _, _, startTime, endTime = UnitCastingInfo(unit)
            if name then
                interruptedStartTime = startTime / 1000
                interruptedEndTime = endTime / 1000
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID, _, _, _, _, _, _, _, extraSpellID = CombatLogGetCurrentEventInfo()
        if subEvent == "SPELL_INTERRUPT" and destGUID == UnitGUID("player") then
            combatLogEventTime = GetTime()
        end
    end

    if spellInterruptedTime and combatLogEventTime and math.abs(spellInterruptedTime - combatLogEventTime) < 0.01 then
        if interruptedUnit and interruptedStartTime and interruptedEndTime then
            local castTime = interruptedEndTime - interruptedStartTime
            local interruptedAt = spellInterruptedTime - interruptedStartTime
            local percentage = (interruptedAt / castTime) * 100
            text:SetText(string.format("%.2f", percentage) .. "%")
            interruptMark:SetPoint("LEFT", customCastBar, "LEFT", customCastBar:GetWidth() * (interruptedAt / castTime), 0)
            interruptMark:Show()
        end
        spellInterruptedTime = nil
        combatLogEventTime = nil
        interruptedUnit = nil
        interruptedStartTime = nil
        interruptedEndTime = nil
    end
end)

-- Update the custom casting bar when a spell starts or stops casting
local function updateCustomCastBar()
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")
    if name then
        startTime = startTime / 1000
        endTime = endTime / 1000

        -- Add a small offset to the time to compensate for frame lag
        local timeOffset = 0.02  -- Adjust this value as needed
        customCastBar:SetMinMaxValues(0, endTime - startTime)
        customCastBar:SetValue((GetTime() + timeOffset) - startTime)
    else
        customCastBar:SetValue(0)
    end
end

-- Create a frame to handle cast bar events
local castFrameEvents = CreateFrame("Frame")
castFrameEvents:RegisterEvent("UNIT_SPELLCAST_START")
castFrameEvents:RegisterEvent("UNIT_SPELLCAST_STOP")
castFrameEvents:SetScript("OnEvent", function(self, event, ...)
    updateCustomCastBar()
end)

-- Update the custom casting bar every frame
customCastBar:SetScript("OnUpdate", updateCustomCastBar)

-- -- interrupt icon code --
-- local iconFrame = CreateFrame("Frame", nil, textFrame)
-- iconFrame:SetSize(20, 20)
-- iconFrame:SetPoint("LEFT", textFrame, "RIGHT", 10, 0)
-- local iconTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
-- local spellID = 1766
-- local _, _, spellIcon = GetSpellInfo(spellID)
-- iconTexture:SetTexture(spellIcon)
-- iconTexture:SetAllPoints(iconFrame)
-- Create a frame to display the interrupt icon
-- local iconFrame = CreateFrame("Frame", nil, textFrame)
-- iconFrame:SetSize(20, 20) -- Adjust size as needed
-- iconFrame:SetPoint("LEFT", textFrame, "RIGHT", 10, 0) -- Position the icon to the right of the text frame

-- -- Set the texture of the interrupt icon
-- local iconTexture = iconFrame:CreateTexture(nil, "OVERLAY")
-- iconTexture:SetAllPoints(iconFrame)
