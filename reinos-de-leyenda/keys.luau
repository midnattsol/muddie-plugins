-- Keys as players of Reinos de Leyenda coming from VipMud know them: off
-- until the player switches them on, from the palette,
-- or with the alias "teclasrl"; remembered. A plugin of a MUD does not
-- change anyone's keys unasked.
--
-- Walking, with Alt and the keys around the right hand, as a keypad:
--
--   Alt+7  noroeste   Alt+8  norte   Alt+9  noreste
--   Alt+U  oeste      Alt+I  arriba  Alt+O  este
--   Alt+J  suroeste   Alt+K  sur     Alt+L  sureste
--   Alt+M  abajo      Alt+,  dentro  Alt+.  fuera
--
-- They walk on the map too, while it is explored.
--
--   Alt+1, Alt+2          life, energy; with Shift, copied
--   F2, F3, F4, F5        the last said in the room, tell, event, change
--                         of life; with Shift, all of them, to choose
--   Alt+3, Alt+Shift+3    the last who came or went; all of them
--   Alt+T                 whom "r" replies to; Ctrl+Shift+T, choose them
--   F11, F12              the next mode; quiet
--
-- So that they do not clash with Muddie's, the most recent lines are read
-- with Ctrl and the figures, as in VipMud (Ctrl+Shift for a panel), the
-- link of a line followed with Ctrl+Alt+O, and where you are said with
-- Ctrl+Alt+M. Switched off, Muddie's are back.

local KEPT = "reinos_keys"

local WALKING = {
    ["alt+7"] = "no",
    ["alt+8"] = "n",
    ["alt+9"] = "ne",
    ["alt+u"] = "o",
    ["alt+i"] = "ar",
    ["alt+o"] = "e",
    ["alt+j"] = "so",
    ["alt+k"] = "s",
    ["alt+l"] = "se",
    ["alt+m"] = "ab",
    ["alt+comma"] = "de",
    ["alt+period"] = "fu",
}

-- Muddie's shortcuts these take the keys of, and those they get instead.
local MOVED = {
    follow_link = "ctrl+alt+o",
    ["where"] = "ctrl+alt+m",
}
for figure = 1, 9 do
    MOVED[`read_recent_{figure}`] = `ctrl+{figure}`
    MOVED[`panel_recent_{figure}`] = `ctrl+shift+{figure}`
end

-- How many points of `what` there are, as Char.Status gives them.
local function points(what: string): (number?, number?)
    local status = gmcp.get("Char.Status")
    local of = type(status) == "table" and status[what]
    if type(of) ~= "table" then
        return nil, nil
    end
    return tonumber(of.min), tonumber(of.max)
end

local function say_points(what: string, name: { [string]: string }, copy: boolean)
    local now, most = points(what)
    if not now or not most then
        speak({ en = "Not known yet.", es = "Aún no se sabe." })
        return
    end
    if copy then
        clipboard.set(`{now}({most})`)
        speak({ en = "Copied.", es = "Copiado." })
    else
        speak({ en = `{name.en} {now} of {most}.`, es = `{name.es} {now} de {most}.` })
    end
end

local LIFE = { en = "Life", es = "Vida" }
local ENERGY = { en = "Energy", es = "Energía" }

-- What each key does but walking.
local DOING: { [string]: () -> () } = {
    ["alt+1"] = function()
        say_points("pvs", LIFE, false)
    end,
    ["alt+shift+1"] = function()
        say_points("pvs", LIFE, true)
    end,
    ["alt+2"] = function()
        say_points("pe", ENERGY, false)
    end,
    ["alt+shift+2"] = function()
        say_points("pe", ENERGY, true)
    end,
    f2 = function()
        emit("reinos_history", { last = "room" })
    end,
    ["shift+f2"] = function()
        emit("reinos_history", { open = "room" })
    end,
    f3 = function()
        emit("reinos_history", { last = "tells" })
    end,
    ["shift+f3"] = function()
        emit("reinos_history", { open = "tells" })
    end,
    f4 = function()
        emit("reinos_history", { last = "events" })
    end,
    ["shift+f4"] = function()
        emit("reinos_history", { open = "events" })
    end,
    f5 = function()
        emit("reinos_life", "last")
    end,
    ["shift+f5"] = function()
        emit("reinos_life", "list")
    end,
    ["alt+3"] = function()
        emit("reinos_moves", "last")
    end,
    ["alt+shift+3"] = function()
        emit("reinos_moves", "list")
    end,
    ["alt+t"] = function()
        emit("reinos_history", "who")
    end,
    ["ctrl+shift+t"] = function()
        emit("reinos_history", "reply_to")
    end,
    f11 = function()
        emit("reinos_mode", "next")
    end,
    f12 = function()
        emit("reinos_quiet", true)
    end,
}

-- The keys made, to take them away.
local made: { Made } = {}

local function switch_on()
    local place = "Reinos de Leyenda/Keys"
    for key, way in WALKING do
        table.insert(made, macro(key, way, { place = place, tags = "reinos-keys" }))
    end
    for key, doing in DOING do
        table.insert(made, macro(key, doing, { place = place, tags = "reinos-keys" }))
    end
    for name, keys in MOVED do
        shortcuts[name] = keys
    end
end

local function switch_off()
    for _, key in made do
        key:remove()
    end
    made = {}
    for name in MOVED do
        shortcuts[name] = nil
    end
end

local on_now = vars[KEPT] == true
if on_now then
    switch_on()
end

local ACTION = { en = "Keys of Reinos, as in VipMud", es = "Teclas de Reinos, como en VipMud" }
local switch: (on: boolean) -> ()

-- Offered in the palette, ticked while they are on.
local function offer()
    action(ACTION, switch, { checked = on_now })
end

function switch(on: boolean)
    on_now = on
    vars[KEPT] = on
    if on then
        switch_on()
        speak({ en = "Keys of Reinos on.", es = "Teclas de Reinos activadas." })
    else
        switch_off()
        speak({ en = "Keys of Reinos off: Muddie's are back.", es = "Teclas de Reinos desactivadas: vuelven las de Muddie." })
    end
    offer()
end

offer()

alias("^teclasrl$", function()
    switch(not on_now)
end, { place = "Reinos de Leyenda/Keys/Switch" })
