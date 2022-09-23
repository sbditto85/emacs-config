(defun insert-date-time ()
  (interactive)
  (insert (format-time-string "%a %b %d %Y")))


(defun comment-attribution ()
  (interactive)
  (insert "- Casey, ")
  (insert-date-time)
  )


(global-set-key (kbd "C-M-a") (lambda() (interactive) (comment-attribution)))
