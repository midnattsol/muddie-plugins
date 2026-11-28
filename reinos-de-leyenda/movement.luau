-- Who comes into the room and who leaves it, and by which way: read short
-- in the modes that shorten ("Orco llega, sur"), not at all while idle,
-- and kept, to hear the last again or go through them (alias "hmov").
--
-- A target, the one you are after: the first of your nick x as you set it
-- in the game ("nick x Orome, Ana" makes it Orome), or the one you give
-- with "obj nombre". When it is in the room, comes or leaves, it is said at
-- once, cutting in; "obj" alone says which it is.

local corrector = require("corrector")

local MOST = 30
local TARGET = "reinos_target"

local moves: { string } = {}
-- Who the game said is here, in the room the player is in, by name in
-- lower case: the target is told of once per room.
local here: { [string]: boolean } = {}

local function mode(): string
    return if type(vars.reinos_mode) == "string" then vars.reinos_mode else "combat"
end

local function target(): string?
    return if type(vars[TARGET]) == "string" then vars[TARGET] else nil
end

local function is_target(name: string): boolean
    local wanted = target()
    return wanted ~= nil and name:lower() == wanted:lower()
end

local function keep(text: string)
    table.insert(moves, 1, text)
    if #moves > MOST then
        table.remove(moves)
    end
end

-- The way, as the game writes it, without its article: "el sur" is "sur".
local function way_of(text: string): string
    local way = text:gsub("^el ", ""):gsub("^la ", ""):gsub("^los ", ""):gsub("^las ", "")
    return way
end

-- A line that is someone else's words, on a channel or said: not a move.
local function said(text: string): boolean
    return text:match("^%[") ~= nil or text:match(": ") ~= nil
end

local function moved(who: string, way: string, came: boolean, line: Line)
    local name = corrector.name(who)
    local short = if came
        then tr({ en = `{name} arrives, {way}`, es = `{name} llega, {way}` })
        else tr({ en = `{name} leaves, {way}`, es = `{name} se va, {way}` })
    keep(short)
    emit("reinos_event", { kind = if came then "arrives" else "leaves", who = name, way = way, target = is_target(name) })
    if came then
        here[name:lower()] = true
    else
        here[name:lower()] = nil
    end
    if is_target(name) then
        line:mute()
        speak(if came
            then { en = `Target here: {name}, {way}!`, es = `¡Objetivo aquí: {name}, {way}!` }
            else { en = `Target leaves: {name}, {way}!`, es = `¡El objetivo se va: {name}, {way}!` },
            { aloud = "cut" })
    elseif mode() == "idle" then
        line:mute()
    elseif tags.enabled("reinos-brief") then
        line:read(short)
    end
end

-- "Orco llega desde el sur.", "Orco llega de el norte seguido de Ana."
trigger([[^(\S+(?: \S+){0,3}) llegan? (?:\S+ )?(?:desde|de) (.+?)(?: seguid[oa]s? de .+)?\.$]], function(m, line)
    if not said(line.text) then
        moved(m[1], way_of(m[2]), true, line)
    end
end, { place = "Reinos de Leyenda/Movement/Arrives" })

-- "Orco se va hacia el norte.", "Orco se va en dirección norte seguido de Ana."
trigger([[^(\S+(?: \S+){0,3}) se van? (?:\S+ )?(?:hacia|en direcci[oó]n(?: a)?) (.+?)(?: seguid[oa]s? de .+)?\.$]], function(m, line)
    if not said(line.text) then
        moved(m[1], way_of(m[2]), false, line)
    end
end, { place = "Reinos de Leyenda/Movement/Leaves" })

---------------------------------------------------------------------------
-- Who is here: "Orco está aquí.", "Ana, Bob y un orco están aquí."

trigger([[^(.+?) est[aá]n? aqu[ií]\.$]], function(m, line)
    if said(line.text) then
        return
    end
    for _, name in corrector.names(m[1]) do
        local key = name:lower()
        if is_target(name) and not here[key] then
            emit("reinos_event", { kind = "target_here", who = name })
            speak({ en = `Target here: {name}!`, es = `¡Objetivo aquí: {name}!` }, { aloud = "cut" })
        end
        here[key] = true
    end
end, { place = "Reinos de Leyenda/Movement/Here" })

-- Another room: who is in it is said again.
on("room", function()
    here = {}
end)

---------------------------------------------------------------------------
-- The target.

-- The first of the nick x, as it is set in the game.
on("send", function(text)
    local list = text:match("^nick x (.+)$")
    if list then
        local first = corrector.names(list)[1]
        if first then
            vars[TARGET] = first
        end
    end
    return nil
end)

alias("^obj$", function()
    local wanted = target()
    speak(if wanted
        then { en = `Target: {wanted}.`, es = `Objetivo: {wanted}.` }
        else { en = "No target.", es = "Sin objetivo." })
end, { place = "Reinos de Leyenda/Movement/Which target" })

alias("^obj (.+)$", function(m)
    local name = corrector.name(m[1])
    vars[TARGET] = name
    speak({ en = `Target: {name}.`, es = `Objetivo: {name}.` })
end, { place = "Reinos de Leyenda/Movement/Target" })

---------------------------------------------------------------------------
-- Reading the moves again.

local function last_move()
    speak(moves[1] or tr({ en = "No one has come or gone yet.", es = "Nadie ha llegado ni se ha ido todavía." }))
end

local function list_moves()
    if #moves == 0 then
        last_move()
        return
    end
    choose(moves, function(_, text)
        if text then
            clipboard.set(text)
            speak({ en = "Copied.", es = "Copiado." })
        end
    end, { title = { en = "Who came and went", es = "Quién llegó y se fue" } })
end

alias("^hmov$", list_moves, { place = "Reinos de Leyenda/Movement/List" })
on("emit", "reinos_moves", function(what)
    if what == "last" then
        last_move()
    elseif what == "list" then
        list_moves()
    end
end)
