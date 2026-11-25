-- Reinos de Leyenda (rlmud.org), as it is played: the character's states,
-- what is said on its channels, each in its tab, and the map, which the
-- MUD publishes made with Mudlet, following the player on it. Its gauges of
-- life, energy and faith are among those of the editor. What is said aloud is
-- in aloud.luau.
-- All by GMCP, in packages of the MUD's own; this is what it sends, as a
-- session shows:
--
--   on logging in    Char.Status, Char.Status.Estados.set, Char.Ficha,
--                    Char.Stats, Comm.Canales, Room.Actual once
--   on each step     the room in its text as "Name [exits]", then
--                    Room.Movimiento "este"; or Room.MovimientoErroneo
--                    "sudeste" for a move that could not be made
--   as it happens    Char.Status (what changed only), Char.Status.Estados
--                    .add and .remove, Comm.MensajeCanal, and
--                    Comm.EnciendeCanal and Comm.ApagaCanal
--
-- The MUD sends nothing over GMCP until asked from inside the game:
--     consentir gmcp on
-- If nothing has come a while after entering the game, this says so.
--
-- What it shows is in the language of the interface, English or Spanish,
-- each text given in both.

local prompt = require("prompt")

gmcp.support("Char 1")
gmcp.support("Comm 1")
gmcp.support("Room 1")

local heard = false

-- Text, as it comes or inside a table of the MUD's.
local function text_of(value)
    if type(value) == "string" then
        return value
    end
    if type(value) == "table" then
        for _, field in { "nombre", "name", "canal", "salida", "direccion", 1 } do
            if type(value[field]) == "string" then
                return value[field]
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Gauges: they are among the gauges of the editor, made from Char.Status,
-- life, energy and faith. Char.Status gives each as {min = now,
-- max = most}, at first all of them and then only what changed: it is
-- merged into what came before, for the gauges to have it whole.

gmcp.merge("Char.Status")
on("gmcp", "Char", function()
    heard = true
end)

---------------------------------------------------------------------------
-- States: each a label of the gauge Efectos, with what it is; the worst
-- kinds first, in their colour. A state is {nombre, corto, tipo, ayuda}. What
-- changes of them is said by aloud.luau.

-- The colour of each kind of state, the worst first.
local KINDS = {
    enfermedades = { colour = "#e05050", order = 1 },
    incapacidades = { colour = "#e0c040", order = 2 },
}

-- A state as the gauge shows it, with what it is known by.
local function shown(state)
    if type(state) ~= "table" then
        state = { nombre = state }
    end
    local kind = KINDS[state.tipo or ""]
    local id = text_of(state) or ""
    return {
        id = id,
        name = state.corto or id,
        about = state.ayuda or "",
        colour = kind and kind.colour or "",
        order = kind and kind.order or 99,
    }
end

-- Those the character is in.
local states = {}

local function show()
    table.sort(states, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.name < b.name
    end)
    local items = {}
    for _, state in states do
        table.insert(items, { name = state.name, about = state.about, colour = state.colour })
    end
    gauges.set("Efectos", {
        kind = "effects",
        items = items,
        colour = "#8a9bb8",
        aloud = "never",
        panel = "Efectos",
        place = "Reinos de Leyenda/Efectos",
    })
end

-- Takes out the state known by `id`.
local function leave(id)
    for index, known in states do
        if known.id == id then
            table.remove(states, index)
            return
        end
    end
end

on("gmcp", "Char.Status.Estados.set", function(data)
    states = {}
    if type(data) == "table" then
        for key, state in pairs(data) do
            table.insert(states, shown(type(state) == "table" and state or key))
        end
    end
    show()
end)

on("gmcp", "Char.Status.Estados.add", function(state)
    local new = shown(state)
    leave(new.id)
    table.insert(states, new)
    show()
end)

on("gmcp", "Char.Status.Estados.remove", function(state)
    leave(text_of(state))
    show()
end)

on("disconnect", function()
    states = {}
end)

