;; This uses a lpeg parser to parse a glob, and the output is another lpeg
;; parser that represents that glob.

;; It doesn't support escape sequences nor negations.

;; This is WIP. Currently ** and * are both broken. Example of matches that don't work:
;;
;; - *.go doesn't match fi.le.go (it does match file.go though)
;; - **/*.go doesn't match dir/subdir/file.go (it does match dir/file.go though)

(local letters (let [first-upper (string.byte :A)
                     t []]
                 (for [b first-upper (+ first-upper 25)]
                   (let [c (string.char b)]
                     (table.insert t c)
                     (table.insert t (string.lower c))))
                 t))

(local digits (let [t []]
                (for [digit 0 9]
                  (table.insert t (tostring digit)))
                t))

(local special-chars ["-" "+" "@" "_" "~" ";" ":" "."])

(fn make-literal-set [exclude extra]
  (let [chars (or extra [])
        exclude (or exclude {})]
    (fn add-to-chars [list]
      (each [_ ch (ipairs list)]
        (when (= (. exclude ch) nil)
          (table.insert chars ch))))

    (add-to-chars letters)
    (add-to-chars digits)
    (add-to-chars special-chars)
    (table.concat chars "")))

(let [lpeg (require :lpeg)
      {: C : P : S : R : V : Ct} (require :lpeg)
      glob-parser (let [CompLiteralChar (S (make-literal-set))
                        GroupLiteralChar (+ CompLiteralChar (S "/"))
                        LiteralChar (+ GroupLiteralChar (S ",}"))
                        OneStar (/ (+ (* (C (P "*")) (C (P 1))) (P "*"))
                                   #(if $2
                                        (* (^ (S (make-literal-set {$2 true}))
                                              1)
                                           (P $2))
                                        (^ CompLiteralChar 1)))
                        SingleMatch (/ (P "?") #LiteralChar)
                        TwoStars (/ (+ (* (C (P "**")) (C (P 1))) (P "**"))
                                    #(if $2
                                         (* (^ (S (make-literal-set {$2 true}))
                                               0)
                                            (P $2))
                                         (^ LiteralChar 1)))
                        OpenGroup (P "{")
                        CloseGroup (P "}")
                        Comma (P ",")
                        Literal (/ (^ LiteralChar 1) #(P $1))
                        GroupLiteral (/ (^ GroupLiteralChar 1) #(P $1))
                        Glob (V :Glob)
                        Term (V :Term)
                        GroupGlob (V :GroupGlob)
                        GroupTerm (V :GroupTerm)
                        Group (V :Group)]
                    (P {1 Glob
                        :Glob (/ (^ Term 1)
                                 (fn [...]
                                   (let [p (accumulate [acc nil _ rule (ipairs [...])]
                                             (if (= acc nil) rule (* acc rule)))]
                                     (* p -1))))
                        :Term (+ TwoStars OneStar SingleMatch Group Literal)
                        :Group (/ (* OpenGroup
                                     (+ (* GroupGlob Comma GroupGlob) GroupGlob)
                                     CloseGroup)
                                  (fn [...]
                                    (accumulate [acc nil _ rule (ipairs [...])]
                                      (if (= acc nil) rule (+ acc rule)))))
                        :GroupGlob (^ GroupTerm 1)
                        :GroupTerm (+ TwoStars OneStar SingleMatch Group
                                      GroupLiteral)}))]
  (fn compile [glob]
    (let [parser (lpeg.match glob-parser glob)]
      (if parser
          (values true parser)
          (values false (string.format "invalid glob: '%s'" glob)))))

  {: compile})
