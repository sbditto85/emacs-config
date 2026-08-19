;;; elpaca-apply-update.el -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch --init-directory=. -l init.el -l scripts/elpaca-apply-update.el -- \
;;     DIR1=REF1 DIR2=REF2 ...
;;
;; Each trailing argument is a source-dir=target-ref pair, exactly as found
;; in var/elpaca-outdated.tsv (the "source-dir" and "new-ref" columns) for
;; every repo whose update was approved. For a mono-repo (treemacs, magit,
;; embark, dired-hacks, etc.) this only needs to be listed once even though
;; it provides several package ids.
;;
;; For each pair: checks out REF in DIR with plain git (exact, no re-fetch,
;; no risk of picking up commits that landed after review), then asks
;; Elpaca to rebuild every queued package id backed by that dir. Once every
;; rebuild has finished, regenerates elpaca-lock.el via Elpaca's own
;; elpaca-write-lock-file so the lock file reflects reality rather than
;; being hand-edited.

(defun cea/elpaca-apply--git (dir &rest args)
  (with-temp-buffer
    (let ((default-directory (file-name-as-directory dir)))
      (unless (zerop (apply #'call-process "git" nil t nil args))
        (error "git %s failed in %s: %s" args dir (buffer-string))))
    (string-trim (buffer-string))))

(defun cea/elpaca-apply--ids-for-dir (dir)
  (let (ids)
    (dolist (pair (elpaca--queued))
      (when (equal (ignore-errors (elpaca<-source-dir (cdr pair))) dir)
        (push (car pair) ids)))
    (nreverse ids)))

(defun cea/elpaca-apply--run (pairs)
  (unless pairs
    (error "Usage: -- DIR1=REF1 DIR2=REF2 ..."))
  (let (all-ids)
    (dolist (pair pairs)
      (unless (string-match "\\`\\(.+\\)=\\([0-9a-f]+\\)\\'" pair)
        (error "Malformed argument %S, expected DIR=REF" pair))
      (let* ((dir (expand-file-name (match-string 1 pair)))
             (ref (match-string 2 pair))
             (ids (cea/elpaca-apply--ids-for-dir dir)))
        (unless ids (error "No queued packages found for source-dir %s" dir))
        (message "Checking out %s in %s (packages: %s)" ref dir
                 (mapconcat #'symbol-name ids ", "))
        (cea/elpaca-apply--git dir "checkout" "--detach" ref)
        (dolist (id ids)
          (push id all-ids)
          (message "Queuing rebuild for %s" id)
          (elpaca-rebuild id))))
    (message "Waiting for rebuilds to finish...")
    (elpaca-wait)
    (message "Writing lock file to %s" elpaca-lock-file)
    (elpaca-write-lock-file elpaca-lock-file)
    (message "Done. Updated: %s" (mapconcat #'symbol-name (nreverse all-ids) ", "))))

(cea/elpaca-apply--run (cdr (member "--" command-line-args)))
