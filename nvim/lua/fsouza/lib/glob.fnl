;; This library provides two functions: `compile`, that compiles a given glob
;; into an internal representation that can be used later for matches, and
;; `match` that takes a compiled glob and a filepath as a string and returns a
;; boolean indicating whether or not the path matches the given glob.

;; This doesn't support negation nor nested groups (are nested groups a thing
;; in globs?).

;; TODO: don't use vim.fn, this lib should be standalone.
(fn escape-literal [literal]
  (vim.fn.escape literal "^$.*?/\\[]()"))

(let [lpeg (require :lpeg)
      {: C : P : S : R : V : Ct} (require :lpeg)
      glob-parser (let [GroupLiteralChar (+ (R :AZ) (R :az) (R :09)
                                            (S "-+@_~;:./"))
                        LiteralChar (+ GroupLiteralChar (S ",}"))
                        OneStar (/ (P "*") "[^/]*")
                        QuestionMark (/ (P "?") ".")
                        TwoStars (/ (P "**") ".*")
                        OpenGroup (/ (P "{") "(")
                        CloseGroup (/ (P "}") ")")
                        Comma (/ (P ",") "|")
                        GroupLiteral (/ (^ GroupLiteralChar 1) escape-literal)
                        Literal (/ (^ LiteralChar 1) escape-literal)
                        Glob (V :Glob)
                        Term (V :Term)
                        InsideGroup (V :InsideGroup)
                        GroupGlob (V :GroupGlob)
                        GroupTerm (V :GroupTerm)
                        Group (V :Group)]
                    (P {1 Glob
                        :Glob (/ (^ Term 1)
                                 (fn [...]
                                   (accumulate [acc "" _ rule (ipairs [...])]
                                     (.. acc rule))))
                        :Term (+ TwoStars OneStar QuestionMark Group Literal)
                        :Group (/ (* OpenGroup InsideGroup CloseGroup)
                                  (fn [...]
                                    (accumulate [acc "" _ rule (ipairs [...])]
                                      (.. acc rule))))
                        :InsideGroup (* GroupGlob (^ (* Comma GroupGlob) 0))
                        :GroupGlob (^ GroupTerm 1)
                        :GroupTerm (+ TwoStars OneStar QuestionMark
                                      GroupLiteral)}))
      glob-parser (* glob-parser -1)]
  (fn compile [glob]
    (let [re (lpeg.match glob-parser glob)]
      (if re
          (let [rex (require :rex_pcre)
                re (.. "^" re "$")
                (ok pat-or-err) (pcall rex.new re)]
            (if ok
                (values true pat-or-err)
                (values false (string.format "internal error compiling glob string '%s' to a regular expression:
generated regex: %s
pcre error: %s" glob re pat-or-err))))
          (values false (string.format "invalid glob string '%s'" glob)))))

  (fn do-match [patt str]
    (let [m (patt:exec str)]
      (if m true false)))

  {: compile :match do-match})
