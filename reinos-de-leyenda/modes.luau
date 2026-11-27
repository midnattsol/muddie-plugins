-- Ways of playing Reinos de Leyenda, each reading more or less of the game:
--
--   original   everything as the game writes it
--   combat     what matters in a fight, said short: who comes and goes,
--              what is said in the room, what happens to you
--   xp         as combat, and the lines of killing and of experience
--              not read: for gaining experience while listening to the
--              channels
--   idle       the room and the tells not read, only kept to read later
--
-- And the game read aloud or not at all, apart from the mode.
--
-- The mode is changed from the palette, with the alias
-- "modo" (the next, or "modo xp"), or with a key of keys.luau; it is said
-- once as it changes, and remembered. The other scripts of the plugin read
-- it, vars.reinos_mode, and ask for another with emit("reinos_mode", name):
-- a big hit leaves xp, being attacked leaves idle. What is read short is so
-- while the tag "reinos-brief" is on, which original switches off.

local MODES = { "original", "combat", "xp", "idle" }
local NAMES = {
    original = { en = "Original", es = "Original" },
    combat = { en = "Combat", es = "Combate" },
    xp = { en = "Experience", es = "Experiencia" },
    idle = { en = "Idle", es = "Inactivo" },
}
-- What a player types for each, in either language.
local TYPED = {
    original = "original",
    combate = "combat",
    combat = "combat",
    xp = "xp",
    experiencia = "xp",
    idle = "idle",
    inactivo = "idle",
}

local KEPT = "reinos_mode"

-- The mode there is: combat until another is chosen.
local function current(): string
    local mode = vars[KEPT]
    if type(mode) == "string" and NAMES[mode] then
        return mode
    end
    return "combat"
end

-- Switches what each mode switches.
local function apply(mode: string)
    if mode == "original" then
        tags.disable("reinos-brief")
    else
        tags.enable("reinos-brief")
    end
end

-- Puts a mode, and says it once.
local function choose_mode(mode: string)
    if not NAMES[mode] then
        return
    end
    local before = current()
    vars[KEPT] = mode
    apply(mode)
    if mode ~= before then
        speak({ en = `Mode: {NAMES[mode].en}.`, es = `Modo: {NAMES[mode].es}.` }, { aloud = "cut" })
    end
end

-- The next mode after the one there is.
local function next_mode()
    local now = current()
    for index, mode in MODES do
        if mode == now then
            choose_mode(MODES[index % #MODES + 1])
            return
        end
    end
    choose_mode(MODES[1])
end

apply(current())

action({ en = "Next way of playing (mode)", es = "Siguiente modo de juego" }, next_mode)

alias("^modo$", next_mode, { place = "Reinos de Leyenda/Modes/Next" })
alias("^modo (\\w+)$", function(m)
    local mode = TYPED[m[1]:lower()]
    if mode then
        choose_mode(mode)
    else
        speak({
            en = "The modes are original, combate, xp and inactivo.",
            es = "Los modos son original, combate, xp e inactivo.",
        })
    end
end, { place = "Reinos de Leyenda/Modes/Choose" })

on("emit", "reinos_mode", function(mode)
    if mode == "next" then
        next_mode()
    elseif type(mode) == "string" then
        choose_mode(mode)
    end
end)

-- What mode it is, without changing it.
alias("^modo\\?$", function()
    local mode = current()
    speak({ en = `Mode: {NAMES[mode].en}.`, es = `Modo: {NAMES[mode].es}.` })
end, { place = "Reinos de Leyenda/Modes/Which" })

---------------------------------------------------------------------------
-- Quiet: the game not read aloud at all, what Muddie says still is. Back
-- with the same alias or action.

local function quiet()
    local reading = not session.reading
    session.reading = reading
    speak(if reading
        then { en = "The game is read aloud again.", es = "Se vuelve a leer el juego." }
        else { en = "Quiet: the game is not read.", es = "Silencio: el juego no se lee." },
        { always = true })
end

action({ en = "Quiet: the game not read", es = "Silencio: no leer el juego" }, quiet)
alias("^silencio$", quiet, { place = "Reinos de Leyenda/Modes/Quiet" })
on("emit", "reinos_quiet", quiet)
