(fn should-use-ts [node]
  (if (= node nil)
      false
      (let [node-type (node:type)
            node-types (vim.iter [; generic
                                  :local_function
                                  :function_declaration
                                  :method_declaration
                                  :type_spec
                                  :assignment
                                  ; typescript
                                  :class
                                  :function
                                  :type_alias_declaration
                                  :interface_declaration
                                  :method_definition
                                  :variable_declarator
                                  :public_field_definition
                                  ; python
                                  :class_definition
                                  :function_definition
                                  ; go
                                  :var_spec
                                  ; ocaml
                                  :let_binding
                                  :value_definition
                                  :type_definition
                                  ; java
                                  :class_declaration])]
        (node-types:any #(= $1 node-type)))))

(fn normalize-loc [loc]
  (when (not loc.uri)
    (when loc.targetUri
      (tset loc :uri loc.targetUri))
    (when loc.targetRange
      (tset loc :range loc.targetRange)))
  loc)

(fn ts-range [current-buf loc]
  (let [loc (normalize-loc loc)]
    (if (not loc.uri)
        loc
        (let [parsers (require :nvim-treesitter.parsers)
              filetype (. vim :bo current-buf :filetype)
              lang (parsers.ft_to_lang filetype)]
          (if (or (not lang) (= lang "") (not (parsers.has_parser lang)))
              loc
              (let [bufnr (vim.uri_to_bufnr loc.uri)
                    start-pos loc.range.start
                    end-pos loc.range.end]
                (tset (. vim :bo bufnr) :buflisted true)
                (tset (. vim :bo bufnr) :filetype filetype)
                (let [parser (vim.treesitter.get_parser bufnr lang)
                      (_ t) (next (parser:trees))]
                  (if (not t)
                      loc
                      (let [root (t:root)
                            node (root:named_descendant_for_range start-pos.line
                                                                  start-pos.character
                                                                  end-pos.line
                                                                  end-pos.character)
                            parent-node (node:parent)
                            ts-node (if (should-use-ts parent-node) parent-node
                                        (should-use-ts node) node)]
                        (when ts-node
                          (let [(sl sc el ec) (ts-node:range)]
                            (tset loc.range.start :line sl)
                            (tset loc.range.start :character sc)
                            (tset loc.range.end :line el)
                            (tset loc.range.end :character ec)))
                        loc)))))))))

(fn peek-location-callback [_ result context]
  (when result
    (let [loc (if (vim.islist result)
                  (. result 1)
                  result)
          loc (ts-range context.bufnr loc)
          (_ winid) (vim.lsp.util.preview_location loc)
          popup (require :fsouza.lib.popup)]
      (popup.stylize winid))))

(macro make-lsp-loc-action [method]
  `(fn []
     (let [params# (vim.lsp.util.make_position_params)]
       (vim.lsp.buf_request 0 ,method params# peek-location-callback))))

{:preview-definition (make-lsp-loc-action :textDocument/definition)
 :preview-declaration (make-lsp-loc-action :textDocument/declaration)
 :preview-implementation (make-lsp-loc-action :textDocument/implementation)
 :preview-type-definition (make-lsp-loc-action :textDocument/typeDefinition)}
