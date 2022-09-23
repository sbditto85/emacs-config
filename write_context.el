(defun write-context (idx names)
  (concat
   (make-string (* 2 idx) ?\s)
   "context \""
   (replace-regexp-in-string
    "_"
    " "
    (string-inflection-capital-underscore-function (car names))
    )
   "\" do\n"
   (if (length= (cdr names) 0)
       ""
     (write-context (1+ idx) (cdr names))
     )
   (make-string (* 2 idx) ?\s)
   "end\n"
   )
  )


(defun write-contexts-get-directories ()
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

(defun write-contexts-write-up-dir (names)
  (insert "../")
  (if (length= (cdr names) 0)
      ()
    (write-contexts-write-up-dir (cdr names))
    )
  )

(defun write-contexts-write-require-relative ()
  (insert "require_relative \"")
  (write-contexts-write-up-dir (write-contexts-get-directories))
  (insert "automated_init\"\n\n")
  )

(defun write-contexts ()
  (interactive)
  (write-contexts-write-require-relative)
  (insert
   (write-context
    0
    (write-contexts-get-directories)
    )
   )
  )
