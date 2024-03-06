local Lockout = LibStub("AceAddon-3.0"):NewAddon("Lockout", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- UI and database
local defaults = {
	profile = {
		message = "Welcome Home!",
		castBarShow = true,
		comps = {},
	},
}

local options = {
	name = "Lockout",
	handler = Lockout,
	type = "group",
	args = {
		castBarShow = {
			name = "Show Cast Bar",
			desc = "Enables / disables the cast bar",
			type = "toggle",
			set = "SetPopUp",
			get = "GetPopUp",
			order = 1,
		},
	},
}

-- Create a custom casting bar
Lockout.customCastBar = CreateFrame("StatusBar", nil, UIParent)
Lockout.customCastBar:SetSize(206, 7)
Lockout.customCastBar:SetPoint("CENTER", 0, -326)
Lockout.customCastBar:SetFrameStrata("TOOLTIP")
Lockout.customCastBar:SetFrameLevel(100)
Lockout.customCastBar:SetMinMaxValues(0, 1)
Lockout.background = Lockout.customCastBar:CreateTexture(nil, "BACKGROUND")
Lockout.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
Lockout.background:SetAllPoints(Lockout.customCastBar)
Lockout.background:SetVertexColor(0, 0, 0, 0.25)
Lockout.customCastBar:Show()
local texture = LSM:Fetch("statusbar", "Interface\\TargetingFrame\\UI-StatusBar")
if texture then
    Lockout.customCastBar:SetStatusBarTexture(texture)
    Lockout.customCastBar:SetStatusBarColor(0.8, 0.5, 1)  -- Set the color to purple
else
    print("Texture not found")
end

Lockout.db = LibStub("AceDB-3.0"):New("LockoutDB", defaults, true)
local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(Lockout.db)


function Lockout:SlashCommand()
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function Lockout:OnInitialize()
    AC:RegisterOptionsTable("Lockout", options)
    self.optionsFrame = ACD:AddToBlizOptions("Lockout", "Lockout")
end

function Lockout:GetPopUp()
    return self.db.profile.castBarShow
end

function Lockout:SetPopUp(value)
    self.db.profile.castBarShow = value

    -- Show or hide customCastBar depending on the value of the popUp option
    if value then
        self.customCastBar:Show()
    else
        self.customCastBar:Hide()
    end
    ACR:NotifyChange("Lockout")
end

function Lockout:OnInitialize()
    AC:RegisterOptionsTable("Lockout", options)
    self.optionsFrame = ACD:AddToBlizOptions("Lockout", "Lockout")

    -- Show or hide customCastBar depending on the initial value of the popUp option
    if self.db.profile.castBarShow then
        self.customCastBar:Show()
    else
        self.customCastBar:Hide()
    end
end

-- Register the slash command
SLASH_LOCKOUT1 = "/lockout"

-- Define the function to be called when the slash command is used
SlashCmdList["LOCKOUT"] = function(msg)
    Lockout:SlashCommand()
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
textFrame:SetPoint("CENTER", 0, -314)
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
    Lockout.background:Hide()
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
            interruptMark:SetPoint("LEFT", customCastBar, "LEFT", Lockout.customCastBar:GetWidth() * (interruptedAt / castTime), 0)
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
        local timeOffset = 0.01  -- Adjust this value as needed
        Lockout.customCastBar:SetMinMaxValues(0, endTime - startTime)
        Lockout.customCastBar:SetValue((GetTime() + timeOffset) - startTime)
    else
        Lockout.customCastBar:SetValue(0)
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
Lockout.customCastBar:SetScript("OnUpdate", updateCustomCastBar)

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

-- GUI and Settings

