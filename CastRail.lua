-- Cast Rail: restyles the game's own cast bars (player, target, focus).
--
--  * Two skins. Modern: flat bar, thin black edge, icon on the left, time on the
--    right (the mUI look). Classic: keeps the game's frame and text, so it fits the
--    default UI; only the fill changes.
--  * Both skins take the color sets (same as XP Rail / Cooldown Skin) and a bar
--    texture: the game's own, five of ours, or any LibSharedMedia one installed.
--  * The bars stay the game's: the client still runs the cast and its timing, and
--    Edit Mode still places the player bar. We only dress them after each update.

local ADDON = ...
local db   -- CastRailDB, set on ADDON_LOADED; declared first so every function below sees it

-- Locale ------------------------------------------------------------------

local L = {
    title = "Cast Rail",
    sub = "Changes apply at once. Drag to move, Esc to close.",
    secSkin = "Skin", secLayout = "Layout", secBars = "Bars", secTexture = "Texture", secColors = "Colors",
    skin = "Skin", modern = "Modern", classic = "Classic",
    width = "Width", height = "Height", border = "Border", textSize = "Text size",
    icon = "Show the spell icon", timer = "Cast time", inside = "Inside", outside = "Outside", off = "Off",
    target = "Style the target's cast bar", focus = "Style the focus cast bar",
    more = "More", bright = "Brightness", reset = "Reset to defaults",
    reloadNote = "Going back to the classic skin is cleanest after /reload.",
    openBtn = "Open Cast Rail", openNote = "The options open in their own window (also with /castrail).",
    cls = "Class color", default = "Game colors", famGame = "Game", famClassic = "Classic", famQuality = "Quality",
    castBar = "Cast bar", rested = "Rested",
    texFlat = "Flat", texBlizz = "Game", texRaid = "Raid", texSmooth = "Smooth", texGloss = "Gloss",
    texRounded = "Rounded", texStripes = "Stripes", texMatte = "Matte",
    preview = "Shadow Bolt",
    shadowShow = "Soft shadow around the bar", sparkShow = "Spark at the fill's end",
    nameShow = "Show the spell name",
    secFont = "Font", font = "Font", outline = "Edge", shadow = "Shadow", thin = "Outline", thick = "Thick",
}
if GetLocale() == "deDE" then
    L.sub = "Änderungen wirken sofort. Ziehen zum Verschieben, Esc zum Schließen."
    L.secSkin, L.secLayout, L.secBars, L.secTexture, L.secColors = "Stil", "Aufbau", "Leisten", "Textur", "Farben"
    L.skin, L.modern, L.classic = "Stil", "Modern", "Klassisch"
    L.width, L.height, L.border, L.textSize = "Breite", "Höhe", "Rahmen", "Textgröße"
    L.icon, L.timer = "Zaubersymbol anzeigen", "Zauberzeit"
    L.inside, L.outside, L.off = "Innen", "Außen", "Aus"
    L.target, L.focus = "Zauberleiste des Ziels gestalten", "Zauberleiste des Fokus gestalten"
    L.more, L.bright, L.reset = "Weitere", "Helligkeit", "Auf Standard zurücksetzen"
    L.reloadNote = "Zurück zum klassischen Stil am saubersten nach /reload."
    L.openBtn, L.openNote = "Cast Rail öffnen", "Die Optionen öffnen sich in einem eigenen Fenster (auch mit /castrail)."
    L.cls, L.default, L.famGame = "Klassenfarbe", "Spielfarben", "Spiel"
    L.famClassic, L.famQuality, L.castBar, L.rested = "Klassisch", "Qualität", "Zauberleiste", "Erholt"
    L.texFlat, L.texBlizz, L.texRaid, L.texSmooth = "Flach", "Spiel", "Schlachtzug", "Weich"
    L.texGloss, L.texRounded, L.texStripes, L.texMatte = "Glanz", "Rund", "Streifen", "Matt"
    L.preview = "Schattenblitz"
    L.secFont, L.font, L.outline = "Schrift", "Schrift", "Rand"
    L.shadow, L.thin, L.thick = "Schatten", "Kontur", "Dick"
    L.shadowShow, L.sparkShow = "Weicher Schatten um die Leiste", "Funke am Ende der Füllung"
    L.nameShow = "Zaubername anzeigen"
end

-- Settings ----------------------------------------------------------------

local SQUARE = "Interface\\Buttons\\WHITE8X8"
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Textures\\"

local DEFAULTS = {
    skin = "modern",         -- "modern" or "classic"
    width = 230,             -- player bar, modern skin (target/focus are scaled from it)
    height = 18,
    border = 1,
    shadow = true,           -- soft dark glow outside the border (modern skin)
    spark = true,            -- faint glow at the fill's end (modern skin)
    name = true,             -- the spell name on the bar (both skins)
    icon = true,
    timer = "outside",       -- "outside", "inside" or "off"
    textSize = 12,
    target = true,
    focus = true,
    texture = "Smooth",      -- a TEXTURES key, or "lsm:<name>"
    color = "default",       -- a PALETTES key, "class" or "default"
    bright = 1,
    font = "arialn",         -- a FONTS key, or "lsm:<name>"
    outline = "outline",     -- "shadow", "outline" or "thick"
}

-- The game's own fonts; every client has them (German ones too).
local FONTS = {
    { key = "arialn",   path = "Fonts\\ARIALN.TTF",   name = "Arial Narrow" },
    { key = "friz",     path = "Fonts\\FRIZQT__.TTF", name = "Friz Quadrata" },
    { key = "morpheus", path = "Fonts\\MORPHEUS.TTF", name = "Morpheus" },
    { key = "skurri",   path = "Fonts\\SKURRI.TTF",   name = "Skurri" },
}

