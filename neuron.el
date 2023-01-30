(defvar neuron-map
  (let ((map (make-sparse-keymap)))
    (define-key map "b" 'magit-blame)
    (define-key map "d" 'insert-date-time)
    (define-key map "c" 'write-contexts)
    (define-key map "f" 'find-file-at-point)
    (define-key map "t" 'shell-pop)
    (define-key map "m" 'write-modules)
    (define-key map "n" 'neotree-dir)
    (define-key map "P" 'projectile-discover-projects-in-search-path)
    (define-key map "p" 'copy-file-name)
    (define-key map "r" 'ripgrep-regexp)
    (define-key map "R" 'counsel-projectile-rg)
    map)
  "Neuron key map.")

(global-set-key (kbd "s-n") neuron-map)

(add-hook 'shell-pop-in-after-hook
          (lambda ()
            (term-send-raw-string (concat "cd " (shell-quote-argument (projectile-project-root)) "\n"))
            (term-send-raw-string "\C-l")))


(setq projectile-project-search-path '("~/wsgr/neuron/"))
;; M-x projectile-discover-projects-in-search-path
;; M-x projectile-discover-projects-in-directory


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
