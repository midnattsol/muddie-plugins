-- What scripts are given by Muddie, for an editor that checks Luau, such as one
-- with luau-lsp: give it this file as a definitions file. What each does is in
-- scripting.md.

-- What is switched: by its place, "Folder/Name", and by its tags.
type Switched = { place: string?, tags: (string | { string })? }

-- How something is heard.
type Aloud = "usual" | "never" | "wait" | "cut"
type Heard = { aloud: Aloud?, always: boolean? }

-- A text, or the texts by language: { en = "Hello", es = "Hola" }.
type Texts = { [string]: string }

-- What a script makes.
type Made = {
    enable: (self: Made) -> boolean,
    disable: (self: Made) -> boolean,
    toggle: (self: Made) -> boolean,
    enabled: (self: Made) -> boolean,
    remove: (self: Made) -> boolean,
    left: (self: Made) -> number?,
}

-- The groups of a pattern: by number, from 0, the whole match, and by name.
type Groups = { [number | string]: string }

type Colour = string | number
type Span = {
    text: string,
    fg: Colour?,
    bg: Colour?,
    bold: boolean,
    italic: boolean,
    underline: boolean,
    inverse: boolean,
}

-- The line a trigger is looking at.
type Line = {
    read text: string,
    read prompt: boolean,
    read spans: { Span },
    hide: (self: Line) -> (),
    mute: (self: Line) -> (),
    read: (self: Line, text: string, options: Heard?) -> (),
    replace: (self: Line, text: string) -> boolean,
    paint: (self: Line, fg: Colour?, bg: Colour?) -> (),
    link: (self: Line, command: string, options: { hint: string? }?) -> boolean,
    to_panel: (self: Line, name: string) -> (),
}

-- Sending, showing and saying.
declare function send(text: string): ()
declare function echo(text: string | Texts, options: Heard?): ()
declare function speak(text: string | Texts, options: Heard?): ()
declare function notify(text: string | Texts, options: { aloud: Aloud? }?): ()
declare function log(text: string): ()
declare function hush(): ()
declare function tr(texts: Texts): string
declare function expand(text: string): string

-- Triggers, aliases, keys and timers.
type TriggerOptions = {
    place: string?,
    tags: (string | { string })?,
    once: boolean?,
    prompt: boolean?,
}
type AliasOptions = { place: string?, tags: (string | { string })?, once: boolean? }
declare function trigger(pattern: string, fn: (m: Groups, line: Line) -> (), options: TriggerOptions?): Made
declare function alias(pattern: string, fn: (m: Groups, input: string) -> (), options: AliasOptions?): Made
declare function macro(key: string, action: string | () -> (), options: Switched?): Made
declare function after(seconds: number, fn: () -> (), options: Switched?): Made
declare function every(seconds: number, fn: () -> (), options: Switched?): Made

-- Waiting.
type Lines = { till: string?, count: number?, timeout: number? }
declare wait: ((seconds: number) -> ())
    & ((what: "line", pattern: string, options: { timeout: number?, prompt: boolean? }?) -> (Groups?, Line))
    & ((what: string, options: { [string]: any }?) -> ...any)
    & ((what: string, name: string, options: { [string]: any }?) -> ...any)
declare function lines(options: Lines): () -> Line?

-- Listening. A name, where it takes one; the function; and the options, which
-- are those of a gauge, or where it is switched. The function is given:
--   gmcp, msdp, var, emit    the data and the name
--   gauge                    a Gauge and a Change
--   channel                  a Message
--   send                     the text; what it returns is sent instead
--   room                     the Room the player is now in, and the id before
--   the others               their data, and what they are
type Change = { was: Gauge, came: { Effect }, gone: { Effect } }
type Message = { channel: string, text: string }
type Listened = "gmcp" | "msdp" | "var" | "emit" | "gauge" | "channel" | "send" | "room" | "connect" | "disconnect" | "focus" | "reader" | "panel" | "mxp"
type Handler = (...any) -> ...any
type Listening = { under: number?, over: number?, place: string?, tags: (string | { string })? }
declare function on(what: Listened, name: string | Handler, fn: (Handler | Listening)?, options: Listening?): Made
declare function emit(name: string, data: any): ()

-- What the MUD sends besides text.
type Gmcp = {
    get: (package: string) -> any,
    send: (package: string, data: any) -> (),
    merge: (...string) -> (),
    support: (...string) -> (),
}
type Msdp = {
    get: (variable: string) -> any,
    send: (command: string, ...string) -> (),
    report: (...string) -> (),
}
type Mssp = { get: () -> { [string]: string } }
declare gmcp: Gmcp
declare msdp: Msdp
declare mssp: Mssp

-- Gauges. Their switches are those of every kind.
type Effect = { name: string, about: string?, colour: string? }
type Gauge = {
    name: string,
    place: string?,
    kind: "bar" | "cells" | "number" | "light" | "text" | "effects",
    value: number?,
    max: number?,
    percent: number?,
    on: boolean?,
    text: string?,
    items: { Effect }?,
}
type GaugeSet = {
    value: number?,
    on: boolean?,
    max: number?,
    kind: string?,
    colour: string?,
    off_colour: string?,
    text: string?,
    steps: { { under: number, colour: string } }?,
    items: { [any]: any }?,
    aloud: (Aloud | "lowest")?,
    always: boolean?,
    panel: string?,
    place: string?,
    tags: (string | { string })?,
}
type Gauges = {
    set: (name: string, gauge: GaugeSet) -> (),
    get: (name: string) -> Gauge?,
    all: () -> { Gauge },
    remove: (name: string, options: Switched?) -> (),
    enable: (place: string) -> (),
    disable: (place: string) -> (),
    toggle: (place: string) -> boolean,
    enabled: (place: string) -> boolean,
    list: () -> { string },
}
declare gauges: Gauges

