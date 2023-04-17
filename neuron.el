(defvar neuron-map
  (let ((map (make-sparse-keymap))
        (ripgrepmap (make-sparse-keymap))
        )

    (define-key ripgrepmap "n" 'ripgrep-neuron-lib)
    (define-key ripgrepmap "r" 'counsel-projectile-rg)
    (define-key ripgrepmap "R" 'ripgrep-regexp)

    (define-key map "b" 'magit-blame)
    (define-key map "d" 'insert-date-time)
    (define-key map "c" 'write-contexts)
    (define-key map "f" 'find-file-at-point)
    (define-key map "t" 'shell-pop)
    (define-key map "m" 'write-modules)
    (define-key map "n" 'neotree-dir)
    (define-key map "P" 'projectile-discover-projects-in-search-path)
    (define-key map "p" 'copy-file-name)
    (define-key map "r" ripgrepmap)

    map)
  "Neuron key map.")

(global-set-key (kbd "s-n") neuron-map)

(add-hook 'shell-pop-in-after-hook
          (lambda ()
            (term-send-raw-string (concat "cd " (shell-quote-argument (projectile-project-root)) "\n"))
            (term-send-raw-string "\C-l")))

(add-hook 'magit-revision-mode-hook 'visual-line-mode)

(add-hook 'markdown-mode-hook (lambda ()
                                (make-local-variable 'prelude-whitespace)
                                (setq prelude-whitespace nil)

                                (make-local-variable 'prelude-clean-whitespace-on-save)
                                (setq prelude-clean-whitespace-on-save nil)
                                ))

(setq projectile-project-search-path '("~/wsgr/neuron/" "~/eventide/"))
;; M-x projectile-discover-projects-in-search-path
;; M-x projectile-discover-projects-in-directory

(defun ripgrep-neuron-lib (search_term)
  (interactive
   (list
    (read-from-minibuffer "Ripgrep search for: " (thing-at-point 'symbol))
    )
   )
  (ripgrep-regexp search_term "~/wsgr/neuron" '("-g \"**/lib/**/*.rb\""))
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the mode line to a manageable name that relevant ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun sbditto85--calculated-buffer-name ()
  (let ((bfn buffer-file-name))
    (if bfn
        (let ((n (substring bfn (string-width (projectile-project-root)))))
          (let ((sw (string-width n))
                (cut 60)
                )
            (if (> sw cut)
                (substring n (- sw cut))
              n)
            )
          )
      (buffer-name)
      )
    )
  )

(setq-default mode-line-buffer-identification
              (list '(:eval (propertized-buffer-identification (sbditto85--calculated-buffer-name)))))
