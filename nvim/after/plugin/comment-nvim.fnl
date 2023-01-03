(import-macros {: mod-invoke} :helpers)

(fn pre-hook [ctx]
  (let [U (require :Comment.utils)
        tcs-utils (require :ts_context_commentstring.utils)
        location (if (= ctx.ctype U.ctype.block)
                     (tcs-utils.get_cursor_location)
                     (or (= ctx.cmotion U.cmotion.v)
                         (= ctx.cmotion U.cmotion.V))
                     (tcs-utils.get_visual_start_location)
                     nil)
        key (if (= ctx.ctype U.ctype.line) :__default :__multiline)
        tcs-internal (require :ts_context_commentstring.internal)]
    (tcs-internal.calculate_commentstring {: key : location})))

(mod-invoke :Comment :setup {:pre_hook pre-hook :ignore #"^$"})
