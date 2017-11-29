;;; package --- Summary
;;; Commentary:
;;; Code:

(defun insert-esqueletto-skeleton ()
  "Insert the template for an esqueletto query."
  (interactive)
  (insert "rows <- runDB $ E.select \n$ E.from $ \() -> do \nE.on $ \nE.where_ $ \nreturn (\n)")
  )

(defun my-haskell-mode-config ()
  "For use in `haskell-mode-hook'."
  (local-set-key (kbd "C-c 1") 'insert-esqueletto-skeleton)
  )

(add-hook 'haskell-mode-hook 'my-haskell-mode-config)

;;; haskell-my.el ends here
