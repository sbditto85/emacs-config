;;; git-review.el --- Review git status like a pull request -*- lexical-binding: t; -*-

;; Author: Claude
;; Version: 2.0
;; Keywords: git, vc, tools
;; Package-Requires: ((emacs "28.1"))

;;; Commentary:

;; Provides a PR-review-like interface for reviewing the current git
;; working tree.  Shows a side-by-side diff with a file list at the
;; bottom.  Supports staging/unstaging files and individual hunks.
;;
;; Each file shows one entry.  Use TAB to toggle between viewing
;; staged vs unstaged changes when a file has both.
;;
;;   Unstaged view: left = index, right = worktree  (s to stage)
;;   Staged view:   left = HEAD,  right = index     (u to unstage)
;;
;; Entry point: M-x git-review

;;; Code:

(require 'cl-lib)

;; ---------------------------------------------------------------------------
;; Faces
;; ---------------------------------------------------------------------------

(defface git-review-added-face
  '((t :inherit diff-added))
  "Face for added lines in git-review."
  :group 'git-review)

(defface git-review-removed-face
  '((t :inherit diff-removed))
  "Face for removed lines in git-review."
  :group 'git-review)

(defface git-review-file-header-face
  '((t :inherit font-lock-function-name-face :weight bold))
  "Face for file headers in the file list."
  :group 'git-review)

(defface git-review-status-modified-face
  '((t :inherit warning))
  "Face for modified file status."
  :group 'git-review)

(defface git-review-status-added-face
  '((t :inherit success))
  "Face for added/untracked file status."
  :group 'git-review)

(defface git-review-status-deleted-face
  '((t :inherit error))
  "Face for deleted file status."
  :group 'git-review)

(defface git-review-current-file-face
  '((t :inherit highlight))
  "Face for the currently selected file in the list."
  :group 'git-review)

(defface git-review-hunk-header-face
  '((t :inherit diff-hunk-header))
  "Face for hunk boundary markers."
  :group 'git-review)

(defface git-review-view-indicator-face
  '((t :inherit font-lock-warning-face :weight bold))
  "Face for the staged/unstaged view indicator."
  :group 'git-review)

(defface git-review-added-word-face
  '((t :inherit diff-refine-added))
  "Face for added characters within added lines in git-review."
  :group 'git-review)

(defface git-review-removed-word-face
  '((t :inherit diff-refine-removed))
  "Face for removed characters within removed lines in git-review."
  :group 'git-review)

;; ---------------------------------------------------------------------------
;; Data structures
;; ---------------------------------------------------------------------------

(cl-defstruct git-review-file
  "A file entry from git status."
  name          ; relative path
  index-status  ; status char from index column (or nil)
  work-status   ; status char from worktree column (or nil)
  has-staged    ; non-nil if the file has staged changes
  has-unstaged  ; non-nil if the file has unstaged changes
  orig-name)    ; original name for renames

(cl-defstruct git-review-hunk
  "A parsed diff hunk."
  header     ; the @@ line
  old-start  ; start line in old file
  old-count  ; number of lines in old file
  new-start  ; start line in new file
  new-count  ; number of lines in new file
  lines      ; list of (type . text) where type is context, added, removed
  raw)       ; raw hunk text including header (for staging)

;; ---------------------------------------------------------------------------
;; State
;; ---------------------------------------------------------------------------

(defvar-local git-review--state nil
  "Plist holding review session state.  Stored in the file-list buffer.")

(defvar-local git-review--state-buffer nil
  "Reference to the file-list buffer that holds the state.")

(defvar-local git-review--hunks nil
  "List of hunks for the currently displayed file.")

(defvar-local git-review--hunk-line-ranges nil
  "List of (start-line . end-line) for each hunk in the right buffer.")

(defvar git-review--file-list-buffer-name "*git-review-files*")
(defvar git-review--left-buffer-name "*git-review-old*")
(defvar git-review--right-buffer-name "*git-review-new*")

;; ---------------------------------------------------------------------------
;; Git helpers
;; ---------------------------------------------------------------------------

(defun git-review--repo-root ()
  "Return the root of the current git repository."
  (let ((root (string-trim
               (shell-command-to-string "git rev-parse --show-toplevel"))))
    (if (string-prefix-p "fatal" root)
        (error "Not in a git repository")
      root)))

(defun git-review--parse-status (repo-root)
  "Parse `git status --porcelain` output from REPO-ROOT.
Returns one entry per file, tracking both staged and unstaged state."
  (let ((default-directory repo-root)
        (output (shell-command-to-string "git status --porcelain -u"))
        files)
    (dolist (line (split-string output "\n" t))
      (when (>= (length line) 3)
        (let* ((idx-char (aref line 0))
               (wt-char (aref line 1))
               (name-part (substring line 3))
               (orig-name nil)
               (name name-part)
               (has-staged (memq idx-char '(?M ?A ?D ?R)))
               (has-unstaged (memq wt-char '(?M ?D ??))))
          ;; Handle renames: "R  old -> new"
          (when (string-match "\\(.+\\) -> \\(.+\\)" name-part)
            (setq orig-name (match-string 1 name-part))
            (setq name (match-string 2 name-part)))
          (push (make-git-review-file
                 :name name
                 :index-status (unless (= idx-char ?\s) idx-char)
                 :work-status (unless (= wt-char ?\s) wt-char)
                 :has-staged has-staged
                 :has-unstaged has-unstaged
                 :orig-name orig-name)
                files))))
    (nreverse files)))

(defun git-review--get-content (repo-root ref filename)
  "Get FILENAME content at REF from REPO-ROOT.
REF is a git ref like \"HEAD\" or \":\" (for index).  Return nil on failure."
  (let ((default-directory repo-root))
    (with-temp-buffer
      (let ((exit-code (call-process "git" nil t nil "show"
                                     (concat ref filename))))
        (when (= exit-code 0)
          (buffer-string))))))

(defun git-review--get-worktree-content (repo-root filename)
  "Get the working tree version of FILENAME from REPO-ROOT."
  (let ((full-path (expand-file-name filename repo-root)))
    (when (file-exists-p full-path)
      (with-temp-buffer
        (insert-file-contents full-path)
        (buffer-string)))))

(defun git-review--get-diff (repo-root filename &optional cached)
  "Get the unified diff for FILENAME in REPO-ROOT.
If CACHED is non-nil, show the staged diff (HEAD vs index)."
  (let ((default-directory repo-root))
    (with-temp-buffer
      (if cached
          (call-process "git" nil t nil "diff" "--cached" "--no-color" "--" filename)
        (call-process "git" nil t nil "diff" "--no-color" "--" filename))
      (buffer-string))))

(defun git-review--get-diff-for-untracked (repo-root filename)
  "Generate a diff-like output for untracked FILENAME in REPO-ROOT."
  (let* ((full-path (expand-file-name filename repo-root))
         (content (with-temp-buffer
                    (insert-file-contents full-path)
                    (buffer-string)))
         (lines (split-string content "\n"))
         (count (length lines)))
    (concat
     (format "diff --git a/%s b/%s\n" filename filename)
     "new file mode 100644\n"
     (format "--- /dev/null\n+++ b/%s\n" filename)
     (format "@@ -0,0 +1,%d @@\n" count)
     (mapconcat (lambda (l) (concat "+" l)) lines "\n")
     "\n")))

;; ---------------------------------------------------------------------------
;; Diff parsing
;; ---------------------------------------------------------------------------

(defun git-review--parse-hunks (diff-text)
  "Parse DIFF-TEXT into a list of `git-review-hunk' structs."
  (let ((hunks '())
        (lines (split-string diff-text "\n"))
        (diff-header "")
        (header-done nil)
        current-hunk
        current-lines
        current-raw)
    (dolist (line lines)
      (cond
       ;; Hunk header line
       ((string-match "^@@ -\\([0-9]+\\),?\\([0-9]*\\) \\+\\([0-9]+\\),?\\([0-9]*\\) @@" line)
        (unless header-done
          (setq header-done t))
        (when current-hunk
          (setf (git-review-hunk-lines current-hunk) (nreverse current-lines))
          (setf (git-review-hunk-raw current-hunk)
                (concat diff-header (mapconcat #'identity (reverse current-raw) "\n") "\n"))
          (push current-hunk hunks))
        (setq current-hunk
              (make-git-review-hunk
               :header line
               :old-start (string-to-number (match-string 1 line))
               :old-count (let ((s (match-string 2 line)))
                            (if (or (null s) (string= s ""))
                                1
                              (string-to-number s)))
               :new-start (string-to-number (match-string 3 line))
               :new-count (let ((s (match-string 4 line)))
                            (if (or (null s) (string= s ""))
                                1
                              (string-to-number s))))
              current-lines '()
              current-raw (list line)))
       ;; Before first @@ — this is the diff header
       ((not header-done)
        (setq diff-header (concat diff-header line "\n")))
       ;; Inside a hunk — diff content lines
       (current-hunk
        (cond
         ((string-prefix-p "+" line)
          (push (cons 'added (substring line 1)) current-lines)
          (push line current-raw))
         ((string-prefix-p "-" line)
          (push (cons 'removed (substring line 1)) current-lines)
          (push line current-raw))
         ((string-prefix-p " " line)
          (push (cons 'context (substring line 1)) current-lines)
          (push line current-raw))
         ((string-prefix-p "\\" line)
          (push line current-raw))))))
    (when current-hunk
      (setf (git-review-hunk-lines current-hunk) (nreverse current-lines))
      (setf (git-review-hunk-raw current-hunk)
            (concat diff-header (mapconcat #'identity (reverse current-raw) "\n") "\n"))
      (push current-hunk hunks))
    (nreverse hunks)))

;; ---------------------------------------------------------------------------
;; Overlay highlighting
;; ---------------------------------------------------------------------------

(defun git-review--apply-overlays (left-buf right-buf hunks)
  "Apply diff highlighting overlays to LEFT-BUF and RIGHT-BUF based on HUNKS."
  (dolist (buf (list left-buf right-buf))
    (with-current-buffer buf
      (remove-overlays (point-min) (point-max) 'git-review t)))
  (dolist (hunk hunks)
    (let ((old-line (git-review-hunk-old-start hunk))
          (new-line (git-review-hunk-new-start hunk)))
      (when (> new-line 0)
        (with-current-buffer right-buf
          (git-review--add-line-overlay
           (max 1 new-line) 'git-review-hunk-header-face)))
      (dolist (entry (git-review-hunk-lines hunk))
        (let ((type (car entry)))
          (cond
           ((eq type 'removed)
            (with-current-buffer left-buf
              (git-review--add-line-overlay old-line 'git-review-removed-face))
            (cl-incf old-line))
           ((eq type 'added)
            (with-current-buffer right-buf
              (git-review--add-line-overlay new-line 'git-review-added-face))
            (cl-incf new-line))
           ((eq type 'context)
            (cl-incf old-line)
            (cl-incf new-line))))))))

(defun git-review--add-line-overlay (line-num face)
  "Add a highlight overlay at LINE-NUM with FACE in the current buffer."
  (save-excursion
    (goto-char (point-min))
    (when (and (> line-num 0)
               (= (forward-line (1- line-num)) 0))
      (let ((ov (make-overlay (line-beginning-position)
                              (min (1+ (line-end-position)) (point-max)))))
        (overlay-put ov 'face face)
        (overlay-put ov 'git-review t)))))

(defun git-review--char-diff-regions (old-str new-str)
  "Find the changed character region between OLD-STR and NEW-STR.
Returns (old-start old-end new-start new-end) as 0-based offsets, or nil if identical."
  (let* ((old-len (length old-str))
         (new-len (length new-str))
         (prefix-len (let ((i 0))
                       (while (and (< i old-len)
                                   (< i new-len)
                                   (= (aref old-str i) (aref new-str i)))
                         (cl-incf i))
                       i))
         (max-suffix (min (- old-len prefix-len) (- new-len prefix-len)))
         (suffix-len (let ((i 0))
                       (while (and (< i max-suffix)
                                   (= (aref old-str (- old-len 1 i))
                                      (aref new-str (- new-len 1 i))))
                         (cl-incf i))
                       i))
         (old-start prefix-len)
         (old-end   (- old-len suffix-len))
         (new-start prefix-len)
         (new-end   (- new-len suffix-len)))
    (when (or (< old-start old-end) (< new-start new-end))
      (list old-start old-end new-start new-end))))

(defun git-review--add-word-overlay (buf line-num char-start char-end face)
  "In BUF, overlay characters CHAR-START..CHAR-END on LINE-NUM with FACE."
  (with-current-buffer buf
    (save-excursion
      (goto-char (point-min))
      (when (= (forward-line (1- line-num)) 0)
        (let* ((line-beg (line-beginning-position))
               (ov (make-overlay (+ line-beg char-start)
                                 (+ line-beg char-end))))
          (overlay-put ov 'face face)
          (overlay-put ov 'git-review t))))))

(defun git-review--apply-paired-word-diffs (left-buf right-buf removed-lines added-lines)
  "Apply word-level overlays for paired REMOVED-LINES and ADDED-LINES.
Each element is (line-number . text)."
  (let ((rems removed-lines)
        (adds added-lines))
    (while (and rems adds)
      (let* ((rem (car rems))
             (add (car adds))
             (old-linenum (car rem))
             (new-linenum (car add))
             (regions (git-review--char-diff-regions (cdr rem) (cdr add))))
        (when regions
          (let ((old-start (nth 0 regions))
                (old-end   (nth 1 regions))
                (new-start (nth 2 regions))
                (new-end   (nth 3 regions)))
            (when (< old-start old-end)
              (git-review--add-word-overlay
               left-buf old-linenum old-start old-end
               'git-review-removed-word-face))
            (when (< new-start new-end)
              (git-review--add-word-overlay
               right-buf new-linenum new-start new-end
               'git-review-added-word-face)))))
      (setq rems (cdr rems)
            adds (cdr adds)))))

(defun git-review--apply-word-diffs (left-buf right-buf hunks header-lines)
  "Apply word-level diff overlays within changed lines of HUNKS.
HEADER-LINES is the number of header lines to offset line numbers by."
  (dolist (hunk hunks)
    (let ((old-line (+ header-lines (git-review-hunk-old-start hunk)))
          (new-line (+ header-lines (git-review-hunk-new-start hunk)))
          removed-acc added-acc)
      (dolist (entry (git-review-hunk-lines hunk))
        (let ((type (car entry))
              (text (cdr entry)))
          (cond
           ((eq type 'removed)
            (push (cons old-line text) removed-acc)
            (cl-incf old-line))
           ((eq type 'added)
            (push (cons new-line text) added-acc)
            (cl-incf new-line))
           ((eq type 'context)
            (git-review--apply-paired-word-diffs
             left-buf right-buf
             (nreverse removed-acc) (nreverse added-acc))
            (setq removed-acc nil added-acc nil)
            (cl-incf old-line)
            (cl-incf new-line)))))
      ;; Flush any trailing removed/added at end of hunk
      (git-review--apply-paired-word-diffs
       left-buf right-buf
       (nreverse removed-acc) (nreverse added-acc)))))

;; ---------------------------------------------------------------------------
;; Hunk tracking
;; ---------------------------------------------------------------------------

(defun git-review--compute-hunk-ranges (hunks)
  "Compute the line ranges in the right (new) buffer for each hunk in HUNKS."
  (let (ranges)
    (dolist (hunk hunks)
      (let ((start (git-review-hunk-new-start hunk))
            (count (git-review-hunk-new-count hunk)))
        (push (cons start (+ start (max 1 count) -1)) ranges)))
    (nreverse ranges)))

;; ---------------------------------------------------------------------------
;; Window layout
;; ---------------------------------------------------------------------------

(defun git-review--setup-layout ()
  "Create the 3-pane layout and return a plist of window references."
  (delete-other-windows)
  (let* ((list-height (max 8 (/ (window-total-height) 4)))
         (top-window (selected-window))
         (bottom-window (split-window top-window (- list-height) 'below))
         (left-window top-window)
         (right-window (split-window left-window nil 'right)))
    (let ((left-buf (get-buffer-create git-review--left-buffer-name))
          (right-buf (get-buffer-create git-review--right-buffer-name))
          (list-buf (get-buffer-create git-review--file-list-buffer-name)))
      (set-window-buffer left-window left-buf)
      (set-window-buffer right-window right-buf)
      (set-window-buffer bottom-window list-buf)
      (set-window-parameter left-window 'git-review-role 'left)
      (set-window-parameter right-window 'git-review-role 'right)
      (set-window-parameter bottom-window 'git-review-role 'list)
      (set-window-dedicated-p left-window t)
      (set-window-dedicated-p right-window t)
      (set-window-dedicated-p bottom-window t)
      (list :left-window left-window
            :right-window right-window
            :list-window bottom-window
            :left-buffer left-buf
            :right-buffer right-buf
            :list-buffer list-buf))))

;; ---------------------------------------------------------------------------
;; View mode: staged vs unstaged
;; ---------------------------------------------------------------------------

(defun git-review--current-view (state)
  "Return the current view mode: `staged' or `unstaged'."
  (or (plist-get state :view-mode) 'unstaged))

(defun git-review--default-view-for-file (file)
  "Return the default view for FILE based on what changes it has."
  (cond
   ;; Only staged changes — show staged view
   ((and (git-review-file-has-staged file)
         (not (git-review-file-has-unstaged file)))
    'staged)
   ;; Has unstaged (or both) — show unstaged first
   (t 'unstaged)))

(defun git-review--view-label (view)
  "Return a display string for VIEW."
  (if (eq view 'staged) "STAGED" "UNSTAGED"))

;; ---------------------------------------------------------------------------
;; File list rendering
;; ---------------------------------------------------------------------------

(defun git-review--status-display (file)
  "Return a status string for FILE."
  (let ((idx (git-review-file-index-status file))
        (wt (git-review-file-work-status file)))
    (format "%c%c"
            (or idx ?\s)
            (or wt ?\s))))

(defun git-review--status-face (file)
  "Return a face for FILE's status."
  (let ((wt (git-review-file-work-status file))
        (idx (git-review-file-index-status file)))
    (cond
     ((memq wt '(?M))  'git-review-status-modified-face)
     ((memq wt '(?D))  'git-review-status-deleted-face)
     ((memq wt '(??))  'git-review-status-added-face)
     ((memq idx '(?A ?R)) 'git-review-status-added-face)
     ((memq idx '(?M)) 'git-review-status-modified-face)
     ((memq idx '(?D)) 'git-review-status-deleted-face)
     (t 'default))))

(defun git-review--render-file-list (state)
  "Render the file list buffer from STATE."
  (let* ((files (plist-get state :files))
         (current-index (plist-get state :current-index))
         (view (git-review--current-view state))
         (buf (get-buffer git-review--file-list-buffer-name)))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (propertize
                   (format " %d file(s)  |  Viewing: %s  |  TAB to toggle  |  s=stage  u=unstage\n"
                           (length files) (git-review--view-label view))
                   'face 'font-lock-comment-face))
          (insert (propertize " ─────────────────────────────────────────────────────────────────\n"
                              'face 'font-lock-comment-face))
          (cl-loop
           for file in files
           for i from 0
           do (let* ((status-str (git-review--status-display file))
                     (changes-str
                      (cond
                       ((and (git-review-file-has-staged file)
                             (git-review-file-has-unstaged file))
                        (concat (propertize "S" 'face 'git-review-status-added-face)
                                "+"
                                (propertize "U" 'face 'git-review-status-modified-face)))
                       ((git-review-file-has-staged file)
                        (propertize "S" 'face 'git-review-status-added-face))
                       (t
                        (propertize "U" 'face 'git-review-status-modified-face))))
                     (line (format " %s %s %s  [%s]\n"
                                   (propertize status-str 'face (git-review--status-face file))
                                   (propertize (git-review-file-name file)
                                               'face 'git-review-file-header-face)
                                   (if (git-review-file-orig-name file)
                                       (format "(from %s)" (git-review-file-orig-name file))
                                     "")
                                   changes-str)))
                (when (= i current-index)
                  (setq line (propertize line 'face 'git-review-current-file-face)))
                (insert (propertize line 'git-review-file-index i))))
          (goto-char (point-min))
          (forward-line (+ 2 current-index)))))))

;; ---------------------------------------------------------------------------
;; Display a file's diff
;; ---------------------------------------------------------------------------

(defun git-review--guess-mode (filename)
  "Return a major mode appropriate for FILENAME."
  (let ((mode (assoc-default filename auto-mode-alist #'string-match-p)))
    (or mode 'fundamental-mode)))

(defun git-review--show-file (state index)
  "Show the diff for file at INDEX.  STATE is the review session plist."
  (let* ((files (plist-get state :files))
         (file (nth index files))
         (repo-root (plist-get state :repo-root))
         (filename (git-review-file-name file))
         (orig-name (git-review-file-orig-name file))
         (left-buf (plist-get state :left-buffer))
         (right-buf (plist-get state :right-buffer))
         (mode (git-review--guess-mode filename)))
    ;; Set default view for this file only when switching to a different file
    (let ((old-index (plist-get state :current-index)))
      (when (and (not (eql old-index index)))
        (plist-put state :view-mode (git-review--default-view-for-file file))))
    ;; Update state
    (plist-put state :current-index index)
    (plist-put state :current-hunk-index nil)
    ;; Now show based on view mode
    (let* ((view (git-review--current-view state))
           (is-untracked (eql (git-review-file-work-status file) ??))
           (head-name (or orig-name filename))
           ;; Determine left/right content and diff based on view
           (left-content
            (cond
             (is-untracked nil)
             ((eq view 'staged)
              ;; Staged view: left = HEAD
              (git-review--get-content repo-root "HEAD:" head-name))
             (t
              ;; Unstaged view: left = index
              (git-review--get-content repo-root ":" filename))))
           (right-content
            (cond
             (is-untracked
              (git-review--get-worktree-content repo-root filename))
             ((eq view 'staged)
              ;; Staged view: right = index
              (git-review--get-content repo-root ":" filename))
             (t
              ;; Unstaged view: right = worktree
              (git-review--get-worktree-content repo-root filename))))
           (diff-text
            (cond
             (is-untracked
              (git-review--get-diff-for-untracked repo-root filename))
             ((eq view 'staged)
              (git-review--get-diff repo-root filename t))
             (t
              (git-review--get-diff repo-root filename))))
           (hunks (git-review--parse-hunks diff-text))
           (left-label (cond
                        (is-untracked "(new file)")
                        ((eq view 'staged) (format "HEAD: %s" head-name))
                        (t (format "Index: %s" filename))))
           (right-label (cond
                         ((eq view 'staged) (format "Index: %s" filename))
                         (t (format "Worktree: %s" filename))))
           (view-str (propertize
                      (format " [%s] " (git-review--view-label view))
                      'face 'git-review-view-indicator-face)))
      ;; Populate left buffer
      (with-current-buffer left-buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (propertize (concat view-str left-label "\n")
                              'face 'font-lock-comment-face))
          (insert (propertize "────────────────────────────────────\n"
                              'face 'font-lock-comment-face))
          (if left-content
              (insert left-content)
            (insert (propertize "(empty)" 'face 'font-lock-comment-face)))
          (condition-case nil
              (funcall mode)
            (error (fundamental-mode))))
        (git-review-diff-mode 1)
        (setq buffer-read-only t)
        (setq git-review--hunks hunks)
        (goto-char (point-min))
        (setq-local git-review--state-buffer (plist-get state :list-buffer))
        (when (fboundp 'evil-normal-state)
          (evil-normal-state)))
      ;; Populate right buffer
      (with-current-buffer right-buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (propertize (concat view-str right-label "\n")
                              'face 'font-lock-comment-face))
          (insert (propertize "────────────────────────────────────\n"
                              'face 'font-lock-comment-face))
          (if right-content
              (insert right-content)
            (insert (propertize "(deleted)" 'face 'font-lock-comment-face)))
          (condition-case nil
              (funcall mode)
            (error (fundamental-mode))))
        (git-review-diff-mode 1)
        (setq buffer-read-only t)
        (setq git-review--hunks hunks)
        (setq git-review--hunk-line-ranges (git-review--compute-hunk-ranges hunks))
        (goto-char (point-min))
        (setq-local git-review--state-buffer (plist-get state :list-buffer))
        (when (fboundp 'evil-normal-state)
          (evil-normal-state)))
      ;; Apply diff overlays — offset by 2 for the header lines
      (git-review--apply-overlays-with-offset left-buf right-buf hunks 2)
      ;; Update state
      (plist-put state :current-hunks hunks)
      ;; Render file list
      (git-review--render-file-list state)
      ;; Scroll to first change
      (git-review--goto-first-change state))))

(defun git-review--apply-overlays-with-offset (left-buf right-buf hunks header-lines)
  "Apply diff overlays to LEFT-BUF and RIGHT-BUF for HUNKS.
HEADER-LINES is the number of header lines to offset by."
  (dolist (buf (list left-buf right-buf))
    (with-current-buffer buf
      (remove-overlays (point-min) (point-max) 'git-review t)))
  (dolist (hunk hunks)
    (let ((old-line (+ header-lines (git-review-hunk-old-start hunk)))
          (new-line (+ header-lines (git-review-hunk-new-start hunk))))
      (when (> (git-review-hunk-new-start hunk) 0)
        (with-current-buffer right-buf
          (git-review--add-line-overlay (max 1 new-line) 'git-review-hunk-header-face)))
      (dolist (entry (git-review-hunk-lines hunk))
        (let ((type (car entry)))
          (cond
           ((eq type 'removed)
            (with-current-buffer left-buf
              (git-review--add-line-overlay old-line 'git-review-removed-face))
            (cl-incf old-line))
           ((eq type 'added)
            (with-current-buffer right-buf
              (git-review--add-line-overlay new-line 'git-review-added-face))
            (cl-incf new-line))
           ((eq type 'context)
            (cl-incf old-line)
            (cl-incf new-line)))))))
  (git-review--apply-word-diffs left-buf right-buf hunks header-lines))

(defun git-review--goto-first-change (state)
  "Scroll to the first changed line in the current file."
  (let ((hunks (plist-get state :current-hunks)))
    (when hunks
      (git-review--scroll-to-hunk state 0))))

;; ---------------------------------------------------------------------------
;; Staging / Unstaging
;; ---------------------------------------------------------------------------

(defun git-review--stage-file-at-index (state index)
  "Stage the file at INDEX."
  (let* ((files (plist-get state :files))
         (file (nth index files))
         (repo-root (plist-get state :repo-root))
         (default-directory repo-root)
         (filename (git-review-file-name file))
         (wt (git-review-file-work-status file)))
    (if (eql wt ?D)
        (call-process "git" nil nil nil "rm" "--" filename)
      (call-process "git" nil nil nil "add" "--" filename))
    (message "Staged: %s" filename)
    (git-review--refresh state)))

(defun git-review--unstage-file-at-index (state index)
  "Unstage the file at INDEX."
  (let* ((files (plist-get state :files))
         (file (nth index files))
         (repo-root (plist-get state :repo-root))
         (default-directory repo-root)
         (filename (git-review-file-name file)))
    (call-process "git" nil nil nil "reset" "HEAD" "--" filename)
    (message "Unstaged: %s" filename)
    (git-review--refresh state)))

(defun git-review--apply-hunk-patch (state reverse-p)
  "Apply or reverse the current hunk.
If REVERSE-P, reverse the patch (unstage)."
  (let* ((hunks (plist-get state :current-hunks))
         (hunk-index (plist-get state :current-hunk-index))
         (repo-root (plist-get state :repo-root))
         (action (if reverse-p "Unstaged" "Staged")))
    (if (or (null hunk-index) (null hunks))
        (message "No hunk selected — navigate to a hunk first with ]c")
      (let* ((hunk (nth hunk-index hunks))
             (raw (git-review-hunk-raw hunk))
             (default-directory repo-root)
             (err-buf (get-buffer-create " *git-review-error*"))
             (temp-file (make-temp-file "git-review-hunk-" nil ".patch" raw)))
        (unwind-protect
            (progn
              (with-current-buffer err-buf (erase-buffer))
              (let* ((args (if reverse-p
                               (list "apply" "--cached" "--reverse" "--" temp-file)
                             (list "apply" "--cached" "--" temp-file)))
                     (exit-code (apply #'call-process "git" nil err-buf nil args)))
                (if (= exit-code 0)
                    (message "%s hunk %d/%d" action (1+ hunk-index) (length hunks))
                  (message "Failed to %s hunk: %s"
                           (downcase action)
                           (string-trim (with-current-buffer err-buf (buffer-string)))))))
          (delete-file temp-file))
        (git-review--refresh state)))))

;; ---------------------------------------------------------------------------
;; Navigation
;; ---------------------------------------------------------------------------

(defun git-review--next-file (state)
  "Move to the next file."
  (let* ((files (plist-get state :files))
         (idx (plist-get state :current-index))
         (new-idx (min (1- (length files)) (1+ idx))))
    (unless (= new-idx idx)
      (git-review--show-file state new-idx))))

(defun git-review--prev-file (state)
  "Move to the previous file."
  (let* ((idx (plist-get state :current-index))
         (new-idx (max 0 (1- idx))))
    (unless (= new-idx idx)
      (git-review--show-file state new-idx))))

(defun git-review--scroll-to-hunk (state hunk-index)
  "Scroll both panels to the hunk at HUNK-INDEX."
  (let* ((hunks (plist-get state :current-hunks))
         (hunk (nth hunk-index hunks))
         (right-win (plist-get state :right-window))
         (left-win (plist-get state :left-window))
         ;; Account for 2 header lines in the buffers
         (offset 2))
    (when hunk
      (plist-put state :current-hunk-index hunk-index)
      (let ((new-line (+ offset (git-review-hunk-new-start hunk)))
            (old-line (+ offset (git-review-hunk-old-start hunk))))
        (when (and right-win (window-live-p right-win))
          (with-selected-window right-win
            (goto-char (point-min))
            (forward-line (1- new-line))
            (recenter 3)))
        (when (and left-win (window-live-p left-win))
          (with-selected-window left-win
            (goto-char (point-min))
            (forward-line (1- old-line))
            (recenter 3))))
      (let* ((view (git-review--current-view state))
             (view-str (git-review--view-label view)))
        (message "Hunk %d/%d  [%s]" (1+ hunk-index) (length hunks) view-str)))))

(defun git-review--next-hunk (state)
  "Move to the next hunk."
  (let* ((hunks (plist-get state :current-hunks))
         (cur (or (plist-get state :current-hunk-index) -1))
         (next (1+ cur)))
    (if (>= next (length hunks))
        (message "No more hunks")
      (git-review--scroll-to-hunk state next))))

(defun git-review--prev-hunk (state)
  "Move to the previous hunk."
  (let* ((cur (or (plist-get state :current-hunk-index) 0))
         (prev (1- cur)))
    (if (< prev 0)
        (message "No previous hunk")
      (git-review--scroll-to-hunk state prev))))

(defun git-review--toggle-view (state)
  "Toggle between staged and unstaged view for the current file."
  (let* ((files (plist-get state :files))
         (index (plist-get state :current-index))
         (file (nth index files))
         (current (git-review--current-view state)))
    (let ((target (cond
                   ((and (git-review-file-has-staged file)
                         (git-review-file-has-unstaged file))
                    (if (eq current 'staged) 'unstaged 'staged))
                   ((git-review-file-has-staged file) 'staged)
                   ((git-review-file-has-unstaged file) 'unstaged))))
      (if (eq target current)
          (message "File only has %s changes" (git-review--view-label current))
        (plist-put state :view-mode target)
        (git-review--show-file state index)))))

;; ---------------------------------------------------------------------------
;; Refresh
;; ---------------------------------------------------------------------------

(defun git-review--refresh (state)
  "Re-read git status and refresh the display."
  (let* ((repo-root (plist-get state :repo-root))
         (old-index (plist-get state :current-index))
         (old-view (plist-get state :view-mode))
         (new-files (git-review--parse-status repo-root)))
    (plist-put state :files new-files)
    (if (null new-files)
        (progn
          (message "No more changes to review")
          (git-review--quit state))
      (let* ((idx (min old-index (1- (length new-files))))
             (file (nth idx new-files))
             ;; Auto-switch view if the current view no longer has changes
             (view (cond
                    ((and (eq old-view 'unstaged)
                          (not (git-review-file-has-unstaged file))
                          (git-review-file-has-staged file))
                     'staged)
                    ((and (eq old-view 'staged)
                          (not (git-review-file-has-staged file))
                          (git-review-file-has-unstaged file))
                     'unstaged)
                    (t old-view))))
        (plist-put state :view-mode view)
        (plist-put state :current-index idx)
        (git-review--show-file state idx)))))

;; ---------------------------------------------------------------------------
;; Quit
;; ---------------------------------------------------------------------------

(defun git-review--quit (state)
  "Quit the review session and restore windows."
  (let ((saved-config (plist-get state :saved-window-config)))
    (dolist (name (list git-review--left-buffer-name
                        git-review--right-buffer-name
                        git-review--file-list-buffer-name))
      (when-let ((buf (get-buffer name)))
        (dolist (win (get-buffer-window-list buf nil t))
          (set-window-dedicated-p win nil))
        (kill-buffer buf)))
    (when saved-config
      (set-window-configuration saved-config))
    (message "Git review session ended")))

;; ---------------------------------------------------------------------------
;; State access helper
;; ---------------------------------------------------------------------------

(defun git-review--get-state ()
  "Get the review state from the current context."
  (cond
   (git-review--state git-review--state)
   ((and (boundp 'git-review--state-buffer)
         git-review--state-buffer
         (buffer-live-p git-review--state-buffer))
    (buffer-local-value 'git-review--state git-review--state-buffer))
   (t (when-let ((buf (get-buffer git-review--file-list-buffer-name)))
        (buffer-local-value 'git-review--state buf)))))

;; ---------------------------------------------------------------------------
;; Interactive commands
;; ---------------------------------------------------------------------------

(defun git-review-next-file ()
  "Move to the next file."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--next-file state)))

(defun git-review-prev-file ()
  "Move to the previous file."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--prev-file state)))

(defun git-review-next-hunk ()
  "Move to the next hunk."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--next-hunk state)))

(defun git-review-prev-hunk ()
  "Move to the previous hunk."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--prev-hunk state)))

(defun git-review-stage-file ()
  "Stage the current file."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--stage-file-at-index state (plist-get state :current-index))))

(defun git-review-unstage-file ()
  "Unstage the current file."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--unstage-file-at-index state (plist-get state :current-index))))

(defun git-review-stage-hunk ()
  "Stage the current hunk."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--apply-hunk-patch state nil)))

(defun git-review-unstage-hunk ()
  "Unstage the current hunk."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--apply-hunk-patch state t)))

(defun git-review-toggle-view ()
  "Toggle between staged and unstaged view."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--toggle-view state)))

(defun git-review-goto-file ()
  "Jump to the file at point in the file list."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (let ((index (get-text-property (point) 'git-review-file-index)))
      (when index
        (git-review--show-file state index)))))

(defun git-review-refresh ()
  "Refresh the review session."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--refresh state)))

(defun git-review-quit ()
  "Quit the review session."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--quit state)))

(defun git-review-scroll-down ()
  "Scroll both diff panels down."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (let ((left-win (plist-get state :left-window))
          (right-win (plist-get state :right-window)))
      (when (window-live-p left-win)
        (with-selected-window left-win (scroll-up 3)))
      (when (window-live-p right-win)
        (with-selected-window right-win (scroll-up 3))))))

(defun git-review-scroll-up ()
  "Scroll both diff panels up."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (let ((left-win (plist-get state :left-window))
          (right-win (plist-get state :right-window)))
      (when (window-live-p left-win)
        (with-selected-window left-win (scroll-down 3)))
      (when (window-live-p right-win)
        (with-selected-window right-win (scroll-down 3))))))

;; ---------------------------------------------------------------------------
;; Minor mode for diff panels
;; ---------------------------------------------------------------------------

(defvar git-review-diff-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'git-review-quit)
    (define-key map (kbd "s") #'git-review-stage-hunk)
    (define-key map (kbd "S") #'git-review-stage-file)
    (define-key map (kbd "u") #'git-review-unstage-hunk)
    (define-key map (kbd "U") #'git-review-unstage-file)
    (define-key map (kbd "TAB") #'git-review-toggle-view)
    (define-key map (kbd "]") #'git-review-next-hunk)
    (define-key map (kbd "[") #'git-review-prev-hunk)
    (define-key map (kbd "n") #'git-review-next-file)
    (define-key map (kbd "p") #'git-review-prev-file)
    (define-key map (kbd "g") #'git-review-refresh)
    (define-key map (kbd "C-j") #'git-review-scroll-down)
    (define-key map (kbd "C-k") #'git-review-scroll-up)
    map)
  "Keymap for git-review diff panels.")

(define-minor-mode git-review-diff-mode
  "Minor mode active in git-review diff panels."
  :lighter " GR-Diff"
  :keymap git-review-diff-mode-map)

;; ---------------------------------------------------------------------------
;; Major mode for file list
;; ---------------------------------------------------------------------------

(defvar git-review-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'git-review-quit)
    (define-key map (kbd "n") #'git-review-next-file)
    (define-key map (kbd "j") #'git-review-next-file)
    (define-key map (kbd "p") #'git-review-prev-file)
    (define-key map (kbd "k") #'git-review-prev-file)
    (define-key map (kbd "RET") #'git-review-goto-file)
    (define-key map (kbd "s") #'git-review-stage-file)
    (define-key map (kbd "S") #'git-review-stage-file)
    (define-key map (kbd "u") #'git-review-unstage-file)
    (define-key map (kbd "TAB") #'git-review-toggle-view)
    (define-key map (kbd "]") #'git-review-next-hunk)
    (define-key map (kbd "[") #'git-review-prev-hunk)
    (define-key map (kbd "g") #'git-review-refresh)
    (define-key map (kbd "C-j") #'git-review-scroll-down)
    (define-key map (kbd "C-k") #'git-review-scroll-up)
    map)
  "Keymap for git-review file list.")

(define-derived-mode git-review-mode special-mode "Git-Review"
  "Major mode for the git-review file list buffer."
  (setq buffer-read-only t)
  (setq truncate-lines t))

;; Evil integration
(with-eval-after-load 'evil
  (evil-set-initial-state 'git-review-mode 'normal)

  (evil-define-key 'normal git-review-mode-map
    (kbd "q")   #'git-review-quit
    (kbd "j")   #'git-review-next-file
    (kbd "k")   #'git-review-prev-file
    (kbd "RET") #'git-review-goto-file
    (kbd "s")   #'git-review-stage-file
    (kbd "u")   #'git-review-unstage-file
    (kbd "TAB") #'git-review-toggle-view
    (kbd "]c")  #'git-review-next-hunk
    (kbd "[c")  #'git-review-prev-hunk
    (kbd "gr")  #'git-review-refresh
    (kbd "C-j") #'git-review-scroll-down
    (kbd "C-k") #'git-review-scroll-up)

  (evil-define-key '(normal motion) git-review-diff-mode-map
    (kbd "q")   #'git-review-quit
    (kbd "s")   #'git-review-stage-hunk
    (kbd "S")   #'git-review-stage-file
    (kbd "u")   #'git-review-unstage-hunk
    (kbd "U")   #'git-review-unstage-file
    (kbd "TAB") #'git-review-toggle-view
    (kbd "]c")  #'git-review-next-hunk
    (kbd "[c")  #'git-review-prev-hunk
    (kbd "n")   #'git-review-next-file
    (kbd "p")   #'git-review-prev-file
    (kbd "gr")  #'git-review-refresh
    (kbd "C-j") #'git-review-scroll-down
    (kbd "C-k") #'git-review-scroll-up))

;; ---------------------------------------------------------------------------
;; Entry point
;; ---------------------------------------------------------------------------

;;;###autoload
(defun git-review ()
  "Start a git review session for the current repository.
Shows all changed, staged, and untracked files in a PR-review-like
interface with side-by-side diffs and a file list.

Use TAB to toggle between staged and unstaged views per file."
  (interactive)
  (let* ((repo-root (git-review--repo-root))
         (files (git-review--parse-status repo-root)))
    (unless files
      (user-error "No changes to review"))
    (let* ((saved-config (current-window-configuration))
           (layout (git-review--setup-layout))
           (state (append layout
                          (list :files files
                                :current-index nil
                                :repo-root repo-root
                                :saved-window-config saved-config
                                :current-hunks nil
                                :current-hunk-index nil
                                :view-mode nil))))
      (with-current-buffer (plist-get layout :list-buffer)
        (git-review-mode)
        (setq git-review--state state))
      (git-review--show-file state 0)
      (select-window (plist-get layout :list-window)))))

(provide 'git-review)
;;; git-review.el ends here
