;;; git-review.el --- Review git status like a pull request -*- lexical-binding: t; -*-

;; Author: Claude
;; Version: 1.0
;; Keywords: git, vc, tools
;; Package-Requires: ((emacs "28.1"))

;;; Commentary:

;; Provides a PR-review-like interface for reviewing the current git
;; working tree.  Shows a side-by-side diff (HEAD vs working tree) with
;; a file list at the bottom.  Supports staging files and individual
;; hunks during review.
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

;; ---------------------------------------------------------------------------
;; Data structures
;; ---------------------------------------------------------------------------

(cl-defstruct git-review-file
  "A file entry from git status."
  name       ; relative path
  status     ; symbol: modified, added, deleted, untracked, renamed
  staged-p   ; non-nil if the file has staged changes
  orig-name) ; original name for renames

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
  "Parse `git status --porcelain` output from REPO-ROOT into a list of `git-review-file' structs."
  (let ((default-directory repo-root)
        (output (shell-command-to-string "git status --porcelain"))
        files)
    (dolist (line (split-string output "\n" t))
      (when (>= (length line) 3)
        (let* ((index-status (aref line 0))
               (worktree-status (aref line 1))
               (name-part (substring line 3))
               (orig-name nil)
               (name name-part)
               status staged-p)
          ;; Handle renames: "R  old -> new"
          (when (string-match "\\(.+\\) -> \\(.+\\)" name-part)
            (setq orig-name (match-string 1 name-part))
            (setq name (match-string 2 name-part)))
          ;; Determine status from worktree column primarily
          (cond
           ((= worktree-status ?M) (setq status 'modified))
           ((= worktree-status ?D) (setq status 'deleted))
           ((= worktree-status ??) (setq status 'untracked))
           ((= index-status ?A)    (setq status 'added) (setq staged-p t))
           ((= index-status ?M)    (setq status 'modified) (setq staged-p t))
           ((= index-status ?D)    (setq status 'deleted) (setq staged-p t))
           ((= index-status ?R)    (setq status 'renamed) (setq staged-p t))
           (t                      (setq status 'modified)))
          (push (make-git-review-file
                 :name name
                 :status status
                 :staged-p staged-p
                 :orig-name orig-name)
                files))))
    (nreverse files)))

(defun git-review--get-head-content (repo-root filename)
  "Get the HEAD version of FILENAME from REPO-ROOT.  Return nil if not tracked."
  (let* ((default-directory repo-root)
         (output (with-temp-buffer
                   (let ((exit-code (call-process "git" nil t nil "show" (concat "HEAD:" filename))))
                     (if (= exit-code 0)
                         (buffer-string)
                       nil)))))
    output))

(defun git-review--get-worktree-content (repo-root filename)
  "Get the working tree version of FILENAME from REPO-ROOT.  Return nil if deleted."
  (let ((full-path (expand-file-name filename repo-root)))
    (when (file-exists-p full-path)
      (with-temp-buffer
        (insert-file-contents full-path)
        (buffer-string)))))

(defun git-review--get-diff (repo-root filename &optional cached)
  "Get the unified diff for FILENAME in REPO-ROOT.
If CACHED is non-nil, show the staged diff."
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
    ;; Single pass through all lines
    (dolist (line lines)
      (cond
       ;; Hunk header line
       ((string-match "^@@ -\\([0-9]+\\),?\\([0-9]*\\) \\+\\([0-9]+\\),?\\([0-9]*\\) @@" line)
        ;; On first @@, finalize the diff header
        (unless header-done
          (setq header-done t))
        ;; Save previous hunk if any
        (when current-hunk
          (setf (git-review-hunk-lines current-hunk) (nreverse current-lines))
          (setf (git-review-hunk-raw current-hunk)
                (concat diff-header (mapconcat #'identity (reverse current-raw) "\n") "\n"))
          (push current-hunk hunks))
        ;; Start new hunk
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
    ;; Save last hunk
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
  ;; Clear existing overlays
  (dolist (buf (list left-buf right-buf))
    (with-current-buffer buf
      (remove-overlays (point-min) (point-max) 'git-review t)))
  (dolist (hunk hunks)
    (let ((old-line (git-review-hunk-old-start hunk))
          (new-line (git-review-hunk-new-start hunk)))
      ;; Add hunk header overlay in right buffer
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

;; ---------------------------------------------------------------------------
;; Hunk tracking (for staging individual hunks)
;; ---------------------------------------------------------------------------

(defvar-local git-review--hunks nil
  "List of hunks for the currently displayed file.")

(defvar-local git-review--hunk-line-ranges nil
  "List of (start-line . end-line) for each hunk in the right buffer.")

(defun git-review--compute-hunk-ranges (hunks)
  "Compute the line ranges in the right (new) buffer for each hunk in HUNKS."
  (let (ranges)
    (dolist (hunk hunks)
      (let ((start (git-review-hunk-new-start hunk))
            (count (git-review-hunk-new-count hunk)))
        (push (cons start (+ start (max 1 count) -1)) ranges)))
    (nreverse ranges)))

(defun git-review--hunk-at-line (line-num ranges)
  "Return the index of the hunk at LINE-NUM given RANGES, or nil."
  (cl-loop for range in ranges
           for i from 0
           when (and (>= line-num (car range))
                     (<= line-num (cdr range)))
           return i))

;; ---------------------------------------------------------------------------
;; Window layout
;; ---------------------------------------------------------------------------

(defun git-review--setup-layout ()
  "Create the 3-pane layout and return a plist of window references."
  (delete-other-windows)
  (let* ((list-height (max 8 (/ (window-total-height) 4)))
         ;; Split for file list at bottom
         (top-window (selected-window))
         (bottom-window (split-window top-window (- list-height) 'below))
         ;; Split top into left/right
         (left-window top-window)
         (right-window (split-window left-window nil 'right)))
    ;; Create buffers
    (let ((left-buf (get-buffer-create git-review--left-buffer-name))
          (right-buf (get-buffer-create git-review--right-buffer-name))
          (list-buf (get-buffer-create git-review--file-list-buffer-name)))
      ;; Assign buffers
      (set-window-buffer left-window left-buf)
      (set-window-buffer right-window right-buf)
      (set-window-buffer bottom-window list-buf)
      ;; Set window parameters for identification
      (set-window-parameter left-window 'git-review-role 'left)
      (set-window-parameter right-window 'git-review-role 'right)
      (set-window-parameter bottom-window 'git-review-role 'list)
      ;; Make windows dedicated
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
;; File list rendering
;; ---------------------------------------------------------------------------

(defun git-review--status-char (file)
  "Return a status character for FILE."
  (pcase (git-review-file-status file)
    ('modified "M")
    ('added    "A")
    ('deleted  "D")
    ('untracked "?")
    ('renamed  "R")
    (_         " ")))

(defun git-review--status-face (file)
  "Return a face for FILE's status."
  (pcase (git-review-file-status file)
    ('modified  'git-review-status-modified-face)
    ('added     'git-review-status-added-face)
    ('untracked 'git-review-status-added-face)
    ('deleted   'git-review-status-deleted-face)
    ('renamed   'git-review-status-modified-face)
    (_          'default)))

(defun git-review--render-file-list (files current-index)
  "Render the file list into the file list buffer.
FILES is a list of `git-review-file', CURRENT-INDEX is the selected index."
  (let ((buf (get-buffer git-review--file-list-buffer-name)))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (propertize (format " %d file(s) changed\n" (length files))
                              'face 'font-lock-comment-face))
          (insert (propertize " ─────────────────────────────────────────\n"
                              'face 'font-lock-comment-face))
          (cl-loop for file in files
                   for i from 0
                   do (let* ((status-str (git-review--status-char file))
                             (staged-str (if (git-review-file-staged-p file) "●" " "))
                             (line (format " %s %s %s\n"
                                          staged-str
                                          (propertize status-str 'face (git-review--status-face file))
                                          (propertize (git-review-file-name file)
                                                      'face 'git-review-file-header-face))))
                        (when (= i current-index)
                          (setq line (propertize line 'face 'git-review-current-file-face)))
                        (insert (propertize line 'git-review-file-index i))))
          (goto-char (point-min))
          ;; Move to current file line (skip 2 header lines)
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
         (status (git-review-file-status file))
         (left-buf (plist-get state :left-buffer))
         (right-buf (plist-get state :right-buffer))
         (mode (git-review--guess-mode filename))
         (head-content (unless (memq status '(untracked))
                         (git-review--get-head-content repo-root filename)))
         (worktree-content (unless (eq status 'deleted)
                             (git-review--get-worktree-content repo-root filename)))
         (diff-text (if (eq status 'untracked)
                        (git-review--get-diff-for-untracked repo-root filename)
                      (git-review--get-diff repo-root filename)))
         (hunks (git-review--parse-hunks diff-text)))
    ;; Populate left buffer (HEAD version)
    (with-current-buffer left-buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (if head-content
            (insert head-content)
          (insert (propertize "(new file)" 'face 'font-lock-comment-face)))
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
    ;; Populate right buffer (working tree version)
    (with-current-buffer right-buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (if worktree-content
            (insert worktree-content)
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
    ;; Apply diff overlays
    (git-review--apply-overlays left-buf right-buf hunks)
    ;; Update state
    (plist-put state :current-index index)
    (plist-put state :current-hunks hunks)
    (plist-put state :current-hunk-index nil)
    ;; Update file list highlight
    (git-review--render-file-list files index)
    ;; Scroll both buffers to the first change
    (git-review--goto-first-change state)))

(defun git-review--goto-first-change (state)
  "Scroll to the first changed line in the current file."
  (let ((hunks (plist-get state :current-hunks)))
    (when hunks
      (git-review--scroll-to-hunk state 0))))

;; ---------------------------------------------------------------------------
;; Staging
;; ---------------------------------------------------------------------------

(defun git-review--stage-file-at-index (state index)
  "Stage the file at INDEX.  STATE is the review session plist."
  (let* ((files (plist-get state :files))
         (file (nth index files))
         (repo-root (plist-get state :repo-root))
         (default-directory repo-root)
         (filename (git-review-file-name file)))
    (if (eq (git-review-file-status file) 'deleted)
        (call-process "git" nil nil nil "rm" "--" filename)
      (call-process "git" nil nil nil "add" "--" filename))
    (message "Staged: %s" filename)
    (git-review--refresh state)))

(defun git-review--unstage-file-at-index (state index)
  "Unstage the file at INDEX.  STATE is the review session plist."
  (let* ((files (plist-get state :files))
         (file (nth index files))
         (repo-root (plist-get state :repo-root))
         (default-directory repo-root)
         (filename (git-review-file-name file)))
    (call-process "git" nil nil nil "reset" "HEAD" "--" filename)
    (message "Unstaged: %s" filename)
    (git-review--refresh state)))

(defun git-review--stage-hunk-at-point (state)
  "Stage the current hunk.  STATE is the review session plist."
  (let* ((hunks (plist-get state :current-hunks))
         (hunk-index (plist-get state :current-hunk-index))
         (repo-root (plist-get state :repo-root)))
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
              (let ((exit-code (call-process "git" nil err-buf nil
                                             "apply" "--cached" "--" temp-file)))
                (if (= exit-code 0)
                    (message "Staged hunk %d/%d" (1+ hunk-index) (length hunks))
                  (message "Failed to stage hunk: %s"
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
         (left-win (plist-get state :left-window)))
    (when hunk
      (plist-put state :current-hunk-index hunk-index)
      (let ((new-line (git-review-hunk-new-start hunk))
            (old-line (git-review-hunk-old-start hunk)))
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
      (message "Hunk %d/%d" (1+ hunk-index) (length hunks)))))

(defun git-review--next-hunk (state)
  "Move to the next hunk in the current file."
  (let* ((hunks (plist-get state :current-hunks))
         (cur (or (plist-get state :current-hunk-index) -1))
         (next (1+ cur)))
    (if (>= next (length hunks))
        (message "No more hunks")
      (git-review--scroll-to-hunk state next))))

(defun git-review--prev-hunk (state)
  "Move to the previous hunk in the current file."
  (let* ((cur (or (plist-get state :current-hunk-index) 0))
         (prev (1- cur)))
    (if (< prev 0)
        (message "No previous hunk")
      (git-review--scroll-to-hunk state prev))))

;; ---------------------------------------------------------------------------
;; Refresh
;; ---------------------------------------------------------------------------

(defun git-review--refresh (state)
  "Re-read git status and refresh the display."
  (let* ((repo-root (plist-get state :repo-root))
         (old-index (plist-get state :current-index))
         (new-files (git-review--parse-status repo-root)))
    (plist-put state :files new-files)
    (if (null new-files)
        (progn
          (message "No more changes to review")
          (git-review--quit state))
      (let ((idx (min old-index (1- (length new-files)))))
        (git-review--show-file state idx)))))

;; ---------------------------------------------------------------------------
;; Quit
;; ---------------------------------------------------------------------------

(defun git-review--quit (state)
  "Quit the review session and restore windows."
  (let ((saved-config (plist-get state :saved-window-config)))
    ;; Kill review buffers
    (dolist (name (list git-review--left-buffer-name
                        git-review--right-buffer-name
                        git-review--file-list-buffer-name))
      (when-let ((buf (get-buffer name)))
        ;; Un-dedicate windows first
        (dolist (win (get-buffer-window-list buf nil t))
          (set-window-dedicated-p win nil))
        (kill-buffer buf)))
    ;; Restore window configuration
    (when saved-config
      (set-window-configuration saved-config))
    (message "Git review session ended")))

;; ---------------------------------------------------------------------------
;; State access helper
;; ---------------------------------------------------------------------------

(defun git-review--get-state ()
  "Get the review state from the current context."
  (cond
   ;; We're in the file list buffer
   (git-review--state git-review--state)
   ;; We're in a diff buffer that knows about the list buffer
   ((and (boundp 'git-review--state-buffer)
         git-review--state-buffer
         (buffer-live-p git-review--state-buffer))
    (buffer-local-value 'git-review--state git-review--state-buffer))
   ;; Try to find the file list buffer
   (t (when-let ((buf (get-buffer git-review--file-list-buffer-name)))
        (buffer-local-value 'git-review--state buf)))))

;; ---------------------------------------------------------------------------
;; Interactive commands
;; ---------------------------------------------------------------------------

(defun git-review-next-file ()
  "Move to the next file in the review."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--next-file state)))

(defun git-review-prev-file ()
  "Move to the previous file in the review."
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
  "Stage the hunk at point."
  (interactive)
  (when-let ((state (git-review--get-state)))
    (git-review--stage-hunk-at-point state)))

(defun git-review-goto-file ()
  "Visit the file at point in the file list."
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
    (define-key map (kbd "u") #'git-review-unstage-file)
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
    (kbd "]c")  #'git-review-next-hunk
    (kbd "[c")  #'git-review-prev-hunk
    (kbd "gr")  #'git-review-refresh
    (kbd "C-j") #'git-review-scroll-down
    (kbd "C-k") #'git-review-scroll-up)

  (evil-define-key '(normal motion) git-review-diff-mode-map
    (kbd "q")   #'git-review-quit
    (kbd "s")   #'git-review-stage-hunk
    (kbd "S")   #'git-review-stage-file
    (kbd "u")   #'git-review-unstage-file
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
interface with side-by-side diffs and a file list."
  (interactive)
  (let* ((repo-root (git-review--repo-root))
         (files (git-review--parse-status repo-root)))
    (unless files
      (user-error "No changes to review"))
    (let* ((saved-config (current-window-configuration))
           (layout (git-review--setup-layout))
           (state (append layout
                          (list :files files
                                :current-index 0
                                :repo-root repo-root
                                :saved-window-config saved-config
                                :current-hunks nil))))
      ;; Set up the file list buffer with the mode and state
      (with-current-buffer (plist-get layout :list-buffer)
        (git-review-mode)
        (setq git-review--state state))
      ;; Show first file
      (git-review--show-file state 0)
      ;; Focus the file list
      (select-window (plist-get layout :list-window)))))

(provide 'git-review)
;;; git-review.el ends here
