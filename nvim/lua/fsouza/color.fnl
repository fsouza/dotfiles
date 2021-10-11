(import-macros {: if-nil} :helpers)

(local helpers (require :fsouza.lib.nvim-helpers))
(local themes (require :fsouza.themes))

(fn set-popup-winid [state winid]
  (when (. state :enabled)
    (tset (. state :themes) winid (. themes :popup))))

(fn gc [state]
  (each [_ winid (ipairs (. state :themes))]
    (when (not (vim.api.nvim_win_is_valid winid))
      (tset (. state :themes) winid nil))))

(fn start-gc-timer [state interval-ms]
  (let [timer (if-nil (. state :timer) (vim.loop.new_timer))]
    (tset state :timer timer)
    (timer:start interval-ms interval-ms (vim.schedule_wrap (partial gc state)))))

(fn stop-gc-timer [state]
  (when (. state :timer)
    (state.timer:close)))

(fn setup-autocmd [mod autogroup-name]
  (helpers.augroup
    autogroup-name
    [{
      :events ["ColorScheme"]
      :targets ["*"]
      :modifiers ["++once"]
      :command (helpers.fn-cmd mod.disable)}]))

(fn disable-autocmd [autogroup-name]
  (helpers.augroup autogroup-name []))

(fn enable [state]
  (tset vim.o :background "light")
  (tset state :enabled true)
  (tset state :default-theme themes.none)
  (when (not state.ns)
    (fn decoration-cb [_ winid]
      (when (. state :enabled)
        (let [theme (if-nil (. state.themes winid) state.default-theme)]
          (vim.api.nvim__set_hl_ns theme))))
    (tset state :ns (vim.api.nvim_create_namespace "fsouza__color"))
    (vim.api.nvim_set_decoration_provider state.ns { :on_win decoration-cb :on_line decoration-cb })))

(let [state {:enabled false
             :default-theme nil
             :themes {}
             :ns nil
             :timer nil}
      autogroup-name "fsouza__colors_auto_disable"
      gc-interval-ms 5000
      mod {:set-popup-winid (partial set-popup-winid state)}]
  (tset mod :enable (fn []
                     (enable state)
                     (start-gc-timer state gc-interval-ms)
                     (setup-autocmd mod autogroup-name)))
  (tset mod :disable (fn []
                      (tset state :enabled false)
                      (tset state :themes {})
                      (stop-gc-timer state)
                      (vim.api.nvim__set_hl_ns 0)
                      (disable-autocmd autogroup-name)))
  mod)
