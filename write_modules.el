(defun write-module (idx names)
  (concat
   (make-string (* 2 idx) ?\s)
   "module "
   (replace-regexp-in-string
    "_"
    ""
    (string-inflection-capital-underscore-function (car names))
    )
   "\n"
   (if (length= (cdr names) 0)
       ""
     (write-module (1+ idx) (cdr names))
     )
   (make-string (* 2 idx) ?\s)
   "end\n"
   )
  )

(defun write-module-get-directories ()
  (append
   (seq-drop
    (seq-drop-while
     (lambda (elt) (not (string-equal elt "lib") ))
     (split-string
      (string-trim
       (file-name-directory
        (buffer-file-name)
        )
       "/"
       "/"
       )
      "/"
      )
     )
    1)
   (list
    (file-name-base
     (buffer-file-name)
     )
    )
   )
  )

(defun write-modules ()
  (interactive)
  (insert
   (write-module
    0
    (write-module-get-directories)
    )
   )
  )
