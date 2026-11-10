;;; elpaca-apply-update.el -*- lexical-binding: t; -*-

;; Checking out the exact reviewed ref, rather than pulling, keeps commits
;; that landed upstream after the review from being picked up.
;; - Casey, Tue Nov 10 2026
(defun cea/elpaca-apply--checkout (spec)
  "Check out the REPO=REF SPEC and return the package ids it provides."
  (unless (string-match "\\`\\([^=]+\\)=\\([0-9a-f]\\{7,40\\}\\)\\'" spec)
    (error "Malformed argument %S, expected REPO=REF" spec))
  (let* ((name (match-string 1 spec))
         (ref (match-string 2 spec))
         (repo (cea/elpaca-upgrade-find-repo name))
         (dir (car repo)))
    (unless (cea/elpaca-upgrade-git dir "cat-file" "-e" (concat ref "^{commit}"))
      (error "%s has no commit %s; run the scan again" name ref))
    (message "Checking out %s at %s (%s)" name ref
             (mapconcat #'symbol-name (cdr repo) ", "))
    (cea/elpaca-upgrade-git! dir "checkout" "--quiet" "--detach" ref)
    (cdr repo)))

(defun cea/elpaca-apply--run ()
  (let* ((ids (mapcan #'cea/elpaca-apply--checkout (cea/elpaca-upgrade-positional-args)))
         (ids (cl-union ids (cea/elpaca-upgrade-stale-ids))))
    (unless ids
      (error "Nothing to apply. Usage: -- REPO=REF ..."))
    (elpaca-wait)
    (cea/elpaca-upgrade-rebuild (sort ids #'string<))
    (when-let* ((failed (cea/elpaca-upgrade-failed-ids)))
      (error "Packages did not finish building: %S" failed))
    (message "Rebuilt: %s" (mapconcat #'symbol-name ids ", "))))

(cea/elpaca-upgrade-main #'cea/elpaca-apply--run)