-- Bar textures we may ship: the game's own and ours (Textures\, made for this addon).
local TEXTURES = {
    { key = "Flat",    path = SQUARE,                                       name = L.texFlat },
    { key = "Blizzard", path = "Interface\\TargetingFrame\\UI-StatusBar",   name = L.texBlizz },
    { key = "Raid",    path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",     name = L.texRaid },
    { key = "Smooth",  path = MEDIA .. "Smooth",  name = L.texSmooth },
    { key = "Gloss",   path = MEDIA .. "Gloss",   name = L.texGloss },
    { key = "Rounded", path = MEDIA .. "Rounded", name = L.texRounded },
    { key = "Stripes", path = MEDIA .. "Stripes", name = L.texStripes },
    { key = "Matte",   path = MEDIA .. "Matte",   name = L.texMatte },
}
local TEX_BY_KEY = {}
for _, t in ipairs(TEXTURES) do TEX_BY_KEY[t.key] = t end

local function LSM() return LibStub and LibStub("LibSharedMedia-3.0", true) end

local function texturePath(key)
    if type(key) == "string" and key:sub(1, 4) == "lsm:" then
        local lib = LSM()
        local ok, p = lib and pcall(lib.Fetch, lib, "statusbar", key:sub(5), true)
        if ok and p then return p end
        key = DEFAULTS.texture
    end
    return (TEX_BY_KEY[key] or TEX_BY_KEY[DEFAULTS.texture]).path
end

-- Every font to cycle through: the game's, then LibSharedMedia's ("lsm:<name>").
local function fontKeys()
    local keys = {}
    for _, f in ipairs(FONTS) do keys[#keys + 1] = f.key end
    local lib = LSM()
    if lib then
        for _, n in ipairs(lib:List("font") or {}) do keys[#keys + 1] = "lsm:" .. n end
    end
    return keys
end

local function fontInfo(key)
    if type(key) == "string" and key:sub(1, 4) == "lsm:" then
        local lib = LSM()
        local ok, p = lib and pcall(lib.Fetch, lib, "font", key:sub(5), true)
        if ok and p then return p, key:sub(5) end
        key = DEFAULTS.font
    end
    for _, f in ipairs(FONTS) do
        if f.key == key then return f.path, f.name end
    end
    return STANDARD_TEXT_FONT, "Standard"
end

-- Font, size and edge on a font string: a soft shadow, a thin or a thick outline.
local function applyFont(fs, size)
    local flags = (db.outline == "thick" and "THICKOUTLINE") or (db.outline == "outline" and "OUTLINE") or ""
    if not pcall(fs.SetFont, fs, (fontInfo(db.font)), size, flags) then
        pcall(fs.SetFont, fs, STANDARD_TEXT_FONT, size, flags)
    end
    if db.outline == "shadow" then
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
    else
        fs:SetShadowOffset(0, 0)
    end
end

local function textureName(key)
    if type(key) == "string" and key:sub(1, 4) == "lsm:" then return key:sub(5) end
    return TEX_BY_KEY[key] and TEX_BY_KEY[key].name or key
end

-- Gradient pairs, start to end of the fill (same sets as XP Rail / Cooldown Skin).
local PALETTES = {
    neon   = { { 0.00, 1.00, 1.00 }, { 1.00, 0.00, 1.00 } },
    toxic  = { { 0.60, 1.00, 0.00 }, { 0.00, 1.00, 0.60 } },
    sunset = { { 1.00, 0.45, 0.00 }, { 1.00, 0.00, 0.55 } },
    void   = { { 0.65, 0.00, 1.00 }, { 0.00, 0.55, 1.00 } },
    fel    = { { 0.15, 1.00, 0.10 }, { 0.85, 1.00, 0.00 } },
    ice    = { { 0.70, 0.95, 1.00 }, { 0.15, 0.40, 1.00 } },
    ctp_mauve = { { 0.80, 0.65, 0.97 }, { 0.96, 0.76, 0.91 } },
    ctp_peach = { { 0.98, 0.70, 0.53 }, { 0.95, 0.55, 0.66 } },
    ctp_teal  = { { 0.58, 0.89, 0.84 }, { 0.54, 0.86, 0.92 } },
    ctp_blue  = { { 0.54, 0.71, 0.98 }, { 0.71, 0.75, 1.00 } },
    ctp_green = { { 0.65, 0.89, 0.63 }, { 0.98, 0.89, 0.69 } },
    ctp_rose  = { { 0.95, 0.80, 0.80 }, { 0.92, 0.63, 0.67 } },
    cyber_yellow = { { 0.99, 0.93, 0.04 }, { 0.02, 0.85, 0.91 } },
    cyber_pink   = { { 1.00, 0.16, 0.43 }, { 0.48, 0.02, 0.92 } },
    cyber_cyan   = { { 0.02, 0.85, 0.91 }, { 0.18, 0.42, 1.00 } },
    cyber_red    = { { 1.00, 0.00, 0.24 }, { 1.00, 0.00, 0.63 } },
    cyber_acid   = { { 0.22, 1.00, 0.08 }, { 0.00, 0.94, 1.00 } },
    cyber_purple = { { 0.69, 0.15, 1.00 }, { 1.00, 0.16, 0.43 } },
    drac_purple = { { 0.74, 0.58, 0.98 }, { 1.00, 0.47, 0.78 } },
    drac_cyan   = { { 0.55, 0.91, 0.99 }, { 0.74, 0.58, 0.98 } },
    drac_green  = { { 0.31, 0.98, 0.48 }, { 0.55, 0.91, 0.99 } },
    drac_orange = { { 1.00, 0.72, 0.42 }, { 1.00, 0.33, 0.33 } },
    drac_pink   = { { 1.00, 0.47, 0.78 }, { 1.00, 0.33, 0.33 } },
    drac_yellow = { { 0.95, 0.98, 0.55 }, { 0.31, 0.98, 0.48 } },
    cl_health  = { { 0.00, 0.60, 0.00 }, { 0.00, 1.00, 0.00 } },
    cl_mana    = { { 0.00, 0.18, 0.70 }, { 0.10, 0.40, 1.00 } },
    cl_rage    = { { 0.60, 0.00, 0.00 }, { 1.00, 0.00, 0.00 } },
    cl_energy  = { { 0.75, 0.65, 0.00 }, { 1.00, 1.00, 0.00 } },
    cl_cast    = { { 0.80, 0.55, 0.00 }, { 1.00, 0.70, 0.00 } },
    cl_rested  = { { 0.00, 0.25, 0.60 }, { 0.00, 0.39, 0.88 } },
    q_uncommon  = { { 0.08, 0.65, 0.00 }, { 0.12, 1.00, 0.00 } },
    q_rare      = { { 0.00, 0.29, 0.58 }, { 0.00, 0.44, 0.87 } },
    q_epic      = { { 0.42, 0.14, 0.62 }, { 0.64, 0.21, 0.93 } },
    q_legendary = { { 0.70, 0.33, 0.00 }, { 1.00, 0.50, 0.00 } },
    q_artifact  = { { 0.58, 0.52, 0.33 }, { 0.90, 0.80, 0.50 } },
    q_heirloom  = { { 0.00, 0.52, 0.65 }, { 0.00, 0.80, 1.00 } },
    gruv_red    = { { 0.98, 0.29, 0.20 }, { 1.00, 0.50, 0.10 } },
    gruv_orange = { { 1.00, 0.50, 0.10 }, { 0.98, 0.74, 0.18 } },
    gruv_yellow = { { 0.98, 0.74, 0.18 }, { 0.72, 0.73, 0.15 } },
    gruv_green  = { { 0.72, 0.73, 0.15 }, { 0.56, 0.75, 0.49 } },
    gruv_aqua   = { { 0.56, 0.75, 0.49 }, { 0.51, 0.65, 0.60 } },
    gruv_blue   = { { 0.51, 0.65, 0.60 }, { 0.83, 0.53, 0.61 } },
    rose_love = { { 0.92, 0.44, 0.57 }, { 0.92, 0.74, 0.73 } },
    rose_gold = { { 0.96, 0.76, 0.47 }, { 0.92, 0.44, 0.57 } },
    rose_rose = { { 0.92, 0.74, 0.73 }, { 0.77, 0.65, 0.91 } },
    rose_iris = { { 0.77, 0.65, 0.91 }, { 0.61, 0.81, 0.85 } },
    rose_foam = { { 0.61, 0.81, 0.85 }, { 0.19, 0.45, 0.56 } },
    rose_pine = { { 0.19, 0.45, 0.56 }, { 0.77, 0.65, 0.91 } },
    kana_violet = { { 0.58, 0.50, 0.72 }, { 0.82, 0.49, 0.60 } },
    kana_blue   = { { 0.49, 0.61, 0.85 }, { 0.50, 0.71, 0.79 } },
    kana_green  = { { 0.60, 0.73, 0.42 }, { 0.48, 0.66, 0.62 } },
    kana_yellow = { { 0.90, 0.76, 0.52 }, { 1.00, 0.63, 0.40 } },
    kana_red    = { { 0.89, 0.41, 0.46 }, { 1.00, 0.63, 0.40 } },
    kana_spring = { { 0.50, 0.71, 0.79 }, { 0.58, 0.50, 0.72 } },
    one_purple = { { 0.78, 0.47, 0.87 }, { 0.38, 0.69, 0.94 } },
    one_blue   = { { 0.38, 0.69, 0.94 }, { 0.34, 0.71, 0.76 } },
    one_cyan   = { { 0.34, 0.71, 0.76 }, { 0.60, 0.76, 0.47 } },
    one_green  = { { 0.60, 0.76, 0.47 }, { 0.90, 0.75, 0.48 } },
    one_yellow = { { 0.90, 0.75, 0.48 }, { 0.82, 0.60, 0.40 } },
    one_orange = { { 0.82, 0.60, 0.40 }, { 0.91, 0.40, 0.44 } },
    tokyo_blue   = { { 0.48, 0.64, 0.97 }, { 0.73, 0.60, 0.97 } },
    tokyo_cyan   = { { 0.49, 0.81, 1.00 }, { 0.48, 0.64, 0.97 } },
    tokyo_green  = { { 0.62, 0.81, 0.42 }, { 0.10, 0.74, 0.61 } },
    tokyo_yellow = { { 0.88, 0.69, 0.41 }, { 1.00, 0.62, 0.39 } },
    tokyo_orange = { { 1.00, 0.62, 0.39 }, { 0.97, 0.46, 0.56 } },
    tokyo_purple = { { 0.62, 0.49, 0.85 }, { 0.97, 0.46, 0.56 } },
}
local PALETTE_ROWS = {
    { name = L.famGame,    list = { "default", "class" } },
    { name = L.famClassic, list = { "cl_health", "cl_mana", "cl_rage", "cl_energy", "cl_cast", "cl_rested" } },
    { name = L.famQuality, list = { "q_uncommon", "q_rare", "q_epic", "q_legendary", "q_artifact", "q_heirloom" } },
    { name = "Neon",       list = { "neon", "toxic", "sunset", "void", "fel", "ice" } },
    { name = "Cyberpunk",  list = { "cyber_yellow", "cyber_pink", "cyber_cyan", "cyber_red", "cyber_acid", "cyber_purple" } },
    { name = "Dracula",    list = { "drac_purple", "drac_cyan", "drac_green", "drac_orange", "drac_pink", "drac_yellow" } },
    { name = "Gruvbox",    list = { "gruv_red", "gruv_orange", "gruv_yellow", "gruv_green", "gruv_aqua", "gruv_blue" } },
    { name = "Catppuccin", list = { "ctp_mauve", "ctp_peach", "ctp_teal", "ctp_blue", "ctp_green", "ctp_rose" } },
    { name = "Rosé Pine",  list = { "rose_love", "rose_gold", "rose_rose", "rose_iris", "rose_foam", "rose_pine" } },
    { name = "Kanagawa",   list = { "kana_violet", "kana_blue", "kana_green", "kana_yellow", "kana_red", "kana_spring" } },
    { name = "OneDark",    list = { "one_purple", "one_blue", "one_cyan", "one_green", "one_yellow", "one_orange" } },
    { name = "Tokyo Night", list = { "tokyo_blue", "tokyo_cyan", "tokyo_green", "tokyo_yellow", "tokyo_orange", "tokyo_purple" } },
}
local COLOR_NAMES = { default = L.default, class = L.cls,
    neon = "Neon", toxic = "Toxic", sunset = "Sunset", void = "Void", fel = "Fel", ice = "Ice",
    ctp_mauve = "Catppuccin Mauve", ctp_peach = "Catppuccin Peach", ctp_teal = "Catppuccin Teal",
    ctp_blue = "Catppuccin Blue", ctp_green = "Catppuccin Green", ctp_rose = "Catppuccin Rose",
    cyber_yellow = "Cyberpunk Yellow", cyber_pink = "Cyberpunk Pink", cyber_cyan = "Cyberpunk Cyan",
    cyber_red = "Cyberpunk Red", cyber_acid = "Cyberpunk Acid", cyber_purple = "Cyberpunk Purple",
    drac_purple = "Dracula Purple", drac_cyan = "Dracula Cyan", drac_green = "Dracula Green",
    drac_orange = "Dracula Orange", drac_pink = "Dracula Pink", drac_yellow = "Dracula Yellow",
    gruv_red = "Gruvbox Red", gruv_orange = "Gruvbox Orange", gruv_yellow = "Gruvbox Yellow",
    gruv_green = "Gruvbox Green", gruv_aqua = "Gruvbox Aqua", gruv_blue = "Gruvbox Blue",
    rose_love = "Rosé Pine Love", rose_gold = "Rosé Pine Gold", rose_rose = "Rosé Pine Rose",
    rose_iris = "Rosé Pine Iris", rose_foam = "Rosé Pine Foam", rose_pine = "Rosé Pine Pine",
    kana_violet = "Kanagawa Violet", kana_blue = "Kanagawa Blue", kana_green = "Kanagawa Green",
    kana_yellow = "Kanagawa Yellow", kana_red = "Kanagawa Red", kana_spring = "Kanagawa Spring",
    one_purple = "OneDark Purple", one_blue = "OneDark Blue", one_cyan = "OneDark Cyan",
    one_green = "OneDark Green", one_yellow = "OneDark Yellow", one_orange = "OneDark Orange",
    tokyo_blue = "Tokyo Night Blue", tokyo_cyan = "Tokyo Night Cyan", tokyo_green = "Tokyo Night Green",
    tokyo_yellow = "Tokyo Night Yellow", tokyo_orange = "Tokyo Night Orange", tokyo_purple = "Tokyo Night Purple",
    cl_health = HEALTH or "Health", cl_mana = MANA or "Mana", cl_rage = RAGE or "Rage",
    cl_energy = ENERGY or "Energy", cl_cast = L.castBar, cl_rested = L.rested,
    q_uncommon = ITEM_QUALITY2_DESC or "Uncommon", q_rare = ITEM_QUALITY3_DESC or "Rare",
    q_epic = ITEM_QUALITY4_DESC or "Epic", q_legendary = ITEM_QUALITY5_DESC or "Legendary",
    q_artifact = ITEM_QUALITY6_DESC or "Artifact", q_heirloom = ITEM_QUALITY7_DESC or "Heirloom" }

-- The game's own cast colors, one pair per bar state (used by "Game colors").
local GAME_STATE = {
    standard        = { { 0.80, 0.55, 0.00 }, { 1.00, 0.70, 0.00 } },   -- cast: gold
    channel         = { { 0.00, 0.55, 0.00 }, { 0.10, 1.00, 0.10 } },   -- channel: green
    uninterruptable = { { 0.40, 0.40, 0.42 }, { 0.70, 0.70, 0.72 } },   -- can't be kicked: grey
    interrupted     = { { 0.60, 0.00, 0.00 }, { 1.00, 0.10, 0.10 } },   -- interrupted: red
}

local function say(msg) print("|cffcca3ffCast Rail:|r " .. msg) end

-- Colors ------------------------------------------------------------------

-- Secret values (the client hides some unit data from addons) can't be compared.
local function plainString(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return type(v) == "string" and v or nil
end

-- What state a bar is in: "standard", "channel", "uninterruptable" or "interrupted".
local function stateOf(frame)
    local t = plainString(frame and frame.barType)
    if t == "empowered" then return "standard" end
    if t and GAME_STATE[t] then return t end
    return "standard"
end

-- The chosen set's base pair, before the bar's state is applied.
local function basePair()
    local p = PALETTES[db.color]
    if p then return p[1], p[2] end
    if db.color == "class" then
        local _, class = UnitClass("player")
        local cc = class and ((C_ClassColor and C_ClassColor.GetClassColor(class)) or RAID_CLASS_COLORS[class])
        if cc then
            return { cc.r * 0.6, cc.g * 0.6, cc.b * 0.6 },
                   { math.min(1, cc.r * 1.2), math.min(1, cc.g * 1.2), math.min(1, cc.b * 1.2) }
        end
    end
    return GAME_STATE.standard[1], GAME_STATE.standard[2]
end

-- How a color set shows the bar's states. a, b = the set's pair (start, end of the
-- fill); state = "standard", "channel", "uninterruptable" or "interrupted".
-- Returns the pair to draw. ("Game colors" never come here: they use GAME_STATE.)
-- Casts and channels keep the set; the warnings use the game's fixed red and grey,
-- so they read the same in every theme.
local function stateColors(state, a, b)
    if state == "interrupted" or state == "uninterruptable" then
        return GAME_STATE[state][1], GAME_STATE[state][2]
    end
    return a, b
end

local function colorsFor(state)
    local a, b
    if db.color == "default" then
        a, b = GAME_STATE[state][1], GAME_STATE[state][2]
    else
        a, b = stateColors(state, basePair())
    end
    local k = db.bright or 1
    return { a[1] * k, a[2] * k, a[3] * k }, { b[1] * k, b[2] * k, b[3] * k }
end

local function gradient(tex, a, b)
    if CreateColor and tex.SetGradient then
        local ok = pcall(tex.SetGradient, tex, "HORIZONTAL", CreateColor(a[1], a[2], a[3], 1), CreateColor(b[1], b[2], b[3], 1))
        if ok then return end
    end
    tex:SetVertexColor((a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2, 1)
end

-- The bars ----------------------------------------------------------------

local BARS = {
    { name = "PlayerCastingBarFrame",        kind = "player" },
    { name = "OverlayPlayerCastingBarFrame", kind = "player" },   -- the talent-switch cast
    { name = "TargetFrameSpellBar",          kind = "target" },
    { name = "FocusFrameSpellBar",           kind = "focus" },
}

-- The game's art we fade out for the modern skin. Faded with SetAlpha, not Hide,
-- so the game showing them again doesn't bring them back.
local ART = { "Border", "BorderShield", "TextBorder", "StandardGlow", "Flash", "Background",
    "BaseGlow", "Shine", "InterruptGlow", "ChargeFlash", "ChargeGlow", "EnergyGlow", "WispGlow",
    "Sparkles01", "Sparkles02", "CraftGlow", "ChannelShadow", "DropShadow" }

-- Our own pieces per bar, kept here and not on the game's frames (keeps them clean).
local own = setmetatable({}, { __mode = "k" })
local busy = false   -- set while we change a bar, so our own hooks don't loop

local function setArtAlpha(frame, alpha)
    for _, k in ipairs(ART) do
        local t = frame[k]
        if type(t) == "table" and t.SetAlpha then pcall(t.SetAlpha, t, alpha) end
    end
end

local SHADOW_STEPS, SHADOW_ALPHA = 4, 0.14   -- 4 px wide; ~45% dark by the edge

-- Shadow sheets 1..STEPS go around `bar`, the rest around `icon` (if shown).
-- `e` = border, so the shadow starts outside it.
local function placeShadow(p, bar, icon, e)
    for i, t in ipairs(p.shadow) do
        local target = i <= SHADOW_STEPS and bar or icon
        local o = e + ((i - 1) % SHADOW_STEPS) + 1
        t:ClearAllPoints()
        local on = db.shadow and target ~= nil and (target == bar or db.icon)
        t:SetShown(on and true or false)
        if on then
            t:SetPoint("TOPLEFT", target, "TOPLEFT", -o, o)
            t:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", o, -o)
        end
    end
end

local function piecesFor(frame)
    local p = own[frame]
    if p then return p end
    p = {}
    -- Shadow: faint black sheets, each a pixel bigger than the last, under everything.
    -- Where they overlap they add up, so it is darkest by the edge and fades outward.
    p.shadow = {}
    for i = 1, 2 * SHADOW_STEPS do
        p.shadow[i] = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        p.shadow[i]:SetColorTexture(0, 0, 0, SHADOW_ALPHA)
    end
    p.back = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    p.back:SetAllPoints()
    p.back:SetColorTexture(0.06, 0.06, 0.07, 0.85)
    p.edges = {}
    for i = 1, 4 do
        p.edges[i] = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
        p.edges[i]:SetColorTexture(0, 0, 0, 1)
    end
    p.iconEdge = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    p.iconEdge:SetColorTexture(0, 0, 0, 1)
    p.timer = frame:CreateFontString(nil, "OVERLAY")
    own[frame] = p
    return p
end

-- A ring `e` pixels thick just outside the frame.
local function placeEdges(p, frame, e)
    local t = p.edges
    for _, x in ipairs(t) do x:ClearAllPoints(); x:SetShown(e > 0) end
    if e <= 0 then return end
    t[1]:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -e, 0); t[1]:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", e, 0); t[1]:SetHeight(e)
    t[2]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -e, 0); t[2]:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", e, 0); t[2]:SetHeight(e)
    t[3]:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0); t[3]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0); t[3]:SetWidth(e)
    t[4]:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0); t[4]:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0); t[4]:SetWidth(e)
