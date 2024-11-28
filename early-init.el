;;; early-init.el -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil)

;; ;; Used to indicate the desired font
;; ;; ## Not sure if I want to change the font, leaving here for a record on how to do so in the future
(setq custom/monospace-font "JetBrains Mono NL"
      custom/monospace-font-size 15)

(setq frame-inhibit-implied-resize t)

;; Configure default frame settings before the first frame is shown
(setq default-frame-alist
      (append
       (list
        `(font . ,(concat custom/monospace-font "-" (number-to-string custom/monospace-font-size)))
        ;; Research and verify these are what I want - Casey, Wed Nov 27 2024
        ;; '(internal-border-width . 0)
        ;; '(undecorated-round . t)
        ;; '(left-fringe . 16)
        ;; '(right-fringe . 16))
        )
       default-frame-alist))

(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(menu-bar-mode -1)

(set-fringe-mode 10) ; Give some breathing room

(column-number-mode)
(global-display-line-numbers-mode t)
(tab-bar-mode 1)
