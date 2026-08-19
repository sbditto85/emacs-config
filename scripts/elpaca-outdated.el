;;; elpaca-outdated.el -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch --init-directory=. -l init.el -l scripts/elpaca-outdated.el
;;
;; Loads the real config so every declared package is queued with Elpaca,
;; then for each package's git repo: fetches origin and compares the
;; currently checked-out commit (the one pinned in elpaca-lock.el) against
;; origin's default branch tip.
;;
;; Writes one tab-separated line per repo with pending updates to
;; var/elpaca-outdated.tsv:
;;   package-ids(comma separated)<TAB>source-dir<TAB>remote-url<TAB>old-ref<TAB>new-ref
;;
;; A single line covers every package id sharing that source dir (mono-repos
;; like treemacs, magit, dired-hacks, embark all check out one directory).

(defun cea/elpaca-outdated--git (dir &rest args)
  "Run git ARGS in DIR, returning trimmed stdout."
  (with-temp-buffer
    (let ((default-directory (file-name-as-directory dir)))
      (apply #'call-process "git" nil t nil args))
    (string-trim (buffer-string))))

(defun cea/elpaca-outdated--default-branch (dir)
  "Return DIR's origin default branch name, falling back to \"master\"."
  (let ((ref (cea/elpaca-outdated--git dir "symbolic-ref" "refs/remotes/origin/HEAD")))
    (if (string-empty-p ref) "master" (file-name-nondirectory ref))))

(defun cea/elpaca-outdated--source-dirs ()
  "Return alist of (source-dir . package-ids) for every queued, git-backed package."
  (let ((groups (make-hash-table :test 'equal)))
    (dolist (pair (elpaca--queued))
      (let* ((id (car pair))
             (e (cdr pair))
             (dir (ignore-errors (elpaca<-source-dir e))))
        (when (and dir (file-directory-p (expand-file-name ".git" dir)))
          (puthash dir (cons id (gethash dir groups)) groups))))
    (let (alist)
      (maphash (lambda (dir ids) (push (cons dir (nreverse ids)) alist)) groups)
      alist)))

(defun cea/elpaca-outdated--run ()
  (let* ((groups (cea/elpaca-outdated--source-dirs))
         (out-file (expand-file-name "var/elpaca-outdated.tsv" user-emacs-directory))
         (total (length groups))
         (found 0)
         (index 0))
    (make-directory (file-name-directory out-file) t)
    (with-temp-file out-file
      (dolist (group groups)
        (cl-incf index)
        (let* ((dir (car group))
               (ids (cdr group))
               (old-ref (cea/elpaca-outdated--git dir "rev-parse" "HEAD")))
          (message "[%d/%d] Fetching %s (%s)..." index total (car ids) dir)
          (cea/elpaca-outdated--git dir "fetch" "origin" "--quiet")
          (let* ((branch (cea/elpaca-outdated--default-branch dir))
                 (new-ref (cea/elpaca-outdated--git dir "rev-parse" (format "origin/%s" branch)))
                 (url (cea/elpaca-outdated--git dir "remote" "get-url" "origin")))
            (unless (string= old-ref new-ref)
              (cl-incf found)
              (insert (format "%s\t%s\t%s\t%s\t%s\n"
                              (mapconcat #'symbol-name ids ",")
                              dir url old-ref new-ref)))))))
    (message "Checked %d repos, %d have pending updates. Wrote %s" total found out-file)))

(require 'cl-lib)
(cea/elpaca-outdated--run)
