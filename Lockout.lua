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
        local _, subEvent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if subEvent == "SPELL_INTERRUPT" and destGUID == UnitGUID("player") then
            combatLogEventTime = GetTime()
        end
    end

    if spellInterruptedTime and combatLogEventTime and math.abs(spellInterruptedTime - combatLogEventTime) < 0.01 then
        print("UNIT_SPELLCAST_INTERRUPTED and COMBAT_LOG_EVENT_UNFILTERED happened at the same time")
        -- Reset the times
        if interruptedUnit and interruptedStartTime and interruptedEndTime then
            local castTime = interruptedEndTime - interruptedStartTime
            local interruptedAt = spellInterruptedTime - interruptedStartTime
            local percentage = (interruptedAt / castTime) * 100
            print("You were interrupted at " .. percentage .. "% of your cast.")
        end
        spellInterruptedTime = nil
        combatLogEventTime = nil
        interruptedUnit = nil
        interruptedStartTime = nil
        interruptedEndTime = nil
    end
end)

local castbarFrame = CreateFrame("Frame")
castbarFrame:RegisterEvent("PLAYER_LOGIN")

castbarFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Access the player's casting bar
        local castingBar = PlayerFrame.CastingBar

        -- Change the size of the cast bar
        castingBar:SetSize(300, 30)

        -- Change the position of the cast bar
        castingBar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

        -- Change the texture of the cast bar
        castingBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")

        -- Change the color of the cast bar
        castingBar:SetStatusBarColor(0, 0.65, 1)

        -- Change the font of the cast bar's text
        castingBar.Text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    end
end)

-- have a gradient of where somebody kicked last
-- --------------- . o O o . --