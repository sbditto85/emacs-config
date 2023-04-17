(defun set-sharing ()
  (interactive)
  (set-face-attribute 'default nil :height 185)
  (setq magit-status-headers-hook
        '(magit-insert-error-header magit-insert-diff-filter-header magit-insert-head-branch-header))
  )

(defun set-solo ()
  (interactive)
  (set-face-attribute 'default nil :height 150)
  (setq magit-status-headers-hook
        '(magit-insert-error-header magit-insert-diff-filter-header magit-insert-head-branch-header magit-insert-upstream-branch-header magit-insert-push-branch-header magit-insert-tags-header))
  )

(set-solo)