end

local function enabledFor(kind)
    return kind == "player" or db[kind]
end

-- Fill only: texture and colors. Both skins.
local function paintFill(frame)
    busy = true
    pcall(frame.SetStatusBarTexture, frame, texturePath(db.texture))
    local tex = frame:GetStatusBarTexture()
    if tex then
        local a, b = colorsFor(stateOf(frame))
        gradient(tex, a, b)
    end
    busy = false
end

-- The modern skin's layout: size, flat back and edge, icon, text, timer spot.
local function layoutModern(frame, kind, p)
    local small = kind ~= "player"
    local w = small and math.floor(db.width * 0.65 + 0.5) or db.width
    local h = small and math.max(8, db.height - 6) or db.height
    local e = db.border
    frame:SetSize(w, h)
    setArtAlpha(frame, 0)
    p.back:Show()
    placeEdges(p, frame, e)

    local icon = frame.Icon
    if icon then
        local size = h + 2 * e
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", frame, "LEFT", -(e + 3 + e), 0)
        icon:SetSize(size - 2 * e, size - 2 * e)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if db.icon then icon:Show() end
        icon:SetAlpha(db.icon and 1 or 0)
        p.iconEdge:ClearAllPoints()
        p.iconEdge:SetPoint("TOPLEFT", icon, "TOPLEFT", -e, e)
        p.iconEdge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", e, -e)
        p.iconEdge:SetShown(db.icon and e > 0)
    end
    placeShadow(p, frame, icon, e)

    -- Spark: the classic thin glow instead of the game's newer pip (a yellow block on
    -- channels). The game still moves it along the fill.
    local spark = frame.Spark
    if spark and spark.SetTexture then
        pcall(spark.SetTexture, spark, "Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        -- Kept faint and short: a hint of the fill's end, not a flare.
        spark:SetVertexColor(1, 1, 1, 1)
        spark:SetSize(math.max(4, h * 0.45), h * 1.6)
        spark:SetAlpha(db.spark and 0.6 or 0)
    end

    local size = small and math.max(8, db.textSize - 2) or db.textSize
    local text = frame.Text
    if text then
        text:ClearAllPoints()
        if db.timer == "inside" then
            text:SetPoint("LEFT", frame, "LEFT", 4, 0)
            text:SetPoint("RIGHT", frame, "RIGHT", -36, 0)
            text:SetJustifyH("LEFT")
        else
            text:SetPoint("LEFT", frame, "LEFT", 2, 0)
            text:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
            text:SetJustifyH("CENTER")
        end
        text:SetWordWrap(false)
        applyFont(text, size)
    end
    p.timer:ClearAllPoints()
    if db.timer == "inside" then
        p.timer:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    else
        p.timer:SetPoint("LEFT", frame, "RIGHT", e + 4, 0)
    end
    applyFont(p.timer, size + 2)
end

-- The classic skin: the game's frame and text spot stay; only the font changes.
local function layoutClassic(frame, kind, p)
    setArtAlpha(frame, 1)
    p.back:Hide()
    placeEdges(p, frame, 0)
    p.iconEdge:Hide()
    for _, t in ipairs(p.shadow) do t:Hide() end
    if frame.Spark then frame.Spark:SetAlpha(1) end   -- in case Modern had it off
    local size = kind ~= "player" and math.max(8, db.textSize - 2) or db.textSize
    if frame.Text then applyFont(frame.Text, size) end
    p.timer:ClearAllPoints()
    if db.timer == "inside" then
        p.timer:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    else
        p.timer:SetPoint("LEFT", frame, "RIGHT", 6, 0)
    end
    applyFont(p.timer, size + 1)
end

local function style(frame, kind)
    if not (db and frame and enabledFor(kind)) then return end
    local p = piecesFor(frame)
    busy = true
    if db.skin == "modern" then layoutModern(frame, kind, p) else layoutClassic(frame, kind, p) end
    busy = false
    p.timer:SetShown(db.timer ~= "off")
    -- Faded, not hidden, so the game showing it on the next cast doesn't undo it.
    if frame.Text then frame.Text:SetAlpha(db.name and 1 or 0) end
    paintFill(frame)
end

-- Time left, from the client's own duration object where it has one (safe with
-- hidden values), else from the cast's end time.
local function updateTimer(frame)
    local p = own[frame]
    if not (p and db and db.timer ~= "off") then return end
    local unit = frame.unit or "player"
    local ok = false
    if frame.casting or frame.channeling then
        local getter = frame.channeling and UnitChannelDuration or UnitCastingDuration
        if getter then
            ok = pcall(function()
                local d = getter(unit)
                p.timer:SetText(string.format("%.1f", d:GetRemainingDuration()))
            end)
        end
        if not ok then
            local info = frame.channeling and UnitChannelInfo or UnitCastingInfo
            ok = pcall(function()
                local endMS = select(5, info(unit))
                p.timer:SetText(string.format("%.1f", math.max(0, endMS / 1000 - GetTime())))
            end)
        end
    end
    if not ok then p.timer:SetText("") end
