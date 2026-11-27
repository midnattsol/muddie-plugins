-- Life, heard: how much was lost or gained as it changes, and a warning as
-- it falls under half, under 30 % and under 10 %, the last cutting in on
-- whatever is being read. The last changes are kept, to read them again
-- with the alias "hvida" (or a key of keys.luau), and to copy one.
--
-- The gauge Vida of the editor shows life and is read with Alt+0; this is
-- what is said of it, so that it can be switched off alone and nothing is
-- said twice: the gauge itself says nothing.
--
-- A hit of more than 200 leaves the experience mode: whatever hits so hard
-- is no prey.

local MOST = 20
local BIG_HIT = 200

-- The last changes, the newest first, each as it is read and copied.
local changes: { string } = {}
-- Life as it was last told: nil until the MUD says it.
local before: number? = nil

local function life(): (number?, number?)
    local status = gmcp.get("Char.Status")
    local points = type(status) == "table" and status.pvs
    if type(points) ~= "table" then
        return nil, nil
    end
    return tonumber(points.min), tonumber(points.max)
end

-- Whether a change is worth saying in the mode there is: none while idle,
-- only losses of a tenth in xp, and a twentieth of life otherwise.
local function worth_saying(change: number, most: number): boolean
    local mode = vars.reinos_mode
    if mode == "idle" then
        return false
    end
    local share = math.abs(change) / math.max(most, 1)
    if mode == "xp" then
        return change < 0 and share >= 0.1
    end
    return share >= 0.05
end

on("gmcp", "Char.Status", function()
    local now, most = life()
    if not now or not most then
        return
    end
    local was = before
    before = now
    if not was or now == was then
        return
    end
    local change = now - was
    local said = if change < 0
        then tr({ en = `Life lost: {-change}.`, es = `Vida perdida: {-change}.` })
        else tr({ en = `Life gained: {change}.`, es = `Vida ganada: {change}.` })
    table.insert(changes, 1, `{said} {now}/{most}`)
    if #changes > MOST then
        table.remove(changes)
    end
    if worth_saying(change, most) then
        speak(said)
    end
    if change <= -BIG_HIT and vars.reinos_mode == "xp" then
        emit("reinos_mode", "combat")
    end
end)

on("disconnect", function()
    before = nil
end)

-- Warnings as life falls, each once until it comes back over it.
on("gauge", "Vida", function()
    speak({ en = "Life under half.", es = "Vida por debajo de la mitad." }, { aloud = "wait" })
end, { under = 50, place = "Reinos de Leyenda/Life/Half" })
on("gauge", "Vida", function()
    speak({ en = "Life low!", es = "¡Vida baja!" }, { aloud = "cut" })
end, { under = 30, place = "Reinos de Leyenda/Life/Low" })
on("gauge", "Vida", function()
    speak({ en = "Life critical!", es = "¡Vida crítica!" }, { aloud = "cut", always = true })
end, { under = 10, place = "Reinos de Leyenda/Life/Critical" })

-- The last change, said; and all of them, to choose one to copy.
local function last_change()
    speak(changes[1] or tr({ en = "No change of life yet.", es = "Aún no ha cambiado la vida." }))
end

local function list_changes()
    if #changes == 0 then
        last_change()
        return
    end
    choose(changes, function(_, text)
        if text then
            clipboard.set(text)
            speak({ en = "Copied.", es = "Copiado." })
        end
    end, { title = { en = "Changes of life", es = "Cambios de vida" } })
end

-- How much life there is now, said.
local function life_now()
    local now, most = life()
    if now and most then
        speak({ en = `Life {now} of {most}.`, es = `Vida {now} de {most}.` })
    end
end

alias("^hvida$", list_changes, { place = "Reinos de Leyenda/Life/List" })
on("emit", "reinos_life", function(what)
    if what == "last" then
        last_change()
    elseif what == "list" then
        list_changes()
    elseif what == "now" then
        life_now()
    end
end)
