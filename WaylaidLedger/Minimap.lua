local _, addon = ...
local L = addon.L
addon.MinimapButton = {}
local Button = addon.MinimapButton

function Button.Position()
    if not Button.frame or not Minimap then
        return
    end
    local angle = math.rad(addon.db.minimap.angle)
    local x = math.cos(angle) * (Minimap:GetWidth() / 2 + 8)
    local y = math.sin(angle) * (Minimap:GetHeight() / 2 + 8)
    Button.frame:ClearAllPoints()
    Button.frame:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function Button.Update()
    if not Button.frame then
        return
    end
    Button.Position()
    Button.frame:SetShown(not addon.db.minimap.hide)
end

function Button.Create()
    if Button.frame or not Minimap then
        return
    end
    local frame = CreateFrame("Button", "WaylaidLedgerMinimapButton", Minimap)
    Button.frame = frame
    frame:SetSize(32, 32)
    frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:RegisterForDrag("LeftButton")
    frame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Crate_05")
    local border = frame:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    frame:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            addon.UI.ToggleSettings()
        else
            addon.UI.Toggle()
        end
    end)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Waylaid Ledger", 1, 0.82, 0)
        GameTooltip:AddLine(L["Left-click: open | Right-click: settings"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag to move around the minimap"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    frame:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            addon.db.minimap.angle = math.deg(math.atan2(y / scale - centerY, x / scale - centerX))
            Button.Position()
        end)
    end)
    frame:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    Button.Update()
end
