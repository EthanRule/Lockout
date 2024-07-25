local Lockout = LibStub("AceAddon-3.0"):NewAddon("Lockout", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local debugStatements = false

-- UI and database
local defaults = {
	profile = {
		message = "Welcome Home!",
		castBar = true,
        castBarX = 0,
        castBarY = -326,
        castBarWidth = 206,
        castBarHeight = 7,
        castBarColor = {0.8, 0.5, 1, 1},
	},
}

local options = {
    name = "Lockout",
    handler = Lockout,
    type = "group",
    args = {
        header = {
            order = 0,
            type = "description",
            name = "This is a cast bar overlay. Position the cast bar in the center of your default one.\n\n|cFFFFD700Author:|r Rudar",
        },
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
        castBarWidth = {
            name = "Cast Bar Width",
            desc = "Set the width of the Cast Bar",
            type = "input",
            set = "SetCastBarWidth",
            get = "GetCastBarWidth",
            order = 5,
        },
        castBarHeight = {
            name = "Cast Bar Height",
            desc = "Set the height of the Cast Bar",
            type = "input",
            set = "SetCastBarHeight",
            get = "GetCastBarHeight",
            order = 6,
        },
        -- reset = {
        --     name = "Reset to Defaults",
        --     desc = "Reset the settings to their default values",
        --     type = "execute",
        --     func = "ResetToDefaults",
        --     order = 7,
        -- },
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
    [47528] = RAID_CLASS_COLORS["DEATHKNIGHT"],   -- Mind Freeze
    [183752] = RAID_CLASS_COLORS["DEMONHUNTER"],  -- Disrupt
    [96231] = RAID_CLASS_COLORS["PALADIN"],       -- Rebuke
    [97547] = RAID_CLASS_COLORS["DRUID"],         -- Solar Beam        
    [106839] = RAID_CLASS_COLORS["DRUID"],        -- Skull Bash         
    [93985] = RAID_CLASS_COLORS["DRUID"],         -- Skull Bash (bear form)
    [6552] = RAID_CLASS_COLORS["WARRIOR"],        -- Pummel
    [132409] = RAID_CLASS_COLORS["WARLOCK"],      -- Spell Lock
    [19647] = RAID_CLASS_COLORS["WARLOCK"],       -- Spell Lock (felhunter)
    [212619] = RAID_CLASS_COLORS["WARLOCK"],      -- Call Felhunter         TODO: FIX, (Not working Showing red dash for class color)
    [347008] = RAID_CLASS_COLORS["WARLOCK"],       -- Axe Toss
    [57994] = RAID_CLASS_COLORS["SHAMAN"],        -- Wind Shear
    [147362] = RAID_CLASS_COLORS["HUNTER"],       -- Counter Shot
    [187707] = RAID_CLASS_COLORS["HUNTER"],       -- Muzzle
    [2139] = RAID_CLASS_COLORS["MAGE"],           -- Counterspell
    [1766] = RAID_CLASS_COLORS["ROGUE"],          -- Kick
    [116705] = RAID_CLASS_COLORS["MONK"],         -- Spear Hand Strike
    [351338] = RAID_CLASS_COLORS["EVOKER"],       -- Quell
}

local interruptCoolDowns = {
    [47528] = 15,   -- Mind Freeze
    [183752] = 15,  -- Disrupt
    [96231] = 15,   -- Rebuke
    [97547] = 45,   -- Solar Beam              
    [106839] = 15,  -- Skull Bash             
    [93985] = 15,   -- Skull Bash (bear form)
    [6552] = 14,    -- Pummel
    [132409] = 24,  -- Spell Lock
    [19647] = 24,   -- Spell Lock (felhunter)
    [212619] = 60,  -- Call Felhunter           TODO: FIX, (Not working Showing red dash for class color)
    [347008] = 30,   -- Axe Toss
    [57994] = 12,   -- Wind Shear
    [147362] = 24,  -- Counter Shot
    [187707] = 15,  -- Muzzle
    [2139] = 20,    -- Counterspell
    [1766] = 15,    -- Kick
    [116705] = 15,  -- Spear Hand Strike
    [351338] = 20,  -- Quell
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
    if debugStatements then
        print("Texture not found")
    end
end

function Lockout:UpdateCastBarColor()
    local isEmpty = true
    local allOnCooldown = true

    -- Check if the interruptMarks table is empty
    for _ in pairs(self.interruptMarks) do
        isEmpty = false
        break
    end

    -- Check if all interrupts are on cooldown
    for _, interruptMark in pairs(self.interruptMarks) do
        local remaining = max(0, interruptMark.start + interruptMark.duration - GetTime())
        if remaining <= 0 then
            allOnCooldown = false
            break
        end
    end

    -- Change the color of the cast bar based on the state of the interrupt table
    if isEmpty or allOnCooldown then
        self.customCastBar:SetStatusBarColor(1, 1, 0)  -- Set the color to yellow
    else
        self.customCastBar:SetStatusBarColor(0.8, 0.5, 1)  -- Set the color to purple
    end
end

function Lockout:SlashCommand()
    --InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) (broken needs fix for slash commands)
end

-- Setters & Getters

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

function Lockout:GetCastBarWidth(info)
    print("getting cast bar width:")
    print(tostring(self.db.profile.castBarWidth))
    return tostring(self.db.profile.castBarWidth)
end

function Lockout:SetCastBarWidth(info, value)
    self.db.profile.castBarWidth = tonumber(value)
    if self.db.profile.castBarWidth == nil then
        self.db.profile.castBarWidth = 206
    end
    self.customCastBar:SetSize(self.db.profile.castBarWidth, self.db.profile.castBarHeight)
end

function Lockout:GetCastBarHeight(info)
    return tostring(self.db.profile.castBarHeight)
end

function Lockout:SetCastBarHeight(info, value)
    self.db.profile.castBarHeight = tonumber(value)
    self.customCastBar:SetSize(self.db.profile.castBarWidth, self.db.profile.castBarHeight)
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

-- function Lockout:ResetToDefaults(info)
--     self.db.profile = {}
--     for k, v in pairs(defaults.profile) do
--         self.db.profile[k] = v
--     end
--     -- Update the UI elements to reflect the new settings
--     self.customCastBar:SetSize(self.db.profile.castBarWidth, self.db.profile.castBarHeight)
--     self.customCastBar:SetPoint("CENTER", self.db.profile.castBarX, self.db.profile.castBarY)
--     self.customCastBar:SetStatusBarColor(unpack(self.db.profile.castBarColor))
--     if self.db.profile.castBar then
--         self.customCastBar:Show()
--     else
--         self.customCastBar:Hide()
--     end
-- end

function Lockout:OnInitialize()
    if debugStatements then
        print("Initializing")
    end
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
    print("Setting X and Y coordinates")
    print("x:", self.db.profile.castBarX, "y:", self.db.profile.castBarY)
    self.customCastBar:SetPoint("CENTER", self.db.profile.castBarX, self.db.profile.castBarY)

    -- Set the size of the cast bar using the width and height from the profile
    print("Setting width and height")
    print("width:", self.db.profile.castBarWidth, "height:", self.db.profile.castBarHeight)
    self.customCastBar:SetSize(self.db.profile.castBarWidth, self.db.profile.castBarHeight)
end

-- Create interrupt Mark
function CreateInterruptMark(interruptID)
    if debugStatements then
        print("Creating interrupt mark")
    end
    local interruptMark = CreateFrame("Frame", nil, Lockout.customCastBar, "BackdropTemplate")
    interruptMark:SetSize(2, 15)
    interruptMark:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
    interruptMark:SetBackdropColor(1, 0, 0)
    interruptMark:SetAlpha(1.0)

    -- Add the icon texture
    local spellIconPath = GetSpellTexture(interruptID)
    if debugStatements then
        print("interruptID:", interruptID)
        print("spellIconPath:", spellIconPath)
    end
    local iconTexture = interruptMark:CreateTexture(nil, "BACKGROUND")  -- Change the draw layer to "BACKGROUND"
    iconTexture:SetSize(20, 20)  -- Set the size of the texture to 20x20
    iconTexture:SetPoint("CENTER", interruptMark, 0, 20)  -- Position the texture at the center of the interruptMark frame and move it up by 10px
    iconTexture:SetTexture(spellIconPath)
    iconTexture:SetAlpha(1.0)  -- Set the alpha of the texture to 1.0

    -- Create a cooldown frame
    local cooldown = CreateFrame("Cooldown", nil, interruptMark, "CooldownFrameTemplate")
    cooldown:SetAllPoints(iconTexture)  -- Make the cooldown frame cover the entire icon texture
    cooldown:SetDrawEdge(false)  -- Don't draw the edge of the cooldown frame
    cooldown:SetSwipeColor(0, 0, 0, 0.8)  -- Set the color of the cooldown swipe
    cooldown:SetHideCountdownNumbers(true)  -- Hide the countdown numbers

    interruptMark.cooldown = cooldown

    -- Get the cooldown of the spell from the interruptCoolDowns table
    local duration = interruptCoolDowns[interruptID]
    if debugStatements then
        print("Duration:", duration)
    end
    local start = 0  -- Initialize start to 0
    if duration and duration > 0 then
        -- Start the cooldown sweep
        start = GetTime()
        cooldown:SetCooldown(start, duration)
    end

    -- Get the spell name
    local spellName = GetSpellInfo(interruptID)
    interruptMark.spellName = spellName

    -- Forward declaration of ticker
    local ticker

    -- Create a ticker that prints the remaining cooldown and the spell name every 1 second
    ticker = C_Timer.NewTicker(1, function()
        local remaining = max(0, start + duration - GetTime())
        if debugStatements then
            print("Remaining cooldown for", spellName, ":", remaining)
        end
        if remaining <= 0 then
            ticker:Cancel()  -- Stop the ticker when the remaining cooldown is 0
        end
    end)

    interruptMark:Show()
    interruptMark:Raise()

    return interruptMark
end

function CreateInterruptIcon(interruptID, Lockout, interruptedAt, castTime, color)
    if debugStatements then
        print("Creating interrupt icon")
    end
    -- Check if interruptID is not nil
    if interruptID then
        if debugStatements then
            print("Creating interrupt icon for ID: ", interruptID)
        end
        -- Ensure the interrupt mark for this interruptID exists
        local interruptMark = Lockout.interruptMarks[interruptID]
        if not interruptMark then
            -- If it doesn't exist, create it and store it in the interruptMarks table
            if debugStatements then
                print("Interrupt mark does not exist, creating new one")
            end
            interruptMark = CreateInterruptMark(interruptID)
            Lockout.interruptMarks[interruptID] = interruptMark
        else
            if debugStatements then
                print("Interrupt mark already exists")
            end
        end

        -- Set the position of the interrupt mark
        interruptMark:SetPoint("LEFT", Lockout.customCastBar, "LEFT", Lockout.customCastBar:GetWidth() * (interruptedAt / castTime), 0)

        if color then
            -- Set the color of the interrupt mark
            interruptMark:SetBackdropColor(color.r, color.g, color.b)
            --UpdateCastBarColor(Lockout)
        end

        -- Show the interrupt mark
        interruptMark:Show()

        return interruptMark  -- Return the interrupt mark
    else
        -- Handle the case where interruptID is nil
        if debugStatements then
            print("Error: interruptID is nil")
        end
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
    if debugStatements then
        print("Handling event: " .. event)
    end
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
        for k in pairs(Lockout.interruptMarks) do
            Lockout.interruptMarks[k]:Hide()
            Lockout.interruptMarks[k] = nil
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
                    if table.getn(Lockout.interruptMarks) < 3 then
                        interruptMark = CreateInterruptIcon(interruptID, Lockout, interruptedAt, castTime, interruptSpellIdToClassColor[interruptID])
                        if debugStatements then
                            print("Created Interrupt Icon")
                        end
                        Lockout.interruptMarks[interruptID] = interruptMark
                    end
                else
                    -- Update the position of the existing interrupt mark
                    interruptMark:SetPoint("LEFT", Lockout.customCastBar, "LEFT", Lockout.customCastBar:GetWidth() * (interruptedAt / castTime), 0)
                    if debugStatements then
                        print("Updated Interrupt Icon Position")
                    end

                    -- Update the cooldown sweep
                    local duration = interruptCoolDowns[interruptID]
                    local start = 0
                    if duration and duration > 0 then
                        start = GetTime()
                        interruptMark.cooldown:SetCooldown(start, duration)
                    end
                
                    -- Cancel the existing ticker if it exists
                    if interruptMark.ticker then
                        interruptMark.ticker:Cancel()
                    end
                
                    -- Restart the ticker
                    interruptMark.ticker = C_Timer.NewTicker(1, function()
                        local remaining = max(0, start + duration - GetTime())
                        if debugStatements then
                            print("Remaining cooldown for", interruptMark.spellName, ":", remaining)
                        end
                        if remaining <= 0 then
                            interruptMark.ticker:Cancel()
                        end
                    end)
                end
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

