;;; document-markup-mode.el --- Major mode for document markup -*- lexical-binding: t; -*-

;; Author: Wilson Sonsini
;; Version: 1.0
;; Keywords: languages, wp

;;; Commentary:

;; Major mode for editing document markup files used by docx-markup and
;; template-markup.  Provides syntax highlighting for tags like
;; {bold}...{:bold}, {insert: var}, {if: cond}...{:if}, etc.
;;
;; Also provides commands to wrap a region in bold or italic tags.

;;; Code:

(defgroup document-markup nil
  "Major mode for document markup."
  :group 'languages)

(defface document-markup-tag-face
  '((t :inherit font-lock-keyword-face))
  "Face for markup tags like {bold}, {:bold}, {p}, {page-break}."
  :group 'document-markup)

(defface document-markup-closing-tag-face
  '((t :inherit font-lock-keyword-face))
  "Face for closing markup tags like {:bold}."
  :group 'document-markup)

(defface document-markup-template-face
  '((t :inherit font-lock-function-name-face))
  "Face for template tags like {insert:}, {if:}, {each:}."
  :group 'document-markup)

(defface document-markup-parameter-face
  '((t :inherit font-lock-variable-name-face))
  "Face for tag parameters and references."
  :group 'document-markup)

(defface document-markup-format-face
  '((t :inherit font-lock-type-face))
  "Face for formatting tags like {bold}, {italic}, {underline}."
  :group 'document-markup)

(defface document-markup-structure-face
  '((t :inherit font-lock-builtin-face))
  "Face for structural tags like {table}, {p}, {heading-1}."
  :group 'document-markup)

(defface document-markup-escape-face
  '((t :inherit font-lock-constant-face))
  "Face for escape sequences like \\{ and \\}."
  :group 'document-markup)

(defface document-markup-string-face
  '((t :inherit font-lock-string-face))
  "Face for quoted strings in parameters."
  :group 'document-markup)

(defface document-markup-break-face
  '((t :inherit font-lock-warning-face))
  "Face for break tags like {page-break}, {line-break}."
  :group 'document-markup)

;; Formatting tag names
(defconst document-markup--format-tags
  '("bold" "italic" "underline" "uppercase" "error" "white-space")
  "Tag names for character formatting.")

;; Structural tag names
(defconst document-markup--structure-tags
  '("p" "heading-1" "table" "table-row" "table-cell"
    "footer" "section-break" "level-1"
    "hyperlink" "bookmark" "bookmark-link" "bookmark-link-relative"
    "signature-field" "inline-signature-field" "signing-role" "party-name"
    "signature" "date-signature" "signature-block" "signature-block-signature"
    "signature-page-preamble" "signature-page-footer" "prescribed-legend"
    "rspa-section" "rspa-subsection" "rspa-subsubsection"
    "rspa-exhibit" "rspa-exhibit-title" "rspa-exhibit-indent"
    "rspa-conspicuous" "rspa-conspicuous-small"
    "rspa-page-number" "rspa-section-title-page"
    "rspa-signature-block" "rspa-signature-block-signature"
    "exhibit-title"
    "delimited-list" "enumerated-list" "delimiter" "enumerator")
  "Tag names for structural elements.")

;; Break tag names
(defconst document-markup--break-tags
  '("line-break" "column-break" "page-break" "tab"
    "non-breaking-space" "non-breaking-hyphen" "no-leading-space")
  "Tag names for break/whitespace elements.")

;; Template tag names
(defconst document-markup--template-tags
  '("insert" "if" "if-not" "else" "else-if" "else-if-not"
    "each" "render")
  "Tag names for template directives.")

(defconst document-markup--format-re
  (concat "\\({:?\\)\\("
          (regexp-opt document-markup--format-tags)
          "\\)\\([^}]*\\)\\(}\\)")
  "Regexp matching formatting tags.")

(defconst document-markup--structure-re
  (concat "\\({:?\\)\\("
          (regexp-opt document-markup--structure-tags)
          "\\)\\([^}]*\\)\\(}\\)")
  "Regexp matching structural tags.")

(defconst document-markup--break-re
  (concat "\\({\\)\\("
          (regexp-opt document-markup--break-tags)
          "\\)\\([^}]*\\)\\(}\\)")
  "Regexp matching break tags.")

(defconst document-markup--template-re
  (concat "\\({:?\\)\\("
          (regexp-opt document-markup--template-tags)
          "\\)\\(:[^}]*\\|\\)\\(}\\)")
  "Regexp matching template tags.")

(defconst document-markup-font-lock-keywords
  `(
    ;; Escape sequences: \{ and \}
    ("\\\\[{}]" . 'document-markup-escape-face)

    ;; Template tags: {insert: var}, {if: cond}, {each: arr as=item}
    (,document-markup--template-re
     (1 'document-markup-tag-face)
     (2 'document-markup-template-face)
     (3 'document-markup-parameter-face)
     (4 'document-markup-tag-face))

    ;; Formatting tags: {bold}, {:bold}, {italic}, etc.
    (,document-markup--format-re
     (1 'document-markup-tag-face)
     (2 'document-markup-format-face)
     (3 'document-markup-parameter-face)
     (4 'document-markup-tag-face))

    ;; Break tags: {page-break}, {line-break}, {tab}
    (,document-markup--break-re
     (1 'document-markup-tag-face)
     (2 'document-markup-break-face)
     (3 'document-markup-parameter-face)
     (4 'document-markup-tag-face))

    ;; Structure tags: {table}, {p}, {heading-1}, etc.
    (,document-markup--structure-re
     (1 'document-markup-tag-face)
     (2 'document-markup-structure-face)
     (3 'document-markup-parameter-face)
     (4 'document-markup-tag-face))

    ;; Quoted strings inside tags (parameter values)
    ("{[^}]*\\(\"[^\"]*\"\\)[^}]*}" 1 'document-markup-string-face t)

    ;; Catch-all for any remaining tags
    ("\\({:?\\)\\([a-z][a-z0-9-]*\\)\\([^}]*\\)\\(}\\)"
     (1 'document-markup-tag-face)
     (2 'document-markup-tag-face)
     (3 'document-markup-parameter-face)
     (4 'document-markup-tag-face))
    )
  "Font-lock keywords for `document-markup-mode'.")

;;;###autoload
(defun document-markup-wrap-bold (beg end)
  "Wrap the region from BEG to END with {bold}...{:bold} tags.
When called interactively, wraps the active region."
  (interactive "r")
  (document-markup--wrap-region beg end "bold"))

;;;###autoload
(defun document-markup-wrap-italic (beg end)
  "Wrap the region from BEG to END with {italic}...{:italic} tags.
When called interactively, wraps the active region."
  (interactive "r")
  (document-markup--wrap-region beg end "italic"))

;;;###autoload
(defun document-markup-wrap-underline (beg end)
  "Wrap the region from BEG to END with {underline}...{:underline} tags.
When called interactively, wraps the active region."
  (interactive "r")
  (document-markup--wrap-region beg end "underline"))

(defun document-markup--wrap-region (beg end tag)
  "Wrap the region from BEG to END with {TAG}...{:TAG}."
  (save-excursion
    (goto-char end)
    (insert "{:" tag "}")
    (goto-char beg)
    (insert "{" tag "}")))

(defvar document-markup-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-b") #'document-markup-wrap-bold)
    (define-key map (kbd "C-c C-i") #'document-markup-wrap-italic)
    (define-key map (kbd "C-c C-u") #'document-markup-wrap-underline)
    map)
  "Keymap for `document-markup-mode'.")

;;;###autoload
(define-derived-mode document-markup-mode text-mode "Document-Markup"
  "Major mode for editing document markup files used by docx-markup
and template-markup.

Tags use the syntax {tag-name}content{:tag-name} with optional
parameters like {tag-name: key=value}.

\\{document-markup-mode-map}"
  (setq font-lock-defaults '(document-markup-font-lock-keywords))
  (setq font-lock-multiline t))

(provide 'document-markup-mode)

;;; document-markup-mode.el ends here
