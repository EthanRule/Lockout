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
		castBar = true,
        castBarX = 0,
        castBarY = -326,
		comps = {},
	},
}

local options = {
    name = "Lockout",
    handler = Lockout,
    type = "group",
    args = {
        castBar = {
            name = "Show Cast Bar",
            desc = "Enables / disables the Cast Bar",
            type = "toggle",
            set = "SetCastBar",
            get = "GetCastBar",
            order = 1,
        },
        castBarX = {
            name = "Cast Bar X",
            desc = "Set the X coordinate of the Cast Bar",
            type = "input",
            set = "SetCastBarX",
            get = "GetCastBarX",
            order = 2,
        },
        castBarY = {
            name = "Cast Bar Y",
            desc = "Set the Y coordinate of the Cast Bar",
            type = "input",
            set = "SetCastBarY",
            get = "GetCastBarY",
            order = 3,
        },
        castBarColor = {
            name = "Cast Bar Color",
            desc = "Set the color of the Cast Bar",
            type = "color",
            set = "SetCastBarColor",
            get = "GetCastBarColor",
            order = 4,
        },
        -- import = {
        --     name = "Import",
        --     desc = "Import a profile",
        --     type = "execute",
        --     func = "ImportProfile",
        --     order = 7,
        -- },
        -- export = {
        --     name = "Export",
        --     desc = "Export a profile",
        --     type = "execute",
        --     func = "ExportProfile",
        --     order = 8,
        -- }
    },
}

-- Mapping of interrupt spell IDs to class colors
local interruptSpellIdToClassColor = {
    [47528] = RAID_CLASS_COLORS["DEATHKNIGHT"],
    [183752] = RAID_CLASS_COLORS["DEMONHUNTER"],
    [96231] = RAID_CLASS_COLORS["PALADIN"],
    [106839] = RAID_CLASS_COLORS["DRUID"],
    [78675] = RAID_CLASS_COLORS["DRUID"],
    [106839] = RAID_CLASS_COLORS["DRUID"],
    [6552] = RAID_CLASS_COLORS["WARRIOR"],
    [119910] = RAID_CLASS_COLORS["WARLOCK"],
    [212619] = RAID_CLASS_COLORS["WARLOCK"],
    [57994] = RAID_CLASS_COLORS["SHAMAN"],
    [147362] = RAID_CLASS_COLORS["HUNTER"],
    [187707] = RAID_CLASS_COLORS["HUNTER"],
    [2139] = RAID_CLASS_COLORS["MAGE"],
    [1766] = RAID_CLASS_COLORS["ROGUE"],
    [116705] = RAID_CLASS_COLORS["MONK"],
    [351338] = RAID_CLASS_COLORS["EVOKER"],
}

Lockout.interruptMarks = Lockout.interruptMarks or {}


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

function Lockout:SlashCommand()
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function Lockout:SetCastBar(info)
	local pop = self.db.profile.castBar
	self.db.profile.castBar = not pop
    if self.db.profile.castBar then
        self.customCastBar:Show()
    else
        self.customCastBar:Hide()
    end
end

function Lockout:GetCastBar(info)
	return self.db.profile.castBar
end

function Lockout:SetCastBarX(info, value)
    self.db.profile.castBarX = tonumber(value)
    if self.db.profile.castBarX == nil then
        self.db.profile.castBarX = 0
    end
    self.customCastBar:SetPoint("CENTER", self.db.profile.castBarX, self.db.profile.castBarY)
end

function Lockout:GetCastBarX(info)
    return tostring(self.db.profile.castBarX)
end

function Lockout:SetCastBarY(info, value)
    self.db.profile.castBarY = tonumber(value)
    self.customCastBar:SetPoint("CENTER", self.db.profile.castBarX, self.db.profile.castBarY)
end

function Lockout:GetCastBarY(info)
    return tostring(self.db.profile.castBarY)
end

function Lockout:SetCastBarColor(info, r, g, b, a)
    self.db.profile.castBarColor = {r, g, b, a}
    self.customCastBar:SetStatusBarColor(r, g, b, a)
end

function Lockout:GetCastBarColor(info)
    local color = self.db.profile.castBarColor
    if color then
        return unpack(color)
    else
        return 0.8, 0.5, 1, 1  -- Default to purple if no color is set
    end
end

function Lockout:OnInitialize()
    print("Initializing")
    self.db = LibStub("AceDB-3.0"):New("LockoutDB", defaults, true)
    AC:RegisterOptionsTable("Lockout", options)
    self.optionsFrame = ACD:AddToBlizOptions("Lockout", "Lockout")

    -- Show or hide customCastBar depending on the initial value of the castBar option
    if self.db.profile.castBar then
        self.customCastBar:Show()
    else
        self.customCastBar:Hide()
    end
    -- Set the color of the cast bar
    local color = self.db.profile.castBarColor
    if color then
        self.customCastBar:SetStatusBarColor(unpack(color))
    end

    -- Set the point of the cast bar using the X and Y coordinates from the profile
    self.customCastBar:SetPoint("CENTER", self.db.profile.castBarX, self.db.profile.castBarY)
end

