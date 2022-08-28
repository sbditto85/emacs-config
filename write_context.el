(defun write-context (idx names)
  (concat
   (make-string (* 2 idx) ?\s)
   "context \""
   (car names)
   "\"\n"
   (if (length= (cdr names) 0)
       ""
     (write-context (1+ idx) (cdr names))
     )
   (make-string (* 2 idx) ?\s)
   "end\n"
   )
  )


(defun write-contexts ()
  (interactive)
  (insert
   (write-context
    0
    (seq-drop
     (seq-drop-while
      (lambda (elt) (not (string-equal elt "automated") ))
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
