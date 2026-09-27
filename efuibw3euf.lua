--[[
================================================================================
  SHADOW UI  ::  v1.0
  ------------------------------------------------------------------------------
  A modern, resizable, inline-capable Drawing-based UI library for Matcha.
  Designed from scratch with reference to REM UI and INS-UI, but:
    - Dark glass aesthetic
    - Corner-drag resize handle
    - True in-line row layout
    - Scroll-wheel + scrollbar
    - Full config persistence
    - Icon font rendered from line segments (no image data)
  ------------------------------------------------------------------------------
  Load:  loadstring(game:HttpGet("<your gist raw url>"))()
  Use:   local UI = ShadowUI
================================================================================
--]]

local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")
local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()
local Camera        = workspace.CurrentCamera
local HttpService   = game:GetService("HttpService")

local Fonts         = Drawing.Fonts
local FontSystem    = Fonts.System
local FontBold      = Fonts.SystemBold
local FontMono      = Fonts.Monospace
local FontUI        = Fonts.UI
local FontPixel     = Fonts.Pixel

-- approximate per-character width multipliers, used for text fitting
local FontMetrics = {
    [FontSystem] = 0.48,
    [FontBold]   = 0.52,
    [FontUI]     = 0.50,
    [FontMono]   = 0.60,
    [FontPixel]  = 0.50,
}

