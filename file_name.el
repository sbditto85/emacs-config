(defun copy-file-name ()
  (interactive)
  (kill-new (car (projectile-make-relative-to-root (list (buffer-file-name)))))
  )
