((ace-window :source "elpaca-menu-lock-file" :recipe
             (:package "ace-window" :repo "abo-abo/ace-window"
                       :fetcher github :files
                       ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                        "*.texinfo" "doc/dir" "doc/*.info"
                        "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                        "docs/dir" "docs/*.info" "docs/*.texi"
                        "docs/*.texinfo"
                        (:exclude ".dir-locals.el" "test.el"
                                  "tests.el" "*-test.el" "*-tests.el"
                                  "LICENSE" "README*" "*-pkg.el"))
                       :source "MELPA" :protocol https :inherit t
                       :depth treeless :ref
                       "77115afc1b0b9f633084cf7479c767988106c196"))
 (all-the-icons :source "elpaca-menu-lock-file" :recipe
                (:package "all-the-icons" :repo
                          "domtronn/all-the-icons.el" :fetcher github
                          :files (:defaults "data") :source "MELPA"
                          :protocol https :inherit t :depth treeless
                          :ref
                          "4778632b29c8c8d2b7cd9ce69535d0be01d846f9"))
 (annalist :source "elpaca-menu-lock-file" :recipe
           (:package "annalist" :fetcher github :repo
                     "noctuid/annalist.el" :files
                     ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                      "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                      "doc/*.texinfo" "lisp/*.el" "docs/dir"
                      "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                      (:exclude ".dir-locals.el" "test.el" "tests.el"
                                "*-test.el" "*-tests.el" "LICENSE"
                                "README*" "*-pkg.el"))
                     :source "MELPA" :protocol https :inherit t :depth
                     treeless :ref
                     "e1ef5dad75fa502d761f70d9ddf1aeb1c423f41d"))
 (avy :source "elpaca-menu-lock-file" :recipe
      (:package "avy" :repo "abo-abo/avy" :fetcher github :files
                ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                 "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                 "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                 "docs/*.texinfo"
                 (:exclude ".dir-locals.el" "test.el" "tests.el"
                           "*-test.el" "*-tests.el" "LICENSE"
                           "README*" "*-pkg.el"))
                :source "MELPA" :protocol https :inherit t :depth
                treeless :ref
                "933d1f36cca0f71e4acb5fac707e9ae26c536264"))
 (browse-at-remote :source "elpaca-menu-lock-file" :recipe
                   (:package "browse-at-remote" :repo
                             "rmuslimov/browse-at-remote" :fetcher
                             github :files
                             ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                              "*.texinfo" "doc/dir" "doc/*.info"
                              "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                              "docs/dir" "docs/*.info" "docs/*.texi"
                              "docs/*.texinfo"
                              (:exclude ".dir-locals.el" "test.el"
                                        "tests.el" "*-test.el"
                                        "*-tests.el" "LICENSE"
                                        "README*" "*-pkg.el"))
                             :source "MELPA" :protocol https :inherit
                             t :depth treeless :ref
                             "38e5ffd77493c17c821fd88f938dbf42705a5158"))
 (cape :source "elpaca-menu-lock-file" :recipe
       (:package "cape" :repo "minad/cape" :fetcher github :files
                 ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                  "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                  "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                  "docs/*.texinfo"
                  (:exclude ".dir-locals.el" "test.el" "tests.el"
                            "*-test.el" "*-tests.el" "LICENSE"
                            "README*" "*-pkg.el"))
                 :source "MELPA" :protocol https :inherit t :depth
                 treeless :ref
                 "2b2a5c5bef16eddcce507d9b5804e5a0cc9481ae"))
 (cfrs :source "elpaca-menu-lock-file" :recipe
       (:package "cfrs" :repo "Alexander-Miller/cfrs" :fetcher github
                 :files
                 ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                  "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                  "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                  "docs/*.texinfo"
                  (:exclude ".dir-locals.el" "test.el" "tests.el"
                            "*-test.el" "*-tests.el" "LICENSE"
                            "README*" "*-pkg.el"))
                 :source "MELPA" :protocol https :inherit t :depth
                 treeless :ref
                 "981bddb3fb9fd9c58aed182e352975bd10ad74c8"))
 (compdef :source "elpaca-menu-lock-file" :recipe
          (:package "compdef" :fetcher github :repo
                    "cyruseuros/compdef" :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :wait t :ref
                    "30fb5846ed851efee641ce8c5d8879ad36cd7ac6"))
 (cond-let
   :source "elpaca-menu-lock-file" :recipe
   (:package "cond-let" :fetcher github :repo "tarsius/cond-let"
             :files
             ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
              "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
              "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
              "docs/*.texinfo"
              (:exclude ".dir-locals.el" "test.el" "tests.el"
                        "*-test.el" "*-tests.el" "LICENSE" "README*"
                        "*-pkg.el"))
             :source "MELPA" :protocol https :inherit t :depth
             treeless :ref "8bf87d45e169ebc091103b2aae325aece3aa804d"))
 (consult :source "elpaca-menu-lock-file" :recipe
          (:package "consult" :repo "minad/consult" :fetcher github
                    :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :ref
                    "d1d39d52151a10f7ca29aa291886e99534cc94db"))
 (corfu :source "elpaca-menu-lock-file" :recipe
        (:package "corfu" :repo "minad/corfu" :files
                  (:defaults "extensions/corfu-*.el") :fetcher github
                  :source "MELPA" :protocol https :inherit t :depth
                  treeless :ref
                  "abfe0003d71b61ffdcf23fc6e546643486daeb69"))
 (dash :source "elpaca-menu-lock-file" :recipe
       (:package "dash" :fetcher github :repo "magnars/dash.el" :files
                 ("dash.el" "dash.texi") :source "MELPA" :protocol
                 https :inherit t :depth treeless :ref
                 "fb443e7a6e660ba849cafcd01021d9aac3ac6764"))
 (diff-hl :source "elpaca-menu-lock-file" :recipe
          (:package "diff-hl" :fetcher github :repo "dgutov/diff-hl"
                    :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :ref
                    "3eefe68941933c8549049502007411ed2bf70387"))
 (dired-hacks-utils :source "elpaca-menu-lock-file" :recipe
                    (:package "dired-hacks-utils" :fetcher github
                              :repo "Fuco1/dired-hacks" :files
                              ("dired-hacks-utils.el") :source "MELPA"
                              :protocol https :inherit t :depth
                              treeless :ref
                              "de9336f4b47ef901799fe95315fa080fa6d77b48"))
 (dired-subtree :source "elpaca-menu-lock-file" :recipe
                (:package "dired-subtree" :fetcher github :repo
                          "Fuco1/dired-hacks" :files
                          ("dired-subtree.el") :source "MELPA"
                          :protocol https :inherit t :depth treeless
                          :ref
                          "de9336f4b47ef901799fe95315fa080fa6d77b48"))
 (doom-modeline :source "elpaca-menu-lock-file" :recipe
                (:package "doom-modeline" :repo
                          "seagle0128/doom-modeline" :fetcher github
                          :files
                          ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                           "*.texinfo" "doc/dir" "doc/*.info"
                           "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                           "docs/dir" "docs/*.info" "docs/*.texi"
                           "docs/*.texinfo"
                           (:exclude ".dir-locals.el" "test.el"
                                     "tests.el" "*-test.el"
                                     "*-tests.el" "LICENSE" "README*"
                                     "*-pkg.el"))
                          :source "MELPA" :protocol https :inherit t
                          :depth treeless :ref
                          "0c91e47a0cfe8a56cc09d1da485ea0d19947777c"))
 (dumb-jump :source "elpaca-menu-lock-file" :recipe
            (:package "dumb-jump" :repo "jacktasia/dumb-jump" :fetcher
                      github :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "0bb557a2bdc6e0364fd63ee6a34908f538956999"))
 (elisp-refs :source "elpaca-menu-lock-file" :recipe
             (:package "elisp-refs" :repo "Wilfred/elisp-refs"
                       :fetcher github :files
                       (:defaults (:exclude "elisp-refs-bench.el"))
                       :source "MELPA" :protocol https :inherit t
                       :depth treeless :ref
                       "541a064c3ce27867872cf708354a65d83baf2a6d"))
 (elpaca :source
   "elpaca-menu-lock-file" :recipe
   (:source nil :protocol https :inherit ignore :depth 1 :repo
            "https://github.com/progfolio/elpaca.git" :ref
            "1508298c1ed19c81fa4ebc5d22d945322e9e4c52" :files
            (:defaults "elpaca-test.el" (:exclude "extensions"))
            :build (:not elpaca--activate-package) :package "elpaca"))
 (elpaca-use-package :source "elpaca-menu-lock-file" :recipe
                     (:package "elpaca-use-package" :wait t :repo
                               "https://github.com/progfolio/elpaca.git"
                               :files
                               ("extensions/elpaca-use-package.el")
                               :main
                               "extensions/elpaca-use-package.el"
                               :build (:not elpaca--compile-info)
                               :source "Elpaca extensions" :protocol
                               https :inherit t :depth treeless :ref
                               "1508298c1ed19c81fa4ebc5d22d945322e9e4c52"))
 (embark :source "elpaca-menu-lock-file" :recipe
         (:package "embark" :repo "oantolin/embark" :fetcher github
                   :files ("embark.el" "embark-org.el" "embark.texi")
                   :source "MELPA" :protocol https :inherit t :depth
                   treeless :ref
                   "7b3b2fa239c34c2e304eab4367a4f5924c047e2b"))
 (embark-consult :source "elpaca-menu-lock-file" :recipe
                 (:package "embark-consult" :repo "oantolin/embark"
                           :fetcher github :files
                           ("embark-consult.el") :source "MELPA"
                           :protocol https :inherit t :depth treeless
                           :ref
                           "7b3b2fa239c34c2e304eab4367a4f5924c047e2b"))
 (evil :source "elpaca-menu-lock-file" :recipe
       (:package "evil" :repo "emacs-evil/evil" :fetcher github :files
                 (:defaults "doc/build/texinfo/evil.texi"
                            (:exclude "evil-test-helpers.el"))
                 :source "MELPA" :protocol https :inherit t :depth
                 treeless :ref
                 "729d9a58b387704011a115c9200614e32da3cefc"))
 (evil-collection :source "elpaca-menu-lock-file" :recipe
                  (:package "evil-collection" :fetcher github :repo
                            "emacs-evil/evil-collection" :files
                            (:defaults "modes") :source "MELPA"
                            :protocol https :inherit t :depth treeless
                            :ref
                            "d052ad2ec1f6a4b101f873f01517b295cd7dc4a9"))
 (evil-escape :source "elpaca-menu-lock-file" :recipe
              (:package "evil-escape" :fetcher github :repo
                        "emacsorphanage/evil-escape" :files
                        ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                         "*.texinfo" "doc/dir" "doc/*.info"
                         "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                         "docs/dir" "docs/*.info" "docs/*.texi"
                         "docs/*.texinfo"
                         (:exclude ".dir-locals.el" "test.el"
                                   "tests.el" "*-test.el" "*-tests.el"
                                   "LICENSE" "README*" "*-pkg.el"))
                        :source "MELPA" :protocol https :inherit t
                        :depth treeless :ref
                        "aebd1a78a6bd33e5164e7552096b3fe1172d3012"))
 (evil-goggles :source "elpaca-menu-lock-file" :recipe
               (:package "evil-goggles" :repo "edkolev/evil-goggles"
                         :fetcher github :files
                         ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                          "*.texinfo" "doc/dir" "doc/*.info"
                          "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                          "docs/dir" "docs/*.info" "docs/*.texi"
                          "docs/*.texinfo"
                          (:exclude ".dir-locals.el" "test.el"
                                    "tests.el" "*-test.el"
                                    "*-tests.el" "LICENSE" "README*"
                                    "*-pkg.el"))
                         :source "MELPA" :protocol https :inherit t
                         :depth treeless :ref
                         "34ca276a85f615d2b45e714c9f8b5875bcb676f3"))
 (evil-mc :source "elpaca-menu-lock-file" :recipe
          (:package "evil-mc" :fetcher github :repo "gabesoft/evil-mc"
                    :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :ref
                    "7e363dd6b0a39751e13eb76f2e9b7b13c7054a43"))
 (evil-surround :source "elpaca-menu-lock-file" :recipe
                (:package "evil-surround" :repo
                          "emacs-evil/evil-surround" :fetcher github
                          :old-names (surround) :files
                          ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                           "*.texinfo" "doc/dir" "doc/*.info"
                           "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                           "docs/dir" "docs/*.info" "docs/*.texi"
                           "docs/*.texinfo"
                           (:exclude ".dir-locals.el" "test.el"
                                     "tests.el" "*-test.el"
                                     "*-tests.el" "LICENSE" "README*"
                                     "*-pkg.el"))
                          :source "MELPA" :protocol https :inherit t
                          :depth treeless :ref
                          "da05c60b0621cf33161bb4335153f75ff5c29d91"))
 (f :source "elpaca-menu-lock-file" :recipe
    (:package "f" :fetcher github :repo "rejeep/f.el" :files
              ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
               "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
               "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
               "docs/*.texinfo"
               (:exclude ".dir-locals.el" "test.el" "tests.el"
                         "*-test.el" "*-tests.el" "LICENSE" "README*"
                         "*-pkg.el"))
              :source "MELPA" :protocol https :inherit t :depth
              treeless :ref "931b6d0667fe03e7bf1c6c282d6d8d7006143c52"))
 (general :source "elpaca-menu-lock-file" :recipe
          (:package "general" :fetcher github :repo
                    "noctuid/general.el" :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :ref
                    "a48768f85a655fe77b5f45c2880b420da1b1b9c3"))
 (goto-chg :source "elpaca-menu-lock-file" :recipe
           (:package "goto-chg" :repo "emacs-evil/goto-chg" :fetcher
                     github :files
                     ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                      "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                      "doc/*.texinfo" "lisp/*.el" "docs/dir"
                      "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                      (:exclude ".dir-locals.el" "test.el" "tests.el"
                                "*-test.el" "*-tests.el" "LICENSE"
                                "README*" "*-pkg.el"))
                     :source "MELPA" :protocol https :inherit t :depth
                     treeless :ref
                     "72f556524b88e9d30dc7fc5b0dc32078c166fda7"))
 (haskell-mode :source "elpaca-menu-lock-file" :recipe
               (:package "haskell-mode" :repo "haskell/haskell-mode"
                         :fetcher github :files
                         (:defaults "NEWS" "logo.svg") :source "MELPA"
                         :protocol https :inherit t :depth treeless
                         :ref
                         "2dd755a5fa11577a9388af88f385d2a8e18f7a8d"))
 (helpful :source "elpaca-menu-lock-file" :recipe
          (:package "helpful" :repo "Wilfred/helpful" :fetcher github
                    :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :ref
                    "03756fa6ad4dcca5e0920622b1ee3f70abfc4e39"))
 (ht :source "elpaca-menu-lock-file" :recipe
     (:package "ht" :fetcher github :repo "Wilfred/ht.el" :files
               ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
                "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
                "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
                "docs/*.texinfo"
                (:exclude ".dir-locals.el" "test.el" "tests.el"
                          "*-test.el" "*-tests.el" "LICENSE" "README*"
                          "*-pkg.el"))
               :source "MELPA" :protocol https :inherit t :depth
               treeless :ref
               "1c49aad1c820c86f7ee35bf9fff8429502f60fef"))
 (hydra :source "elpaca-menu-lock-file" :recipe
        (:package "hydra" :repo "abo-abo/hydra" :fetcher github :files
                  (:defaults (:exclude "lv.el")) :source "MELPA"
                  :protocol https :inherit t :depth treeless :ref
                  "59a2a45a35027948476d1d7751b0f0215b1e61aa"))
 (jinx :source "elpaca-menu-lock-file" :recipe
       (:package "jinx" :repo "minad/jinx" :files
                 (:defaults "jinx-mod.c" "emacs-module.h") :fetcher
                 github :source "MELPA" :protocol https :inherit t
                 :depth treeless :ref
                 "75e8e4805fe6f4ab256bd59bec71464edbc23887"))
 (literate-config :source "elpaca-menu-lock-file" :recipe
                  (:source nil :protocol ssh :inherit t :depth
                           treeless :wait t :host github :repo
                           "aaronjensen/emacs-literate-config"
                           :package "literate-config" :ref
                           "2dea0ba886576f3dcd2abc00e78807161dd2b25d"))
 (llama :source "elpaca-menu-lock-file" :recipe
        (:package "llama" :fetcher github :repo "tarsius/llama" :files
                  ("llama.el" ".dir-locals.el") :source "MELPA"
                  :protocol https :inherit t :depth treeless :ref
                  "2a89ba755b0459914a44b1ffa793e57f759a5b85"))
 (lv :source "elpaca-menu-lock-file" :recipe
     (:package "lv" :repo "abo-abo/hydra" :fetcher github :files
               ("lv.el") :source "MELPA" :protocol https :inherit t
               :depth treeless :ref
               "59a2a45a35027948476d1d7751b0f0215b1e61aa"))
 (magit :source "elpaca-menu-lock-file" :recipe
        (:package "magit" :fetcher github :repo "magit/magit" :files
                  ("lisp/magit*.el" "lisp/git-*.el" "docs/magit.texi"
                   "docs/AUTHORS.md" "LICENSE" ".dir-locals.el"
                   ("git-hooks" "git-hooks/*")
                   (:exclude "lisp/magit-section.el"))
                  :source "MELPA" :protocol https :inherit t :depth
                  treeless :ref
                  "e83149fff95b580aeab3b2e56ab386bb2e1d128b"))
 (magit-section :source "elpaca-menu-lock-file" :recipe
                (:package "magit-section" :fetcher github :repo
                          "magit/magit" :files
                          ("lisp/magit-section.el"
                           "docs/magit-section.texi"
                           "magit-section-pkg.el")
                          :source "MELPA" :protocol https :inherit t
                          :depth treeless :ref
                          "e83149fff95b580aeab3b2e56ab386bb2e1d128b"))
 (markdown-mode :source "elpaca-menu-lock-file" :recipe
                (:package "markdown-mode" :fetcher github :repo
                          "jrblevin/markdown-mode" :files
                          ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                           "*.texinfo" "doc/dir" "doc/*.info"
                           "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                           "docs/dir" "docs/*.info" "docs/*.texi"
                           "docs/*.texinfo"
                           (:exclude ".dir-locals.el" "test.el"
                                     "tests.el" "*-test.el"
                                     "*-tests.el" "LICENSE" "README*"
                                     "*-pkg.el"))
                          :source "MELPA" :protocol https :inherit t
                          :depth treeless :ref
                          "9de2df5a9f2f864c82ec112d3369154767a2bb49"))
 (modus-themes :source "elpaca-menu-lock-file" :recipe
               (:package "modus-themes" :fetcher github :repo
                         "protesilaos/modus-themes" :files
                         ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                          "*.texinfo" "doc/dir" "doc/*.info"
                          "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                          "docs/dir" "docs/*.info" "docs/*.texi"
                          "docs/*.texinfo"
                          (:exclude ".dir-locals.el" "test.el"
                                    "tests.el" "*-test.el"
                                    "*-tests.el" "LICENSE" "README*"
                                    "*-pkg.el"))
                         :source "MELPA" :protocol https :inherit t
                         :depth treeless :ref
                         "0ace30e471ce9db21590272624787272022f068c"))
 (nerd-icons :source "elpaca-menu-lock-file" :recipe
             (:package "nerd-icons" :repo
                       "rainstormstudio/nerd-icons.el" :fetcher github
                       :files (:defaults "data") :source "MELPA"
                       :protocol https :inherit t :depth treeless :ref
                       "9a7f44db9a53567f04603bc88d05402cad49c64c"))
 (no-littering :source "elpaca-menu-lock-file" :recipe
               (:package "no-littering" :fetcher github :repo
                         "emacscollective/no-littering" :files
                         ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                          "*.texinfo" "doc/dir" "doc/*.info"
                          "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                          "docs/dir" "docs/*.info" "docs/*.texi"
                          "docs/*.texinfo"
                          (:exclude ".dir-locals.el" "test.el"
                                    "tests.el" "*-test.el"
                                    "*-tests.el" "LICENSE" "README*"
                                    "*-pkg.el"))
                         :source "MELPA" :protocol https :inherit t
                         :depth treeless :wait t :ref
                         "ec8b6b76e6a8e53fa5e471949021dee68f3bc2e6"))
 (orderless :source "elpaca-menu-lock-file" :recipe
            (:package "orderless" :repo "oantolin/orderless" :fetcher
                      github :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "3a2a32181f7a5bd7b633e40d89de771a5dd88cc7"))
 (ox-reveal :source "elpaca-menu-lock-file" :recipe
            (:package "ox-reveal" :repo "yjwen/org-reveal" :fetcher
                      github :old-names (org-reveal) :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "f55c851bf6aeb1bb2a7f6cf0f2b7bd0e79c4a5a0"))
 (persistent-scratch :source "elpaca-menu-lock-file" :recipe
                     (:package "persistent-scratch" :fetcher github
                               :repo "Fanael/persistent-scratch"
                               :files
                               ("*.el" "*.el.in" "dir" "*.info"
                                "*.texi" "*.texinfo" "doc/dir"
                                "doc/*.info" "doc/*.texi"
                                "doc/*.texinfo" "lisp/*.el" "docs/dir"
                                "docs/*.info" "docs/*.texi"
                                "docs/*.texinfo"
                                (:exclude ".dir-locals.el" "test.el"
                                          "tests.el" "*-test.el"
                                          "*-tests.el" "LICENSE"
                                          "README*" "*-pkg.el"))
                               :source "MELPA" :protocol https
                               :inherit t :depth treeless :ref
                               "5ff41262f158d3eb966826314516f23e0cb86c04"))
 (pfuture :source "elpaca-menu-lock-file" :recipe
          (:package "pfuture" :repo "Alexander-Miller/pfuture"
                    :fetcher github :files
                    ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                     "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                     "doc/*.texinfo" "lisp/*.el" "docs/dir"
                     "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                     (:exclude ".dir-locals.el" "test.el" "tests.el"
                               "*-test.el" "*-tests.el" "LICENSE"
                               "README*" "*-pkg.el"))
                    :source "MELPA" :protocol https :inherit t :depth
                    treeless :ref
                    "19b53aebbc0f2da31de6326c495038901bffb73c"))
 (popup :source "elpaca-menu-lock-file" :recipe
        (:package "popup" :fetcher github :repo
                  "auto-complete/popup-el" :files
                  ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                   "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                   "doc/*.texinfo" "lisp/*.el" "docs/dir"
                   "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                   (:exclude ".dir-locals.el" "test.el" "tests.el"
                             "*-test.el" "*-tests.el" "LICENSE"
                             "README*" "*-pkg.el"))
                  :source "MELPA" :protocol https :inherit t :depth
                  treeless :ref
                  "45a0b759076ce4139aba36dde0a2904136282e73"))
 (posframe :source "elpaca-menu-lock-file" :recipe
           (:package "posframe" :fetcher github :repo
                     "tumashu/posframe" :files
                     ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                      "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                      "doc/*.texinfo" "lisp/*.el" "docs/dir"
                      "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                      (:exclude ".dir-locals.el" "test.el" "tests.el"
                                "*-test.el" "*-tests.el" "LICENSE"
                                "README*" "*-pkg.el"))
                     :source "MELPA" :protocol https :inherit t :depth
                     treeless :ref
                     "4fc893c3c9ea3f6b5099ac1b369abb3c6da40b1e"))
 (rust-mode :source "elpaca-menu-lock-file" :recipe
            (:package "rust-mode" :repo "rust-lang/rust-mode" :fetcher
                      github :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "f68ddca5c22b94a2de7c9ce20d629cd78d60b269"))
 (s :source "elpaca-menu-lock-file" :recipe
    (:package "s" :fetcher github :repo "magnars/s.el" :files
              ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
               "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
               "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
               "docs/*.texinfo"
               (:exclude ".dir-locals.el" "test.el" "tests.el"
                         "*-test.el" "*-tests.el" "LICENSE" "README*"
                         "*-pkg.el"))
              :source "MELPA" :protocol https :inherit t :depth
              treeless :ref "dda84d38fffdaf0c9b12837b504b402af910d01d"))
 (shrink-path :source "elpaca-menu-lock-file" :recipe
              (:package "shrink-path" :fetcher gitlab :repo
                        "bennya/shrink-path.el" :files
                        ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                         "*.texinfo" "doc/dir" "doc/*.info"
                         "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                         "docs/dir" "docs/*.info" "docs/*.texi"
                         "docs/*.texinfo"
                         (:exclude ".dir-locals.el" "test.el"
                                   "tests.el" "*-test.el" "*-tests.el"
                                   "LICENSE" "README*" "*-pkg.el"))
                        :source "MELPA" :protocol https :inherit t
                        :depth treeless :ref
                        "c14882c8599aec79a6e8ef2d06454254bb3e1e41"))
 (tabspaces :source "elpaca-menu-lock-file" :recipe
            (:package "tabspaces" :repo "mclear-tools/tabspaces"
                      :fetcher github :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "cd9f780bd69747fb8a598be1d4347e2e161c2d82"))
 (transient :source "elpaca-menu-lock-file" :recipe
            (:package "transient" :fetcher github :repo
                      "magit/transient" :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "bda7c2e0772deaee8e36a217d15c14784e8c6800"))
 (treemacs :source "elpaca-menu-lock-file" :recipe
           (:package "treemacs" :fetcher github :repo
                     "Alexander-Miller/treemacs" :files
                     (:defaults "Changelog.org" "icons"
                                "src/elisp/treemacs*.el"
                                "src/scripts/treemacs*.py"
                                (:exclude "src/extra/*"))
                     :source "MELPA" :protocol https :inherit t :depth
                     treeless :ref
                     "2ab5a3c89fa01bbbd99de9b8986908b2bc5a7b49"))
 (treemacs-all-the-icons :source "elpaca-menu-lock-file" :recipe
                         (:package "treemacs-all-the-icons" :fetcher
                                   github :repo
                                   "Alexander-Miller/treemacs" :files
                                   ("src/extra/treemacs-all-the-icons.el")
                                   :source "MELPA" :protocol https
                                   :inherit t :depth treeless :ref
                                   "2ab5a3c89fa01bbbd99de9b8986908b2bc5a7b49"))
 (treemacs-evil :source "elpaca-menu-lock-file" :recipe
                (:package "treemacs-evil" :fetcher github :repo
                          "Alexander-Miller/treemacs" :files
                          ("src/extra/treemacs-evil.el") :source
                          "MELPA" :protocol https :inherit t :depth
                          treeless :ref
                          "2ab5a3c89fa01bbbd99de9b8986908b2bc5a7b49"))
 (treemacs-magit :source "elpaca-menu-lock-file" :recipe
                 (:package "treemacs-magit" :fetcher github :repo
                           "Alexander-Miller/treemacs" :files
                           ("src/extra/treemacs-magit.el") :source
                           "MELPA" :protocol https :inherit t :depth
                           treeless :ref
                           "2ab5a3c89fa01bbbd99de9b8986908b2bc5a7b49"))
 (treemacs-tab-bar :source "elpaca-menu-lock-file" :recipe
                   (:package "treemacs-tab-bar" :fetcher github :repo
                             "Alexander-Miller/treemacs" :files
                             ("src/extra/treemacs-tab-bar.el") :source
                             "MELPA" :protocol https :inherit t :depth
                             treeless :ref
                             "2ab5a3c89fa01bbbd99de9b8986908b2bc5a7b49"))
 (vertico :source "elpaca-menu-lock-file" :recipe
          (:package "vertico" :repo "minad/vertico" :files
                    (:defaults "extensions/vertico-*.el") :fetcher
                    github :source "MELPA" :protocol https :inherit t
                    :depth treeless :ref
                    "93f15873d7d6244d72202c5dd7724a030a2d5b9a"))
 (vterm :source "elpaca-menu-lock-file" :recipe
        (:package "vterm" :fetcher github :repo
                  "akermu/emacs-libvterm" :files
                  ("CMakeLists.txt" "elisp.c" "elisp.h"
                   "emacs-module.h" "etc" "utf8.c" "utf8.h" "vterm.el"
                   "vterm-module.c" "vterm-module.h")
                  :source "MELPA" :protocol https :inherit t :depth
                  treeless :wait t :ref
                  "a01a2894a1c1e81a39527835a9169e35b7ec5dec"))
 (vterm-toggle :source "elpaca-menu-lock-file" :recipe
               (:package "vterm-toggle" :fetcher github :repo
                         "jixiuf/vterm-toggle" :files
                         ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                          "*.texinfo" "doc/dir" "doc/*.info"
                          "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                          "docs/dir" "docs/*.info" "docs/*.texi"
                          "docs/*.texinfo"
                          (:exclude ".dir-locals.el" "test.el"
                                    "tests.el" "*-test.el"
                                    "*-tests.el" "LICENSE" "README*"
                                    "*-pkg.el"))
                         :source "MELPA" :protocol https :inherit t
                         :depth treeless :ref
                         "81d031f153c5fa656c744cd518b7d54c54506706"))
 (vundo :source "elpaca-menu-lock-file" :recipe
        (:package "vundo" :repo
                  ("https://github.com/casouri/vundo" . "vundo")
                  :files ("*" (:exclude ".git" "test")) :source
                  "GNU ELPA" :protocol https :inherit t :depth
                  treeless :ref
                  "e0af8c5845abf884a644215a9cac37f39c13cd5a"))
 (wgrep :source "elpaca-menu-lock-file" :recipe
        (:package "wgrep" :fetcher github :repo
                  "mhayashi1120/Emacs-wgrep" :files ("wgrep.el")
                  :source "MELPA" :protocol https :inherit t :depth
                  treeless :ref
                  "49f09ab9b706d2312cab1199e1eeb1bcd3f27f6f"))
 (window-numbering :source "elpaca-menu-lock-file" :recipe
                   (:package "window-numbering" :fetcher github :repo
                             "nschum/window-numbering.el" :files
                             ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                              "*.texinfo" "doc/dir" "doc/*.info"
                              "doc/*.texi" "doc/*.texinfo" "lisp/*.el"
                              "docs/dir" "docs/*.info" "docs/*.texi"
                              "docs/*.texinfo"
                              (:exclude ".dir-locals.el" "test.el"
                                        "tests.el" "*-test.el"
                                        "*-tests.el" "LICENSE"
                                        "README*" "*-pkg.el"))
                             :source "MELPA" :protocol https :inherit
                             t :depth treeless :ref
                             "10809b3993a97c7b544240bf5d7ce9b1110a1b89"))
 (with-editor :source "elpaca-menu-lock-file"
   :recipe
   (:package "with-editor" :fetcher github :repo "magit/with-editor"
             :files
             ("*.el" "*.el.in" "dir" "*.info" "*.texi" "*.texinfo"
              "doc/dir" "doc/*.info" "doc/*.texi" "doc/*.texinfo"
              "lisp/*.el" "docs/dir" "docs/*.info" "docs/*.texi"
              "docs/*.texinfo"
              (:exclude ".dir-locals.el" "test.el" "tests.el"
                        "*-test.el" "*-tests.el" "LICENSE" "README*"
                        "*-pkg.el"))
             :source "MELPA" :protocol https :inherit t :depth
             treeless :ref "902b4d572af2c2f36060da01e3c33d194cdec32b"))
 (yaml-mode :source "elpaca-menu-lock-file" :recipe
            (:package "yaml-mode" :repo "yoshiki/yaml-mode" :fetcher
                      github :files
                      ("*.el" "*.el.in" "dir" "*.info" "*.texi"
                       "*.texinfo" "doc/dir" "doc/*.info" "doc/*.texi"
                       "doc/*.texinfo" "lisp/*.el" "docs/dir"
                       "docs/*.info" "docs/*.texi" "docs/*.texinfo"
                       (:exclude ".dir-locals.el" "test.el" "tests.el"
                                 "*-test.el" "*-tests.el" "LICENSE"
                                 "README*" "*-pkg.el"))
                      :source "MELPA" :protocol https :inherit t
                      :depth treeless :ref
                      "d91f878729312a6beed77e6637c60497c5786efa")))
