-- Create a frame to display the text
local textFrame = CreateFrame("Frame", nil, UIParent)
textFrame:SetSize(200, 100) -- Adjust size as needed
textFrame:SetPoint("CENTER", 0, -315) -- Move the frame 100 pixels down from the center of the screen
-- Create a FontString to display the text
local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetAllPoints(textFrame)

-- Create a frame to display the interrupt icon
local iconFrame = CreateFrame("Frame", nil, textFrame)
iconFrame:SetSize(20, 20) -- Adjust size as needed
iconFrame:SetPoint("LEFT", textFrame, "RIGHT", 10, 0) -- Position the icon to the right of the text frame

-- Set the texture of the interrupt icon
local iconTexture = iconFrame:CreateTexture(nil, "OVERLAY")
iconTexture:SetAllPoints(iconFrame)

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

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
            -- Set the texture to the interrupt spell icon
            iconTexture:SetTexture(GetSpellTexture(extraSpellID))
        end
    end

    if spellInterruptedTime and combatLogEventTime and math.abs(spellInterruptedTime - combatLogEventTime) < 0.01 then
        -- Reset the times
        if interruptedUnit and interruptedStartTime and interruptedEndTime then
            local castTime = interruptedEndTime - interruptedStartTime
            local interruptedAt = spellInterruptedTime - interruptedStartTime
            local percentage = (interruptedAt / castTime) * 100
            -- Display the percentage on the screen
            text:SetText(string.format("%.2f", percentage) .. "%")
        end
        spellInterruptedTime = nil
        combatLogEventTime = nil
        interruptedUnit = nil
        interruptedStartTime = nil
        interruptedEndTime = nil
    end
end)