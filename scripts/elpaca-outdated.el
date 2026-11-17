;;; elpaca-outdated.el -*- lexical-binding: t; -*-

(defun cea/elpaca-outdated--target-branch (dir e)
  (or (plist-get (elpaca<-recipe e) :branch)
      (when-let* ((ref (cea/elpaca-upgrade-git dir "symbolic-ref" "--short" "refs/remotes/origin/HEAD")))
        (string-remove-prefix "origin/" ref))
      "master"))

(defun cea/elpaca-outdated--row (dir ids)
  "Fetch DIR and return a TSV row if its upstream branch has moved on."
  ;; `git fetch' never updates `origin/HEAD' and keeps remote-tracking
  ;; branches that upstream deleted, so after an upstream default branch
  ;; rename (master to main) the clone still points at the old branch.
  ;; Pruning drops the deleted branch and `set-head --auto' re-reads the
  ;; remote's default branch.
  (cea/elpaca-upgrade-git! dir "fetch" "--quiet" "--prune" "origin")
  (cea/elpaca-upgrade-git dir "remote" "set-head" "origin" "--auto")
  (let* ((e (elpaca-get (car ids)))
         (branch (cea/elpaca-outdated--target-branch dir e))
         (old-ref (cea/elpaca-upgrade-git! dir "rev-parse" "HEAD"))
         (new-ref (cea/elpaca-upgrade-git! dir "rev-parse" (concat "origin/" branch))))
    ;; A locked commit that already contains the branch tip is not
    ;; outdated; applying the tip would be a downgrade.
    (unless (or (string= old-ref new-ref)
                (cea/elpaca-upgrade-git dir "merge-base" "--is-ancestor" new-ref old-ref))
      (let ((fast-forward (cea/elpaca-upgrade-git dir "merge-base" "--is-ancestor" old-ref new-ref))
            (commits (cea/elpaca-upgrade-git! dir "rev-list" "--count" (concat old-ref ".." new-ref)))
            (files (cea/elpaca-upgrade-git! dir "diff" "--shortstat" old-ref new-ref)))
        (string-join
         (list (cea/elpaca-upgrade-repo-name dir)
               (mapconcat #'symbol-name ids ",")
               dir
               (or (cea/elpaca-upgrade-git dir "remote" "get-url" "origin") "")
               old-ref
               new-ref
               branch
               commits
               ;; A rewritten upstream history is a supply-chain warning
               ;; sign, so it is reported rather than hidden.
               ;; - Casey, Tue Nov 10 2026
               (if fast-forward "yes" "NO")
               files)
         "\t")))))

(defun cea/elpaca-outdated--run ()
  (let* ((repos (cea/elpaca-upgrade-repos))
         (out-file (cea/elpaca-upgrade-output-file "outdated.tsv"))
         (total (length repos))
         (index 0)
         rows errors)
    (dolist (repo repos)
      (cl-incf index)
      (message "[%d/%d] %s" index total (cea/elpaca-upgrade-repo-name (car repo)))
      (condition-case err
          (when-let* ((row (cea/elpaca-outdated--row (car repo) (cdr repo))))
            (push row rows))
        (error (push (format "%s: %s" (car repo) (error-message-string err)) errors))))
    (setq rows (nreverse rows))
    (with-temp-file out-file
      (insert "repo\tids\tsource-dir\turl\told-ref\tnew-ref\tbranch\tcommits\tfast-forward\tchanges\n")
      (dolist (row rows) (insert row "\n")))
    (message "Checked %d repos, %d have updates. Wrote %s" total (length rows) out-file)
    (when-let* ((stale (cea/elpaca-upgrade-stale-ids)))
      (message "Stale builds (rebuilt by the apply step): %s"
               (mapconcat #'symbol-name stale ", ")))
    (when errors
      (error "Could not check %d repos:\n%s" (length errors) (string-join (nreverse errors) "\n")))))

(cea/elpaca-upgrade-main #'cea/elpaca-outdated--run)
