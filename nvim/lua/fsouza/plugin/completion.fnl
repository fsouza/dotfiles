(let [cmp (require :cmp)]
  (cmp.setup {:snippet {:expand #(let [luasnip (require :luasnip)]
                                   (luasnip.lsp_expand $1.body))}
              :mapping {:<c-y> (cmp.mapping.confirm {:behavior cmp.ConfirmBehavior.Replace
                                                     :select true})
                        :<c-b> (cmp.mapping (cmp.mapping.scroll_docs -4) [:i])
                        :<c-f> (cmp.mapping (cmp.mapping.scroll_docs +4) [:i])
                        :<c-x><c-o> (cmp.mapping (cmp.mapping.complete) [:i])}
              :sources (cmp.config.sources [{:name "nvim_lsp"}
                                            {:name "buffer"
                                             :keyword_length 5
                                             :option {:keyword_length 5}}])
              :formatting {:format (fn [entry vim-item]
                                     (let [menu (if (= entry.source.name "nvim_lsp")
                                                  "LSP"
                                                  entry.source.name)]
                                       (tset vim-item :menu (string.format "「%s」" menu))
                                       vim-item))}
              :preselect cmp.PreselectMode.None
              :experimental {:native_menu true}}))
