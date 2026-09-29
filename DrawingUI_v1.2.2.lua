--[[
================================================================================
  DRAWING UI LIBRARY  ::  1.2.0
  ------------------------------------------------------------------------------
  A modern, resizable, inline-capable Drawing-based UI library for Matcha.
  Designed from scratch with reference to REM UI and INS-UI, but:
    - Dark glass aesthetic
    - Corner-drag resize handle
    - True in-line row layout
    - Scroll-wheel + scrollbar
    - Icon font rendered from line segments (no image data)
  ------------------------------------------------------------------------------
  Load:  loadstring(game:HttpGet("<your gist raw url>"))()
  Use:   local UI = loadstring(game:HttpGet("<raw library url>"))()
================================================================================
--]]

local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")
local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()
local Camera        = workspace.CurrentCamera

local Fonts         = Drawing.Fonts

-- approximate per-character width multipliers, used for text fitting
local FontMetrics = {
    [Fonts.System] = 0.48,
    [Fonts.SystemBold]   = 0.52,
    [Fonts.UI]     = 0.50,
    [Fonts.Monospace]   = 0.60,
    [Fonts.Pixel]  = 0.50,
}

-- Matcha's complete Drawing.Fonts set currently exposed by this library.
-- Store the resolver on the existing Fonts table instead of allocating more
-- top-level locals; Matcha/Lua chunks have a hard 200-register ceiling.
Fonts.ResolveOverlay = function(value, fallback)
    if value == nil then return fallback or Fonts.SystemBold end
    if type(value) ~= "string" then return value end
    local key = string.lower(value)
    key = string.gsub(key, "[%s_%-]", "")
    if key == "system" then return Fonts.System end
    if key == "systembold" or key == "bold" then return Fonts.SystemBold end
    if key == "ui" then return Fonts.UI end
    if key == "monospace" or key == "mono" then return Fonts.Monospace end
    if key == "pixel" then return Fonts.Pixel end
    return fallback or Fonts.SystemBold
end

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
        Base        = rgb(36, 40, 54),      -- window background
        Panel       = rgb(46, 51, 68),      -- control card background
        PanelHi     = rgb(58, 64, 82),      -- hover/active panel
        Stroke      = rgb(78, 85, 110),      -- panel borders
        Divider     = rgb(78, 86, 112),
        Text        = rgb(232, 234, 245),
        TextDim     = rgb(202, 207, 223),
        TextMuted   = rgb(154, 160, 181),
        AccentA     = rgb(120, 140, 255),
        AccentB     = rgb(180, 130, 255),
        Accent      = rgb(150, 135, 255),
        AccentDim   = rgb(96, 90, 180),
        Track       = rgb(66, 72, 94),
        TrackFill   = rgb(120, 140, 255),
        Danger      = rgb(255, 96, 120),
        Warning     = rgb(255, 190, 90),
        Success     = rgb(120, 230, 170),
    },
    {
        Name        = "Obsidian",
        Base        = rgb(33, 35, 43),
        Panel       = rgb(43, 45, 55),
        PanelHi     = rgb(56, 59, 70),
        Stroke      = rgb(73, 76, 92),
        Divider     = rgb(74, 78, 98),
        Text        = rgb(228, 228, 235),
        TextDim     = rgb(200, 202, 216),
        TextMuted   = rgb(151, 153, 170),
        AccentA     = rgb(120, 220, 210),
        AccentB     = rgb(90, 180, 240),
        Accent      = rgb(105, 200, 225),
        AccentDim   = rgb(70, 130, 160),
        Track       = rgb(63, 65, 79),
        TrackFill   = rgb(120, 220, 210),
        Danger      = rgb(255, 90, 110),
        Warning     = rgb(255, 180, 80),
        Success     = rgb(110, 220, 160),
    },
    {
        Name        = "Burgundy",
        Base        = rgb(44, 27, 35),
        Panel       = rgb(57, 35, 45),
        PanelHi     = rgb(69, 42, 53),
        Stroke      = rgb(96, 60, 74),
        Divider     = rgb(94, 58, 72),
        Text        = rgb(245, 232, 235),
        TextDim     = rgb(195, 166, 176),
        TextMuted   = rgb(139, 106, 117),
        AccentA     = rgb(255, 130, 150),
        AccentB     = rgb(255, 90, 140),
        Accent      = rgb(255, 110, 145),
        AccentDim   = rgb(160, 70, 95),
        Track       = rgb(56, 35, 44),
        TrackFill   = rgb(255, 130, 150),
        Danger      = rgb(255, 80, 80),
        Warning     = rgb(255, 190, 90),
        Success     = rgb(140, 220, 160),
    },

    {
        Name="Cyber",
        Base=rgb(8,12,22), Panel=rgb(12,20,34), PanelHi=rgb(18,29,47),
        Stroke=rgb(31,82,105), Divider=rgb(24,69,91),
        Text=rgb(231,250,255), TextDim=rgb(166,218,229), TextMuted=rgb(103,153,169),
        AccentA=rgb(0,229,255), AccentB=rgb(170,75,255), Accent=rgb(0,210,245),
        AccentDim=rgb(24,111,139), Track=rgb(24,45,62), TrackFill=rgb(0,229,255),
        Danger=rgb(255,78,116), Warning=rgb(255,194,92), Success=rgb(70,231,161),
    },
    {
        Name="Bubblegum",
        Base=rgb(34,20,39), Panel=rgb(48,27,55), PanelHi=rgb(62,34,69),
        Stroke=rgb(104,58,96), Divider=rgb(92,49,85),
        Text=rgb(255,239,249), TextDim=rgb(236,184,218), TextMuted=rgb(176,122,160),
        AccentA=rgb(255,104,181), AccentB=rgb(118,188,255), Accent=rgb(245,116,190),
        AccentDim=rgb(155,70,122), Track=rgb(72,40,68), TrackFill=rgb(255,104,181),
        Danger=rgb(255,84,116), Warning=rgb(255,190,105), Success=rgb(102,226,169),
    },
    {
        Name="Emerald",
        Base=rgb(10,24,20), Panel=rgb(14,34,28), PanelHi=rgb(20,47,38),
        Stroke=rgb(42,91,74), Divider=rgb(35,78,64),
        Text=rgb(233,255,247), TextDim=rgb(169,218,201), TextMuted=rgb(109,161,143),
        AccentA=rgb(55,232,154), AccentB=rgb(73,198,255), Accent=rgb(55,220,148),
        AccentDim=rgb(35,135,96), Track=rgb(28,61,51), TrackFill=rgb(55,232,154),
        Danger=rgb(255,91,109), Warning=rgb(250,190,91), Success=rgb(55,232,154),
    },
    {
        Name="Crimson",
        Base=rgb(30,13,17), Panel=rgb(43,18,24), PanelHi=rgb(57,23,31),
        Stroke=rgb(103,42,53), Divider=rgb(88,34,45),
        Text=rgb(255,239,241), TextDim=rgb(225,174,181), TextMuted=rgb(165,111,120),
        AccentA=rgb(255,70,92), AccentB=rgb(255,145,72), Accent=rgb(246,73,96),
        AccentDim=rgb(153,46,62), Track=rgb(68,29,37), TrackFill=rgb(255,70,92),
        Danger=rgb(255,70,92), Warning=rgb(255,177,80), Success=rgb(85,222,148),
    },
    {
        Name="Arctic",
        Base=rgb(13,23,34), Panel=rgb(18,33,47), PanelHi=rgb(25,46,64),
        Stroke=rgb(54,94,116), Divider=rgb(45,81,102),
        Text=rgb(239,250,255), TextDim=rgb(181,216,232), TextMuted=rgb(119,158,178),
        AccentA=rgb(115,210,255), AccentB=rgb(177,149,255), Accent=rgb(111,201,247),
        AccentDim=rgb(69,128,160), Track=rgb(35,61,79), TrackFill=rgb(115,210,255),
        Danger=rgb(255,100,125), Warning=rgb(255,197,104), Success=rgb(94,224,170),
    },
    {
        Name="Sunset",
        Base=rgb(34,18,23), Panel=rgb(48,24,31), PanelHi=rgb(62,30,39),
        Stroke=rgb(109,58,55), Divider=rgb(95,49,48),
        Text=rgb(255,243,236), TextDim=rgb(232,190,171), TextMuted=rgb(173,126,112),
        AccentA=rgb(255,132,74), AccentB=rgb(255,79,151), Accent=rgb(255,116,82),
        AccentDim=rgb(163,73,65), Track=rgb(75,39,43), TrackFill=rgb(255,132,74),
        Danger=rgb(255,77,102), Warning=rgb(255,184,83), Success=rgb(102,224,151),
    },

}

-- ============================================================================
--  BACKGROUND EFFECTS / WINDOW APPEARANCE
-- ============================================================================

local BackgroundNames = {
    none = true,
    dots = true,
    scanlines = true,
    particles = true,
    aurora = true,
    snow = true,
    rainfall = true,
}

local function NormalizeBackground(value)
    if type(value) == "table" then
        local kind = string.lower(tostring(value.Type or value.type or value.Name or value.name or "none"))
        local out = {}
        for k, v in pairs(value) do out[k] = v end
        out.Type = BackgroundNames[kind] and kind or "none"
        return out
    end
    local kind = string.lower(tostring(value or "none"))
    if not BackgroundNames[kind] then kind = "none" end
    return kind
end


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
    TabRailMinW     = 94,
    TabRailNarrow   = 94,

    -- tab / section
    TabRowH         = 34,
    TabGap          = 7,
    TabIcon         = 16,
    SectionH        = 22,
    SectionGap      = 12,
    SectionColumnGap = 12,
    SectionPadX     = 16,
    SectionPadY     = 12,
    SectionCorner   = 12,
    SectionTitleH   = 18,
    SectionDescH    = 16,

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
--  PERSISTENT IMAGE LOADER  --  INS-style raw byte loading for Matcha
-- ============================================================================

local function IsPictureBytes(bytes)
    if type(bytes) ~= "string" or #bytes < 24 then return false end
    local a, b = string.byte(bytes, 1, 2)
    return (a == 137 and b == 80)      -- PNG
        or (a == 255 and b == 216)     -- JPEG
        or (a == 71 and b == 73)       -- GIF
end

local function PictureHash(text)
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % 2147483648
    end
    return string.format("%08x", hash)
end

local function ReadPictureBytes(source, kind)
    local target = tostring(source or "")
    if target == "" then return nil end
    if IsPictureBytes(target) then return target end

    local remote = string.find(target, "://", 1, true) ~= nil
    local cache = "DrawingUI_" .. tostring(kind or "image") .. "_" .. PictureHash(target) .. ".dat"

    if not remote then
        local ok, exists = pcall(function() return isfile and isfile(target) end)
        if ok and exists then
            local readOk, bytes = pcall(function() return readfile(target) end)
            if readOk and IsPictureBytes(bytes) then return bytes end
        end
    end

    do
        local ok, exists = pcall(function() return isfile and isfile(cache) end)
        if ok and exists then
            local readOk, bytes = pcall(function() return readfile(cache) end)
            if readOk and IsPictureBytes(bytes) then return bytes end
        end
    end

    if not remote then return nil end

    local ok, bytes = pcall(function()
        if httpget then return httpget(target) end
        if game and game.HttpGet then return game:HttpGet(target) end
        return nil
    end)
    if not ok or not IsPictureBytes(bytes) then return nil end

    pcall(function()
        if writefile then writefile(cache, bytes) end
    end)

    return bytes
end

local function LoadPicture(source, kind)
    if source == nil or source == "" then return nil end
    local holder = { Image = nil, Source = source }

    if IsPictureBytes(source) then
        local image = Drawing.new("Image")
        image.Data = source
        image.Visible = false
        holder.Image = image
        return holder
    end

    task.spawn(function()
        local bytes = ReadPictureBytes(source, kind)
        if bytes then
            local image = Drawing.new("Image")
            image.Data = bytes
            image.Visible = false
            holder.Image = image
        end
    end)

    return holder
end

local function DrawPicture(holder, x, y, width, height, z, transparency, corner)
    local image = holder and holder.Image
    if not image then return false end

    image.Position = Vector2.new(x, y)
    image.Size = Vector2.new(width, height)
    pcall(function() image.Rounding = corner or 0 end)
    image.ZIndex = z
    image.Transparency = math.max(0, math.min(1, transparency or 1))
    image.Visible = image.Transparency > 0.01
    return true
end

local function HidePicture(holder)
    if holder and holder.Image then holder.Image.Visible = false end
end

-- ============================================================================
--  PRIMITIVE DRAWERS  --  every visual element goes through one of these
-- ============================================================================

local FrameAlpha = 1  -- global fade multiplier used during open/close

-- Dedicated surface renderer for the main glass pane. This deliberately does
-- not share the normal Rect() alpha value, so changing the glass strength
-- cannot alter buttons, sliders, overlays, text, or other controls.
local GlassSurfaceAlpha = 0.85

local function GlassSurface(x, y, w, h, color, z, corner)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color and l.ColorWritable ~= false then
        local ok = pcall(function() o.Color = color end)
        if ok then
            l.Color = color
            l.ColorWritable = true
        else
            -- Matcha can expose pooled Drawing objects whose runtime type does
            -- not implement Color. Mark this object so we do not throw every frame.
            l.ColorWritable = false
        end
    end
    if not l.Filled then l.Filled = true; o.Filled = true end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = GlassSurfaceAlpha * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
end

local function SolidSurface(x, y, w, h, color, z, corner)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color and l.ColorWritable ~= false then
        local ok = pcall(function() o.Color = color end)
        if ok then
            l.Color = color
            l.ColorWritable = true
        else
            -- Matcha can expose pooled Drawing objects whose runtime type does
            -- not implement Color. Mark this object so we do not throw every frame.
            l.ColorWritable = false
        end
    end
    if not l.Filled then l.Filled = true; o.Filled = true end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    -- Fully solid surface. Only the normal window fade can reduce it.
    local a = FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
end

-- Dark translucent surface used for detached panels that should feel like
-- frosted glass instead of a separate solid block.
local FrostedSurfaceAlpha = 0.68

local function FrostedSurface(x, y, w, h, color, z, corner)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color and l.ColorWritable ~= false then
        local ok = pcall(function() o.Color = color end)
        if ok then
            l.Color = color
            l.ColorWritable = true
        else
            -- Matcha can expose pooled Drawing objects whose runtime type does
            -- not implement Color. Mark this object so we do not throw every frame.
            l.ColorWritable = false
        end
    end
    if not l.Filled then l.Filled = true; o.Filled = true end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = FrostedSurfaceAlpha * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
end

local function Rect(x, y, w, h, color, z, corner, alpha)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color and l.ColorWritable ~= false then
        local ok = pcall(function() o.Color = color end)
        if ok then
            l.Color = color
            l.ColorWritable = true
        else
            -- Matcha can expose pooled Drawing objects whose runtime type does
            -- not implement Color. Mark this object so we do not throw every frame.
            l.ColorWritable = false
        end
    end
    if not l.Filled then l.Filled = true; o.Filled = true end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
end

local function Stroke(x, y, w, h, color, z, corner, alpha)
    if w <= 0 or h <= 0 then DrawOrder = DrawOrder + 1; return end
    local o, l = Take("Square")
    local depth = Layer(z)

    if l.X ~= x or l.Y ~= y then l.X, l.Y = x, y; o.Position = Vector2.new(x, y) end
    if l.W ~= w or l.H ~= h then l.W, l.H = w, h; o.Size = Vector2.new(w, h) end
    if l.Color ~= color and l.ColorWritable ~= false then
        local ok = pcall(function() o.Color = color end)
        if ok then
            l.Color = color
            l.ColorWritable = true
        else
            -- Matcha can expose pooled Drawing objects whose runtime type does
            -- not implement Color. Mark this object so we do not throw every frame.
            l.ColorWritable = false
        end
    end
    if l.Filled ~= false then l.Filled = false; o.Filled = false end
    if l.Corner ~= corner then l.Corner = corner; o.Corner = corner end
    if l.Depth ~= depth then l.Depth = depth; o.ZIndex = depth end

    local a = (alpha or 1) * FrameAlpha
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
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
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
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
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
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
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
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
    if l.Alpha ~= a then l.Alpha = a; o.Transparency = a end
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
    ["home"] = {
        {3.5,9.5,10,3.8,1.55,1},{10,3.8,16.5,9.5,1.55,1},
        {5.2,8.1,5.2,16.2,1.5,1},{5.2,16.2,14.8,16.2,1.5,1},{14.8,16.2,14.8,8.1,1.5,1},
        {8.4,16.2,8.4,11.2,1.35,1},{8.4,11.2,11.6,11.2,1.35,1},{11.6,11.2,11.6,16.2,1.35,1}
    },
    ["gear"]      = {
        {10,3, 10,5, 1.6, 1}, {10,15, 10,17, 1.6, 1},
        {3,10, 5,10, 1.6, 1}, {15,10, 17,10, 1.6, 1},
        {5.2,5.2, 6.6,6.6, 1.5, 1}, {13.4,13.4, 14.8,14.8, 1.5, 1},
        {5.2,14.8, 6.6,13.4, 1.5, 1}, {14.8,5.2, 13.4,6.6, 1.5, 1},
        {10,6.5, 13.5,10, 1.6, 0.9}, {13.5,10, 10,13.5, 1.6, 0.9},
        {10,13.5, 6.5,10, 1.6, 0.9}, {6.5,10, 10,6.5, 1.6, 0.9},
    },
    ["folder"]    = { {3,6, 8,6, 1.5, 1}, {8,6, 10,8, 1.5, 1}, {10,8, 17,8, 1.5, 1}, {17,8, 16,16, 1.5, 1}, {16,16, 3,16, 1.5, 1}, {3,16, 3,6, 1.5, 1} },
    ["file"]      = { {5,3, 5,17, 1.6, 1}, {5,3, 13,3, 1.6, 1}, {13,3, 15,5, 1.6, 1}, {15,5, 15,17, 1.6, 1}, {15,17, 5,17, 1.6, 1}, {13,3, 13,5, 1.6, 1}, {13,5, 15,5, 1.6, 1} },

    -- UI glyphs
    ["user"]      = { {10,4, 10,4.5, 1.8, 1}, {7,7, 13,7, 1.6, 1}, {7,7, 7,10, 1.6, 1}, {13,7, 13,10, 1.6, 1}, {7,10, 13,10, 1.6, 1}, {5,17, 10,12, 1.6, 1}, {15,17, 10,12, 1.6, 1}, {5,17, 15,17, 1.6, 1} },
    ["shield"]    = { {10,3, 16,5, 1.6, 1}, {16,5, 16,10, 1.6, 1}, {16,10, 10,17, 1.6, 1}, {10,17, 4,10, 1.6, 1}, {4,10, 4,5, 1.6, 1}, {4,5, 10,3, 1.6, 1} },
    ["bell"]      = { {6,9, 6,14, 1.6, 1}, {14,9, 14,14, 1.6, 1}, {6,9, 10,4, 1.6, 1}, {10,4, 14,9, 1.6, 1}, {4,14, 16,14, 1.6, 1}, {9,16, 11,16, 1.6, 1} },
    ["eye"] = {
        {2.8,10,5.8,7,1.5,1},{5.8,7,10,5.4,1.5,1},{10,5.4,14.2,7,1.5,1},
        {14.2,7,17.2,10,1.5,1},{17.2,10,14.2,13,1.5,1},{14.2,13,10,14.6,1.5,1},
        {10,14.6,5.8,13,1.5,1},{5.8,13,2.8,10,1.5,1},
        {7.8,10,8.45,8.45,1.45,1},{8.45,8.45,10,7.8,1.45,1},
        {10,7.8,11.55,8.45,1.45,1},{11.55,8.45,12.2,10,1.45,1},
        {12.2,10,11.55,11.55,1.45,1},{11.55,11.55,10,12.2,1.45,1},
        {10,12.2,8.45,11.55,1.45,1},{8.45,11.55,7.8,10,1.45,1}
    },
    ["search"]    = { {3,3, 12,3, 1.6, 1}, {12,3, 12,12, 1.6, 1}, {12,12, 3,12, 1.6, 1}, {3,12, 3,3, 1.6, 1}, {12,12, 17,17, 2, 1} },
    ["crosshair"] = { {10,3, 10,7, 1.4, 1}, {10,13, 10,17, 1.4, 1}, {3,10, 7,10, 1.4, 1}, {13,10, 17,10, 1.4, 1}, {6,10, 6,7, 1.3, 0.8}, {6,7, 10,7, 1.3, 0.8}, {10,7, 14,7, 1.3, 0.8}, {14,7, 14,10, 1.3, 0.8}, {14,10, 14,13, 1.3, 0.8}, {14,13, 10,13, 1.3, 0.8}, {10,13, 6,13, 1.3, 0.8}, {6,13, 6,10, 1.3, 0.8} },
    ["play"]      = { {6,4, 6,16, 1.8, 1}, {6,4, 16,10, 1.8, 1}, {6,16, 16,10, 1.8, 1} },
    ["pause"]     = { {7,4, 7,16, 1.8, 1}, {13,4, 13,16, 1.8, 1} },
    ["stop"]      = { {5,5, 15,5, 1.8, 1}, {15,5, 15,15, 1.8, 1}, {15,15, 5,15, 1.8, 1}, {5,15, 5,5, 1.8, 1} },
    ["refresh"]   = { {5,6, 10,4, 1.6, 1}, {10,4, 15,6, 1.6, 1}, {15,6, 16,11, 1.6, 1}, {16,11, 13,15, 1.6, 1}, {13,15, 8,16, 1.6, 1}, {8,16, 4,13, 1.6, 1} },
    ["download"]  = { {10,3, 10,13, 1.8, 1}, {6,9, 10,13, 1.8, 1}, {14,9, 10,13, 1.8, 1}, {5,16, 15,16, 1.8, 1} },
    ["upload"]    = { {10,17, 10,7, 1.8, 1}, {6,11, 10,7, 1.8, 1}, {14,11, 10,7, 1.8, 1}, {5,4, 15,4, 1.8, 1} },
    ["trash"]     = { {5,5, 5,17, 1.6, 1}, {15,5, 15,17, 1.6, 1}, {5,17, 15,17, 1.6, 1}, {5,5, 15,5, 1.6, 1}, {7,5, 7,3, 1.6, 1}, {13,5, 13,3, 1.6, 1}, {7,3, 13,3, 1.6, 1} },
    ["edit"]      = { {5,15, 7,9, 1.6, 1}, {7,9, 15,3, 1.6, 1}, {15,3, 17,5, 1.6, 1}, {17,5, 9,11, 1.6, 1}, {9,11, 5,15, 1.6, 1}, {5,15, 3,17, 1.6, 1}, {3,17, 5,17, 1.6, 1} },

    -- status glyphs
    ["info"]      = { {10,4.2,10,4.7,2.1,1}, {10,8,10,15.5,1.75,1}, {8.3,8,10,8,1.55,0.9} },
    ["warning"]   = { {10,2.8,17.2,16.4,1.65,1}, {17.2,16.4,2.8,16.4,1.65,1}, {2.8,16.4,10,2.8,1.65,1}, {10,7.2,10,12.2,1.8,1}, {10,14.2,10,14.7,2.1,1} },
    ["error"]     = { {4.2,4.2,15.8,15.8,1.8,1}, {15.8,4.2,4.2,15.8,1.8,1} },
    ["success"]   = { {4.2,10.2,8.2,14.1,1.9,1}, {8.2,14.1,15.9,5.8,1.9,1} },

    -- misc
    ["star"]      = { {10,3, 11.5,8, 1.5, 1}, {11.5,8, 17,8, 1.5, 1}, {17,8, 12.5,11.5, 1.5, 1}, {12.5,11.5, 14.5,17, 1.5, 1}, {14.5,17, 10,13.5, 1.5, 1}, {10,13.5, 5.5,17, 1.5, 1}, {5.5,17, 7.5,11.5, 1.5, 1}, {7.5,11.5, 3,8, 1.5, 1}, {3,8, 8.5,8, 1.5, 1}, {8.5,8, 10,3, 1.5, 1} },
    ["heart"]     = { {10,6, 7,3.5, 1.6, 1}, {7,3.5, 4,3.5, 1.6, 1}, {4,3.5, 3,7, 1.6, 1}, {3,7, 4,10.5, 1.6, 1}, {4,10.5, 10,17, 1.6, 1}, {10,17, 16,10.5, 1.6, 1}, {16,10.5, 17,7, 1.6, 1}, {17,7, 16,3.5, 1.6, 1}, {16,3.5, 13,3.5, 1.6, 1}, {13,3.5, 10,6, 1.6, 1} },
    ["lock"]      = { {6,9, 6,17, 1.6, 1}, {14,9, 14,17, 1.6, 1}, {6,17, 14,17, 1.6, 1}, {6,9, 14,9, 1.6, 1}, {7,9, 7,6, 1.6, 1}, {13,9, 13,6, 1.6, 1}, {7,6, 9,3, 1.6, 1}, {9,3, 11,3, 1.6, 1}, {11,3, 13,6, 1.6, 1} },
    ["unlock"]    = { {6,9, 6,17, 1.6, 1}, {14,9, 14,17, 1.6, 1}, {6,17, 14,17, 1.6, 1}, {6,9, 14,9, 1.6, 1}, {7,9, 7,6, 1.6, 1}, {7,6, 11,3, 1.6, 1}, {11,3, 13,4, 1.6, 1} },
    ["power"]     = { {10,3, 10,10, 1.8, 1}, {5,6, 3,10, 1.6, 1}, {3,10, 5,15, 1.6, 1}, {5,15, 10,17, 1.6, 1}, {10,17, 15,15, 1.6, 1}, {15,15, 17,10, 1.6, 1}, {17,10, 15,6, 1.6, 1}, {15,6, 10,4, 1.6, 1} },
    ["layers"]    = { {4,6, 10,3, 1.4, 1}, {10,3, 16,6, 1.4, 1}, {16,6, 10,9, 1.4, 1}, {10,9, 4,6, 1.4, 1}, {4,10, 10,7, 1.4, 1}, {10,7, 16,10, 1.4, 1}, {16,10, 10,13, 1.4, 1}, {10,13, 4,10, 1.4, 1}, {4,14, 10,11, 1.4, 1}, {10,11, 16,14, 1.4, 1}, {16,14, 10,17, 1.4, 1}, {10,17, 4,14, 1.4, 1} },
    ["globe"]     = { {10,3, 10,17, 1.4, 1}, {3,10, 17,10, 1.4, 1}, {5,6, 15,6, 1.3, 1}, {5,14, 15,14, 1.3, 1}, {10,3, 6,6, 1.3, 1}, {6,6, 4,10, 1.3, 1}, {4,10, 6,14, 1.3, 1}, {6,14, 10,17, 1.3, 1}, {10,3, 14,6, 1.3, 1}, {14,6, 16,10, 1.3, 1}, {16,10, 14,14, 1.3, 1}, {14,14, 10,17, 1.3, 1} },
    ["zap"]       = { {12,3, 6,10, 1.6, 1}, {6,10, 10,10, 1.6, 1}, {10,10, 8,17, 1.6, 1}, {8,17, 15,8, 1.6, 1}, {15,8, 11,8, 1.6, 1} },
    ["settings-sliders"] = { {3,5, 17,5, 1.5, 1}, {3,10, 17,10, 1.5, 1}, {3,15, 17,15, 1.5, 1}, {6,3, 6,7, 1.7, 1}, {13,8, 13,12, 1.7, 1}, {8,13, 8,17, 1.7, 1} },
    ["keyboard"] = {
        {2.8,5,17.2,5,1.5,1},{17.2,5,17.2,15.2,1.5,1},{17.2,15.2,2.8,15.2,1.5,1},{2.8,15.2,2.8,5,1.5,1},
        {5,8,6.2,8,1.55,1},{8,8,9.2,8,1.55,1},{11,8,12.2,8,1.55,1},{14,8,15.2,8,1.55,1},
        {5,11,6.2,11,1.55,1},{8,11,9.2,11,1.55,1},{11,11,15.2,11,1.55,1},
        {6.5,13.2,13.5,13.2,1.35,0.85}
    },
    ["sparkles"] = {
        {9.5,2.8,9.5,8.4,1.5,1},{6.7,5.6,12.3,5.6,1.5,1},
        {14.8,9.2,14.8,15.3,1.4,1},{11.75,12.25,17.85,12.25,1.4,1},
        {5.4,10.8,5.4,16.3,1.35,0.9},{2.65,13.55,8.15,13.55,1.35,0.9}
    },

}

