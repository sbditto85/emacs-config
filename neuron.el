(defvar neuron-map
  (let ((map (make-sparse-keymap)))
    (define-key map "b" 'magit-blame)
    (define-key map "c" 'write-context)
    (define-key map "m" 'write-modules)
    (define-key map "r" 'ripgrep-regexp)
    map)
  "Neuron key map.")

(global-set-key (kbd "s-n") neuron-map)