-- Switching what there is of a kind, by its place.
type Kind = {
    enable: (place: string) -> (),
    disable: (place: string) -> (),
    toggle: (place: string) -> boolean,
    enabled: (place: string) -> boolean,
    list: () -> { string },
}
declare triggers: Kind
declare aliases: Kind
declare macros: Kind
declare timers: Kind
declare scripts: Kind
declare tags: Kind

-- Panels, channels and sounds.
type Panels = {
    set: (name: string, text: string) -> (),
    add: (name: string, text: string, options: Heard?) -> (),
    clear: (name: string) -> (),
    size: (name: string?) -> { columns: number, rows: number }?,
}
type Channels = {
    say: (name: string, text: string, options: { panel: string?, aloud: Aloud?, always: boolean? }?) -> (),
    open: (name: string, options: { panel: string? }?) -> (),
    close: (name: string) -> (),
    all: () -> { string },
}
type Sound = { stop: (self: Sound) -> (), playing: (self: Sound) -> boolean }
type SoundOptions = {
    volume: number?,
    loop: boolean?,
    start: number?,
    finish: number?,
    fade_in: number?,
    fade_out: number?,
}
type Sounds = { play: (file: string, options: SoundOptions?) -> Sound, stop: () -> () }
declare panels: Panels
declare channels: Channels
declare sounds: Sounds
declare output: { last: (count: number?) -> { string } }

-- A list to choose from, and the clipboard.
type Choosable = string | { text: string | Texts, about: (string | Texts)? }
declare function choose(items: { Choosable }, fn: (index: number?, text: string?) -> (), options: { title: (string | Texts)? }?): ()
declare clipboard: { set: (text: string) -> (), get: () -> string? }

-- The session, and what is kept in it.
type Session = {
    read connected: boolean,
    read host: string,
    read profile: string?,
    read reader: boolean,
    read focused: boolean,
    separator: any,
    input: string?,
    reading: boolean,
    completions: (name: string, words: { string }?) -> (),
    feed: (text: string) -> (),
}
declare session: Session
declare vars: { [string]: any }

-- Muddie's shortcuts, by name: read, a list of keys; set, a key, a list of
-- keys, false for none, or nil for those it had.
type Shortcut = { name: string, place: string, about: string, keys: { string } }
declare shortcuts: { all: () -> { Shortcut }, [string]: any }

-- The map. A place is a room's number, or a mark or a name.
type Place = number | string
type Room = {
    id: number,
    name: string,
    area: string,
    x: number,
    y: number,
    z: number,
    cost: number,
    avoid: boolean,
    colour: string?,
    note: string,
    renamed: boolean,
    added: boolean,
    shape: string?,
    symbol: string,
    exits: { [string]: number },
}
type Seen = { name: string?, exits: { string }?, came: string? }
type Exit = { to: number, cost: number, blocked: boolean, command: string?, custom: boolean }
type Drawing = { wrong_exits: number, stacked: number }
type MapTable = {
    native: boolean?,
    persist: boolean?,
    learn: boolean?,
    language: string?,
    directions: { [string]: string | { string } }?,
    names: { region: string?, exits: string? }?,
    visit: (room: { [string]: any }) -> number,
    set_room: (room: { [string]: any }) -> number,
    arrive: (seen: Seen) -> number?,
    add: (seen: Seen) -> (number?, string),
    here: (room: Place) -> boolean,
    candidates: () -> { number },
    clear: () -> (),
    room: (room: Place?) -> Room?,
    find: (text: string, options: { exact: boolean? }?) -> { number },
    way: (to: Place, from: Place?) -> { string }?,
    go: (to: Place) -> (),
    stop: () -> (),
    failed: () -> (),
    import: (address: string) -> (),
    newer: (address: string, fn: () -> ()) -> (),
    action: (name: string | Texts, fn: ((on: boolean) -> ())?, options: { checked: boolean? }?) -> (),
    count: () -> number,
    exit: (from: Place, direction: string) -> Exit?,
    set_exit: (
        from: Place,
        direction: string,
        to: Place?,
        options: { cost: number?, blocked: boolean?, command: string? }?
    ) -> boolean,
    remove_exit: (from: Place, direction: string) -> boolean,
    remove_room: (room: Place) -> boolean,
    edit_room: (room: Place, changes: { [string]: any }) -> boolean,
    direction: (word: string) -> string?,
    marks: () -> { [string]: number },
    mark: (name: string, room: Place?) -> boolean,
    areas: () -> { string },
    id: (text: string) -> number,
    tidy: (area: string?) -> (number, { now: Drawing, ["then"]: Drawing }?),
    undo: () -> boolean,
    show_area: (area: string) -> (),
}
declare map: MapTable