---------------------------------------------------------------------------
-- Channels: each in its tab, made before anyone speaks on it, and taken
-- away when the character leaves it. What was said before logging in comes
-- too.

local function said(data, before)
    heard = true
    if type(data) == "table" and data.canal and data.mensaje then
        channels.say(data.canal, data.mensaje, { aloud = if before then "never" else "usual" })
    end
end

on("gmcp", "Comm.MensajeCanal", function(data)
    said(data, false)
end)
-- Kept, and not read aloud: it comes all at once.
on("gmcp", "Comm.MensajeCanalHistorico", function(data)
    said(data, true)
end)

on("gmcp", "Comm.Canales", function(data)
    heard = true
    for name in pairs(data) do
        channels.open(name)
    end
end)

on("gmcp", "Comm.EnciendeCanal", function(data)
    local name = text_of(data)
    if name then
        channels.open(name)
    end
end)

on("gmcp", "Comm.ApagaCanal", function(data)
    local name = text_of(data)
    if name then
        channels.close(name)
    end
end)

---------------------------------------------------------------------------
-- The map. The MUD publishes it for Mudlet: it is taken when the session
-- has no map yet, and after that only when the user asks for it, from the
-- map's menu or the palette, so that the map never changes unasked. On
-- connecting it is looked whether the MUD's has changed, to say so. Taken
-- again, what the user set on the map stays: the names given to rooms,
-- notes, marks, rooms to avoid and exits of their own, and the rooms the
-- map added where the player went, if the user switched that on (below).

local MAP = "https://mudlet.reinosdeleyenda.es/Mapa_Mudlet.zip"
-- Its name, in the language the interface is in when shown.
local SYNC = { en = "Sync with the official map", es = "Sincronizar con el mapa oficial" }

-- The month a newer map was last told of, kept in the profile: told at each
-- connection, it would be noise.
local NEWER_TOLD = "reinos_newer_map_told"

map.action(SYNC, function()
    vars[NEWER_TOLD] = nil
    map.import(MAP)
end)

-- How its rooms are named: the region first, as in "Anduar: Plaza Mayor",
-- and some with their exits after, as in "Desierto de Sharframna [n,s]".
map.names = { region = ":", exits = "[]" }

-- It is played in Spanish: its words for directions are those of the
-- language, long and short, "norte" and "n" to "fuera" and "fu". One of its
-- own would go after it, with map.directions.
map.language = "es"

-- Following the player. The MUD tells three things, each used for what it
-- is good for:
--   Room.Movimiento "este"   that a move was made, and by which exit: what
--                            moves the player on the map, each one as it
--                            comes, in order, whatever the lag;
--   "Name [exits]"           the room, as the game writes it in its text
--                            just before that move, and again on looking:
--                            what checks the map is right, and puts it
--                            right if it is not;
--   Room.Actual              the room, once, on logging in.
-- The room written is taken with the move that follows it; one written
-- with no move after it, as on looking, is taken by itself a moment later.

local shown = nil

local function exits_of(list)
    local exits = {}
    -- Doors are marked on their exits with | and -.
    for exit in (list:gsub("[|%-]", "")):gmatch("[^%[%],%s]+") do
        table.insert(exits, exit)
    end
    return exits
end

