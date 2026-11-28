-- What is said around the character, kept to read again: what is said in
-- the room, the tells received, and what happens that matters in a fight
-- (who attacks you, who is found hiding, who comes into or leaves your
-- group, who falls). Each list is opened with an alias, or a key of
-- keys.luau, to go through it and copy one; it lasts the session.
--
--   hsala       what was said in the room
--   htels       the tells received
--   heventos    what happened
--   r texto     replies by telepathy to whoever told you last
--   rt          chooses whom "r" replies to, among those who told you
--
-- What is said in the room and the tells are read shorter in the modes
-- that shorten, and not at all while idle: they are kept all the same.

local corrector = require("corrector")

local MOST = 50

local room: { string } = {}
local tells: { string } = {}
local events: { string } = {}
-- Who told you something, the last first, and whom "r" replies to.
local senders: { string } = {}
local reply_to: string? = nil

local function keep(list: { string }, text: string)
    table.insert(list, 1, text)
    if #list > MOST then
        table.remove(list)
    end
end

local function mode(): string
    return if type(vars.reinos_mode) == "string" then vars.reinos_mode else "combat"
end

-- Whether a line is what someone says on a channel, which is not of the
-- room: those begin with the channel between brackets.
local function of_a_channel(text: string): boolean
    return text:match("^%[") ~= nil
end

---------------------------------------------------------------------------
-- Tells: "Ana te dice: hola", and the same exclaimed or asked; those of
-- while you were away, "... - Ana te dijo: hola".

trigger([[^(?:.* - )?(\S+) te (dice|exclama|pregunta|dijo): (.+)$]], function(m, line)
    if of_a_channel(line.text) then
        return
    end
    local who = corrector.name(m[1])
    local said = corrector.text(m[3])
    keep(tells, `{who}: {said}`)
    emit("reinos_event", { kind = "tell", who = who })
    reply_to = who
    for index, known in senders do
        if known == who then
            table.remove(senders, index)
            break
        end
    end
    table.insert(senders, 1, who)
    if mode() == "idle" then
        line:mute()
    elseif tags.enabled("reinos-brief") then
        line:read(tr({ en = `Tell from {who}: {said}`, es = `Telepatía de {who}: {said}` }))
    end
end, { place = "Reinos de Leyenda/History/Tells" })

---------------------------------------------------------------------------
-- The room: "Ana dice en común: hola", "Ana pregunta: ¿sí?", whispered and
-- the like. Tells and channels are not of it.

trigger([[^(\S+(?: \S+)?) (dice|pregunta|exclama|susurra|responde|balbucea|ordena)[^:]*: (.+)$]], function(m, line)
    if of_a_channel(line.text) or line.text:match(" te %a+: ") then
        return
    end
    local who = corrector.name(m[1])
    local said = corrector.text(m[3])
    keep(room, `{who}: {said}`)
    emit("reinos_event", { kind = "room", who = who })
    if mode() == "idle" then
        line:mute()
    elseif tags.enabled("reinos-brief") then
        line:read(`{who}: {said}`)
    end
end, { place = "Reinos de Leyenda/History/Room" })

---------------------------------------------------------------------------
-- What happens that matters, kept as the game says it.

-- Each with what kind of thing it is, told to who listens (sounds.luau).
local EVENTS = {
    { [[^Est[aá]s siendo atacad[oa] por (.+?)\.?$]], "attacked" },
    { [[^¡?Descubres a .+ intentando moverse en silencio!?$]], "found" },
    { [[^.+ descubre a .+ intentando moverse en silencio!?$]], "found" },
    { [[^\[Grupo\] .+ (?:se une al|abandona el) grupo\.$]], "group" },
    { [[^\[Grupo\] .+ es expulsad[oa] del grupo\.$]], "group" },
    { [[^\[Grupo\] (?:Te unes al|Abandonas el) grupo liderado por .+$]], "group" },
    { [[^Propinas el golpe mortal a .+$]], "kill" },
    { [[^.+ propina el golpe mortal a .+$]], "death" },
}

for _, event in EVENTS do
    local pattern, kind = event[1], event[2]
    trigger(pattern, function(_, line)
        keep(events, corrector.text(line.text))
        emit("reinos_event", { kind = kind })
    end, { place = "Reinos de Leyenda/History/Events" })
end

-- Gaining experience, what tells of each kill and of the experience is not
-- read: it is in the output all the same.
local XP_QUIET = {
    [=[^\[Obtienes .+ puntos de experiencia\]]=],
    [[^Propinas el golpe mortal a ]],
    [[^.+ cae al suelo sin vida\.$]],
}

for _, pattern in XP_QUIET do
    trigger(pattern, function(_, line)
        if mode() == "xp" then
            line:mute()
        end
    end, { place = "Reinos de Leyenda/History/Quiet in xp" })
end

-- Attacked while idle: back to combat.
trigger([[^Est[aá]s siendo atacad[oa] por ]], function()
    if mode() == "idle" then
        emit("reinos_mode", "combat")
    end
end, { place = "Reinos de Leyenda/History/Attacked" })

---------------------------------------------------------------------------
-- Reading them again.

local LISTS = {
    room = { list = room, title = { en = "Said in the room", es = "Dicho en la sala" } },
    tells = { list = tells, title = { en = "Tells", es = "Telepatías" } },
    events = { list = events, title = { en = "What happened", es = "Lo que ha pasado" } },
}

local function nothing()
    speak({ en = "Nothing yet.", es = "Nada todavía." })
end

-- The last of a list, said.
local function last(name: string)
    local list = LISTS[name] and LISTS[name].list
    if list and list[1] then
        speak(list[1])
    else
        nothing()
    end
end

-- A list, to go through, and copy what is chosen.
local function open(name: string)
    local of = LISTS[name]
    if not of or #of.list == 0 then
        nothing()
        return
    end
    choose(of.list, function(_, text)
        if text then
            clipboard.set(text)
            emit("reinos_event", { kind = "copied" })
            speak({ en = "Copied.", es = "Copiado." })
        end
    end, { title = of.title })
end

alias("^hsala$", function()
    open("room")
end, { place = "Reinos de Leyenda/History/List room" })
alias("^htels$", function()
    open("tells")
end, { place = "Reinos de Leyenda/History/List tells" })
alias("^heventos$", function()
    open("events")
end, { place = "Reinos de Leyenda/History/List events" })

---------------------------------------------------------------------------
-- Replying by telepathy.

local function no_one()
    speak({ en = "No one has told you anything yet.", es = "Nadie te ha mandado telepatías todavía." })
end

alias("^r (.+)$", function(m)
    if not reply_to then
        no_one()
        return
    end
    send(`telepatia {reply_to} {m[1]}`)
end, { place = "Reinos de Leyenda/History/Reply" })

local function choose_reply()
    if #senders == 0 then
        no_one()
        return
    end
    choose(senders, function(_, who)
        if who then
            reply_to = who
            speak({ en = `Replying to {who}.`, es = `Respondes a {who}.` })
        end
    end, { title = { en = "Reply to", es = "Responder a" } })
end

alias("^rt$", choose_reply, { place = "Reinos de Leyenda/History/Reply to" })

on("emit", "reinos_history", function(what)
    if what == "reply_to" then
        choose_reply()
    elseif what == "who" then
        if reply_to then
            speak({ en = `Replying to {reply_to}.`, es = `Respondes a {reply_to}.` })
        else
            no_one()
        end
    elseif type(what) == "table" and what.last then
        last(what.last)
    elseif type(what) == "table" and what.open then
        open(what.open)
    end
end)
