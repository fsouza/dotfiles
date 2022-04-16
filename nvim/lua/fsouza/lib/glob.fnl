;; This library provides two functions: `compile`, that compiles a given glob
;; into an internal representation that can be used later for matches, and
;; `match` that takes a compiled glob and a filepath as a string and returns a
;; boolean indicating whether or not the path matches the given glob.

(fn escape-literal [literal]
  (let [special-chars {"\\" true
                       :^ true
                       :$ true
                       :. true
                       :* true
                       "(" true
                       ")" true}
        (literal _) (string.gsub literal "."
                                 #(if (. special-chars $1)
                                      (.. "\\" $1)
                                      $1))]
    literal))

(fn make-special [value]
  {:type :special : value})

(fn make-literal [value is-literal]
  {:type :literal : value : is-literal})

(fn startswith [str prefix]
  (= (string.sub str 1 (length prefix)) prefix))

(fn get-node-type [v]
  (if v.type v.type
      (= (type v) :table) :tree
      (error (string.format "not a node: %s" v))))

(fn is-group [v]
  (if (not= (get-node-type v) :tree) false
      (let [first-node (. v 1)]
        (and (= first-node.type :special) (= first-node.value "{")))))

(fn split-group [group]
  ;; split the group into sub-trees. Maybe I should fix the grammar so this
  ;; happens automatically?
  (let [output []]
    (each [_ node (ipairs group)]
      (if (= node.type :special)
          (if (or (= node.value "{") (= node.value ","))
              (table.insert output [])
              (not= node.value "}")
              (table.insert (. output (length output)) node))
          (table.insert (. output (length output)) node)))
    output))

(fn compile-to-regex [tree]
  (fn compile-special [value]
    (match value
      "*" "[^/]*"
      "?" "."
      "{" "("
      "}" ")"
      "," "|"
      (where value (startswith value "**")) ".*"
      value value))

  (fn compile-literal [value is-literal]
    (if is-literal
        value
        (escape-literal value)))

  (accumulate [regex "" _ node (ipairs tree)]
    (let [node-str (match (get-node-type node)
                     :tree (compile-to-regex node)
                     :special (compile-special node.value)
                     :literal (compile-literal node.value node.is-literal))]
      (.. regex node-str))))

(let [lpeg (require :lpeg)
      {: Ct : C : P : S : R : V} (require :lpeg)
      glob-parser (let [GroupLiteralChar (+ (R :AZ) (R :az) (R :09)
                                            (S "-+@_~;:./$^"))
                        LiteralChar (+ GroupLiteralChar (S ",}"))
                        OneStar (/ (P "*") make-special)
                        QuestionMark (/ (P "?") make-special)
                        TwoStars (/ (* (P "**") (^ (P "/*") 0)) make-special)
                        OpenGroup (/ (P "{") make-special)
                        CloseGroup (/ (P "}") make-special)
                        Comma (/ (P ",") make-special)
                        OpenRange (/ (P "[") make-special)
                        CloseRange (/ (P "]") make-special)
                        RangeNegation (/ (P "!") make-special)
                        RangeLiteral (/ (^ (- (P 1) (P "]")) 1)
                                        #(make-literal $1 true))
                        InsideRange (* (^ RangeNegation -1) RangeLiteral)
                        Range (* OpenRange InsideRange CloseRange)
                        GroupLiteral (/ (^ GroupLiteralChar 1) make-literal)
                        Literal (/ (^ LiteralChar 1) make-literal)
                        Glob (V :Glob)
                        Term (V :Term)
                        InsideGroup (V :InsideGroup)
                        GroupGlob (V :GroupGlob)
                        GroupTerm (V :GroupTerm)
                        Group (V :Group)]
                    (P {1 Glob
                        :Glob (Ct (^ Term 1))
                        :Term (+ TwoStars OneStar QuestionMark Group Literal
                                 Range)
                        :Group (Ct (* OpenGroup InsideGroup CloseGroup))
                        :InsideGroup (* GroupGlob (^ (* Comma GroupGlob) 0))
                        :GroupGlob (^ GroupTerm 1)
                        :GroupTerm (+ TwoStars OneStar QuestionMark Group
                                      GroupLiteral Range)}))
      glob-parser (* glob-parser -1)]
  (fn parse [glob]
    (lpeg.match glob-parser glob))

  (fn compile [glob]
    (let [tree (parse glob)]
      (if tree
          (let [rex (require :rex_pcre)
                re (compile-to-regex tree)
                re (.. "^" re "$")
                (ok pat-or-err) (pcall rex.new re)]
            (if ok
                (values true pat-or-err)
                (values false
                        (string.format "internal error compiling glob string '%s' to a regular expression:
  generated regex: %s
  pcre error: %s" glob re pat-or-err))))
          (values false (string.format "invalid glob string '%s'" glob)))))

  (fn do-match [patt str]
    (let [m (patt:exec str)]
      (if m true false)))

  (fn break-tree [tree]
    (accumulate [acc [""] _ node (ipairs tree)]
      (if (is-group node)
          (let [trees (split-group node)
                broken-trees (icollect [_ t (ipairs trees)]
                               (break-tree t))]
            (accumulate [result [] _ nodes-str (ipairs broken-trees)]
              (do
                (each [_ node-str (ipairs nodes-str)]
                  (each [_ e (ipairs acc)]
                    (table.insert result (.. e node-str))))
                result)))
          (icollect [_ e (ipairs acc)]
            (.. e node.value)))))

  (fn strip-special [glob]
    (string.gsub glob "/?[^/]+[*?[{].*" ""))

  (fn break [glob]
    (->> glob
         (parse)
         (break-tree)))

  {: compile :match do-match : break : parse : strip-special})
