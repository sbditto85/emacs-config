;;; task-manager.el --- A simple task management package for Emacs 30+

;;; Commentary:
;; This package provides a lightweight task management system
;; with features like adding tasks, subtasks, completion, and frame positioning.

;;; Code:

(require 'cl-lib)
(require 'widget)
(require 'wid-edit)

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

(defvar task-manager-tasks '()
  "List of all tasks in the task manager.")

(defvar task-manager-window nil
  "Window for the task manager.")

(defvar task-manager-frame nil
  "Frame for the task manager.")

(defvar task-manager-current-task nil
  "Currently selected task.")

(defstruct task-manager-task
  id
  text
  completed
  subtasks)

(defun task-manager-create-task (text &optional parent)
  "Create a new task with TEXT, optionally as a subtask of PARENT."
  (let ((new-task (make-task-manager-task
                   :id (random 10000)
                   :text text
                   :completed nil
                   :subtasks '())))
    (if parent
        (push new-task (task-manager-task-subtasks parent))
      (push new-task task-manager-tasks))
    new-task))

(defun task-manager-toggle-task-completion (task)
  "Toggle the completion status of TASK."
  (setf (task-manager-task-completed task)
        (not (task-manager-task-completed task))))

(defun task-manager-delete-task (task)
  "Remove TASK from the task list."
  (setq task-manager-tasks
        (remove task task-manager-tasks)))

(defun task-manager-render-task (task &optional depth)
  "Render a TASK with optional DEPTH for indentation."
  (let* ((depth (or depth 0))
         (indent (make-string (* depth 2) ? ))
         (status (if (task-manager-task-completed task) "✓ " "☐ "))
         (text (if (task-manager-task-completed task)
                   (propertize (task-manager-task-text task) 'face 'shadow 'strike-through t)
                 (task-manager-task-text task))))
    (insert indent status text "\n")
    (dolist (subtask (task-manager-task-subtasks task))
      (task-manager-render-task subtask (1+ depth)))))

(defun task-manager-position-window ()
  "Position the task manager window in the top right of the frame."
  (let* ((frame (selected-frame))
         (frame-width (frame-width frame))
         (frame-height (frame-height frame))
         (window-width (round (* frame-width task-manager-width)))
         (window-height (round (* frame-height task-manager-height)))
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

(defun task-manager-render-buffer ()
  "Render the task manager buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (propertize
             (format "Task Manager - Current: %s"
                     (or (and task-manager-current-task
                              (task-manager-task-text task-manager-current-task))
                         "None"))
             'face 'bold)
            "\n\n")
    (if task-manager-tasks
        (dolist (task task-manager-tasks)
          (task-manager-render-task task))
      (insert "No tasks. Add a task using 'M-x task-manager-add-task'\n"))))

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
  (let ((task-text (read-string "Enter task: "))
        (parent (when task-manager-current-task
                  (y-or-n-p "Add as a subtask? ")
                  task-manager-current-task)))
    (task-manager-create-task task-text parent)
    (task-manager-show-buffer)))

(defun task-manager-complete-task ()
  "Complete the current or selected task."
  (interactive)
  (when task-manager-current-task
    (task-manager-toggle-task-completion task-manager-current-task)
    (task-manager-show-buffer)))

(defun task-manager-delete-current-task ()
  "Delete the current task."
  (interactive)
  (when task-manager-current-task
    (task-manager-delete-task task-manager-current-task)
    (setq task-manager-current-task nil)
    (task-manager-show-buffer)))

(define-derived-mode task-manager-mode special-mode "Task Manager"
  "Major mode for task management."
  (setq buffer-read-only t)
  (use-local-map task-manager-mode-map)
  (setq-local revert-buffer-function #'task-manager-render-buffer))

(define-key task-manager-mode-map (kbd "a") #'task-manager-add-task)
(define-key task-manager-mode-map (kbd "c") #'task-manager-complete-task)
(define-key task-manager-mode-map (kbd "d") #'task-manager-delete-current-task)
(define-key task-manager-mode-map (kbd "q") #'task-manager-hide-buffer)

;;;###autoload
(defun task-manager ()
  "Start the task manager."
  (interactive)
  (task-manager-show-buffer))

(provide 'task-manager)

;;; task-manager.el ends here
