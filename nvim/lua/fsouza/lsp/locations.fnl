(import-macros {: mod-invoke} :helpers)

(fn should-use-ts [node]
  (when (= node nil)
    (lua "return false"))
  (let [node-type (node:type)
        node-types [; generic
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
                    :value_definition]]
    (mod-invoke :fsouza.pl.tablex :exists node-types #(= $1 node-type))))

(fn normalize-loc [loc]
  (when (not loc.uri)
    (when loc.targetUri
      (tset loc :uri loc.targetUri))
    (when loc.targetRange
      (tset loc :range loc.targetRange)))
  loc)

(fn ts-range [loc]
  (let [loc (normalize-loc loc)]
    (when (not loc.uri)
      (lua "return loc"))
    (let [parsers (require :nvim-treesitter.parsers)
          lang (parsers.ft_to_lang vim.bo.filetype)]
      (when (or (not lang) (= lang "") (not (parsers.has_parser lang)))
        (lua "return loc"))
      (let [bufnr (vim.uri_to_bufnr loc.uri)
            start-pos loc.range.start
            end-pos loc.range.end]
        (vim.api.nvim_buf_set_option bufnr :buflisted true)
        (vim.api.nvim_buf_set_option bufnr :filetype vim.bo.filetype)
        (let [parser (vim.treesitter.get_parser bufnr lang)
              (_ t) (next (parser:trees))]
          (when (not t)
            (lua "return loc"))
          (let [root (t:root)
                node (root:named_descendant_for_range start-pos.line
                                                      start-pos.character
                                                      end-pos.line
                                                      end-pos.character)
                parent-node (node:parent)]
            (when (should-use-ts parent-node)
              (let [(sl sc el ec) (parent-node:range)]
                (tset loc.range.start :line sl)
                (tset loc.range.start :character sc)
                (tset loc.range.end :line el)
                (tset loc.range.end :character ec)))
            loc))))))

(fn peek-location-callback [_ result]
  (when (and result (not (vim.tbl_isempty result)))
    (let [loc (ts-range (. result 1))]
      (vim.lsp.util.preview_location loc))))

(macro make-lsp-loc-action [method]
  `(fn []
     (let [params# (vim.lsp.util.make_position_params)]
       (vim.lsp.buf_request 0 ,method params# peek-location-callback))))

{:preview-definition (make-lsp-loc-action :textDocument/definition)
 :preview-declaration (make-lsp-loc-action :textDocument/declaration)
 :preview-implementation (make-lsp-loc-action :textDocument/implementation)
 :preview-type-definition (make-lsp-loc-action :textDocument/typeDefinition)}
