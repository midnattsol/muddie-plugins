-- What is read aloud of what players write, made easier to listen to: the
-- signs that a voice reads one by one, or that say nothing heard, are taken
-- out, and the race after a name, as "Orome (Hum)". It changes only what is
-- read, never what is shown.
--
--   local corrector = require("corrector")
--   corrector.text("**Hola!!** :)")    -- "Hola!!"
--   corrector.name("Orome (Hum)")      -- "Orome"
--
-- A module: it makes nothing, it only returns what it has.

local corrector = {}

-- Signs that are noise read aloud, and what each becomes.
local SIGNS = {
    ["%*"] = "",
    ["%^"] = "",
    ["|"] = "",
    ["¨"] = "",
    ["·"] = "",
    ["~"] = "",
    ["_"] = " ",
    ["%[%s*"] = "",
    ["%s*%]"] = "",
    ["%-=%("] = "",
    ["%)=%-"] = "",
    ['"'] = "",
}

-- What a player writes, as it is better read: signs out, repeated ones
-- once, and spaces tidied.
function corrector.text(text: string): string
    local read = text
    for sign, instead in SIGNS do
        read = read:gsub(sign, instead)
    end
    -- "!!!!" and "...." are read once.
    for _, sign in { "!", "?", ".", "," } do
        read = read:gsub(`%{sign}%{sign}+`, sign)
    end
    -- Faces made of signs, as :) or :-(, say nothing.
    read = read:gsub("[:;]%-?[%)%(DPp]", "")
    read = read:gsub("%s+", " ")
    return (read:match("^%s*(.-)%s*$") or read)
end

-- A name as it is better read: without the race after it, in brackets,
-- nor signs around it.
function corrector.name(name: string): string
    local read = name:gsub("%s*%(%a+%.?%)%s*$", "")
    read = read:gsub("^[%[%]%*>%-/\\+|%s]+", ""):gsub("[%[%]%*>%-/\\+|%s]+$", "")
    return read
end

-- Names one after another, as the game writes them: "Ana, Bob y Ciro".
function corrector.names(list: string): { string }
    local names = {}
    local spaced = list:gsub(" y ", ", ")
    for part in spaced:gmatch("[^,]+") do
        local name = corrector.name(part)
        if name ~= "" then
            table.insert(names, name)
        end
    end
    return names
end

return corrector
