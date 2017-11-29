(autoload 'gedcom-mode "gedcom")
(setq auto-mode-alist (cons '("\\.ged$" . gedcom-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("lltmp[0-9a-zA-Z.]+$" . gedcom-mode) auto-mode-alist))
