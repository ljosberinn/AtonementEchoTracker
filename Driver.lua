---@type string, AtonementEchoTracker
local addonName, Private = ...

local LibEditMode = LibStub("LibEditMode")
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

---@class Driver
local AtonementEchoTracker = {}

local enabledAuras = {
	[1468] = { [364343] = true }, -- preservation: echo
	[256] = { [194384] = true }, -- discipline: atonement
	[105] = { [774] = true, [155777] = true }, -- restoration: rejuvenation (primary icon), germination
	[270] = { [119611] = true }, -- misteweaver: renewing mist
}

function AtonementEchoTracker:Init()
	self.specId = PlayerUtil.GetCurrentSpecID()
	self.auraIds = enabledAuras[self.specId]
	self.activeInstances = {}

	Private.EventRegistry:RegisterCallback(Private.Enum.Events.SETTING_CHANGED, self.OnSettingsChanged, self)

	---@type AtonementEchoTrackerFrame
	self.frame = CreateFrame("Frame", "AtonementEchoTracker", UIParent, "AtonementEchoTrackerTemplate")
	self.frame.Cooldown:SetUseAuraDisplayTime(true)
	self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
	self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self.frame:RegisterEvent("LOADING_SCREEN_DISABLED")
	self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
	self.frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

	self:ApplySettings()
	self:UpdateDisplay()

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

	LibEditMode:RegisterCallback("enter", function()
		if self.auraIds then
			local firstAuraId = next(self.auraIds)
			self.frame.Icon:SetTexture(C_Spell.GetSpellTexture(firstAuraId))
		end

		self:UpdateDisplay()
	end)

	LibEditMode:RegisterCallback("exit", function()
		if not self:LoadConditionsProhibitExecution() then
			self:UpdateDisplay()
		else
			self.frame:Hide()
		end
	end)

	self:UpdateContentType()

	if not self:LoadConditionsProhibitExecution() then
		self:Enable()
	end

	self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
end

function AtonementEchoTracker:UpdateContentType()
	local _, instanceType, difficultyId = GetInstanceInfo()
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
end

function AtonementEchoTracker:LoadConditionsProhibitExecution()
	if self.auraIds == nil then
		return true
	end

	if not AtonementEchoTrackerSaved.Settings.LoadConditionContentType[self.contentType] then
		return true
	end

	return false
end

function AtonementEchoTracker:OnListenerEvent(_self, event, ...)
	self:OnFrameEvent(self, event, ...)
end

function AtonementEchoTracker:Enable()
	table.wipe(self.activeInstances)
	self:UpdateDisplay()
	self.frame.Icon:SetTexture(C_Spell.GetSpellTexture(next(self.auraIds)))

	self:RegisterRaidEvents()

	if not IsInRaid() then
		self:RegisterPartyEvents()
	end

	if AtonementEchoTrackerSaved.Settings.CombatOnly then
		self:RegisterCombatEvents()
	end
end

function AtonementEchoTracker:RegisterPartyEvents()
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
end

function AtonementEchoTracker:UnregisterPartyEvents()
	for _, frame in ipairs(self.listenerFrames.party) do
		frame:UnregisterEvent("UNIT_AURA")
	end
end

function AtonementEchoTracker:RegisterRaidEvents()
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
	table.wipe(self.activeInstances)

	for _, frame in ipairs(self.listenerFrames.party) do
		frame:UnregisterAllEvents()
	end

	for _, frame in ipairs(self.listenerFrames.raid) do
		frame:UnregisterAllEvents()
	end

	self:UnregisterCombatEvents()

	if not LibEditMode:IsInEditMode() then
		self.frame:Hide()
	end
end

function AtonementEchoTracker:RegisterCombatEvents()
	self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function AtonementEchoTracker:UnregisterCombatEvents()
	self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function AtonementEchoTracker:ApplyPosition()
	self.frame:ClearAllPoints()
	PixelUtil.SetPoint(
		self.frame,
		AtonementEchoTrackerSaved.Settings.Position.point,
		UIParent,
		AtonementEchoTrackerSaved.Settings.Position.point,
		AtonementEchoTrackerSaved.Settings.Position.x,
		AtonementEchoTrackerSaved.Settings.Position.y
	)
end

