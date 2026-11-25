-- What is said aloud of Reinos de Leyenda, apart from what the gauges say by
-- themselves, which each says in the editor. It can be switched off alone,
-- among the scripts: what is shown stays. It goes by what the MUD sends, not
-- by what is shown of it, so it says the same whatever gauges and panels there
-- are.
--
-- What it says is in the language of the interface, English or Spanish.

local prompt = require("prompt")

---------------------------------------------------------------------------
-- The prompt is not read: what is in it is said by the gauges as it runs low,
-- and read with Alt+0. What comes after it on its line is.

trigger("", function(_, line)
    local rest = prompt.rest(line.text)
    if rest == "" then
        line:mute()
    elseif rest then
        line:read(rest)
    end
end, { place = "Reinos de Leyenda/Prompt aloud" })

-- Once in the game, one that is not known is told of, once: the player has
-- only to make it again.
local playing = false
on("gmcp", "Char", function()
    playing = true
end)
on("disconnect", function()
    playing = false
end)

trigger("\\S", function(_, line)
    if playing and not vars.reinos_prompt_told and not prompt.is_known() and not prompt.rest(line.text) then
        vars.reinos_prompt_told = true
        notify({
            en = "Your prompt is read each time. For it not to be, make it again in the game: prompt, and promptcombate for that of a fight.",
            es = "Se te lee el prompt cada vez. Para que no, defínelo otra vez en el juego: prompt, y promptcombate para el de combate.",
        })
    end
end, { place = "Reinos de Leyenda/Prompt not known", prompt = true })

---------------------------------------------------------------------------
-- States: of those the character is in, only what changes: the name of one
-- that comes, and that one is gone.

-- The name of each state the character is in, by what it is known by; nil
-- until the MUD says which: those there are on logging in are not news.
local known = nil

-- What a state is known by, and its name. A state is {nombre, corto, tipo,
-- ayuda}, or its name alone.
local function named(state)
    if type(state) == "table" then
        local id = state.nombre or state.name or ""
        return id, state.corto or id
    end
    local id = tostring(state or "")
    return id, id
end

local function came(name)
    speak(`{name}.`)
end

local function went(name)
    speak({ en = `No longer: {name}.`, es = `Ya no: {name}.` })
end

on("gmcp", "Char.Status.Estados.set", function(data)
    local now = {}
    if type(data) == "table" then
        for key, state in pairs(data) do
            local id, name = named(type(state) == "table" and state or key)
            now[id] = name
        end
    end
    local before = known
    known = now
    if not before then
        return
    end
    for id, name in pairs(now) do
        if not before[id] then
            came(name)
        end
    end
    for id, name in pairs(before) do
        if not now[id] then
            went(name)
        end
    end
end)

on("gmcp", "Char.Status.Estados.add", function(state)
    local id, name = named(state)
    known = known or {}
    if not known[id] then
        came(name)
    end
    known[id] = name
end)

on("gmcp", "Char.Status.Estados.remove", function(state)
    local id = named(state)
    local name = known and known[id]
    if name then
        known[id] = nil
        went(name)
    end
end)

on("disconnect", function()
    known = nil
end)
