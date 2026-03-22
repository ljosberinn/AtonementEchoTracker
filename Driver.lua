---@type string, AtonementEchoTracker
local addonName, Private = ...

local AtonementEchoTracker = {}

local enabledAuras = {
	[1468] = 194384, -- preservation: echo
	[256] = 194384, -- discipline: atonement
}

function AtonementEchoTracker:Init()
	self.contentType = Private.Enum.ContentType.OpenWorld
	self.specId = PlayerUtil.GetCurrentSpecID()
	self.auraId = enabledAuras[self.specId]
	self.activeInstances = {}

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	self:SetupFrame(true)
end

function AtonementEchoTracker:IsRelevantSpec()
	return self.specId == 1468 or self.specId == 256
end

function AtonementEchoTracker:OnListenerEvent(_, event, ...)
	self.frame:OnEvent(self, event, ...)
end

function AtonementEchoTracker:Enable()
	self.listenerFrames.party:RegisterUnitEvent("UNIT_AURA", "player")
	for i = 1, 4 do
		self.listenerFrames.party:RegisterUnitEvent("UNIT_AURA", "party" .. i)
		print("registered", "party" .. i)
	end

	for index, frame in ipairs(self.listenerFrames.raid) do
		for i = index, index + 4 do
			if i > 30 then
				break
			end

			frame:RegisterUnitEvent("UNIT_AURA", "raid" .. i)
			print("registered", "raid" .. i)
		end
	end
end

function AtonementEchoTracker:Disable()
	self.listenerFrames.party:UnregisterAllEvents()
	for _, frame in ipairs(self.listenerFrames.raid) do
		frame:UnregisterAllEvents()
	end
end

function AtonementEchoTracker:OnSettingsChanged(key, value) end

function AtonementEchoTracker:SetupFrame(isBoot)
	if isBoot then
		self.frame = CreateFrame("Cooldown", "AtonementEchoTracker", UIParent)
		self.frame.StackCount = self.frame:CreateFontString("StackCount", "OVERLAY")
		Private.EventRegistry:RegisterCallback(
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
			self.OnFrameEvent,
			self,
			self.frame,
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED
			-- the remaining args are being passed when the event gets triggered
		)

		self.listenerFrames = {
			party = CreateFrame("Frame", "AtonementEchoTrackerPartyListener", UIParent),
			raid = {},
		}

		local raidTokens = 30
		local perFrame = 4
		for i = 1, math.ceil(raidTokens / perFrame) do
			local frame = CreateFrame("Frame", "AtonementEchoTrackerRaidListener" .. i, UIParent)
			table.insert(self.listenerFrames.raid, frame)
		end

		Private.SetupEditMode(self.frame)
	else
		self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
		self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
		self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

		if self:IsRelevantSpec() then
			self:Enable()
		end

		self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
	end
end

function AtonementEchoTracker:UpdateDisplay()
	local activeCount = #self.activeInstances

	if activeCount == 0 then
		self.frame.StackCount:SetText(0)

		if AtonementEchoTrackerSaved.Settings.DefaultState == Private.Enum.DefaultState.Hidden then
			self.frame:Hide()
		else
			-- todo: desaturation
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
		self.frame:SetCooldownFromDurationObject(duration)
		self.frame.StackCount:SetText(activeCount)
		-- todo: clear desaturation
		self.frame:Show()
	end
end

function AtonementEchoTracker:OnFrameEvent(_, event, ...)
	if event == "UNIT_AURA" then
		---@type string, UnitAuraUpdateInfo
		local unit, updateInfo = ...

		print(unit, updateInfo ~= nil)

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
					return
				end
			end
		elseif updateInfo.updatedAuraInstanceIDs then
			local activeInstanceIndex = nil

			for i, auraInfo in ipairs(self.activeInstances) do
				if auraInfo.unit == unit then
					activeInstanceIndex = i
					break
				end
			end

			if activeInstanceIndex == nil then
				return
			end

			for _, auraInstanceId in ipairs(updateInfo.updatedAuraInstanceIDs) do
				if auraInstanceId == self.activeInstances[activeInstanceIndex].auraInstanceId then
					local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceId)

					if auraData ~= nil then
						print(
							"updating",
							unit,
							auraInstanceId,
							"to",
							auraData.expirationTime,
							"from",
							self.activeInstances[activeInstanceIndex].expirationTime
						)
						self.activeInstances[activeInstanceIndex].expirationTime = auraData.expirationTime
						self:UpdateDisplay()
					end

					return
				end
			end
		elseif updateInfo.removedAuraInstanceIDs then
			local activeInstanceIndex = nil

			for i, auraInfo in ipairs(self.activeInstances) do
				if auraInfo.unit == unit then
					activeInstanceIndex = i
					break
				end
			end

			if activeInstanceIndex == nil then
				return
			end

			for _, auraInstanceId in ipairs(updateInfo.removedAuraInstanceIDs) do
				if auraInstanceId == self.activeInstances[activeInstanceIndex].auraInstanceId then
					table.remove(self.activeInstances, activeInstanceIndex)
					self:UpdateDisplay()
					return
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
