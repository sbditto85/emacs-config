(defun set-sharing-font-size ()
  (interactive)
  (set-face-attribute 'default nil :height 185)
  )

(defun set-solo-font-size ()
  (interactive)
  (set-face-attribute 'default nil :height 150)
  )

(set-solo-font-size)
