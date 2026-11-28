-- Sounds of Reinos de Leyenda, for whoever plays by ear: those of ScriptsRL,
-- by Rhomdur and Enorthus, used with their permission. Muddie fetches the
-- ones played here from ScriptsRL's repository, as plugin.toml says, and
-- keeps them; a player who has ScriptsRL can put the contents of its
-- sounds/RL folder in the profile's sounds folder, and those are played.
--
-- On by default with a screen reader, off without: switched with the alias
-- "sonidos" or from the palette, and remembered. Each group of sounds has
-- its own volume, from 0 to 100, remembered: "volumen alertas 40"; with no
-- figure, it is said.
--
--   alerts      life under 50, 30 and 10 %, again and again until it
--               comes back up
--   combat      being attacked, a kill, someone found hiding, experience
--   messages    a tell, something said in the room
--   movement    someone comes or goes, to the side they come by; the target
--   ambient     modes, quiet, something copied
--
-- It listens to what the other scripts of the plugin tell: life from what
-- the MUD sends, as life.luau; the rest as history, movement and modes say.

local KEPT = "reinos_sounds"
local PLACE = "Reinos de Leyenda/Sounds"

local FILES = {
    life50 = "Combate/Alerta vida 50.wav",
    life30 = "Combate/Alerta vida 30.wav",
    life10 = "Combate/Alerta vida 10.wav",
    attacked = "Combate/Siendo atacado.wav",
    kill = "Combate/Muerte enemigo.wav",
    found = "Sucesos/Enemigo descubierto.wav",
    group = "Generales/Grupo evento.wav",
    xp = "Generales/XP ganada.wav",
    tell = "Comunicaciones/telepatia.wav",
    room = "Comunicaciones/room.wav",
    arrives = "Movimiento/Llega desconocido.wav",
    leaves = "Movimiento/Se va desconocido.wav",
    target_here = "Movimiento/Objetivo aqui.wav",
    target_arrives = "Movimiento/Objetivo llega.wav",
    target_leaves = "Movimiento/Objetivo se va.wav",
    on = "Modos/On.wav",
    off = "Modos/Off.wav",
    mode = "Modos/Boton.wav",
    copied = "Generales/Portapapeles.wav",
}

-- The groups, by the name a player types, in either language.
local GROUPS = {
    alertas = "alerts",
    alerts = "alerts",
    combate = "combat",
    combat = "combat",
    mensajes = "messages",
    messages = "messages",
    movimiento = "movement",
    movement = "movement",
    ambiente = "ambient",
    ambient = "ambient",
}

---------------------------------------------------------------------------
-- On or off.

-- Whether the sounds are on: as the player chose, else with a screen
-- reader.
local function wanted(): boolean
    local chosen = vars[KEPT]
    if type(chosen) == "boolean" then
        return chosen
    end
    return session.reader
end

local on_now = false
local loops: { [string]: any } = {}

local function stop_loops()
    for step, sound in loops do
        sound:stop()
        loops[step] = nil
    end
end

local function play(cue: string, options: { [string]: any }?)
    if on_now then
        return sounds.play(FILES[cue], options)
    end
    return nil
end

-- Puts the volume of each group as the player left it.
local function volumes()
    for _, group in { "alerts", "combat", "messages", "movement", "ambient" } do
        local volume = vars[`reinos_volume_{group}`]
        if type(volume) == "number" then
            sounds.volume(group, volume)
        end
    end
end

local function set_on(now: boolean)
    on_now = now
    if now then
        local all = {}
        for _, file in FILES do
            table.insert(all, file)
        end
        -- All at once, so that the first alert is not late.
        sounds.fetch(all)
        volumes()
    else
        stop_loops()
    end
end

set_on(wanted())

-- A screen reader that comes, or goes, while the player chose nothing.
on("reader", function()
    if vars[KEPT] == nil then
        set_on(wanted())
    end
end)

local ACTION = { en = "Sounds of Reinos", es = "Sonidos de Reinos" }
local switch: (on: boolean) -> ()

local function offer()
    action(ACTION, switch, { checked = on_now })
