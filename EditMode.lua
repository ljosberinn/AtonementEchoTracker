---@type string, AtonementEchoTracker
local addonName, Private = ...

---@param editModeParentFrame Frame
function Private.SetupEditMode(editModeParentFrame)
	local LibEditMode = LibStub("LibEditMode")
	local LibSharedMedia = LibStub("LibSharedMedia-3.0")

	local function CreateSetting(key, defaults)
		if key == Private.Settings.Keys.LoadConditionContentType then
			local labels = Private.Settings.GetContentTypeLabels()

			local function Generator(_, rootDescription)
				for id, label in pairs(labels) do
					local function IsEnabled()
						return AtonementEchoTrackerSaved.Settings.LoadConditionContentType[id]
					end

					local function Toggle()
						AtonementEchoTrackerSaved.Settings.LoadConditionContentType[id] =
							not AtonementEchoTrackerSaved.Settings.LoadConditionContentType[id]
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							AtonementEchoTrackerSaved.Settings.LoadConditionContentType
						)
					end

					rootDescription:CreateCheckbox(label, IsEnabled, Toggle, { value = label, multiple = true })
				end
			end

			local function Set(_, values)
				local hasChanges = false
				for id, bool in pairs(values) do
					if AtonementEchoTrackerSaved.Settings.LoadConditionContentType[id] ~= bool then
						AtonementEchoTrackerSaved.Settings.LoadConditionContentType[id] = bool
						hasChanges = true
					end
				end
				if hasChanges then
					Private.EventRegistry:TriggerEvent(
						Private.Enum.Events.SETTING_CHANGED,
						key,
						AtonementEchoTrackerSaved.Settings.LoadConditionContentType
					)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = "Load Conditions",
				desc = "Content types in which the tracker is active.",
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.LoadConditionContentType,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Width then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.Width
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.Width ~= value then
					AtonementEchoTrackerSaved.Settings.Width = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Width",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.Width,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.Height then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.Height
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.Height ~= value then
					AtonementEchoTrackerSaved.Settings.Height = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Height",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.Height,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.DurationFontSize then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.DurationFontSize
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.DurationFontSize ~= value then
					AtonementEchoTrackerSaved.Settings.DurationFontSize = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Duration Font Size",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.DurationFontSize,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.StackFontSize then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.StackFontSize
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.StackFontSize ~= value then
					AtonementEchoTrackerSaved.Settings.StackFontSize = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Stack Font Size",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.StackFontSize,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.DefaultState then
			local function Generator(_, rootDescription)
				for _, state in ipairs(Private.Settings.GetDefaultStates()) do
					local function IsEnabled()
						return AtonementEchoTrackerSaved.Settings.DefaultState == state
					end

					local function SetProxy()
						if AtonementEchoTrackerSaved.Settings.DefaultState ~= state then
							AtonementEchoTrackerSaved.Settings.DefaultState = state
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, state)
						end
					end

					rootDescription:CreateRadio(state, IsEnabled, SetProxy)
				end
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.DefaultState ~= value then
					AtonementEchoTrackerSaved.Settings.DefaultState = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = "Default State",
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.DefaultState,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.FontFlags then
			local function Generator(_, rootDescription)
				for _, flag in ipairs({ Private.Enum.FontFlags.OUTLINE, Private.Enum.FontFlags.SHADOW }) do
					local function IsEnabled()
						return AtonementEchoTrackerSaved.Settings.FontFlags[flag] == true
					end

					local function SetProxy()
						AtonementEchoTrackerSaved.Settings.FontFlags[flag] =
							not AtonementEchoTrackerSaved.Settings.FontFlags[flag]
						Private.EventRegistry:TriggerEvent(
							Private.Enum.Events.SETTING_CHANGED,
							key,
							AtonementEchoTrackerSaved.Settings.FontFlags
						)
					end

					rootDescription:CreateCheckbox(flag, IsEnabled, SetProxy)
				end
			end

			local function Set(_, value)
				AtonementEchoTrackerSaved.Settings.FontFlags = value
				Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
			end

			---@type LibEditModeDropdown
			return {
				name = "Font Flags",
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.FontFlags,
				generator = Generator,
				set = Set,
				multiple = true,
			}
		end

		if key == Private.Settings.Keys.DurationColor then
			local function Get(_)
				return CreateColorFromHexString(AtonementEchoTrackerSaved.Settings.DurationColor)
			end

			---@param _ string
			---@param color ColorMixin
			local function Set(_, color)
				local r, g, b, a = color:GetRGBA()
				local hex = string.format("%02X%02X%02X%02X", a * 255, r * 255, g * 255, b * 255)
				if AtonementEchoTrackerSaved.Settings.DurationColor ~= hex then
					AtonementEchoTrackerSaved.Settings.DurationColor = hex
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, hex)
				end
			end

			---@type LibEditModeColorPicker
			return {
				name = "Duration Color",
				desc = "Only applies when Show Duration Fractions is enabled.",
				kind = LibEditMode.SettingType.ColorPicker,
				default = CreateColorFromHexString(defaults.DurationColor),
				get = Get,
				set = Set,
				hasOpacity = true,
			}
		end

		if key == Private.Settings.Keys.StackColor then
			local function Get(_)
				return CreateColorFromHexString(AtonementEchoTrackerSaved.Settings.StackColor)
			end

			---@param _ string
			---@param color ColorMixin
			local function Set(_, color)
				local r, g, b, a = color:GetRGBA()
				local hex = string.format("%02X%02X%02X%02X", a * 255, r * 255, g * 255, b * 255)
				if AtonementEchoTrackerSaved.Settings.StackColor ~= hex then
					AtonementEchoTrackerSaved.Settings.StackColor = hex
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, hex)
				end
			end

			---@type LibEditModeColorPicker
			return {
				name = "Stack Color",
				kind = LibEditMode.SettingType.ColorPicker,
				default = CreateColorFromHexString(defaults.StackColor),
				get = Get,
				set = Set,
				hasOpacity = true,
			}
		end

		if key == Private.Settings.Keys.ShowFractions then
			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.ShowFractions
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.ShowFractions ~= value then
					AtonementEchoTrackerSaved.Settings.ShowFractions = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeCheckbox
			return {
				name = "Show Duration Fractions",
				kind = Enum.EditModeSettingDisplayType.Checkbox,
				default = defaults.ShowFractions,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.ShowDuration then
			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.ShowDuration
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.ShowDuration ~= value then
					AtonementEchoTrackerSaved.Settings.ShowDuration = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeCheckbox
			return {
				name = "Show Duration",
				kind = Enum.EditModeSettingDisplayType.Checkbox,
				default = defaults.ShowDuration,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.CombatOnly then
			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.CombatOnly
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.CombatOnly ~= value then
					AtonementEchoTrackerSaved.Settings.CombatOnly = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeCheckbox
			return {
				name = "Only Show In Combat",
				kind = Enum.EditModeSettingDisplayType.Checkbox,
				default = defaults.CombatOnly,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.Opacity then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.Opacity
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.Opacity ~= value then
					AtonementEchoTrackerSaved.Settings.Opacity = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Opacity",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.Opacity,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.IconZoom then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.IconZoom
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.IconZoom ~= value then
					AtonementEchoTrackerSaved.Settings.IconZoom = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Icon Zoom",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.IconZoom,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.Font then
			local function Generator(_, rootDescription)
				for name, path in pairs(LibSharedMedia:HashTable(LibSharedMedia.MediaType.FONT)) do
					local function IsEnabled()
						return AtonementEchoTrackerSaved.Settings.Font == path
					end

					local function SetProxy()
						if AtonementEchoTrackerSaved.Settings.Font ~= path then
							AtonementEchoTrackerSaved.Settings.Font = path
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, path)
						end
					end

					rootDescription:CreateRadio(name, IsEnabled, SetProxy)
				end
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.Font ~= value then
					AtonementEchoTrackerSaved.Settings.Font = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = "Font",
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.Font,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.BorderStyle then
			local function Generator(_, rootDescription)
				for _, style in ipairs(Private.Settings.GetBorderOptions()) do
					local function IsEnabled()
						return AtonementEchoTrackerSaved.Settings.BorderStyle == style
					end

					local function SetProxy()
						if AtonementEchoTrackerSaved.Settings.BorderStyle ~= style then
							AtonementEchoTrackerSaved.Settings.BorderStyle = style
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, style)
						end
					end

					rootDescription:CreateRadio(style, IsEnabled, SetProxy)
				end
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.BorderStyle ~= value then
					AtonementEchoTrackerSaved.Settings.BorderStyle = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = "Border Style",
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.BorderStyle,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.HideMask then
			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.HideMask
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.HideMask ~= value then
					AtonementEchoTrackerSaved.Settings.HideMask = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeCheckbox
			return {
				name = "Hide Mask",
				kind = Enum.EditModeSettingDisplayType.Checkbox,
				default = defaults.HideMask,
				get = Get,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.StackCountAnchor then
			local function Generator(_, rootDescription)
				for _, anchor in ipairs(Private.Settings.GetStackCountAnchors()) do
					local function IsEnabled()
						return AtonementEchoTrackerSaved.Settings.StackCountAnchor == anchor
					end

					local function SetProxy()
						if AtonementEchoTrackerSaved.Settings.StackCountAnchor ~= anchor then
							AtonementEchoTrackerSaved.Settings.StackCountAnchor = anchor
							Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, anchor)
						end
					end

					rootDescription:CreateRadio(anchor, IsEnabled, SetProxy)
				end
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.StackCountAnchor ~= value then
					AtonementEchoTrackerSaved.Settings.StackCountAnchor = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeDropdown
			return {
				name = "Stack Count Anchor",
				kind = Enum.EditModeSettingDisplayType.Dropdown,
				default = defaults.StackCountAnchor,
				generator = Generator,
				set = Set,
			}
		end

		if key == Private.Settings.Keys.StackCountOffsetX then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.StackCountOffsetX
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.StackCountOffsetX ~= value then
					AtonementEchoTrackerSaved.Settings.StackCountOffsetX = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Stack Count Offset X",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.StackCountOffsetX,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		if key == Private.Settings.Keys.StackCountOffsetY then
			local sliderSettings = Private.Settings.GetSliderSettingsForKey(key)

			local function Get(_)
				return AtonementEchoTrackerSaved.Settings.StackCountOffsetY
			end

			local function Set(_, value)
				if AtonementEchoTrackerSaved.Settings.StackCountOffsetY ~= value then
					AtonementEchoTrackerSaved.Settings.StackCountOffsetY = value
					Private.EventRegistry:TriggerEvent(Private.Enum.Events.SETTING_CHANGED, key, value)
				end
			end

			---@type LibEditModeSlider
			return {
				name = "Stack Count Offset Y",
				kind = Enum.EditModeSettingDisplayType.Slider,
				default = defaults.StackCountOffsetY,
				get = Get,
				set = Set,
				minValue = sliderSettings.min,
				maxValue = sliderSettings.max,
				valueStep = sliderSettings.step,
			}
		end

		error(string.format("CreateSetting: no widget defined for key '%s'", key or "nil"))
	end

	LibEditMode:AddFrame(editModeParentFrame, function(frame, layoutName, point, x, y)
		Private.EventRegistry:TriggerEvent(
			Private.Enum.Events.EDIT_MODE_POSITION_CHANGED,
			frame,
			layoutName,
			point,
			x,
			y
		)
	end, { point = "CENTER", x = 0, y = 0 }, addonName)

	local displayOrder = Private.Settings.GetDisplayOrder()
	local defaults = Private.Settings.GetDefaultSettings()
	local settings = {}

	for i = 1, #displayOrder do
		table.insert(settings, CreateSetting(displayOrder[i], defaults))
	end

	LibEditMode:AddFrameSettings(editModeParentFrame, settings)
end
