;;; elpaca-upgrade-lib.el -*- lexical-binding: t; -*-

;; Loaded before init.el by scripts/upgrade-run.sh, so it can only define
;; functions here; Elpaca is not loaded yet. - Casey, Tue Nov 10 2026

(require 'cl-lib)
(require 'subr-x)

;; Declared so that let binds it dynamically even though Elpaca is not
;; loaded yet when this file is. - Casey, Tue Nov 10 2026
(defvar elpaca-lock-file-functions)

;; Booting the config in batch would otherwise run kill-emacs-hook on exit,
;; and tabspaces would overwrite the saved session with this headless
;; session's empty one. - Casey, Tue Nov 10 2026
(advice-add 'kill-emacs :before (lambda (&rest _) (setq kill-emacs-hook nil)))

;; Exiting explicitly keeps Emacs from treating the arguments after "--" as
;; files to visit once the script returns. - Casey, Tue Nov 10 2026
(defun cea/elpaca-upgrade-main (function)
  "Call FUNCTION, then exit with status 0, or 1 if it signaled an error."
  (condition-case err
      (progn (funcall function) (kill-emacs 0))
    (error (message "ERROR: %s" (error-message-string err))
           (kill-emacs 1))))

(defun cea/elpaca-upgrade-args ()
  "Return the command line arguments given after \"--\"."
  (cdr (member "--" command-line-args)))

(defun cea/elpaca-upgrade-flag-p (flag)
  (and (member flag (cea/elpaca-upgrade-args)) t))

(defun cea/elpaca-upgrade-option (name)
  "Return the value following option NAME, e.g. --label VALUE."
  (cadr (member name (cea/elpaca-upgrade-args))))

(defun cea/elpaca-upgrade-positional-args ()
  "Return arguments after \"--\" that are not options or option values."
  (let ((args (cea/elpaca-upgrade-args)) positional)
    (while args
      (let ((arg (pop args)))
        (cond ((member arg '("--label" "--from-sources")) (pop args))
              ((string-prefix-p "--" arg))
              (t (push arg positional)))))
    (nreverse positional)))

(defun cea/elpaca-upgrade-output-file (name)
  (let ((file (expand-file-name (concat "var/upgrade/" name) user-emacs-directory)))
    (make-directory (file-name-directory file) t)
    file))

(defun cea/elpaca-upgrade-git (dir &rest args)
  "Run git ARGS in DIR and return trimmed stdout, or nil if git fails."
  (with-temp-buffer
    (let* ((default-directory (file-name-as-directory dir))
           (status (apply #'call-process "git" nil '(t nil) nil args)))
      (when (zerop status)
        (string-trim (buffer-string))))))

(defun cea/elpaca-upgrade-git! (dir &rest args)
  "Run git ARGS in DIR and return trimmed stdout, signaling if git fails."
  (with-temp-buffer
    (let* ((default-directory (file-name-as-directory dir))
           (status (apply #'call-process "git" nil t nil args)))
      (unless (zerop status)
        (error "git %s failed in %s: %s"
               (string-join args " ") dir (string-trim (buffer-string))))
      (string-trim (buffer-string)))))

;; Elpaca's private struct accessors change between versions (the status
;; slot was renamed), and the compiled Elpaca can be older than its source,
;; so the slot is read whichever way the loaded version provides.
;; - Casey, Tue Nov 10 2026
(defun cea/elpaca-upgrade-status (e)
  (cond ((fboundp 'elpaca--status) (elpaca--status e))
        ((fboundp 'elpaca<-statuses) (car (elpaca<-statuses e)))
        ((fboundp 'elpaca<-status)
         (let ((status (elpaca<-status e)))
           (if (consp status) (car status) status)))))

(defun cea/elpaca-upgrade-repos ()
  "Return a list of (SOURCE-DIR . IDS) for every queued git-backed package.
Mono-repos such as magit or treemacs provide several ids from one
SOURCE-DIR, and can only be updated together."
  (let ((groups (make-hash-table :test 'equal)) repos)
    (dolist (pair (elpaca--queued))
      (let ((dir (ignore-errors (directory-file-name (elpaca<-source-dir (cdr pair))))))
        (when (and dir (file-exists-p (expand-file-name ".git" dir)))
          (cl-pushnew (car pair) (gethash dir groups)))))
    (maphash (lambda (dir ids) (push (cons dir (sort ids #'string<)) repos)) groups)
    (sort repos (lambda (a b) (string< (car a) (car b))))))

(defun cea/elpaca-upgrade-repo-name (dir)
  (file-name-nondirectory (directory-file-name dir)))

(defun cea/elpaca-upgrade-find-repo (name)
  "Return the (SOURCE-DIR . IDS) entry whose directory is named NAME."
  (or (assoc name (cea/elpaca-upgrade-repos)
             (lambda (dir name) (string= (cea/elpaca-upgrade-repo-name dir) name)))
      (error "No queued git package has a source directory named %s" name)))

(defun cea/elpaca-upgrade-stale-ids ()
  "Return ids whose build has a byte-compiled file older than its source.
Emacs loads the older byte-compiled file in that case, so the package
runs code that no longer matches its checkout."
  (let (ids)
    (dolist (pair (elpaca--queued))
      (when-let* ((build-dir (ignore-errors (elpaca<-build-dir (cdr pair))))
                  ((file-directory-p build-dir)))
        (when (cl-some (lambda (elc)
                         (let ((el (substring elc 0 -1)))
                           (and (file-exists-p el) (file-newer-than-file-p el elc))))
                       (directory-files build-dir t "\\.elc\\'"))
          (cl-pushnew (car pair) ids))))
    (sort ids #'string<)))

(defun cea/elpaca-upgrade-read-lock-file (file)
  "Return an alist of (ID . REF) read from lock FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (mapcar (lambda (entry)
              (cons (car entry) (plist-get (plist-get (cdr entry) :recipe) :ref)))
            (read (current-buffer)))))

;; Elpaca's default filter keeps only packages queued during init, but in
;; batch init.el is loaded after startup has finished, so the filter would
;; drop nearly every package. - Casey, Tue Nov 10 2026
(defun cea/elpaca-upgrade-write-lock-file ()
  (let ((elpaca-lock-file-functions nil))
    (elpaca-write-lock-file elpaca-lock-file)))

(defun cea/elpaca-upgrade-rebuild (ids)
  "Rebuild IDS and block until Elpaca has finished processing them."
  (dolist (id ids)
    (message "Rebuilding %s" id)
    (elpaca-rebuild id))
  (elpaca-wait))

(defun cea/elpaca-upgrade-failed-ids ()
  "Return a list of (ID . STATUS) for packages that did not finish."
  (let (failed)
    (dolist (pair (elpaca--queued))
      (let ((status (cea/elpaca-upgrade-status (cdr pair))))
        (unless (eq status 'finished)
          (push (cons (car pair) status) failed))))
    (nreverse failed)))
