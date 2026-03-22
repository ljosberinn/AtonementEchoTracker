---@type string, table
local _, Private = ...

---@class AtonementEchoTrackerSettings
Private.Settings = {}

Private.Settings.Keys = {
	LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE",
	Width = "FRAME_WIDTH",
	Height = "FRAME_HEIGHT",
	DurationFontSize = "DURATION_FONT_SIZE",
	StackFontSize = "STACK_FONT_SIZE",
	DefaultState = "DEFAULT_STATE",
	DurationColor = "DURATION_COLOR",
	StackColor = "STACK_COLOR",
	Opacity = "OPACITY",
	IconZoom = "ICON_ZOOM",
	Font = "FONT",
	FontFlags = "FONT_FLAGS",
	BorderStyle = "BORDER_STYLE",
	ShowFractions = "SHOW_FRACTIONS",
	HideMask = "HIDE_MASK",
	StackCountAnchor = "STACK_COUNT_ANCHOR",
}

---@return AtonementEchoTrackerSavedSettings
function Private.Settings.GetDefaultSettings()
	return {
		LoadConditionContentType = {
			[Private.Enum.ContentType.OpenWorld] = false,
			[Private.Enum.ContentType.Delve] = false,
			[Private.Enum.ContentType.Dungeon] = true,
			[Private.Enum.ContentType.Raid] = true,
			[Private.Enum.ContentType.Arena] = false,
			[Private.Enum.ContentType.Battleground] = false,
		},
		Width = 40,
		Height = 40,
		DurationFontSize = 14,
		StackFontSize = 10,
		DefaultState = Private.Enum.DefaultState.Desaturated,
		DurationColor = "FFFFFFFF",
		StackColor = "FFFFFFFF",
		Opacity = 1,
		IconZoom = 0,
		Font = "Fonts\\FRIZQT__.TTF",
		FontFlags = {
			[Private.Enum.FontFlags.OUTLINE] = true,
			[Private.Enum.FontFlags.SHADOW] = false,
		},
		BorderStyle = "None",
		ShowFractions = false,
		HideMask = false,
		StackCountAnchor = Private.Enum.StackCountAnchor.BottomRight,
		Position = { point = "CENTER", x = 0, y = 0 },
	}
end

---@param key string
---@return SliderSettings
function Private.Settings.GetSliderSettingsForKey(key)
	if key == Private.Settings.Keys.Width or key == Private.Settings.Keys.Height then
		return { min = 8, max = 400, step = 1 }
	end

	if key == Private.Settings.Keys.DurationFontSize or key == Private.Settings.Keys.StackFontSize then
		return { min = 6, max = 100, step = 1 }
	end

	if key == Private.Settings.Keys.Opacity then
		return { min = 0, max = 1, step = 0.05 }
	end

	if key == Private.Settings.Keys.IconZoom then
		return { min = 0, max = 0.5, step = 0.01 }
	end

	error(string.format("GetSliderSettingsForKey: no slider settings defined for key '%s'", key or "nil"))
end

function Private.Settings.GetDefaultStates()
	return {
		Private.Enum.DefaultState.Desaturated,
		Private.Enum.DefaultState.Hidden,
	}
end

function Private.Settings.GetStackCountAnchors()
	return {
		Private.Enum.StackCountAnchor.TopLeft,
		Private.Enum.StackCountAnchor.Top,
		Private.Enum.StackCountAnchor.TopRight,
		Private.Enum.StackCountAnchor.Left,
		Private.Enum.StackCountAnchor.Center,
		Private.Enum.StackCountAnchor.Right,
		Private.Enum.StackCountAnchor.BottomLeft,
		Private.Enum.StackCountAnchor.Bottom,
		Private.Enum.StackCountAnchor.BottomRight,
	}
end

function Private.Settings.GetBorderOptions()
	local LibSharedMedia = LibStub("LibSharedMedia-3.0")
	local borders = CopyTable(LibSharedMedia:List(LibSharedMedia.MediaType.BORDER))
	table.sort(borders)
	return borders
end

function Private.Settings.GetDisplayOrder()
	return {
		Private.Settings.Keys.Width,
		Private.Settings.Keys.Height,
		Private.Settings.Keys.Opacity,
		Private.Settings.Keys.IconZoom,
		Private.Settings.Keys.Font,
		Private.Settings.Keys.FontFlags,
		Private.Settings.Keys.DurationFontSize,
		Private.Settings.Keys.StackFontSize,
		Private.Settings.Keys.StackCountAnchor,
		Private.Settings.Keys.DefaultState,
		Private.Settings.Keys.HideMask,
		Private.Settings.Keys.ShowFractions,
		Private.Settings.Keys.DurationColor,
		Private.Settings.Keys.StackColor,
		Private.Settings.Keys.BorderStyle,
	}
end
