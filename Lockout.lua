local frame = CreateFrame("Frame", "MyCastBar", UIParent)
frame:SetSize(200, 20)
frame:SetPoint("CENTER", 0, 0)

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetColorTexture(0, 0, 0, 0.5)

local lastCastBar = frame:CreateTexture(nil, "ARTWORK")
lastCastBar:SetColorTexture(0, 1, 0, 0.8)
lastCastBar:SetPoint("LEFT", frame, "LEFT")
lastCastBar:SetHeight(20)

local currentCastBar = frame:CreateTexture(nil, "ARTWORK")
currentCastBar:SetColorTexture(1, 0, 0, 0.8)
currentCastBar:SetPoint("LEFT", lastCastBar, "RIGHT")
currentCastBar:SetHeight(20)

local interruptIndicator = frame:CreateTexture(nil, "OVERLAY")
interruptIndicator:SetColorTexture(0.5, 0, 0.5, 1) -- Purple color
interruptIndicator:SetSize(2, 20)

local druidIcon = frame:CreateTexture(nil, "OVERLAY")
local _, classFilename = UnitClass("player")
if classFilename == "DRUID" then
    local _, _, _, _, _, _, classID = GetSpecializationInfo(GetSpecialization())
    if classID == 11 then -- Druid class ID
        local _, _, _, icon = GetSpecializationInfoForClassID(11, 102) -- Balance specialization ID
        druidIcon:SetTexture(icon)
    else
        druidIcon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend")
    end
else
    druidIcon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend")
end
druidIcon:SetSize(20, 20) -- Adjust size as needed
druidIcon:SetPoint("LEFT", interruptIndicator, "CENTER", 0, 0) -- Position the icon relative to the interruptIndicator

local castStartTime = 0
local lastCastPercent = 0
local interruptPercent = 0
local maxCastTime = 1.7

local function UpdateCastBar()
    local castEndTime = GetTime()
    local castDuration = castEndTime - castStartTime
    lastCastPercent = castDuration / maxCastTime
    lastCastBar:SetWidth(frame:GetWidth() * lastCastPercent)
    currentCastBar:SetWidth(frame:GetWidth() * (1 - lastCastPercent))
    interruptIndicator:SetPoint("LEFT", frame, "LEFT", frame:GetWidth() * interruptPercent, 0)
    druidIcon:SetPoint("LEFT", interruptIndicator, "CENTER", 0, 0) -- Update icon position with the interruptIndicator
end

local function StartCast()
    local baseCastTime = 1.7 -- all spammable cc is 2 seconds. Chaosbolt?
    print("Base cast time" .. baseCastTime)
    local hastePercentage = UnitSpellHaste("player") / 100
    local adjustedCastTime = baseCastTime / (1 + hastePercentage)
    print("Adjusted cast time" .. adjustedCastTime)
    castStartTime = GetTime()
    maxCastTime = adjustedCastTime
    UpdateCastBar()
end

local function StopCast(interruptedByEnemy)
    if interruptedByEnemy then
        interruptPercent = lastCastPercent
        UpdateCastBar() -- Update the cast bar when interrupted by an enemy
    end
end

local function OnEvent(self, event, unit, spell, rank, lineID, spellID)
    if unit == "player" then
        if event == "UNIT_SPELLCAST_START" then
            StartCast()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- Check if the interruption was caused by an enemy
            local interruptedByEnemy = false
            if event == "UNIT_SPELLCAST_INTERRUPTED" then
                local target = UnitChannelInfo("player") or UnitCastingInfo("player")
                if target and UnitCanAttack("player", target) then
                    interruptedByEnemy = true
                end
            end
            StopCast(interruptedByEnemy)
        elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
            -- Interrupted by an enemy
            -- Call StopCast to update the cast bar
            StopCast(true)
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
frame:SetScript("OnEvent", OnEvent)
