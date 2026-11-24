-- Reinos de Leyenda (rlmud.org), as it is played: the character's states,
-- what is said on its channels, each in its tab, and the map, which the
-- MUD publishes made with Mudlet, following the player on it. Its gauges
-- are among those of the editor.
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
-- If nothing has come a while after connecting, this says so.
--
-- What it shows is in the language of the interface, English or Spanish,
-- each text given in both with tr.

support_gmcp("Char 1")
support_gmcp("Comm 1")
support_gmcp("Room 1")

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

merge_gmcp("Char.Status")
on_gmcp("Char", function()
    heard = true
end)

---------------------------------------------------------------------------
-- States: kept in the variable estados, which the gauge Efectos of the
-- editor follows, each a label with what it is; the worst kinds first, in
-- their colour. A state is {nombre, corto, tipo, ayuda}. They are not said
-- aloud: the game says so itself, in its text.

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

local function keep(states)
    table.sort(states, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.name < b.name
    end)
    vars.estados = states
end

-- Those kept but the one known by `id`.
local function all_but(id)
    local left = {}
    for _, known in vars.estados or {} do
        if known.id ~= id then
            table.insert(left, known)
        end
    end
    return left
end

on_gmcp("Char.Status.Estados.set", function(data)
    local states = {}
    if type(data) == "table" then
        for key, state in pairs(data) do
            table.insert(states, shown(type(state) == "table" and state or key))
        end
    end
    keep(states)
end)

on_gmcp("Char.Status.Estados.add", function(state)
    local new = shown(state)
    local states = all_but(new.id)
    table.insert(states, new)
    keep(states)
end)

on_gmcp("Char.Status.Estados.remove", function(state)
    keep(all_but(text_of(state)))
end)

---------------------------------------------------------------------------
-- Channels: each in its tab, made before anyone speaks on it, and taken
-- away when the character leaves it. What was said before logging in comes
-- too.

local function said(data)
    heard = true
    if type(data) == "table" and data.canal and data.mensaje then
        channel(data.canal, data.mensaje)
    end
end

on_gmcp("Comm.MensajeCanal", said)
on_gmcp("Comm.MensajeCanalHistorico", said)

on_gmcp("Comm.Canales", function(data)
    heard = true
    for name in pairs(data) do
        channel(name)
    end
end)

on_gmcp("Comm.EnciendeCanal", function(data)
    local name = text_of(data)
    if name then
        channel(name)
    end
end)

on_gmcp("Comm.ApagaCanal", function(data)
    local name = text_of(data)
    if name then
        close_channel(name)
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

map.action(SYNC, function()
    map.import(MAP)
end)

-- How its rooms are named: the region first, as in "Anduar: Plaza Mayor",
-- and some with their exits after, as in "Desierto de Sharframna [n,s]".
map.names({ region = ":", exits = "[]" })

-- It is played in Spanish: its words for directions are those of the
-- language, long and short, "norte" and "n" to "fuera" and "fu". One of its
-- own would go after it, with map.directions.
map.language("es")

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

local LEARNING = "Reinos de Leyenda: mantener el mapa"
local LEARNING_ACTION = { en = "Keep the map up to date as you go", es = "Mantener el mapa al día sobre la marcha" }
local learning = vars[LEARNING] ~= false
map.learn(learning)
map.action(LEARNING_ACTION, function(on)
    learning = on
    vars[LEARNING] = on
    map.learn(on)
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
    if seen.came and not seen.name and here and not (exit and map.room(exit.to)) then
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
    local now = map.arrive(seen)
    -- Shown when Muddie is started with --debug.
    log(`Reinos: name={seen.name} exits={table.concat(seen.exits or {}, ",")} came={seen.came} -> {now}`)
end

-- The room as the game writes it. Each player sets what the prompt says
-- and how a room is shown, so neither is counted on: the prompt ends in no
-- new line, and with lag the room comes after it on its line, as "[PV 90]
-- Anduar: Arco Este [s,e,n,o]"; what is before the name is let go a word
-- at a time, up to a name the map has a room of.
local function known_room(text)
    local rest = text
    while rest do
        if #map.find(rest, { exact = true }) > 0 then
            return rest
        end
        rest = rest:match("^%S+%s+(.+)$")
    end
    return nil
end

local function written(this)
    shown = this
    after(0.2, function()
        if shown == this then
            shown = nil
            step(this)
        end
    end)
end

-- With its exits after it, as most show it.
trigger([[^(.*?) \[([A-Za-z|,\-]+)\]\s*$]], function(m)
    local name = known_room(m[1]) or m[1]:match("^.-[%]>]%s+(.+)$") or m[1]
    written({ name = name, exits = exits_of(m[2]), written = true })
end, { place = "Reinos de Leyenda/Sala escrita" })

-- Or by its name alone, as some show it: only a name the map has.
trigger([[^(.*\S: \S.*?)\s*$]], function(m)
    if m[1]:match("%[[^%]]*%]%s*$") then
        return
    end
    local name = known_room(m[1])
    if name then
        written({ name = name, written = true })
    end
end, { place = "Reinos de Leyenda/Sala escrita sin salidas" })

-- Moves come, but the map does not know where from: said once, with what
-- tells it, as moving alone does not.
local lost_told = false

on_gmcp("Room.Movimiento", function(way)
    heard = true
    local seen = shown or {}
    shown = nil
    seen.came = text_of(way)
    step(seen)
    if not map.room() and not lost_told then
        lost_told = true
        notify(tr({
            en = "The map does not know where you are. Reinos de Leyenda says it on logging in: reconnect, or say it with “I am in…”, in the palette.",
            es = "El mapa no sabe dónde estás. Reinos de Leyenda lo dice al entrar: reconecta, o díselo con «Estoy en…», en la paleta.",
        }))
    end
end)

-- A move that could not be made: it did not happen, and a walk stops.
on_gmcp("Room.MovimientoErroneo", function()
    shown = nil
    map.failed()
end)

on_gmcp("Room.Actual", function(room)
    heard = true
    room = text_of(room)
    if not room then
        return
    end
    local name, list = room:match("^(.-)%s*(%b[])%s*$")
    step({ name = name or room, exits = list and exits_of(list) })
end)

-- Once per connection: the map, and whether GMCP comes.
on_event("connect", function()
    heard = false
    lost_told = false
    shown = nil
    if map.count() == 0 then
        map.import(MAP)
    else
        map.newer(MAP, function()
            notify(tr({
                en = `There is a new version of the official map. To bring it: “{SYNC.en}”, in the map's menu or the palette. What you have put right on the map is kept.`,
                es = `Hay una versión nueva del mapa oficial. Para traerla: «{SYNC.es}», en el menú del mapa o en la paleta. Lo que hayas corregido en el mapa se mantiene.`,
            }))
        end)
    end
    after(90, function()
        if not heard then
            notify(tr({
                en = "Reinos de Leyenda does not send your life, the channels or where you are until you write in the game: consentir gmcp on",
                es = "Reinos de Leyenda no manda la vida, los canales ni dónde estás hasta que escribas en el juego: consentir gmcp on",
            }))
        end
    end)
end)