end

local hooked = {}
local function hookBar(frame, kind)
    if hooked[frame] then return end
    hooked[frame] = true
    -- After the game updates the bar (start, stop, interrupt, look change), dress it again.
    local function again() if not busy then style(frame, kind) end end
    frame:HookScript("OnEvent", function(self, event)
        again()
        -- On this client a channel's bar says "Channeling"; show the spell's name.
        if (event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE")
                and enabledFor(kind) and self.Text and UnitChannelInfo then
            pcall(function()
                local name = UnitChannelInfo(self.unit or "player")
                if name then self.Text:SetText(name) end
            end)
        end
    end)
    frame:HookScript("OnShow", again)
    if frame.SetLook then hooksecurefunc(frame, "SetLook", again) end
    -- The game swaps the fill on finish and interrupt; put ours back.
    hooksecurefunc(frame, "SetStatusBarTexture", function() if not busy and db and enabledFor(kind) then paintFill(frame) end end)
    hooksecurefunc(frame, "SetStatusBarColor", function() if not busy and db and enabledFor(kind) then paintFill(frame) end end)
    frame:HookScript("OnUpdate", updateTimer)
end

local function applyAll()
    for _, b in ipairs(BARS) do
        local f = _G[b.name]
        if f then
            hookBar(f, b.kind)
            style(f, b.kind)
        end
    end
end

-- Options -----------------------------------------------------------------
-- The same dark window as XP Rail and Cooldown Skin.

local UI_FILL = { 0.05, 0.05, 0.06 }
local UI_EDGE = { 0.30, 0.30, 0.33 }
local UI_ACCENT = { 0.80, 0.64, 1.00 }
local UI_W, UI_PAD = 340, 16
local UI_INNER = UI_W - 2 * UI_PAD

local function uiEdges(f, fill, alpha)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(fill[1], fill[2], fill[3], alpha or 1)
    for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
                         { "TOPLEFT", "BOTTOMLEFT", true }, { "TOPRIGHT", "BOTTOMRIGHT", true } }) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetPoint(e[1]); t:SetPoint(e[2])
        if e[3] then t:SetWidth(1) else t:SetHeight(1) end
        t:SetColorTexture(UI_EDGE[1], UI_EDGE[2], UI_EDGE[3], 1)
    end