-- ============================================================================
--  THEME  --  dark glass with subtle accent wash
-- ============================================================================

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function mix(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

local Themes = {
    {
        Name        = "Midnight",
        Base        = rgb(27, 30, 42),      -- window background
        Panel       = rgb(37, 41, 56),      -- control card background
        PanelHi     = rgb(48, 53, 70),      -- hover/active panel
        Stroke      = rgb(67, 73, 96),      -- panel borders
        Divider     = rgb(52, 57, 78),
        Text        = rgb(232, 234, 245),
        TextDim     = rgb(190, 195, 212),
        TextMuted   = rgb(140, 146, 168),
        AccentA     = rgb(120, 140, 255),
        AccentB     = rgb(180, 130, 255),
        Accent      = rgb(150, 135, 255),
        AccentDim   = rgb(96, 90, 180),
        Track       = rgb(58, 63, 84),
        TrackFill   = rgb(120, 140, 255),
        Danger      = rgb(255, 96, 120),
        Warning     = rgb(255, 190, 90),
        Success     = rgb(120, 230, 170),
    },
    {
        Name        = "Obsidian",
        Base        = rgb(25, 27, 34),
        Panel       = rgb(35, 37, 46),
        PanelHi     = rgb(47, 50, 61),
        Stroke      = rgb(63, 66, 81),
        Divider     = rgb(49, 51, 64),
        Text        = rgb(228, 228, 235),
        TextDim     = rgb(188, 190, 205),
        TextMuted   = rgb(139, 141, 157),
        AccentA     = rgb(120, 220, 210),
        AccentB     = rgb(90, 180, 240),
        Accent      = rgb(105, 200, 225),
        AccentDim   = rgb(70, 130, 160),
        Track       = rgb(56, 58, 72),
        TrackFill   = rgb(120, 220, 210),
        Danger      = rgb(255, 90, 110),
        Warning     = rgb(255, 180, 80),
        Success     = rgb(110, 220, 160),
    },
    {
        Name        = "Burgundy",
        Base        = rgb(38, 23, 30),
        Panel       = rgb(50, 30, 39),
        PanelHi     = rgb(64, 38, 49),
        Stroke      = rgb(87, 52, 65),
        Divider     = rgb(65, 39, 50),
        Text        = rgb(245, 232, 235),
        TextDim     = rgb(180, 150, 160),
        TextMuted   = rgb(120, 90, 100),
        AccentA     = rgb(255, 130, 150),
        AccentB     = rgb(255, 90, 140),
        Accent      = rgb(255, 110, 145),
        AccentDim   = rgb(160, 70, 95),
        Track       = rgb(48, 30, 38),
        TrackFill   = rgb(255, 130, 150),
        Danger      = rgb(255, 80, 80),
        Warning     = rgb(255, 190, 90),
        Success     = rgb(140, 220, 160),
    },
}

-- ============================================================================
--  LAYOUT CONSTANTS  --  all spatial values live here so they can be tweaked
-- ============================================================================

local Layout = {
    -- window
    WindowW         = 700,
    WindowH         = 500,
    WindowMinW      = 500,
    WindowMinH      = 340,
    Corner          = 12,
    TopbarH         = 44,
    TabRailW        = 172,
    TabRailMinW     = 52,
    TabRailNarrow   = 52,

    -- tab / section
    TabRowH         = 34,
    TabIcon         = 16,
    SectionH        = 22,
    SectionGap      = 8,

    -- content
    ContentPadX     = 18,
    ContentPadY     = 14,
    ContentGapY     = 10,

    -- row / column
    RowHeight       = 28,
    RowColumnGap    = 8,
    RowGapY         = 7,

    -- controls
    ToggleW         = 38,
    ToggleH         = 20,
    ToggleKnob      = 14,

    SliderH         = 6,
    SliderKnob      = 6,

    ButtonH         = 28,
    FieldH          = 26,
    DropdownH       = 28,
    DividerH        = 1,

    -- font sizes
    TitleSize       = 14,
    TextSize        = 13,
    SmallSize       = 12,
    TinySize        = 11,

    -- scroll
    ScrollSpeed     = 30,
    ScrollbarW      = 4,

    -- animations
    AnimFast        = 18,
    AnimMed         = 12,
    AnimSlow        = 8,

    -- resize handle
    ResizeGrab      = 12,
}

-- ============================================================================
--  DRAWING POOL  --  reuse Drawing objects, no allocation churn per frame
-- ============================================================================

local Pool = {
    Square   = {},
    Text     = {},
    Line     = {},
    Circle   = {},
    Triangle = {},
    Image    = {},
}

local PoolCache = {
    Square   = {},
    Text     = {},
    Line     = {},
    Circle   = {},
    Triangle = {},
    Image    = {},
}

local PoolUsed  = { Square = 0, Text = 0, Line = 0, Circle = 0, Triangle = 0, Image = 0 }
local PoolMade  = { Square = 0, Text = 0, Line = 0, Circle = 0, Triangle = 0, Image = 0 }
local DrawOrder = 0

local function Layer(z)
    DrawOrder = DrawOrder + 1
    return z * 100000 + DrawOrder
end

local function Take(kind)
    local idx = PoolUsed[kind] + 1
    PoolUsed[kind] = idx

    local obj = Pool[kind][idx]
    local last = PoolCache[kind][idx]

    if not obj then
        obj = Drawing.new(kind)
        last = {}
        Pool[kind][idx] = obj
        PoolCache[kind][idx] = last
    end

    if idx > PoolMade[kind] then PoolMade[kind] = idx end
    if not last.Visible then last.Visible = true; obj.Visible = true end

    return obj, last
end

local function ResetPool()
    for k in pairs(PoolUsed) do PoolUsed[k] = 0 end
    DrawOrder = 0
end

local function HideUnused()
    for kind, list in pairs(Pool) do
        local cache = PoolCache[kind]
        for i = PoolUsed[kind] + 1, PoolMade[kind] do
            if cache[i] and cache[i].Visible then
                cache[i].Visible = false
                list[i].Visible = false
            end
        end
    end
end

local function ClearPool()
    for kind, list in pairs(Pool) do
        for i, obj in ipairs(list) do
            pcall(function() obj:Remove() end)
        end
        Pool[kind] = {}
        PoolCache[kind] = {}
        PoolUsed[kind] = 0
        PoolMade[kind] = 0
    end
end

-- ============================================================================
--  PRIMITIVE DRAWERS  --  every visual element goes through one of these
-- ============================================================================

local FrameAlpha = 1  -- global fade multiplier used during open/close

local function Rect(x, y, w, h, color, z, corner, alpha)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color then l.Color = color; o.Color = color end
    if not l.Filled then l.Filled = true; o.Filled = true end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = 1 - a end
end

local function Stroke(x, y, w, h, color, z, corner, alpha)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color then l.Color = color; o.Color = color end
    if l.Filled ~= false then l.Filled = false; o.Filled = false end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = 1 - a end
end

local function Line(x1, y1, x2, y2, color, z, thickness, alpha)
    local o, l = Take("Line")
    local depth = Layer(z)

    if l.X1 ~= x1 or l.Y1 ~= y1 then l.X1, l.Y1 = x1, y1; o.From = Vector2.new(x1, y1) end
    if l.X2 ~= x2 or l.Y2 ~= y2 then l.X2, l.Y2 = x2, y2; o.To = Vector2.new(x2, y2) end
    if l.Color ~= color then l.Color = color; o.Color = color end
    if l.Thickness ~= thickness then l.Thickness = thickness; o.Thickness = thickness end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = 1 - a end
end

local function Circle(x, y, radius, color, z, filled, thickness, sides, alpha)
    local o, l = Take("Circle")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.Radius ~= radius then l.Radius = radius; o.Radius = radius end
    if l.Color ~= color then l.Color = color; o.Color = color end
    if l.Filled ~= filled then l.Filled = filled; o.Filled = filled end
    if l.Thickness ~= thickness then l.Thickness = thickness; o.Thickness = thickness end
    if l.Sides ~= sides then l.Sides = sides; o.NumSides = sides end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = 1 - a end
end

local function Triangle(ax, ay, bx, by, cx, cy, color, z, alpha)
    local o, l = Take("Triangle")
    local depth = Layer(z)

    if l.AX ~= ax or l.AY ~= ay then l.AX, l.AY = ax, ay; o.PointA = Vector2.new(ax, ay) end
    if l.BX ~= bx or l.BY ~= by then l.BX, l.BY = bx, by; o.PointB = Vector2.new(bx, by) end
    if l.CX ~= cx or l.CY ~= cy then l.CX, l.CY = cx, cy; o.PointC = Vector2.new(cx, cy) end
    if l.Color ~= color then l.Color = color; o.Color = color end
    if not l.Filled then l.Filled = true; o.Filled = true end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = 1 - a end
end

local function Bar(x1, y1, x2, y2, thickness, color, z, alpha)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return end
    local px, py = -dy / len * thickness / 2, dx / len * thickness / 2
    Triangle(x1 + px, y1 + py, x1 - px, y1 - py, x2 - px, y2 - py, color, z, alpha)
    Triangle(x1 + px, y1 + py, x2 - px, y2 - py, x2 + px, y2 + py, color, z, alpha)
end

local function TextWidth(text, size, font)
    return #text * size * (FontMetrics[font] or 0.5)
end

local function TrimText(text, room, size, font)
    local fit = math.floor(room / (size * (FontMetrics[font] or 0.5)))
    if #text <= fit then return text end
    if fit <= 2 then return "" end
    return string.sub(text, 1, fit - 2) .. ".."
end

local function TextMidY(y, h, size)
    return math.floor(y + (h - size) / 2 + 0.5)
end

local function Text(text, x, y, color, size, font, z, alpha, room, center)
    if room then text = TrimText(text, room, size, font) end
    if text == "" then DrawOrder = DrawOrder + 1; return end

    local o, l = Take("Text")
    local depth = Layer(z + 0.5)

    if l.Text ~= text then l.Text = text; o.Text = text end
    if l.Color ~= color then l.Color = color; o.Color = color end
    if l.Font ~= font then l.Font = font; o.Font = font end
    if l.Size ~= size then l.Size = size; o.Size = size end
    if l.Outline ~= false then l.Outline = false; o.Outline = false end
    if l.Center ~= (center or false) then l.Center = center; o.Center = center end
    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = 1 - a end
end

local function TextCenter(text, cx, y, color, size, font, z, alpha, room)
    if room then text = TrimText(text, room, size, font) end
    if text == "" then return end
    local w = TextWidth(text, size, font)
    Text(text, cx - w / 2, y, color, size, font, z, alpha, nil, false)
end

-- horizontal gradient rectangle: steps of solid color
local function GradientRect(x, y, w, h, first, second, z, alpha, steps)
    steps = steps or 18
    local prev = math.floor(x + 0.5)
    for i = 1, steps do
        local nxt = math.floor(x + w * i / steps + 0.5)
        local slice = math.max(1, nxt - prev)
        Rect(prev, y, slice, h, mix(first, second, (i - 0.5) / steps), z, 0, alpha)
        prev = nxt
    end
end

-- ============================================================================
--  ICON FONT  --  line segments drawn in a 20x20 space, Stroke-based
-- ============================================================================
-- Each icon is a list of segments: {x1, y1, x2, y2, thickness, alpha}
-- Coordinates are in a 20x20 grid. At draw time we scale to target size.
-- Add to this table freely. Names are case-insensitive keys.

local Icons = {
    -- one-segment straight glyphs
    ["minus"]     = { {4,10, 16,10, 1.8, 1} },
    ["plus"]      = { {10,4, 10,16, 1.8, 1}, {4,10, 16,10, 1.8, 1} },
    ["close"]     = { {5,5, 15,15, 1.8, 1}, {15,5, 5,15, 1.8, 1} },
    ["check"]     = { {4,10, 9,15, 2, 1},   {9,15, 16,5, 2, 1} },
    ["chevron-down"]  = { {5,8, 10,13, 1.8, 1}, {10,13, 15,8, 1.8, 1} },
    ["chevron-up"]    = { {5,12, 10,7, 1.8, 1}, {10,7, 15,12, 1.8, 1} },
    ["chevron-right"] = { {8,5, 13,10, 1.8, 1}, {13,10, 8,15, 1.8, 1} },
    ["chevron-left"]  = { {12,5, 7,10, 1.8, 1}, {7,10, 12,15, 1.8, 1} },
    ["arrow-right"]   = { {4,10, 15,10, 1.8, 1}, {11,6, 15,10, 1.8, 1}, {15,10, 11,14, 1.8, 1} },
    ["arrow-left"]    = { {16,10, 5,10, 1.8, 1}, {9,6, 5,10, 1.8, 1},   {5,10, 9,14, 1.8, 1} },
    ["menu"]          = { {4,6, 16,6, 1.8, 1}, {4,10, 16,10, 1.8, 1}, {4,14, 16,14, 1.8, 1} },

    -- window glyphs
    ["window"]    = { {4,5, 16,5, 1.6, 1}, {4,5, 4,15, 1.6, 1}, {16,5, 16,15, 1.6, 1}, {4,15, 16,15, 1.6, 1}, {4,9, 16,9, 1.6, 1} },
    ["home"]      = { {3,10, 10,3, 1.8, 1}, {10,3, 17,10, 1.8, 1}, {5,10, 5,17, 1.8, 1}, {5,17, 15,17, 1.8, 1}, {15,17, 15,10, 1.8, 1} },
    ["gear"]      = {
        {10,3, 10,5, 1.6, 1}, {10,15, 10,17, 1.6, 1},
        {3,10, 5,10, 1.6, 1}, {15,10, 17,10, 1.6, 1},
        {5.2,5.2, 6.6,6.6, 1.5, 1}, {13.4,13.4, 14.8,14.8, 1.5, 1},
        {5.2,14.8, 6.6,13.4, 1.5, 1}, {14.8,5.2, 13.4,6.6, 1.5, 1},
        {10,6.5, 13.5,10, 1.6, 0.9}, {13.5,10, 10,13.5, 1.6, 0.9},
        {10,13.5, 6.5,10, 1.6, 0.9}, {6.5,10, 10,6.5, 1.6, 0.9},
    },
    ["folder"]    = { {3,6, 3,16, 1.6, 1}, {3,6, 8,6, 1.6, 1}, {8,6, 8,8, 1.6, 1}, {8,8, 17,8, 1.6, 1}, {17,8, 17,16, 1.6, 1}, {3,16, 17,16, 1.6, 1} },
    ["file"]      = { {5,3, 5,17, 1.6, 1}, {5,3, 13,3, 1.6, 1}, {13,3, 15,5, 1.6, 1}, {15,5, 15,17, 1.6, 1}, {15,17, 5,17, 1.6, 1}, {13,3, 13,5, 1.6, 1}, {13,5, 15,5, 1.6, 1} },

    -- UI glyphs
    ["user"]      = { {10,4, 10,4.5, 1.8, 1}, {7,7, 13,7, 1.6, 1}, {7,7, 7,10, 1.6, 1}, {13,7, 13,10, 1.6, 1}, {7,10, 13,10, 1.6, 1}, {5,17, 10,12, 1.6, 1}, {15,17, 10,12, 1.6, 1}, {5,17, 15,17, 1.6, 1} },
    ["shield"]    = { {10,3, 16,5, 1.6, 1}, {16,5, 16,10, 1.6, 1}, {16,10, 10,17, 1.6, 1}, {10,17, 4,10, 1.6, 1}, {4,10, 4,5, 1.6, 1}, {4,5, 10,3, 1.6, 1} },
    ["bell"]      = { {6,9, 6,14, 1.6, 1}, {14,9, 14,14, 1.6, 1}, {6,9, 10,4, 1.6, 1}, {10,4, 14,9, 1.6, 1}, {4,14, 16,14, 1.6, 1}, {9,16, 11,16, 1.6, 1} },
    ["eye"]       = { {2,10, 6,6, 1.6, 1}, {6,6, 14,6, 1.6, 1}, {14,6, 18,10, 1.6, 1}, {18,10, 14,14, 1.6, 1}, {14,14, 6,14, 1.6, 1}, {6,14, 2,10, 1.6, 1}, {8,8, 12,12, 1.4, 1}, {12,8, 8,12, 1.4, 1} },
    ["search"]    = { {3,3, 12,3, 1.6, 1}, {12,3, 12,12, 1.6, 1}, {12,12, 3,12, 1.6, 1}, {3,12, 3,3, 1.6, 1}, {12,12, 17,17, 2, 1} },
    ["crosshair"] = { {10,3, 10,6, 1.5, 1}, {10,14, 10,17, 1.5, 1}, {3,10, 6,10, 1.5, 1}, {14,10, 17,10, 1.5, 1}, {6,6, 14,14, 1.3, 0.8}, {14,6, 6,14, 1.3, 0.8}, {7,7, 13,7, 1.2, 0.7}, {7,13, 13,13, 1.2, 0.7}, {7,7, 7,13, 1.2, 0.7}, {13,7, 13,13, 1.2, 0.7} },

    -- action glyphs
    ["play"]      = { {6,4, 6,16, 1.8, 1}, {6,4, 16,10, 1.8, 1}, {6,16, 16,10, 1.8, 1} },
    ["pause"]     = { {7,4, 7,16, 1.8, 1}, {13,4, 13,16, 1.8, 1} },
    ["stop"]      = { {5,5, 15,5, 1.8, 1}, {15,5, 15,15, 1.8, 1}, {15,15, 5,15, 1.8, 1}, {5,15, 5,5, 1.8, 1} },
    ["refresh"]   = { {5,6, 10,4, 1.6, 1}, {10,4, 15,6, 1.6, 1}, {15,6, 16,11, 1.6, 1}, {16,11, 13,15, 1.6, 1}, {13,15, 8,16, 1.6, 1}, {8,16, 4,13, 1.6, 1} },
    ["download"]  = { {10,3, 10,13, 1.8, 1}, {6,9, 10,13, 1.8, 1}, {14,9, 10,13, 1.8, 1}, {5,16, 15,16, 1.8, 1} },
    ["upload"]    = { {10,17, 10,7, 1.8, 1}, {6,11, 10,7, 1.8, 1}, {14,11, 10,7, 1.8, 1}, {5,4, 15,4, 1.8, 1} },
    ["trash"]     = { {5,5, 5,17, 1.6, 1}, {15,5, 15,17, 1.6, 1}, {5,17, 15,17, 1.6, 1}, {5,5, 15,5, 1.6, 1}, {7,5, 7,3, 1.6, 1}, {13,5, 13,3, 1.6, 1}, {7,3, 13,3, 1.6, 1} },
    ["edit"]      = { {5,15, 7,9, 1.6, 1}, {7,9, 15,3, 1.6, 1}, {15,3, 17,5, 1.6, 1}, {17,5, 9,11, 1.6, 1}, {9,11, 5,15, 1.6, 1}, {5,15, 3,17, 1.6, 1}, {3,17, 5,17, 1.6, 1} },

    -- status glyphs
    ["info"]      = { {10,3, 10,3.5, 1.8, 1}, {10,6, 10,16, 1.6, 1} },
    ["warning"]   = { {10,3, 17,16, 1.6, 1}, {17,16, 3,16, 1.6, 1}, {3,16, 10,3, 1.6, 1}, {10,8, 10,12, 1.6, 1}, {10,14, 10,14.5, 1.6, 1} },
    ["error"]     = { {10,3, 10,3.5, 1.8, 1}, {10,5, 10,13, 1.6, 1}, {10,15, 10,15.5, 1.6, 1} },
    ["success"]   = { {10,3, 10,3.5, 1.8, 1}, {7,10, 9,12, 1.8, 1}, {9,12, 14,5, 1.8, 1} },

    -- misc
    ["star"]      = { {10,3, 11.5,8, 1.5, 1}, {11.5,8, 17,8, 1.5, 1}, {17,8, 12.5,11.5, 1.5, 1}, {12.5,11.5, 14.5,17, 1.5, 1}, {14.5,17, 10,13.5, 1.5, 1}, {10,13.5, 5.5,17, 1.5, 1}, {5.5,17, 7.5,11.5, 1.5, 1}, {7.5,11.5, 3,8, 1.5, 1}, {3,8, 8.5,8, 1.5, 1}, {8.5,8, 10,3, 1.5, 1} },
    ["heart"]     = { {10,6, 7,3.5, 1.6, 1}, {7,3.5, 4,3.5, 1.6, 1}, {4,3.5, 3,7, 1.6, 1}, {3,7, 4,10.5, 1.6, 1}, {4,10.5, 10,17, 1.6, 1}, {10,17, 16,10.5, 1.6, 1}, {16,10.5, 17,7, 1.6, 1}, {17,7, 16,3.5, 1.6, 1}, {16,3.5, 13,3.5, 1.6, 1}, {13,3.5, 10,6, 1.6, 1} },
    ["lock"]      = { {6,9, 6,17, 1.6, 1}, {14,9, 14,17, 1.6, 1}, {6,17, 14,17, 1.6, 1}, {6,9, 14,9, 1.6, 1}, {7,9, 7,6, 1.6, 1}, {13,9, 13,6, 1.6, 1}, {7,6, 9,3, 1.6, 1}, {9,3, 11,3, 1.6, 1}, {11,3, 13,6, 1.6, 1} },
    ["unlock"]    = { {6,9, 6,17, 1.6, 1}, {14,9, 14,17, 1.6, 1}, {6,17, 14,17, 1.6, 1}, {6,9, 14,9, 1.6, 1}, {7,9, 7,6, 1.6, 1}, {7,6, 11,3, 1.6, 1}, {11,3, 13,4, 1.6, 1} },
    ["power"]     = { {10,3, 10,10, 1.8, 1}, {5,6, 3,10, 1.6, 1}, {3,10, 5,15, 1.6, 1}, {5,15, 10,17, 1.6, 1}, {10,17, 15,15, 1.6, 1}, {15,15, 17,10, 1.6, 1}, {17,10, 15,6, 1.6, 1}, {15,6, 10,4, 1.6, 1} },
    ["settings-sliders"] = { {3,5, 17,5, 1.5, 1}, {3,10, 17,10, 1.5, 1}, {3,15, 17,15, 1.5, 1}, {6,3, 6,7, 1.7, 1}, {13,8, 13,12, 1.7, 1}, {8,13, 8,17, 1.7, 1} },
}

-- case-insensitive lookup
local IconIndex = {}
for name, data in pairs(Icons) do
    IconIndex[string.lower(name)] = data
end

local function DrawIconByName(name, x, y, size, color, z, alpha, thickness)
    if not name then return false end
    local data = IconIndex[string.lower(name)]
    if not data then return false end

    local scale = size / 20
    local defaultThick = thickness or 1.5
    alpha = alpha or 1

    for _, seg in ipairs(data) do
        local x1 = x + seg[1] * scale
        local y1 = y + seg[2] * scale
        local x2 = x + seg[3] * scale
        local y2 = y + seg[4] * scale
        local thick = (seg[5] or defaultThick) * (size / 20) * 2
        local segA = (seg[6] or 1) * alpha
        Bar(x1, y1, x2, y2, thick, color, z, segA)
    end

    return true
end

-- ============================================================================
--  TWEEN  --  exponential approach, all animated state uses this
-- ============================================================================

local NoAnim = false

local function Approach(current, target, speed, dt)
    if NoAnim then return target end
    return current + (target - current) * (1 - math.exp(-speed * (dt or (1 / 60))))
end

local function Snap(current, target, speed, epsilon, dt)
    local v = Approach(current, target, speed, dt)
    if math.abs(v - target) < epsilon then return target end
    return v
end

-- ============================================================================
--  PART 1 COMPLETE
--  Next: PART 2 -- input system, key map, text editing, capture
-- ============================================================================

-- ============================================================================
--  INPUT  --  mouse state, key state, per-frame snapshot
-- ============================================================================

local Input = {
    X = 0, Y = 0,
    PrevX = 0, PrevY = 0,
    DX = 0, DY = 0,

    Down = false,       -- left mouse held
    RightDown = false,  -- right mouse held
    MidDown = false,    -- middle mouse held

    Click = false,      -- left click this frame
    RightClick = false, -- right click this frame
    MidClick = false,   -- middle click this frame

    Up = false,         -- left mouse released this frame
    Wheel = 0,          -- wheel delta this frame
}

local PrevMouseState = { L = false, R = false, M = false }
local PrevWheel = 0

local function ReadInput()
    Input.PrevX, Input.PrevY = Input.X, Input.Y
    Input.X, Input.Y = Mouse.X, Mouse.Y
    Input.DX = Input.X - Input.PrevX
    Input.DY = Input.Y - Input.PrevY

    local l, r, m = false, false, false

    pcall(function() l = ismouse1pressed() end)
    pcall(function() r = ismouse2pressed() end)
    pcall(function()
        -- middle button via raw keycode
        m = iskeypressed(0x04)
    end)

    Input.Down      = l
    Input.RightDown = r
    Input.MidDown   = m

    Input.Click      = l and not PrevMouseState.L
    Input.RightClick = r and not PrevMouseState.R
    Input.MidClick   = m and not PrevMouseState.M

    Input.Up = (not l) and PrevMouseState.L

    PrevMouseState.L = l
    PrevMouseState.R = r
    PrevMouseState.M = m

    -- wheel: executors expose this differently. Try common names.
    local wheel = 0
    pcall(function()
        if mousewheel then wheel = mousewheel() end
    end)
    pcall(function()
        if getwheel then wheel = getwheel() end
    end)

    Input.Wheel = wheel - PrevWheel
    PrevWheel = wheel
end

local function MouseIn(x, y, w, h)
    return Input.X >= x and Input.X <= x + w
       and Input.Y >= y and Input.Y <= y + h
end

local function MouseInCircle(cx, cy, radius)
    local dx = Input.X - cx
    local dy = Input.Y - cy
    return (dx * dx + dy * dy) <= (radius * radius)
end

-- ============================================================================
--  KEY MAP  --  name <-> virtual code, held/click state
-- ============================================================================

local Keys = {}
local KeyList = {}

local function AddKey(name, code, char, shifted)
    local entry = {
        Name    = name,
        Code    = code,
        Char    = char,
        Shifted = shifted,
        Held    = false,
        Click   = false,
    }
    Keys[name] = entry
    KeyList[#KeyList + 1] = entry
end

-- mouse buttons (executor-specific, but iskeypressed may accept these on some)
AddKey("MB1", 0x01)
AddKey("MB2", 0x02)
AddKey("MB3", 0x04)
AddKey("MB4", 0x05)
AddKey("MB5", 0x06)

-- control keys
AddKey("Backspace",  0x08)
AddKey("Tab",        0x09)
AddKey("Enter",      0x0D)
AddKey("Shift",      0x10)
AddKey("Ctrl",       0x11)
AddKey("Alt",        0x12)
AddKey("Pause",      0x13)
AddKey("Caps",       0x14)
AddKey("Escape",     0x1B)
AddKey("Space",      0x20, " ", " ")

AddKey("PageUp",     0x21)
AddKey("PageDown",   0x22)
AddKey("End",        0x23)
AddKey("Home",       0x24)
AddKey("Left",       0x25)
AddKey("Up",         0x26)
AddKey("Right",      0x27)
AddKey("Down",       0x28)
AddKey("Insert",     0x2D)
AddKey("Delete",     0x2E)

AddKey("LeftShift",  0xA0)
AddKey("RightShift", 0xA1)
AddKey("LeftCtrl",   0xA2)
AddKey("RightCtrl",  0xA3)

AddKey("Num0", 0x60)
AddKey("Num1", 0x61)
AddKey("Num2", 0x62)
AddKey("Num3", 0x63)
AddKey("Num4", 0x64)
AddKey("Num5", 0x65)
AddKey("Num6", 0x66)
AddKey("Num7", 0x67)
AddKey("Num8", 0x68)
AddKey("Num9", 0x69)

-- letters
for i = 0, 25 do
    local lower = string.char(97 + i)
    local upper = string.upper(lower)
    AddKey(upper, 0x41 + i, lower, upper)
end

-- numbers (top row)
local shiftedNums = { ")", "!", "@", "#", "$", "%", "^", "&", "*", "(" }
for i = 0, 9 do
    AddKey("N" .. i, 0x30 + i, tostring(i), shiftedNums[i + 1])
end

-- function keys
for i = 1, 12 do
    AddKey("F" .. i, 0x6F + i)
end

-- punctuation
AddKey("Minus",    0xBD, "-", "_")
AddKey("Equals",   0xBB, "=", "+")
AddKey("LBracket", 0xDB, "[", "{")
AddKey("RBracket", 0xDD, "]", "}")
AddKey("Semicolon",0xBA, ";", ":")
AddKey("Quote",    0xDE, "'", "\"")
AddKey("Comma",    0xBC, ",", "<")
AddKey("Period",   0xBE, ".", ">")
AddKey("Slash",    0xBF, "/", "?")
AddKey("Backslash",0xDC, "\\", "|")
AddKey("Grave",    0xC0, "`", "~")

local function ReadKeys()
    for i = 1, #KeyList do
        local k = KeyList[i]
        local held = false
        pcall(function() held = iskeypressed(k.Code) end)
        k.Click = held and not k.Held
        k.Held = held
    end
end

local function AnyKeyClicked()
    for i = 1, #KeyList do
        local k = KeyList[i]
        if k.Click and k.Name ~= "Shift" and k.Name ~= "Ctrl"
           and k.Name ~= "Alt" and k.Name ~= "LeftShift"
           and k.Name ~= "RightShift" and k.Name ~= "LeftCtrl"
           and k.Name ~= "RightCtrl" then
            return k
        end
    end
    return nil
end

-- ============================================================================
--  KEY NAME  --  display formatting for keybind chips
-- ============================================================================

local KeyLabel = {}
local KeyAlias = {
    mb1 = "MB1", mb2 = "MB2", mb3 = "MB3", mb4 = "MB4", mb5 = "MB5",
    mouse1 = "MB1", mousebutton1 = "MB1", lmb = "MB1",
    mouse2 = "MB2", mousebutton2 = "MB2", rmb = "MB2",
    escape = "Esc", ["return"] = "Enter", control = "Ctrl",
    pgup = "PgUp", pgdn = "PgDn", space = "Space",
    leftshift = "LShift", rightshift = "RShift",
    leftctrl = "LCtrl", rightctrl = "RCtrl",
}

function KeyLabel.Format(value)
    if not value or value == "" then return "none" end
    local parts = {}
    for segment in string.gmatch(value, "[^+]+") do
        parts[#parts + 1] = segment
    end
    for i = 1, #parts do
        local lower = string.lower(parts[i])
        parts[i] = KeyAlias[lower] or string.upper(parts[i])
    end
    return table.concat(parts, "+")
end

-- ============================================================================
--  TEXT EDITOR  --  per-frame handler for any focused text field
-- ============================================================================

local TextEditor = {}
local RepeatDelay = 0.4
local RepeatRate  = 0.03

local CurrentRepeatKey = nil
local NextRepeatAt = 0

local function RepeatHeld(key)
    local now = os.clock()
    if key.Click then
        CurrentRepeatKey = key
        NextRepeatAt = now + RepeatDelay
        return true
    end
    if not key.Held then return false end
    if CurrentRepeatKey ~= key then return false end
    if now < NextRepeatAt then return false end
    NextRepeatAt = now + RepeatRate
    return true
end

local function ShiftHeld()
    return Keys.Shift.Held or Keys.LeftShift.Held or Keys.RightShift.Held
end

local function CtrlHeld()
    return Keys.Ctrl.Held or Keys.LeftCtrl.Held or Keys.RightCtrl.Held
end

local function TypedChar()
    local shifted = ShiftHeld()
    for i = 1, #KeyList do
        local k = KeyList[i]
        if k.Char and RepeatHeld(k) then
            return shifted and k.Shifted or k.Char
        end
    end
    return nil
end

-- Process one field's state. row must have: .Value (string), .Caret (int), .Anchor (int/nil)
-- allowed: optional pattern (e.g. "%d" for digits only)
-- onCommit: optional function called when Enter/Escape is pressed
local function ProcessText(row, allowed, onCommit)
    local value  = row.Value  or ""
    local caret  = math.min(math.max(row.Caret or #value, 0), #value)
    local anchor = row.Anchor and math.min(math.max(row.Anchor, 0), #value) or nil
    local selected = anchor ~= nil and anchor ~= caret
    local low  = selected and math.min(anchor, caret) or caret
    local high = selected and math.max(anchor, caret) or caret

    local function Commit(text, newCaret)
        row.Value  = text
        row.Caret  = newCaret
        row.Anchor = nil
    end

    -- Ctrl shortcuts
    if CtrlHeld() then
        if Keys.A.Click then row.Anchor, row.Caret = 0, #value; Keys.A.Click = false end
        if Keys.C.Click and selected then
            pcall(setclipboard, string.sub(value, low + 1, high))
            Keys.C.Click = false
        end
        if Keys.X.Click and selected then
            pcall(setclipboard, string.sub(value, low + 1, high))
            Commit(string.sub(value, 1, low) .. string.sub(value, high + 1), low)
            Keys.X.Click = false
        end
        if Keys.V.Click then
            local clip = nil
            pcall(function() clip = getclipboard() end)
            if clip and clip ~= "" then
                if allowed then
                    local filtered = ""
                    for i = 1, #clip do
                        local c = string.sub(clip, i, i)
                        if string.match(c, allowed) then filtered = filtered .. c end
                    end
                    clip = filtered
                end
                Commit(
                    string.sub(value, 1, low) .. clip .. string.sub(value, high + 1),
                    low + #clip
                )
            end
            Keys.V.Click = false
        end
    end

    -- caret navigation
    local step = Keys.Left.Click and -1 or (Keys.Right.Click and 1) or nil
    local jump = Keys.Home.Click and 0 or (Keys.End.Click and #value) or nil

    if step or jump then
        local moved = jump
        if step then
            if selected and not ShiftHeld() then
                moved = step < 0 and low or high
            else
                moved = math.min(math.max(caret + step, 0), #value)
            end
        end
        row.Anchor = ShiftHeld() and (anchor or caret) or nil
        row.Caret  = moved

        Keys.Left.Click  = false
        Keys.Right.Click = false
        Keys.Home.Click  = false
        Keys.End.Click   = false
    end

    -- enter / escape
    if Keys.Enter.Click or Keys.Escape.Click then
        if onCommit then onCommit(value) end
        return "done"
    end

    -- delete
    if RepeatHeld(Keys.Backspace) then
        if selected then
            Commit(string.sub(value, 1, low) .. string.sub(value, high + 1), low)
        elseif caret > 0 then
            Commit(string.sub(value, 1, caret - 1) .. string.sub(value, caret + 1), caret - 1)
        end
        return "edit"
    end

    if RepeatHeld(Keys.Delete) then
        if selected then
            Commit(string.sub(value, 1, low) .. string.sub(value, high + 1), low)
        elseif caret < #value then
            Commit(string.sub(value, 1, caret) .. string.sub(value, caret + 2), caret)
        end
        return "edit"
    end

    -- normal character
    local c = TypedChar()
    if not c then return nil end
    if allowed and not string.match(c, allowed) then return nil end
    Commit(
        string.sub(value, 1, low) .. c .. string.sub(value, high + 1),
        low + 1
    )
    return "edit"
end

-- ============================================================================
--  CAPTURE  --  listen for a keypress and set it on a bind object
-- ============================================================================

local Capture = {
    Active = nil,   -- { Target = bind, OnSet = function(name) }
}

local function BeginCapture(bind, onSet)
    Capture.Active = { Target = bind, OnSet = onSet }
end

local function CancelCapture()
    Capture.Active = nil
end

local function UpdateCapture()
    if not Capture.Active then return end

    -- Escape cancels
    if Keys.Escape.Click then
        Capture.Active = nil
        return
    end

    local hit = AnyKeyClicked()
    if not hit then return end

    local name = string.lower(hit.Name)
    local target = Capture.Active
    Capture.Active = nil

    if target.OnSet then
        target.OnSet(name)
    end
end

-- ============================================================================
--  FOCUS  --  single active text field at a time
-- ============================================================================

local Focus = {
    Field = nil,   -- { Value, Caret, Anchor, Allowed, OnCommit, OnBlur }
}

local function SetFocus(field)
    if Focus.Field == field then return end
    if Focus.Field and Focus.Field.OnBlur then Focus.Field.OnBlur() end
    Focus.Field = field
    if field then
        field.Caret  = field.Caret or #(field.Value or "")
        field.Anchor = nil
    end
end

local function ClearFocus()
    if Focus.Field and Focus.Field.OnBlur then Focus.Field.OnBlur() end
    Focus.Field = nil
end

local function TickFocus()
    if not Focus.Field then return end
    local result = ProcessText(Focus.Field, Focus.Field.Allowed, Focus.Field.OnCommit)
    if result == "done" then ClearFocus() end
end

-- ============================================================================
--  STATE  --  shared UI state table, all modules read/write this
-- ============================================================================

local State = {
    -- window
    X = 100, Y = 100,
    W = Layout.WindowW,
    H = Layout.WindowH,
    Visible = 1,          -- 0..1 animation
    Open = true,

    -- drag / resize
    Drag        = nil,    -- { GrabX, GrabY }
    Resize      = nil,    -- { Edge, GrabX, GrabY, StartW, StartH, StartX, StartY }
    DragSpeed   = 20,

    -- tabs
    Tabs        = {},
    ActiveIndex = 1,
    RailOpen    = 0,      -- 0 = narrow, 1 = full
    RailPinned  = false,

    -- scrolling
    Scroll      = {},     -- per-tab scroll offset

    -- popups
    Popup       = nil,    -- currently open dropdown / picker / etc.

    -- lifecycle
    Alive       = true,
    Frame       = 0,
    Delta       = 1 / 60,
    LastTick    = os.clock(),

    -- global animation toggle
    NoAnim      = false,

    -- hotkeys
    MenuKey     = "p",

    -- config
    ConfigFile  = "ShadowUI_config.json",

    -- theme
    Theme       = Themes[1],
    ThemeIndex  = 1,
    ThemeTween  = {},     -- color tween state

    -- notifications queue
    Notifications = {},
}

-- ============================================================================
--  PART 2 COMPLETE
--  Next: PART 3 -- layout engine, scroll, resize handle, window frame,
--                   tab rail with icon-font icons
-- ============================================================================

-- ============================================================================
--  GEOMETRY HELPERS  --  small math, no state
-- ============================================================================

local function Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function PointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function Distance2(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

-- ============================================================================
--  WINDOW GEOMETRY  --  derived every frame from State.X/Y/W/H
-- ============================================================================

local Geometry = {}

function Geometry.Recalculate()
    Geometry.X = State.X
    Geometry.Y = State.Y
    Geometry.W = State.W
    Geometry.H = State.H

    -- top bar
    Geometry.TopY  = State.Y
    Geometry.TopH  = Layout.TopbarH

    -- tab rail (left side)
    Geometry.RailX = State.X
    Geometry.RailY = State.Y + Geometry.TopH
    Geometry.RailH = State.H - Geometry.TopH

    local wide = math.max(Layout.TabRailW, math.floor(State.W * 0.22))
    local open = State.RailOpen
    Geometry.RailW = Layout.TabRailNarrow + (wide - Layout.TabRailNarrow) * open

    -- content area (right of rail)
    Geometry.ContentX = Geometry.RailX + Geometry.RailW
    Geometry.ContentY = Geometry.RailY
    Geometry.ContentW = State.W - Geometry.RailW
    Geometry.ContentH = Geometry.RailH

    -- inner content (padding applied)
    Geometry.InnerX = Geometry.ContentX + Layout.ContentPadX
    Geometry.InnerY = Geometry.ContentY + Layout.ContentPadY
    Geometry.InnerW = Geometry.ContentW - Layout.ContentPadX * 2 - Layout.ScrollbarW
    Geometry.InnerH = Geometry.ContentH - Layout.ContentPadY * 2
end

-- ============================================================================
--  TABS  --  structural data
-- ============================================================================

local Tab = {}
Tab.__index = Tab

function Tab.new(parent, opts)
    opts = opts or {}
    local self = setmetatable({
        Parent   = parent,
        Name     = opts.Title or "Tab",
        Icon     = opts.Icon,
        Hidden   = opts.Hidden or false,

        -- layout values (recomputed each frame)
        RowY     = 0,
        RowH     = Layout.TabRowH,

        -- animation state
        Glow     = 0,
        Hover    = 0,

        -- content
        Rows     = {},           -- top-level controls on this tab
        Scroll   = 0,            -- vertical offset
        ScrollTo = 0,            -- animation target
        MaxScroll = 0,

        -- children
        Subs     = {},           -- sub-tabs if used later

        -- pending redraw pass
        Dirty    = true,
    }, Tab)
    State.Tabs[#State.Tabs + 1] = self
    -- also mirror on the parent table so ShadowUI.Tabs stays in sync
    parent.Tabs = parent.Tabs or {}
    parent.Tabs[#parent.Tabs + 1] = self

    return self
end

-- registers a row builder at the tab's root
function Tab:AddRow(builder)
    self.Rows[#self.Rows + 1] = builder
    return builder
end

-- ============================================================================
--  SECTION  --  visual group of rows with a header
-- ============================================================================

local Section = {}
Section.__index = Section

function Section.new(tab, title)
    local self = setmetatable({
        Parent = tab,
        Title  = title or "Section",
        Rows   = {},
        HeaderH = Layout.SectionH,
    }, Section)
    tab.Rows = tab.Rows or {}
    tab.Rows[#tab.Rows + 1] = self
    return self
end

function Section:AddRow(builder)
    self.Rows[#self.Rows + 1] = builder
    return builder
end

-- ============================================================================
--  INLINE ROW  --  lets several controls share a horizontal line
-- ============================================================================

local InlineRow = {}
InlineRow.__index = InlineRow

function InlineRow.new(parent, weights)
    weights = weights or {}
    local self = setmetatable({
        Parent  = parent,
        Cells   = {},
        Weights = weights,       -- weights[i] = fractional width
        Height  = Layout.RowHeight,
    }, InlineRow)
    parent.Rows[#parent.Rows + 1] = self
    return self
end

-- Each control factory accepts a parent (Tab, Section, or InlineRow).
-- If InlineRow, the control becomes a cell with equal weight by default.

local function IsInline(parent)
    return getmetatable(parent) == InlineRow
end

-- ============================================================================
--  SCROLL  --  smooth scroll per tab + scrollbar rendering
-- ============================================================================

local function TickScroll(tab, dt)
    tab.ScrollTo = Clamp(tab.ScrollTo, 0, tab.MaxScroll or 0)

    if State.NoAnim then
        tab.Scroll = tab.ScrollTo
    else
        tab.Scroll = Approach(tab.Scroll, tab.ScrollTo, 22, dt)
        if math.abs(tab.Scroll - tab.ScrollTo) < 0.4 then
            tab.Scroll = tab.ScrollTo
        end
    end
end

local function HandleWheel(tab)
    if not tab then return end
    if not MouseIn(Geometry.ContentX, Geometry.ContentY,
                   Geometry.ContentW, Geometry.ContentH) then return end
    if Input.Wheel == 0 then return end
    tab.ScrollTo = tab.ScrollTo - Input.Wheel * Layout.ScrollSpeed
    tab.ScrollTo = Clamp(tab.ScrollTo, 0, tab.MaxScroll or 0)
end

local function DrawScrollbar(tab)
    if (tab.MaxScroll or 0) <= 0 then return end
    local trackX = Geometry.ContentX + Geometry.ContentW - Layout.ScrollbarW - 3
    local trackY = Geometry.ContentY + 4
    local trackH = Geometry.ContentH - 8

    Rect(trackX, trackY, Layout.ScrollbarW, trackH,
         State.Theme.Track, 20, Layout.ScrollbarW / 2, 0.35)

    local viewFrac = Geometry.InnerH / (Geometry.InnerH + tab.MaxScroll)
    local thumbH = math.max(24, trackH * viewFrac)
    local scrollFrac = tab.ScrollTo / math.max(1, tab.MaxScroll)
    local thumbY = trackY + (trackH - thumbH) * scrollFrac

    Rect(trackX, thumbY, Layout.ScrollbarW, thumbH,
         State.Theme.Accent, 21, Layout.ScrollbarW / 2, 0.7)
end

-- ============================================================================
--  RESIZE HANDLE  --  bottom-right corner drag
-- ============================================================================

local function BeginResize()
    State.Resize = {
        StartX = State.X,
        StartY = State.Y,
        StartW = State.W,
        StartH = State.H,
        GrabX  = Input.X,
        GrabY  = Input.Y,
    }
end

local function TickResize()
    local r = State.Resize
    if not r then return end

    if not Input.Down then
        State.Resize = nil
        return
    end

    State.W = Clamp(r.StartW + (Input.X - r.GrabX),
                    Layout.WindowMinW, 2400)
    State.H = Clamp(r.StartH + (Input.Y - r.GrabY),
                    Layout.WindowMinH, 1600)

    -- keep window on-screen
    local vp = Camera.ViewportSize
    State.X = math.min(math.max(State.X, -State.W + 120), vp.X - 120)
    State.Y = math.min(math.max(State.Y, 0), vp.Y - 40)
end

local function DrawResizeHandle()
    local hx = State.X + State.W - Layout.ResizeGrab
    local hy = State.Y + State.H - Layout.ResizeGrab

    local hovered = MouseIn(hx, hy, Layout.ResizeGrab, Layout.ResizeGrab)
    if not hovered and not State.Resize then return end

    local a = hovered and 0.9 or 0.5
    for i = 0, 2 do
        local off = i * 3
        Bar(
            hx + Layout.ResizeGrab - 2 - off,
            hy + Layout.ResizeGrab - 2,
            hx + Layout.ResizeGrab - 2,
            hy + Layout.ResizeGrab - 2 - off,
            1.5, State.Theme.AccentDim, 200, a - i * 0.15
        )
    end

    if hovered and Input.Click then
        BeginResize()
        Input.Click = false
    end
end

-- ============================================================================
--  WINDOW DRAG  --  top bar
-- ============================================================================

local function BeginDrag()
    State.Drag = {
        GrabX = Input.X - State.X,
        GrabY = Input.Y - State.Y,
        WantX = State.X,
        WantY = State.Y,
    }
end

local function TickDrag(dt)
    local d = State.Drag
    if not d then return end

    if Input.Down then
        d.WantX = Input.X - d.GrabX
        d.WantY = Input.Y - d.GrabY
    end

    if State.NoAnim then
        State.X, State.Y = d.WantX, d.WantY
    else
        State.X = Approach(State.X, d.WantX, State.DragSpeed, dt)
        State.Y = Approach(State.Y, d.WantY, State.DragSpeed, dt)
    end

    -- snap
    if not Input.Down
       and math.abs(State.X - d.WantX) < 0.5
       and math.abs(State.Y - d.WantY) < 0.5 then
        State.X, State.Y = d.WantX, d.WantY
        State.Drag = nil
    end

    local vp = Camera.ViewportSize
    State.X = math.min(math.max(State.X, -State.W + 120), vp.X - 120)
    State.Y = math.min(math.max(State.Y, 0), vp.Y - 40)
end

-- ============================================================================
--  WINDOW FRAME  --  background, top bar, shadow, resize indicator
-- ============================================================================

local function DrawFrame()
    local th = State.Theme

    -- soft shadow
    if not State.NoAnim then
        local shadowSteps = 3
        for i = shadowSteps, 1, -1 do
            local pad = i * 2
            Rect(State.X - pad, State.Y - pad + 2,
                 State.W + pad * 2, State.H + pad * 2,
                 Color3.new(0, 0, 0), 5,
                 Layout.Corner + i,
                 0.022 / i)
        end
    end

    -- main background
    Rect(State.X, State.Y, State.W, State.H,
         th.Base, 10, Layout.Corner, 0.94)

    -- accent stroke at top
    GradientRect(
        State.X + 1, State.Y + 1, State.W - 2, 1.5,
        th.AccentA, th.AccentB, 12, 0.55
    )

    -- subtle border
    Stroke(State.X, State.Y, State.W, State.H,
           th.Stroke, 11, Layout.Corner, 0.72)

    -- top bar
    Rect(State.X, State.Y, State.W, Layout.TopbarH,
         th.Panel, 12, Layout.Corner, 0.98)

    -- bottom of topbar divider
    Line(State.X + 6, State.Y + Layout.TopbarH,
         State.X + State.W - 6, State.Y + Layout.TopbarH,
         th.Divider, 13, 1, 0.95)

    -- rail background
    Rect(Geometry.RailX, Geometry.RailY,
         Geometry.RailW, Geometry.RailH,
         th.Panel, 13, 0, 0.98)

    -- rail right divider
    Line(Geometry.RailX + Geometry.RailW, Geometry.RailY,
         Geometry.RailX + Geometry.RailW, Geometry.RailY + Geometry.RailH,
         th.Divider, 14, 1, 0.85)

    -- content background
    Rect(Geometry.ContentX, Geometry.ContentY,
         Geometry.ContentW, Geometry.ContentH,
         th.Base, 14, 0, 0.96)
end

-- ============================================================================
--  WINDOW TITLE  --  title text + close button + menu button
-- ============================================================================

local TitleButtons = {
    Close  = { Size = 22, X = 0, Y = 0 },
    Menu   = { Size = 22, X = 0, Y = 0 },
}

local function DrawTitleBar(title)
    local th = State.Theme
    local cy = State.Y + Layout.TopbarH / 2
    local cxLeft = State.X + 14

    -- brand mark: small rounded square + first letter
    local markSize = 20
    local markX = cxLeft
    local markY = cy - markSize / 2

    Rect(markX, markY, markSize, markSize,
         th.Accent, 30, 5, 0.18)
    Stroke(markX, markY, markSize, markSize,
           th.Accent, 31, 5, 0.55)

    local letter = string.upper(string.sub(title, 1, 1))
    local letterW = TextWidth(letter, 13, FontBold)
    Text(letter, markX + markSize / 2 - letterW / 2,
         markY + (markSize - 13) / 2,
         th.Accent, 13, FontBold, 32, 1)

    -- title text
    local titleX = markX + markSize + 10
    local titleY = TextMidY(State.Y, Layout.TopbarH, 13)
    Text(title, titleX, titleY,
         th.Text, 13, FontBold, 33, 0.95,
         Geometry.RailW - (titleX - State.X) - 8)

    -- close button (top right)
    local closeSize = TitleButtons.Close.Size
    local closeX = State.X + State.W - closeSize - 8
    local closeY = cy - closeSize / 2
    TitleButtons.Close.X = closeX
    TitleButtons.Close.Y = closeY

    local closeHover = MouseIn(closeX, closeY, closeSize, closeSize)
    if closeHover then
        Rect(closeX, closeY, closeSize, closeSize,
             th.Danger, 30, 6, 0.18)
        Stroke(closeX, closeY, closeSize, closeSize,
               th.Danger, 31, 6, 0.55)
    end

    local closeColor = closeHover and th.Danger or th.TextDim
    local cxi = closeX + closeSize / 2
    local cyi = closeY + closeSize / 2
    local s = 5
    Bar(cxi - s, cyi - s, cxi + s, cyi + s, 1.6, closeColor, 32, closeHover and 1 or 0.8)
    Bar(cxi + s, cyi - s, cxi - s, cyi + s, 1.6, closeColor, 32, closeHover and 1 or 0.8)

    -- menu keybind button
    local menuSize = TitleButtons.Menu.Size
    local menuX = closeX - menuSize - 6
    local menuY = cy - menuSize / 2
    TitleButtons.Menu.X = menuX
    TitleButtons.Menu.Y = menuY

    local menuHover = MouseIn(menuX, menuY, menuSize, menuSize)
    if menuHover then
        Rect(menuX, menuY, menuSize, menuSize,
             th.Accent, 30, 6, 0.15)
        Stroke(menuX, menuY, menuSize, menuSize,
               th.Accent, 31, 6, 0.5)
    end

    local menuColor = menuHover and th.Accent or th.TextDim
    local mxi = menuX + menuSize / 2
    local myi = menuY + menuSize / 2
    for i = -1, 1 do
        Bar(mxi - 5, myi + i * 4, mxi + 5, myi + i * 4, 1.4, menuColor, 32, menuHover and 1 or 0.75)
    end

    -- clicks
    if closeHover and Input.Click then
        State.Open = false
        Input.Click = false
        return
    end

    if menuHover and Input.Click then
        State.RailPinned = not State.RailPinned
        Input.Click = false
        return
    end

    -- drag anywhere in the bar
    local barHover = MouseIn(State.X, State.Y, State.W, Layout.TopbarH)
    if barHover and Input.Click and not State.Drag then
        local exclude =
            PointInRect(Input.X, Input.Y, closeX, closeY, closeSize, closeSize) or
            PointInRect(Input.X, Input.Y, menuX, menuY, menuSize, menuSize)
        if not exclude then
            BeginDrag()
            Input.Click = false
        end
    end
end

-- ============================================================================
--  TAB RAIL  --  sidebar with tabs, icons, hover/active states
-- ============================================================================

local function TickRailOpen(dt)
    local inRail = MouseIn(Geometry.RailX, Geometry.RailY,
                           Geometry.RailW, Geometry.RailH)

    local target = (State.RailPinned or inRail) and 1 or 0
    State.RailOpen = Approach(State.RailOpen, target, 14, dt)
    if math.abs(State.RailOpen - target) < 0.005 then
        State.RailOpen = target
    end
end

local function DrawTabRail()
    local th = State.Theme
    local openAmt = State.RailOpen
    local railW = Geometry.RailW

    local rowY = Geometry.RailY + 12
    local padX = 8
    local rowH = Layout.TabRowH
    local iconSize = Layout.TabIcon

    for i, tab in ipairs(State.Tabs) do
        if not tab.Hidden then
            local x = Geometry.RailX + padX
            local y = rowY
            local w = railW - padX * 2

            local hover = MouseIn(x, y, w, rowH)
            local active = (State.ActiveIndex == i)

            -- animate states
            tab.Glow = Approach(tab.Glow or 0, active and 1 or 0, 16, State.Delta)
            tab.Hover = Approach(tab.Hover or 0, hover and 1 or 0, 18, State.Delta)

            if math.abs(tab.Glow - (active and 1 or 0)) < 0.01 then
                tab.Glow = active and 1 or 0
            end
            if math.abs(tab.Hover - (hover and 1 or 0)) < 0.01 then
                tab.Hover = hover and 1 or 0
            end

            -- soft neutral tab surface; the accent is used only as a state indicator.
            local bgColor = mix(th.Panel, th.PanelHi, tab.Hover * 0.7 + tab.Glow * 0.3)
            local bgAlpha = 0.35 + 0.25 * tab.Hover + 0.12 * tab.Glow
            Rect(x, y, w, rowH, bgColor, 40, 7, bgAlpha)

            -- slim active indicator, kept outside the icon/text area.
            if tab.Glow > 0.01 then
                Rect(Geometry.RailX + 3, y + 6,
                     2, rowH - 12,
                     th.Accent, 42, 1, tab.Glow * 0.95)
            end

            -- icon column
            local iconX = x + 11
            local iconY = y + (rowH - iconSize) / 2
            local iconAlpha = 0.55 + 0.45 * math.max(tab.Glow, tab.Hover)
            local iconColor = tab.Glow > 0.5 and th.Accent or th.TextDim

            if not DrawIconByName(tab.Icon, iconX, iconY, iconSize,
                                  iconColor, 44, iconAlpha) then
                -- fallback: small square mark
                Rect(iconX + 3, iconY + 3, iconSize - 6, iconSize - 6,
                     iconColor, 44, 2, iconAlpha)
            end

            -- label
            if openAmt > 0.02 then
                local labelX = x + 36
                local labelRoom = w - (labelX - x) - 6
                local labelY = TextMidY(y, rowH, Layout.TextSize)
                local labelColor = th.Text
                local labelAlpha = openAmt * (0.7 + 0.3 * math.max(tab.Glow, tab.Hover))
                if tab.Glow > 0.5 then
                    labelColor = th.Text
                    labelAlpha = openAmt
                end
                Text(tab.Name, labelX, labelY,
                     labelColor, Layout.TextSize, FontBold,
                     45, labelAlpha, labelRoom)
            end

            -- click
            if hover and Input.Click then
                if State.ActiveIndex ~= i then
                    State.ActiveIndex = i
                end
                Input.Click = false
            end

            rowY = rowY + rowH + 4
        end
    end

    -- bottom of rail: version / watermark
    if openAmt > 0.1 then
        local bottomY = Geometry.RailY + Geometry.RailH - 20
        local text = "SHADOW UI v1.0"
        local w = TextWidth(text, Layout.TinySize, FontSystem)
        Text(text,
             Geometry.RailX + (Geometry.RailW - w) / 2,
             bottomY,
             th.TextMuted, Layout.TinySize, FontSystem,
             46, openAmt * 0.55)
    end
end

-- ============================================================================
--  CLIP HELPER  --  hide anything outside the content rectangle
-- ============================================================================

local function IsVisible(x, y, w, h)
    return y + h >= Geometry.ContentY
       and y <= Geometry.ContentY + Geometry.ContentH
end

-- ============================================================================
--  PART 3 COMPLETE
--  Next: PART 4 -- control batch A: Label, Divider, Button, Toggle, Slider
-- ============================================================================

-- ============================================================================
--  CONTROL REGISTRY
--  Every control type registers a constructor that returns an object with:
--    Obj.Height        -- intrinsic row height
--    Obj:Draw(x, y, w) -- render at given rect
--    Obj:Input(x, y, w)-- hit-testing & input handling
--    Obj:GetValue()    -- current value
--    Obj:SetValue(v)   -- programmatic set
--    Obj:OnChanged(cb) -- subscribe to change events
-- ============================================================================

local Controls = {}

-- ============================================================================
--  BASE  --  shared helpers so every control gets common behavior for free
-- ============================================================================

local Base = {}
Base.__index = Base

function Base.New(kind, parent, opts)
    opts = opts or {}
    local self = setmetatable({
        Kind        = kind,
        Parent      = parent,
        Title       = opts.Title or "",
        Description = opts.Description or "",
        Hidden      = false,
        Enabled     = true,
        _listeners  = {},
        _hover      = 0,
        _press      = 0,
    }, Base)

    if parent then
        parent.Rows = parent.Rows or {}
        if parent.AddRow then
            parent:AddRow(self)
        else
            parent.Rows[#parent.Rows + 1] = self
        end
    end

    return self
end

function Base:OnChanged(cb)
    self._listeners[#self._listeners + 1] = cb
    return self
end

function Base:_Fire(value)
    for i = 1, #self._listeners do
        pcall(self._listeners[i], value)
    end
end

function Base:SetVisible(v)
    self.Hidden = not v
    return self
end

function Base:SetEnabled(v)
    self.Enabled = v and true or false
    return self
end

function Base:GetValue() return nil end
function Base:SetValue(v) end
function Base:Draw(x, y, w) end
function Base:Input(x, y, w) end

-- register a new control constructor under Controls[name]
local function Register(name, constructor)
    Controls[name] = constructor
end

-- ============================================================================
--  ANIMATION TICK  --  all controls advance their _hover/_press in one place
-- ============================================================================

local function TickAnim(control, hovered, pressed, dt)
    if State.NoAnim then
        control._hover = hovered and 1 or 0
        control._press = pressed and 1 or 0
        return
    end
    control._hover = Approach(control._hover, hovered and 1 or 0, 18, dt)
    control._press = Approach(control._press, pressed and 1 or 0, 26, dt)
    if math.abs(control._hover - (hovered and 1 or 0)) < 0.01 then
        control._hover = hovered and 1 or 0
    end
    if math.abs(control._press - (pressed and 1 or 0)) < 0.01 then
        control._press = pressed and 1 or 0
    end
end

-- ============================================================================
--  LABEL  --  simple text row
-- ============================================================================

Register("Label", function(parent, opts)
    local self = Base.New("Label", parent, opts)
    self.Height = 22

    function self:Draw(x, y, w)
        local th = State.Theme
        local titleY = TextMidY(y, 18, Layout.TextSize)
        Text(self.Title, x, titleY,
             th.Text, Layout.TextSize, FontSystem,
             50, self.Enabled and 0.92 or 0.4, w)

        if self.Description ~= "" then
            local descY = y + 16
            Text(self.Description, x, descY,
                 th.TextDim, Layout.SmallSize, FontSystem,
                 51, self.Enabled and 0.7 or 0.3,
                 w)
            self.Height = 32
        else
            self.Height = 18
        end
    end

    function self:Input() return end

    return self
end)

-- ============================================================================
--  DIVIDER  --  thin separator line, optionally with a label
-- ============================================================================

Register("Divider", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Divider", parent, opts)
    self.Height = 14

    function self:Draw(x, y, w)
        local th = State.Theme
        local cy = y + 7
        if self.Title and self.Title ~= "" then
            local textW = TextWidth(self.Title, Layout.TinySize, FontBold)
            local px = 6
            local gap = 8
            -- left line
            Line(x, cy, x + 6, cy, th.Divider, 50, 1, 0.5)
            -- title
            Text(string.upper(self.Title),
                 x + gap, cy - 6,
                 th.TextMuted, Layout.TinySize, FontBold,
                 51, 0.7)
            -- right line
            Line(x + gap + textW + gap, cy,
                 x + w, cy,
                 th.Divider, 50, 1, 0.5)
        else
            Line(x, cy, x + w, cy, th.Divider, 50, 1, 0.5)
        end
    end

    function self:Input() end

    return self
end)

-- ============================================================================
--  BUTTON  --  solid button row
-- ============================================================================

Register("Button", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Button", parent, opts)
    self.ButtonText = opts.ButtonText or "Run"
    self.Callback   = opts.Callback
    self.Height     = Layout.ButtonH + 6

    function self:Draw(x, y, w)
        local th = State.Theme
        local h = Layout.ButtonH

        local btnW = math.max(60,
            math.min(w * 0.4,
                     TextWidth(self.ButtonText, Layout.TextSize, FontBold) + 24))
        local btnX = x + w - btnW
        local btnY = y + 3

        local hover = MouseIn(btnX, btnY, btnW, h) and self.Enabled
        TickAnim(self, hover, hover and Input.Down, State.Delta)

        local glow = self._hover
        local bg = mix(th.PanelHi, th.Accent, glow * 0.5)
        local bgA = 0.7 + 0.25 * glow

        Rect(btnX, btnY, btnW, h, bg, 52, 6, bgA)
        Stroke(btnX, btnY, btnW, h, th.Accent, 53, 6, 0.35 + 0.45 * glow)

        local label = self.ButtonText
        local lw = TextWidth(label, Layout.TextSize, FontBold)
        local lc = mix(th.Text, th.Accent, glow * 0.7)
        Text(label, btnX + (btnW - lw) / 2, btnY + (h - Layout.TextSize) / 2,
             lc, Layout.TextSize, FontBold, 54, self.Enabled and 1 or 0.5)

        -- title on the left
        if self.Title ~= "" then
            local titleY = TextMidY(y, Layout.ButtonH + 6, Layout.TextSize)
            Text(self.Title, x, titleY,
                 th.Text, Layout.TextSize, FontSystem,
                 51, self.Enabled and 0.9 or 0.4,
                 btnX - x - 10)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.ButtonH
        local btnW = math.max(60,
            math.min(w * 0.4,
                     TextWidth(self.ButtonText, Layout.TextSize, FontBold) + 24))
        local btnX = x + w - btnW
        local btnY = y + 3

        if MouseIn(btnX, btnY, btnW, h) and Input.Click then
            Input.Click = false
            if self.Callback then
                task.spawn(self.Callback)
            end
        end
    end

    return self
end)

-- ============================================================================
--  TOGGLE  --  sliding switch
-- ============================================================================

Register("Toggle", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Toggle", parent, opts)
    self.Value   = opts.Default and true or false
    self.Callback = opts.Callback
    self.Height  = Layout.ToggleH + 10

    -- internal animation
    self._knob = self.Value and 1 or 0

    function self:GetValue() return self.Value end

    function self:SetValue(v, silent)
        v = v and true or false
        if self.Value == v then return end
        self.Value = v
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local trackW = Layout.ToggleW
        local trackH = Layout.ToggleH
        local knob   = Layout.ToggleKnob

        local trackX = x + w - trackW
        local trackY = y + (self.Height - trackH) / 2

        local hover = MouseIn(trackX, trackY, trackW, trackH) and self.Enabled
        TickAnim(self, hover, hover and Input.Down, State.Delta)

        local target = self.Value and 1 or 0
        self._knob = Approach(self._knob, target, 22, State.Delta)
        if math.abs(self._knob - target) < 0.01 then self._knob = target end

        -- track background
        local trackColor = mix(th.Track, th.Accent, self._knob)
        local trackAlpha = 0.75 + 0.25 * self._hover
        Rect(trackX, trackY, trackW, trackH, trackColor, 52,
             trackH / 2, trackAlpha)
        Stroke(trackX, trackY, trackW, trackH, th.Stroke, 53,
               trackH / 2, 0.5)

        -- knob
        local knobX = trackX + 2 + (trackW - knob - 4) * self._knob
        local knobY = trackY + (trackH - knob) / 2
        local knobColor = mix(th.TextDim, th.Text, self._knob)
        Circle(knobX + knob / 2, knobY + knob / 2, knob / 2,
               knobColor, 54, true, 1, 18, 1)

        -- title
        if self.Title ~= "" then
            local titleY = TextMidY(y, self.Height, Layout.TextSize)
            Text(self.Title, x, titleY,
                 th.Text, Layout.TextSize, FontSystem,
                 51, self.Enabled and 0.92 or 0.4,
                 trackX - x - 10)
        end

        -- description
        if self.Description ~= "" then
            local descY = y + self.Height - 4
            Text(self.Description, x, descY,
                 th.TextDim, Layout.SmallSize, FontSystem,
                 51, self.Enabled and 0.6 or 0.25,
                 trackX - x - 10)
            self.Height = math.max(self.Height, Layout.ToggleH + 22)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local trackW = Layout.ToggleW
        local trackH = Layout.ToggleH
        local trackX = x + w - trackW
        local trackY = y + (self.Height - trackH) / 2

        if MouseIn(trackX, trackY, trackW, trackH) and Input.Click then
            Input.Click = false
            self:SetValue(not self.Value)
        end
    end

    return self
end)

-- ============================================================================
--  SLIDER  --  horizontal track with knob, value badge, optional step ticks
-- ============================================================================

Register("Slider", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Slider", parent, opts)
    self.Min     = opts.Min or 0
    self.Max     = opts.Max or 100
    self.Step    = opts.Step or 1
    self.Value   = opts.Default or self.Min
    self.Suffix  = opts.Suffix or ""
    self.Callback = opts.Callback
    self.Height  = 34

    self._dragging = false
    self._knobAnim = 0

    local function snap(v)
        if self.Step <= 0 then
            return Clamp(v, self.Min, self.Max)
        end
        local s = math.floor((v - self.Min) / self.Step + 0.5) * self.Step + self.Min
        return Clamp(s, self.Min, self.Max)
    end

    local function frac()
        if self.Max <= self.Min then return 0 end
        return (self.Value - self.Min) / (self.Max - self.Min)
    end

    function self:GetValue() return self.Value end

    function self:SetValue(v, silent)
        v = snap(v)
        if self.Value == v then return end
        self.Value = v
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local trackH = Layout.SliderH
        local knobR  = Layout.SliderKnob

        -- value display
        local valueText = tostring(self.Value) .. self.Suffix
        local valueW = TextWidth(valueText, Layout.TextSize, FontMono)
        local badgeW = valueW + 14
        local badgeH = 18
        local badgeX = x + w - badgeW
        local badgeY = y + 2

        -- title
        if self.Title ~= "" then
            Text(self.Title, x, y + 1,
                 th.Text, Layout.TextSize, FontSystem,
                 51, self.Enabled and 0.92 or 0.4,
                 w - badgeW - 12)
        end

        -- value badge
        Rect(badgeX, badgeY, badgeW, badgeH,
             th.PanelHi, 52, 4, 0.85)
        Stroke(badgeX, badgeY, badgeW, badgeH,
               th.Stroke, 53, 4, 0.55)
        Text(valueText,
             badgeX + (badgeW - valueW) / 2,
             badgeY + (badgeH - Layout.TextSize) / 2,
             th.Accent, Layout.TextSize, FontMono,
             54, 1)

        -- track
        local trackY = y + 26
        local trackX = x
        local trackW = w

        Rect(trackX, trackY - trackH / 2, trackW, trackH,
             th.Track, 51, trackH / 2, 0.8)

        -- fill
        local f = frac()
        local fillW = trackW * f
        if fillW > 0.5 then
            Rect(trackX, trackY - trackH / 2, fillW, trackH,
                 th.Accent, 52, trackH / 2, 0.85)
        end

        -- knob
        local knobX = trackX + fillW
        local hover = MouseIn(x, trackY - 10, w, 20) and self.Enabled
        TickAnim(self, hover, self._dragging, State.Delta)
        self._knobAnim = Approach(self._knobAnim, (self._dragging or hover) and 1 or 0, 22, State.Delta)
        if math.abs(self._knobAnim - ((self._dragging or hover) and 1 or 0)) < 0.01 then
            self._knobAnim = (self._dragging or hover) and 1 or 0
        end

        local kR = knobR + self._knobAnim * 2
        Circle(knobX, trackY, kR + 3,
               th.Accent, 53, false, 1.4, 24, 0.3 + self._knobAnim * 0.5)
        Circle(knobX, trackY, kR,
               th.Text, 54, true, 1, 24, 1)
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local trackY = y + 26
        local hitY = trackY - 12
        local hitH = 24

        local clicked = MouseIn(x, hitY, w, hitH) and Input.Click
        local held = MouseIn(x, hitY, w, hitH) and Input.Down

        if clicked then
            self._dragging = true
        end
        if not Input.Down then
            self._dragging = false
        end

        if self._dragging and held then
            local t = Clamp((Input.X - x) / w, 0, 1)
            local v = self.Min + t * (self.Max - self.Min)
            self:SetValue(v)
        end
    end

    return self
end)

-- ============================================================================
--  INLINE HELPER  --  build a row of controls that share the horizontal space
-- ============================================================================

local function LayoutInline(row, x, y, w)
    -- Distribute widths according to weights (default: equal)
    local n = #row.Cells
    if n == 0 then return end

    local weights = row.Weights or {}
    local total = 0
    for i = 1, n do total = total + (weights[i] or 1) end
    if total <= 0 then total = n end

    local pad = Layout.RowColumnGap
    local availW = w - (n - 1) * pad
    local cx = x
    local maxH = 0

    for i = 1, n do
        local frac = (weights[i] or 1) / total
        local cw = math.floor(availW * frac)
        local ctrl = row.Cells[i]
        ctrl._inlineX = cx
        ctrl._inlineY = y
        ctrl._inlineW = cw
        cx = cx + cw + pad
        if ctrl.Height > maxH then maxH = ctrl.Height end
    end

    -- now draw each one
    for i = 1, n do
        local ctrl = row.Cells[i]
        if not ctrl.Hidden then
            ctrl:Draw(ctrl._inlineX, ctrl._inlineY, ctrl._inlineW)
        end
    end

    return maxH
end

local function InputInline(row, x, y, w)
    for i = 1, #row.Cells do
        local ctrl = row.Cells[i]
        if not ctrl.Hidden then
            ctrl:Input(ctrl._inlineX or x, ctrl._inlineY or y, ctrl._inlineW or w)
        end
    end
end

-- ============================================================================
--  CONTENT  --  generic render pass: walks a tab's rows and draws them
-- ============================================================================

local ContentCursor = { y = 0 }

local function DrawRow(row, x, y, w)
    if row.Hidden then return 0 end

    -- Section: header + nested rows
    if getmetatable(row) == Section then
        local hy = y + 4
        Text(string.upper(row.Title),
             x, hy,
             State.Theme.TextMuted, Layout.TinySize, FontBold,
             50, 0.8, w)
        -- underline
        local underY = hy + 12
        Line(x, underY, x + w, underY, State.Theme.Divider, 51, 1, 0.5)

        local cy = underY + Layout.SectionGap
        for _, child in ipairs(row.Rows) do
            if not child.Hidden then
                cy = cy + DrawRow(child, x, cy, w) + Layout.RowGapY
            end
        end
        return cy - y
    end

    -- Inline row
    if getmetatable(row) == InlineRow then
        local h = LayoutInline(row, x, y, w)
        return h or Layout.RowHeight
    end

    -- Control
    if row.Draw then
        row:Draw(x, y, w)
        return row.Height or Layout.RowHeight
    end

    return 0
end

local function InputRow(row, x, y, w)
    if row.Hidden then return 0 end

    if getmetatable(row) == Section then
        local cy = y + 22 + Layout.SectionGap
        for _, child in ipairs(row.Rows) do
            if not child.Hidden then
                cy = cy + InputRow(child, x, cy, w) + Layout.RowGapY
            end
        end
        return cy - y
    end

    if getmetatable(row) == InlineRow then
        InputInline(row, x, y, w)
        return Layout.RowHeight
    end

    if row.Input then
        row:Input(x, y, w)
        return row.Height or Layout.RowHeight
    end

    return 0
end

-- ============================================================================
--  PART 4 COMPLETE
--  Next: PART 5 -- control batch B: Range, Dropdown, Keybind, Textbox
-- ============================================================================

-- ============================================================================
--  RANGE SLIDER  --  two knobs, dual values, min/max clamp
-- ============================================================================

Register("RangeSlider", function(parent, opts)
    opts = opts or {}
    local self = Base.New("RangeSlider", parent, opts)
    self.Min      = opts.Min or 0
    self.Max      = opts.Max or 100
    self.Step     = opts.Step or 1
    self.Low      = opts.DefaultLow or self.Min
    self.High     = opts.DefaultHigh or self.Max
    self.Suffix   = opts.Suffix or ""
    self.Callback = opts.Callback
    self.Height   = 38

    self._dragging = nil   -- "low" | "high" | nil
    self._lowAnim  = 0
    self._highAnim = 0

    local function snap(v)
        if self.Step <= 0 then return Clamp(v, self.Min, self.Max) end
        local s = math.floor((v - self.Min) / self.Step + 0.5) * self.Step + self.Min
        return Clamp(s, self.Min, self.Max)
    end

    local function fracOf(v)
        if self.Max <= self.Min then return 0 end
        return (v - self.Min) / (self.Max - self.Min)
    end

    function self:GetValue() return self.Low, self.High end
    function self:GetLow() return self.Low end
    function self:GetHigh() return self.High end

    function self:SetValue(lo, hi, silent)
        lo = snap(lo)
        hi = snap(hi)
        if lo > hi then lo, hi = hi, lo end
        if self.Low == lo and self.High == hi then return end
        self.Low, self.High = lo, hi
        if not silent then
            if self.Callback then pcall(self.Callback, lo, hi) end
            self:_Fire({ lo, hi })
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local trackH = Layout.SliderH
        local knobR  = Layout.SliderKnob

        -- dual value display
        local valueText = tostring(self.Low) .. " - " .. tostring(self.High) .. self.Suffix
        local valueW = TextWidth(valueText, Layout.TextSize, FontMono)
        local badgeW = valueW + 14
        local badgeH = 18
        local badgeX = x + w - badgeW
        local badgeY = y + 2

        if self.Title ~= "" then
            Text(self.Title, x, y + 1,
                 th.Text, Layout.TextSize, FontSystem,
                 51, self.Enabled and 0.92 or 0.4,
                 w - badgeW - 12)
        end

        Rect(badgeX, badgeY, badgeW, badgeH,
             th.PanelHi, 52, 4, 0.85)
        Stroke(badgeX, badgeY, badgeW, badgeH,
               th.Stroke, 53, 4, 0.55)
        Text(valueText,
             badgeX + (badgeW - valueW) / 2,
             badgeY + (badgeH - Layout.TextSize) / 2,
             th.Accent, Layout.TextSize, FontMono,
             54, 1)

        -- track
        local trackY = y + 28
        local trackX = x
        local trackW = w

        Rect(trackX, trackY - trackH / 2, trackW, trackH,
             th.Track, 51, trackH / 2, 0.8)

        -- active fill between knobs
        local flo = fracOf(self.Low)
        local fhi = fracOf(self.High)
        local fillX = trackX + trackW * flo
        local fillW = trackW * (fhi - flo)
        if fillW > 0.5 then
            Rect(fillX, trackY - trackH / 2, fillW, trackH,
                 th.Accent, 52, trackH / 2, 0.85)
        end

        -- knobs
        local hover = MouseIn(x, trackY - 10, w, 20) and self.Enabled
        TickAnim(self, hover, self._dragging ~= nil, State.Delta)

        self._lowAnim  = Approach(self._lowAnim,  (self._dragging == "low")  and 1 or 0, 22, State.Delta)
        self._highAnim = Approach(self._highAnim, (self._dragging == "high") and 1 or 0, 22, State.Delta)

        local lx = trackX + trackW * flo
        local hx = trackX + trackW * fhi

        local lr = knobR + self._lowAnim * 2
        Circle(lx, trackY, lr + 3, th.Accent, 53, false, 1.4, 24, 0.3 + self._lowAnim * 0.5)
        Circle(lx, trackY, lr, th.Text, 54, true, 1, 24, 1)

        local hr = knobR + self._highAnim * 2
        Circle(hx, trackY, hr + 3, th.Accent, 53, false, 1.4, 24, 0.3 + self._highAnim * 0.5)
        Circle(hx, trackY, hr, th.Text, 54, true, 1, 24, 1)
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local trackY = y + 28
        local hitY = trackY - 12
        local hitH = 24

        local inTrack = MouseIn(x, hitY, w, hitH)

        if inTrack and Input.Click then
            -- pick nearest knob
            local t = Clamp((Input.X - x) / w, 0, 1)
            local v = self.Min + t * (self.Max - self.Min)
            local dlo = math.abs(v - self.Low)
            local dhi = math.abs(v - self.High)
            self._dragging = (dlo <= dhi) and "low" or "high"
        end

        if not Input.Down then self._dragging = nil end

        if self._dragging and Input.Down then
            local t = Clamp((Input.X - x) / w, 0, 1)
            local v = self.Min + t * (self.Max - self.Min)
            if self._dragging == "low" then
                self:SetValue(math.min(v, self.High), self.High)
            else
                self:SetValue(self.Low, math.max(v, self.Low))
            end
        end
    end

    return self
end)

-- ============================================================================
--  DROPDOWN  --  single-select, flyout list with scroll
-- ============================================================================

Register("Dropdown", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Dropdown", parent, opts)
    self.Options  = opts.Options or {}
    self.Value    = opts.Default or (self.Options[1])
    self.Callback = opts.Callback
    self.Height   = 32

    self._open = false
    self._openAnim = 0
    self._listScroll = 0
    self._listScrollTo = 0

    function self:GetValue() return self.Value end

    function self:SetValue(v, silent)
        if self.Value == v then return end
        self.Value = v
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local h = Layout.DropdownH

        local fieldX = x
        local fieldY = y + 2
        local fieldW = w

        local hover = MouseIn(fieldX, fieldY, fieldW, h) and self.Enabled
        TickAnim(self, hover, self._open, State.Delta)

        local bg = mix(th.PanelHi, th.Panel, self._hover * 0.5)
        Rect(fieldX, fieldY, fieldW, h, bg, 52, 6, 0.85 + 0.1 * self._hover)
        Stroke(fieldX, fieldY, fieldW, h, th.Stroke, 53, 6, 0.5 + 0.3 * self._hover)

        -- title
        local labelX = fieldX + 10
        if self.Title ~= "" then
            Text(self.Title, labelX, fieldY + (h - Layout.TextSize) / 2,
                 th.Text, Layout.TextSize, FontSystem,
                 54, self.Enabled and 0.92 or 0.4,
                 fieldW - 60)
        end

        -- value
        local valueText = tostring(self.Value or "-")
        local valueW = TextWidth(valueText, Layout.TextSize, FontBold)
        Text(valueText,
             fieldX + fieldW - 26 - valueW,
             fieldY + (h - Layout.TextSize) / 2,
             th.Accent, Layout.TextSize, FontBold,
             54, self.Enabled and 1 or 0.4,
             200)

        -- chevron
        local cx = fieldX + fieldW - 14
        local cy = fieldY + h / 2
        local turn = self._open and 1 or 0
        local ang = turn * math.pi
        local rad = 4
        local ca, sa = math.cos(ang), math.sin(ang)
        local function rot(ox, oy)
            return cx + ox * ca - oy * sa, cy + ox * sa + oy * ca
        end
        local x1, y1 = rot(-rad, -rad * 0.45)
        local xt, yt = rot(0, rad * 0.45)
        local x2, y2 = rot(rad, -rad * 0.45)
        Bar(x1, y1, xt, yt, 1.5, th.TextDim, 55, 0.85)
        Bar(xt, yt, x2, y2, 1.5, th.TextDim, 55, 0.85)

        -- open list
        self._openAnim = Approach(self._openAnim, self._open and 1 or 0, 20, State.Delta)
        if math.abs(self._openAnim - (self._open and 1 or 0)) < 0.01 then
            self._openAnim = self._open and 1 or 0
        end

        if self._openAnim > 0.02 then
            self:_DrawList(fieldX, fieldY + h + 3, fieldW, th)
        end
    end

    function self:_DrawList(x, y, w, th)
        local rowH = 22
        local maxVisible = 8
        local visible = math.min(#self.Options, maxVisible)
        local listH = visible * rowH + 8

        local maxScroll = math.max(0, #self.Options - maxVisible)
        self._listScrollTo = Clamp(self._listScrollTo, 0, maxScroll)
        if State.NoAnim then
            self._listScroll = self._listScrollTo
        else
            self._listScroll = Approach(self._listScroll, self._listScrollTo, 22, State.Delta)
            if math.abs(self._listScroll - self._listScrollTo) < 0.05 then
                self._listScroll = self._listScrollTo
            end
        end

        -- shadow + background
        Rect(x + 2, y + 3, w, listH, Color3.new(0, 0, 0), 60, 6, 0.25 * self._openAnim)
        Rect(x, y, w, listH, th.Base, 61, 6, 0.98 * self._openAnim)
        Stroke(x, y, w, listH, th.Accent, 62, 6, 0.5 * self._openAnim)

        for i = 1, visible do
            local idx = i + math.floor(self._listScroll)
            local option = self.Options[idx]
            if not option then break end

            local ry = y + 4 + (i - 1) * rowH
            local selected = (option == self.Value)
            local hover = MouseIn(x + 4, ry, w - 8, rowH)

            if selected or hover then
                local a = selected and 0.18 or 0.1
                Rect(x + 4, ry, w - 8, rowH, th.Accent, 63, 4, a * self._openAnim)
            end

            local labelColor = selected and th.Accent or th.Text
            Text(tostring(option),
                 x + 12, ry + (rowH - Layout.TextSize) / 2,
                 labelColor, Layout.TextSize, FontSystem,
                 64, (selected and 1 or 0.85) * self._openAnim,
                 w - 20)

            if hover and Input.Click then
                Input.Click = false
                self:SetValue(option)
                self._open = false
            end
        end

        -- scrollbar hint (if more options than fit)
        if maxScroll > 0 then
            local sx = x + w - 4
            local trackH = listH - 8
            Rect(sx, y + 4, 2, trackH, th.Track, 65, 1, 0.6)
            local thumbH = math.max(10, trackH * (maxVisible / #self.Options))
            local thumbY = y + 4 + (trackH - thumbH) * (self._listScroll / maxScroll)
            Rect(sx, thumbY, 2, thumbH, th.Accent, 66, 1, 0.9)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.DropdownH
        local fieldX, fieldY = x, y + 2

        -- if list is open, list hit-test runs first
        if self._open then
            local rowH = 22
            local maxVisible = 8
            local listH = math.min(#self.Options, maxVisible) * rowH + 8
            local listY = fieldY + h + 3

            -- hit test inside list
            if MouseIn(fieldX, listY, w, listH) and Input.Click then
                Input.Click = false
                return   -- handled in Draw
            end

            -- scroll
            if MouseIn(fieldX, listY, w, listH) and Input.Wheel ~= 0 then
                local maxScroll = math.max(0, #self.Options - maxVisible)
                self._listScrollTo = Clamp(self._listScrollTo - Input.Wheel, 0, maxScroll)
            end

            -- click outside closes
            if Input.Click and not MouseIn(fieldX, fieldY, w, h) then
                self._open = false
            end
        end

        -- field itself
        if MouseIn(fieldX, fieldY, w, h) and Input.Click then
            Input.Click = false
            self._open = not self._open
        end
    end

    return self
end)

-- ============================================================================
--  KEYBIND  --  click the chip, press any key, chip updates
-- ============================================================================

Register("Keybind", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Keybind", parent, opts)
    self.Value    = opts.Default or "none"    -- stored as lowercase string, e.g. "q", "f1", "mb1"
    self.Callback = opts.Callback
    self.Mode     = opts.Mode or "Hold"       -- "Hold" | "Toggle" | "Always"
    self.Height   = 28

    self._listening = false
    self._chipAnim = 0

    function self:GetValue() return self.Value end

    function self:SetValue(v, silent)
        v = v or "none"
        v = string.lower(v)
        if self.Value == v then return end
        self.Value = v
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local h = Layout.FieldH

        -- title
        local titleW = 0
        if self.Title ~= "" then
            Text(self.Title, x, TextMidY(y, self.Height, Layout.TextSize),
                 th.Text, Layout.TextSize, FontSystem,
                 51, self.Enabled and 0.92 or 0.4,
                 w - 80)
            titleW = TextWidth(self.Title, Layout.TextSize, FontSystem)
        end

        -- chip on the right
        local display = self._listening and "..." or KeyLabel.Format(self.Value)
        local chipW = math.max(38, TextWidth(display, Layout.TextSize, FontMono) + 18)
        local chipX = x + w - chipW
        local chipY = y + (self.Height - h) / 2

        local hover = MouseIn(chipX, chipY, chipW, h) and self.Enabled
        TickAnim(self, hover, self._listening, State.Delta)
        self._chipAnim = Approach(self._chipAnim, self._listening and 1 or 0, 22, State.Delta)

        local bg = mix(th.PanelHi, th.Accent, self._chipAnim * 0.5)
        Rect(chipX, chipY, chipW, h, bg, 52, 6, 0.85 + 0.1 * self._hover)

        local strokeColor = self._listening and th.Accent or th.Stroke
        local strokeA = self._listening and (0.6 + 0.4 * self._chipAnim) or (0.5 + 0.3 * self._hover)
        Stroke(chipX, chipY, chipW, h, strokeColor, 53, 6, strokeA)

        -- mode indicator: small dot color-coded
        local dotColor = th.TextDim
        if self.Mode == "Toggle" then dotColor = th.AccentA
        elseif self.Mode == "Always" then dotColor = th.AccentB end

        Circle(chipX + 8, chipY + h / 2, 2, dotColor, 54, true, 1, 10, 0.9)

        local labelColor = self._listening and th.Accent or th.Text
        Text(display,
             chipX + (chipW - TextWidth(display, Layout.TextSize, FontMono)) / 2 + 4,
             chipY + (h - Layout.TextSize) / 2,
             labelColor, Layout.TextSize, FontMono,
             54, self.Enabled and 1 or 0.5)
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.FieldH

        local display = self._listening and "..." or KeyLabel.Format(self.Value)
        local chipW = math.max(38, TextWidth(display, Layout.TextSize, FontMono) + 18)
        local chipX = x + w - chipW
        local chipY = y + (self.Height - h) / 2

        if MouseIn(chipX, chipY, chipW, h) and Input.Click then
            Input.Click = false
            self._listening = true
            BeginCapture(self, function(name)
                self._listening = false
                self:SetValue(name)
            end)
        end
    end

    return self
end)

-- ============================================================================
--  TEXTBOX  --  editable text field, focus to type, enter commits
-- ============================================================================

Register("Textbox", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Textbox", parent, opts)
    self.Value       = opts.Default or ""
    self.Placeholder = opts.Placeholder or "Enter..."
    self.Callback    = opts.Callback
    self.Allowed     = opts.Allowed    -- optional Lua pattern, e.g. "%d" for digits only
    self.Height      = 30

    self._focus = { Value = self.Value, Caret = #self.Value, Anchor = nil }
    self._caretAnim = 1

    function self:GetValue() return self.Value end

    function self:SetValue(v, silent)
        v = tostring(v or "")
        self.Value = v
        self._focus.Value = v
        self._focus.Caret = #v
        self._focus.Anchor = nil
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local h = Layout.FieldH + 2
        local fieldX = x
        local fieldY = y + 2
        local fieldW = w

        local hover = MouseIn(fieldX, fieldY, fieldW, h) and self.Enabled
        local focused = (Focus.Field == self._focus)
        TickAnim(self, hover, focused, State.Delta)

        local bg = mix(th.PanelHi, th.Panel, self._hover * 0.5)
        Rect(fieldX, fieldY, fieldW, h, bg, 52, 6, 0.85 + 0.1 * self._hover)

        local strokeColor = focused and th.Accent or th.Stroke
        local strokeA = focused and 0.85 or (0.5 + 0.3 * self._hover)
        Stroke(fieldX, fieldY, fieldW, h, strokeColor, 53, 6, strokeA)

        -- title
        local textX = fieldX + 10
        if self.Title ~= "" then
            Text(self.Title, textX, fieldY + (h - Layout.TextSize) / 2,
                 th.Text, Layout.TextSize, FontSystem,
                 54, self.Enabled and 0.92 or 0.4,
                 100)
            textX = textX + TextWidth(self.Title, Layout.TextSize, FontSystem) + 12
        end

        -- value / placeholder
        local val = self._focus.Value
        local display = (val == "" and not focused) and self.Placeholder or val
        local color = (val == "" and not focused) and th.TextMuted or th.Text

        local availW = fieldW - (textX - fieldX) - 12
        local visible = display
        if TextWidth(visible, Layout.TextSize, FontMono) > availW then
            -- trim from left to show end of value
            local excess = TextWidth(visible, Layout.TextSize, FontMono) - availW
            local cut = math.ceil(excess / (Layout.TextSize * (FontMetrics[FontMono] or 0.6)))
            visible = string.sub(visible, cut + 1)
        end

        Text(visible, textX, fieldY + (h - Layout.TextSize) / 2,
             color, Layout.TextSize, FontMono, 54, 1, availW)

        -- caret (blinking when focused)
        if focused then
            self._caretAnim = self._caretAnim - State.Delta * 1.6
            if self._caretAnim < 0 then self._caretAnim = 1 end
            local caretAlpha = (self._caretAnim > 0.5) and 1 or 0.2

            -- position caret within visible range
            local caretX = textX + TextWidth(string.sub(val, 1, self._focus.Caret), Layout.TextSize, FontMono)
            if caretX < fieldX + 6 then caretX = fieldX + 6 end
            if caretX > fieldX + fieldW - 6 then caretX = fieldX + fieldW - 6 end

            Rect(caretX, fieldY + 4, 1.4, h - 8, th.Accent, 55, 0, caretAlpha)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.FieldH + 2
        local fieldY = y + 2

        if MouseIn(x, fieldY, w, h) and Input.Click then
            Input.Click = false
            SetFocus(self._focus)
            self._focus.OnCommit = function(v)
                self:SetValue(v)
            end
        end

        -- click outside = unfocus
        if Input.Click and Focus.Field == self._focus then
            if not MouseIn(x, fieldY, w, h) then
                ClearFocus()
            end
        end
    end

    return self
end)

-- ============================================================================
--  PART 5 COMPLETE
--  Next: PART 6 -- ColorPicker, Section sub-tabs, Search/Spotlight
-- ============================================================================

-- ============================================================================
--  HSV <-> RGB HELPERS  --  used by ColorPicker
-- ============================================================================

local function RGBToHSV(r, g, b)
    local maxc = math.max(r, g, b)
    local minc = math.min(r, g, b)
    local delta = maxc - minc

    local h = 0
    if delta > 0 then
        if maxc == r then
            h = ((g - b) / delta) % 6
        elseif maxc == g then
            h = ((b - r) / delta) + 2
        else
            h = ((r - g) / delta) + 4
        end
        h = h / 6
        if h < 0 then h = h + 1 end
    end

    local s = (maxc == 0) and 0 or (delta / maxc)
    local v = maxc

    return h, s, v
end

local function HSVToRGB(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    local r, g, b
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else              r, g, b = v, p, q
    end

    return r, g, b
end

-- ============================================================================
--  COLORPICKER  --  inline swatch + expanding HSV picker panel
-- ============================================================================

Register("ColorPicker", function(parent, opts)
    opts = opts or {}
    local self = Base.New("ColorPicker", parent, opts)
    self.Value     = opts.Default or Color3.fromRGB(120, 140, 255)
    self.Callback  = opts.Callback
    self.Height    = 30

    self._open     = false
    self._openAnim = 0

    -- HSV state, kept in sync with Color
    self._h, self._s, self._v = RGBToHSV(self.Value.R, self.Value.G, self.Value.B)

    -- internal drags
    self._svDrag   = false
    self._hueDrag  = false
    self._alphaDrag = false
    self._alpha    = opts.DefaultAlpha or 1

    function self:GetValue() return self.Value, self._alpha end

    function self:SetValue(color, silent)
        if not color then return end
        self.Value = color
        self._h, self._s, self._v = RGBToHSV(color.R, color.G, color.B)
        if not silent then
            if self.Callback then pcall(self.Callback, color, self._alpha) end
            self:_Fire(color)
        end
    end

    local function emit()
        local r, g, b = HSVToRGB(self._h, self._s, self._v)
        self.Value = Color3.new(r, g, b)
        if self.Callback then pcall(self.Callback, self.Value, self._alpha) end
        self:_Fire(self.Value)
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local h = Layout.FieldH

        -- title
        local titleW = 0
        if self.Title ~= "" then
            Text(self.Title, x, TextMidY(y, self.Height, Layout.TextSize),
                 th.Text, Layout.TextSize, FontSystem,
                 51, self.Enabled and 0.92 or 0.4,
                 w - 60)
        end

        -- swatch
        local swatchW = 34
        local swatchX = x + w - swatchW
        local swatchY = y + (self.Height - h) / 2

        local hover = MouseIn(swatchX, swatchY, swatchW, h) and self.Enabled
        TickAnim(self, hover, self._open, State.Delta)

        Rect(swatchX, swatchY, swatchW, h, self.Value, 52, 5, self._alpha)
        Stroke(swatchX, swatchY, swatchW, h, th.Text, 53, 5, 0.35 + 0.35 * self._hover)

        -- open panel
        self._openAnim = Approach(self._openAnim, self._open and 1 or 0, 18, State.Delta)
        if math.abs(self._openAnim - (self._open and 1 or 0)) < 0.01 then
            self._openAnim = self._open and 1 or 0
        end

        if self._openAnim > 0.02 then
            self:_DrawPanel(swatchX - 190, swatchY + h + 4, 190)
        end
    end

    function self:_DrawPanel(px, py, pw)
        local th = State.Theme
        local a = self._openAnim
        local pph = 200

        -- shadow, panel, stroke
        Rect(px + 2, py + 3, pw, pph, Color3.new(0, 0, 0), 60, 8, 0.28 * a)
        Rect(px, py, pw, pph, th.Base, 61, 8, 0.98 * a)
        Stroke(px, py, pw, pph, th.Accent, 62, 8, 0.5 * a)

        local padX = 10
        local padY = 10

        -- --- saturation/value field ---
        local svX = px + padX
        local svY = py + padY
        local svW = pw - padX * 2 - 14
        local svH = 110

        -- base hue color
        local hr, hg, hb = HSVToRGB(self._h, 1, 1)
        local hueColor = Color3.new(hr, hg, hb)

        -- white -> hue gradient (columns)
        GradientRect(svX, svY, svW, svH,
                     Color3.new(1, 1, 1), hueColor, 63, a, 24)

        -- black overlay (rows, top transparent -> bottom opaque)
        local steps = 12
        for i = 1, steps do
            local t = (i - 0.5) / steps
            Rect(svX, svY + svH * (i - 1) / steps,
                 svW, svH / steps + 1,
                 Color3.new(0, 0, 0), 64, 0, t * a)
        end
        Stroke(svX, svY, svW, svH, th.Stroke, 65, 4, 0.5 * a)

        -- cursor
        local cxp = svX + svW * self._s
        local cyp = svY + svH * (1 - self._v)
        Circle(cxp, cyp, 6, th.Text, 66, false, 1.8, 24, a)
        Circle(cxp, cyp, 6, Color3.new(0, 0, 0), 66, false, 2.6, 24, 0.5 * a)
        Circle(cxp, cyp, 3, self.Value, 67, true, 1, 20, a)

        -- --- hue strip ---
        local hueX = svX
        local hueY = svY + svH + 8
        local hueW = svW
        local hueH = 12

        -- vertical rainbow
        local hues = 24
        for i = 1, hues do
            local t = (i - 0.5) / hues
            local r, g, b = HSVToRGB(t, 1, 1)
            local sw = hueW / hues + 1
            Rect(hueX + (i - 1) * (hueW / hues), hueY, sw, hueH,
                 Color3.new(r, g, b), 63, 0, a)
        end
        Stroke(hueX, hueY, hueW, hueH, th.Stroke, 65, 3, 0.5 * a)

        -- hue marker
        local hueCx = hueX + hueW * self._h
        Rect(hueCx - 1.5, hueY - 2, 3, hueH + 4, th.Text, 66, 1.5, a)
        Rect(hueCx - 2.5, hueY - 2, 5, hueH + 4, Color3.new(0, 0, 0), 66, 2.5, 0.5 * a)

        -- --- preview + hex ---
        local prevY = hueY + hueH + 8
        local prevH = 22
        local previewX = px + padX
        local previewW = 42

        Rect(previewX, prevY, previewW, prevH, self.Value, 63, 5, self._alpha)
        Stroke(previewX, prevY, previewW, prevH, th.Text, 64, 5, 0.35)

        local r8 = math.floor(self.Value.R * 255 + 0.5)
        local g8 = math.floor(self.Value.G * 255 + 0.5)
        local b8 = math.floor(self.Value.B * 255 + 0.5)
        local hex = string.format("#%02X%02X%02X", r8, g8, b8)

        Text(hex,
             previewX + previewW + 8, prevY + 5,
             th.TextDim, Layout.SmallSize, FontMono, 65, 0.9)

        -- --- alpha strip ---
        local alphaY = prevY + prevH + 6
        local alphaX = px + padX
        local alphaW = pw - padX * 2
        local alphaH = 6

        -- checker base
        Rect(alphaX, alphaY, alphaW, alphaH, th.Track, 63, 2, 0.5 * a)

        -- alpha gradient (black -> color)
        local baseColor = Color3.new(1, 1, 1)
        GradientRect(alphaX, alphaY, alphaW * self._alpha, alphaH,
                     Color3.new(1, 1, 1), self.Value, 64, a, 16)

        -- alpha cursor
        local alphaCx = alphaX + alphaW * self._alpha
        Rect(alphaCx - 1.5, alphaY - 2, 3, alphaH + 4, th.Text, 66, 1.5, a)
        Rect(alphaCx - 2.5, alphaY - 2, 5, alphaH + 4, Color3.new(0, 0, 0), 66, 2.5, 0.5 * a)
        Stroke(alphaX, alphaY, alphaW, alphaH, th.Stroke, 65, 2, 0.5 * a)

        Text(string.format("%d%%", math.floor(self._alpha * 100 + 0.5)),
             alphaX + alphaW - 30, alphaY + 8,
             th.TextDim, Layout.TinySize, FontMono, 65, 0.8)

        -- cache panel geometry on self for Input
        self._panelX = px
        self._panelY = py
        self._panelW = pw
        self._panelH = pph
        self._svX, self._svY, self._svW, self._svH = svX, svY, svW, svH
        self._hueX, self._hueY, self._hueW, self._hueH = hueX, hueY, hueW, hueH
        self._alphaX, self._alphaY, self._alphaW, self._alphaH = alphaX, alphaY, alphaW, alphaH
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.FieldH
        local swatchW = 34
        local swatchX = x + w - swatchW
        local swatchY = y + (self.Height - h) / 2

        -- swatch click toggles panel
        if MouseIn(swatchX, swatchY, swatchW, h) and Input.Click then
            Input.Click = false
            self._open = not self._open
        end

        if not self._open then return end

        local px, py, pw = self._panelX, self._panelY, self._panelW
        if not px then return end

        -- sv drag
        if self._svX then
            local inside = MouseIn(self._svX, self._svY, self._svW, self._svH)
            if inside and Input.Click then
                self._svDrag = true
            end
            if not Input.Down then self._svDrag = false end
            if self._svDrag and Input.Down then
                local s = Clamp((Input.X - self._svX) / self._svW, 0, 1)
                local v = 1 - Clamp((Input.Y - self._svY) / self._svH, 0, 1)
                self._s, self._v = s, v
                emit()
            end
        end

        -- hue drag
        if self._hueX then
            local inside = MouseIn(self._hueX, self._hueY, self._hueW, self._hueH)
            if (inside and Input.Click) or self._hueDrag then
                if Input.Click then self._hueDrag = true end
                if not Input.Down then
                    self._hueDrag = false
                else
                    local hh = Clamp((Input.X - self._hueX) / self._hueW, 0, 1)
                    self._h = hh
                    emit()
                end
            end
        end

        -- alpha drag
        if self._alphaX then
            local inside = MouseIn(self._alphaX, self._alphaY, self._alphaW, self._alphaH + 6)
            if (inside and Input.Click) or self._alphaDrag then
                if Input.Click then self._alphaDrag = true end
                if not Input.Down then
                    self._alphaDrag = false
                else
                    local aa = Clamp((Input.X - self._alphaX) / self._alphaW, 0, 1)
                    self._alpha = aa
                    emit()
                end
            end
        end

        -- click outside closes
        if Input.Click and not MouseIn(px, py, pw, self._panelH or 200)
                        and not MouseIn(swatchX, swatchY, swatchW, h) then
            self._open = false
        end
    end

    return self
end)

-- ============================================================================
--  SUB-TABS  --  secondary tab bar inside a tab's content area
-- ============================================================================

local SubTab = {}
SubTab.__index = SubTab

function SubTab.new(parent, name, icon)
    local self = setmetatable({
        Parent   = parent,
        Name     = name or "Sub",
        Icon     = icon,
        Rows     = {},
        Scroll   = 0,
        ScrollTo = 0,
        MaxScroll = 0,
    }, SubTab)
    parent.Subs = parent.Subs or {}
    parent.Subs[#parent.Subs + 1] = self
    if #parent.Subs == 1 then
        parent.ActiveSub = self
    end
    return self
end

function SubTab:AddRow(builder)
    self.Rows[#self.Rows + 1] = builder
    return builder
end

-- renders a sub-tab header row (pill buttons)
local function DrawSubTabs(parent, x, y, w)
    if not parent.Subs or #parent.Subs == 0 then return 0 end

    local th = State.Theme
    local pillH = 24
    local padX = 8
    local gap = 6
    local cx = x

    for _, sub in ipairs(parent.Subs) do
        local tw = TextWidth(sub.Name, Layout.SmallSize, FontBold)
        local pillW = tw + 20
        local hover = MouseIn(cx, y, pillW, pillH)
        local active = parent.ActiveSub == sub

        sub._anim = Approach(sub._anim or 0, active and 1 or 0, 20, State.Delta)
        if math.abs(sub._anim - (active and 1 or 0)) < 0.01 then
            sub._anim = active and 1 or 0
        end

        local bg = mix(th.Panel, th.Accent, sub._anim * 0.4)
        local bgA = 0.5 + 0.4 * sub._anim + (active and 0 or (hover and 0.15 or 0))
        Rect(cx, y, pillW, pillH, bg, 51, 5, bgA)
        Stroke(cx, y, pillW, pillH, th.Stroke, 52, 5, 0.4 + 0.4 * sub._anim)

        local labelColor = active and th.Accent or th.Text
        Text(sub.Name, cx + 10, y + (pillH - Layout.SmallSize) / 2,
             labelColor, Layout.SmallSize, FontBold,
             53, active and 1 or (hover and 0.9 or 0.75))

        if hover and Input.Click then
            Input.Click = false
            parent.ActiveSub = sub
        end

        cx = cx + pillW + gap
    end

    return pillH + Layout.RowGapY
end

-- ============================================================================
--  SPOTLIGHT  --  fuzzy search overlay for controls across all tabs
-- ============================================================================

local Spotlight = {
    Open = false,
    Query = "",
    Caret = 0,
    Anchor = nil,
    Results = {},      -- { { Tab = tab, Row = row, Name = "..." , Kind = "..." } }
    SelectedIndex = 1,
    ScrollTo = 0,
    Scroll = 0,
    _anim = 0,
}

local function CollectRows()
    local list = {}
    for ti, tab in ipairs(State.Tabs) do
        local function walk(container, path)
            for _, row in ipairs(container.Rows or {}) do
                if not row.Hidden and row.Title and row.Title ~= "" then
                    list[#list + 1] = {
                        Tab = tab,
                        TabName = tab.Name,
                        Row = row,
                        Name = row.Title,
                        Kind = row.Kind or "Control",
                        Path = path,
                    }
                end
                if getmetatable(row) == Section then
                    walk(row, (path or "") .. (row.Title or "") .. " / ")
                elseif getmetatable(row) == InlineRow then
                    -- inline cells skip path prefix
                end
            end
        end
        walk(tab, "")
    end
    return list
end

local function FuzzyMatch(query, text)
    if query == "" then return true, 0 end
    local q, t = string.lower(query), string.lower(text)
    local qi, ti = 1, 1
    local score = 0
    local lastMatch = 0

    while qi <= #q and ti <= #t do
        if q:sub(qi, qi) == t:sub(ti, ti) then
            score = score + (10 - math.min(9, ti - lastMatch))
            lastMatch = ti
            qi = qi + 1
        end
        ti = ti + 1
    end

    return qi > #q, score
end

local function RefreshSpotlight()
    local all = CollectRows()
    local q = Spotlight.Query
    local filtered = {}

    if q == "" then
        for i = 1, math.min(#all, 40) do
            filtered[#filtered + 1] = all[i]
        end
    else
        local scored = {}
        for _, entry in ipairs(all) do
            local match, score = FuzzyMatch(q, entry.Name)
            if match then
                scored[#scored + 1] = { entry = entry, score = score }
            end
        end
        table.sort(scored, function(a, b) return a.score > b.score end)
        for i = 1, math.min(#scored, 40) do
            filtered[#filtered + 1] = scored[i].entry
        end
    end

    Spotlight.Results = filtered
    Spotlight.SelectedIndex = math.min(math.max(Spotlight.SelectedIndex, 1), #filtered)
end

local function OpenSpotlight()
    Spotlight.Open = true
    Spotlight.Query = ""
    Spotlight.Caret = 0
    Spotlight.Anchor = nil
    Spotlight.ScrollTo = 0
    Spotlight.Scroll = 0
    Spotlight.SelectedIndex = 1
    RefreshSpotlight()
    SetFocus({
        Value = "",
        Caret = 0,
        Anchor = nil,
        OnCommit = function(v)
            Spotlight.Query = v
            RefreshSpotlight()
        end,
    })
end

local function CloseSpotlight()
    Spotlight.Open = false
    ClearFocus()
end

local function DrawSpotlight()
    if not Spotlight.Open then return end

    Spotlight._anim = Approach(Spotlight._anim, 1, 22, State.Delta)
    if math.abs(Spotlight._anim - 1) < 0.01 then Spotlight._anim = 1 end
    local a = Spotlight._anim

    local vp = Camera.ViewportSize
    local panelW = 520
    local panelH = 380
    local panelX = (vp.X - panelW) / 2
    local panelY = math.max(80, vp.Y * 0.18)

    -- full-screen veil
    Rect(0, 0, vp.X, vp.Y, Color3.new(0, 0, 0), 100, 0, 0.45 * a)

    -- panel
    Rect(panelX + 2, panelY + 4, panelW, panelH, Color3.new(0, 0, 0), 101, 12, 0.35 * a)
    Rect(panelX, panelY, panelW, panelH, State.Theme.Base, 102, 12, 0.98 * a)
    Stroke(panelX, panelY, panelW, panelH, State.Theme.Accent, 103, 12, 0.55 * a)

    -- search field row
    local fieldH = 38
    local fieldY = panelY + 12
    local fieldX = panelX + 12
    local fieldW = panelW - 24

    Rect(fieldX, fieldY, fieldW, fieldH, State.Theme.PanelHi, 104, 8, 0.6 * a)
    Stroke(fieldX, fieldY, fieldW, fieldH, State.Theme.Accent, 105, 8, 0.5 * a)

    -- search icon
    local sx, sy = fieldX + 16, fieldY + fieldH / 2
    Circle(sx, sy, 6, State.Theme.Accent, 106, false, 1.6, 20, 0.9 * a)
    Bar(sx + 4, sy + 4, sx + 8, sy + 8, 1.8, State.Theme.Accent, 106, 0.9 * a)

    -- query text or placeholder
    local textX = fieldX + 32
    local textY = fieldY + (fieldH - 14) / 2
    local q = Spotlight.Query
    if q == "" then
        Text("Search controls...", textX, textY,
             State.Theme.TextMuted, 14, FontSystem, 107, 0.6 * a)
    else
        Text(q, textX, textY,
             State.Theme.Text, 14, FontSystem, 107, a)

        -- caret
        local caretX = textX + TextWidth(q, 14, FontSystem)
        Rect(caretX + 1, fieldY + 8, 1.4, fieldH - 16, State.Theme.Accent, 108, 0, a)
    end

    -- results list
    local listY = fieldY + fieldH + 10
    local listH = panelH - (listY - panelY) - 14
    local rowH = 32
    local visible = math.floor(listH / rowH)

    local maxScroll = math.max(0, #Spotlight.Results - visible)
    Spotlight.ScrollTo = Clamp(Spotlight.ScrollTo, 0, maxScroll)
    Spotlight.Scroll = Approach(Spotlight.Scroll, Spotlight.ScrollTo, 22, State.Delta)

    if #Spotlight.Results == 0 then
        Text("No matches", panelX + panelW / 2 - 40, listY + 20,
             State.Theme.TextMuted, 13, FontSystem, 108, 0.6 * a)
    else
        for i = 1, math.min(visible, #Spotlight.Results) do
            local idx = i + math.floor(Spotlight.Scroll)
            local entry = Spotlight.Results[idx]
            if not entry then break end

            local ry = listY + (i - 1) * rowH
            local selected = idx == Spotlight.SelectedIndex
            local hover = MouseIn(panelX + 8, ry, panelW - 16, rowH)

            if selected then
                Rect(panelX + 8, ry, panelW - 16, rowH, State.Theme.Accent, 108, 6, 0.15 * a)
            elseif hover then
                Rect(panelX + 8, ry, panelW - 16, rowH, State.Theme.PanelHi, 108, 6, 0.5 * a)
            end

            -- tab badge
            local badge = entry.TabName
            local bw = TextWidth(badge, 11, FontBold) + 12
            Rect(panelX + 14, ry + 8, bw, 16, State.Theme.AccentDim, 109, 4, 0.7 * a)
            Text(badge, panelX + 20, ry + 10,
                 State.Theme.Text, 11, FontBold, 110, 0.95 * a)

            -- name
            Text(entry.Name, panelX + 14 + bw + 10, ry + 8,
                 State.Theme.Text, 13, FontSystem, 110, 0.95 * a,
                 panelW - (bw + 40))

            -- kind
            Text(entry.Kind, panelX + panelW - 90, ry + 9,
                 State.Theme.TextMuted, 11, FontSystem, 110, 0.7 * a)

            if hover and Input.Click then
                Input.Click = false
                -- jump to tab, close spotlight
                for ti, tab in ipairs(State.Tabs) do
                    if tab == entry.Tab then
                        State.ActiveIndex = ti
                        break
                    end
                end
                CloseSpotlight()
                return
            end
        end
    end

    -- hint footer
    Text("Enter to jump  ·  Esc to close  ·  ↑↓ navigate",
         panelX + 14, panelY + panelH - 20,
         State.Theme.TextMuted, 11, FontSystem, 110, 0.55 * a)

    -- keyboard nav
    if Keys.Down.Click then
        Spotlight.SelectedIndex = math.min(Spotlight.SelectedIndex + 1, #Spotlight.Results)
        if Spotlight.SelectedIndex - visible >= Spotlight.ScrollTo then
            Spotlight.ScrollTo = Spotlight.SelectedIndex - visible
        end
    end
    if Keys.Up.Click then
        Spotlight.SelectedIndex = math.max(Spotlight.SelectedIndex - 1, 1)
        if Spotlight.SelectedIndex <= Spotlight.ScrollTo then
            Spotlight.ScrollTo = Spotlight.SelectedIndex - 1
        end
    end
    if Keys.Enter.Click and #Spotlight.Results > 0 then
        local entry = Spotlight.Results[Spotlight.SelectedIndex]
        for ti, tab in ipairs(State.Tabs) do
            if tab == entry.Tab then
                State.ActiveIndex = ti
                break
            end
        end
        CloseSpotlight()
    end
    if Keys.Escape.Click then
        CloseSpotlight()
    end

    -- route typing into the query
    local result = ProcessText({
        Value = Spotlight.Query,
        Caret = Spotlight.Caret,
        Anchor = Spotlight.Anchor,
    }, nil, function(v)
        CloseSpotlight()
    end)
    -- ProcessText mutates the field we passed, but it's a temp. Capture it back.
    -- (We need to re-read to pick up modifications.)
    -- Since we passed an anonymous table, we re-apply by reading through Focus
    if Focus.Field then
        local f = Focus.Field
        if Spotlight.Query ~= f.Value then
            Spotlight.Query = f.Value
            Spotlight.Caret = f.Caret
            Spotlight.Anchor = f.Anchor
            RefreshSpotlight()
        end
    end
end

-- ============================================================================
--  PART 6 COMPLETE
--  Next: PART 7 -- Notifications, Tooltips, HUD Boxes, Config save/load
-- ============================================================================

-- ============================================================================
--  NOTIFICATIONS  --  stacked toast queue, slide-in from right
-- ============================================================================

local Notification = {}
Notification.__index = Notification

local NoteColors = {
    info    = { accent = "Accent",   icon = "info"    },
    success = { accent = "Success",  icon = "success" },
    warning = { accent = "Warning",  icon = "warning" },
    error   = { accent = "Danger",   icon = "error"   },
}

local function Notify(opts)
    opts = opts or {}
    local entry = setmetatable({
        Title    = opts.Title   or "Notice",
        Content  = opts.Content or "",
        Type     = opts.Type    or "info",
        Duration = opts.Duration or 4,

        -- animation
        Fade     = 0,
        Slide    = 0,
        Life     = 0,
        TargetLife = opts.Duration or 4,
        Done     = false,
    }, Notification)

    State.Notifications[#State.Notifications + 1] = entry
    return entry
end

local function TickNotifications(dt)
    local list = State.Notifications
    local i = 1

    while i <= #list do
        local n = list[i]
        n.Life = n.Life + dt

        -- fade in fast, fade out over last 0.4s
        local remaining = n.TargetLife - n.Life
        local targetFade, targetSlide

        if n.Life < 0.25 then
            targetFade = n.Life / 0.25
            targetSlide = (1 - n.Life / 0.25) * 40
        elseif remaining < 0.4 then
            targetFade = math.max(0, remaining / 0.4)
            targetSlide = (1 - math.max(0, remaining / 0.4)) * 40
        else
            targetFade = 1
            targetSlide = 0
        end

        n.Fade  = Approach(n.Fade,  targetFade,  18, dt)
        n.Slide = Approach(n.Slide, targetSlide, 18, dt)

        if n.Life >= n.TargetLife and n.Fade < 0.02 then
            n.Done = true
        end

        if n.Done then
            table.remove(list, i)
        else
            i = i + 1
        end
    end
end

local function DrawNotifications()
    local th = State.Theme
    local vp = Camera.ViewportSize
    local notW = 280
    local notH = 56
    local gap = 8
    local baseY = vp.Y - 60
    local baseX = vp.X - notW - 16

    for i = #State.Notifications, 1, -1 do
        local n = State.Notifications[i]
        local a = n.Fade
        if a > 0.005 then
            local ny = baseY - (i - 1) * (notH + gap)
            local nx = baseX + n.Slide

            local colors = NoteColors[n.Type] or NoteColors.info
            local accent = th[colors.accent] or th.Accent

            -- shadow
            Rect(nx + 2, ny + 3, notW, notH, Color3.new(0, 0, 0), 200, 10, 0.3 * a)

            -- body
            Rect(nx, ny, notW, notH, th.Panel, 201, 10, 0.98 * a)
            Stroke(nx, ny, notW, notH, accent, 202, 10, 0.65 * a)

            -- accent stripe (left)
            Rect(nx, ny + 6, 3, notH - 12, accent, 203, 1.5, a * 0.95)

            -- icon
            DrawIconByName(colors.icon, nx + 12, ny + notH / 2 - 8, 16,
                           accent, 204, a * 0.9)

            -- title
            Text(n.Title, nx + 38, ny + 10,
                 th.Text, 13, FontBold, 205, a * 0.98, notW - 48)

            -- content (word-wrapped to 2 lines if needed)
            if n.Content ~= "" then
                Text(n.Content, nx + 38, ny + 28,
                     th.TextDim, 11, FontSystem, 205, a * 0.8, notW - 48)
            end

            -- progress bar at bottom of card
            local remain = 1 - (n.Life / n.TargetLife)
            if remain > 0 and remain < 1 then
                local barY = ny + notH - 3
                local barW = (notW - 20) * remain
                Rect(nx + 10, barY, barW, 1.5, accent, 206, 0.75, a * 0.75)
            end
        end
    end
end

-- ============================================================================
--  TOOLTIPS  --  hover info panel, topmost layer
-- ============================================================================

local Tooltip = {
    Current = nil,     -- text
    X = 0, Y = 0,
    Fade = 0,
    LastSetAt = 0,
    Delay = 0.35,
}

local function WantTooltip(text)
    if not text or text == "" then return end
    if Tooltip.Current ~= text then
        Tooltip.Current = text
        Tooltip.LastSetAt = os.clock()
    end
    Tooltip.X = Input.X
    Tooltip.Y = Input.Y
end

local function TickTooltip(dt)
    local target = 0
    if Tooltip.Current and (os.clock() - Tooltip.LastSetAt) >= Tooltip.Delay then
        target = 1
    end

    Tooltip.Fade = Approach(Tooltip.Fade, target, 18, dt)

    if not Tooltip.Current then
        Tooltip.Fade = 0
    end
end

local function DrawTooltip()
    if Tooltip.Fade < 0.02 or not Tooltip.Current then return end

    local th = State.Theme
    local a = Tooltip.Fade

    local text = Tooltip.Current
    local textW = TextWidth(text, 12, FontSystem)
    local padX = 10
    local padY = 6
    local boxW = textW + padX * 2
    local boxH = 12 + padY * 2 + 4

    local vp = Camera.ViewportSize
    local tx = Tooltip.X + 14
    local ty = Tooltip.Y + 18

    -- flip sides if near right/bottom edges
    if tx + boxW > vp.X - 8 then
        tx = Tooltip.X - boxW - 8
    end
    if ty + boxH > vp.Y - 8 then
        ty = Tooltip.Y - boxH - 8
    end

    -- shadow + body
    Rect(tx + 2, ty + 3, boxW, boxH, Color3.new(0, 0, 0), 300, 6, 0.28 * a)
    Rect(tx, ty, boxW, boxH, th.Base, 301, 6, 0.98 * a)
    Stroke(tx, ty, boxW, boxH, th.Stroke, 302, 6, 0.6 * a)

    Text(text, tx + padX, ty + padY + 1,
         th.Text, 12, FontSystem, 303, a)
end

local function ClearTooltip()
    Tooltip.Current = nil
    Tooltip.Fade = 0
end

-- ============================================================================
--  HUD BOXES  --  persistent floating info panels, draggable
-- ============================================================================

local HUDBox = {}
HUDBox.__index = HUDBox

local HUDBoxes = {}

function HUDBox.new(opts)
    opts = opts or {}
    local self = setmetatable({
        Title    = opts.Title or "Box",
        X        = opts.X or 40,
        Y        = opts.Y or 40,
        W        = opts.W or 200,
        Lines    = {},
        Visible  = true,
        Pin      = false,
        _drag    = nil,
        _hover   = 0,
    }, HUDBox)
    HUDBoxes[#HUDBoxes + 1] = self
    return self
end

function HUDBox:SetVisible(v) self.Visible = v and true or false end

function HUDBox:Line(text, color)
    self.Lines[#self.Lines + 1] = { Text = text, Color = color }
    return self
end

function HUDBox:Clear() self.Lines = {} return self end

local function DrawHUDBoxes()
    local th = State.Theme

    for _, box in ipairs(HUDBoxes) do
        if box.Visible then
            local lineH = 16
            local headerH = 22
            local padX = 10
            local padY = 8
            local contentH = math.max(1, #box.Lines) * lineH
            local totalH = headerH + contentH + padY

            -- drag
            if box._drag then
                if Input.Down then
                    box.X = Input.X - box._drag.gx
                    box.Y = Input.Y - box._drag.gy
                else
                    box._drag = nil
                end
            end

            local hover = MouseIn(box.X, box.Y, box.W, totalH)
            box._hover = Approach(box._hover, hover and 1 or 0, 16, State.Delta)

            if hover and Input.Click then
                box._drag = { gx = Input.X - box.X, gy = Input.Y - box.Y }
                Input.Click = false
            end

            -- shadow
            Rect(box.X + 2, box.Y + 3, box.W, totalH,
                 Color3.new(0, 0, 0), 220, 8, 0.28)

            -- body
            Rect(box.X, box.Y, box.W, totalH, th.Base, 221, 8, 0.94)
            Stroke(box.X, box.Y, box.W, totalH, th.Accent, 222, 8,
                   0.4 + 0.3 * box._hover)

            -- header gradient bar
            Rect(box.X, box.Y, box.W, headerH, th.Panel, 223, 8, 0.85)
            GradientRect(box.X + 1, box.Y + 1, box.W - 2, 1.5,
                         th.AccentA, th.AccentB, 224, 0.6)

            Text(box.Title, box.X + padX, box.Y + 4,
                 th.Text, 12, FontBold, 225, 0.95,
                 box.W - padX * 2)

            -- divider
            Line(box.X + 6, box.Y + headerH,
                 box.X + box.W - 6, box.Y + headerH,
                 th.Divider, 224, 1, 0.7)

            -- lines
            for i, line in ipairs(box.Lines) do
                local ly = box.Y + headerH + padY + (i - 1) * lineH
                Text(line.Text, box.X + padX, ly,
                     line.Color or th.TextDim, 11, FontSystem, 226, 0.9,
                     box.W - padX * 2)
            end
        end
    end
end

local function HUDBox_Remove(box)
    for i, b in ipairs(HUDBoxes) do
        if b == box then
            table.remove(HUDBoxes, i)
            return
        end
    end
end

-- ============================================================================
--  CONFIG  --  save/load values keyed by tab+row path
-- ============================================================================

local function BuildPath(tab, row)
    local tabName = tab and tab.Name or "?"
    local rowName = row and row.Title or "?"
    return tabName .. "/" .. rowName
end

local function CollectConfig()
    local out = {}
    for _, tab in ipairs(State.Tabs) do
        local function walk(container, pathPrefix)
            for _, row in ipairs(container.Rows or {}) do
                local path = pathPrefix .. (row.Title or "")

                if getmetatable(row) == Section then
                    walk(row, path .. "/")
                elseif getmetatable(row) == InlineRow then
                    -- inline cells not individually tracked
                elseif row.Kind == "Toggle" then
                    out[path] = { k = "Toggle", v = row.Value }
                elseif row.Kind == "Slider" then
                    out[path] = { k = "Slider", v = row.Value }
                elseif row.Kind == "Dropdown" then
                    out[path] = { k = "Dropdown", v = row.Value }
                elseif row.Kind == "Keybind" then
                    out[path] = { k = "Keybind", v = row.Value }
                elseif row.Kind == "Textbox" then
                    out[path] = { k = "Textbox", v = row.Value }
                elseif row.Kind == "RangeSlider" then
                    out[path] = { k = "RangeSlider", lo = row.Low, hi = row.High }
                elseif row.Kind == "ColorPicker" then
                    out[path] = {
                        k = "ColorPicker",
                        r = row.Value.R, g = row.Value.G, b = row.Value.B,
                        a = row._alpha or 1,
                    }
                end
            end
        end
        walk(tab, tab.Name .. "/")
    end
    return out
end

local function ApplyConfig(data)
    if not data then return end
    for _, tab in ipairs(State.Tabs) do
        local function walk(container, pathPrefix)
            for _, row in ipairs(container.Rows or {}) do
                local path = pathPrefix .. (row.Title or "")

                if getmetatable(row) == Section then
                    walk(row, path .. "/")
                else
                    local entry = data[path]
                    if entry then
                        pcall(function()
                            if entry.k == "Toggle" then
                                row:SetValue(entry.v, true)
                            elseif entry.k == "Slider" then
                                row:SetValue(entry.v, true)
                            elseif entry.k == "Dropdown" then
                                row:SetValue(entry.v, true)
                            elseif entry.k == "Keybind" then
                                row:SetValue(entry.v, true)
                            elseif entry.k == "Textbox" then
                                row:SetValue(entry.v, true)
                            elseif entry.k == "RangeSlider" then
                                row:SetValue(entry.lo, entry.hi, true)
                            elseif entry.k == "ColorPicker" then
                                row:SetValue(Color3.new(entry.r, entry.g, entry.b), true)
                                row._alpha = entry.a or 1
                            end
                        end)
                    end
                end
            end
        end
        walk(tab, tab.Name .. "/")
    end
end

local function SaveConfig()
    local data = CollectConfig()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not ok then return false end
    local ok2 = pcall(function()
        writefile(State.ConfigFile, encoded)
    end)
    return ok2
end

local function LoadConfig()
    local ok, exists = pcall(function() return isfile(State.ConfigFile) end)
    if not ok or not exists then return false end
    local ok2, raw = pcall(function() return readfile(State.ConfigFile) end)
    if not ok2 then return false end
    local ok3, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok3 or not decoded then return false end
    ApplyConfig(decoded)
    return true
end

-- ============================================================================
--  PART 7 COMPLETE
--  Next: PART 8 -- Public API, main render loop, bootstrap
-- ============================================================================

-- ============================================================================
--  CONTENT RENDER  --  draws the active tab's rows inside the content area
-- ============================================================================

local function DrawContent()
    local tab = State.Tabs[State.ActiveIndex]
    if not tab then return end

    -- tab title header
    local titleY = Geometry.ContentY + 6
    local title = tab.Name
    Text(title, Geometry.ContentX + Layout.ContentPadX, titleY,
         State.Theme.Text, 16, FontBold, 60, 0.98,
         Geometry.ContentW - Layout.ContentPadX * 2)

    -- subtitle (optional)
    if tab.Subtitle and tab.Subtitle ~= "" then
        Text(tab.Subtitle,
             Geometry.ContentX + Layout.ContentPadX, titleY + 20,
             State.Theme.TextDim, 11, FontSystem, 60, 0.7,
             Geometry.ContentW - Layout.ContentPadX * 2)
    end

    -- thin underline under the title
    Line(
        Geometry.ContentX + Layout.ContentPadX,
        titleY + (tab.Subtitle and 38 or 22),
        Geometry.ContentX + Geometry.ContentW - Layout.ContentPadX,
        titleY + (tab.Subtitle and 38 or 22),
        State.Theme.Divider, 60, 1, 0.6
    )

    local headerH = (tab.Subtitle and 42 or 26)

    -- sub-tab bar
    local subH = 0
    if tab.Subs and #tab.Subs > 0 then
        subH = DrawSubTabs(
            tab,
            Geometry.ContentX + Layout.ContentPadX,
            Geometry.ContentY + headerH,
            Geometry.ContentW - Layout.ContentPadX * 2
        )
    end

    -- choose the row container
    local container = tab
    if tab.ActiveSub then container = tab.ActiveSub end

    -- scroll target
    local viewportTop = Geometry.ContentY + headerH + subH + Layout.ContentPadY
    local viewportH = Geometry.ContentH - (headerH + subH) - Layout.ContentPadY * 2

    -- layout pass: measure everything first so we know max scroll
    local measureY = 0
    local function measureRow(row, x, w, into)
        if row.Hidden then return end

        if getmetatable(row) == Section then
            into.y = into.y + 22 + Layout.SectionGap
            for _, child in ipairs(row.Rows or {}) do
                measureRow(child, x, w, into)
                into.y = into.y + Layout.RowGapY
            end
        elseif getmetatable(row) == InlineRow then
            local h = 0
            for _, ctrl in ipairs(row.Cells or {}) do
                if ctrl.Height and ctrl.Height > h then h = ctrl.Height end
            end
            into.y = into.y + (h > 0 and h or Layout.RowHeight)
        else
            into.y = into.y + (row.Height or Layout.RowHeight)
        end
    end

    local acc = { y = 0 }
    for _, row in ipairs(container.Rows or {}) do
        measureRow(row, Geometry.InnerX, Geometry.InnerW, acc)
        acc.y = acc.y + Layout.RowGapY
    end

    container.MaxScroll = math.max(0, acc.y - viewportH)
    TickScroll(container, State.Delta)
    HandleWheel(container)

    -- render pass: draw from -scroll offset
    local cy = viewportTop - container.Scroll
    local baseY = cy

    for _, row in ipairs(container.Rows or {}) do
        if not row.Hidden then
            local h = DrawRow(row, Geometry.InnerX, cy, Geometry.InnerW)
            cy = cy + (h or Layout.RowHeight) + Layout.RowGapY
        end
    end

    -- scrollbar
    DrawScrollbar(container)
end

-- ============================================================================
--  CONTENT INPUT  --  routes clicks/wheel into the active tab's rows
-- ============================================================================

local function InputContent()
    local tab = State.Tabs[State.ActiveIndex]
    if not tab then return end

    -- global pre-checks
    if not MouseIn(Geometry.ContentX, Geometry.ContentY,
                   Geometry.ContentW, Geometry.ContentH) then
        return
    end

    local container = tab
    if tab.ActiveSub then container = tab.ActiveSub end

    -- header/sub-tab region absorbs clicks (already handled in DrawSubTabs)
    local subH = 0
    if tab.Subs and #tab.Subs > 0 then
        subH = 24 + Layout.RowGapY
    end
    local headerH = (tab.Subtitle and 42 or 26)

    local viewportTop = Geometry.ContentY + headerH + subH + Layout.ContentPadY

    -- offset by scroll
    local cy = viewportTop - container.Scroll

    for _, row in ipairs(container.Rows or {}) do
        if not row.Hidden then
            InputRow(row, Geometry.InnerX, cy, Geometry.InnerW)
            cy = cy + (row.Height or Layout.RowHeight) + Layout.RowGapY
        end
    end

    -- click in empty content area = close popups
    if Input.Click then
        if State.Popup then
            State.Popup = nil
        end
    end
end

-- ============================================================================
--  TAB MANAGEMENT  --  public helpers
-- ============================================================================

local function FindTab(name)
    for i, tab in ipairs(State.Tabs) do
        if tab.Name == name then return tab, i end
    end
    return nil, nil
end

local function SetActiveTab(index)
    if index >= 1 and index <= #State.Tabs then
        State.ActiveIndex = index
    end
end

local function SetActiveTabByName(name)
    local _, idx = FindTab(name)
    if idx then State.ActiveIndex = idx end
end

-- ============================================================================
--  THEME SWITCHING  --  tween between theme palettes
-- ============================================================================

local ThemeTween = {
    Active = false,
    From = nil,
    To = nil,
    T = 0,
    Duration = 0.35,
}

local function SwitchTheme(index)
    if index == State.ThemeIndex then return end
    local new = Themes[index]
    if not new then return end

    if State.NoAnim then
        State.Theme = new
        State.ThemeIndex = index
        return
    end

    -- capture current as "from"
    local from = {}
    for k, v in pairs(State.Theme) do
        if typeof(v) == "Color3" then from[k] = v end
    end

    ThemeTween.Active = true
    ThemeTween.From = from
    ThemeTween.To = new
    ThemeTween.T = 0
    State.ThemeIndex = index
end

local function TickTheme(dt)
    if not ThemeTween.Active then return end

    ThemeTween.T = ThemeTween.T + dt / ThemeTween.Duration
    if ThemeTween.T >= 1 then ThemeTween.T = 1 end

    local t = ThemeTween.T
    -- ease-out cubic
    t = 1 - (1 - t) ^ 3

    local from = ThemeTween.From
    local to   = ThemeTween.To
    local result = {}
    for k, v in pairs(to) do
        if typeof(v) == "Color3" and from[k] then
            result[k] = mix(from[k], v, t)
        else
            result[k] = v
        end
    end
    State.Theme = result

    if ThemeTween.T >= 1 then
        ThemeTween.Active = false
        State.Theme = to
    end
end

local function SetThemeByName(name)
    for i, th in ipairs(Themes) do
        if th.Name == name then
            SwitchTheme(i)
            return true
        end
    end
    return false
end

local function NextTheme()
    local nxt = State.ThemeIndex + 1
    if nxt > #Themes then nxt = 1 end
    SwitchTheme(nxt)
end

-- ============================================================================
--  OPEN / CLOSE  --  visibility animation
-- ============================================================================

local function TickVisibility(dt)
    local target = State.Open and 1 or 0
    if State.NoAnim then
        State.Visible = target
    else
        State.Visible = Approach(State.Visible, target, 16, dt)
        if math.abs(State.Visible - target) < 0.01 then
            State.Visible = target
        end
    end
    FrameAlpha = State.Visible
end

local function ToggleUI()
    State.Open = not State.Open
    if not State.Open then
        ClearFocus()
        CancelCapture()
        State.Popup = nil
        ClearTooltip()
    end
end

-- ============================================================================
--  MAIN RENDER PASS  --  runs every frame
-- ============================================================================

local LastHotkeyState = false

local function Render()
    -- read inputs
    ReadInput()
    ReadKeys()

    -- measure dt
    local now = os.clock()
    State.Delta = math.min(now - State.LastTick, 1 / 20)
    State.LastTick = now
    State.Frame = State.Frame + 1

    -- input capture dispatcher
    UpdateCapture()

    -- text focus
    TickFocus()

    -- hotkey toggle
    local key = string.lower(State.MenuKey)
    local hk = Keys[string.upper(key)]
    if hk then
        if hk.Click then ToggleUI() end
    end

    -- spotlight pre-empt
    if Spotlight.Open then
        -- reset pool, draw only spotlight at top of everything
        ResetPool()
        DrawSpotlight()
        HideUnused()
        return
    end

    -- lifecycle
    TickVisibility(State.Delta)
    TickTheme(State.Delta)

    if State.Visible < 0.005 then
        -- window hidden: skip everything
        ResetPool()
        -- but notifications/tooltips still show
        TickNotifications(State.Delta)
        DrawNotifications()
        HideUnused()
        return
    end

    -- animate/state updates first. Geometry must be calculated AFTER these
    -- so every element uses the exact same window position for this frame.
    TickRailOpen(State.Delta)
    TickDrag(State.Delta)
    TickResize()
    TickTooltip(State.Delta)

    -- geometry
    Geometry.Recalculate()

    -- reset drawing pool for this frame
    ResetPool()

    -- render back-to-front
    DrawFrame()
    DrawTitleBar("SHADOW UI")
    DrawTabRail()
    DrawContent()

    -- input for the interactive regions
    InputContent()

    -- drag from title bar handled in DrawTitleBar already

    -- notifications & tooltips sit above everything
    TickNotifications(State.Delta)
    DrawNotifications()
    DrawTooltip()

    -- HUD boxes
    DrawHUDBoxes()

    -- resize handle is topmost interactive
    DrawResizeHandle()

    -- hide unused drawing objects
    HideUnused()
end

-- ============================================================================
--  HOTKEY HELPER  --  detect a keybind string like "q+ctrl" against Keys
-- ============================================================================

local function IsBindHeld(bindName)
    if not bindName or bindName == "" then return false end

    for segment in string.gmatch(bindName, "[^+]+") do
        local seg = string.upper(segment)
        local key = Keys[seg]
        if not key or not key.Held then return false end
    end
    return true
end

local function IsBindClicked(bindName)
    if not bindName or bindName == "" then return false end

    local clickedAny = false
    for segment in string.gmatch(bindName, "[^+]+") do
        local seg = string.upper(segment)
        local key = Keys[seg]
        if not key or not key.Held then return false end
        if key.Click then clickedAny = true end
    end
    return clickedAny
end

-- ============================================================================
--  PUBLIC API  --  the ShadowUI table every user script talks to
-- ============================================================================

local ShadowUI = {}

ShadowUI.Themes         = Themes
ShadowUI.Layout         = Layout
ShadowUI.State          = State
ShadowUI.Tabs           = {}

-- tabs ----------------------------------------------------------------------
function ShadowUI:AddTab(opts)
    opts = opts or {}
    local tab = Tab.new(self, opts)
    if opts.Select then
        State.ActiveIndex = #State.Tabs
    end
    return tab
end

function ShadowUI:GetTab(name)
    local tab = FindTab(name)
    return tab
end

function ShadowUI:SelectTab(name)
    SetActiveTabByName(name)
end

-- notifications -------------------------------------------------------------
function ShadowUI:Notify(opts)
    return Notify(opts)
end

-- theme ---------------------------------------------------------------------
function ShadowUI:SetTheme(name)
    return SetThemeByName(name)
end

function ShadowUI:NextTheme()
    NextTheme()
end

-- hotkey --------------------------------------------------------------------
function ShadowUI:SetKeybind(key)
    State.MenuKey = string.lower(tostring(key))
end

-- config --------------------------------------------------------------------
function ShadowUI:Save()
    return SaveConfig()
end

function ShadowUI:Load()
    return LoadConfig()
end

function ShadowUI:SetConfigFile(path)
    State.ConfigFile = path
end

-- lifecycle ----------------------------------------------------------------
function ShadowUI:Toggle()   ToggleUI() end
function ShadowUI:Show()     State.Open = true end
function ShadowUI:Hide()     State.Open = false end

function ShadowUI:IsAlive() return State.Alive end

function ShadowUI:Destroy()
    State.Alive = false
    pcall(function() SaveConfig() end)
    ClearPool()
    ClearFocus()
    CancelCapture()
    _G.ShadowUI = nil
end

-- HUD boxes ----------------------------------------------------------------
function ShadowUI:CreateBox(opts)
    return HUDBox.new(opts)
end

ShadowUI.IsBindHeld    = IsBindHeld
ShadowUI.IsBindClicked = IsBindClicked


local function AttachControl(parentType, methodName, ctorName)
    local ctor = Controls[ctorName]
    if not ctor then return end
    parentType[methodName] = function(self, opts)
        return ctor(self, opts)
    end
end

for _, parentType in ipairs({ Tab, Section, SubTab }) do
    AttachControl(parentType, "AddLabel",       "Label")
    AttachControl(parentType, "AddDivider",     "Divider")
    AttachControl(parentType, "AddButton",      "Button")
    AttachControl(parentType, "AddToggle",      "Toggle")
    AttachControl(parentType, "AddSlider",      "Slider")
    AttachControl(parentType, "AddRangeSlider", "RangeSlider")
    AttachControl(parentType, "AddDropdown",    "Dropdown")
    AttachControl(parentType, "AddKeybind",     "Keybind")
    AttachControl(parentType, "AddTextbox",     "Textbox")
    AttachControl(parentType, "AddColorPicker", "ColorPicker")
end

function Tab:AddSubTab(name, icon)
    return SubTab.new(self, name, icon)
end

function Tab:AddSection(title)
    return Section.new(self, title)
end

function Tab:AddInline(weights)
    return InlineRow.new(self, weights)
end

function Section:AddInline(weights)
    return InlineRow.new(self, weights)
end


function InlineRow:AddRow(builder)
    self.Cells[#self.Cells + 1] = builder
    return builder
end

for _, ctrlName in ipairs({
    "Label", "Divider", "Toggle", "Slider", "RangeSlider",
    "Dropdown", "Keybind", "Textbox", "ColorPicker", "Button"
}) do
    AttachControl(InlineRow, "Add" .. ctrlName, ctrlName)
end

-- [FIX] allow chaining control creation: `row:AddToggle({}):AddToggle({})`
for _, ctrlName in ipairs({
    "Label", "Divider", "Toggle", "Slider", "RangeSlider",
    "Dropdown", "Keybind", "Textbox", "ColorPicker", "Button"
}) do
    local ctor = Controls[ctrlName]
    if ctor then
        Base["Add" .. ctrlName] = function(self, opts)
            return ctor(self.Parent, opts)
        end
    end
end

_G.ShadowUI = ShadowUI
_G.Shadow   = ShadowUI   -- alias

do
    local prev = _G.ShadowUI
    if prev and prev ~= ShadowUI and prev.Destroy then
        pcall(function() prev:Destroy() end)
    end
end

do
    local vp = Camera.ViewportSize
    State.X = math.floor((vp.X - State.W) / 2)
    State.Y = math.floor((vp.Y - State.H) / 2)
end

pcall(LoadConfig)

task.spawn(function()
    while State.Alive do
        local ok, err = pcall(Render)
        if not ok then
            warn("[ShadowUI] render error:", tostring(err))
        end
        task.wait(1 / 60)
    end
end)

task.spawn(function()
    while State.Alive do
        task.wait(15)
        pcall(SaveConfig)
    end
end)

ShadowUI:Notify({
    Title   = "Shadow UI loaded",
    Content = "Press " .. string.upper(State.MenuKey) .. " to toggle",
    Type    = "info",
    Duration = 4,
})
