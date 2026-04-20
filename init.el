;;; init.el -*- lexical-binding: t; -*-

;; Elpaca lock file
(setq elpaca-lock-file (expand-file-name "elpaca-lock.el" user-emacs-directory))

;;; Update process
;;  - elpaca-fetch / elpaca-fetch-all — only downloads remote commits, does not merge or rebuild
;;  - elpaca-merge / elpaca-merge-all — merges changes (optionally fetches first), rebuilds
;;  - elpaca-pull / elpaca-pull-all — fetch + merge + rebuild (aliased as elpaca-update / elpaca-update-all)
;;  So elpaca-fetch-all does work, but it only fetches — it won't merge or rebuild anything. This is actually useful for your workflow:
;;  Safer update workflow
;;  1. M-x elpaca-fetch-all — download all new commits without changing anything
;;  2. M-x elpaca-log-updates — review what changed (if available), or check elpaca-manager to see which packages have pending updates
;;  3. M-x elpaca-pull-all — actually merge and rebuild when you're ready
;;  4. Restart Emacs, verify things work
;;  5. M-x elpaca-write-lock-file — regenerate the lock file
;;  6. git diff elpaca-lock.el — review and commit

;; Install Elpaca
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; use-package uses elpaca
(elpaca elpaca-use-package
  (elpaca-use-package-mode))

;; ## Identify if this is how I want to do literate config or not. Maybe multiple
;; ## literate config files? I do need to identify a better way to organize the
;; ## literate config if I keep it in one file - Casey, Thu Nov 07 2024

;; Literate config from Aaron Jensen, defaults to config.org and config.el
(use-package literate-config
  :ensure (:wait t :host github :repo "aaronjensen/emacs-literate-config" :protocol ssh))

(literate-config-init)

;;; Experimental personal config
;; (let* ((literate-config-org-file-name (expand-file-name (concat user-emacs-directory "experimental.org")))
;;        (literate-config-el-file-name (expand-file-name (concat user-emacs-directory "experimental.el")))
;;        )
;;     (literate-config-init))