-- case-insensitive lookup
local IconIndex = {}
for name, data in pairs(Icons) do
    IconIndex[string.lower(name)] = data
end

local function DrawIconByName(name, x, y, size, color, z, alpha, thickness)
    if not name then return false end
    local key = string.lower(tostring(name))
    if key == "settings" then key = "gear" end

    -- A few high-visibility icons benefit from real circular primitives rather
    -- than approximating every curve with polygonal line segments.
    if key == "gear" then
        local cx, cy = x + size / 2, y + size / 2
        local sc = size / 20
        local thick = math.max(1, math.min(1.8, (thickness or 1.45) * sc))
        Circle(cx, cy, size * 0.22, color, z, false, thick, 18, alpha or 1)
        Circle(cx, cy, size * 0.065, color, z + 0.1, true, 1, 14, alpha or 1)
        for i = 0, 7 do
            local ang = i * math.pi / 4
            local r1, r2 = size * 0.29, size * 0.40
            Bar(cx + math.cos(ang) * r1, cy + math.sin(ang) * r1,
                cx + math.cos(ang) * r2, cy + math.sin(ang) * r2,
                thick, color, z, alpha or 1)
        end
        return true
    end

    local data = IconIndex[key]
    if not data then return false end

    -- Icons are authored on a 20x20 grid. Snap endpoints to half pixels so
    -- thin Drawing lines stay crisp instead of landing between raster pixels.
    local scale = size / 20
    local defaultThick = thickness or 1.35
    alpha = alpha or 1

    local function snap(v)
        return math.floor(v * 2 + 0.5) / 2
    end

    for _, seg in ipairs(data) do
        local x1 = snap(x + seg[1] * scale)
        local y1 = snap(y + seg[2] * scale)
        local x2 = snap(x + seg[3] * scale)
        local y2 = snap(y + seg[4] * scale)
        local authored = seg[5] or defaultThick
        local thick = math.max(1, math.min(1.75, authored * scale))
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

    -- Some executors briefly expose nil mouse coordinates during startup or
    -- while the game window is changing focus. Keep the renderer numeric.
    local mx = tonumber(Mouse.X) or Input.PrevX or 0
    local my = tonumber(Mouse.Y) or Input.PrevY or 0
    Input.X, Input.Y = mx, my
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

    -- Wheel APIs vary between executors. Prefer event/delta-style values;
    -- fall back to a cumulative counter only when the value clearly behaves
    -- like one. Keyboard PageUp/PageDown is handled by HandleWheel as well.
    local wheel = 0
    local gotWheel = false

    local function acceptWheel(value)
        value = tonumber(value)
        if value ~= nil and value ~= 0 then
            wheel = value
            gotWheel = true
        end
    end

    pcall(function()
        if mousewheel then acceptWheel(mousewheel()) end
    end)
    if not gotWheel then
        pcall(function()
            if getwheel then acceptWheel(getwheel()) end
        end)
    end
    if not gotWheel then
        pcall(function()
            if Mouse and Mouse.WheelDelta ~= nil then acceptWheel(Mouse.WheelDelta) end
        end)
    end

    -- Most Matcha-style wheel functions expose a signed per-frame delta.
    -- Clamp large values so one wheel notch cannot fling through a page.
    if wheel > 0 then
        Input.Wheel = math.min(wheel, 3)
    elseif wheel < 0 then
        Input.Wheel = math.max(wheel, -3)
    else
        Input.Wheel = 0
    end

end

local function MouseIn(x, y, w, h)
    local mx = tonumber(Input.X) or 0
    local my = tonumber(Input.Y) or 0
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    w = tonumber(w) or 0
    h = tonumber(h) or 0
    return (mx >= x) and (mx <= x + w)
       and (my >= y) and (my <= y + h)
end

local function MouseInCircle(cx, cy, radius)
    local mx = tonumber(Input.X) or 0
    local my = tonumber(Input.Y) or 0
    local dx = mx - cx
    local dy = my - cy
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
    Visible = 0,          -- 0..1 animation
    Open = false,

    -- drag / resize
    Drag        = nil,    -- { GrabX, GrabY }
    Resize      = nil,    -- { Edge, GrabX, GrabY, StartW, StartH, StartX, StartY }
    DragSpeed   = 20,

    -- tabs
    Tabs        = {},
    ActiveIndex = 1,
    RailOpen    = 0,      -- 0 = narrow, 1 = full
    RailPinned  = false,

    -- dynamic title island
    Island = {
        Open = false,
        Expand = 0,
        IconReveal = 0,
        Actions = {},
        MaxActions = 6,
    },

    -- scrolling
    Scroll      = {},     -- per-tab scroll offset

    -- popups
    Popup       = nil,    -- currently open dropdown / picker / etc.

    -- lifecycle
    Alive       = true,
    Frame       = 0,
    InputSent   = true,
    Delta       = 1 / 60,
    LastTick    = os.clock(),

    -- startup animation
    Startup = {
        Active = false,
        Phase = "idle",
        Time = 0,
        Duration = 7.0,
        Progress = 0,
        RevealProgress = 0,
        RevealDuration = 0.85,
        ShrinkDuration = 0.42,
        PopDuration = 0.72,
        Enabled = true,
        TextFade = true,
        Image = nil,
        ImageSource = nil,
        Title = nil,
        LogoSize = 50,
        BackgroundImage = nil,
        BackgroundImageSource = nil,
        BackgroundOpacity = 0.22,
        TypewriterCount = 0,
        TypewriterAccumulator = 0,
        TypewriterLastTime = 0,
        StartX = 0, StartY = 0, StartW = 0, StartH = 0,
        TargetX = 0, TargetY = 0, TargetW = 0, TargetH = 0,
    },

    -- global animation / settings
    NoAnim      = false,
    Settings = {
        KeybindOverlay = true,
        PerformanceOverlay = true,
        BackgroundEffects = true,
        BorderComet = true,
        WindowOpacity = 82,
        CompactOverlay = false,
        ToggleStyle = "Switch",
        ConfigName = "default",
    },

    -- overlay reveal sequencing
    OverlayRevealTime = 0,
    OverlayNextRevealAt = 1.0,

    -- window identity / appearance
    WindowTitle    = "Window",
    WindowSubtitle = "",
    Logo           = nil,
    LogoSource     = nil,
    LogoSize       = 30,
    BackgroundImage = nil,
    BackgroundImageSource = nil,
    OpenDropdownWheelRect = nil,
    ActiveDropdown = nil,
    Background     = "none",
    BackgroundOptions = {},

    -- hotkeys
    MenuKey     = "p",

    -- theme
    Theme       = Themes[1],
    ThemeIndex  = 1,
    ThemeTween  = {},     -- color tween state

    -- notifications queue
    Notifications = {},
    NotificationPosition = "top_left",
}


function Library:_SyncGameInput(force)
    if type(setrobloxinput) ~= "function" then return end

    local toGame = Focus.Field == nil
    if not force and State.InputSent == toGame then return end

    State.InputSent = toGame
    pcall(setrobloxinput, toGame)
end

local function ApplyThemeOptions(themeOption)
    if type(themeOption) == "string" then
        for i, th in ipairs(Themes) do
            if string.lower(th.Name) == string.lower(themeOption) then
                State.Theme = th
                State.ThemeIndex = i
                return
            end
        end
        return
    end
    if type(themeOption) ~= "table" then return end
    local source = State.Theme or Themes[1]
    local merged = {}
    for k, v in pairs(source) do merged[k] = v end
    local aliases = {
        accent = "Accent", accenta = "AccentA", accentb = "AccentB",
        based = "Base", base = "Base", panel = "Panel", panelhi = "PanelHi",
        stroke = "Stroke", divider = "Divider", text = "Text", textdim = "TextDim",
        textmuted = "TextMuted", accentdim = "AccentDim", track = "Track",
        trackfill = "TrackFill", danger = "Danger", warning = "Warning", success = "Success",
    }
    for k, v in pairs(themeOption) do
        local key = aliases[string.lower(tostring(k))]
        if key and typeof(v) == "Color3" then merged[key] = v end
    end
    State.Theme = merged
    State.ThemeIndex = 0
end

-- Best-effort Roblox game-input sink while the UI menu is open.
-- Everything is protected so executors that restrict game services continue
-- to run normally rather than breaking the UI.
-- ============================================================================
--  PART 2 COMPLETE
--  Next: PART 3 -- layout engine, scroll, resize handle, window frame,
--                   tab rail with icon-font icons
-- ============================================================================

-- ============================================================================
--  GEOMETRY HELPERS  --  small math, no state
-- ============================================================================

local function Clamp(v, lo, hi)
    v = tonumber(v) or 0
    lo = tonumber(lo) or 0
    hi = tonumber(hi) or 0
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function PointInRect(px, py, x, y, w, h)
    px, py = tonumber(px) or 0, tonumber(py) or 0
    x, y = tonumber(x) or 0, tonumber(y) or 0
    w, h = tonumber(w) or 0, tonumber(h) or 0
    return (px >= x) and (px <= x + w)
       and (py >= y) and (py <= y + h)
end