-- Create interrupt Mark
function CreateInterruptMark()
    print("Creating interrupt mark")
    local interruptMark = CreateFrame("Frame", nil, Lockout.customCastBar, "BackdropTemplate")
    interruptMark:SetSize(2, 15)
    interruptMark:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
    interruptMark:SetBackdropColor(1, 0, 0)
    interruptMark:SetAlpha(1.0)
    return interruptMark
end

function CreateInterruptIcon(interruptID)
    print("Creating interrupt icon")
    -- Check if interruptID is not nil
    if interruptID then
        print("Creating interrupt icon for ID: ", interruptID)
        -- Ensure the interrupt mark for this interruptID exists
        local interruptMark = Lockout.interruptMarks[interruptID]
        if not interruptMark then
            -- If it doesn't exist, create it and store it in the interruptMarks table
            print("Interrupt mark does not exist, creating new one")
            interruptMark = CreateInterruptMark()
            Lockout.interruptMarks[interruptID] = interruptMark
        else
            print("Interrupt mark already exists")
        end

        local spellIconPath = GetSpellTexture(interruptID)
        local iconTexture = interruptMark:CreateTexture(nil, "ARTWORK")
        iconTexture:SetSize(20, 20)  -- Set the size of the texture to 20x20
        iconTexture:SetPoint("CENTER", interruptMark, 0, 20)  -- Position the texture at the center of the interruptMark frame and move it up by 10px
        iconTexture:SetTexture(spellIconPath)
        iconTexture:SetAlpha(1.0)  -- Set the alpha of the texture to 1.0
    else
        -- Handle the case where interruptID is nil
        print("Error: interruptID is nil")
    end
end

-- Percent Text
Lockout.textFrame = CreateFrame("Frame", nil, Lockout.customCastBar)
Lockout.textFrame:SetSize(200, 17)
Lockout.textFrame:SetPoint("BOTTOM", Lockout.customCastBar, "TOP", 0, 2)
local text = Lockout.textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetAllPoints(Lockout.textFrame)

-- Create a frame to handle hiding and showing cast bar.
Lockout.combatFrame = CreateFrame("Frame")
Lockout.combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
Lockout.combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
Lockout.combatFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
Lockout.combatFrame:SetScript("OnEvent", function(self, event, ...)
    print("Handling event: " .. event)
    if event == "PLAYER_REGEN_ENABLED" then
        Lockout.background:Hide()
        for i, interruptMark in ipairs(Lockout.interruptMarks) do
            interruptMark:Hide()
        end
        Lockout.textFrame:Hide() -- Hide the percent text
    elseif event == "PLAYER_REGEN_DISABLED" then
        Lockout.background:Show()
        for i, interruptMark in ipairs(Lockout.interruptMarks) do
            interruptMark:Show()
        end
        Lockout.textFrame:Show() -- Show the percent text
    end
    if event == "ZONE_CHANGED_NEW_AREA" then
        -- Iterate over the table and reset the data for each interrupt mark
        for i, interruptMark in ipairs(Lockout.interruptMarks) do
            interruptMark:Hide()
        end    
    end
end)

-- Initially hide the background and each interruptMark if not in combat
if not InCombatLockdown() then
    Lockout.background:Hide()
    for i, interruptMark in ipairs(Lockout.interruptMarks) do
        interruptMark:Hide()
    end
end

-- Determine When a Spell is Interrupted
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local spellInterruptedTime, combatLogEventTime, interruptedUnit, interruptedStartTime, interruptedEndTime, interruptID, interruptSourceName
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
        local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
        if subEvent == "SPELL_INTERRUPT" and destGUID == UnitGUID("player") then
            combatLogEventTime = GetTime()
            interruptID = spellId
            interruptSourceName = sourceName
        end
    end

    if spellInterruptedTime and combatLogEventTime and math.abs(spellInterruptedTime - combatLogEventTime) < 0.01 then
        if interruptedUnit and interruptedStartTime and interruptedEndTime then
            local castTime = interruptedEndTime - interruptedStartTime
            local interruptedAt = spellInterruptedTime - interruptedStartTime
            local percentage = (interruptedAt / castTime) * 100
            local interruptMark = Lockout.interruptMarks[interruptID]
            print("Interrupt ID found when interrupted:", interruptID)
            if interruptID then
                if not interruptMark then
                    -- Create a new interruptMark if it doesn't exist
                    interruptMark = CreateInterruptIcon(interruptID)
                    print("Created Interrupt Icon")
                    Lockout.interruptMarks[interruptID] = interruptMark
                end
            
                Lockout.interruptMarks[interruptID]:SetPoint("LEFT", Lockout.customCastBar, "LEFT", Lockout.customCastBar:GetWidth() * (interruptedAt / castTime), 0)
            
                if color then
                    -- Set the color of the interruptMark
                    Lockout.interruptMarks[interruptID]:SetBackdropColor(color.r, color.g, color.b)
                end
            
                -- Show the interrupt mark
                Lockout.interruptMarks[interruptID]:Show()
            end
        end
        spellInterruptedTime = nil
        combatLogEventTime = nil
        interruptedUnit = nil
        interruptedStartTime = nil
        interruptedEndTime = nil
        interruptID = nil
    end
end)

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

-- Slash Commands
SLASH_LOCKOUT1 = "/lockout"
SlashCmdList["LOCKOUT"] = function(msg)
    Lockout:SlashCommand()
end

-- Profiles
function Lockout: ExportProfile()

end

function Lockout: ImportProfile()

end