function AtonementEchoTracker:ApplySize()
	local width = AtonementEchoTrackerSaved.Settings.Width
	local height = AtonementEchoTrackerSaved.Settings.Height

	self.frame:SetSize(width, height)

	self.frame.Overlay:ClearAllPoints()
	PixelUtil.SetPoint(self.frame.Overlay, "TOPLEFT", self.frame, "TOPLEFT", -(0.15 * width), 0.15 * width)
	PixelUtil.SetPoint(self.frame.Overlay, "BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0.15 * height, -(0.15 * height))
end

function AtonementEchoTracker:ApplyOpacity()
	self.frame:SetAlpha(AtonementEchoTrackerSaved.Settings.Opacity)
end

function AtonementEchoTracker:ApplyIconZoom()
	local zoom = AtonementEchoTrackerSaved.Settings.IconZoom
	self.frame.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
end

function AtonementEchoTracker:BuildFontFlags()
	local flags = {}

	if AtonementEchoTrackerSaved.Settings.FontFlags[Private.Enum.FontFlags.OUTLINE] then
		table.insert(flags, Private.Enum.FontFlags.OUTLINE)
	end

	if AtonementEchoTrackerSaved.Settings.FontFlags[Private.Enum.FontFlags.SHADOW] then
		table.insert(flags, Private.Enum.FontFlags.SHADOW)
	end

	return table.concat(flags, ",")
end

function AtonementEchoTracker:ApplyStackFont()
	self.frame.Cooldown.StackCount:SetFont(
		AtonementEchoTrackerSaved.Settings.Font,
		AtonementEchoTrackerSaved.Settings.StackFontSize,
		self:BuildFontFlags()
	)
end

function AtonementEchoTracker:ApplyDurationFont()
	local font = AtonementEchoTrackerSaved.Settings.Font
	local size = AtonementEchoTrackerSaved.Settings.DurationFontSize
	local flags = self:BuildFontFlags()

	self.frame.Cooldown.DurationText:SetFont(font, size, flags)
	self.frame.Cooldown:GetCountdownFontString():SetFont(font, size, flags)
end

function AtonementEchoTracker:ApplyStackColor()
	self.frame.Cooldown.StackCount:SetTextColor(
		CreateColorFromHexString(AtonementEchoTrackerSaved.Settings.StackColor):GetRGBA()
	)
end

function AtonementEchoTracker:ApplyDurationColor()
	self.frame.Cooldown.DurationText:SetTextColor(
		CreateColorFromHexString(AtonementEchoTrackerSaved.Settings.DurationColor):GetRGBA()
	)
end

function AtonementEchoTracker:SetShowFractions(showFractions)
	self.frame.Cooldown:SetHideCountdownNumbers(showFractions or not AtonementEchoTrackerSaved.Settings.ShowDuration)
	self.frame.Cooldown.DurationText:SetShown(
		showFractions and AtonementEchoTrackerSaved.Settings.ShowDuration and #self.activeInstances > 0
	)
	self.frame:SetScript("OnUpdate", showFractions and GenerateClosure(self.OnUpdate, self) or nil)
end

function AtonementEchoTracker:OnUpdate(_, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed

	if self.elapsed < 0.1 then
		return
	end

	self.elapsed = self.elapsed - 0.1

	if self.activeDuration == nil then
		return
	end

	self.frame.Cooldown.DurationText:SetFormattedText("%.1f", self.activeDuration:GetRemainingDuration())
end

function AtonementEchoTracker:ApplyMask()
	local hide = AtonementEchoTrackerSaved.Settings.HideMask

	if hide then
		self.frame.Icon:RemoveMaskTexture(self.frame.Mask)
	else
		self.frame.Icon:AddMaskTexture(self.frame.Mask)
	end

	self.frame.Overlay:SetShown(not hide)
end

function AtonementEchoTracker:ApplyStackCountAnchor()
	local anchor = AtonementEchoTrackerSaved.Settings.StackCountAnchor
	local justifyH = "CENTER"

	if anchor == "TOPLEFT" or anchor == "LEFT" or anchor == "BOTTOMLEFT" then
		justifyH = "LEFT"
	elseif anchor == "TOPRIGHT" or anchor == "RIGHT" or anchor == "BOTTOMRIGHT" then
		justifyH = "RIGHT"
	end

	self.frame.Cooldown.StackCount:ClearAllPoints()
	self.frame.Cooldown.StackCount:SetPoint(
		anchor,
		self.frame.Cooldown,
		anchor,
		AtonementEchoTrackerSaved.Settings.StackCountOffsetX,
		AtonementEchoTrackerSaved.Settings.StackCountOffsetY
	)
	self.frame.Cooldown.StackCount:SetJustifyH(justifyH)
end

function AtonementEchoTracker:ApplyBorderStyle()
	local path = LibSharedMedia:Fetch(LibSharedMedia.MediaType.BORDER, AtonementEchoTrackerSaved.Settings.BorderStyle)
	if path then
		self.frame.Border:SetBackdrop({ edgeFile = path, edgeSize = 8 })
	else
		self.frame.Border:SetBackdrop(nil)
	end
end

function AtonementEchoTracker:ApplySettings()
	self:ApplySize()
	self:ApplyPosition()
	self:ApplyOpacity()
	self:ApplyIconZoom()
	self:ApplyStackFont()
	self:ApplyStackColor()
	self:ApplyDurationFont()
	self:ApplyDurationColor()
	self:ApplyBorderStyle()
	self:ApplyMask()
	self:ApplyStackCountAnchor()
	self:SetShowFractions(AtonementEchoTrackerSaved.Settings.ShowFractions)
end

function AtonementEchoTracker:OnSettingsChanged(key, value)
	local Keys = Private.Settings.Keys

	if key == Keys.Width or key == Keys.Height then
		self:ApplySize()
	elseif key == Keys.Opacity then
		self:ApplyOpacity()
	elseif key == Keys.IconZoom then
		self:ApplyIconZoom()
	elseif key == Keys.Font or key == Keys.StackFontSize or key == Keys.FontFlags then
		self:ApplyStackFont()
		self:ApplyDurationFont()
	elseif key == Keys.DurationFontSize then
		self:ApplyDurationFont()
	elseif key == Keys.StackColor then
		self:ApplyStackColor()
	elseif key == Keys.DurationColor then
		self:ApplyDurationColor()
	elseif key == Keys.BorderStyle then
		self:ApplyBorderStyle()
	elseif key == Keys.ShowFractions then
		self:SetShowFractions(value)
	elseif key == Keys.DefaultState then
		self:UpdateDisplay()
	elseif key == Keys.HideMask then
		self:ApplyMask()
	elseif key == Keys.StackCountAnchor or key == Keys.StackCountOffsetX or key == Keys.StackCountOffsetY then
		self:ApplyStackCountAnchor()
	elseif key == Keys.ShowDuration then
		self:SetShowFractions(AtonementEchoTrackerSaved.Settings.ShowFractions)
	elseif key == Keys.CombatOnly then
		if value then
			self:RegisterCombatEvents()

			if not UnitAffectingCombat("player") and not LibEditMode:IsInEditMode() then
				self.frame:Hide()
			end
		else
			self:UnregisterCombatEvents()
			self:UpdateDisplay()
		end
	elseif key == Keys.LoadConditionContentType then
		if not self:LoadConditionsProhibitExecution() then
			self:Enable()
		else
			self:Disable()
		end
	end
end

function AtonementEchoTracker:UpdateDisplay()
	local activeCount = #self.activeInstances

	if activeCount == 0 then
		self.activeDuration = nil
		self.frame.Cooldown.StackCount:SetText("0")
		self.frame.Cooldown.DurationText:SetShown(false)
		self.frame.Cooldown:Clear()

		if LibEditMode:IsInEditMode() then
			self.frame:Show()
		elseif AtonementEchoTrackerSaved.Settings.DefaultState == Private.Enum.DefaultState.Hidden then
			self.frame:Hide()
		else
			self.frame.Icon:SetDesaturated(true)
			self.frame:SetShown(not AtonementEchoTrackerSaved.Settings.CombatOnly)
		end
	else
		local nextExpiringInstance = nil

		for _, instance in ipairs(self.activeInstances) do
			if nextExpiringInstance == nil or instance.expirationTime < nextExpiringInstance.expirationTime then
				nextExpiringInstance = instance
			end
		end

		local duration = C_DurationUtil.CreateDuration()
		duration:SetTimeFromEnd(nextExpiringInstance.expirationTime, nextExpiringInstance.duration)
		self.activeDuration = duration
		self.frame.Cooldown:SetCooldownFromDurationObject(duration, true)
		self.frame.Cooldown.StackCount:SetText(tostring(activeCount))
		self.frame.Cooldown.DurationText:SetShown(
			AtonementEchoTrackerSaved.Settings.ShowFractions and AtonementEchoTrackerSaved.Settings.ShowDuration
		)
		self.frame.Icon:SetDesaturated(false)
		self.frame:Show()
	end
end

function AtonementEchoTracker:OnFrameEvent(_, event, ...)
	if event == "UNIT_AURA" then
		---@type string, UnitAuraUpdateInfo
		local unit, updateInfo = ...

		-- a bit unfortunate but this is already handled via raid tokens
		if unit == "player" and IsInRaid() then
			return
		end

		if updateInfo.isFullUpdate then
			for i = #self.activeInstances, 1, -1 do
				if self.activeInstances[i].unit == unit then
					table.remove(self.activeInstances, i)
				end
			end

			local auraIndex = 1
			local results = {}

			while true do
				local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL|PLAYER")

				if aura == nil then
					break
				end

				if
					not issecretvalue(aura.spellId)
					and self.auraIds[aura.spellId] == true
					and not issecretvalue(aura.expirationTime)
					and not issecretvalue(aura.duration)
				then
					table.insert(results, {
						auraInstanceId = aura.auraInstanceID,
						expirationTime = aura.expirationTime,
						duration = aura.duration,
						spellId = aura.spellId,
					})
				end

				auraIndex = auraIndex + 1
			end

			for _, entry in ipairs(results) do
				table.insert(self.activeInstances, {
					auraInstanceId = entry.auraInstanceId,
					expirationTime = entry.expirationTime,
					duration = entry.duration,
					spellId = entry.spellId,
					unit = unit,
				})
			end

			if #results > 0 then
				self:UpdateDisplay()
			end
		end

		if updateInfo.addedAuras then
			for _, aura in ipairs(updateInfo.addedAuras) do
				if
					not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, "HELPFUL|PLAYER")
					and not issecretvalue(aura.spellId)
					and enabledAuras[self.specId][aura.spellId] == true
					and not issecretvalue(aura.expirationTime)
					and not issecretvalue(aura.duration)
				then
					table.insert(self.activeInstances, {
						auraInstanceId = aura.auraInstanceID,
						expirationTime = aura.expirationTime,
						duration = aura.duration,
						spellId = aura.spellId,
						unit = unit,
					})

					self:UpdateDisplay()
				end
			end
		end

		if updateInfo.updatedAuraInstanceIDs then
			for _, auraInstanceId in ipairs(updateInfo.updatedAuraInstanceIDs) do
				for i, instance in ipairs(self.activeInstances) do
					if instance.unit == unit and instance.auraInstanceId == auraInstanceId then
						local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceId)

						if auraData ~= nil then
							if not issecretvalue(auraData.expirationTime) then
								self.activeInstances[i].expirationTime = auraData.expirationTime
								self:UpdateDisplay()
							end
							-- duration rarely changes on refresh but guard it anyway
							if not issecretvalue(auraData.duration) then
								self.activeInstances[i].duration = auraData.duration
							end
						end

						break
					end
				end
			end
		end

		if updateInfo.removedAuraInstanceIDs then
			for _, auraInstanceId in ipairs(updateInfo.removedAuraInstanceIDs) do
				for i = #self.activeInstances, 1, -1 do
					if
						self.activeInstances[i].unit == unit
						and self.activeInstances[i].auraInstanceId == auraInstanceId
					then
						table.remove(self.activeInstances, i)
						self:UpdateDisplay()
					end
				end
			end
		end
	elseif event == "ENCOUNTER_END" then
		if IsInRaid() then
			table.wipe(self.activeInstances)
			self:UpdateDisplay()
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if IsInRaid() then
			self:UnregisterPartyEvents()
		else
			self:RegisterPartyEvents()
		end
	elseif
		event == "ZONE_CHANGED_NEW_AREA"
		or event == "LOADING_SCREEN_DISABLED"
		or event == "PLAYER_SPECIALIZATION_CHANGED"
		or event == "UPDATE_INSTANCE_INFO"
	then
		self:UpdateContentType()

		local specId = PlayerUtil.GetCurrentSpecID()
		self.specId = specId
		self.auraIds = enabledAuras[self.specId]

		if not self:LoadConditionsProhibitExecution() then
			self:Enable()
		else
			self:Disable()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:UpdateDisplay()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if not LibEditMode:IsInEditMode() then
			self.frame:Hide()
		end
	elseif event == Private.Enum.Events.EDIT_MODE_POSITION_CHANGED then
		local _, _, point, x, y = ...

		AtonementEchoTrackerSaved.Settings.Position.point = point
		AtonementEchoTrackerSaved.Settings.Position.x = x
		AtonementEchoTrackerSaved.Settings.Position.y = y

		self:ApplyPosition()
	end
end

table.insert(Private.LoginFnQueue, GenerateClosure(AtonementEchoTracker.Init, AtonementEchoTracker))
