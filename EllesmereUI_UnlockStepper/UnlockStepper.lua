-------------------------------------------------------------------------------
--  EllesmereUI Unlock Stepper
--  Adds [-] and [+] buttons around every number box in the Unlock Mode cog
--  menu (Width, Height, X Position, Y Position, Offset X/Y, Extra W/H).
--    Click        : +/- 1
--    Shift+Click  : +/- 10
--    Hold         : repeats
--    Mouse wheel over the box : +/- 1 (Shift: 10)
--  A step writes the new number into the box and runs the box's own
--  OnEnterPressed, so the move goes through EllesmereUI's own commit path
--  (pixel-exact nudge, anchors, pending save) exactly like typing + Enter.
-------------------------------------------------------------------------------
if not EllesmereUI then return end

local BTN_W, BTN_H, GAP = 16, 18, 2
local REPEAT_DELAY, REPEAT_RATE = 0.40, 0.06

local function Accent()
    local g = EllesmereUI.ELLESMERE_GREEN
    if type(g) == "table" then
        return g.r or g[1] or 0.05, g.g or g[2] or 0.82, g.b or g[3] or 0.62
    end
    return 0.05, 0.82, 0.62
end

local function StepBox(box, dir)
    if not box or not box:IsShown() or not box:IsEnabled() then return end
    if InCombatLockdown() then return end
    local n = IsShiftKeyDown() and 10 or 1
    local v = tonumber(box:GetText()) or 0
    local nv = v + dir * n
    if box:IsNumeric() and nv < 1 then nv = 1 end   -- Width / Height
    box:SetText(tostring(nv))
    local fn = box:GetScript("OnEnterPressed")
    if fn then fn(box) end
end

local function StopRepeat(self)
    self:SetScript("OnUpdate", nil)
end

local function RepeatTick(self, elapsed)
    self._t = self._t + elapsed
    if self._t >= self._delay then
        self._t = 0
        self._delay = REPEAT_RATE
        if not IsMouseButtonDown("LeftButton") then return StopRepeat(self) end
        StepBox(self._box, self._dir)
    end
end

local function PaintBtn(btn, hover)
    local enabled = btn._box:IsEnabled()
    if not enabled then
        btn._bg:SetColorTexture(0, 0, 0, 0.25)
        btn._fs:SetTextColor(0.4, 0.4, 0.4, 0.7)
    elseif hover then
        local r, g, b = Accent()
        btn._bg:SetColorTexture(r, g, b, 0.25)
        btn._fs:SetTextColor(r, g, b, 1)
    else
        btn._bg:SetColorTexture(0, 0, 0, 0.4)
        btn._fs:SetTextColor(1, 1, 1, 0.9)
    end
end

local function MakeBtn(box, dir)
    local btn = CreateFrame("Button", nil, box)
    btn:SetSize(BTN_W, BTN_H)
    btn:EnableMouse(true)
    btn._box, btn._dir = box, dir
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    btn._bg = bg
    local fs = btn:CreateFontString(nil, "OVERLAY")
    local font = box:GetFont()
    fs:SetFont(font or STANDARD_TEXT_FONT, 12, "")
    fs:SetPoint("CENTER", 0, 1)
    fs:SetText(dir > 0 and "+" or "-")
    btn._fs = fs
    btn:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        StepBox(self._box, self._dir)
        self._t, self._delay = 0, REPEAT_DELAY
        self:SetScript("OnUpdate", RepeatTick)
    end)
    btn:SetScript("OnMouseUp", StopRepeat)
    btn:SetScript("OnHide", StopRepeat)
    btn:SetScript("OnEnter", function(self)
        PaintBtn(self, true)
        if EllesmereUI.ShowWidgetTooltip then
            EllesmereUI.ShowWidgetTooltip(self, "Click: 1 px   Shift+Click: 10 px\nHold to repeat, mouse wheel over the box also works")
        end
    end)
    btn:SetScript("OnLeave", function(self)
        PaintBtn(self, false)
        if EllesmereUI.HideWidgetTooltip then EllesmereUI.HideWidgetTooltip() end
    end)
    PaintBtn(btn, false)
    return btn
end

-- Pooled boxes are reused for different rows on every open, so the buttons
-- are attached once per box and always act on whatever the box does now.
local function DecorateBox(box, row)
    if not box._eusPlus then
        box._eusPlus  = MakeBtn(box,  1)
        box._eusMinus = MakeBtn(box, -1)
        box:EnableMouseWheel(true)
        box:SetScript("OnMouseWheel", function(self, delta)
            StepBox(self, delta > 0 and 1 or -1)
        end)
    end
    local plus, minus = box._eusPlus, box._eusMinus
    plus:ClearAllPoints()
    plus:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    box:ClearAllPoints()
    box:SetPoint("RIGHT", plus, "LEFT", -GAP, 0)
    minus:ClearAllPoints()
    minus:SetPoint("RIGHT", box, "LEFT", -GAP, 0)
    local lvl = box:GetFrameLevel() + 1
    plus:SetFrameLevel(lvl)
    minus:SetFrameLevel(lvl)
    PaintBtn(plus, plus:IsMouseOver())
    PaintBtn(minus, minus:IsMouseOver())
end

local function DecorateMenu(menu)
    local p = menu._pool
    if not p or not p.fields then return end
    for i = 1, #p.fields do
        local row = p.fields[i]
        local box = row and row._box
        if box and row:IsShown() and box:IsShown() then
            DecorateBox(box, row)
        end
    end
end

-- Cog menus are unnamed children of the unlock overlay, built lazily per
-- mover; they are recognised by the arrow-key hint they carry (_hintFS).
local hooked = {}
local function HookMenu(menu)
    if hooked[menu] then return end
    hooked[menu] = true
    menu:HookScript("OnShow", function(self)
        DecorateMenu(self)
        C_Timer.After(0, function() if self:IsShown() then DecorateMenu(self) end end)
    end)
    -- The menu can be rebuilt while open (anchor/match changes): re-check now and then.
    local acc = 0
    menu:HookScript("OnUpdate", function(self, elapsed)
        acc = acc + elapsed
        if acc >= 0.25 then acc = 0; DecorateMenu(self) end
    end)
    if menu:IsShown() then DecorateMenu(menu) end
end

local lastCount = -1
local function ScanOverlay(overlay)
    local n = overlay:GetNumChildren()
    if n == lastCount then return end
    lastCount = n
    for _, child in ipairs({ overlay:GetChildren() }) do
        if child._hintFS and not hooked[child] then HookMenu(child) end
    end
end

local watcher = CreateFrame("Frame")
local acc = 0
watcher:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.2 then return end
    acc = 0
    local overlay = _G.EllesmereUnlockMode
    if overlay and overlay:IsShown() then ScanOverlay(overlay) end
end)
