-- The player's prompts, the usual one and that of a fight, as each made them:
-- what tells them from what the game writes after them, on the same line.
-- They are learned as the game says them (see reinos.luau), and kept.
--
--   local prompt = require("prompt")
--   prompt.learn(true, "Pv:$v Pe:$g>")    -- that of a fight; false, the usual
--   prompt.rest("Pv:90 Pe:50> Un orco.")  -- "Un orco."; nil, if it has none

local prompt = {}

-- Where each is kept.
local KEPT = { [true] = "reinos_fight_prompt", [false] = "reinos_prompt" }

-- What ends every prompt: ">", or another as the character can do less, as "}"
-- while an action can be given up.
local ENDS = "[>%]}]"

-- What is in the place of each code: a number, the exits, or a few words.
local NUMBER = "%-?%d[%d%.]*"
local EXITS = "%s*%[?[%a|,%-]*%]?"
local WORDS = ".-"
local CODES = {
    v = NUMBER,
    V = NUMBER,
    g = NUMBER,
    G = NUMBER,
    x = NUMBER,
    e = NUMBER,
    n = NUMBER,
    t = NUMBER,
    p = NUMBER,
    AM = NUMBER,
    AP = NUMBER,
    AS = NUMBER,
    AZ = NUMBER,
    s = EXITS,
}

-- The pattern of one line of a prompt, and whether it has enough to be told by.
local function pattern_of(line)
    local pattern, telling = "", false
    local at = 1
    while at <= #line do
        local code = line:match("^%$(A[MPSZ])", at) or line:match("^%$(%a)", at)
        if code then
            local what = CODES[code] or WORDS
            telling = telling or what == NUMBER
            pattern ..= what
            at += #code + 1
        else
            local char = line:sub(at, at)
            telling = telling or char:match("[%a:]") ~= nil
            pattern ..= char:gsub("%p", "%%%0")
            at += 1
        end
    end
    return pattern, telling
end

-- A prompt as the game says it, made ready: the patterns of its lines, the
-- last with what comes after it. None, if it has nothing to be told by.
local function made(template)
    local body = template:gsub(ENDS .. "%s*$", "")
    local ready = {}
    local lines = body:split("$l")
    for index, line in lines do
        local pattern, telling = pattern_of(line)
        if index < #lines then
            if telling then
                table.insert(ready, { whole = `^{pattern}%s*$` })
            end
        elseif telling or line == "" then
            table.insert(ready, { before = `^{pattern}{ENDS}%s+(.*)$`, alone = `^{pattern}{ENDS}%s*$` })
        end
    end
    return ready
end

-- Those made, by what they were made of.
local ready = {}
local function known()
    local all = {}
    for _, name in KEPT do
        local template = vars[name]
        if type(template) == "string" then
            ready[template] = ready[template] or made(template)
            table.move(ready[template], 1, #ready[template], #all + 1, all)
        end
    end
    -- The one who made none has.
    ready[">"] = ready[">"] or made(">")
    table.move(ready[">"], 1, #ready[">"], #all + 1, all)
    return all
end

function prompt.learn(fight, template)
    vars[KEPT[fight]] = template
end

-- Whether the player's is known.
function prompt.is_known()
    return vars[KEPT[false]] ~= nil
end

-- What is after the prompt on a line: "" if there is nothing, nil if the line
-- has no prompt. There may be several, one after another, when much comes.
function prompt.rest(line)
    local rest = nil
    local left = line
    while true do
        local found = nil
        for _, one in known() do
            if left:match(one.whole or one.alone) then
                return ""
            end
            found = one.before and left:match(one.before)
            if found then
                break
            end
        end
        if not found then
            return rest
        end
        rest, left = found, found
    end
end

return prompt
