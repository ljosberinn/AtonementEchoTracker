---@type string, AtonementEchoTracker
local _, Private = ...

---@class AtonementEchoTrackerEnums
Private.Enum = {}

---@enum AtonementEchoTrackerEvents
Private.Enum.Events = {
	SETTING_CHANGED = "SETTING_CHANGED",
	EDIT_MODE_POSITION_CHANGED = "EDIT_MODE_POSITION_CHANGED",
}

---@enum ContentType
Private.Enum.ContentType = {
	OpenWorld = 1,
	Delve = 2,
	Dungeon = 3,
	Raid = 4,
	Arena = 5,
	Battleground = 6,
}

---@enum FontFlags
Private.Enum.FontFlags = {
	OUTLINE = "OUTLINE",
	SHADOW = "SHADOW",
}

---@enum DefaultState
Private.Enum.DefaultState = {
	Desaturated = "Desaturated",
	Hidden = "Hidden",
}

---@enum StackCountAnchor
Private.Enum.StackCountAnchor = {
	TopLeft = "TOPLEFT",
	Top = "TOP",
	TopRight = "TOPRIGHT",
	Left = "LEFT",
	Center = "CENTER",
	Right = "RIGHT",
	BottomLeft = "BOTTOMLEFT",
	Bottom = "BOTTOM",
	BottomRight = "BOTTOMRIGHT",
}
