;;; task-manager.el --- A simple task management package for Emacs 30+

;;; Commentary:
;; This package provides a lightweight task management system
;; with features like adding tasks, subtasks, completion, and frame positioning.
;; Supports both standard Emacs and evil-mode.
;; Task data is persistent between Emacs sessions.

;;; Code:

(require 'cl-lib)
(require 'widget)
(require 'wid-edit)
(require 'pp)

(defgroup task-manager nil
  "Customization group for the task manager package."
  :group 'productivity)

(defcustom task-manager-buffer-name "*Task Manager*"
  "Name of the task manager buffer."
  :type 'string
  :group 'task-manager)

(defcustom task-manager-width 0.25
  "Width of the task manager window as a fraction of frame width."
  :type 'float
  :group 'task-manager)

(defcustom task-manager-height 0.5
  "Height of the task manager window as a fraction of frame height."
  :type 'float
  :group 'task-manager)

(defcustom task-manager-save-file (expand-file-name "task-manager-data.el" user-emacs-directory)
  "File to save task manager data."
  :type 'file
  :group 'task-manager)

(cl-defstruct (task-manager-task (:constructor task-manager-task-create))
  id
  text
  (completed nil)
  (subtasks nil)
  (parent nil))

(defvar task-manager-tasks '()
  "List of all tasks in the task manager.")

(defvar task-manager-window nil
  "Window for the task manager.")

(defvar task-manager-task-markers nil
  "Markers for all tasks, used for selection.")

(defvar task-manager-current-task nil
  "Currently selected task.")

(defvar task-manager-task-overlay nil
  "Overlay for highlighting the current task.")

(defvar task-manager-dirty nil
  "Flag to indicate if tasks have been modified since last save.")

(defun task-manager-create-task (text &optional parent)
  "Create a new task with TEXT, optionally as a subtask of PARENT."
  (let ((new-task (task-manager-task-create
                   :id (random 10000)
                   :text text
                   :parent parent)))
    (if parent
        (push new-task (task-manager-task-subtasks parent))
      (push new-task task-manager-tasks))
    (setq task-manager-dirty t)
    new-task))

(defun task-manager-toggle-task-completion (task)
  "Toggle the completion status of TASK."
  (setf (task-manager-task-completed task)
        (not (task-manager-task-completed task)))
  (setq task-manager-dirty t))

(defun task-manager-delete-task (task)
  "Remove TASK from the task list or its parent's subtasks."
  (if (task-manager-task-parent task)
      (setf (task-manager-task-subtasks (task-manager-task-parent task))
            (cl-remove task (task-manager-task-subtasks (task-manager-task-parent task))))
    (setq task-manager-tasks
          (cl-remove task task-manager-tasks)))
  (setq task-manager-dirty t))

(defun task-manager-clear-completed-subtasks (task)
  "Remove all completed subtasks recursively from TASK."
  (setf (task-manager-task-subtasks task)
        (cl-remove-if
         (lambda (subtask)
           (when (not (task-manager-task-completed subtask))
             ;; Recursively process incomplete subtasks
             (task-manager-clear-completed-subtasks subtask)
             nil)  ; Keep this subtask
           t)      ; Remove completed subtasks
         (task-manager-task-subtasks task)))
  (setq task-manager-dirty t))

(defun task-manager-clear-completed-tasks ()
  "Remove all completed tasks and subtasks."
  (interactive)
  (when (y-or-n-p "Delete all completed tasks? ")
    ;; First, remove completed top-level tasks
    (setq task-manager-tasks
          (cl-remove-if
           (lambda (task)
             (task-manager-task-completed task))
           task-manager-tasks))

    ;; Then clean completed subtasks from remaining tasks
    (dolist (task task-manager-tasks)
      (task-manager-clear-completed-subtasks task))

    ;; Clear current task if it was completed
    (when (and task-manager-current-task
               (task-manager-task-completed task-manager-current-task))
      (setq task-manager-current-task nil))

    (setq task-manager-dirty t)
    (task-manager-render-buffer)))

(defun task-manager-find-task-by-line (line-number)
  "Find task from the task-manager-task-markers by line number."
  (let ((marker-key (number-to-string line-number)))
    (when (and task-manager-task-markers
               (gethash marker-key task-manager-task-markers))
      (gethash marker-key task-manager-task-markers))))

(defun task-manager-find-task-at-point ()
  "Find the task at the current point in the buffer."
  (task-manager-find-task-by-line (line-number-at-pos)))

(defun task-manager-serialize-task (task)
  "Convert TASK to a serializable form."
  (let ((serialized
         (list :id (task-manager-task-id task)
               :text (task-manager-task-text task)
               :completed (task-manager-task-completed task)
               :subtasks nil)))
    ;; Recursively serialize subtasks
    (when (task-manager-task-subtasks task)
      (setf (plist-get serialized :subtasks)
            (mapcar #'task-manager-serialize-task
                    (task-manager-task-subtasks task))))
    serialized))

(defun task-manager-deserialize-task (data &optional parent)
  "Convert serialized DATA back to a task object with optional PARENT."
  (let ((task (task-manager-task-create
               :id (plist-get data :id)
               :text (plist-get data :text)
               :completed (plist-get data :completed)
               :parent parent)))
    ;; Recursively deserialize subtasks
    (when (plist-get data :subtasks)
      (setf (task-manager-task-subtasks task)
            (mapcar (lambda (subtask-data)
                      (task-manager-deserialize-task subtask-data task))
                    (plist-get data :subtasks))))
    task))

(defun task-manager-save-tasks ()
  "Save tasks to the save file."
  (interactive)
  (when task-manager-dirty
    (with-temp-file task-manager-save-file
      (let ((serialized-tasks
             (mapcar #'task-manager-serialize-task task-manager-tasks)))
        (insert ";; Task Manager Data - Edit with caution\n")
        (insert ";; Format: List of task plists with :id, :text, :completed, and :subtasks\n\n")
        (pp serialized-tasks (current-buffer))))
    (setq task-manager-dirty nil)
    (message "Tasks saved to %s" task-manager-save-file)))

(defun task-manager-load-tasks ()
  "Load tasks from the save file."
  (interactive)
  (when (file-exists-p task-manager-save-file)
    (with-temp-buffer
      (insert-file-contents task-manager-save-file)
      (goto-char (point-min))
      (condition-case nil
          (let ((data (read (current-buffer))))
            (setq task-manager-tasks
                  (mapcar #'task-manager-deserialize-task data))
            (setq task-manager-dirty nil)
            (message "Tasks loaded from %s" task-manager-save-file))
        (error (message "Error reading task data from %s" task-manager-save-file))))))

(defun task-manager-edit-tasks-file ()
  "Open the task data file for manual editing."
  (interactive)
  (find-file task-manager-save-file)
  (message "Edit carefully. Reload tasks with 'M-x task-manager-load-tasks' when done."))

(defun task-manager-render-task (task depth)
  "Render a TASK with DEPTH for indentation and track its position."
  (let* ((indent (make-string (* depth 2) ? ))
         (status (if (task-manager-task-completed task) "✓ " "☐ "))
         (text (if (task-manager-task-completed task)
                   (propertize (task-manager-task-text task) 'face 'shadow 'strike-through t)
                 (task-manager-task-text task)))
         (start (point)))
    ;; Add line marker
    (puthash (number-to-string (line-number-at-pos)) task task-manager-task-markers)
    (insert indent status text "\n")
    ;; Render subtasks
    (dolist (subtask (task-manager-task-subtasks task))
      (task-manager-render-task subtask (1+ depth)))))

(defun task-manager-position-window ()
  "Position the task manager window in the top right of the frame."
  (let* ((frame (selected-frame))
         (frame-width (frame-width frame))
         (frame-height (frame-height frame))
         (window-width (round (* frame-width task-manager-width)))
         (task-buffer (get-buffer task-manager-buffer-name)))

    ;; If the task manager window doesn't exist, create it
    (unless (get-buffer-window task-buffer)
      (let ((new-window
             (split-window
              nil
              (- frame-width window-width)
              'right)))
        (set-window-buffer new-window task-buffer)
        (set-window-dedicated-p new-window t)
        (setq task-manager-window new-window)))))

(defun task-manager-highlight-current-task ()
  "Highlight the current task in the buffer."
  (when task-manager-task-overlay
    (delete-overlay task-manager-task-overlay))
  (when task-manager-current-task
    (save-excursion
      (goto-char (point-min))
      ;; Find the line containing the current task
      (cl-loop for i from 1
               while (not (eobp))
               do
               (when (equal (task-manager-find-task-by-line i) task-manager-current-task)
                 (setq task-manager-task-overlay
                       (make-overlay (line-beginning-position) (line-end-position)))
                 (overlay-put task-manager-task-overlay 'face 'highlight)
                 (cl-return))
               (forward-line 1)))))

(defun task-manager-render-buffer ()
  "Render the task manager buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    ;; Create a new hash table for task markers
    (setq task-manager-task-markers (make-hash-table :test 'equal))

    (insert (propertize
             (format "Task Manager - Current: %s"
                     (or (and task-manager-current-task
                              (task-manager-task-text task-manager-current-task))
                         "None"))
             'face 'bold)
            "\n\n")

    (if task-manager-tasks
        (dolist (task task-manager-tasks)
          (task-manager-render-task task 0))
      (insert "No tasks. Add a task using 'M-x task-manager-add-task'\n"))

    (task-manager-highlight-current-task)))

(defun task-manager-show-buffer ()
  "Show the task manager buffer."
  (interactive)
  (let ((buffer (get-buffer-create task-manager-buffer-name)))
    (with-current-buffer buffer
      (task-manager-mode)
      (task-manager-render-buffer))
    (display-buffer buffer)
    (task-manager-position-window)))

(defun task-manager-hide-buffer ()
  "Hide the task manager buffer."
  (interactive)
  (let ((buffer (get-buffer task-manager-buffer-name)))
    (when buffer
      (delete-windows-on buffer))))

(defun task-manager-add-task ()
  "Interactively add a new task."
  (interactive)
  (let* ((task-text (read-string "Enter task: "))
         (add-as-subtask (and task-manager-current-task
                             (y-or-n-p "Add as a subtask? ")))
         (parent (when add-as-subtask
                   task-manager-current-task)))
    (task-manager-create-task task-text parent)
    (task-manager-render-buffer)))

(defun task-manager-select-task ()
  "Select the task at point."
  (interactive)
  (let ((task (task-manager-find-task-at-point)))
    (setq task-manager-current-task task)
    (task-manager-render-buffer)))

(defun task-manager-deselect-task ()
  "Deselect the current task."
  (interactive)
  (setq task-manager-current-task nil)
  (task-manager-render-buffer))

(defun task-manager-complete-task ()
  "Complete the current or selected task."
  (interactive)
  (when task-manager-current-task
    (task-manager-toggle-task-completion task-manager-current-task)
    (task-manager-render-buffer)))

(defun task-manager-delete-current-task ()
  "Delete the current task."
  (interactive)
  (when task-manager-current-task
    (task-manager-delete-task task-manager-current-task)
    (setq task-manager-current-task nil)
    (task-manager-render-buffer)))

(define-derived-mode task-manager-mode special-mode "Task Manager"
  "Major mode for task management."
  (setq buffer-read-only t)
  (use-local-map task-manager-mode-map)
  (setq-local revert-buffer-function #'task-manager-render-buffer)

  ;; Evil mode specific setup
  (when (bound-and-true-p evil-mode)
    (add-hook 'evil-normal-state-entry-hook #'task-manager-evil-setup nil t)
    (evil-set-initial-state 'task-manager-mode 'normal)))

(defun task-manager-evil-setup ()
  "Setup evil-mode keybindings for task manager."
  (when (eq major-mode 'task-manager-mode)
    (evil-define-key 'normal task-manager-mode-map
      "a" #'task-manager-add-task
      "\r" #'task-manager-select-task
      "c" #'task-manager-complete-task
      "d" #'task-manager-delete-current-task
      "C" #'task-manager-clear-completed-tasks
      "u" #'task-manager-deselect-task
      "w" #'task-manager-save-tasks
      "e" #'task-manager-edit-tasks-file
      "q" #'task-manager-hide-buffer)))

(define-key task-manager-mode-map (kbd "a") #'task-manager-add-task)
(define-key task-manager-mode-map (kbd "RET") #'task-manager-select-task)
(define-key task-manager-mode-map (kbd "c") #'task-manager-complete-task)
(define-key task-manager-mode-map (kbd "d") #'task-manager-delete-current-task)
(define-key task-manager-mode-map (kbd "C") #'task-manager-clear-completed-tasks)
(define-key task-manager-mode-map (kbd "u") #'task-manager-deselect-task)
(define-key task-manager-mode-map (kbd "w") #'task-manager-save-tasks)
(define-key task-manager-mode-map (kbd "e") #'task-manager-edit-tasks-file)
(define-key task-manager-mode-map (kbd "q") #'task-manager-hide-buffer)

;; Save tasks when Emacs exits
(add-hook 'kill-emacs-hook #'task-manager-save-tasks)

;;;###autoload
(defun task-manager ()
  "Start the task manager."
  (interactive)
  (unless task-manager-tasks
    (task-manager-load-tasks))
  (task-manager-show-buffer))

(provide 'task-manager)

;;; task-manager.el ends here
