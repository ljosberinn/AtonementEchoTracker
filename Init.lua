---@type string, table
local addonName, Private = ...

Private.L = {}

Private.EventRegistry = CreateFromMixins(CallbackRegistryMixin)
Private.EventRegistry:OnLoad()
Private.EventRegistry:GenerateCallbackEvents({ Private.Enum.Events.SETTING_CHANGED })

Private.LoginFnQueue = {}

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	local class = select(3, UnitClass("player"))
	if class ~= Constants.UICharacterClasses.Evoker and class ~= Constants.UICharacterClasses.Priest then
		return
	end

	-- ---@type EssencesSaved
	-- EssencesSaved = EssencesSaved or {}
	-- EssencesSaved.Settings = EssencesSaved.Settings or {}

	-- local defaults = Private.Settings.GetDefaultSettings()

	-- for key, value in pairs(defaults) do
	-- 	if EssencesSaved.Settings[key] == nil then
	-- 		EssencesSaved.Settings[key] = value
	-- 	end
	-- end

	for i = 1, #Private.LoginFnQueue do
		Private.LoginFnQueue[i]()
	end

	table.wipe(Private.LoginFnQueue)
end)
