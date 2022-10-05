(global-set-key (kbd "M-n") (lambda() (interactive) (next-line 5)))
(global-set-key (kbd "M-p") (lambda() (interactive) (previous-line 5)))


(add-hook 'markdown-mode-hook
          (lambda ()
            (local-set-key (kbd "M-n") nil)
            (local-set-key (kbd "M-p") nil)))
