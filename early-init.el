;;; early-init.el -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil)

;; ;; Used to indicate the desired font
;; ;; ## Not sure if I want to change the font, leaving here for a record on how to do so in the future
;; (setq c/monospace-font "JetBrains Mono NL"
;;       c/monospace-font-size 15)

;; ;; Configure default frame settings before the first frame is shown
;; (setq default-frame-alist
;;       (append
;;        (list
;;         `(font . ,(concat c/monospace-font "-" (number-to-string c/monospace-font-size))))
;;        default-frame-alist))