local function Distance2(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

-- ============================================================================
--  WINDOW GEOMETRY  --  derived every frame from State.X/Y/W/H
-- ============================================================================

local Geometry = { FooterH = 20 }

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
    -- Reserve a compact footer strip at the bottom of the window.
    Geometry.FooterH = 20
    Geometry.RailH = math.max(1, State.H - Geometry.TopH - Geometry.FooterH)

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
        IsSettings = opts.IsSettings or false,

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

        -- pending redraw pass
        Dirty    = true,
    }, Tab)
    State.Tabs[#State.Tabs + 1] = self
    -- also mirror on the parent table so Library.Tabs stays in sync
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

function Section.new(tab, title, description, opts)
    opts = opts or {}
    local self = setmetatable({
        Parent      = tab,
        Title       = title or "Section",
        Description = description or "",
        Collapsed   = opts.Collapsed and true or false,
        Rows        = {},
        HeaderH     = Layout.SectionH,
        _layoutX    = 0,
        _layoutY    = 0,
        _layoutW    = 0,
        _layoutH    = 0,
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

local ContentScrollbarDrag = {
    Active = false,
    OffsetY = 0,
    Tab = nil,
}

local function GetContentScrollbarGeometry(tab)
    if not tab or (tab.MaxScroll or 0) <= 0 then return nil end
    local trackW = math.max(6, Layout.ScrollbarW)
    local trackX = Geometry.ContentX + Geometry.ContentW - trackW - 3
    local trackY = Geometry.ContentY + 4
    local trackH = math.max(20, Geometry.ContentH - 8)
    local viewFrac = Geometry.InnerH / math.max(1, Geometry.InnerH + tab.MaxScroll)
    local thumbH = math.max(24, trackH * viewFrac)
    local travel = math.max(1, trackH - thumbH)
    local scrollFrac = (tab.ScrollTo or 0) / math.max(1, tab.MaxScroll)
    local thumbY = trackY + travel * scrollFrac
    return trackX, trackY, trackW, trackH, thumbY, thumbH, travel
end

local function UpdateContentScrollbarInput(tab)
    if not tab then
        ContentScrollbarDrag.Active = false
        ContentScrollbarDrag.Tab = nil
        return
    end

    local trackX, trackY, trackW, trackH, thumbY, thumbH, travel =
        GetContentScrollbarGeometry(tab)
    if not trackX then
        ContentScrollbarDrag.Active = false
        ContentScrollbarDrag.Tab = nil
        return
    end

    if ContentScrollbarDrag.Active and ContentScrollbarDrag.Tab == tab then
        if Input.Down then
            local newThumbY = Clamp(Input.Y - ContentScrollbarDrag.OffsetY,
                                    trackY, trackY + travel)
            local frac = (newThumbY - trackY) / math.max(1, travel)
            tab.ScrollTo = Clamp(frac * tab.MaxScroll, 0, tab.MaxScroll)
            tab.Scroll = tab.ScrollTo
            Input.Click = false
        else
            ContentScrollbarDrag.Active = false
            ContentScrollbarDrag.Tab = nil
        end
        return
    end

    if Input.Click and MouseIn(trackX - 3, thumbY - 2, trackW + 6, thumbH + 4) then
        ContentScrollbarDrag.Active = true
        ContentScrollbarDrag.Tab = tab
        ContentScrollbarDrag.OffsetY = Input.Y - thumbY
        Input.Click = false
        return
    end

    -- Clicking the empty track jumps the thumb there and begins dragging.
    if Input.Click and MouseIn(trackX - 3, trackY, trackW + 6, trackH) then
        local centered = Clamp(Input.Y - thumbH / 2, trackY, trackY + travel)
        local frac = (centered - trackY) / math.max(1, travel)
        tab.ScrollTo = Clamp(frac * tab.MaxScroll, 0, tab.MaxScroll)
        tab.Scroll = tab.ScrollTo
        ContentScrollbarDrag.Active = true
        ContentScrollbarDrag.Tab = tab
        ContentScrollbarDrag.OffsetY = thumbH / 2
        Input.Click = false
    end
end

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

    local popup = State.OpenDropdownWheelRect
    if popup and MouseIn(popup.X, popup.Y, popup.W, popup.H) then
        return
    end

    local delta = Input.Wheel or 0
    local pgUp = Keys.PageUp and Keys.PageUp.Click
    local pgDn = Keys.PageDown and Keys.PageDown.Click

    if delta ~= 0 then
        tab.ScrollTo = tab.ScrollTo - delta * Layout.ScrollSpeed
        Input.Wheel = 0
    elseif pgUp then
        tab.ScrollTo = tab.ScrollTo - math.max(80, Geometry.ContentH * 0.65)
    elseif pgDn then
        tab.ScrollTo = tab.ScrollTo + math.max(80, Geometry.ContentH * 0.65)
    else
        return
    end

    tab.ScrollTo = Clamp(tab.ScrollTo, 0, tab.MaxScroll or 0)
end

local function DrawScrollbar(tab)
    local trackX, trackY, trackW, trackH, thumbY, thumbH =
        GetContentScrollbarGeometry(tab)
    if not trackX then return end

    Rect(trackX, trackY, trackW, trackH,
         State.Theme.Track, 20, trackW / 2, 0.38)

    local active = ContentScrollbarDrag.Active and ContentScrollbarDrag.Tab == tab
    Rect(trackX, thumbY, trackW, thumbH,
         State.Theme.Accent, 21, trackW / 2, active and 1 or 0.82)
end

-- ============================================================================
--  DYNAMIC TAB HEIGHT  --  keep the window tall enough for every visible tab
-- ============================================================================

local function GetVisibleTabCount()
    local count = 0
    for _, tab in ipairs(State.Tabs) do
        if not tab.Hidden then
            count = count + 1
        end
    end
    return count
end

local function GetRequiredWindowHeight()
    local count = GetVisibleTabCount()

    -- Keep the normal default window size for small tab counts.
    -- Only grow the window when the complete collapsed sidebar stack would
    -- otherwise extend beyond the detached sidebar section.
    local defaultHeight = Layout.WindowH

    if count <= 0 then
        return math.max(Layout.WindowMinH, defaultHeight)
    end

    -- DrawTabRail() starts collapsed, so use the largest tab height here.
    -- Its actual row step is:
    --     tabRowH + TabGap
    -- where tabRowH = TabRowH * collapsedScale.
    local sectionTopPad = 5
    local tabTopPad = 11
    local tabBottomPad = 10
    local sectionBottomPad = 5

    local collapsedScale = 1.18
    local tabH = Layout.TabRowH * collapsedScale
    local gap = Layout.TabGap

    local tabsHeight =
        (count * tabH)
        + (math.max(0, count - 1) * gap)

    -- RailY starts directly below the topbar. The detached section is
    -- inset by 5px at both vertical edges.
    local railHeight =
        sectionTopPad
        + tabTopPad
        + tabsHeight
        + tabBottomPad
        + sectionBottomPad

    local required =
        Layout.TopbarH
        + Geometry.FooterH
        + railHeight

    -- Never make a normal 3-tab window smaller than the standard 500px
    -- window. Larger tab counts grow downward from that baseline.
    return math.max(Layout.WindowMinH, defaultHeight, math.ceil(required))
end

local function EnsureWindowFitsTabs()
    local required = GetRequiredWindowHeight()
    if State.H < required then
        local oldH = State.H
        State.H = required

        -- Keep the window visually centered when automatic growth happens.
        State.Y = State.Y - math.floor((required - oldH) / 2)
    end
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
    local minWindowH = GetRequiredWindowHeight()
    State.H = Clamp(r.StartH + (Input.Y - r.GrabY),
                    minWindowH, 1600)

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

    -- Dragging is intentionally immediate. Every drawable is derived from
    -- State.X/Y in the same frame, preventing visible separation between
    -- the window shell and its contents.
    State.X, State.Y = d.WantX, d.WantY

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
--  WINDOW FRAME  --  background, top bar, depth effect, resize indicator
-- ============================================================================

local function GlassBorderPoint(distance, x, y, w, h, radius)
    local straightW = math.max(0, w - radius * 2)
    local straightH = math.max(0, h - radius * 2)
    local arc = math.pi * radius / 2

    local top = straightW
    local topRight = top + arc
    local right = topRight + straightH
    local bottomRight = right + arc
    local bottom = bottomRight + straightW
    local bottomLeft = bottom + arc
    local left = bottomLeft + straightH
    local total = left + arc

    local d = distance % total

    if d <= top then
        return x + radius + d, y
    elseif d <= topRight then
        local a = -math.pi / 2 + (d - top) / radius
        return x + w - radius + math.cos(a) * radius,
               y + radius + math.sin(a) * radius
    elseif d <= right then
        return x + w, y + radius + (d - topRight)
    elseif d <= bottomRight then
        local a = (d - right) / radius
        return x + w - radius + math.cos(a) * radius,
               y + h - radius + math.sin(a) * radius
    elseif d <= bottom then
        return x + w - radius - (d - bottomRight), y + h
    elseif d <= bottomLeft then
        local a = math.pi / 2 + (d - bottom) / radius
        return x + radius + math.cos(a) * radius,
               y + h - radius + math.sin(a) * radius
    elseif d <= left then
        return x, y + h - radius - (d - bottomLeft)
    else
        local a = math.pi + (d - left) / radius
        return x + radius + math.cos(a) * radius,
               y + radius + math.sin(a) * radius
    end
end

local function DrawGlassBorder(th)
    local x, y = State.X, State.Y
    local w, h = State.W, State.H
    local radius = math.min(Layout.Corner, math.max(2, math.min(w, h) / 2 - 1))

    -- Bright white outline shared by the loading frame and the main window.
    Stroke(x, y, w, h, th.Accent, 20, radius, 0.88)

    if State.NoAnim then
        return
    end

    -- Two mirrored comets travel in opposite directions around the same
    -- perimeter. Their brighter heads, soft halos and longer trails make the
    -- motion readable without turning the border into a heavy effect.
    local straightW = math.max(0, w - radius * 2)
    local straightH = math.max(0, h - radius * 2)
    local perimeter = 2 * straightW + 2 * straightH + 2 * math.pi * radius
    local distance = (os.clock() * 96) % perimeter

    if State.Settings and State.Settings.BorderComet == false then
        return
    end

    local function DrawComet(headDistance, direction, accent, zBase)
        local trailCount = 12
        local trailLength = 48

        for i = trailCount, 1, -1 do
            local t = i / trailCount
            local trailDistance = headDistance - direction * trailLength * t
            local tx, ty = GlassBorderPoint(trailDistance, x, y, w, h, radius)
            local strength = 1 - t
            local trailAlpha = 0.07 + strength * 0.54
            local trailSize = 1.15 + strength * 1.75
            Circle(tx, ty, trailSize, accent,
                   zBase + i, true, 1, 14, trailAlpha)
        end

        local hx, hy = GlassBorderPoint(headDistance, x, y, w, h, radius)
        Circle(hx, hy, 6.0, accent, zBase + 20, true, 1, 20, 0.13)
        Circle(hx, hy, 3.5, accent, zBase + 21, true, 1, 18, 1)
        Circle(hx, hy, 1.6, Color3.new(1, 1, 1),
               zBase + 22, true, 1, 14, 0.88)
    end

    -- The second head mirrors the first by traversing the perimeter in the
    -- opposite direction from the same phase.
    DrawComet(distance, 1, th.AccentA, 21)
    DrawComet((-distance) % perimeter, -1, th.AccentB or th.AccentA, 55)
end

local function DrawBackgroundEffect()
    if State.Settings and State.Settings.BackgroundEffects == false then return end
    local effect = State.Background
    local kind = type(effect) == "table" and effect.Type or effect
    if kind == "none" then return end

    local th = State.Theme
    local x, y, w, h = State.X, State.Y, State.W, State.H
    local top = y + Layout.TopbarH
    local usableH = math.max(1, h - Layout.TopbarH)
    local now = os.clock()
    local intensity = type(effect) == "table" and tonumber(effect.Intensity) or nil
    intensity = Clamp(intensity or 1, 0, 1)

    -- Stable pseudo-random 0..1 value. This keeps procedural particles
    -- deterministic without allocating particle tables every frame.
    local function Hash(n)
        local v = math.sin(n * 12.9898 + 78.233) * 43758.5453
        return v - math.floor(v)
    end

    if kind == "dots" then
        local spacing = type(effect) == "table" and tonumber(effect.Spacing) or 25
        spacing = math.max(12, spacing)
        local driftX = (now * 3.5) % spacing
        local driftY = (now * 1.8) % spacing

        for gx = x - spacing + driftX, x + w + spacing, spacing do
            for gy = top - spacing + driftY, y + h + spacing, spacing do
                if gx >= x + 5 and gx <= x + w - 5 and gy >= top + 5 and gy <= y + h - 5 then
                    local pulse = 0.5 + 0.5 * math.sin(now * 1.25 + gx * 0.025 + gy * 0.018)
                    Circle(gx, gy, 0.9 + pulse * 0.45,
                           th.AccentA, 11, true, 1, 8,
                           (0.20 + pulse * 0.22) * intensity)
                end
            end
        end

    elseif kind == "scanlines" then
        local spacing = type(effect) == "table" and tonumber(effect.Spacing) or 8
        spacing = math.max(5, spacing)
        local offset = (now * 14) % spacing

        for gy = top - spacing + offset, y + h, spacing do
            Line(x + 5, gy, x + w - 5, gy,
                 th.Text, 11, 1, 0.10 * intensity)
        end

        -- One soft travelling sweep keeps scanlines from looking static.
        local sweepY = top + ((now * 34) % usableH)
        for i = -3, 3 do
            local strength = 1 - math.abs(i) / 4
            Line(x + 5, sweepY + i * 2, x + w - 5, sweepY + i * 2,
                 th.AccentA, 12, 1,
                 0.055 * strength * intensity)
        end

    elseif kind == "particles" then
        local count = math.floor(type(effect) == "table" and tonumber(effect.Count) or 30)
        count = Clamp(count, 8, 64)

        for i = 1, count do
            local seedX = Hash(i * 2.17)
            local seedY = Hash(i * 7.31)
            local speed = 5 + Hash(i * 4.91) * 13
            local sway = math.sin(now * (0.35 + Hash(i * 3.2) * 0.55) + i) * (4 + Hash(i) * 10)
            local px = x + 10 + seedX * math.max(1, w - 20) + sway
            local py = top + ((seedY * usableH + now * speed) % usableH)
            local pulse = 0.5 + 0.5 * math.sin(now * 1.8 + i * 0.9)
            local radius = 0.9 + Hash(i * 9.1) * 1.4 + pulse * 0.35
            local col = (i % 3 == 0) and th.AccentB or th.AccentA

            if px >= x + 5 and px <= x + w - 5 then
                Circle(px, py, radius, col, 11, true, 1, 10,
                       (0.24 + pulse * 0.34) * intensity)
                if i % 5 == 0 then
                    Circle(px, py, radius + 3.5, col, 10, true, 1, 12,
                           0.045 * intensity)
                end
            end
        end

    elseif kind == "aurora" then
        local bands = type(effect) == "table" and math.floor(tonumber(effect.Bands) or 6) or 6
        bands = Clamp(bands, 3, 9)

        -- Layer broad translucent orbs along moving wave paths. Multiple
        -- overlapping points make each band feel continuous instead of like
        -- isolated circles.
        for band = 1, bands do
            local col = (band % 2 == 0) and th.AccentB or th.AccentA
            local bandY = top + usableH * (0.10 + band / (bands + 1) * 0.78)
            for point = 0, 5 do
                local phase = now * (0.22 + band * 0.018) + band * 1.37 + point * 0.72
                local px = x + w * (point / 5) + math.sin(phase) * 32
                local py = bandY + math.sin(phase * 1.23) * (12 + band * 2)
                local radius = 38 + band * 5
                Circle(px, py, radius, col, 10 + band, true, 1, 28,
                       (0.025 + band * 0.004) * intensity)
            end
        end

    elseif kind == "snow" then
        local count = math.floor(type(effect) == "table" and tonumber(effect.Count) or 42)
        count = Clamp(count, 12, 80)

        for i = 1, count do
            local seedX = Hash(i * 2.71)
            local seedY = Hash(i * 8.13)
            local depth = 0.45 + Hash(i * 5.41) * 0.85
            local speed = 11 + depth * 18
            local sway = math.sin(now * (0.65 + depth * 0.35) + i * 1.7) * (4 + depth * 7)
            local px = x + 7 + seedX * math.max(1, w - 14) + sway
            local py = top + ((seedY * usableH + now * speed) % usableH)
            local radius = 0.8 + depth * 1.25
            local alpha = (0.28 + depth * 0.42) * intensity

            if px >= x + 5 and px <= x + w - 5 then
                Circle(px, py, radius + 2.8, th.Text, 10, true, 1, 10, 0.035 * alpha)
                Circle(px, py, radius, th.Text, 11, true, 1, 10, alpha)
            end
        end

    elseif kind == "rainfall" then
        local count = math.floor(type(effect) == "table" and tonumber(effect.Count) or 38)
        count = Clamp(count, 12, 72)

        for i = 1, count do
            local seedX = Hash(i * 3.77)
            local seedY = Hash(i * 9.21)
            local depth = 0.55 + Hash(i * 4.43) * 0.75
            local speed = 95 + depth * 115
            local px = x + 8 + seedX * math.max(1, w - 16)
            local py = top + ((seedY * usableH + now * speed) % (usableH + 24)) - 12
            local length = 7 + depth * 8
            local slant = 2.5 + depth * 2.5
            local col = (i % 5 == 0) and th.AccentA or th.TextDim

            if py >= top - 12 and py <= y + h + 4 then
                Line(px, py, px - slant, py + length,
                     col, 11, 1, (0.18 + depth * 0.30) * intensity)
            end
        end
    end
end

local function DrawFrame(hideBackgroundImage)
    local th = State.Theme

    -- One continuous translucent glass pane. It uses its own alpha path so
    -- the rest of the UI keeps the exact same transparency behaviour.
    GlassSurface(State.X, State.Y, State.W, State.H,
                 rgb(18, 21, 30), 10, Layout.Corner)

    -- Optional persistent image wallpaper, above the base glass and behind
    -- effects, separators, sidebar/content surfaces and controls.
    if State.BackgroundImage and not hideBackgroundImage then
        DrawPicture(State.BackgroundImage,
                    State.X, State.Y, State.W, State.H,
                    Layer(11),
                    GlassSurfaceAlpha * FrameAlpha,
                    Layout.Corner)
    end

    -- A restrained top reflection. This follows the same outer silhouette and
    -- does not create a second panel or a horizontal split.
    Rect(State.X + Layout.Corner, State.Y + 1,
         math.max(1, State.W - Layout.Corner * 2), 1,
         Color3.new(1, 1, 1), 12, 0, 0.12)

    DrawBackgroundEffect()

    -- Integrated premium header trace; no heavy divider.
    local headerY = State.Y + Layout.TopbarH - 1
    GradientRect(State.X + 18, headerY,
                 math.max(40, State.W - 36), 1,
                 th.AccentA, th.AccentB, 14, 0.22)

    -- Keep the vertical separator exactly one sidebar-section padding unit
    -- to the right of the detached section, matching the 10px left inset.
    local sidebarSectionPad = 10
    local sidebarSectionRight = Geometry.RailX + sidebarSectionPad
        + math.max(40, Geometry.RailW - sidebarSectionPad - sidebarSectionPad)
    local separatorX = sidebarSectionRight + sidebarSectionPad

    Line(separatorX, Geometry.RailY + 1,
         separatorX, State.Y + State.H - 2,
         th.Accent, 14, 1, 0.52)

    -- Single animated glass edge.
    DrawGlassBorder(th)
end

-- ============================================================================
--  STARTUP ANIMATION  --  the existing window becomes the startup frame
-- ============================================================================

local function StartupEase(t)
    if t < 0.5 then
        return 4 * t * t * t
    end
    local f = -2 * t + 2
    return 1 - (f * f * f) / 2
end

local function DrawStartupFrame()
    local th = State.Theme
    local x, y, w, h = State.X, State.Y, State.W, State.H
    local st = State.Startup

    GlassSurface(x, y, w, h, rgb(14, 16, 23), 10, Layout.Corner)

    -- Optional splash-only background image. It deliberately fills the complete
    -- card so the splash can have its own artwork independently of the window.
    if st.BackgroundImage and st.BackgroundOpacity > 0 then
        DrawPicture(st.BackgroundImage, x, y, w, h, Layer(11),
                    math.max(0, math.min(1, st.BackgroundOpacity)), Layout.Corner)
        -- A quiet dark wash keeps white typography readable over bright artwork.
        Rect(x, y, w, h, rgb(8, 10, 15), 12, Layout.Corner, 0.24)
    else
        HidePicture(st.BackgroundImage)
    end

    DrawGlassBorder(th)

    -- Premium identity sequence:
    --   1) a large framed logo begins centered
    --   2) it glides left and fully settles
    --   3) after a short pause, the title emerges from the logo and types
    --   4) the typing title softly settles from muted white into pure white
    local logoSize = math.max(28, math.min(64, tonumber(st.LogoSize) or 50))
    local logoBorder = 2
    local centerLogoX = x + (w - logoSize) / 2
    local finalLogoX = x + 16
    local logoY = y + (h - logoSize) / 2

    local duration = math.max(0.5, st.Duration or 5)
    local logoMoveStart = duration * 0.055
    local logoMoveEnd   = duration * 0.235

    -- The title is choreographed from the logo movement rather than from an
    -- unrelated percentage of the splash duration. Let the logo fully settle,
    -- breathe for a moment, then begin typing.
    local titleStart    = logoMoveEnd + math.max(0.07, math.min(0.14, duration * 0.018))
    local titleEnd      = math.max(titleStart + 0.55, duration * 0.74)

    local function Smooth01(v)
        v = math.max(0, math.min(1, v))
        return v * v * (3 - 2 * v)
    end

    local moveT = Smooth01((st.Time - logoMoveStart) /
                           math.max(0.001, logoMoveEnd - logoMoveStart))
    local logoX = centerLogoX + (finalLogoX - centerLogoX) * moveT

    -- Visible neutral frame around the image; intentionally not accent-coloured.
    Rect(logoX - logoBorder, logoY - logoBorder,
         logoSize + logoBorder * 2, logoSize + logoBorder * 2,
         rgb(95, 99, 111), 30, 9, 0.88)
    Rect(logoX, logoY, logoSize, logoSize, rgb(17, 19, 26), 31, 7, 1)

    local logoReady = DrawPicture(st.Image or State.Logo, logoX, logoY,
                                  logoSize, logoSize, Layer(34), 1, 7)

    if not logoReady then
        local pulse = 0.68 + math.sin(os.clock() * 2.0) * 0.10
        Rect(logoX + logoSize * 0.18, logoY + logoSize * 0.48,
             logoSize * 0.64, 2, th.TextDim, 32, 1, pulse)
    end

    local title = tostring(st.Title or State.WindowTitle or "DRAWING UI")
    local titleSize = 16
    local finalTitleX = finalLogoX + logoSize + 15
    local titleY = math.floor(y + (h - titleSize) / 2 + 0.5)
    local typedTitle = ""

    if st.Time >= titleStart then
        local typeDuration = math.max(0.001, titleEnd - titleStart)
        local charInterval = typeDuration / math.max(1, #title)

        -- Accumulate elapsed render time, but reveal at most one character on
        -- each rendered frame. This prevents frame-time spikes from jumping
        -- over intermediate characters on longer splash titles.
        local now = st.Time
        local previous = st.TypewriterLastTime or titleStart
        if previous < titleStart then previous = titleStart end
        local elapsed = math.max(0, now - previous)
        st.TypewriterLastTime = now
        st.TypewriterAccumulator = (st.TypewriterAccumulator or 0) + elapsed

        if (st.TypewriterCount or 0) == 0 then
            st.TypewriterCount = 1
            st.TypewriterAccumulator = 0
        elseif st.TypewriterCount < #title and st.TypewriterAccumulator >= charInterval then
            st.TypewriterCount = st.TypewriterCount + 1
            st.TypewriterAccumulator = st.TypewriterAccumulator - charInterval

            -- Do not retain a huge backlog after a hitch. The goal is a
            -- consistent visible typewriter, not catching up by skipping.
            if st.TypewriterAccumulator > charInterval * 2 then
                st.TypewriterAccumulator = charInterval
            end
        end

        local charCount = math.min(#title, st.TypewriterCount or 0)
        typedTitle = string.sub(title, 1, charCount)

        if typedTitle ~= "" then
            -- Render the typewriter as one continuous Text object. Splitting the
            -- newest character into a second object causes visible kerning gaps
            -- in Matcha because TextWidth does not perfectly match glyph layout.
            --
            -- TextFade now softly settles the whole currently-visible word from
            -- muted white toward pure white during the early typing sequence.
            -- Character placement therefore never depends on measured widths.
            local level = 1
            if st.TextFade then
                local typeDuration = math.max(0.001, titleEnd - titleStart)
                local fadeT = math.max(0, math.min(1, (st.Time - titleStart) /
                                                   math.max(0.12, typeDuration * 0.30)))
                fadeT = fadeT * fadeT * (3 - 2 * fadeT)
                level = 0.72 + 0.28 * fadeT
            end

            Text(typedTitle, finalTitleX, titleY, Color3.new(level, level, level),
                 titleSize, Fonts.SystemBold, 35, 1,
                 math.max(40, w - (finalTitleX - x) - 18))
        end
    end
end

local function TickStartup(dt)
    local st = State.Startup
    if not st.Active then return end
    st.Time = st.Time + dt

    if st.Phase == "loading" then
        local t = math.min(st.Time / st.Duration, 1)
        st.Progress = 1 - (1 - t) * (1 - t)
        if t >= 1 then
            st.Phase = "shrink"
            st.Time = 0
            st.Progress = 1
        end
        return
    end

    if st.Phase == "shrink" then
        local t = math.min(st.Time / st.ShrinkDuration, 1)
        local eased = t * t * (3 - 2 * t)
        local minW, minH = 34, 5
        State.W = st.StartW + (minW - st.StartW) * eased
        State.H = st.StartH + (minH - st.StartH) * eased
        State.X = st.StartX + (st.StartW - State.W) / 2
        State.Y = st.StartY + (st.StartH - State.H) / 2
        if t >= 1 then
            State.W, State.H = minW, minH
            State.X = st.StartX + (st.StartW - minW) / 2
            State.Y = st.StartY + (st.StartH - minH) / 2
            st.Phase = "pop"
            st.Time = 0
        end
        return
    end

    if st.Phase == "pop" then
        local t = math.min(st.Time / st.PopDuration, 1)
        local c1, c3 = 1.32, 2.32
        local eased = 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
        local minW, minH = 34, 5
        State.W = minW + (st.TargetW - minW) * eased
        State.H = minH + (st.TargetH - minH) * eased
        State.X = st.TargetX + (st.TargetW - State.W) / 2
        State.Y = st.TargetY + (st.TargetH - State.H) / 2
        if t >= 1 then
            State.X, State.Y = st.TargetX, st.TargetY
            State.W, State.H = st.TargetW, st.TargetH
            st.Phase = "reveal"
            st.Time = 0
            st.RevealProgress = 0
        end
        return
    end

    if st.Phase == "reveal" then
        local t = math.min(st.Time / st.RevealDuration, 1)
        st.RevealProgress = t * t * (3 - 2 * t)
        if t >= 1 then
            st.RevealProgress = 1
            st.Active = false
            st.Phase = "done"
        end
    end
end

local function StartStartup(opts)
    opts = opts or {}
    local st = State.Startup
    local vp = Camera.ViewportSize

    st.Enabled = opts.Enabled ~= false
    st.Duration = math.max(0.5, tonumber(opts.Duration) or 5.0)
    st.TextFade = opts.TextFade ~= false
    st.Title = opts.Title ~= nil and tostring(opts.Title) or State.WindowTitle
    st.LogoSize = math.max(28, math.min(64, tonumber(opts.LogoSize) or 50))
    st.BackgroundOpacity = tonumber(opts.BackgroundOpacity) or 0.22
    if st.BackgroundOpacity > 1 then st.BackgroundOpacity = st.BackgroundOpacity / 100 end
    st.BackgroundOpacity = math.max(0, math.min(1, st.BackgroundOpacity))

    if opts.Image ~= nil and opts.Image ~= st.ImageSource then
        HidePicture(st.Image)
        st.ImageSource = opts.Image
        st.Image = LoadPicture(opts.Image, "splash_logo")
    elseif opts.Image == nil then
        HidePicture(st.Image)
        st.Image = nil
        st.ImageSource = nil
    end

    if opts.BackgroundImage ~= nil and opts.BackgroundImage ~= st.BackgroundImageSource then
        HidePicture(st.BackgroundImage)
        st.BackgroundImageSource = opts.BackgroundImage
        st.BackgroundImage = LoadPicture(opts.BackgroundImage, "splash_background")
    elseif opts.BackgroundImage == nil then
        HidePicture(st.BackgroundImage)
        st.BackgroundImage = nil
        st.BackgroundImageSource = nil
    end

    st.TargetW, st.TargetH = State.W, State.H
    st.TargetX, st.TargetY = State.X, State.Y

    if not st.Enabled then
        st.Active = false
        st.Phase = "done"
        st.Progress = 1
        st.RevealProgress = 1
        State.Visible = 1
        State.Open = true
        State.RailOpen = 1
        return
    end

    st.Time = 0
    st.Progress = 0
    st.RevealProgress = 0
    st.TypewriterCount = 0
    st.TypewriterAccumulator = 0
    st.TypewriterLastTime = 0
    st.Phase = "loading"
    st.Active = true

    local splashW, splashH = 330, 86
    local size = opts.Size
    if type(size) == "userdata" or type(size) == "table" then
        splashW = tonumber(size.X or size.x or size[1]) or splashW
        splashH = tonumber(size.Y or size.y or size[2]) or splashH
    end
    splashW = math.max(220, math.min(560, splashW))
    splashH = math.max(st.LogoSize + 18, math.min(160, splashH))

    st.StartW = splashW
    st.StartH = splashH
    st.StartX = math.floor((vp.X - st.StartW) / 2)
    st.StartY = math.floor((vp.Y - st.StartH) / 2)

    State.W, State.H = st.StartW, st.StartH
    State.X, State.Y = st.StartX, st.StartY
    State.Visible = 1
    State.Open = true
    State.RailOpen = 0
end

-- ============================================================================
--  WINDOW TITLE  --  title text + close button + menu button
-- ============================================================================

local TitleButtons = {
    Close  = { Size = 22, X = 0, Y = 0 },
    Menu   = { Size = 22, X = 0, Y = 0 },
}

local function DrawTitleBar(title, subtitle)
    local th = State.Theme
    local island = State.Island

    -- Island micro-icons use a fixed draw-call layout every frame. Matcha does
    -- not reliably tolerate pooled Drawing objects being recoloured/reassigned
    -- when the active state changes, so OFF and ON layers are both always drawn.
    -- Toggling only cross-fades transparency; object order and colours stay fixed.
    local function drawIslandIcon(name, x, y, size, offColor, onColor, z, offAlpha, onAlpha)
        local key = string.lower(tostring(name or "sparkles"))

        local function glyph(color, depth, alpha)
            -- Always emit the same calls, even at alpha 0, to keep pool indices stable.
            if key == "keyboard" then
                Rect(x + 1, y + 3, size - 2, 2, color, depth, 1, alpha)
                Rect(x + 1, y + size - 5, size - 2, 2, color, depth, 1, alpha)
                Rect(x + 1, y + 5, 2, size - 10, color, depth, 1, alpha)
                Rect(x + size - 3, y + 5, 2, size - 10, color, depth, 1, alpha)
                Rect(x + 5, y + 7, 2, 2, color, depth, 1, alpha)
                Rect(x + 9, y + 7, 2, 2, color, depth, 1, alpha)
                Rect(x + 5, y + 10, 6, 2, color, depth, 1, alpha)
            elseif key == "performance" or key == "eye" then
                Rect(x + 2,  y + 10, 3, 4,  color, depth, 1, alpha)
                Rect(x + 7,  y + 7,  3, 7,  color, depth, 1, alpha)
                Rect(x + 12, y + 3,  3, 11, color, depth, 1, alpha)
            else
                Rect(x + 7, y + 2, 2, 12, color, depth, 1, alpha)
                Rect(x + 2, y + 7, 12, 2, color, depth, 1, alpha)
                Rect(x + 11, y + 3, 2, 2, color, depth, 1, 0.72 * alpha)
            end
        end

        -- Fixed muted layer.
        glyph(offColor, z, offAlpha)

        -- Fixed accent layer. Same geometry/order every frame, so Matcha only
        -- sees Transparency change when the action is toggled.
        glyph(onColor, z + 1, onAlpha)
    end

    -- The title itself always determines the collapsed size. Registered actions
    -- add equal expansion space around it without ever moving the title.
    local islandText = string.upper(tostring(title or "DRAWING UI"))
    local islandTextSize = 15
    local islandPadX = 14
    local measuredTextW = TextWidth(islandText, islandTextSize, Fonts.SystemBold)
    local collapsedW = math.max(118, measuredTextW + islandPadX * 2)

    local leftCount, rightCount = 0, 0
    for _, action in ipairs(island.Actions) do
        if action.Side == "left" then
            leftCount = leftCount + 1
        elseif action.Side == "right" then
            rightCount = rightCount + 1
        end
    end

    local hasActions = (leftCount + rightCount) > 0
    local actionSlotW = 38
    local sideSlots = math.max(leftCount, rightCount)
    local expandedW = collapsedW + sideSlots * actionSlotW * 2
    local islandMaxW = math.max(collapsedW, State.W - 28)
    expandedW = math.min(expandedW, islandMaxW)

    local targetExpand = (hasActions and island.Open) and 1 or 0
    if State.NoAnim then
        island.Expand = targetExpand
        island.IconReveal = targetExpand
    else
        -- Stage 1: give the island width room to breathe. This is deliberately
        -- slower than the sidebar-style snap used previously.
        island.Expand = Approach(island.Expand or 0, targetExpand, 8.5, State.Delta)
        if math.abs(island.Expand - targetExpand) < 0.006 then
            island.Expand = targetExpand
        end

        -- Stage 2: icons only appear once the opening width is essentially
        -- complete. On close they disappear first, then contraction follows.
        local iconTarget = (island.Open and island.Expand >= 0.965) and 1 or 0
        island.IconReveal = Approach(island.IconReveal or 0, iconTarget, 13, State.Delta)
        if math.abs(island.IconReveal - iconTarget) < 0.01 then
            island.IconReveal = iconTarget
        end

        -- Hold the width open while the icons fade away so closing is the
        -- visual reverse of opening rather than both motions happening at once.
        if not island.Open and island.IconReveal > 0.035 then
            island.Expand = math.max(island.Expand, 1)
        end
    end

    local islandW = collapsedW + (expandedW - collapsedW) * island.Expand
    local islandH = 32
    local islandCX = State.X + State.W * 0.5
    local islandX = islandCX - islandW * 0.5
    local islandY = State.Y + (Layout.TopbarH - islandH) * 0.5

    FrostedSurface(islandX, islandY, islandW, islandH,
                   th.Panel, 31, 10)
    Stroke(islandX, islandY, islandW, islandH,
           th.Stroke, 32, 10, 0.56)

    -- Keep the intact title permanently anchored to the window centre.
    local textY = TextMidY(islandY, islandH, islandTextSize)
    local textX = islandCX - measuredTextW * 0.5
    local titleColor
    if State.NoAnim then
        titleColor = mix(th.AccentA, th.AccentB, 0.5)
    else
        local phase = (math.sin(os.clock() * 2.15) + 1) * 0.5
        local sweep = (math.sin(os.clock() * 1.35 + 0.8) + 1) * 0.5
        local gradientColor = mix(th.AccentA, th.AccentB, phase)
        local highlight = math.max(0, (sweep - 0.72) / 0.28)
        highlight = highlight * highlight
        titleColor = mix(gradientColor, th.Text, highlight * 0.72)
    end

    Text(islandText, textX, textY,
         titleColor, islandTextSize, Fonts.SystemBold,
         34, 1.0, nil, false)

    -- Actions reveal symmetrically away from the fixed title. Each action owns
    -- an icon, side, active-state getter and callback, making the island usable
    -- by scripts for more than the two built-in overlay controls.
    do
        -- IMPORTANT: render every registered action every frame, even while the
        -- island is closed. Alpha becomes zero while hidden, but keeping these
        -- draw calls present prevents the shared Square pool from changing
        -- indices when the island opens/closes.
        local actionAlpha = Clamp(island.IconReveal, 0, 1)
        local leftIndex, rightIndex = 0, 0

        for _, action in ipairs(island.Actions) do
            local index
            if action.Side == "left" then
                leftIndex = leftIndex + 1
                index = leftIndex
            else
                rightIndex = rightIndex + 1
                index = rightIndex
            end

            local slotCX
            if action.Side == "left" then
                slotCX = islandCX - collapsedW * 0.5 - actionSlotW * (index - 0.5)
            else
                slotCX = islandCX + collapsedW * 0.5 + actionSlotW * (index - 0.5)
            end

            local boxSize = 24
            local boxX = slotCX - boxSize * 0.5
            local boxY = islandY + (islandH - boxSize) * 0.5
            local hover = MouseIn(boxX, boxY, boxSize, boxSize)
            local active = false
            if type(action.GetActive) == "function" then
                local ok, value = pcall(action.GetActive)
                active = ok and value == true
            elseif action.Active ~= nil then
                active = action.Active == true
            end

            -- Keep island actions visually bare. OFF has no box/border at all;
            -- ON is communicated purely by highlighting the icon itself.
            -- Keep both colour layers alive every frame. Only transparency
            -- changes, giving Matcha a stable pool layout while making ON/OFF
            -- substantially more distinct.
            local offAlpha = actionAlpha * (active and 0.10 or (hover and 0.70 or 0.46))
            local onAlpha = actionAlpha * (active and 1.0 or 0.0)

            drawIslandIcon(action.Icon or "sparkles",
                           boxX + 4, boxY + 4, 16,
                           th.Text3, th.AccentA,
                           37, offAlpha, onAlpha)

            if hover and Input.Click and actionAlpha > 0.90 then
                if type(action.Callback) == "function" then
                    pcall(action.Callback, action)
                end
                Input.Click = false
                return
            end
        end
    end


    -- Clicking the title capsule toggles expansion. Clicking elsewhere on the
    -- top strip retains the normal window drag behaviour.
    local titleHitX = islandCX - collapsedW * 0.5
    if hasActions and MouseIn(titleHitX, islandY, collapsedW, islandH)
       and Input.Click and not State.Drag then
        island.Open = not island.Open
        Input.Click = false
        return
    end

    if MouseIn(State.X, State.Y, State.W, Layout.TopbarH)
       and Input.Click and not State.Drag then
        BeginDrag()
        Input.Click = false
    end
end

-- ============================================================================
--  TAB RAIL  --  sidebar with tabs, icons, hover/active states
-- ============================================================================

local function TickRailOpen(dt)
    -- Defensive guard for executors that begin the render callback before any
    -- geometry pass has populated the derived rail coordinates.
    if Geometry.RailX == nil or Geometry.RailY == nil
       or Geometry.RailW == nil or Geometry.RailH == nil then
        Geometry.Recalculate()
    end

    -- The entire detached sidebar section is the hover trigger.
    -- This means the rail opens when the cursor is anywhere over the
    -- sidebar surface, not just when it is directly over a tab.
    local sectionPadLeft = 10
    local sectionPadRight = 10
    local sectionPadY = 5
    -- Use the live window position as a safe fallback if derived rail geometry
    -- has not been populated yet on this render callback.
    local railX = Geometry.RailX or State.X
    local railY = Geometry.RailY or (State.Y + Layout.TopbarH)
    local railW = Geometry.RailW or Layout.TabRailNarrow
    local railH = Geometry.RailH or math.max(1, State.H - Layout.TopbarH - Geometry.FooterH)

    local sectionX = railX + sectionPadLeft
    local sectionY = railY + sectionPadY
    local sectionW = math.max(40, railW - sectionPadLeft - sectionPadRight)
    local sectionH = math.max(44, railH - 10)

    local overSidebar = MouseIn(sectionX, sectionY, sectionW, sectionH)

    local target = (State.RailPinned or overSidebar) and 1 or 0

    -- Smooth but responsive expansion.
    State.RailOpen = Approach(State.RailOpen, target, 7, dt)
    if math.abs(State.RailOpen - target) < 0.001 then
        State.RailOpen = target
    end
end

local function StartupRevealCount(total, progress)
    if not State.Startup.Active or State.Startup.Phase ~= "reveal" then
        return total
    end
    if total <= 0 then return 0 end
    return math.min(total, math.max(0, math.ceil(total * progress)))
end

local function DrawTabRail()
    local th = State.Theme
    local openAmt = State.RailOpen

    -- Keep the drawing path safe even if the executor invokes this callback
    -- before derived geometry has been populated.
    local railX = Geometry.RailX or State.X
    local railY = Geometry.RailY or (State.Y + Layout.TopbarH)
    local railW = Geometry.RailW or Layout.TabRailNarrow
    local railH = Geometry.RailH or math.max(1, State.H - Layout.TopbarH - Geometry.FooterH)

    -- The main window remains the background. The navigation is intentionally
    -- detached from it, so there is no full-height solid rail behind this panel.

    -- The tabs now live inside their own detached rounded section. The section
    -- is inset from the sidebar edges so the navigation reads as its own layer.
    -- Detached navigation container: no full-height sidebar fill.
    -- Keep a clear gap from the main window edge so the navigation reads as
    -- its own floating section. It is slightly larger than the previous build.
    local sectionPadX = 10

    -- New sidebar motion: the detached navigation layer slides into place
    -- while it expands. The rail geometry itself stays unchanged so hover,
    -- clicking and the content layout remain stable throughout the animation.
    local sectionX = railX + sectionPadX
    local sectionY = railY + 5
    local sectionW = math.max(40, railW - sectionPadX - sectionPadX)
    local sectionH = math.max(44, railH - 10)

    -- Frosted sidebar: let the main glass pane subtly show through instead
    -- of using a fully opaque block. The faint outline keeps the detached
    -- section readable without competing with the pill tabs.
    FrostedSurface(sectionX, sectionY, sectionW, sectionH,
                   rgb(12, 16, 25), 36, 12)
    Stroke(sectionX, sectionY, sectionW, sectionH,
           th.Stroke, 37, 12, 0.42)

    -- The logo remains the sidebar's visual anchor, but branding text stays
    -- in the floating island. A larger logo gives the rail identity without
    -- consuming enough vertical space to noticeably push the tab list down.
    local brandH = 49
    local brandLogoSize = 38
    local brandLogoX = sectionX + (sectionW - brandLogoSize) * 0.5
    local brandLogoY = sectionY + 6

    if State.Logo then
        DrawPicture(State.Logo, brandLogoX, brandLogoY,
                    brandLogoSize, brandLogoSize,
                    Layer(40), FrameAlpha, 8)
    else
        Rect(brandLogoX, brandLogoY,
             brandLogoSize, brandLogoSize,
             th.Accent, 40, 8, 0.10)
        Stroke(brandLogoX, brandLogoY,
               brandLogoSize, brandLogoSize,
               th.Accent, 41, 8, 0.42)
    end

    -- A short divider keeps the logo visually separated from navigation while
    -- remaining lighter than the old branding block.
    Line(sectionX + 13, sectionY + brandH,
         sectionX + sectionW - 13, sectionY + brandH,
         th.Stroke, 39, 1, 0.26)

    local rowY = sectionY + brandH + 7
    local padX = 8
    local rowH = Layout.TabRowH
    local tabGap = Layout.TabGap
    local iconSize = Layout.TabIcon
    local visibleTabs = StartupRevealCount(#State.Tabs, State.Startup.RevealProgress)
    local settingsIndex = nil
    for i, tab in ipairs(State.Tabs) do
        if tab.IsSettings then settingsIndex = i break end
    end

    for i, tab in ipairs(State.Tabs) do
        if i > visibleTabs then break end
        if not tab.Hidden then
            -- Pill tabs: expanded tabs fill the usable section width, while
            -- collapsed tabs become compact centered capsules instead of large
            -- square blocks. Both states use the same rounded geometry.
            local collapsedTabW = math.min(50, math.max(44, sectionW - 18))
            local expandedTabPadX = 6
            local sectionTabW = math.max(1, sectionW - expandedTabPadX * 2)

            local collapsedScale = 1.00 - (0.04 * openAmt)
            local tabRowH = rowH * collapsedScale
            local narrowTabW = collapsedTabW
            local wideTabW = sectionTabW
            local w = narrowTabW + (wideTabW - narrowTabW) * openAmt

            local x = sectionX + (sectionW - w) * 0.5
            local y = tab.IsSettings and (sectionY + sectionH - rowH - 11) or rowY
            local yOffset = (rowH - tabRowH) * 0.5
            y = y + yOffset

            local railClipTop = sectionY + 1
            local railClipBottom = sectionY + sectionH - 1
            local insideAnimatedRail = (y >= railClipTop and y + tabRowH <= railClipBottom)
            if State.Startup.Active and not insideAnimatedRail then
                rowY = rowY + rowH + tabGap
                continue
            end

            local hover = MouseIn(x, y, w, tabRowH)
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

            -- Soft capsule surface. The radius tracks the height so the
            -- ends stay fully rounded in both collapsed and expanded states.
            local stateMix = tab.Hover * 0.55 + tab.Glow * 0.45
            local bgColor = mix(rgb(40, 44, 58), rgb(55, 60, 76), stateMix)
            local pillRadius = math.max(8, math.floor(tabRowH * 0.5))
            SolidSurface(x, y, w, tabRowH, bgColor, 40, pillRadius)

            -- Active state is a subtle accent wash instead of the old square
            -- side marker, keeping the pill silhouette clean.
            if tab.Glow > 0.01 then
                local activeColor = mix(bgColor, th.Accent, tab.Glow * 0.16)
                SolidSurface(x, y, w, tabRowH, activeColor, 41, pillRadius)
            end

            -- icon column. When the rail is collapsed there is no label, so
            -- center the icon in the entire tab instead of leaving it offset
            -- toward the old label position.
            -- Interpolate the icon position continuously. In the collapsed
            -- state it is centered; as the rail opens it glides smoothly into
            -- the expanded left-aligned position instead of jumping at 50%.
            local collapsedIconSize = math.min(iconSize, tabRowH - 10)
            local centeredIconX = x + math.max(0, (narrowTabW - collapsedIconSize) / 2)
            local expandedIconX = x + 12
            local iconX = centeredIconX + (expandedIconX - centeredIconX) * openAmt
            local drawIconSize = iconSize + (collapsedIconSize - iconSize) * (1 - openAmt)
            local iconY = y + (tabRowH - drawIconSize) / 2
            local iconAlpha = 0.55 + 0.45 * math.max(tab.Glow, tab.Hover)
            local iconColor = tab.Glow > 0.5 and th.Accent or th.TextDim

            if not DrawIconByName(tab.Icon, iconX, iconY, drawIconSize,
                                  iconColor, 44, iconAlpha) then
                -- fallback: small square mark
                Rect(iconX + 3, iconY + 3, math.max(1, drawIconSize - 6), math.max(1, drawIconSize - 6),
                     iconColor, 44, 2, iconAlpha)
            end

            -- label
            if openAmt > 0.02 then
                local labelX = x + 38
                local labelRoom = w - (labelX - x) - 8
                local labelY = TextMidY(y, tabRowH, Layout.TextSize)
                local labelColor = th.Text
                local labelAlpha = openAmt * (0.7 + 0.3 * math.max(tab.Glow, tab.Hover))
                if tab.Glow > 0.5 then
                    labelColor = th.Text
                    labelAlpha = openAmt
                end
                Text(tab.Name, labelX, labelY,
                     labelColor, Layout.TextSize, Fonts.SystemBold,
                     45, labelAlpha, labelRoom)
            end

            -- click
            if hover and Input.Click then
                if State.ActiveIndex ~= i then
                    State.ActiveIndex = i
                end
                Input.Click = false
            end

            if not tab.IsSettings then
                rowY = rowY + tabRowH + tabGap
            end
        end
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
        Tooltip     = opts.Tooltip or "",
        Hidden      = false,
        Enabled     = true,
        ConfigKey   = opts.ConfigKey or opts.configKey or opts.Flag or opts.flag,
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
             th.Text, Layout.TextSize, Fonts.System,
             50, self.Enabled and 0.92 or 0.4, w)

        if self.Description ~= "" then
            local descY = y + 16
            Text(self.Description, x, descY,
                 th.TextDim, Layout.SmallSize, Fonts.System,
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
            local textW = TextWidth(self.Title, Layout.TinySize, Fonts.SystemBold)
            local px = 6
            local gap = 8
            -- left line
            Line(x, cy, x + 6, cy, th.Divider, 50, 1, 0.5)
            -- title
            Text(string.upper(self.Title),
                 x + gap, cy - 6,
                 th.TextMuted, Layout.TinySize, Fonts.SystemBold,
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
                     TextWidth(self.ButtonText, Layout.TextSize, Fonts.SystemBold) + 24))
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
        local lw = TextWidth(label, Layout.TextSize, Fonts.SystemBold)
        local lc = mix(th.Text, th.Accent, glow * 0.7)
        Text(label, btnX + (btnW - lw) / 2, TextMidY(btnY, h, Layout.TextSize),
             lc, Layout.TextSize, Fonts.SystemBold, 54, self.Enabled and 1 or 0.5)

        -- title on the left
        if self.Title ~= "" then
            local titleY = TextMidY(y, Layout.ButtonH + 6, Layout.TextSize)
            Text(self.Title, x, titleY,
                 th.Text, Layout.TextSize, Fonts.System,
                 51, self.Enabled and 0.9 or 0.4,
                 btnX - x - 10)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.ButtonH
        local btnW = math.max(60,
            math.min(w * 0.4,
                     TextWidth(self.ButtonText, Layout.TextSize, Fonts.SystemBold) + 24))
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
    self.Height  = Layout.ToggleH

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
        local checkbox = string.lower(tostring(State.Settings.ToggleStyle or "Switch")) == "checkbox"
        local trackW = checkbox and 18 or Layout.ToggleW
        local trackH = checkbox and 18 or Layout.ToggleH
        local knob   = Layout.ToggleKnob

        local trackX = x + w - trackW
        local trackY = y + (self.Height - trackH) / 2

        local hover = MouseIn(trackX, trackY, trackW, trackH) and self.Enabled
        TickAnim(self, hover, hover and Input.Down, State.Delta)

        local target = self.Value and 1 or 0
        self._knob = Approach(self._knob, target, 22, State.Delta)
        if math.abs(self._knob - target) < 0.01 then self._knob = target end

        if checkbox then
            local fill = mix(th.PanelHi, th.Accent, self._knob)
            Rect(trackX, trackY, trackW, trackH, fill, 52, 4, 0.82 + 0.12 * self._hover)
            Stroke(trackX, trackY, trackW, trackH,
                   self.Value and th.AccentA or th.Stroke, 53, 4,
                   self.Value and 0.92 or 0.62)
            -- Fixed check geometry every frame; alpha alone represents state.
            local checkA = self._knob
            Bar(trackX + 4, trackY + 9, trackX + 7, trackY + 12,
                1.6, th.Text, 54, checkA)
            Bar(trackX + 7, trackY + 12, trackX + 14, trackY + 5,
                1.6, th.Text, 54, checkA)
        else
            local trackColor = mix(th.Track, th.Accent, self._knob)
            local trackAlpha = 0.75 + 0.25 * self._hover
            Rect(trackX, trackY, trackW, trackH, trackColor, 52,
                 trackH / 2, trackAlpha)
            Stroke(trackX, trackY, trackW, trackH, th.Stroke, 53,
                   trackH / 2, 0.5)

            local knobX = trackX + 2 + (trackW - knob - 4) * self._knob
            local knobY = trackY + (trackH - knob) / 2
            local knobColor = mix(th.TextDim, th.Text, self._knob)
            Circle(knobX + knob / 2, knobY + knob / 2, knob / 2,
                   knobColor, 54, true, 1, 18, 1)
        end

        -- title
        if self.Title ~= "" then
            local titleY = TextMidY(y, self.Height, Layout.TextSize)
            Text(self.Title, x, titleY,
                 th.Text, Layout.TextSize, Fonts.System,
                 51, self.Enabled and 0.92 or 0.4,
                 trackX - x - 10)
        end

        -- description
        if self.Description ~= "" then
            local descY = y + self.Height - 4
            Text(self.Description, x, descY,
                 th.TextDim, Layout.SmallSize, Fonts.System,
                 51, self.Enabled and 0.6 or 0.25,
                 trackX - x - 10)
            self.Height = math.max(self.Height, Layout.ToggleH + 12)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local checkbox = string.lower(tostring(State.Settings.ToggleStyle or "Switch")) == "checkbox"
        local trackW = checkbox and 18 or Layout.ToggleW
        local trackH = checkbox and 18 or Layout.ToggleH
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
--  RADIO  --  mutually exclusive option group
-- ============================================================================

Register("Radio", function(parent, opts)
    opts = opts or {}
    local self = Base.New("Radio", parent, opts)
    self.Options = opts.Options or opts.options or {}
    self.Value = opts.Default or opts.default or self.Options[1]
    self.Callback = opts.Callback or opts.callback
    self.RowH = 24
    self.Height = math.max(28, (#self.Options * self.RowH) + (self.Title ~= "" and 24 or 4))

    function self:GetValue() return self.Value end

    function self:SetValue(v, silent)
        local valid = false
        for _, option in ipairs(self.Options) do
            if option == v then valid = true break end
        end
        if not valid or self.Value == v then return end
        self.Value = v
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local top = y
        if self.Title ~= "" then
            Text(self.Title, x, y + 2, th.Text, Layout.TextSize,
                 Fonts.System, 51, self.Enabled and 0.92 or 0.4, w)
            top = y + 23
        end

        for i, option in ipairs(self.Options) do
            local cy = top + (i - 1) * self.RowH + self.RowH / 2
            local selected = self.Value == option
            local hover = MouseIn(x, top + (i - 1) * self.RowH, w, self.RowH) and self.Enabled
            local ring = selected and th.AccentA or th.Stroke
            Circle(x + 9, cy, 7, ring, 52, false, 1.5, 18, hover and 0.95 or 0.72)
            Circle(x + 9, cy, 3.5, th.AccentA, 53, true, 1, 18, selected and 1 or 0)
            Text(tostring(option), x + 24, cy - Layout.TextSize / 2,
                 selected and th.Text or th.TextDim, Layout.TextSize,
                 Fonts.System, 53, self.Enabled and 0.95 or 0.4, w - 24)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local top = y + (self.Title ~= "" and 23 or 0)
        for i, option in ipairs(self.Options) do
            local ry = top + (i - 1) * self.RowH
            if MouseIn(x, ry, w, self.RowH) and Input.Click then
                Input.Click = false
                self:SetValue(option)
                return
            end
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
        local valueW = TextWidth(valueText, Layout.TextSize, Fonts.Monospace)
        local badgeW = valueW + 14
        local badgeH = 18
        local badgeX = x + w - badgeW
        local badgeY = y + 2

        -- title
        if self.Title ~= "" then
            Text(self.Title, x, y + 1,
                 th.Text, Layout.TextSize, Fonts.System,
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
             th.Accent, Layout.TextSize, Fonts.Monospace,
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

local WantTooltip

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
            if ctrl.Enabled ~= false and MouseIn(ctrl._inlineX, ctrl._inlineY, ctrl._inlineW, ctrl.Height or Layout.RowHeight) then
                WantTooltip(ctrl.Tooltip or ctrl.Description)
            end
        end
    end

    return maxH
end

-- Inline input uses the exact geometry cached by LayoutInline so the
-- clickable area always matches the controls that were drawn.
local function InputInline(row, x, y, w)
    local n = #row.Cells
    if n == 0 then return 0 end

    -- Refresh the same column geometry if input runs before this frame's draw.
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
        maxH = math.max(maxH, ctrl.Height or Layout.RowHeight)
        cx = cx + cw + pad
    end

    for i = 1, n do
        local ctrl = row.Cells[i]
        if not ctrl.Hidden and ctrl.Enabled ~= false and ctrl.Input then
            ctrl:Input(ctrl._inlineX, ctrl._inlineY, ctrl._inlineW)
        end
    end

    return maxH
end

--  CONTENT  --  generic render pass: walks a tab's rows and draws them
-- ============================================================================

local DrawKeybindOverlay
local UpdateKeybindOverlayInput
local DrawPerformanceOverlay
local UpdatePerformanceOverlayInput
local TickPerformanceOverlay

local ContentCursor = { y = 0 }

-- Forward declarations used by section rendering/input.
local DrawRow
local InputRow

local function IsSection(row)
    return getmetatable(row) == Section
end

local function GetSectionHeaderHeight(section)
    -- Header now lives inside the section card: top padding + title +
    -- optional description + separator breathing room.
    if section.Description and section.Description ~= "" then
        return Layout.SectionTitleH + Layout.SectionDescH + 17
    end
    return Layout.SectionTitleH + 15
end

local function TickSection(section)
    local target = section.Collapsed and 1 or 0
    section._collapse = section._collapse or target
    if State.NoAnim then
        section._collapse = target
    else
        section._collapse = Approach(section._collapse, target, 18, State.Delta)
        if math.abs(section._collapse - target) < 0.01 then
            section._collapse = target
        end
    end
end

local function MeasureSection(section, w)
    TickSection(section)

    local panelW = math.max(1, w)
    local innerW = math.max(1, panelW - Layout.SectionPadX * 2)
    local contentH = 0

    for _, child in ipairs(section.Rows or {}) do
        if not child.Hidden then
            if getmetatable(child) == InlineRow then
                local h = 0
                for _, ctrl in ipairs(child.Cells or {}) do
                    if not ctrl.Hidden then
                        h = math.max(h, ctrl.Height or Layout.RowHeight)
                    end
                end
                contentH = contentH + (h > 0 and h or Layout.RowHeight)
            else
                contentH = contentH + (child.Height or Layout.RowHeight)
            end
            contentH = contentH + Layout.RowGapY
        end
    end

    if contentH > 0 then
        contentH = contentH - Layout.RowGapY
    end

    local headerH = GetSectionHeaderHeight(section)
    local contentMinH = math.max(Layout.RowHeight, contentH)
    local fullPanelH = Layout.SectionPadY + contentMinH + Layout.SectionPadY
    local collapse = Clamp(section._collapse or 0, 0, 1)
    local visiblePanelH = fullPanelH * (1 - collapse)

    return headerH + visiblePanelH
end

local ActiveClipTop = nil
local ActiveClipBottom = nil

local function VerticalVisible(y, h)
    if ActiveClipTop == nil or ActiveClipBottom == nil then return true end
    h = math.max(0, h or 0)
    return (y + h >= ActiveClipTop) and (y <= ActiveClipBottom)
end

local function DrawSection(section, x, y, w)
    TickSection(section)

    local headerH = GetSectionHeaderHeight(section)
    local collapse = Clamp(section._collapse or 0, 0, 1)

    -- Reconstruct the uncollapsed content height.
    local contentH = 0
    for _, child in ipairs(section.Rows or {}) do
        if not child.Hidden then
            if getmetatable(child) == InlineRow then
                local h = 0
                for _, ctrl in ipairs(child.Cells or {}) do
                    if not ctrl.Hidden then h = math.max(h, ctrl.Height or Layout.RowHeight) end
                end
                contentH = contentH + (h > 0 and h or Layout.RowHeight)
            else
                contentH = contentH + (child.Height or Layout.RowHeight)
            end
            contentH = contentH + Layout.RowGapY
        end
    end
    if contentH > 0 then contentH = contentH - Layout.RowGapY end

    local fullContentH = Layout.SectionPadY + math.max(Layout.RowHeight, contentH) + Layout.SectionPadY
    local visibleContentH = math.max(0, fullContentH * (1 - collapse))
    local totalH = headerH + visibleContentH

    section._layoutX = x
    section._layoutY = y
    section._layoutW = w
    section._layoutH = totalH

    local viewportTop = ActiveClipTop or -math.huge
    local viewportBottom = ActiveClipBottom or math.huge
    local clippedTop = math.max(y, viewportTop)
    local clippedBottom = math.min(y + totalH, viewportBottom)
    local clippedH = math.max(0, clippedBottom - clippedTop)
    if clippedH <= 0 then return end

    -- One continuous frosted card contains both section identity and controls.
    -- Preserve the section's rounded identity while it moves through the
    -- viewport. Matcha has no scissor rectangle, so the visible card geometry
    -- is shortened, but it should never visually turn into a square card.
    FrostedSurface(x, clippedTop, w, clippedH,
                   State.Theme.Panel, 40, Layout.SectionCorner)
    Stroke(x, clippedTop, w, clippedH,
           State.Theme.Stroke, 41, Layout.SectionCorner, 0.42)

    local headerVisible = (y >= viewportTop and y + headerH <= viewportBottom)
    if headerVisible then
        local titleX = x + Layout.SectionPadX
        local chevronCX = x + w - Layout.SectionPadX - 7
        local chevronCY = y + math.floor(headerH * 0.43)

        Text(section.Title,
             titleX, y + 7,
             State.Theme.Text, Layout.TitleSize,
             Fonts.SystemBold, 50, 0.98,
             math.max(1, chevronCX - titleX - 16))

        if section.Description and section.Description ~= "" then
            Text(section.Description,
                 titleX, y + 7 + Layout.SectionTitleH,
                 State.Theme.TextDim, Layout.SmallSize,
                 Fonts.System, 50, 0.72,
                 math.max(1, chevronCX - titleX - 16))
        end

        -- Animated drawn chevron. collapse=0 points down; collapse=1 points
        -- right, so the affordance follows the existing collapse tween.
        local arm = 4.2
        local downLX, downLY = chevronCX - arm, chevronCY - 2
        local downRX, downRY = chevronCX + arm, chevronCY - 2
        local downMX, downMY = chevronCX, chevronCY + 2.5
        local rightLX, rightLY = chevronCX - 2, chevronCY - arm
        local rightRX, rightRY = chevronCX - 2, chevronCY + arm
        local rightMX, rightMY = chevronCX + 2.5, chevronCY

        local ax = downLX + (rightLX - downLX) * collapse
        local ay = downLY + (rightLY - downLY) * collapse
        local bx = downMX + (rightMX - downMX) * collapse
        local by = downMY + (rightMY - downMY) * collapse
        local cx = downRX + (rightRX - downRX) * collapse
        local cy = downRY + (rightRY - downRY) * collapse

        Bar(ax, ay, bx, by, 1.45, State.Theme.Accent, 51, 0.88)
        Bar(bx, by, cx, cy, 1.45, State.Theme.Accent, 51, 0.88)

        -- Fade the separator with the section content so a fully collapsed
        -- section leaves only the clean header card.
        local separatorAlpha = 0.46 * (1 - collapse)
        if separatorAlpha > 0.01 then
            Line(x + Layout.SectionPadX, y + headerH - 1,
                 x + w - Layout.SectionPadX, y + headerH - 1,
                 State.Theme.Stroke, 49, 1, separatorAlpha)
        end
    end

    if collapse >= 0.985 then return end

    local panelY = y + headerH
    local innerX = x + Layout.SectionPadX
    local innerY = panelY + Layout.SectionPadY
    local innerW = math.max(1, w - Layout.SectionPadX * 2)
    local cy = innerY
    local contentBottom = math.min(panelY + visibleContentH - Layout.SectionPadY,
                                   viewportBottom - Layout.SectionPadY)

    for _, child in ipairs(section.Rows or {}) do
        if not child.Hidden and cy < contentBottom then
            local estimatedH = child.Height or Layout.RowHeight
            if getmetatable(child) == InlineRow then
                estimatedH = Layout.RowHeight
                for _, ctrl in ipairs(child.Cells or {}) do
                    if not ctrl.Hidden then
                        estimatedH = math.max(estimatedH, ctrl.Height or Layout.RowHeight)
                    end
                end
            end

            local h = estimatedH
            local fullyInsideViewport =
                cy >= viewportTop and
                (cy + estimatedH) <= contentBottom and
                (cy + estimatedH) <= viewportBottom

            if fullyInsideViewport then
                if getmetatable(child) == InlineRow then
                    h = LayoutInline(child, innerX, cy, innerW)
                else
                    h = DrawRow(child, innerX, cy, innerW)
                end
            end

            cy = cy + (h or Layout.RowHeight) + Layout.RowGapY
        end
    end
end

local function InputSection(section)
    local x = section._layoutX or 0
    local y = section._layoutY or 0
    local w = section._layoutW or 0
    local headerH = GetSectionHeaderHeight(section)

    if MouseIn(x, y, w, headerH) and Input.Click then
        section.Collapsed = not section.Collapsed
        Input.Click = false
        return
    end

    if (section._collapse or 0) >= 0.98 then return end

    local panelY = y + headerH
    local innerX = x + Layout.SectionPadX
    local innerY = panelY + Layout.SectionPadY
    local innerW = math.max(1, w - Layout.SectionPadX * 2)
    local cy = innerY

    for _, child in ipairs(section.Rows or {}) do
        if not child.Hidden then
            local h = child.Height or Layout.RowHeight
            if getmetatable(child) == InlineRow then
                h = Layout.RowHeight
                for _, ctrl in ipairs(child.Cells or {}) do
                    if not ctrl.Hidden then h = math.max(h, ctrl.Height or Layout.RowHeight) end
                end
                if cy >= Geometry.ContentY and cy + h <= Geometry.ContentY + Geometry.ContentH then
                    InputInline(child, innerX, cy, innerW)
                end
            else
                if cy >= Geometry.ContentY and cy + h <= Geometry.ContentY + Geometry.ContentH then
                    h = InputRow(child, innerX, cy, innerW)
                end
            end
            cy = cy + (h or Layout.RowHeight) + Layout.RowGapY
        end
    end
end

function DrawRow(row, x, y, w)
    if row.Hidden then return 0 end

    if IsSection(row) then
        DrawSection(row, x, y, w)
        return row._layoutH or MeasureSection(row, w)
    end

    if getmetatable(row) == InlineRow then
        local h = LayoutInline(row, x, y, w)
        for _, ctrl in ipairs(row.Cells or {}) do
            local kind = ctrl.Kind
            local tooltipAllowed = kind == "Toggle"
                or kind == "Button"
                or kind == "Slider"
                or kind == "RangeSlider"
                or kind == "Dropdown"
            if tooltipAllowed and ctrl.Enabled ~= false and ctrl.Tooltip and ctrl.Tooltip ~= ""
                and ctrl._inlineX and ctrl._inlineY and ctrl._inlineW
                and MouseIn(ctrl._inlineX, ctrl._inlineY, ctrl._inlineW, ctrl.Height or Layout.RowHeight) then
                WantTooltip(ctrl.Tooltip)
            end
        end
        return h or Layout.RowHeight
    end

    if row.Draw then
        local ok, err = pcall(function()
            row:Draw(x, y, w)
        end)
        if not ok then
            if not row._drawErrorShown then
                row._drawErrorShown = true
                warn("[Library] control draw error:", tostring(row.Kind), tostring(row.Title), tostring(err))
            end
            return row.Height or Layout.RowHeight
        end

        local kind = row.Kind
        local tooltipAllowed = kind == "Toggle"
            or kind == "Button"
            or kind == "Slider"
            or kind == "RangeSlider"
            or kind == "Dropdown"
        if tooltipAllowed and row.Enabled ~= false and row.Tooltip and row.Tooltip ~= ""
            and MouseIn(x, y, w, row.Height or Layout.RowHeight) then
            WantTooltip(row.Tooltip)
        end
        return row.Height or Layout.RowHeight
    end

    return 0
end

function InputRow(row, x, y, w)
    if row.Hidden then return 0 end

    if IsSection(row) then
        InputSection(row)
        return row._layoutH or MeasureSection(row, w)
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
--  Next: PART 5 -- control batch B: Range, Dropdown, Keybind
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
        local valueW = TextWidth(valueText, Layout.TextSize, Fonts.Monospace)
        local badgeW = valueW + 14
        local badgeH = 18
        local badgeX = x + w - badgeW
        local badgeY = y + 2

        if self.Title ~= "" then
            Text(self.Title, x, y + 1,
                 th.Text, Layout.TextSize, Fonts.System,
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
             th.Accent, Layout.TextSize, Fonts.Monospace,
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
    self.Options  = opts.Options or opts.options or {}
    self.Multi    = (opts.Multi == true or opts.multi == true or
                     opts.MultiSelect == true or opts.multiSelect == true)
    self.Callback = opts.Callback or opts.callback
    self.Height   = 32

    self._open = false
    self._openAnim = 0
    self._listScroll = 0
    self._listScrollTo = 0
    self._scrollDrag = false
    self._scrollDragOffsetY = 0
    self._popupGeom = nil

    local function CopyArray(value)
        local out = {}
        if type(value) == "table" then
            for _, v in ipairs(value) do out[#out + 1] = v end
        end
        return out
    end

    local function Contains(list, value)
        for _, v in ipairs(list or {}) do
            if v == value then return true end
        end
        return false
    end

    local default = opts.Default
    if default == nil then default = opts.default end

    if self.Multi then
        self.Value = CopyArray(default)
    else
        self.Value = default
        if self.Value == nil then self.Value = self.Options[1] end
    end

    function self:GetValue()
        if self.Multi then return CopyArray(self.Value) end
        return self.Value
    end

    function self:SetValue(v, silent)
        if self.Multi then
            local nextValue = CopyArray(v)
            self.Value = nextValue
            if not silent then
                local emitted = CopyArray(nextValue)
                if self.Callback then pcall(self.Callback, emitted) end
                self:_Fire(emitted)
            end
            return
        end

        if self.Value == v then return end
        self.Value = v
        if not silent then
            if self.Callback then pcall(self.Callback, v) end
            self:_Fire(v)
        end
    end

    function self:_ToggleOption(option)
        if not self.Multi then
            self:SetValue(option)
            self._open = false
            return
        end

        local nextValue = CopyArray(self.Value)
        local found = nil
        for i, v in ipairs(nextValue) do
            if v == option then found = i break end
        end
        if found then
            table.remove(nextValue, found)
        else
            nextValue[#nextValue + 1] = option
        end
        self:SetValue(nextValue)
    end

    function self:_DisplayValue()
        if not self.Multi then return tostring(self.Value or "-") end
        if #self.Value == 0 then return "None" end
        local parts = {}
        for _, v in ipairs(self.Value) do parts[#parts + 1] = tostring(v) end
        return table.concat(parts, ", ")
    end

    local function FitText(text, maxW, size, font)
        text = tostring(text or "")
        maxW = math.max(1, maxW or 1)
        if TextWidth(text, size, font) <= maxW then return text end

        local dots = "..."
        local dotsW = TextWidth(dots, size, font)
        if dotsW >= maxW then return "" end

        local lo, hi = 0, #text
        while lo < hi do
            local mid = math.ceil((lo + hi) / 2)
            local candidate = string.sub(text, 1, mid) .. dots
            if TextWidth(candidate, size, font) <= maxW then
                lo = mid
            else
                hi = mid - 1
            end
        end
        return string.sub(text, 1, lo) .. dots
    end

    function self:_BuildFieldGeometry(x, y, w, h)
        local fieldY = y + 2
        local labelW = self.Title ~= "" and TextWidth(self.Title, Layout.TextSize, Fonts.System) or 0

        -- Preserve enough room for the title, but let the selector itself size
        -- to the selected text. Multi-select can grow to a fixed cap, after
        -- which the displayed selection is ellipsized.
        local labelReserve = math.min(w * 0.48, labelW + 18)
        local availableW = math.max(70, w - labelReserve)
        local maxFieldW = math.min(240, availableW)

        local display = self:_DisplayValue()
        local textW = TextWidth(display, Layout.TextSize, Fonts.SystemBold)
        local desiredW = textW + 34 -- compact left room + arrow/right padding
        local fieldW = Clamp(desiredW, 70, maxFieldW)

        -- Right-align compact selectors so all dropdown arrows stay aligned.
        local fieldX = x + w - fieldW

        return {
            X = fieldX,
            Y = fieldY,
            W = fieldW,
            H = h,
            Display = display,
            LabelRoom = math.max(1, fieldX - x - 8),
        }
    end

    function self:_BuildPopupGeometry(fieldX, fieldY, fieldW, h)
        local rowH = 22
        local maxVisible = 8
        local visible = math.min(#self.Options, maxVisible)
        local listH = visible * rowH + 8

        -- One canonical on-screen rectangle is used by drawing AND input.
        -- Size the selector to its actual content instead of always stretching
        -- to the full field width. It can grow to a fixed cap, then text uses
        -- ellipsis inside the popup.
        local minX = Geometry.ContentX + 4
        local maxRight = Geometry.ContentX + Geometry.ContentW - 4
        local availableW = math.max(70, maxRight - minX)
        local maxPopupW = math.min(260, availableW)

        local widest = TextWidth(self:_DisplayValue(), Layout.TextSize, Fonts.SystemBold)
        for _, option in ipairs(self.Options) do
            widest = math.max(widest, TextWidth(tostring(option), Layout.TextSize, Fonts.System))
        end

        local scrollbarRoom = (#self.Options > maxVisible) and 17 or 8
        local desiredW = widest + 18 + scrollbarRoom
        local popupW = Clamp(math.max(fieldW, desiredW), 70, maxPopupW)

        -- Prefer aligning the popup's right edge with the selector field. This
        -- keeps a compact popup visually attached to the selected-value chip.
        local preferredX = fieldX + fieldW - popupW
        local popupX = Clamp(preferredX, minX, math.max(minX, maxRight - popupW))
        local popupY = fieldY + h + 3

        local maxScroll = math.max(0, #self.Options - maxVisible)
        local barW = 5
        local trackX = popupX + popupW - barW - 3
        local trackY = popupY + 4
        local trackH = listH - 8
        local thumbH = maxScroll > 0 and math.max(14, trackH * (maxVisible / #self.Options)) or trackH
        local travel = math.max(1, trackH - thumbH)

        return {
            X = popupX, Y = popupY, W = popupW, H = listH,
            RowH = rowH, MaxVisible = maxVisible, Visible = visible,
            MaxScroll = maxScroll,
            TrackX = trackX, TrackY = trackY, TrackW = barW,
            TrackH = trackH, ThumbH = thumbH, Travel = travel,
        }
    end

    function self:Draw(x, y, w)
        local th = State.Theme
        local h = Layout.DropdownH

        local fg = self:_BuildFieldGeometry(x, y, w, h)
        local fieldX, fieldY, fieldW = fg.X, fg.Y, fg.W

        local hover = MouseIn(fieldX, fieldY, fieldW, h) and self.Enabled
        TickAnim(self, hover, self._open, State.Delta)

        local bg = mix(th.PanelHi, th.Panel, self._hover * 0.5)
        Rect(fieldX, fieldY, fieldW, h, bg, 52, 6, 0.85 + 0.1 * self._hover)
        Stroke(fieldX, fieldY, fieldW, h, th.Stroke, 53, 6, 0.5 + 0.3 * self._hover)

        if self.Title ~= "" then
            Text(self.Title, x, fieldY + (h - Layout.TextSize) / 2,
                 th.Text, Layout.TextSize, Fonts.System,
                 54, self.Enabled and 0.92 or 0.4,
                 fg.LabelRoom)
        end

        -- Compact selected-value spacing: keep only a small gap before the
        -- arrow instead of the older oversized right padding.
        local valueRightPad = 22
        local valueMaxW = math.max(1, fieldW - valueRightPad - 6)
        local valueText = FitText(fg.Display, valueMaxW, Layout.TextSize, Fonts.SystemBold)
        local valueW = TextWidth(valueText, Layout.TextSize, Fonts.SystemBold)
        Text(valueText,
             fieldX + fieldW - valueRightPad - valueW,
             fieldY + (h - Layout.TextSize) / 2,
             th.Accent, Layout.TextSize, Fonts.SystemBold,
             54, self.Enabled and 1 or 0.4,
             valueMaxW)

        local cx = fieldX + fieldW - 14
        local cy = fieldY + h / 2
        local ang = (self._open and 1 or 0) * math.pi
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

        self._openAnim = Approach(self._openAnim, self._open and 1 or 0, 20, State.Delta)
        if math.abs(self._openAnim - (self._open and 1 or 0)) < 0.01 then
            self._openAnim = self._open and 1 or 0
        end

        if self._openAnim > 0.02 then
            local pg = self:_BuildPopupGeometry(fieldX, fieldY, fieldW, h)
            self._popupGeom = pg
            if self._open then
                State.OpenDropdownWheelRect = { X = pg.X, Y = pg.Y, W = pg.W, H = pg.H }
                State.ActiveDropdown = self
            end
            self:_DrawList(pg, th)
        elseif not self._open then
            self._popupGeom = nil
        end
    end

    function self:_DrawList(pg, th)
        local maxScroll = pg.MaxScroll
        self._listScrollTo = Clamp(self._listScrollTo, 0, maxScroll)
        if State.NoAnim then
            self._listScroll = self._listScrollTo
        else
            self._listScroll = Approach(self._listScroll, self._listScrollTo, 22, State.Delta)
            if math.abs(self._listScroll - self._listScrollTo) < 0.05 then
                self._listScroll = self._listScrollTo
            end
        end

        Rect(pg.X + 2, pg.Y + 3, pg.W, pg.H, Color3.new(0, 0, 0), 60, 6, 0.25 * self._openAnim)
        Rect(pg.X, pg.Y, pg.W, pg.H, th.Base, 61, 6, 0.98 * self._openAnim)
        Stroke(pg.X, pg.Y, pg.W, pg.H, th.Accent, 62, 6, 0.5 * self._openAnim)

        local scrollbarReserve = maxScroll > 0 and 11 or 3
        local optionPadX = 8
        local labelMaxW = math.max(1, pg.W - optionPadX - 5 - scrollbarReserve)

        for i = 1, pg.Visible do
            local idx = i + math.floor(self._listScroll)
            local option = self.Options[idx]
            if option == nil then break end

            local ry = pg.Y + 4 + (i - 1) * pg.RowH
            local selected = self.Multi and Contains(self.Value, option) or (option == self.Value)
            local hoverW = math.max(1, pg.W - 8 - (maxScroll > 0 and 9 or 0))
            local hover = MouseIn(pg.X + 4, ry, hoverW, pg.RowH)

            if selected or hover then
                local a = selected and 0.18 or 0.1
                Rect(pg.X + 4, ry, hoverW, pg.RowH, th.Accent, 63, 4, a * self._openAnim)
            end

            local optionText = FitText(option, labelMaxW, Layout.TextSize, Fonts.System)
            local labelColor = selected and th.Accent or th.Text
            Text(optionText,
                 pg.X + optionPadX, ry + (pg.RowH - Layout.TextSize) / 2,
                 labelColor, Layout.TextSize, Fonts.System,
                 64, (selected and 1 or 0.85) * self._openAnim,
                 labelMaxW)

            if hover and Input.Click and not self._scrollDrag then
                Input.Click = false
                self:_ToggleOption(option)
            end
        end

        if maxScroll > 0 then
            local thumbY = pg.TrackY + pg.Travel * (self._listScroll / maxScroll)
            Rect(pg.TrackX, pg.TrackY, pg.TrackW, pg.TrackH,
                 th.Track, 65, pg.TrackW / 2, 0.62 * self._openAnim)
            Rect(pg.TrackX, thumbY, pg.TrackW, pg.ThumbH,
                 th.Accent, 66, pg.TrackW / 2,
                 (self._scrollDrag and 1 or 0.9) * self._openAnim)
        end
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.DropdownH
        local fg = self:_BuildFieldGeometry(x, y, w, h)
        local fieldX, fieldY, fieldW = fg.X, fg.Y, fg.W

        -- Popup option clicks use the canonical on-screen popup rectangle.
        if self._open and self._popupGeom then
            local pg = self._popupGeom
            if Input.Click and MouseIn(pg.X, pg.Y, pg.W, pg.H) then
                local row = math.floor((Input.Y - (pg.Y + 4)) / pg.RowH) + 1
                if row >= 1 and row <= pg.Visible then
                    local idx = row + math.floor(self._listScroll)
                    local option = self.Options[idx]
                    local scrollbarZone = pg.MaxScroll > 0 and
                        MouseIn(pg.TrackX - 3, pg.TrackY, pg.TrackW + 6, pg.TrackH)
                    if option ~= nil and not scrollbarZone then
                        Input.Click = false
                        self:_ToggleOption(option)
                        return
                    end
                end
            end

            if Input.Click
               and not MouseIn(fieldX, fieldY, fieldW, h)
               and not MouseIn(pg.X, pg.Y, pg.W, pg.H) then
                self._open = false
            end
        end

        if MouseIn(fieldX, fieldY, fieldW, h) and Input.Click then
            Input.Click = false
            self._open = not self._open
            if self._open then State.ActiveDropdown = self end
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
                 th.Text, Layout.TextSize, Fonts.System,
                 51, self.Enabled and 0.92 or 0.4,
                 w - 80)
            titleW = TextWidth(self.Title, Layout.TextSize, Fonts.System)
        end

        -- chip on the right
        local display = self._listening and "..." or KeyLabel.Format(self.Value)
        local chipW = math.max(38, TextWidth(display, Layout.TextSize, Fonts.Monospace) + 18)
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
             chipX + (chipW - TextWidth(display, Layout.TextSize, Fonts.Monospace)) / 2 + 4,
             chipY + (h - Layout.TextSize) / 2,
             labelColor, Layout.TextSize, Fonts.Monospace,
             54, self.Enabled and 1 or 0.5)
    end

    function self:Input(x, y, w)
        if not self.Enabled then return end
        local h = Layout.FieldH

        local display = self._listening and "..." or KeyLabel.Format(self.Value)
        local chipW = math.max(38, TextWidth(display, Layout.TextSize, Fonts.Monospace) + 18)
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
--  INTERNAL CONFIG TEXTBOX  --  Settings-only editor, not public API
-- ============================================================================

Register("ConfigTextbox", function(parent, opts)
    opts = opts or {}
    local self = Base.New("ConfigTextbox", parent, opts)
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
        local fieldY = y + 2
        local labelW = self.Title ~= "" and TextWidth(self.Title, Layout.TextSize, Fonts.System) or 0
        local fieldX = x + math.min(w * 0.48, labelW + 18)
        local fieldW = math.max(70, w - (fieldX - x))

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
                 th.Text, Layout.TextSize, Fonts.System,
                 54, self.Enabled and 0.92 or 0.4,
                 100)
            textX = textX + TextWidth(self.Title, Layout.TextSize, Fonts.System) + 12
        end

        -- value / placeholder
        local val = self._focus.Value
        local display = (val == "" and not focused) and self.Placeholder or val
        local color = (val == "" and not focused) and th.TextMuted or th.Text

        local availW = fieldW - (textX - fieldX) - 12
        local visible = display
        if TextWidth(visible, Layout.TextSize, Fonts.Monospace) > availW then
            -- trim from left to show end of value
            local excess = TextWidth(visible, Layout.TextSize, Fonts.Monospace) - availW
            local cut = math.ceil(excess / (Layout.TextSize * (FontMetrics[Fonts.Monospace] or 0.6)))
            visible = string.sub(visible, cut + 1)
        end

        Text(visible, textX, fieldY + (h - Layout.TextSize) / 2,
             color, Layout.TextSize, Fonts.Monospace, 54, 1, availW)

        -- caret (blinking when focused)
        if focused then
            self._caretAnim = self._caretAnim - State.Delta * 1.6
            if self._caretAnim < 0 then self._caretAnim = 1 end
            local caretAlpha = (self._caretAnim > 0.5) and 1 or 0.2

            -- position caret within visible range
            local caretX = textX + TextWidth(string.sub(val, 1, self._focus.Caret), Layout.TextSize, Fonts.Monospace)
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
--  Next: PART 6 -- ColorPicker and Section sub-tabs
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
    self.Height    = 22

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
        local h = 16

        -- title
        local titleW = 0
        if self.Title ~= "" then
            Text(self.Title, x, TextMidY(y, self.Height, Layout.TextSize),
                 th.Text, Layout.TextSize, Fonts.System,
                 51, self.Enabled and 0.92 or 0.4,
                 w - 44)
        end

        -- swatch
        local swatchW = 24
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
        local pph = 172

        -- single clean rounded popup frame
        Rect(px, py, pw, pph, th.Base, 61, 8, 0.98 * a)
        Stroke(px, py, pw, pph, th.Stroke, 62, 8, 0.55 * a)

        local padX = 10
        local padY = 10

        -- --- saturation/value field ---
        local svX = px + padX
        local svY = py + padY
        local svW = pw - padX * 2 - 14
        local svH = 88

        -- base hue color
        local hr, hg, hb = HSVToRGB(self._h, 1, 1)
        local hueColor = Color3.new(hr, hg, hb)

        -- white -> hue gradient (columns)
        GradientRect(svX, svY, svW, svH,
                     Color3.new(1, 1, 1), hueColor, 63, a, 64)

        -- black overlay (rows, top transparent -> bottom opaque)
        local steps = 48
        for i = 1, steps do
            local t = (i - 0.5) / steps
            Rect(svX, svY + svH * (i - 1) / steps,
                 svW, svH / steps + 1,
                 Color3.new(0, 0, 0), 64, 0, t * a)
        end

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
        local hues = 48
        for i = 1, hues do
            local t = (i - 0.5) / hues
            local r, g, b = HSVToRGB(t, 1, 1)
            local sw = hueW / hues + 1
            Rect(hueX + (i - 1) * (hueW / hues), hueY, sw, hueH,
                 Color3.new(r, g, b), 63, 0, a)
        end

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

        local r8 = math.floor(self.Value.R * 255 + 0.5)
        local g8 = math.floor(self.Value.G * 255 + 0.5)
        local b8 = math.floor(self.Value.B * 255 + 0.5)
        local hex = string.format("#%02X%02X%02X", r8, g8, b8)

        Text(hex,
             previewX + previewW + 8, prevY + 5,
             th.TextDim, Layout.SmallSize, Fonts.Monospace, 65, 0.9)

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

        Text(string.format("%d%%", math.floor(self._alpha * 100 + 0.5)),
             alphaX + alphaW - 30, alphaY + 8,
             th.TextDim, Layout.TinySize, Fonts.Monospace, 65, 0.8)

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
        local h = 16
        local swatchW = 24
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
--  PART 7 COMPLETE
--  Next: PART 8 -- Public API, main render loop, bootstrap
-- ============================================================================

-- ============================================================================
--  CONTENT RENDER  --  draws the active tab's rows inside the content area
-- ============================================================================

local function GetContentRevealUnits(tab)
    if not tab then return 0 end
    local units = 0
    local i = 1
    while i <= #(tab.Rows or {}) do
        local row = tab.Rows[i]
        if not row.Hidden then
            if IsSection(row) and tab.Rows[i + 1] and not tab.Rows[i + 1].Hidden and IsSection(tab.Rows[i + 1]) then
                units = units + 1
                i = i + 2
            else
                units = units + 1
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    return units
end

local function BuildContentLayout(tab, viewportTop, halfW)
    local items = {}
    local leftY = viewportTop
    local rightY = viewportTop
    local sectionIndex = 0
    local revealIndex = 0
    local i = 1

    while i <= #(tab.Rows or {}) do
        local row = tab.Rows[i]
        if row.Hidden then
            i = i + 1
        elseif IsSection(row) then
            sectionIndex = sectionIndex + 1
            revealIndex = revealIndex + 1

            local h = MeasureSection(row, halfW)
            local useLeft = (sectionIndex % 2) == 1
            local x = useLeft and Geometry.InnerX or (Geometry.InnerX + halfW + Layout.SectionColumnGap)
            local y = useLeft and leftY or rightY

            row._layoutX = x
            row._layoutY = y
            row._layoutW = halfW
            row._layoutH = h

            items[#items + 1] = {
                row = row,
                x = x,
                y = y,
                w = halfW,
                h = h,
                reveal = revealIndex,
                kind = "section",
            }

            if useLeft then
                leftY = y + h + Layout.SectionGap
            else
                rightY = y + h + Layout.SectionGap
            end
            i = i + 1
        else
            -- A non-section row is full width. It starts after whichever
            -- section column currently extends farther down.
            local y = math.max(leftY, rightY)
            local h
            if getmetatable(row) == InlineRow then
                h = 0
                for _, ctrl in ipairs(row.Cells or {}) do
                    if not ctrl.Hidden then
                        h = math.max(h, ctrl.Height or Layout.RowHeight)
                    end
                end
                h = h > 0 and h or Layout.RowHeight
            else
                h = row.Height or Layout.RowHeight
            end

            revealIndex = revealIndex + 1
            items[#items + 1] = {
                row = row,
                x = Geometry.InnerX,
                y = y,
                w = Geometry.InnerW,
                h = h,
                reveal = revealIndex,
                kind = "row",
            }

            local nextY = y + h + Layout.RowGapY
            leftY = nextY
            rightY = nextY
            i = i + 1
        end
    end

    return items, math.max(leftY, rightY) - viewportTop
end

local function DrawContent()
    local tab = State.Tabs[State.ActiveIndex]
    if not tab then return end

    local titleY = Geometry.ContentY + 6
    local title = tab.Name
    Text(title, Geometry.ContentX + Layout.ContentPadX, titleY,
         State.Theme.Text, 16, Fonts.SystemBold, 60, 0.98,
         Geometry.ContentW - Layout.ContentPadX * 2)

    if tab.Subtitle and tab.Subtitle ~= "" then
        Text(tab.Subtitle,
             Geometry.ContentX + Layout.ContentPadX, titleY + 20,
             State.Theme.TextDim, 11, Fonts.System, 60, 0.7,
             Geometry.ContentW - Layout.ContentPadX * 2)
    end

    Line(
        Geometry.ContentX + Layout.ContentPadX,
        titleY + (tab.Subtitle and 38 or 22),
        Geometry.ContentX + Geometry.ContentW - Layout.ContentPadX,
        titleY + (tab.Subtitle and 38 or 22),
        State.Theme.Divider, 60, 1, 0.6)

    local headerH = (tab.Subtitle and 42 or 26)
    local viewportTop = Geometry.ContentY + headerH + Layout.ContentPadY
    local viewportH = Geometry.ContentH - headerH - Layout.ContentPadY * 2
    local halfW = math.floor((Geometry.InnerW - Layout.SectionColumnGap) / 2)

    local items, contentH = BuildContentLayout(tab, viewportTop, halfW)
    tab.MaxScroll = math.max(0, contentH - viewportH)
    if tab._SearchTarget then
        for _, item in ipairs(items) do
            if item.row == tab._SearchTarget then
                tab.ScrollTo = Clamp(item.y - viewportTop, 0, tab.MaxScroll)
                tab.Scroll = tab.ScrollTo
                break
            end
        end
        tab._SearchTarget = nil
    end
    TickScroll(tab, State.Delta)
    HandleWheel(tab)

    local clipTop = viewportTop
    local clipBottom = Geometry.ContentY + Geometry.ContentH
    ActiveClipTop = clipTop
    ActiveClipBottom = clipBottom
    for _, item in ipairs(items) do
        local row = item.row
        local y = item.y - tab.Scroll
        local h = item.h
        local revealThis = item.reveal <= StartupRevealCount(#items, State.Startup.RevealProgress)

        if revealThis then
            if item.kind == "section" then
                if y + h >= clipTop and y <= clipBottom then
                    DrawSection(row, item.x, y, item.w)
                end
            else
                -- Matcha Drawing has no scissor rectangle. Hide partial rows
                -- instead of allowing their primitives to escape the window.
                if y >= clipTop and (y + h) <= clipBottom then
                    DrawRow(row, item.x, y, item.w)
                end
            end
        end
    end

    DrawScrollbar(tab)
    ActiveClipTop = nil
    ActiveClipBottom = nil
end

-- ============================================================================
--  CONTENT INPUT  --  routes clicks/wheel into the active tab's rows
-- ============================================================================

local function UpdateDropdownScrollbarInput()
    local dropdown = State.ActiveDropdown
    if not dropdown or not dropdown._open then
        if dropdown then dropdown._scrollDrag = false end
        State.ActiveDropdown = nil
        return false
    end

    local pg = dropdown._popupGeom
    if not pg or pg.MaxScroll <= 0 then
        dropdown._scrollDrag = false
        return false
    end

    -- Identical interaction pattern to the working main content scrollbar.
    local trackX, trackY = pg.TrackX, pg.TrackY
    local trackW, trackH = pg.TrackW, pg.TrackH
    local thumbH, travel = pg.ThumbH, pg.Travel
    local maxScroll = pg.MaxScroll
    local thumbY = trackY + travel * ((dropdown._listScrollTo or 0) / maxScroll)

    if dropdown._scrollDrag then
        if Input.Down then
            local newThumbY = Clamp(Input.Y - dropdown._scrollDragOffsetY,
                                    trackY, trackY + travel)
            local frac = (newThumbY - trackY) / math.max(1, travel)
            dropdown._listScrollTo = Clamp(frac * maxScroll, 0, maxScroll)
            dropdown._listScroll = dropdown._listScrollTo
            Input.Click = false
            return true
        else
            dropdown._scrollDrag = false
        end
    end

    if Input.Click and MouseIn(trackX - 3, thumbY - 2, trackW + 6, thumbH + 4) then
        dropdown._scrollDrag = true
        dropdown._scrollDragOffsetY = Input.Y - thumbY
        Input.Click = false
        return true
    end

    if Input.Click and MouseIn(trackX - 3, trackY, trackW + 6, trackH) then
        local centered = Clamp(Input.Y - thumbH / 2, trackY, trackY + travel)
        local frac = (centered - trackY) / math.max(1, travel)
        dropdown._listScrollTo = Clamp(frac * maxScroll, 0, maxScroll)
        dropdown._listScroll = dropdown._listScrollTo
        dropdown._scrollDrag = true
        dropdown._scrollDragOffsetY = thumbH / 2
        Input.Click = false
        return true
    end

    return false
end

local function InputContent()
    local tab = State.Tabs[State.ActiveIndex]
    if not tab then return end

    -- Dropdown flyouts are overlays, so their scrollbar must receive input
    -- globally rather than through the section row that spawned them.
    if UpdateDropdownScrollbarInput() then return end

    UpdateContentScrollbarInput(tab)
    if ContentScrollbarDrag.Active then return end

    if not MouseIn(Geometry.ContentX, Geometry.ContentY,
                   Geometry.ContentW, Geometry.ContentH) then
        return
    end

    local headerH = (tab.Subtitle and 42 or 26)
    local viewportTop = Geometry.ContentY + headerH + Layout.ContentPadY
    local halfW = math.floor((Geometry.InnerW - Layout.SectionColumnGap) / 2)
    local items = BuildContentLayout(tab, viewportTop, halfW)

    for _, item in ipairs(items) do
        local row = item.row
        local y = item.y - tab.Scroll
        local h = item.h

        local viewportBottom = Geometry.ContentY + Geometry.ContentH
        if item.kind == "section" then
            if y + h >= viewportTop and y <= viewportBottom then
                InputSection(row)
            end
        elseif y >= viewportTop and (y + h) <= viewportBottom then
            InputRow(row, item.x, y, item.w)
        end
    end

    if Input.Click and State.Popup then
        State.Popup = nil
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

-- Matcha may not expose Roblox's typeof() helper.
-- Detect Color3 values without relying on typeof().
local function IsColor3(value)
    if value == nil then return false end

    local okR, r = pcall(function() return value.R end)
    local okG, g = pcall(function() return value.G end)
    local okB, b = pcall(function() return value.B end)

    return okR and okG and okB
        and type(r) == "number"
        and type(g) == "number"
        and type(b) == "number"
end

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
        if IsColor3(v) then from[k] = v end
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
        if IsColor3(v) and from[k] then
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


-- Additional premium global themes.
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
--  NOTIFICATIONS  --  premium viewport-anchored toast system
-- ============================================================================

local Notification = {}
Notification.__index = Notification

local NoteColors = {
    info    = { accent = "Accent",   icon = "info",    label = "INFO"    },
    success = { accent = "Success",  icon = "success", label = "SUCCESS" },
    warning = { accent = "Warning",  icon = "warning", label = "WARNING" },
    error   = { accent = "Danger",   icon = "error",   label = "ERROR"   },
}

local function NormalizeNotificationPosition(value)
    local p = string.lower(tostring(value or "top_left"))
    p = string.gsub(p, "%s+", "_")
    p = string.gsub(p, "-", "_")
    if p == "topleft" then p = "top_left" end
    if p == "topright" then p = "top_right" end
    if p == "bottomleft" then p = "bottom_left" end
    if p == "bottomright" then p = "bottom_right" end

    if p ~= "top_left" and p ~= "top_right"
       and p ~= "bottom_left" and p ~= "bottom_right" then
        p = "top_left"
    end
    return p
end

local function Notify(opts)
    opts = opts or {}
    local entry = setmetatable({
        Title      = tostring(opts.Title or opts.title or "Notice"),
        Content    = tostring(opts.Content or opts.content or ""),
        Type       = string.lower(tostring(opts.Type or opts.type or "info")),
        Duration   = math.max(0.5, tonumber(opts.Duration or opts.duration) or 4),

        Fade       = 0,
        Slide      = 0,
        Life       = 0,
        TargetLife = math.max(0.5, tonumber(opts.Duration or opts.duration) or 4),
        Done       = false,
        -- Separate Drawing.Image holder using the same CreateWindow logo
        -- source, allowing several notifications and the titlebar logo to
        -- render simultaneously.
        Logo       = State.LogoSource and LoadPicture(State.LogoSource, "notification_logo") or nil,
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

        local targetFade, targetSlide
        local fadeDuration = 0.42

        -- The lifetime/progress bar now reaches exactly zero while the card
        -- is still fully visible. Only AFTER that does the toast fade away.
        if n.Life < 0.22 then
            local t = n.Life / 0.22
            targetFade = t
            targetSlide = (1 - t) * 34
        elseif n.Life <= n.TargetLife then
            targetFade = 1
            targetSlide = 0
        else
            local fadeT = Clamp((n.Life - n.TargetLife) / fadeDuration, 0, 1)
            targetFade = 1 - fadeT
            targetSlide = fadeT * 26
        end

        n.Fade  = Approach(n.Fade, targetFade, 22, dt)
        n.Slide = Approach(n.Slide, targetSlide, 20, dt)

        if n.Life >= n.TargetLife + fadeDuration and n.Fade < 0.02 then
            n.Done = true
        end

        if n.Done then
            HidePicture(n.Logo)
            table.remove(list, i)
        else
            i = i + 1
        end
    end
end

local function DrawNotifications()
    local th = State.Theme
    local vp = Camera.ViewportSize
    local pos = NormalizeNotificationPosition(State.NotificationPosition)

    -- Larger than the legacy 280x56 toast so important feedback stands out.
    local notW = 326
    local notH = 78
    local gap = 10
    local marginX = 18
    local marginY = 18

    local fromTop = (pos == "top_left" or pos == "top_right")
    local fromLeft = (pos == "top_left" or pos == "bottom_left")

    -- Oldest notification remains closest to the chosen anchor.
    for i, n in ipairs(State.Notifications) do
        local a = n.Fade
        if a > 0.005 then
            local stackOffset = (i - 1) * (notH + gap)
            local ny
            if fromTop then
                ny = marginY + stackOffset
            else
                ny = vp.Y - marginY - notH - stackOffset
            end

            local baseX = fromLeft and marginX or (vp.X - marginX - notW)
            local slideDir = fromLeft and -1 or 1
            local nx = baseX + slideDir * n.Slide

            local colors = NoteColors[n.Type] or NoteColors.info
            local accent = th[colors.accent] or th.Accent
            local typeLabel = colors.label or "INFO"

            -- Clean floating card: no external depth effect and no decorative
            -- accent rails. Type colour + progress bar carry the status.
            Rect(nx, ny, notW, notH,
                 rgb(13, 16, 23), 371, 12, 0.97 * a)
            Stroke(nx, ny, notW, notH,
                   th.Stroke, 372, 12, 0.72 * a)

            -- Use the same image source supplied to CreateWindow.logo.
            local logoSize = 38
            local logoX = nx + 15
            local logoY = ny + (notH - logoSize) / 2
            local drewLogo = DrawPicture(n.Logo, logoX, logoY,
                                         logoSize, logoSize,
                                         Layer(376), a, 8)
            if not drewLogo then
                -- Small neutral fallback while an async remote logo loads.
                Circle(logoX + logoSize / 2, logoY + logoSize / 2,
                       4, accent, 376, true, 1, 14, 0.85 * a)
            end

            local textX = logoX + logoSize + 12
            local rightPad = 14
            local textW = notW - (textX - nx) - rightPad

            -- Small semantic type label above the title.
            Text(typeLabel, textX, ny + 10,
                 accent, 8, Fonts.SystemBold, 377, 0.90 * a, textW)

            Text(n.Title, textX, ny + 24,
                 th.Text, 14, Fonts.SystemBold, 378, 0.99 * a, textW)

            if n.Content ~= "" then
                Text(n.Content, textX, ny + 45,
                     th.TextDim, 10, Fonts.System, 378, 0.84 * a, textW)
            end

            -- Lifetime track + accent progress. It shrinks toward the anchor.
            local progressX = nx + 14
            local progressY = ny + notH - 6
            local progressW = notW - 28
            Rect(progressX, progressY, progressW, 2,
                 th.Track, 379, 1, 0.60 * a)

            local remain = Clamp(1 - (n.Life / n.TargetLife), 0, 1)
            if remain > 0 then
                Rect(progressX, progressY, progressW * remain, 2,
                     accent, 380, 1, 0.95 * a)
            end
        end
    end
end

-- ============================================================================
--  TOOLTIPS  --  hover info panel, topmost layer
-- ============================================================================

local Tooltip = {
    Current = nil,
    X = 0, Y = 0,
    Fade = 0,
    LastSetAt = 0,
    Delay = 0.35,
    Hovered = false,
}

WantTooltip = function(text)
    if not text or text == "" then return end
    Tooltip.Hovered = true
    if Tooltip.Current ~= text then
        Tooltip.Current = text
        Tooltip.LastSetAt = os.clock()
    end
    Tooltip.X = Input.X
    Tooltip.Y = Input.Y
end

local function TickTooltip(dt)
    local target = 0
    if Tooltip.Hovered and Tooltip.Current and (os.clock() - Tooltip.LastSetAt) >= Tooltip.Delay then
        target = 1
    end

    Tooltip.Fade = Approach(Tooltip.Fade, target, 18, dt)

    if not Tooltip.Hovered and Tooltip.Fade < 0.02 then
        Tooltip.Current = nil
    end
    Tooltip.Hovered = false
end

local function DrawTooltip()
    if Tooltip.Fade < 0.02 or not Tooltip.Current then return end

    local th = State.Theme
    local a = Tooltip.Fade

    local text = Tooltip.Current
    local textW = TextWidth(text, 12, Fonts.System)
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

    -- depth effect + body
    Rect(tx + 2, ty + 3, boxW, boxH, Color3.new(0, 0, 0), 300, 6, 0.28 * a)
    Rect(tx, ty, boxW, boxH, th.Base, 301, 6, 0.98 * a)
    Stroke(tx, ty, boxW, boxH, th.Stroke, 302, 6, 0.6 * a)

    Text(text, tx + padX, ty + padY + 1,
         th.Text, 12, Fonts.System, 303, a)
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

    local visible = opts.Visible
    if visible == nil then visible = opts.visible end
    if visible == nil then visible = opts.SetVisible end
    if visible == nil then visible = opts.setVisible end
    if visible == nil then visible = true end

    local dynamic = opts.Dynamic
    if dynamic == nil then dynamic = opts.dynamic end
    dynamic = dynamic and true or false

    local explicitW = tonumber(opts.Width or opts.width or opts.W or opts.w)
    local explicitH = tonumber(opts.Height or opts.height or opts.H or opts.h)

    local self = setmetatable({
        Title       = tostring(opts.Title or opts.title or "Overlay"),
        X           = tonumber(opts.X or opts.x) or 40,
        Y           = tonumber(opts.Y or opts.y) or 40,
        W           = math.max(100, explicitW or 200),
        H           = explicitH,
        Lines       = {},
        Visible     = visible and true or false,
        Dynamic     = dynamic,
        MaxLines    = Clamp(math.floor(tonumber(opts.MaxLines or opts.maxLines) or 100), 1, 100),
        MaxChars    = Clamp(math.floor(tonumber(opts.MaxWidth or opts.maxWidth or opts.MaxChars or opts.maxChars) or 50), 8, 50),
        Font        = Fonts.ResolveOverlay(opts.Font or opts.font, Fonts.SystemBold),
        HeaderFont  = Fonts.ResolveOverlay(opts.HeaderFont or opts.headerFont, Fonts.SystemBold),
        FontSize    = Clamp(tonumber(opts.FontSize or opts.fontSize) or 10, 7, 18),
        HeaderSize  = Clamp(tonumber(opts.HeaderSize or opts.headerSize) or 12, 8, 20),
        Pin         = false,
        _drag       = nil,
        _hover      = 0,
        _reveal     = 0,
        _revealOrder = #HUDBoxes + 1,
    }, HUDBox)

    if self.H then self.H = math.max(48, self.H) end

    HUDBoxes[#HUDBoxes + 1] = self
    return self
end

function HUDBox:SetVisible(v)
    local nextVisible = v and true or false
    if nextVisible and not self.Visible then
        self._reveal = 0
        local now = State.OverlayRevealTime or 0
        local queued = math.max(now + 0.5, State.OverlayNextRevealAt or 0)
        self._revealAt = queued
        State.OverlayNextRevealAt = queued + 0.5
    end
    self.Visible = nextVisible
    if not self.Visible then self._drag = nil end
    return self
end

function HUDBox:GetVisible()
    return self.Visible
end

function HUDBox:Toggle()
    return self:SetVisible(not self.Visible)
end

function HUDBox:SetTitle(title)
    self.Title = tostring(title or "")
    return self
end

function HUDBox:SetSize(width, height)
    if width ~= nil then self.W = math.max(100, tonumber(width) or self.W) end
    if height ~= nil then self.H = math.max(48, tonumber(height) or (self.H or 48)) end
    return self
end

function HUDBox:SetDynamic(value)
    self.Dynamic = value and true or false
    return self
end

function HUDBox:SetFont(font)
    self.Font = Fonts.ResolveOverlay(font, self.Font)
    return self
end

function HUDBox:SetHeaderFont(font)
    self.HeaderFont = Fonts.ResolveOverlay(font, self.HeaderFont)
    return self
end

function HUDBox:SetPosition(x, y)
    if x ~= nil then self.X = tonumber(x) or self.X end
    if y ~= nil then self.Y = tonumber(y) or self.Y end
    return self
end

function HUDBox:Line(text, color, font)
    -- Whole-line style:
    --   overlay:Line("ONLINE", green, "SystemBold")
    --   overlay:Line({Text="ONLINE", Color=green, Font="Pixel"})
    --
    -- Rich per-segment style:
    --   overlay:Line({
    --       {Text="STATUS  ", Color=white, Font="UI"},
    --       {Text="ONLINE", Color=green, Font="SystemBold"},
    --   })
    if type(text) == "table" and not text.Text and not text.text then
        local segments = {}
        for _, part in ipairs(text) do
            if type(part) == "table" then
                segments[#segments + 1] = {
                    Text = tostring(part.Text or part.text or part[1] or ""),
                    Color = part.Color or part.color or part[2],
                    Font = Fonts.ResolveOverlay(part.Font or part.font or part[3], nil),
                    Size = tonumber(part.Size or part.size or part[4]),
                }
            else
                segments[#segments + 1] = {
                    Text = tostring(part),
                    Color = color,
                    Font = Fonts.ResolveOverlay(font, nil),
                }
            end
        end
        self.Lines[#self.Lines + 1] = {
            Segments = segments,
            Color = color,
            Font = Fonts.ResolveOverlay(font, self.Font),
        }
    else
        local tableFont = type(text) == "table" and (text.Font or text.font or text[3]) or nil
        local tableSize = type(text) == "table" and (text.Size or text.size or text[4]) or nil
        self.Lines[#self.Lines + 1] = {
            Text = tostring((type(text) == "table" and (text.Text or text.text or text[1])) or text or ""),
            Color = (type(text) == "table" and (text.Color or text.color or text[2])) or color,
            Font = Fonts.ResolveOverlay(tableFont or font, self.Font),
            Size = tonumber(tableSize),
        }
    end
    return self
end

function HUDBox:AddLine(text, color, font)
    return self:Line(text, color, font)
end

function HUDBox:SetLines(lines)
    self.Lines = {}
    for _, line in ipairs(lines or {}) do
        if type(line) == "table" and (line.Segments or line.segments) then
            self:Line(line.Segments or line.segments,
                      line.Color or line.color,
                      line.Font or line.font)
        elseif type(line) == "table" and (line.Text or line.text) then
            self:Line(line)
        elseif type(line) == "table" then
            self:Line(line)
        else
            self:Line(line)
        end
    end
    return self
end

function HUDBox:Clear()
    self.Lines = {}
    return self
end

local function DrawHUDBoxes()
    local th = State.Theme
    local previousAlpha = FrameAlpha
    FrameAlpha = 1

    for _, box in ipairs(HUDBoxes) do
        do
            local revealAt = box._revealAt
            if revealAt == nil then
                revealAt = math.max(0, (box._revealOrder + 1) * 0.5)
            end
            local revealTarget = (box.Visible and (State.OverlayRevealTime or 0) >= revealAt) and 1 or 0
            box._reveal = State.NoAnim and revealTarget
                or Approach(box._reveal or 0, revealTarget, 14, State.Delta)
            if math.abs((box._reveal or 0) - revealTarget) < 0.01 then box._reveal = revealTarget end

            local boxAlpha = box._reveal or 0
            FrameAlpha = boxAlpha

            local headerH = 34
            local padX = 12
            local contentPadY = 4
            local visibleCount = math.min(#box.Lines, box.MaxLines or 100)

            -- Measure rich text exactly using the font of every segment.
            local widestLine = 0
            local tallestLine = box.FontSize or 10
            for i = 1, visibleCount do
                local line = box.Lines[i]
                local lineW = 0
                local lineTall = box.FontSize or 10
                if line.Segments then
                    for _, segment in ipairs(line.Segments) do
                        local font = segment.Font or line.Font or box.Font or Fonts.SystemBold
                        local size = segment.Size or box.FontSize or 10
                        lineW = lineW + TextWidth(tostring(segment.Text or ""), size, font)
                        lineTall = math.max(lineTall, size)
                    end
                else
                    local font = line.Font or box.Font or Fonts.SystemBold
                    local size = line.Size or box.FontSize or 10
                    lineW = TextWidth(tostring(line.Text or ""), size, font)
                    lineTall = math.max(lineTall, size)
                end
                widestLine = math.max(widestLine, lineW)
                tallestLine = math.max(tallestLine, lineTall)
            end

            local headerFont = box.HeaderFont or Fonts.SystemBold
            local headerSize = box.HeaderSize or 12
            local header = string.upper(tostring(box.Title or "OVERLAY"))
            local headerW = TextWidth(header, headerSize, headerFont)

            -- Max width is expressed as a character ceiling (default/max 50),
            -- converted through the overlay's active font to a real pixel cap.
            local maxChars = Clamp(box.MaxChars or 50, 8, 50)
            local charCapW = TextWidth(string.rep("M", maxChars),
                                       box.FontSize or 10,
                                       box.Font or Fonts.SystemBold) + padX * 2
            local naturalW = math.max(headerW + 28, widestLine + padX * 2)
            local dynamicW = Clamp(naturalW, 100, math.max(100, charCapW))
            local boxW = box.Dynamic and dynamicW or box.W
            box.W = boxW

            local lineH = math.max(25, tallestLine + 12)
            local naturalH = headerH + math.max(1, visibleCount) * lineH + 8
            local totalH = box.Dynamic and naturalH
                or (box.H and math.max(headerH + 8, box.H) or naturalH)

            local vp = Camera.ViewportSize
            box.X = math.max(6, math.min(box.X, math.max(6, vp.X - boxW - 6)))
            box.Y = math.max(6, math.min(box.Y, math.max(6, vp.Y - totalH - 6)))

            if box._drag then
                if Input.Down then
                    box.X = Input.X - box._drag.gx
                    box.Y = Input.Y - box._drag.gy
                else
                    box._drag = nil
                end
            end

            local hover = MouseIn(box.X, box.Y, boxW, totalH)
            box._hover = Approach(box._hover, hover and 1 or 0, 16, State.Delta)

            if box.Visible and boxAlpha > 0.95
               and hover and Input.Click and State.Open and State.Visible >= 0.50 then
                box._drag = { gx = Input.X - box.X, gy = Input.Y - box.Y }
                Input.Click = false
            end

            Rect(box.X, box.Y, boxW, totalH, rgb(13, 16, 23), 351, 9, 0.96)
            Stroke(box.X, box.Y, boxW, totalH, th.Accent, 352, 9, 0.88)

            local measuredHeaderW = TextWidth(header, headerSize, headerFont)
            Text(header,
                 box.X + (boxW - measuredHeaderW) / 2,
                 TextMidY(box.Y, headerH, headerSize) - 2,
                 th.Text, headerSize, headerFont, 354, 1,
                 math.max(1, boxW - 20))

            Line(box.X + 10, box.Y + headerH - 1,
                 box.X + boxW - 10, box.Y + headerH - 1,
                 th.Accent, 354, 1, 0.22)

            for i = 1, visibleCount do
                local line = box.Lines[i]
                local rowY = box.Y + headerH + contentPadY + (i - 1) * lineH
                if rowY + 8 <= box.Y + totalH - 5 then
                    local tx = box.X + padX
                    local maxRight = box.X + boxW - padX

                    if line.Segments then
                        for _, segment in ipairs(line.Segments) do
                            if tx >= maxRight then break end
                            local font = segment.Font or line.Font or box.Font or Fonts.SystemBold
                            local size = segment.Size or box.FontSize or 10
                            local room = maxRight - tx
                            local segmentText = TrimText(tostring(segment.Text or ""), room, size, font)
                            if segmentText ~= "" then
                                Text(segmentText, tx,
                                     TextMidY(rowY, lineH, size),
                                     segment.Color or line.Color or th.Text,
                                     size, font, 355, 0.96, room)
                                tx = tx + TextWidth(segmentText, size, font)
                            end
                        end
                    else
                        local font = line.Font or box.Font or Fonts.SystemBold
                        local size = line.Size or box.FontSize or 10
                        Text(line.Text or "", tx,
                             TextMidY(rowY, lineH, size),
                             line.Color or th.Text,
                             size, font, 355, 0.96,
                             maxRight - tx)
                    end
                end
            end
            if not box.Visible then box._drag = nil end
        end
    end

    FrameAlpha = previousAlpha
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
    -- Startup owns the first render. Never draw the full window before
    -- CreateWindow has explicitly started the startup sequence.
    if not State.Startup.Active and State.Frame == 0 then
        ResetPool()
        HideUnused()
        return
    end

    -- read inputs
    ReadInput()
    ReadKeys()

    -- measure dt
    local now = os.clock()
    State.Delta = math.min(now - State.LastTick, 1 / 20)
    State.LastTick = now
    State.Frame = State.Frame + 1
    TickPerformanceOverlay(State.Delta)

    -- input capture dispatcher
    UpdateCapture()

    -- text focus
    TickFocus()

    -- Matcha input routing is stateful; enforce the desired state every render
    -- while an internal text editor owns keyboard focus.
    Library:_SyncGameInput(false)

    -- hotkey toggle
    local key = string.lower(State.MenuKey)
    local hk = Keys[string.upper(key)]
    if hk then
        if hk.Click then ToggleUI() end
    end


    -- lifecycle
    if not State.Startup.Active then
        EnsureWindowFitsTabs()
    end
    TickVisibility(State.Delta)
    TickTheme(State.Delta)
    TickStartup(State.Delta)
    if not State.Startup.Active then
        State.OverlayRevealTime = (State.OverlayRevealTime or 0) + State.Delta
    end

    local startupIsLoading = State.Startup.Active and State.Startup.Phase == "loading"
    local startupIsShrink = State.Startup.Active and State.Startup.Phase == "shrink"
    local startupIsPop = State.Startup.Active and State.Startup.Phase == "pop"
    local startupIsReveal = State.Startup.Active and State.Startup.Phase == "reveal"

    if startupIsLoading then
        HidePicture(State.BackgroundImage)
        -- Keep the configured splash dimensions stable throughout its hold.
        State.W = State.Startup.StartW
        State.H = State.Startup.StartH
        State.X = State.Startup.StartX
        State.Y = State.Startup.StartY

        Geometry.Recalculate()
        ResetPool()
        DrawStartupFrame()
        HideUnused()
        return
    end

    if startupIsShrink then
        HidePicture(State.Logo)
        HidePicture(State.BackgroundImage)
        Geometry.Recalculate()
        ResetPool()
        HidePicture(State.Startup.Image)
        HidePicture(State.Startup.BackgroundImage)
        local radius = math.min(Layout.Corner, math.max(1, State.H / 2))
        GlassSurface(State.X, State.Y, State.W, State.H, rgb(14, 16, 23), 10, radius)
        Stroke(State.X, State.Y, State.W, State.H, Color3.new(1, 1, 1), 20, radius, 0.72)
        if State.H <= 12 then
            Rect(State.X + 5, State.Y + State.H / 2 - 1,
                 math.max(1, State.W - 10), 2,
                 State.Theme.TextDim, 31, 1, 0.58)
        end
        HideUnused()
        return
    end

    if startupIsPop then
        HidePicture(State.Logo)
        Geometry.Recalculate()
        ResetPool()
        DrawFrame(true)

        local t = math.min(State.Startup.Time / State.Startup.PopDuration, 1)
        local flash = (1 - t) * (1 - t)
        if flash > 0.002 then
            local flashW = math.max(18, math.min(State.W * 0.22, 90 + 70 * t))
            Rect(State.X + (State.W - flashW) / 2,
                 State.Y + State.H / 2 - 1,
                 flashW, 2, State.Theme.TextDim,
                 45, 1, 0.34 * flash)
        end
        HideUnused()
        return
    end

    if State.Visible < 0.005 then
        HidePicture(State.Logo)
        HidePicture(State.BackgroundImage)
        -- window hidden: skip everything
        ResetPool()
        -- but notifications/tooltips still show
        TickNotifications(State.Delta)
        DrawNotifications()
        UpdateKeybindOverlayInput()
        UpdatePerformanceOverlayInput()
        DrawKeybindOverlay()
        DrawPerformanceOverlay()
        -- Custom HUD overlays are independent of the main window just like
        -- HOTKEYS/PERFORMANCE. They remain visible, but cannot be dragged
        -- until the main window is open again.
        DrawHUDBoxes()
        HideUnused()
        return
    end

    -- TickRailOpen uses derived rail geometry. Establish a valid baseline
    -- before any hover/animation math, including on the first render frame.
    Geometry.Recalculate()

    -- Animate/state updates.
    TickRailOpen(State.Delta)
    TickDrag(State.Delta)
    TickResize()

    -- Recalculate after state changes so rendering uses the final geometry
    -- for this frame.
    Geometry.Recalculate()

    -- reset drawing pool for this frame
    ResetPool()
    Tooltip.Hovered = false

    -- Persistent overlays must consume the same pool slots before any
    -- tab/control-dependent rendering. This prevents navigation/clicks from
    -- remapping their Drawing objects for a frame and causing flicker.
    UpdateKeybindOverlayInput()
    UpdatePerformanceOverlayInput()
    DrawKeybindOverlay()
    DrawPerformanceOverlay()
    DrawHUDBoxes()

    -- render back-to-front
    DrawFrame()
    DrawTitleBar(State.WindowTitle, State.WindowSubtitle)
    DrawTabRail()
    DrawContent()
    TickTooltip(State.Delta)

    -- Do not interact with partially revealed controls. They become live once
    -- the reveal reaches the final frame.
    if not startupIsReveal then
        InputContent()
    end

    -- drag from title bar handled in DrawTitleBar already

    -- notifications & tooltips sit above everything
    TickNotifications(State.Delta)
    DrawNotifications()
    DrawTooltip()

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
--  KEYBIND MANAGER
-- ============================================================================

local function CollectKeybinds()
    local out = {}
    local function walk(container, prefix)
        for _, row in ipairs(container.Rows or {}) do
            if getmetatable(row) == Section then
                walk(row, prefix .. row.Title .. "/")
            elseif getmetatable(row) == InlineRow then
                for _, ctrl in ipairs(row.Cells or {}) do
                    if ctrl.Kind == "Keybind" then
                        out[#out + 1] = { Path = prefix .. (ctrl.Title ~= "" and ctrl.Title or "Keybind"), Title = (ctrl.Title ~= "" and ctrl.Title or "Keybind"), Row = ctrl }
                    end
                end
            elseif row.Kind == "Keybind" then
                out[#out + 1] = { Path = prefix .. (row.Title ~= "" and row.Title or "Keybind"), Title = (row.Title ~= "" and row.Title or "Keybind"), Row = row }
            end
        end
    end
    for _, tab in ipairs(State.Tabs) do
        walk(tab, tab.Name .. "/")
    end
    return out
end

local KeybindHUD = {
    X = nil,
    Y = 18,
    Dragging = false,
    DragOffsetX = 0,
    DragOffsetY = 0,
    Reveal = 0,
}

local function GetKeybindOverlayGeometry()
    local vp = Camera.ViewportSize
    local list = CollectKeybinds()
    local maxRows = math.min(#list, 8)
    local rowH = 27
    local headerH = 34
    local footerH = #list > 8 and 20 or 8

    -- Size the whole HUD from the longest visible label and key. Every key
    -- chip starts on the same X position so shorter rows line up cleanly.
    local labelSize = 11
    local keySize = 12
    local longestLabelW = TextWidth("No hotkeys assigned", labelSize, Fonts.SystemBold)
    local longestKeyW = TextWidth("NONE", keySize, Fonts.SystemBold)
    for i = 1, math.min(#list, 8) do
        local entry = list[i]
        local title = tostring(entry.Title or "Hotkey")
        local value = string.upper(tostring(entry.Row and entry.Row.Value or "NONE"))
        longestLabelW = math.max(longestLabelW, TextWidth(title, labelSize, Fonts.SystemBold))
        longestKeyW = math.max(longestKeyW, TextWidth(value, keySize, Fonts.SystemBold))
    end

    local pillW = math.max(36, longestKeyW + 18)
    local leftPad, gap, rightPad = 12, 14, 12
    local w = math.max(142, leftPad + longestLabelW + gap + pillW + rightPad)
    local h = headerH + math.max(1, maxRows) * rowH + footerH
    local x = KeybindHUD.X
    if x == nil then x = math.max(10, vp.X - w - 18) end
    x = math.max(6, math.min(x, math.max(6, vp.X - w - 6)))
    local y = math.max(6, math.min(KeybindHUD.Y, math.max(6, vp.Y - h - 6)))
    return x, y, w, h, headerH, rowH, list, longestLabelW, pillW
end

UpdateKeybindOverlayInput = function()
    if State.Settings and State.Settings.KeybindOverlay == false then return end
    if (KeybindHUD.Reveal or 0) < 0.95 then return end
    if not State.Open or State.Visible < 0.50 then
        KeybindHUD.Dragging = false
        return
    end
    local x, y, w, h = GetKeybindOverlayGeometry()
    local hover = MouseIn(x, y, w, h)

    if KeybindHUD.Dragging then
        if Input.Down then
            KeybindHUD.X = Input.X - KeybindHUD.DragOffsetX
            KeybindHUD.Y = Input.Y - KeybindHUD.DragOffsetY
        else
            KeybindHUD.Dragging = false
        end
        Input.Click = false
        return
    end

    if hover and Input.Click then
        KeybindHUD.Dragging = true
        KeybindHUD.DragOffsetX = Input.X - x
        KeybindHUD.DragOffsetY = Input.Y - y
        KeybindHUD.X = x
        KeybindHUD.Y = y
        Input.Click = false
    end
end

DrawKeybindOverlay = function()
    local target = (State.Settings and State.Settings.KeybindOverlay ~= false
                    and (State.OverlayRevealTime or 0) >= 0) and 1 or 0
    KeybindHUD.Reveal = State.NoAnim and target
        or Approach(KeybindHUD.Reveal or 0, target, 14, State.Delta)
    local th = State.Theme
    local x, y, w, h, headerH, rowH, list, labelColumnW, pillW =
        GetKeybindOverlayGeometry()

    local previousAlpha = FrameAlpha
    FrameAlpha = KeybindHUD.Reveal or 0

    Rect(x, y, w, h, rgb(13, 16, 23), 331, 9, 0.96)
    Stroke(x, y, w, h, th.Accent, 332, 9, 0.88)

    local header = "HOTKEYS"
    local headerSize = 12
    local headerW = TextWidth(header, headerSize, Fonts.SystemBold)
    Text(header, x + (w - headerW) / 2,
         TextMidY(y, headerH, headerSize) - 2,
         th.Text, headerSize, Fonts.SystemBold, 334, 1, headerW + 2)

    Line(x + 10, y + headerH - 1, x + w - 10, y + headerH - 1,
         th.Accent, 334, 1, 0.22)

    local rowY = y + headerH
    if #list == 0 then
        local empty = "No hotkeys assigned"
        local emptyW = TextWidth(empty, 11, Fonts.SystemBold)
        Text(empty, x + (w - emptyW) / 2,
             TextMidY(rowY, rowH, 11),
             th.TextDim, 11, Fonts.SystemBold, 335, 0.82, emptyW + 2)
        FrameAlpha = previousAlpha
        return
    end

    local labelX = x + 12
    local pillX = labelX + labelColumnW + 14
    for i = 1, math.min(#list, 8) do
        local entry = list[i]
        local title = tostring(entry.Title or "Hotkey")
        local value = string.upper(tostring(entry.Row and entry.Row.Value or "NONE"))
        local labelSize = 11
        local keySize = 12
        local valueW = TextWidth(value, keySize, Fonts.SystemBold)
        local pillH = 20
        local pillY = rowY + (rowH - pillH) / 2

        Text(title, labelX, TextMidY(rowY, rowH, labelSize),
             th.Text, labelSize, Fonts.SystemBold, 336, 0.96, labelColumnW + 2)

        Rect(pillX, pillY, pillW, pillH, th.Accent, 337, 5, 0.13)
        Stroke(pillX, pillY, pillW, pillH, th.Accent, 338, 5, 0.42)
        Text(value,
             pillX + (pillW - valueW) / 2,
             TextMidY(pillY, pillH, keySize),
             th.Accent, keySize, Fonts.SystemBold, 339, 1, valueW + 2)

        rowY = rowY + rowH
    end

    if #list > 8 then
        local more = "+" .. tostring(#list - 8) .. " more"
        local moreW = TextWidth(more, 8, Fonts.SystemBold)
        Text(more, x + (w - moreW) / 2, rowY + 4,
             th.TextDim, 8, Fonts.SystemBold, 339, 0.68, moreW + 2)
    end

    FrameAlpha = previousAlpha
end

-- ============================================================================
--  PERFORMANCE OVERLAY
-- ============================================================================

local PerformanceHUD = {
    X = 18,
    Y = 18,
    Dragging = false,
    DragOffsetX = 0,
    DragOffsetY = 0,
    FPS = 60,
    FrameMS = 16.7,
    AccumTime = 0,
    AccumFrames = 0,
    Reveal = 0,
}

TickPerformanceOverlay = function(dt)
    dt = math.max(0.0001, tonumber(dt) or (1 / 60))
    PerformanceHUD.AccumTime = PerformanceHUD.AccumTime + dt
    PerformanceHUD.AccumFrames = PerformanceHUD.AccumFrames + 1
    if PerformanceHUD.AccumTime >= 0.35 then
        PerformanceHUD.FPS = PerformanceHUD.AccumFrames / PerformanceHUD.AccumTime
        PerformanceHUD.FrameMS = (PerformanceHUD.AccumTime / PerformanceHUD.AccumFrames) * 1000
        PerformanceHUD.AccumTime = 0
        PerformanceHUD.AccumFrames = 0
    end
end

local function GetPerformanceRows()
    local vp = Camera.ViewportSize
    return {
        {"FPS", tostring(math.floor(PerformanceHUD.FPS + 0.5))},
        {"FRAME", string.format("%.1f ms", PerformanceHUD.FrameMS)},
        {"WINDOW", tostring(math.floor(State.W)) .. " x " .. tostring(math.floor(State.H))},
        {"VIEWPORT", tostring(math.floor(vp.X)) .. " x " .. tostring(math.floor(vp.Y))},
    }
end

local function GetPerformanceOverlayGeometry()
    local vp = Camera.ViewportSize
    local rows = GetPerformanceRows()
    local labelSize, valueSize = 10, 10
    local labelW, valueW = 0, 0
    for _, row in ipairs(rows) do
        labelW = math.max(labelW, TextWidth(row[1], labelSize, Fonts.SystemBold))
        valueW = math.max(valueW, TextWidth(row[2], valueSize, Fonts.SystemBold))
    end
    local headerH, rowH = 34, 25
    local w = math.max(158, 12 + labelW + 18 + valueW + 12)
    local h = headerH + #rows * rowH + 8
    local x = math.max(6, math.min(PerformanceHUD.X, math.max(6, vp.X - w - 6)))
    local y = math.max(6, math.min(PerformanceHUD.Y, math.max(6, vp.Y - h - 6)))
    return x, y, w, h, headerH, rowH, rows, labelW, valueW
end

UpdatePerformanceOverlayInput = function()
    if State.Settings and State.Settings.PerformanceOverlay == false then return end
    if (PerformanceHUD.Reveal or 0) < 0.95 then return end
    if not State.Open or State.Visible < 0.50 then
        PerformanceHUD.Dragging = false
        return
    end
    local x, y, w, h = GetPerformanceOverlayGeometry()
    local hover = MouseIn(x, y, w, h)

    if PerformanceHUD.Dragging then
        if Input.Down then
            PerformanceHUD.X = Input.X - PerformanceHUD.DragOffsetX
            PerformanceHUD.Y = Input.Y - PerformanceHUD.DragOffsetY
        else
            PerformanceHUD.Dragging = false
        end
        Input.Click = false
        return
    end

    if hover and Input.Click then
        PerformanceHUD.Dragging = true
        PerformanceHUD.DragOffsetX = Input.X - x
        PerformanceHUD.DragOffsetY = Input.Y - y
        PerformanceHUD.X = x
        PerformanceHUD.Y = y
        Input.Click = false
    end
end

DrawPerformanceOverlay = function()
    local target = (State.Settings and State.Settings.PerformanceOverlay ~= false
                    and (State.OverlayRevealTime or 0) >= 0.5) and 1 or 0
    PerformanceHUD.Reveal = State.NoAnim and target
        or Approach(PerformanceHUD.Reveal or 0, target, 14, State.Delta)
    local th = State.Theme
    local x, y, w, h, headerH, rowH, rows, labelW =
        GetPerformanceOverlayGeometry()

    local previousAlpha = FrameAlpha
    FrameAlpha = PerformanceHUD.Reveal or 0

    Rect(x, y, w, h, rgb(13, 16, 23), 341, 9, 0.96)
    Stroke(x, y, w, h, th.Accent, 342, 9, 0.88)

    local header = "PERFORMANCE"
    local headerSize = 12
    local headerW = TextWidth(header, headerSize, Fonts.SystemBold)
    Text(header, x + (w - headerW) / 2,
         TextMidY(y, headerH, headerSize) - 2,
         th.Text, headerSize, Fonts.SystemBold, 344, 1, headerW + 2)

    Line(x + 10, y + headerH - 1, x + w - 10, y + headerH - 1,
         th.Accent, 344, 1, 0.22)

    local rowY = y + headerH
    local valueX = x + 12 + labelW + 18
    for _, row in ipairs(rows) do
        Text(row[1], x + 12, TextMidY(rowY, rowH, 10),
             th.TextDim, 10, Fonts.SystemBold, 345, 0.86, labelW + 2)
        Text(row[2], valueX, TextMidY(rowY, rowH, 10),
             th.Text, 10, Fonts.SystemBold, 346, 0.98, w - (valueX - x) - 12)
        rowY = rowY + rowH
    end

    FrameAlpha = previousAlpha
end


-- ============================================================================
--  GLOBAL SETTINGS TAB
-- ============================================================================

local function EnsureGlobalSettingsTab(library)
    for _, tab in ipairs(State.Tabs) do
        if tab.IsSettings then return tab end
    end

    local tab = Tab.new(library, {
        Title = "Settings",
        Icon = "settings",
        IsSettings = true,
    })

    local appearance = Section.new(tab, "Appearance", "Global interface appearance", {})
    Controls.Dropdown(appearance, {
        Title = "Theme",
        Options = {"Midnight", "Obsidian", "Burgundy", "Cyber", "Bubblegum", "Emerald", "Crimson", "Arctic", "Sunset"},
        Default = (State.Theme and State.Theme.Name) or "Midnight",
        Callback = function(value) SetThemeByName(value) end,
    })
    Controls.Dropdown(appearance, {
        Title = "Background",
        Options = {"none", "dots", "scanlines", "particles", "aurora", "snow", "rainfall"},
        Default = type(State.Background) == "table" and (State.Background.Type or "none") or State.Background,
        Callback = function(value) State.Background = NormalizeBackground(value) end,
    })
    Controls.Toggle(appearance, {
        Title = "Background effects",
        Description = "Master switch for the animated window background.",
        Default = State.Settings.BackgroundEffects,
        Callback = function(v) State.Settings.BackgroundEffects = v end,
    })
    Controls.Toggle(appearance, {
        Title = "Border animation",
        Description = "Animated comet travelling around the main border.",
        Default = State.Settings.BorderComet,
        Callback = function(v) State.Settings.BorderComet = v end,
    })
    Controls.Toggle(appearance, {
        Title = "Reduce animations",
        Description = "Disables most UI tweening and motion.",
        Default = State.NoAnim,
        Callback = function(v) State.NoAnim = v end,
    })
    Controls.Dropdown(appearance, {
        Title = "Toggle style",
        Description = "Switch between sliding toggles and compact checkboxes.",
        Options = {"Switch", "Checkbox"},
        Default = State.Settings.ToggleStyle,
        Callback = function(v) State.Settings.ToggleStyle = v end,
    })


    local hud = Section.new(tab, "Interface", "Global overlays and feedback", {})
    Controls.Slider(hud, {
        Title = "Window opacity",
        Description = "Controls how transparent or solid the main glass window is.",
        Min = 35, Max = 100, Default = State.Settings.WindowOpacity, Step = 1,
        Suffix = "%",
        Callback = function(v)
            State.Settings.WindowOpacity = v
            GlassSurfaceAlpha = math.max(0.20, math.min(1, v / 100))
        end,
    })


    local behavior = Section.new(tab, "Behavior", "Window and navigation preferences", {})
    Controls.Toggle(behavior, {
        Title = "Keep sidebar open",
        Description = "Pins the sidebar in its expanded state.",
        Default = State.RailPinned,
        Callback = function(v) State.RailPinned = v end,
    })
    Controls.Button(behavior, {
        Title = "Reset overlay position",
        Callback = function()
            KeybindHUD.X = nil
            KeybindHUD.Y = 18
        end,
    })
    Controls.Button(behavior, {
        Title = "Reset window position",
        Callback = function()
            local vp = Camera.ViewportSize
            State.X = math.floor((vp.X - State.W) / 2)
            State.Y = math.floor((vp.Y - State.H) / 2)
        end,
    })

    local configs = Section.new(tab, "Configs", "Save and manage interface configurations.", {})

    Controls.Label(configs, {
        Title = "Config name",
    })

    local configNameBox = Controls.ConfigTextbox(configs, {
        Title = "",
        Placeholder = "default",
        Default = State.Settings.ConfigName or "default",
        Callback = function(v)
            v = string.gsub(tostring(v or "default"), "[^%w_%-]", "_")
            if v == "" then v = "default" end
            State.Settings.ConfigName = v
        end,
    })

    local savedConfigs = Controls.Dropdown(configs, {
        Title = "Saved configs",
        Options = {"None"},
        Default = "None",
    })

    local function RefreshConfigs(selectName)
        local names = {}

        if type(listfiles) == "function" then
            local ok, files = pcall(listfiles, ".")
            if ok and type(files) == "table" then
                for _, path in ipairs(files) do
                    local file = tostring(path):gsub("\\", "/"):match("([^/]+)$") or tostring(path)
                    local name = file:match("^DrawingUI_(.+)%.json$")
                    if name and name ~= "" then
                        names[#names + 1] = name
                    end
                end
            end
        end

        table.sort(names, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        if #names == 0 then names[1] = "None" end
        savedConfigs.Options = names

        local wanted = selectName
        local found = false
        if wanted then
            for _, name in ipairs(names) do
                if name == wanted then found = true break end
            end
        end

        savedConfigs:SetValue(found and wanted or names[1], true)
    end

    Controls.Button(configs, {
        Title = "Save config",
        ButtonText = "Save",
        Callback = function()
            local name = State.Settings.ConfigName or "default"
            if configNameBox and configNameBox.GetValue then
                name = configNameBox:GetValue()
            end
            name = string.gsub(tostring(name or "default"), "[^%w_%-]", "_")
            if name == "" then name = "default" end
            State.Settings.ConfigName = name

            if library.SaveConfig then
                local ok = library:SaveConfig(name)
                if ok then RefreshConfigs(name) end
            end
        end,
    })

    Controls.Button(configs, {
        Title = "Load config",
        ButtonText = "Load",
        Callback = function()
            local name = savedConfigs:GetValue()
            if name and name ~= "None" and library.LoadConfig then
                library:LoadConfig(name)
                State.Settings.ConfigName = name
                configNameBox:SetValue(name, true)
            end
        end,
    })

    Controls.Button(configs, {
        Title = "Delete config",
        ButtonText = "Delete",
        Callback = function()
            local name = savedConfigs:GetValue()
            if name and name ~= "None" and library.DeleteConfig then
                local ok = library:DeleteConfig(name)
                if ok then RefreshConfigs() end
            end
        end,
    })

    RefreshConfigs()

    return tab
end

-- ============================================================================
--  PUBLIC API  --  the Library table every user script talks to
-- ============================================================================

local Library = {}

-- CreateWindow is the public constructor used by consumer scripts.
-- The startup animation is part of the same window.
function Library:CreateWindow(opts)
    opts = opts or {}
    GlassSurfaceAlpha = math.max(0.20, math.min(1, (State.Settings.WindowOpacity or 82) / 100))

    local size = opts.Size or opts.size
    if type(size) == "userdata" or type(size) == "table" then
        local sw = tonumber(size.X or size.x)
        local sh = tonumber(size.Y or size.y)
        if sw then State.W = math.max(Layout.WindowMinW, sw) end
        if sh then State.H = math.max(Layout.WindowMinH, sh) end
    else
        if opts.Width or opts.width then State.W = math.max(Layout.WindowMinW, tonumber(opts.Width or opts.width) or State.W) end
        if opts.Height or opts.height then State.H = math.max(Layout.WindowMinH, tonumber(opts.Height or opts.height) or State.H) end
    end

    State.WindowTitle = tostring(opts.Title or opts.title or opts.Name or opts.name or State.WindowTitle or "Window")
    State.WindowSubtitle = tostring(opts.Subtitle or opts.subtitle or "")

    local logoSource = opts.Logo or opts.logo
    if logoSource ~= nil and logoSource ~= State.LogoSource then
        HidePicture(State.Logo)
        State.LogoSource = logoSource
        State.Logo = LoadPicture(logoSource, "logo")
    end
    local logoSize = tonumber(opts.LogoSize or opts.logoSize)
    if logoSize then State.LogoSize = math.max(16, math.min(48, logoSize)) end

    local backgroundImageSource = opts.BackgroundImage or opts.backgroundImage
    if backgroundImageSource ~= nil and backgroundImageSource ~= State.BackgroundImageSource then
        HidePicture(State.BackgroundImage)
        State.BackgroundImageSource = backgroundImageSource
        State.BackgroundImage = LoadPicture(backgroundImageSource, "background")
    end

    if opts.MenuKey or opts.menuKey then State.MenuKey = string.lower(tostring(opts.MenuKey or opts.menuKey)) end

    -- Notification anchor. Defaults to top-left.
    -- Supported: top_left, top_right, bottom_left, bottom_right.
    local notifPos = opts.NotifPos or opts.notifpos or opts.NotificationPosition or opts.notificationPosition
    if notifPos ~= nil then
        State.NotificationPosition = NormalizeNotificationPosition(notifPos)
    end
    if opts.NoAnim ~= nil or opts.noAnim ~= nil then State.NoAnim = (opts.NoAnim ~= nil and opts.NoAnim or opts.noAnim) and true or false end
    if opts.Background ~= nil or opts.background ~= nil then State.Background = NormalizeBackground(opts.Background or opts.background) end
    local themeOption = opts.Theme or opts.theme
    if themeOption ~= nil then
        if type(themeOption) == "string" then
            for i, th in ipairs(Themes) do
                if string.lower(th.Name) == string.lower(themeOption) then
                    State.Theme = th
                    State.ThemeIndex = i
                    break
                end
            end
        elseif type(themeOption) == "table" then
            ApplyThemeOptions(themeOption)
        end
    end

    EnsureGlobalSettingsTab(self)

    local splashOption = opts.Splash
    if splashOption == nil then splashOption = opts.splash end

    if splashOption == false then
        StartStartup({ Enabled = false })
    else
        local splash = type(splashOption) == "table" and splashOption or {}
        local textFadeValue = splash.TextFade
        if textFadeValue == nil then textFadeValue = splash.textFade end
        -- Compatibility with the v1.1.0 splash option: shimmer now controls
        -- the cleaner character fade rather than the removed sweep effect.
        if textFadeValue == nil then textFadeValue = splash.Shimmer end
        if textFadeValue == nil then textFadeValue = splash.shimmer end
        if textFadeValue == nil then textFadeValue = true end

        StartStartup({
            Enabled = true,
            Duration = splash.Duration or splash.duration
                or opts.StartupDuration or opts.startupDuration
                or opts.Duration or opts.duration or 5.0,
            Size = splash.Size or splash.size,
            Image = splash.Image or splash.image,
            Title = splash.Title or splash.title,
            LogoSize = splash.LogoSize or splash.logoSize or splash.ImageSize or splash.imageSize or 50,
            TextFade = textFadeValue,
            BackgroundImage = splash.BackgroundImage or splash.backgroundImage,
            BackgroundOpacity = splash.BackgroundOpacity or splash.backgroundOpacity or 0.22,
        })
    end
    return self
end
Library.Version       = "1.2.2"
Library.Themes         = Themes
Library.Layout         = Layout
Library.State          = State
Library.Tabs           = {}

-- tabs ----------------------------------------------------------------------
function Library:AddTab(opts)
    opts = opts or {}
    local settingsTab, settingsIndex = nil, nil
    for i, existing in ipairs(State.Tabs) do
        if existing.IsSettings then
            settingsTab, settingsIndex = existing, i
            break
        end
    end

    if settingsTab then
        table.remove(State.Tabs, settingsIndex)
        if self.Tabs then
            for i, existing in ipairs(self.Tabs) do
                if existing == settingsTab then table.remove(self.Tabs, i) break end
            end
        end
    end

    local tab = Tab.new(self, opts)

    if settingsTab then
        State.Tabs[#State.Tabs + 1] = settingsTab
        self.Tabs[#self.Tabs + 1] = settingsTab
    end

    EnsureWindowFitsTabs()
    if opts.Select then
        local _, idx = FindTab(tab.Name)
        if idx then State.ActiveIndex = idx end
    end
    return tab
end

function Library:GetTab(name)
    local tab = FindTab(name)
    return tab
end

function Library:SelectTab(name)
    SetActiveTabByName(name)
end

-- configs -------------------------------------------------------------------
function Library:SaveConfig(name)
    name = string.gsub(tostring(name or "default"), "[^%w_%-]", "_")
    if name == "" then name = "default" end

    local data = {
        version = 1,
        theme = State.Theme and State.Theme.Name or "Midnight",
        background = type(State.Background) == "table" and (State.Background.Type or "none") or State.Background,
        settings = {
            WindowOpacity = State.Settings.WindowOpacity,
            BackgroundEffects = State.Settings.BackgroundEffects,
            BorderComet = State.Settings.BorderComet,
            ToggleStyle = State.Settings.ToggleStyle,
            RailPinned = State.RailPinned,
            NoAnim = State.NoAnim,
        },
        controls = {},
    }

    local function storeControl(ctrl, path)
        if not ctrl or not ctrl.GetValue then return end
        if ctrl.Kind ~= "Toggle" and ctrl.Kind ~= "Slider"
           and ctrl.Kind ~= "RangeSlider" and ctrl.Kind ~= "Dropdown"
           and ctrl.Kind ~= "Radio" then return end
        local key = ctrl.ConfigKey or path
        local ok, a, b = pcall(function() return ctrl:GetValue() end)
        if ok then
            if ctrl.Kind == "RangeSlider" then
                data.controls[key] = {a, b}
            else
                data.controls[key] = a
            end
        end
    end

    for ti, tab in ipairs(State.Tabs) do
        for ri, row in ipairs(tab.Rows or {}) do
            if IsSection(row) then
                for ci, child in ipairs(row.Rows or {}) do
                    if getmetatable(child) == InlineRow then
                        for ii, ctrl in ipairs(child.Cells or {}) do
                            storeControl(ctrl, tostring(tab.Name).."/"..tostring(row.Title).."/"..tostring(ctrl.Title).."/"..ii)
                        end
                    else
                        storeControl(child, tostring(tab.Name).."/"..tostring(row.Title).."/"..tostring(child.Title).."/"..ci)
                    end
                end
            else
                storeControl(row, tostring(tab.Name).."/"..tostring(row.Title).."/"..ri)
            end
        end
    end

    if not writefile then return false, "writefile unavailable" end
    local ok, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    if not ok then return false, encoded end
    local path = "DrawingUI_" .. name .. ".json"
    local wrote, err = pcall(function() writefile(path, encoded) end)
    return wrote, wrote and path or err
end

function Library:LoadConfig(name)
    name = string.gsub(tostring(name or "default"), "[^%w_%-]", "_")
    if name == "" then name = "default" end
    local path = "DrawingUI_" .. name .. ".json"
    if not readfile then return false, "readfile unavailable" end
    if isfile then
        local okExists, exists = pcall(function() return isfile(path) end)
        if okExists and not exists then return false, "config not found" end
    end
    local okRead, raw = pcall(function() return readfile(path) end)
    if not okRead then return false, raw end
    local okDecode, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(raw)
    end)
    if not okDecode or type(data) ~= "table" then return false, data end

    if data.theme then SetThemeByName(data.theme) end
    if data.background then State.Background = NormalizeBackground(data.background) end
    local st = data.settings or {}
    if st.WindowOpacity ~= nil then
        State.Settings.WindowOpacity = st.WindowOpacity
        GlassSurfaceAlpha = math.max(0.20, math.min(1, st.WindowOpacity / 100))
    end
    if st.BackgroundEffects ~= nil then State.Settings.BackgroundEffects = st.BackgroundEffects end
    if st.BorderComet ~= nil then State.Settings.BorderComet = st.BorderComet end
    if st.ToggleStyle ~= nil then State.Settings.ToggleStyle = st.ToggleStyle end
    if st.RailPinned ~= nil then State.RailPinned = st.RailPinned end
    if st.NoAnim ~= nil then State.NoAnim = st.NoAnim end

    local values = data.controls or {}
    local function loadControl(ctrl, pathKey)
        if not ctrl or not ctrl.SetValue then return end
        local key = ctrl.ConfigKey or pathKey
        local value = values[key]
        if value == nil then return end
        if ctrl.Kind == "RangeSlider" and type(value) == "table" then
            ctrl:SetValue(value[1], value[2])
        else
            ctrl:SetValue(value)
        end
    end

    for _, tab in ipairs(State.Tabs) do
        for ri, row in ipairs(tab.Rows or {}) do
            if IsSection(row) then
                for ci, child in ipairs(row.Rows or {}) do
                    if getmetatable(child) == InlineRow then
                        for ii, ctrl in ipairs(child.Cells or {}) do
                            loadControl(ctrl, tostring(tab.Name).."/"..tostring(row.Title).."/"..tostring(ctrl.Title).."/"..ii)
                        end
                    else
                        loadControl(child, tostring(tab.Name).."/"..tostring(row.Title).."/"..tostring(child.Title).."/"..ci)
                    end
                end
            else
                loadControl(row, tostring(tab.Name).."/"..tostring(row.Title).."/"..ri)
            end
        end
    end
    return true, path
end

function Library:DeleteConfig(name)
    name = string.gsub(tostring(name or ""), "[^%w_%-]", "_")
    if name == "" then return false, "invalid config name" end

    local path = "DrawingUI_" .. name .. ".json"
    if type(delfile) ~= "function" then return false, "delfile unavailable" end

    if type(isfile) == "function" then
        local okExists, exists = pcall(isfile, path)
        if okExists and not exists then return false, "config not found" end
    end

    local ok, err = pcall(delfile, path)
    return ok, ok and path or err
end

-- notifications -------------------------------------------------------------
function Library:Notify(opts)
    return Notify(opts)
end

-- theme ---------------------------------------------------------------------
function Library:SetTheme(name)
    return SetThemeByName(name)
end

function Library:NextTheme()
    NextTheme()
end

function Library:SetBackground(effect)
    State.Background = NormalizeBackground(effect)
end

-- Dynamic island -------------------------------------------------------------
-- Up to six actions are supported: three on each side of the fixed title.
-- opts: Id, Icon, Side ("left"/"right"), GetActive, Active, Callback.
function Library:AddIslandAction(opts)
    opts = opts or {}
    if #State.Island.Actions >= State.Island.MaxActions then
        return nil
    end

    local side = string.lower(tostring(opts.Side or opts.side or "right"))
    if side ~= "left" and side ~= "right" then side = "right" end

    local sideCount = 0
    for _, action in ipairs(State.Island.Actions) do
        if action.Side == side then sideCount = sideCount + 1 end
    end
    if sideCount >= 3 then return nil end

    local action = {
        Id = tostring(opts.Id or opts.id or ("island_" .. tostring(#State.Island.Actions + 1))),
        Icon = tostring(opts.Icon or opts.icon or "sparkles"),
        Side = side,
        Active = opts.Active ~= nil and opts.Active or opts.active,
        GetActive = opts.GetActive or opts.getActive,
        Callback = opts.Callback or opts.callback,
    }

    table.insert(State.Island.Actions, action)
    return action
end

function Library:RemoveIslandAction(id)
    id = tostring(id)
    for i = #State.Island.Actions, 1, -1 do
        if State.Island.Actions[i].Id == id then
            table.remove(State.Island.Actions, i)
            return true
        end
    end
    return false
end

function Library:ClearIslandActions()
    State.Island.Actions = {}
    State.Island.Open = false
end

function Library:SetIslandOpen(open)
    if #State.Island.Actions == 0 then
        State.Island.Open = false
    else
        State.Island.Open = open == true
    end
end

function Library:ToggleIsland()
    if #State.Island.Actions > 0 then
        State.Island.Open = not State.Island.Open
    end
end

function Library:OpenKeybinds()
    State.Settings.KeybindOverlay = true
end

function Library:CloseKeybinds()
    State.Settings.KeybindOverlay = false
end

function Library:OpenPerformance()
    State.Settings.PerformanceOverlay = true
end

function Library:ClosePerformance()
    State.Settings.PerformanceOverlay = false
end

-- hotkey --------------------------------------------------------------------
function Library:SetKeybind(key)
    State.MenuKey = string.lower(tostring(key))
end

-- lifecycle ----------------------------------------------------------------
function Library:Toggle()   ToggleUI() end
function Library:Show()     State.Open = true end
function Library:Hide()     State.Open = false; ClearFocus(); self:_SyncGameInput(true) end
function Library:StartStartup(opts) StartStartup(opts) end

function Library:IsAlive() return State.Alive end

function Library:Destroy()
    State.Alive = false
    ClearFocus()
    State.InputSent = true
    if type(setrobloxinput) == "function" then pcall(setrobloxinput, true) end
    ClearPool()
    CancelCapture()
end

-- HUD boxes ----------------------------------------------------------------
function Library:CreateOverlay(opts)
    return HUDBox.new(opts)
end

-- Backwards-compatible name kept for scripts already using CreateBox.
function Library:CreateBox(opts)
    return HUDBox.new(opts)
end

Library.IsBindHeld    = IsBindHeld
Library.IsBindClicked = IsBindClicked


do
    local function AttachControl(parentType, methodName, ctorName)
        local ctor = Controls[ctorName]
        if not ctor then return end
        parentType[methodName] = function(self, opts)
            local obj = ctor(self, opts)
            return obj
        end
    end

    for _, parentType in ipairs({ Tab, Section }) do
        AttachControl(parentType, "AddLabel",       "Label")
        AttachControl(parentType, "AddDivider",     "Divider")
        AttachControl(parentType, "AddButton",      "Button")
        AttachControl(parentType, "AddToggle",      "Toggle")
        AttachControl(parentType, "AddRadio",       "Radio")
        AttachControl(parentType, "AddSlider",      "Slider")
        AttachControl(parentType, "AddRangeSlider", "RangeSlider")
        AttachControl(parentType, "AddDropdown",    "Dropdown")
        AttachControl(parentType, "AddKeybind",     "Keybind")
        AttachControl(parentType, "AddColorPicker", "ColorPicker")
    end


    function Tab:AddSection(title, description, opts)
        return Section.new(self, title, description, opts)
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
        "Label", "Divider", "Toggle", "Radio", "Slider", "RangeSlider",
        "Dropdown", "Keybind", "Textbox", "ColorPicker", "Button"
    }) do
        AttachControl(InlineRow, "Add" .. ctrlName, ctrlName)
    end

    -- [FIX] allow chaining control creation: `row:AddToggle({}):AddToggle({})`
    for _, ctrlName in ipairs({
        "Label", "Divider", "Toggle", "Radio", "Slider", "RangeSlider",
        "Dropdown", "Keybind", "Textbox", "ColorPicker", "Button"
    }) do
        local ctor = Controls[ctrlName]
        if ctor then
            Base["Add" .. ctrlName] = function(self, opts)
                local obj = ctor(self.Parent, opts)
                return obj
            end
        end
    end
end

do
    local vp = Camera.ViewportSize
    State.X = math.floor((vp.X - State.W) / 2)
    State.Y = math.floor((vp.Y - State.H) / 2)
end

-- Default dynamic-island actions. They use the same overlay booleans as the
-- rest of the library, so the island is the primary control with no duplicate
-- settings state.
Library:AddIslandAction({
    Id = "hotkeys",
    Icon = "keyboard",
    Side = "left",
    GetActive = function()
        return State.Settings.KeybindOverlay
    end,
    Callback = function()
        State.Settings.KeybindOverlay = not State.Settings.KeybindOverlay
    end,
})

Library:AddIslandAction({
    Id = "performance",
    Icon = "performance",
    Side = "right",
    GetActive = function()
        return State.Settings.PerformanceOverlay
    end,
    Callback = function()
        State.Settings.PerformanceOverlay = not State.Settings.PerformanceOverlay
    end,
})

task.spawn(function()
    while State.Alive do
        local ok, err = pcall(Render)
        if not ok then
            warn("[Library] render error:", tostring(err))
        end
        task.wait()
    end
end)



Library.Version = "1.2.2"

-- Public exports.
-- The returned Library table is the preferred API. UI and DrawingUI are also
-- exposed for environments that load scripts without capturing the return value.
UI = Library
DrawingUI = Library

if type(getgenv) == "function" then
    local env = getgenv()
    env.UI = Library
    env.DrawingUI = Library
end

if type(shared) == "table" then
    shared.UI = Library
    shared.DrawingUI = Library
end

return Library