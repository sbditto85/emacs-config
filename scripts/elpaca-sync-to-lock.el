;;; elpaca-sync-to-lock.el -*- lexical-binding: t; -*-

;; Elpaca only reads the lock file when installing a package, so an
;; existing checkout stays where it is after the lock file changes; this
;; moves each one to its locked ref. - Casey, Tue Nov 10 2026
(defun cea/elpaca-sync--repo-ref (lock ids)
  (seq-some (lambda (id) (alist-get id lock)) ids))

(defun cea/elpaca-sync--has-commit-p (dir ref)
  (cea/elpaca-upgrade-git dir "cat-file" "-e" (concat ref "^{commit}")))

;; Fetching from the candidate's checkout gets exactly the reviewed commits
;; without the network, and still works if upstream has since rewritten
;; its history. - Casey, Tue Nov 10 2026
(defun cea/elpaca-sync--fetch (dir ref)
  (let* ((name (cea/elpaca-upgrade-repo-name dir))
         (from-sources (cea/elpaca-upgrade-option "--from-sources"))
         (local (and from-sources (expand-file-name name from-sources))))
    (when (and local (file-directory-p local))
      (message "Fetching %s from %s" name local)
      (cea/elpaca-upgrade-git dir "fetch" "--quiet" local ref))
    (unless (cea/elpaca-sync--has-commit-p dir ref)
      (message "Fetching %s from origin" name)
      (cea/elpaca-upgrade-git! dir "fetch" "--quiet" "origin"))))

(defun cea/elpaca-sync--checkout (dir ref)
  (unless (cea/elpaca-sync--has-commit-p dir ref)
    (cea/elpaca-sync--fetch dir ref))
  (cea/elpaca-upgrade-git! dir "checkout" "--quiet" "--detach" ref))

(defun cea/elpaca-sync--run ()
  ;; Waiting first installs packages that are new in the lock file, using
  ;; the locked ref from their lock file recipe. - Casey, Tue Nov 10 2026
  (elpaca-wait)
  (let ((lock (cea/elpaca-upgrade-read-lock-file elpaca-lock-file))
        (dry-run (cea/elpaca-upgrade-flag-p "--dry-run"))
        ids)
    (dolist (repo (cea/elpaca-upgrade-repos))
      (let ((dir (car repo))
            (ref (cea/elpaca-sync--repo-ref lock (cdr repo))))
        (when (and ref (not (equal ref (cea/elpaca-upgrade-git dir "rev-parse" "HEAD"))))
          (message "%s %s to %s" (if dry-run "Would move" "Moving")
                   (cea/elpaca-upgrade-repo-name dir) ref)
          (unless dry-run (cea/elpaca-sync--checkout dir ref))
          (setq ids (append ids (cdr repo))))))
    (setq ids (cl-union ids (cea/elpaca-upgrade-stale-ids)))
    (cond ((null ids) (message "Already in sync with %s" elpaca-lock-file))
          (dry-run (message "Would rebuild: %s" (mapconcat #'symbol-name ids ", ")))
          (t (cea/elpaca-upgrade-rebuild (sort ids #'string<))
             (when-let* ((failed (cea/elpaca-upgrade-failed-ids)))
               (error "Packages did not finish building: %S" failed))
             (message "Rebuilt: %s" (mapconcat #'symbol-name ids ", "))))))

(cea/elpaca-upgrade-main #'cea/elpaca-sync--run)
