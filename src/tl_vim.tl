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
    nvim_buf_get_lines: function(number, number, number, boolean): {string}
    nvim_buf_line_count: function(number): number
    nvim_buf_set_keymap: function(number, string, string, string, {string:boolean})
    nvim_create_namespace: function(string): number
    nvim_input: function(string)
    nvim_replace_termcodes: function(string, boolean, boolean, boolean): string
    nvim_set_decoration_provider: function(number, DecorationCallbacks)
    nvim_set_hl: function(number, string, Hl)
    nvim_set_hl_ns: function(number)
    nvim_set_keymap: function(string, string, string, {string:boolean})
    nvim_win_get_cursor: function(number): {number}
    nvim_win_is_valid: function(number): boolean
    nvim_win_set_cursor: function(number, {number})
    nvim_call_function: function(string, {any}): any
end

global type VimCompInfo = record
    mode: string
    pum_visible: number
    selected: number
end

local type VimFn = record
    expand: function(string): string
    complete_info: function(): VimCompInfo
end

local type VimGlobalOptions = record
    background: string
end

global type LoopStat = record
    type: string
end

local type VimLoop = record
    fs_stat: function(string, function(string, LoopStat))
end

local type Vim = record
    api: VimAPI
    cmd: function(string)
    endswith: function(string, string): boolean
    fn: VimFn
    o: VimGlobalOptions
    g: {string:any}
    schedule: function(function())
    startswith: function(string, string): boolean
    loop: VimLoop
end

global vim: Vim
