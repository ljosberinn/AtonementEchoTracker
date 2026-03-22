---@type string, AtonementEchoTracker
local addonName, Private = ...

---@class Driver
local AtonementEchoTracker = {}

local enabledAuras = {
	[1468] = { [364343] = true }, -- preservation: echo
	[256] = { [194384] = true }, -- discipline: atonement
	[105] = { [774] = true, [155777] = true }, -- restoration: rejuvenation & reju (germination)
}

function AtonementEchoTracker:Init()
	self.contentType = Private.Enum.ContentType.OpenWorld
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

	local LibEditMode = LibStub("LibEditMode")

	LibEditMode:RegisterCallback("enter", function()
		self.frame:Show()
	end)
	LibEditMode:RegisterCallback("exit", function()
		if self:IsRelevantSpec() then
			self:UpdateDisplay()
		else
			self.frame:Hide()
		end
	end)

	if self:IsRelevantSpec() then
		self:Enable()
	end

	self.frame:SetScript("OnEvent", GenerateClosure(self.OnFrameEvent, self))
end

function AtonementEchoTracker:IsRelevantSpec()
	return enabledAuras[self.specId] ~= nil
end

function AtonementEchoTracker:OnListenerEvent(_self, event, ...)
	self:OnFrameEvent(self, event, ...)
end

function AtonementEchoTracker:Enable()
	self:UpdateDisplay()
	for auraId, enabled in pairs(self.auraIds) do
		if enabled then
			self.frame.Icon:SetTexture(C_Spell.GetSpellTexture(auraId))
			break
		end
	end

	self:RegisterRaidEvents()

	if not IsInRaid() then
		self:RegisterPartyEvents()
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
	for _, frame in ipairs(self.listenerFrames.party) do
		frame:UnregisterAllEvents()
	end

	for _, frame in ipairs(self.listenerFrames.raid) do
		frame:UnregisterAllEvents()
	end

	self.frame:Hide()
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
	self.frame.Cooldown:SetHideCountdownNumbers(showFractions)
	self.frame.Cooldown.DurationText:SetShown(showFractions and #self.activeInstances > 0)
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
	self.frame.Cooldown.StackCount:SetPoint(anchor)
	self.frame.Cooldown.StackCount:SetJustifyH(justifyH)
end

function AtonementEchoTracker:ApplyBorderStyle()
	local LibSharedMedia = LibStub("LibSharedMedia-3.0")
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
	elseif key == Keys.StackCountAnchor then
		self:ApplyStackCountAnchor()
	end
end

function AtonementEchoTracker:UpdateDisplay()
	local activeCount = #self.activeInstances

	if activeCount == 0 then
		self.activeDuration = nil
		self.frame.Cooldown.StackCount:SetText("0")
		self.frame.Cooldown.DurationText:SetShown(false)
		self.frame.Cooldown:Clear()

		if AtonementEchoTrackerSaved.Settings.DefaultState == Private.Enum.DefaultState.Hidden then
			local LibEditMode = LibStub("LibEditMode")
			if not LibEditMode:IsInEditMode() then
				self.frame:Hide()
			end
		else
			self.frame.Icon:SetDesaturated(true)
			self.frame:Show()
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
		self.frame.Cooldown.DurationText:SetShown(AtonementEchoTrackerSaved.Settings.ShowFractions)
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

		if updateInfo.isFullUpdate or updateInfo.addedAuras ~= nil then
			---@type AuraData[]
			local auras = updateInfo.addedAuras == nil and C_UnitAuras.GetUnitAuras(unit, "PLAYER|HELPFUL", nil)
				or updateInfo.addedAuras

			for _, aura in ipairs(auras) do
				if
					not issecretvalue(aura.sourceUnit)
					and aura.sourceUnit == "player"
					and self.auraIds[aura.spellId]
				then
					table.insert(self.activeInstances, {
						auraInstanceId = aura.auraInstanceID,
						expirationTime = aura.expirationTime,
						duration = aura.duration,
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
		self.auraIds = enabledAuras[self.specId]

		if self:IsRelevantSpec() then
			self:Enable()
		else
			self:Disable()
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