end

local function uiButton(parent, label, w)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w or UI_INNER, 22)
    uiEdges(b, { 0.12, 0.12, 0.13 })
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3], 0.15)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.label:SetPoint("LEFT", 6, 0)
    b.label:SetPoint("RIGHT", -6, 0)
    b.label:SetWordWrap(false)
    b.label:SetJustifyH("CENTER")
    b.label:SetText(label)
    return b
end

local function px(v) return string.format("%d px", v) end
local function pct(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end

local function resetAll()
    CastRailDB = CopyTable(DEFAULTS)
    db = CastRailDB
    applyAll()
end

local panel
local function buildPanel()
    local f = CreateFrame("Frame", "CastRailOptions", UIParent)
    f:SetSize(UI_W * 2, 400)
    f:SetPoint("CENTER", 0, 60)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    uiEdges(f, UI_FILL, 0.95)

    local close = CreateFrame("Button", nil, f)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -8, -8)
    local x = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    x:SetPoint("CENTER")
    x:SetText("\195\151")
    x:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3])
    close:SetScript("OnEnter", function() x:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3]) end)
    close:SetScript("OnClick", function() f:Hide() end)

    local logo = f:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", UI_PAD, -UI_PAD)
    logo:SetTexture("Interface\\Icons\\Spell_Holy_HolyBolt")
    logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -1)
    title:SetText(L.title)
    title:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3])
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    sub:SetText(L.sub)

    local widgets = {}
    local function refreshWidgets() for _, w in ipairs(widgets) do w() end end
    f.Refresh = refreshWidgets
    local function changed() applyAll(); refreshWidgets() end

    local TOP = -(UI_PAD + 32 + 10)
    local cols = { { x = UI_PAD, y = TOP }, { x = UI_W + UI_PAD, y = TOP } }
    local col = cols[1]

    local div = f:CreateTexture(nil, "BORDER")
    div:SetWidth(1)
    div:SetColorTexture(UI_EDGE[1], UI_EDGE[2], UI_EDGE[3], 0.5)
    div:SetPoint("TOP", f, "TOPLEFT", UI_W, TOP - 4)
    div:SetPoint("BOTTOM", f, "BOTTOMLEFT", UI_W, UI_PAD + 30)

    local function head(label)
        col.y = col.y - 6
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", col.x, col.y)
        fs:SetText(label)
        local rule = f:CreateTexture(nil, "BORDER")
        rule:SetHeight(1)
        rule:SetColorTexture(UI_EDGE[1], UI_EDGE[2], UI_EDGE[3], 0.8)
        rule:SetPoint("LEFT", fs, "RIGHT", 8, 0)
        rule:SetPoint("RIGHT", f, "LEFT", col.x + UI_INNER, 0)
        col.y = col.y - 22
    end
    local function row(h)
        local r = CreateFrame("Frame", nil, f)
        r:SetSize(UI_INNER, h or 24)
        r:SetPoint("TOPLEFT", col.x, col.y)
        col.y = col.y - (h or 24) - 4
        return r
    end
    local function label(r, s)
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT")
        fs:SetText(s)
    end

    local function check(s, key, after)
        local r = row()
        local c = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
        c:SetSize(24, 24)
        c:SetPoint("LEFT", -3, 0)
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", c, "RIGHT", 4, 0)
        fs:SetPoint("RIGHT")
        fs:SetJustifyH("LEFT")
        fs:SetText(s)
        c:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and true or false
            if after then after() end
            changed()
        end)
        widgets[#widgets + 1] = function() c:SetChecked(db[key] and true or false) end
        return r
    end

    -- label ......... [-] value [+]   (shift-click: 5 steps)
    local function stepper(s, key, step, lo, hi, fmt)
        local r = row()
        label(r, s)
        local plus = uiButton(r, "+", 24)
        plus:SetPoint("RIGHT")
        local value = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        value:SetWidth(60)
        value:SetJustifyH("CENTER")
        value:SetPoint("RIGHT", plus, "LEFT", -4, 0)
        local minus = uiButton(r, "-", 24)
        minus:SetPoint("RIGHT", value, "LEFT", -4, 0)
        local function bump(d)
            if IsShiftKeyDown() then d = d * 5 end
            local v = math.floor((db[key] + d) / step + 0.5) * step
            db[key] = tonumber(string.format("%.2f", math.max(lo, math.min(hi, v))))
            changed()
        end
        minus:SetScript("OnClick", function() bump(-step) end)
        plus:SetScript("OnClick", function() bump(step) end)
        widgets[#widgets + 1] = function() value:SetText(fmt(db[key])) end
        return r
    end

    -- label ......... [ a | b | c ]  (segmented choice, the chosen one lit)
    local function choice(s, key, list, names, after)
        local r = row()
        label(r, s)
        local LABEL_COL = 100
        local w = math.floor((UI_INNER - LABEL_COL - 2 * (#list - 1)) / #list)
        local btns = {}
        for i = #list, 1, -1 do
            local b = uiButton(r, names[list[i]], w)
            if i == #list then b:SetPoint("RIGHT") else b:SetPoint("RIGHT", btns[i + 1], "LEFT", -2, 0) end
            b:SetScript("OnClick", function()
                local old = db[key]
                db[key] = list[i]
                if after then after(old) end
                changed()
            end)
            btns[i] = b
        end
        widgets[#widgets + 1] = function()
            for i, b in ipairs(btns) do
                local c = db[key] == list[i] and UI_ACCENT or { 0.6, 0.6, 0.6 }
                b.label:SetTextColor(c[1], c[2], c[3])
            end
        end
    end

    -- The modern-only rows, dimmed under the classic skin.
    local modernRows = {}
    local function modernOnly(r) modernRows[#modernRows + 1] = r end
    widgets[#widgets + 1] = function()
        for _, r in ipairs(modernRows) do r:SetAlpha(db.skin == "modern" and 1 or 0.4) end
    end

    -- Left column ----------------------------------------------------------
    head(L.secSkin)
    choice(L.skin, "skin", { "modern", "classic" }, { modern = L.modern, classic = L.classic }, function(old)
        if old == "modern" and db.skin == "classic" then say(L.reloadNote) end
    end)

    head(L.secLayout)
    modernOnly(stepper(L.width, "width", 10, 80, 600, px))
    modernOnly(stepper(L.height, "height", 1, 6, 48, px))
    modernOnly(stepper(L.border, "border", 1, 0, 4, px))
    modernOnly(check(L.shadowShow, "shadow"))
    modernOnly(check(L.sparkShow, "spark"))
    modernOnly(check(L.icon, "icon"))
    choice(L.timer, "timer", { "outside", "inside", "off" }, { outside = L.outside, inside = L.inside, off = L.off })

    head(L.secFont)
    do  -- Font ......... [<] name [>]   (the game's fonts, then LibSharedMedia's)
        local fr = row()
        label(fr, L.font)
        local nextB = uiButton(fr, ">", 24)
        nextB:SetPoint("RIGHT")
        local name = fr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetWidth(UI_INNER - 100 - 56)
        name:SetWordWrap(false)
        name:SetPoint("RIGHT", nextB, "LEFT", -4, 0)
        local prevB = uiButton(fr, "<", 24)
        prevB:SetPoint("RIGHT", name, "LEFT", -4, 0)
        local function step(d)
            local keys = fontKeys()
            local cur = 1
            for i, k in ipairs(keys) do if k == db.font then cur = i end end
            db.font = keys[((cur - 1 + d) % #keys) + 1]
            changed()
        end
        prevB:SetScript("OnClick", function() step(-1) end)
        nextB:SetScript("OnClick", function() step(1) end)
        widgets[#widgets + 1] = function()
            local path, n = fontInfo(db.font)
            pcall(name.SetFont, name, path, 12, "")
            name:SetText(n)
            name:SetTextColor(UI_ACCENT[1], UI_ACCENT[2], UI_ACCENT[3])
        end
    end
    check(L.nameShow, "name")
    choice(L.outline, "outline", { "shadow", "outline", "thick" }, { shadow = L.shadow, outline = L.thin, thick = L.thick })
    stepper(L.textSize, "textSize", 1, 6, 24, px)

    head(L.secBars)
    check(L.target, "target", function() if not db.target then say(L.reloadNote) end end)
    check(L.focus, "focus", function() if not db.focus then say(L.reloadNote) end end)

    -- Right column ---------------------------------------------------------
    col = cols[2]
    head(L.secTexture)

    -- Preview: icon, a bar 60% full in the chosen texture and colors, the name.
    local pv = row(20)
    local pvIconEdge = pv:CreateTexture(nil, "BACKGROUND")
    pvIconEdge:SetPoint("LEFT", 0, 0)
    pvIconEdge:SetSize(20, 20)
    pvIconEdge:SetColorTexture(0, 0, 0, 1)
    local pvIcon = pv:CreateTexture(nil, "ARTWORK")
    pvIcon:SetPoint("TOPLEFT", pvIconEdge, 1, -1)
    pvIcon:SetPoint("BOTTOMRIGHT", pvIconEdge, -1, 1)
    pvIcon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowBolt")
    pvIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local BAR_W = UI_INNER - 24 - 36
    local pvEdge = pv:CreateTexture(nil, "BACKGROUND")
    pvEdge:SetPoint("LEFT", 24, 0)
    pvEdge:SetSize(BAR_W, 20)
    pvEdge:SetColorTexture(0, 0, 0, 1)
    local pvBack = pv:CreateTexture(nil, "BORDER")
    pvBack:SetPoint("TOPLEFT", pvEdge, 1, -1)
    pvBack:SetPoint("BOTTOMRIGHT", pvEdge, -1, 1)
    pvBack:SetColorTexture(0.06, 0.06, 0.07, 1)
    local pvFill = pv:CreateTexture(nil, "ARTWORK")
    pvFill:SetPoint("TOPLEFT", pvBack)
    pvFill:SetPoint("BOTTOMLEFT", pvBack)
    pvFill:SetWidth((BAR_W - 2) * 0.6)
    local pvName = pv:CreateFontString(nil, "OVERLAY")
    pvName:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    pvName:SetPoint("CENTER", pvEdge)
    pvName:SetText(L.preview)
    local pvTime = pv:CreateFontString(nil, "OVERLAY")
    pvTime:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    pvTime:SetPoint("LEFT", pvEdge, "RIGHT", 5, 0)
    pvTime:SetText("1.2")
    widgets[#widgets + 1] = function()
        pvFill:SetTexture(texturePath(db.texture))
        local a, b = colorsFor("standard")
        gradient(pvFill, a, b)
        applyFont(pvName, math.min(db.textSize, 14))
        pvName:SetShown(db.name)
        applyFont(pvTime, math.min(db.textSize + 1, 15))
    end
    col.y = col.y - 4

    -- Texture swatches, four per row; hover for the name.
    local TX_GAP = 4
    local TX_W = math.floor((UI_INNER - 3 * TX_GAP) / 4)
    local texSwatches = {}
    local r
    for i, t in ipairs(TEXTURES) do
        if (i - 1) % 4 == 0 then r = row(14) end
        local s = CreateFrame("Button", nil, r)
        s:SetSize(TX_W, 12)
        s:SetPoint("LEFT", ((i - 1) % 4) * (TX_W + TX_GAP), 0)
        local ring = s:CreateTexture(nil, "BACKGROUND")
        ring:SetPoint("TOPLEFT", -2, 2)
        ring:SetPoint("BOTTOMRIGHT", 2, -2)
        ring:SetColorTexture(1, 1, 1, 1)
        local edge = s:CreateTexture(nil, "BORDER")
        edge:SetAllPoints()
        edge:SetColorTexture(0, 0, 0, 1)
        local fill = s:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", -1, 1)
        fill:SetTexture(t.path)
        s:SetScript("OnClick", function() db.texture = t.key; changed() end)
        s:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(t.name)
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", function() GameTooltip:Hide() end)
        texSwatches[#texSwatches + 1] = { key = t.key, ring = ring, fill = fill }
    end
    widgets[#widgets + 1] = function()
        local a, b = colorsFor("standard")
        for _, sw in ipairs(texSwatches) do
            gradient(sw.fill, a, b)
            sw.ring:SetShown(sw.key == db.texture)
        end
    end

    -- Every LibSharedMedia texture installed by other addons: [<] name [>].
    local lib = LSM()
    if lib then
        local lr = row()
        label(lr, L.more)
        local nextB = uiButton(lr, ">", 24)
        nextB:SetPoint("RIGHT")
        local name = lr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetWidth(UI_INNER - 100 - 56)
        name:SetWordWrap(false)
        name:SetPoint("RIGHT", nextB, "LEFT", -4, 0)
        local prevB = uiButton(lr, "<", 24)
        prevB:SetPoint("RIGHT", name, "LEFT", -4, 0)
        local function step(d)
            local list = lib:List("statusbar") or {}
            if #list == 0 then return end
            local cur = 0
            for i, n in ipairs(list) do if "lsm:" .. n == db.texture then cur = i end end
            cur = ((cur - 1 + d) % #list) + 1
            if cur < 1 then cur = #list end
            db.texture = "lsm:" .. list[cur]
            changed()
        end
        prevB:SetScript("OnClick", function() step(-1) end)
        nextB:SetScript("OnClick", function() step(1) end)
        widgets[#widgets + 1] = function()
            local isLsm = db.texture:sub(1, 4) == "lsm:"
            name:SetText(isLsm and textureName(db.texture) or "-")
            local c = isLsm and UI_ACCENT or { 0.6, 0.6, 0.6 }
            name:SetTextColor(c[1], c[2], c[3])
        end
    end

    head(L.secColors)
    local SW_W, SW_H, SW_GAP = 34, 16, 4
    local LABEL_W = UI_INNER - 6 * (SW_W + SW_GAP) + SW_GAP
    local swatches = {}
    for _, fam in ipairs(PALETTE_ROWS) do
        local rr = row(SW_H + 2)
        local fl = rr:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fl:SetPoint("LEFT")
        fl:SetWidth(LABEL_W - 4)
        fl:SetJustifyH("LEFT")
        fl:SetWordWrap(false)
        fl:SetText(fam.name)
        for i, key in ipairs(fam.list) do
            local s = CreateFrame("Button", nil, rr)
            s:SetSize(SW_W, SW_H)
            s:SetPoint("LEFT", LABEL_W + (i - 1) * (SW_W + SW_GAP), 0)
            local ring = s:CreateTexture(nil, "BACKGROUND")
            ring:SetPoint("TOPLEFT", -2, 2)
            ring:SetPoint("BOTTOMRIGHT", 2, -2)
            ring:SetColorTexture(1, 1, 1, 1)
            local edge = s:CreateTexture(nil, "BORDER")
            edge:SetAllPoints()
            edge:SetColorTexture(0, 0, 0, 1)
            local fill = s:CreateTexture(nil, "ARTWORK")
            fill:SetPoint("TOPLEFT", 1, -1)
            fill:SetPoint("BOTTOMRIGHT", -1, 1)
            fill:SetTexture(SQUARE)
            s:SetScript("OnClick", function() db.color = key; changed() end)
            s:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(COLOR_NAMES[key] or key)
                GameTooltip:Show()
            end)
            s:SetScript("OnLeave", function() GameTooltip:Hide() end)
            swatches[#swatches + 1] = { key = key, ring = ring, fill = fill }
        end
    end
    widgets[#widgets + 1] = function()
        local keep = db.color
        for _, sw in ipairs(swatches) do
            db.color = sw.key                     -- colorsFor reads db.color
            local a, b = colorsFor("standard")
            gradient(sw.fill, a, b)
            sw.ring:SetShown(sw.key == keep)
        end
        db.color = keep
    end
    col.y = col.y - 4
    stepper(L.bright, "bright", 0.05, 0.3, 1, pct)

    local y = math.min(cols[1].y, cols[2].y) - 6
    local reset = uiButton(f, L.reset, 200)
    reset:SetPoint("TOPLEFT", UI_PAD, y)
    reset:SetScript("OnClick", function() resetAll(); refreshWidgets() end)
    y = y - 22

    f:SetHeight(-y + UI_PAD)
    f:SetScript("OnShow", refreshWidgets)
    if UISpecialFrames then table.insert(UISpecialFrames, f:GetName()) end
    f:Hide()
    return f
end

local function togglePanel()
    panel = panel or buildPanel()
    panel:SetShown(not panel:IsShown())
end

function CastRail_OnCompartmentClick() togglePanel() end

local function registerSettings()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local c = CreateFrame("Frame")
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16)
    t:SetText(L.title)
    local s = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
    s:SetText(L.openNote)
    local b = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
    b:SetSize(200, 24)
    b:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -12)
    b:SetText(L.openBtn)
    b:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) end
        panel = panel or buildPanel()
        panel:Show()
    end)
    pcall(function() Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(c, L.title)) end)
end

SLASH_CASTRAIL1 = "/castrail"
SLASH_CASTRAIL2 = "/crail"
SlashCmdList.CASTRAIL = function(msg)
    local cmd = strtrim(msg or ""):lower()
    if cmd == "reset" then
        resetAll()
        say(L.reset)
    elseif cmd == "modern" or cmd == "classic" then
        db.skin = cmd
        applyAll()
    else
        togglePanel()
    end
    if panel and panel:IsShown() then panel.Refresh() end
end

-- Startup -----------------------------------------------------------------

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= ADDON then return end
        CastRailDB = CastRailDB or {}
        db = CastRailDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = type(v) == "table" and CopyTable(v) or v end
        end
        registerSettings()
    elseif event == "PLAYER_LOGIN" then
        applyAll()
    end
end)
