---@type string, AtonementEchoTracker
local addonName, Private = ...

Private.L = {}

Private.EventRegistry = CreateFromMixins(CallbackRegistryMixin)
Private.EventRegistry:OnLoad()
Private.EventRegistry:GenerateCallbackEvents({
	Private.Enum.Events.SETTING_CHANGED,
	Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
})

Private.LoginFnQueue = {}

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	local class = select(3, UnitClass("player"))
	if
		class ~= Constants.UICharacterClasses.Evoker
		and class ~= Constants.UICharacterClasses.Priest
		and class ~= Constants.UICharacterClasses.Druid
	then
		return
	end

	---@type AtonementEchoTrackerSaved
	AtonementEchoTrackerSaved = AtonementEchoTrackerSaved or {}
	AtonementEchoTrackerSaved.Settings = AtonementEchoTrackerSaved.Settings or {}

	local defaults = Private.Settings.GetDefaultSettings()

	for key, value in pairs(defaults) do
		if AtonementEchoTrackerSaved.Settings[key] == nil then
			AtonementEchoTrackerSaved.Settings[key] = value
		end
	end

	for i = 1, #Private.LoginFnQueue do
		Private.LoginFnQueue[i]()
	end

	table.wipe(Private.LoginFnQueue)
end)
