(setq racer-cmd "/home/sbditto85/.cargo/bin/racer")
(setq racer-rust-src-path "/usr/local/src/rustc-1.9.0/src/")

(add-hook 'rust-mode-hook #'racer-mode)
(add-hook 'racer-mode-hook #'eldoc-mode)

(add-hook 'racer-mode-hook #'company-mode)

(global-set-key (kbd "TAB") #'company-indent-or-complete-common) ;
(setq company-tooltip-align-annotations t)
