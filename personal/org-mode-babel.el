;; active Org-babel languages
(org-babel-do-load-languages
 'org-babel-load-languages
 '(;; other Babel languages
   (plantuml . t)))


(setq org-plantuml-jar-path
      (expand-file-name "~/Downloads/plantuml.1.2017.12.jar"))
