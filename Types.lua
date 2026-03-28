---@meta

---@class AtonementEchoTracker
---@field Enum AtonementEchoTrackerEnums
---@field Settings AtonementEchoTrackerSettings
---@field EventRegistry CallbackRegistryMixin
---@field LoginFnQueue function[]
---@field SetupEditMode fun(editModeParentFrame: Frame)

---@class Driver
---@field private auraId number
---@field private specId number
---@field private activeInstances table<number, ActiveAuraInstance>

---@class ActiveAuraInstance
---@field auraInstanceId number
---@field expirationTime number
---@field duration number
---@field unit string

---@class AtonementEchoTrackerEnums
---@field Events table<string, string>
---@field ContentType table<string, number>
---@field FontFlags table<string, string>
---@field DefaultState table<string, string>
---@field StackCountAnchor table<string, string>

---@class AtonementEchoTrackerCooldown : Cooldown
---@field DurationText FontString
---@field StackCount FontString

---@class AtonementEchoTrackerFrame : Frame
---@field Icon Texture
---@field Mask MaskTexture
---@field Overlay Texture
---@field Border Frame|BackdropTemplate
---@field Cooldown AtonementEchoTrackerCooldown

---@class AtonementEchoTrackerSettings
---@field Keys table<string, string>
---@field GetDefaultSettings fun(): AtonementEchoTrackerSavedSettings
---@field GetDisplayOrder fun(): string[]
---@field GetSliderSettingsForKey fun(key: string): SliderSettings
---@field GetBorderOptions fun(): string[]
---@field GetContentTypeLabels fun(): table<number, string>
---@field GetDefaultStates fun(): string[]
---@field GetStackCountAnchors fun(): string[]

---@class AtonementEchoTrackerSaved
---@field Settings AtonementEchoTrackerSavedSettings

---@type AtonementEchoTrackerSaved
AtonementEchoTrackerSaved = AtonementEchoTrackerSaved

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
---@field ShowFractions boolean
---@field ShowDuration boolean
---@field CombatOnly boolean
---@field HideMask boolean
---@field StackCountAnchor string
---@field StackCountOffsetX number
---@field StackCountOffsetY number
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
