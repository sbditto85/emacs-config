;;; early-init.el -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil)

;; ;; Used to indicate the desired font
;; ;; ## Not sure if I want to change the font, leaving here for a record on how to do so in the future
(setq custom/monospace-font "JetBrains Mono NL"
      custom/monospace-font-size 15)

;; Configure default frame settings before the first frame is shown
(setq default-frame-alist
      (append
       (list
        `(font . ,(concat custom/monospace-font "-" (number-to-string custom/monospace-font-size))))
       default-frame-alist))
