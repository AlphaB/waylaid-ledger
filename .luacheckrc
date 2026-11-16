std = "lua51"
self = false -- Colon methods and WoW mocks retain an implicit receiver.
-- StyLua owns wrapping; string literals and URLs can exceed its soft limit.
max_line_length = false
include_files = { "WaylaidLedger/**/*.lua", "tests/**/*.lua" }
exclude_files = { "WaylaidLedger/Libs/**" }

-- WoW API and optional provider globals used by the addon. Keep these read-only
-- in production so accidental global assignments still fail lint.
local wowGlobals = {
    "AuctionHouseFrame", "AuctionHouseFrameDisplayMode", "AuctionHouseFrameMixin", "AuctionHouseSearchContext", "Auctionator",
    "C_AuctionHouse", "C_Bank", "C_Container", "C_Item", "C_TooltipInfo",
    "ChatFontNormal", "CreateDataProvider", "CreateFrame", "CreateScrollBoxListLinearView",
    "DEFAULT_CHAT_FRAME", "Enum", "GameTooltip", "GetBuildInfo", "GetCurrentRegion",
    "GetCursorPosition", "GetItemInfoInstant", "GetLocale", "GetMoneyString",
    "GetNormalizedRealmName", "GetRealmName", "GetTime", "HideUIPanel", "IsShiftKeyDown",
    "GamepadMode", "InCombatLockdown", "InputUtil", "LibStub", "Minimap", "NUM_BAG_SLOTS", "NUM_TOTAL_EQUIPPED_BAG_SLOTS",
    "PanelTemplates_DeselectTab", "PanelTemplates_SelectTab", "PanelTemplates_TabResize",
    "SMART_NAV_INPUT_DIRECTION", "ScrollBoxConstants", "ScrollUtil", "SearchBoxTemplate_OnTextChanged", "Settings", "SettingsPanel",
    "SmartNavigation", "SmartNavigation_AddJumpNavigationOverride", "SmartNavigation_MarkFrameIgnored",
    "TSM_API", "TooltipDataProcessor", "UIParent", "UnitFactionGroup", "UnitGUID", "UnitName",
    "WOW_PROJECT_ID", "date", "debugprofilestop", "hooksecurefunc", "issecretvalue", "time", "tinsert",
}

files["WaylaidLedger/**/*.lua"] = {
    read_globals = wowGlobals,
    globals = { "UISpecialFrames" }, -- UI registers its Escape-to-close frame.
}
files["WaylaidLedger/Core.lua"] = {
    globals = { "WaylaidLedgerDB", "SlashCmdList", "SLASH_WAYLAIDLEDGER1", "SLASH_WAYLAIDLEDGER2" },
}

-- Tests replace WoW APIs and share explicit harness fixtures across chunks.
local testGlobals = {}
for _, name in ipairs(wowGlobals) do
    table.insert(testGlobals, name)
end
for _, name in ipairs({
    "AUCTIONATOR_L_TEMPORARY_LOWER_CASE", "AuctionatorTabs_Shopping", "SlashCmdList",
    "TEST_FRAMES", "TEST_SCANNER_FIXTURE", "UISpecialFrames", "WaylaidLedgerDB",
    "WaylaidLedgerFrame", "WaylaidLedgerReportFrame", "gsub", "strmatch", "strtrim",
}) do
    table.insert(testGlobals, name)
end
files["tests/**/*.lua"] = {
    globals = testGlobals,
    read_globals = { "LOCALIZATION_KEYS", "PROJECT_ROOT", "VERIFY_BOUNDS", "SHOPPING_SCAN", "UPSTREAM_AUCTIONATOR", "UPSTREAM_FOREVER_UI", "UPSTREAM_FOREVER_NAVIGATION", "UPSTREAM_TSM", "UPSTREAM_TSM_GROUP_IMPORT" },
}
