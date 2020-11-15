-- globals that are available in all tl modules.

local type Hl = record
    fg: string
    bg: string
    link: string
    bold: boolean
    reverse: boolean
    underline: boolean
end

local type DecorationCallbacks = record
    on_win: function(string, number, number)
    on_line: function(string, number, number)
    on_buf: function(string, number)
end

local type VimAPI = record
    nvim_input: function(string)
    nvim_create_namespace: function(string): number
    nvim_win_is_valid: function(number): boolean

    nvim_set_hl: function(number, string, Hl)
    nvim_set_hl_ns: function(number)
    nvim_set_decoration_provider: function(number, DecorationCallbacks)
end

local type VimFn = record
    expand: function(string): string
end

local type GlobalVimOptions = record
    background: string
end

local type Vim = record
    api: VimAPI
    fn: VimFn
    o: GlobalVimOptions
    schedule: function(function())
end

global vim: Vim
