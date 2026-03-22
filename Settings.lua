---@type string, table
local _, Private = ...

---@class AtonementEchoTrackerSettings
Private.Settings = {}

Private.Settings.Keys = {
	LoadConditionContentType = "LOAD_CONDITION_CONTENT_TYPE_SELF",
	Width = "FRAME_WIDTH_SELF",
	Height = "FRAME_HEIGHT_SELF",
	DurationFontSize = "DURATION_FONT_SIZE_SELF",
	StackFontSize = "STACK_FONT_SIZE_SELF",
	DefaultState = "DEFAULT_STATE_SELF",
	DurationColor = "DURATION_COLOR_SELF",
	StackColor = "STACK_COLOR_SELF",
	Opacity = "OPACITY_SELF",
	IconZoom = "ICON_ZOOM_SELF",
	Font = "FONT_SELF",
	FontFlags = "FONT_FLAGS_SELF",
	BorderStyle = "BORDER_STYLE_SELF",
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
		BorderStyle = "Blizzard Tooltip Border",
		Position = { point = "CENTER", x = 0, y = 0 },
	}
end

---@param key string
---@return SliderSettings
function Private.Settings.GetSliderSettingsForKey(key)
	if key == Private.Settings.Keys.Width or key == Private.Settings.Keys.Height then
		return { min = 8, max = 200, step = 1 }
	end

	if key == Private.Settings.Keys.DurationFontSize or key == Private.Settings.Keys.StackFontSize then
		return { min = 6, max = 64, step = 1 }
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
		Private.Settings.Keys.DurationFontSize,
		Private.Settings.Keys.StackFontSize,
		Private.Settings.Keys.DefaultState,
		Private.Settings.Keys.DurationColor,
		Private.Settings.Keys.StackColor,
		Private.Settings.Keys.BorderStyle,
	}
end
