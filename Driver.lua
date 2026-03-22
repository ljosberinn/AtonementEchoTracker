---@type string, AtonementEchoTracker
local addonName, Private = ...

local AtonementEchoTracker = {}

local enabledAuras = {
	[1468] = 364343, -- preservation: echo
	[256] = 194384, -- discipline: atonement
}

function AtonementEchoTracker:Init()
	self.contentType = Private.Enum.ContentType.OpenWorld
	self.specId = PlayerUtil.GetCurrentSpecID()
	self.auraId = enabledAuras[self.specId]
	self.activeInstances = {}

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	self.frame = CreateFrame("Frame", "AtonementEchoTracker", UIParent, "AtonementEchoTrackerTemplate")
	self.frame.Cooldown:SetUseAuraDisplayTime(true)
	self.frame:SetSize(AtonementEchoTrackerSaved.Settings.Width, AtonementEchoTrackerSaved.Settings.Height)
	self.frame:SetPoint("CENTER", UIParent, "CENTER")
	self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
	self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
	self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

	if AtonementEchoTrackerSaved.Settings.DefaultState == Private.Enum.DefaultState.Hidden then
		self.frame:Hide()
	else
		self.frame.Icon:SetDesaturated(true)
		self.frame:Show()
	end

	Private.EventRegistry:RegisterCallback(
		Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
		self.OnFrameEvent,
		self,
		self.frame,
		Private.Enum.Events.EDIT_MODE_POSITION_CHANGED
		-- the remaining args are being passed when the event gets triggered
	)

	self.listenerFrames = {
		party = {},
		raid = {},
	}

	local callback = GenerateClosure(self.OnListenerEvent, self)

	for i = 1, math.ceil(5 / 4) do
		local frame = CreateFrame("Frame", "AtonementEchoTrackerPartyListener" .. i, UIParent)
		frame:SetScript("OnEvent", callback)
		table.insert(self.listenerFrames.party, frame)
	end

	local perFrame = 4
	for i = 1, math.ceil(30 / perFrame) do
		local frame = CreateFrame("Frame", "AtonementEchoTrackerRaidListener" .. i, UIParent)
		frame:SetScript("OnEvent", callback)
		table.insert(self.listenerFrames.raid, frame)
	end

	Private.SetupEditMode(self.frame)

	if self:IsRelevantSpec() then
		self:Enable()
	end

	self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
end

function AtonementEchoTracker:IsRelevantSpec()
	return self.specId == 1468 or self.specId == 256
end

function AtonementEchoTracker:OnListenerEvent(_self, event, ...)
	self:OnFrameEvent(self, event, ...)
end

function AtonementEchoTracker:Enable()
	self:SetIcon()

	local partyTokens = {}
	for i = 1, 5 do
		local index = math.ceil(i / 4)
		if partyTokens[index] == nil then
			partyTokens[index] = {}
		end
		table.insert(partyTokens[index], i == 5 and "player" or "party" .. i)
	end

	for index, tokens in ipairs(partyTokens) do
		self.listenerFrames.party[index]:RegisterUnitEvent("UNIT_AURA", unpack(tokens))
	end

	local raidTokens = {}
	for i = 1, 30 do
		local index = math.ceil(i / 4)
		if raidTokens[index] == nil then
			raidTokens[index] = {}
		end
		table.insert(raidTokens[index], "raid" .. i)
	end

	for index, tokens in ipairs(raidTokens) do
		self.listenerFrames.raid[index]:RegisterUnitEvent("UNIT_AURA", unpack(tokens))
	end
end

function AtonementEchoTracker:Disable()
	for _, frame in ipairs(self.listenerFrames.party) do
		frame:UnregisterAllEvents()
	end

	for _, frame in ipairs(self.listenerFrames.raid) do
		frame:UnregisterAllEvents()
	end
end

function AtonementEchoTracker:OnSettingsChanged(key, value) end

function AtonementEchoTracker:UpdateDisplay()
	local activeCount = #self.activeInstances

	print("active count is", activeCount)

	if activeCount == 0 then
		self.frame.Cooldown.StackCount:SetText(0)
		self.frame.Cooldown:Clear()

		if AtonementEchoTrackerSaved.Settings.DefaultState == Private.Enum.DefaultState.Hidden then
			self.frame:Hide()
		else
			self.frame.Icon:SetDesaturated(true)
			self.frame:Show()
		end
	else
		local nextExpiry = nil

		for _, instance in ipairs(self.activeInstances) do
			if nextExpiry == nil or instance.expirationTime < nextExpiry then
				nextExpiry = instance.expirationTime
			end
		end

		local duration = C_DurationUtil.CreateDuration()
		duration:SetTimeFromEnd(nextExpiry, GetTime())
		self.frame.Cooldown:SetCooldownFromDurationObject(duration)
		self.frame.Cooldown.StackCount:SetText(activeCount)
		self.frame.Icon:SetDesaturated(false)
		self.frame:Show()
	end