end

function switch(now: boolean)
    vars[KEPT] = now
    set_on(now)
    speak(if now
        then { en = "Sounds on.", es = "Sonidos activados." }
        else { en = "Sounds off.", es = "Sonidos desactivados." })
    offer()
end

offer()

alias("^sonidos$", function()
    switch(not on_now)
end, { place = `{PLACE}/Switch` })

alias("^volumen (\\S+) ?(\\d*)$", function(m)
    local group = GROUPS[m[1]:lower()]
    if not group then
        speak({
            en = "The groups are alertas, combate, mensajes, movimiento and ambiente.",
            es = "Los grupos son alertas, combate, mensajes, movimiento y ambiente.",
        })
        return
    end
    if m[2] ~= "" then
        local volume = math.clamp(tonumber(m[2]) or 100, 0, 100) / 100
        vars[`reinos_volume_{group}`] = volume
        sounds.volume(group, volume)
    end
    local now = math.floor(sounds.volume(group) * 100 + 0.5)
    speak({ en = `Volume of {m[1]}: {now}.`, es = `Volumen de {m[1]}: {now}.` })
end, { place = `{PLACE}/Volume` })

---------------------------------------------------------------------------
-- Life: an alert for each step it falls under, again and again until it
-- comes back 5 % over it; the lowest alone sounds.

local STEPS = { { under = 10, cue = "life10" }, { under = 30, cue = "life30" }, { under = 50, cue = "life50" } }

on("gmcp", "Char.Status", function()
    local status = gmcp.get("Char.Status")
    local points = type(status) == "table" and status.pvs
    if type(points) ~= "table" then
        return
    end
    local now, most = tonumber(points.min), tonumber(points.max)
    if not now or not most or most <= 0 then
        return
    end
    local percent = now * 100 / most
    -- The step it is under now: the lowest crossed; or the one sounding,
    -- until life is 5 % over it.
    local wanted_step = nil
    for _, step in STEPS do
        local sounding = loops[step.cue] ~= nil
        if percent < step.under or (sounding and percent < step.under + 5) then
            wanted_step = step
            break
        end
    end
    for cue, sound in loops do
        if not wanted_step or wanted_step.cue ~= cue then
            sound:stop()
            loops[cue] = nil
        end
    end
    if wanted_step and not loops[wanted_step.cue] and on_now then
        loops[wanted_step.cue] = play(wanted_step.cue, { loop = true, group = "alerts" })
    end
end, { place = `{PLACE}/Life`, tags = "reinos-sounds" })

on("disconnect", stop_loops)

---------------------------------------------------------------------------
-- What the other scripts of the plugin tell.

-- Where a way is heard: the west on the left, the east on the right, the
-- rest in the middle.
local function side(way: string?): number
    local said = (way or ""):lower()
    if said:find("oeste") then
        return -0.8
    elseif said:find("este") then
        return 0.8
    end
    return 0
end

local GROUP_OF = {
    attacked = "combat",
    kill = "combat",
    found = "combat",
    group = "combat",
    tell = "messages",
    room = "messages",
    copied = "ambient",
}

on("emit", "reinos_event", function(event)
    if type(event) ~= "table" or not on_now then
        return
    end
    local kind = event.kind
    if kind == "arrives" or kind == "leaves" then
        local cue = if event.target then `target_{kind}` else kind
        play(cue, { group = "movement", pan = side(event.way) })
    elseif kind == "target_here" then
        play("target_here", { group = "movement" })
    elseif kind == "mode" then
        play("mode", { group = "ambient" })
    elseif kind == "quiet" then
        play(if event.on then "off" else "on", { group = "ambient" })
    elseif GROUP_OF[kind] then
        play(kind, { group = GROUP_OF[kind] })
    end
end, { place = `{PLACE}/Events`, tags = "reinos-sounds" })

-- Experience gained, as the game says it.
trigger([=[^\[Obtienes .+ puntos de experiencia\]]=], function()
    play("xp", { group = "combat", volume = 0.6 })
end, { place = `{PLACE}/Experience`, tags = "reinos-sounds" })