---------------------------------------------------------------------------
-- Keeping the map up to date as the player goes. The map the MUD publishes
-- names some rooms with what was said or done in them as they were mapped
-- ("Moony te dice: ..."), with their names cut short ("Erial de los
-- Condenados: Ca"), or with nothing; and the MUD renames rooms, opens
-- exits and builds rooms the map has not. The map learns from the room
-- the game writes on each move: it puts right what it has wrong once it
-- is borne out, and adds the rooms it has not, never from a room it does
-- not know for certain the player was in. It says what it changed, and it
-- can be undone. On unless switched off, from the map's menu or the
-- palette, and remembered in the profile.

local LEARNING = "reinos_learning"
local LEARNING_ACTION = { en = "Keep the map up to date as you go", es = "Mantener el mapa al día sobre la marcha" }
local learning = vars[LEARNING] ~= false
map.learn = learning
map.action(LEARNING_ACTION, function(on)
    learning = on
    vars[LEARNING] = on
    map.learn = on
end, { checked = learning })

-- Whether every exit written is a direction: else the line was something
-- said with brackets, not a room.
local function all_directions(exits)
    if #exits == 0 then
        return false
    end
    for _, exit in exits do
        if not map.direction(exit) then
            return false
        end
    end
    return true
end

-- The map did not follow a move: told once, until it follows again.
local stray_told = false

local function step(seen)
    -- A line the game wrote whose brackets hold anything but directions
    -- was not a room: the move alone is followed.
    if seen.written and seen.exits and not all_directions(seen.exits) then
        seen.name, seen.exits = nil, nil
    end
    -- A move with no room written to check it by, by an exit the map has
    -- not or that leads to no room it has: it is said, and the map stays
    -- where it was.
    local here = map.room()
    local exit = here and seen.came and map.exit(here.id, seen.came)
    local stray = seen.came and not seen.name and here and not (exit and map.room(exit.to))
    if stray and not stray_told then
        notify(if exit
            then tr({
                en = `The map does not know where {seen.came} from {here.name} leads: it has not followed you.`,
                es = `El mapa no sabe adónde lleva {seen.came} desde {here.name}: no te ha seguido.`,
            })
            else tr({
                en = `The map has no exit {seen.came} from {here.name}: it has not followed you.`,
                es = `El mapa no tiene la salida {seen.came} desde {here.name}: no te ha seguido.`,
            }))
    end
    if seen.came then
        stray_told = stray
    end
    local now = map.arrive({ name = seen.name, exits = seen.exits, came = seen.came })
    -- Shown when Muddie is started with --debug.
    log(`Reinos: name={seen.name} exits={table.concat(seen.exits or {}, ",")} came={seen.came} -> {now}`)
end

-- The prompt, as the player makes it: the game says it so, whole, on lines as
-- long as it writes them.
trigger([[^(?:.*[>\]}] )?Tu prompt (de combate )?ha sido definido como '(.*)$]], function(m)
    local template = m[2]
    while not template:match("'%.%s*$") do
        local _, line = wait("line", "", { timeout = 1, prompt = false })
        if not line then
            return
        end
        template ..= " " .. line.text
    end
    prompt.learn(m[1] ~= nil and m[1] ~= "", (template:gsub("'%.%s*$", "")))
end, { place = "Reinos de Leyenda/Prompt" })

-- The room as the game writes it. Each player sets what the prompt says and
-- how a room is shown: the prompt ends in no new line, and with lag the room
-- comes after it on its line, as "[PV 90] Anduar: Arco Este [s,e,n,o]". Known
-- the prompt, the room is the line, or what is after the prompt. Not known, the
-- game ends every one in ">", "]" or "}", exits between brackets too.

-- What a line may be, whole, with no prompt before it: the line, and what is
-- left of it after each sign that may end a prompt. The room is one of these
-- or it is not there. Never the last words of a line: anyone may say the name
-- of a room.
local function without_prompt(line)
    local rest = prompt.rest(line)
    if rest then
        return if rest == "" then {} else { rest }
    end
    local parts = { line }
    if prompt.is_known() then
        return parts
    end
    local from = 1
    while true do
        local _, last = line:find("[>%]}]%s*", from)
        if not last or last >= #line then
            return parts
        end
        from = last + 1
        table.insert(parts, line:sub(from))
    end
end

-- The room a line writes: its name, if it is one the map has; else what
-- would be its name, if it can be one.
local function room_written(line)
    local parts = without_prompt(line)
    for _, part in parts do
        if #map.find(part, { exact = true }) > 0 then
            return part, nil
        end
    end
    -- What ends in a colon names what follows it, as "SL:" the exits.
    local last = parts[#parts] or ""
    return nil, if last:match("%S") and not last:match(":%s*$") then last else nil
end

-- Whether a name has a region, or a part, as the rooms of most places do:
-- "Anduar: Plaza Mayor", "Catedral de la Guerra - Tesorería".
local function like_a_room(name)
    return name:match("%S: %S") ~= nil or name:match("%S %- %S") ~= nil
end

-- What was written before exits with no move after it, and is no room the
-- map has, with the room the player was in: part of a prompt of several
-- lines, as "Salidas [n,s]", which comes in room after room, or a room only
-- looked at. What is known to be of the prompt, true, is not taken for the
-- room moved to.
local no_room = {}

local function looked_at(this)
    local name = this.unknown
    local here = map.room()
    if not like_a_room(name) then
        no_room[name] = true
    elseif here then
        local before = no_room[name] or here.id
        no_room[name] = if before == here.id then before else true
    else
        -- Lost: it may be a room the map has by another name.
        this.name = name
        step(this)
    end
end

local function written(this)
    -- A room the map has is not put aside for what comes after it.
    if shown and shown.name and not this.name then
        return
    end
    shown = this
    after(0.2, function()
        if shown ~= this then
            return
        end
        shown = nil
        if this.name then
            step(this)
        elseif this.unknown then
            looked_at(this)
        end
    end)
end

-- The player is in the game, as a room is written: from then on GMCP is to
-- come, and if it does not, it is told how to ask for it.
local entered = false
local asking = nil

local function enter()
    if entered then
        return
    end
    entered = true
    asking = after(90, function()
        if not heard then
            notify(tr({
                en = "Reinos de Leyenda does not send your life, the channels or where you are until you write in the game: consentir gmcp on",
                es = "Reinos de Leyenda no manda la vida, los canales ni dónde estás hasta que escribas en el juego: consentir gmcp on",
            }))
        end
    end)
end

-- With its exits after it, as most show it.
trigger([[^(.*?) \[([A-Za-z|,\-]+)\]\s*$]], function(m)
    local name, unknown = room_written(m[1])
    local exits = exits_of(m[2])
    if all_directions(exits) then
        enter()
    end
    written({ name = name, unknown = unknown, exits = exits, written = true })
end, { place = "Reinos de Leyenda/Room written" })

-- Or by its name alone, as some show it: only a name the map has.
trigger([[^(.*\S: \S.*?)\s*$]], function(m)
    if m[1]:match("%[[^%]]*%]%s*$") then
        return
    end
    local name = room_written(m[1])
    if name then
        enter()
        written({ name = name, written = true })
    end
end, { place = "Reinos de Leyenda/Room written without exits" })

on("gmcp", "Room.Movimiento", function(way)
    heard = true
    local seen = shown or {}
    shown = nil
    if not seen.name then
        if seen.unknown and no_room[seen.unknown] ~= true then
            seen.name = seen.unknown
        else
            seen.exits = nil
        end
    end
    seen.came = text_of(way)
    step(seen)
end)

-- A move that could not be made: it did not happen, and a walk stops.
on("gmcp", "Room.MovimientoErroneo", function()
    shown = nil
    map.failed()
end)

on("gmcp", "Room.Actual", function(room)
    heard = true
    room = text_of(room)
    if not room then
        return
    end
    local name, list = room:match("^(.-)%s*(%b[])%s*$")
    step({ name = name or room, exits = list and exits_of(list) })
end)

-- Once per connection: the map, and whether GMCP comes.
on("connect", function()
    heard = false
    stray_told = false
    no_room = {}
    shown = nil
    if map.count() == 0 then
        map.import(MAP)
    else
        map.newer(MAP, function()
            local month = os.date("%Y-%m")
            if vars[NEWER_TOLD] == month then
                return
            end
            vars[NEWER_TOLD] = month
            notify(tr({
                en = `There is a new version of the official map. To bring it: “{SYNC.en}”, in the map's menu or the palette. What you have put right on the map is kept.`,
                es = `Hay una versión nueva del mapa oficial. Para traerla: «{SYNC.es}», en el menú del mapa o en la paleta. Lo que hayas corregido en el mapa se mantiene.`,
            }))
        end)
    end
    entered = false
    if asking then
        asking:remove()
        asking = nil
    end
end)
