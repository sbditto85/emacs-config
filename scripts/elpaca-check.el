;;; elpaca-check.el -*- lexical-binding: t; -*-

;; These must be known as dynamic variables before the let forms below are
;; evaluated, or the let binds them lexically and they have no effect.
;; - Casey, Tue Nov 10 2026
(require 'bytecomp)
(defvar vterm-always-compile-module)

(defvar cea/elpaca-check--report nil)

(defun cea/elpaca-check--section (title lines)
  (push (concat "## " title "\n"
                (if lines
                    (mapconcat (lambda (line) (concat "- " line)) lines "\n")
                  "- none")
                "\n")
        cea/elpaca-check--report))

(defun cea/elpaca-check--one-line (string)
  (string-trim (replace-regexp-in-string "[ \t\n]+" " " string)))

(defun cea/elpaca-check--failed ()
  (mapcar (lambda (pair) (format "%s: %s" (car pair) (cdr pair)))
          (cea/elpaca-upgrade-failed-ids)))

(defun cea/elpaca-check--warnings ()
  (when-let* ((buffer (get-buffer "*Warnings*")))
    (with-current-buffer buffer
      (seq-uniq
       (seq-remove #'string-empty-p
                   (mapcar #'cea/elpaca-check--one-line
                           (split-string (buffer-string) "^Warning " t)))))))

;; Most packages are deferred by use-package, so booting alone never loads
;; them; requiring each one catches packages that fail to load at all.
;; - Casey, Tue Nov 10 2026
(defun cea/elpaca-check--require-all ()
  (let (errors)
    (dolist (pair (elpaca--queued))
      (let ((feature (car pair)))
        (when (locate-library (symbol-name feature))
          (condition-case err
              (require feature)
            (error (push (format "%s: %s" feature
                                 (cea/elpaca-check--one-line (error-message-string err)))
                         errors))))))
    (sort errors #'string<)))

;; Compiling the config with every package already loaded is what makes the
;; compiler see obsolete, removed, and changed-arity functions and variables
;; the config still uses. - Casey, Tue Nov 10 2026
(defun cea/elpaca-check--compile-config ()
  (let* ((source literate-config-el-file-name)
         (dest (cea/elpaca-upgrade-output-file "config-check.elc"))
         (byte-compile-dest-file-function (lambda (_) dest))
         warnings)
    (let ((byte-compile-log-warning-function
           (lambda (string &optional position _fill _level)
             (push (cons position (cea/elpaca-check--one-line string)) warnings))))
      (byte-compile-file source))
    (when (file-exists-p dest) (delete-file dest))
    (with-temp-buffer
      (insert-file-contents source)
      (seq-uniq
       (mapcar (lambda (warning)
                 (format "config.el:%s: %s"
                         (if (integerp (car warning))
                             (line-number-at-pos (min (car warning) (point-max)))
                           "?")
                         (cdr warning)))
               (sort warnings (lambda (a b) (< (or (car a) 0) (or (car b) 0)))))))))

(defun cea/elpaca-check--lock-differences ()
  "Return differences between the checked-out packages and the lock file."
  (let ((lock (cea/elpaca-upgrade-read-lock-file elpaca-lock-file))
        differences)
    (dolist (repo (cea/elpaca-upgrade-repos))
      (let ((head (cea/elpaca-upgrade-git (car repo) "rev-parse" "HEAD")))
        (dolist (id (cdr repo))
          (let ((ref (alist-get id lock)))
            (cond ((null ref)
                   (push (format "%s: installed but not in the lock file" id) differences))
                  ((not (equal ref head))
                   (push (format "%s: checked out %s, lock file has %s"
                                 id (substring head 0 12) (substring ref 0 12))
                         differences)))))))
    (dolist (entry lock)
      (unless (elpaca-get (car entry))
        (push (format "%s: in the lock file but not installed" (car entry)) differences)))
    (sort differences #'string<)))

;; Elpaca reformats recipes between versions, so the raw lock file diff can
;; be noisy even when few refs moved. - Casey, Tue Nov 10 2026
(defun cea/elpaca-check--committed-lock-changes ()
  "Return the ref changes between HEAD's lock file and the current one."
  (when-let* ((committed (cea/elpaca-upgrade-git user-emacs-directory "show" "HEAD:elpaca-lock.el")))
    (let ((old (with-temp-buffer
                 (insert committed)
                 (let ((file (make-temp-file "elpaca-lock-")))
                   (unwind-protect
                       (progn (write-region nil nil file nil 'silent)
                              (cea/elpaca-upgrade-read-lock-file file))
                     (delete-file file)))))
          (new (cea/elpaca-upgrade-read-lock-file elpaca-lock-file))
          changes)
      (dolist (entry new)
        (let ((old-ref (alist-get (car entry) old)))
          (cond ((null old-ref)
                 (push (format "%s: added at %s" (car entry) (substring (cdr entry) 0 12)) changes))
                ((not (equal old-ref (cdr entry)))
                 (push (format "%s: %s -> %s" (car entry)
                               (substring old-ref 0 12) (substring (cdr entry) 0 12))
                       changes)))))
      (dolist (entry old)
        (unless (assq (car entry) new)
          (push (format "%s: removed" (car entry)) changes)))
      (sort changes #'string<))))

(defun cea/elpaca-check--run ()
  (let ((label (or (cea/elpaca-upgrade-option "--label") "check"))
        (vterm-always-compile-module t))
    (elpaca-wait)
    (cea/elpaca-check--section "Packages That Did Not Finish" (cea/elpaca-check--failed))
    (cea/elpaca-check--section "Startup Warnings" (cea/elpaca-check--warnings))
    (cea/elpaca-check--section "Packages That Fail To Load" (cea/elpaca-check--require-all))
    (cea/elpaca-check--section "Config Compile Warnings" (cea/elpaca-check--compile-config))
    (cea/elpaca-check--section "Stale Builds"
                               (mapcar #'symbol-name (cea/elpaca-upgrade-stale-ids)))
    (when (cea/elpaca-upgrade-flag-p "--write-lock")
      (cea/elpaca-upgrade-write-lock-file))
    (cea/elpaca-check--section "Differences From Lock File"
                               (cea/elpaca-check--lock-differences))
    (cea/elpaca-check--section "Lock File Changes Since HEAD"
                               (cea/elpaca-check--committed-lock-changes))
    (let ((file (cea/elpaca-upgrade-output-file (format "check-%s.md" label)))
          (report (concat (format "# Check - %s\n\n" label)
                          (string-join (reverse cea/elpaca-check--report) "\n"))))
      (with-temp-file file (insert report))
      (message "\n%s\nWrote %s" report file))))

(cea/elpaca-upgrade-main #'cea/elpaca-check--run)