end

function AtonementEchoTracker:SetIcon()
	self.frame.Icon:SetTexture(C_Spell.GetSpellTexture(self.auraId))
end

function AtonementEchoTracker:OnFrameEvent(a, event, ...)
	if event == "UNIT_AURA" then
		---@type string, UnitAuraUpdateInfo
		local unit, updateInfo = ...

		if updateInfo.isFullUpdate or updateInfo.addedAuras ~= nil then
			---@type AuraData[]
			local auras = updateInfo.addedAuras == nil and C_UnitAuras.GetUnitAuras(unit, "PLAYER|HELPFUL", nil)
				or updateInfo.addedAuras

			for _, aura in ipairs(auras) do
				if
					not issecretvalue(aura.sourceUnit)
					and aura.sourceUnit == "player"
					and aura.spellId == self.auraId
				then
					table.insert(self.activeInstances, {
						auraInstanceId = aura.auraInstanceID,
						expirationTime = aura.expirationTime,
						unit = unit,
					})
					self:UpdateDisplay()

					break
				end
			end
		end

		if updateInfo.updatedAuraInstanceIDs then
			local activeInstanceIndex = nil

			for i, auraInfo in ipairs(self.activeInstances) do
				if auraInfo.unit == unit then
					activeInstanceIndex = i

					break
				end
			end

			if activeInstanceIndex ~= nil then
				for _, auraInstanceId in ipairs(updateInfo.updatedAuraInstanceIDs) do
					if auraInstanceId == self.activeInstances[activeInstanceIndex].auraInstanceId then
						local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceId)

						if auraData ~= nil then
							self.activeInstances[activeInstanceIndex].expirationTime = auraData.expirationTime
							self:UpdateDisplay()
						end

						break
					end
				end
			end
		end

		if updateInfo.removedAuraInstanceIDs then
			local activeInstanceIndex = nil

			for i, auraInfo in ipairs(self.activeInstances) do
				if auraInfo.unit == unit then
					activeInstanceIndex = i
					break
				end
			end

			if activeInstanceIndex ~= nil then
				for _, auraInstanceId in ipairs(updateInfo.removedAuraInstanceIDs) do
					if auraInstanceId == self.activeInstances[activeInstanceIndex].auraInstanceId then
						table.remove(self.activeInstances, activeInstanceIndex)
						self:UpdateDisplay()

						break
					end
				end
			end
		end
	elseif event == "ENCOUNTER_END" then
		if IsInRaid() then
			table.wipe(self.activeInstances)
		end
	elseif
		event == "ZONE_CHANGED_NEW_AREA"
		or event == "LOADING_SCREEN_DISABLED"
		or event == "PLAYER_SPECIALIZATION_CHANGED"
		or event == "UPDATE_INSTANCE_INFO"
	then
		local _, instanceType, difficultyId = GetInstanceInfo()
		-- equivalent to `instanceType == "none"`
		local nextContentType = Private.Enum.ContentType.OpenWorld

		if instanceType == "raid" then
			nextContentType = Private.Enum.ContentType.Raid
		elseif instanceType == "party" then
			if
				difficultyId == DifficultyUtil.ID.DungeonTimewalker
				or difficultyId == DifficultyUtil.ID.DungeonNormal
				or difficultyId == DifficultyUtil.ID.DungeonHeroic
				or difficultyId == DifficultyUtil.ID.DungeonMythic
				or difficultyId == DifficultyUtil.ID.DungeonChallenge
				or difficultyId == 205 -- follower dungeons
			then
				nextContentType = Private.Enum.ContentType.Dungeon
			end
		elseif instanceType == "pvp" then
			nextContentType = Private.Enum.ContentType.Battleground
		elseif instanceType == "arena" then
			nextContentType = Private.Enum.ContentType.Arena
		elseif instanceType == "scenario" then
			if difficultyId == 208 then
				nextContentType = Private.Enum.ContentType.Delve
			end
		end

		self.contentType = nextContentType

		local specId = PlayerUtil.GetCurrentSpecID()

		if specId == self.specId then
			return
		end

		self.specId = specId
		self.auraId = enabledAuras[self.specId]

		if self:IsRelevantSpec() then
			self:Enable()
		else
			self:Disable()
		end
	elseif event == Private.Enum.Events.EDIT_MODE_POSITION_CHANGED then
		-- todo
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(AtonementEchoTracker.Init, AtonementEchoTracker))
