-- What is read aloud of Reinos de Leyenda to who listens to the game: here,
-- and only here, apart from what the gauges say by themselves, which each
-- says in the editor. It says nothing when nothing is read aloud, and it can
-- be switched off alone, among the scripts: what is shown stays.
--
-- What it says is in the language of the interface, English or Spanish,
-- each text given in both with tr.

---------------------------------------------------------------------------
-- States: of those the character is in, only what changes: the name of one
-- that comes, and that one is gone. The gauge Efectos shows them all, and
-- says what each is where it is.

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
    speak(tr({ en = `No longer: {name}.`, es = `Ya no: {name}.` }))
end

on_gmcp("Char.Status.Estados.set", function(data)
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

on_gmcp("Char.Status.Estados.add", function(state)
    local id, name = named(state)
    known = known or {}
    if not known[id] then
        came(name)
    end
    known[id] = name
end)

on_gmcp("Char.Status.Estados.remove", function(state)
    local id = named(state)
    local name = known and known[id]
    if name then
        known[id] = nil
        went(name)
    end
end)

on_event("disconnect", function()
    known = nil
end)
