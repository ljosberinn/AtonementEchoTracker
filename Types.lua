---@meta

---@class AtonementEchoTracker
---@field Enum AtonementEchoTrackerEnums
---@field Settings AtonementEchoTrackerSettings
---@field EventRegistry CallbackRegistryMixin
---@field L table<string, table<string, string|nil>>
---@field LoginFnQueue function[]
---@field SetupEditMode fun(editModeParentFrame: Frame)


---@class AtonementEchoTrackerEnums
---@field Events table<string, string>
---@field ContentType table<string, number>
---@field FontFlags table<string, string>
---@field DefaultState table<string, string>

---@class AtonementEchoTrackerSettings
---@field Keys table<string, string>
---@field GetDefaultSettings fun(): AtonementEchoTrackerSavedSettings
---@field GetDisplayOrder fun(): string[]
---@field GetSliderSettingsForKey fun(key: string): SliderSettings
---@field GetBorderOptions fun(): string[]
---@field GetDefaultStates fun(): string[]

---@class AtonementEchoTrackerSaved
---@field Settings AtonementEchoTrackerSavedSettings

---@class AtonementEchoTrackerSavedSettings
---@field LoadConditionContentType table<number, boolean>
---@field Width number
---@field Height number
---@field DurationFontSize number
---@field StackFontSize number
---@field DefaultState string
---@field DurationColor string
---@field StackColor string
---@field Opacity number
---@field IconZoom number
---@field Font string
---@field FontFlags table<string, boolean>
---@field BorderStyle string
---@field Position FramePosition

---@class FramePosition
---@field point FramePoint
---@field x number
---@field y number

---@class SliderSettings
---@field min number
---@field max number
---@field step number

---@class LibEditModeSetting
---@field name string
---@field kind string
---@field desc string?
---@field default number|string|boolean|table
---@field disabled boolean?

---@class LibEditModeGetterSetter
---@field set fun(layoutName: string, value: number|string|boolean|table, fromReset: boolean)
---@field get fun(layoutName: string): number|string|boolean|table

---@class LibEditModeButton
---@field text string
---@field click function

---@class LibEditModeCheckbox : LibEditModeSetting, LibEditModeGetterSetter

---@class LibEditModeDropdownBase : LibEditModeSetting
---@field generator fun(owner, rootDescription, data)
---@field height number?
---@field multiple boolean?

---@class LibEditModeDropdownGenerator : LibEditModeDropdownBase
---@field generator fun(owner, rootDescription, data)

---@class LibEditModeDropdownSet : LibEditModeDropdownBase
---@field set fun(layoutName: string, value: number|string|boolean|table, fromReset: boolean)

---@alias LibEditModeDropdown LibEditModeDropdownGenerator | LibEditModeDropdownSet

---@class LibEditModeSlider : LibEditModeSetting, LibEditModeGetterSetter
---@field minValue number?
---@field maxValue number?
---@field valueStep number?
---@field formatter (fun(value: number): string)|nil

---@class LibEditModeColorPicker : LibEditModeSetting, LibEditModeGetterSetter
---@field hasOpacity boolean?
