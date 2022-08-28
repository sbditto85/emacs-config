(defun write-module (idx names)
  (concat
   (make-string (* 2 idx) ?\s)
   "module "
   (car names)
   "\n"
   (if (length= (cdr names) 0)
       ""
     (write_module (1+ idx) (cdr names))
     )
   (make-string (* 2 idx) ?\s)
   "end\n"
   )
  )

(defun write-modules ()
  (interactive)
  (insert
   (write-module
    0
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
    )
   )
  )
