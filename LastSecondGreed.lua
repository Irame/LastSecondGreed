
local LSG = select(2, ...)
LSG = LibStub("AceAddon-3.0"):NewAddon(LSG, "LastSecondGreed", "AceEvent-3.0", "AceConsole-3.0")

--local L = LibStub("AceLocale-3.0"):GetLocale("LastSecondGreed") -- loads the localization table

local savedDBDefaults = {
    profile = {
        enabled = true,
        rollType = 2
    },
}

local scanFrame
local scanList
local toConfirm

function LSG:OnInitialize()
    self.db = LibStub:GetLibrary("AceDB-3.0"):New("LastSecondGreedDB", savedDBDefaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    self.profile = self.db.profile

    self:RegisterChatCommand("lsg", "ChatCommand")
    self:RegisterChatCommand("lastsecondgreed", "ChatCommand")

    scanFrame = CreateFrame("Frame")
    scanFrame:Hide()
    scanFrame:SetScript("OnUpdate", function(self)
        for id, _ in pairs(scanList) do
            local timeLeft = GetLootRollTimeLeft(id)
            if timeLeft < 1000 then
                local bindOnPickUp, canNeed, canGreed, canDisenchant = select(5, GetLootRollItemInfo(id));
                local rollType
                if (canDisenchant and LSG.profile.rollType == 3) then
                    rollType = 3
                elseif canGreed then
                    rollType = 2
                end
                if rollType then
                    if bindOnPickUp or rollType == 3 then
                        toConfirm[id] = rollType
                    end
                    RollOnLoot(id, rollType)
                    scanList[id] = nil
                end
            end
        end
        for _, _ in pairs(scanList) do
            return
        end
        self:Hide()
    end)

    scanList = {}
    toConfirm = {}
end

function LSG:OnProfileChanged(event, database, newProfileKey)
    self.profile = database.profile
end

function LSG:ChatCommand(oInput)
    if oInput == "dis" or oInput == "disenchant" then
        self.profile.rollType = 3
        self:Print("Rolling 'Disenchant' if possible.")
    elseif oInput == "gre" or oInput == "greed" then
        self.profile.rollType = 2
        self:Print("Rolling 'Greed'.")
    elseif oInput == "enable" or oInput == "on" then
        self.profile.enabled = true
        self:Enable()
    elseif oInput == "disable" or oInput == "off" then
        self.profile.enabled = false
        self:Disable()
    else
        self:PrintHelp()
    end
end

function LSG:PrintHelp()
    self:Print("Usage:")
    print("  /lsg <on|enable>   (Enable LastSecondGreed)")
    print("  /lsg <off|disable>   (Disable LastSecondGreed)")
    print("  /lsg <dis|disenchant>   (Roll 'Disenchant' if possible)")
    print("  /lsg <gre|greed>   (Roll 'Greed')")
end

function LSG:OnEnable()
    if not self.profile.enabled then
        self:Disable()
        return
    end

    self:RegisterEvent("START_LOOT_ROLL")
    self:RegisterEvent("CONFIRM_LOOT_ROLL")

    self:Print("Enabled")
end

function LSG:OnDisable()
    self:UnregisterEvent("START_LOOT_ROLL")
    self:UnregisterEvent("CONFIRM_LOOT_ROLL")

    self:Print("Disabled")
end

function LSG:START_LOOT_ROLL(event, id, time)
    scanList[id] = time
    scanFrame:Show()
end

function LSG:CONFIRM_LOOT_ROLL(event, id, rollType)
    if toConfirm[id] == rollType then
        ConfirmLootRoll(id, rollType)
        toConfirm[id] = nil
    end
end
