;;; tasks.el --- Task management system for org files -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Your Name

;; Author: Your Name
;; Version: 1.0.0
;; Package-Requires: ((emacs "28.1") (org "9.0"))
;; Keywords: tasks, org, productivity
;; URL: https://github.com/yourusername/emacs-config

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package provides a task management system for org files.
;; It allows users to manage tasks within a specific section of an org file,
;; including adding, completing, and deleting tasks, as well as managing
;; subtasks and tracking the current task.

;;; Code:

(require 'org)
(require 'org-element)
(require 'evil)

(defgroup tasks nil
  "Task management system for org files."
  :group 'org
  :prefix "tasks-")

(defcustom tasks-org-file "~/Documents/org/tasks.org"
  "The org file where tasks are stored."
  :type 'file
  :group 'tasks)

(defcustom tasks-section "* Tasks"
  "The section header in the org file where tasks are stored."
  :type 'string
  :group 'tasks)

(defcustom tasks-buffer-name "*Tasks*"
  "Name of the tasks buffer."
  :type 'string
  :group 'tasks)

(defvar tasks--current-task nil
  "The currently active task.")

(defvar tasks--buffer nil
  "The tasks buffer.")

;;; Core Functions

(defun tasks--get-section-position ()
  "Return the position of the tasks section in the org file."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (goto-char (point-min))
      (if (search-forward tasks-section nil t)
          (point)
        (error "Tasks section not found in %s" tasks-org-file)))))

(defun tasks--get-tasks ()
  "Return a list of all tasks in the tasks section."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (goto-char (tasks--get-section-position))
      (let ((tasks nil))
        (org-map-entries
         (lambda ()
           (let ((task (org-element-at-point)))
             (when (eq (org-element-type task) 'headline)
               (push (list
                      :title (org-element-property :title task)
                      :level (org-element-property :level task)
                      :todo (org-element-property :todo-keyword task)
                      :position (org-element-property :begin task)
                      :end-position (org-element-property :end task))  ; Add end position
                     tasks))))
         nil
         'tree)
        (nreverse tasks)))))

(defun tasks--add-task (title &optional parent-position)
  "Add a new task with TITLE.
If PARENT-POSITION is provided, add as subtask."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (if parent-position
          (goto-char parent-position)
        (goto-char (tasks--get-section-position)))
      (if parent-position
          (org-insert-subheading t)
        (org-insert-heading))
      (insert title)
      (org-todo "TODO"))))

(defun tasks--complete-task (position)
  "Mark task at POSITION as done."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (goto-char position)
      (org-todo "DONE"))))

(defun tasks--delete-task (position)
  "Delete task at POSITION."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (goto-char position)
      (org-cut-subtree))))

(defun tasks--delete-completed-tasks ()
  "Delete all completed tasks in the tasks section."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (goto-char (tasks--get-section-position))
      (org-map-entries
       (lambda ()
         (when (string= (org-element-property :todo-keyword (org-element-at-point)) "DONE")
           (org-cut-subtree)))
       nil
       'tree))))

(defun tasks--set-current-task (position)
  "Set the current task to the task at POSITION."
  (with-current-buffer (find-file-noselect tasks-org-file)
    (save-excursion
      (goto-char position)
      (let ((task (org-element-at-point)))
        (setq tasks--current-task
              (list :title (org-element-property :title task)
                    :position position))))))

;;; Interactive Functions

(defun tasks-add-task (title)
  "Add a new task with TITLE."
  (interactive "sTask title: ")
  (let ((inhibit-read-only t))
    (tasks--add-task title)
    (tasks-refresh)))

(defun tasks-add-subtask (title)
  "Add a new subtask with TITLE under the current task."
  (interactive "sSubtask title: ")
  (let ((inhibit-read-only t))
    (if tasks--current-task
        (tasks--add-task title (plist-get tasks--current-task :position))
      (error "No current task selected"))
    (tasks-refresh)))

(defun tasks-complete-task ()
  "Mark the current task as done."
  (interactive)
  (let ((inhibit-read-only t))
    (if tasks--current-task
        (progn
          (tasks--complete-task (plist-get tasks--current-task :position))
          (setq tasks--current-task nil)
          (tasks-refresh))
      (error "No current task selected"))))

(defun tasks-delete-task ()
  "Delete the current task."
  (interactive)
  (let ((inhibit-read-only t))
    (if tasks--current-task
        (progn
          (tasks--delete-task (plist-get tasks--current-task :position))
          (setq tasks--current-task nil)
          (tasks-refresh))
      (error "No current task selected"))))

(defun tasks-delete-completed ()
  "Delete all completed tasks."
  (interactive)
  (let ((inhibit-read-only t))
    (tasks--delete-completed-tasks)
    (tasks-refresh)))

;;; Mode Definition

;; Define the base keymap
(defvar tasks-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" #'tasks-add-task)
    (define-key map "s" #'tasks-add-subtask)
    (define-key map "c" #'tasks-complete-task)
    (define-key map "d" #'tasks-delete-task)
    (define-key map "D" #'tasks-delete-completed)
    (define-key map "n" #'next-line)
    (define-key map "p" #'previous-line)
    (define-key map (kbd "<return>") #'tasks-set-current)
    (define-key map "q" #'quit-window)
    (define-key map "g" #'tasks-refresh)
    map)
  "Keymap for tasks mode.")

(define-derived-mode tasks-mode special-mode "Tasks"
  "Major mode for managing tasks.
\\{tasks-mode-map}"
  :group 'tasks
  (setq-local buffer-read-only nil)
  (setq-local truncate-lines t)
  (setq-local cursor-type 'box)
  (hl-line-mode 1))

;; Setup evil-mode key bindings
(defun tasks--setup-evil-keys ()
  "Setup evil-mode key bindings for tasks mode."
  (when (bound-and-true-p evil-mode)
    (evil-make-overriding-map tasks-mode-map 'normal)
    (evil-define-key 'normal tasks-mode-map
      "a" #'tasks-add-task
      "s" #'tasks-add-subtask
      "c" #'tasks-complete-task
      "d" #'tasks-delete-task
      "D" #'tasks-delete-completed
      "j" #'next-line
      "k" #'previous-line
      "<return>" #'tasks-set-current
      "q" #'quit-window
      "g" #'tasks-refresh
      "r" #'tasks-refresh)
    (evil-define-key 'insert tasks-mode-map
      (kbd "C-c C-c") #'tasks-set-current
      (kbd "C-c C-q") #'quit-window)
    (evil-normal-state)))

(add-hook 'tasks-mode-hook #'tasks--setup-evil-keys)

;;; Buffer Management

(defun tasks--create-buffer ()
  "Create and setup the tasks buffer."
  (setq tasks--buffer (get-buffer-create tasks-buffer-name))
  (with-current-buffer tasks--buffer
    (tasks-mode)
    (setq-local header-line-format "Tasks - [a]dd [s]ubtask [c]omplete [d]elete [D]elete completed [RET]set current [q]uit")))

(defun tasks--display-buffer ()
  "Display the tasks buffer in a popup window."
  (let ((window (display-buffer-in-side-window
                 tasks--buffer
                 '((side . bottom)
                   (window-height . 0.3)
                   (window-parameters
                    (no-other-window . t)
                    (no-delete-other-windows . t))))))
    (select-window window)
    (set-window-dedicated-p window t)
    (when (bound-and-true-p evil-mode)
      (evil-normal-state))))

(defun tasks-refresh ()
  "Refresh the tasks buffer."
  (with-current-buffer tasks--buffer
    (let ((inhibit-read-only t)
          (old-point (point)))
      (erase-buffer)
      (insert "Tasks:\n\n")
      (dolist (task (tasks--get-tasks))
        (let ((prefix (make-string (* 2 (1- (plist-get task :level))) ?\s))
              (status (if (string= (plist-get task :todo) "DONE") "[X]" "[ ]"))
              (current (if (and tasks--current-task
                               (= (plist-get task :position)
                                  (plist-get tasks--current-task :position)))
                          " *" "")))
          (insert (format "%s%s %s %s\n"
                         prefix
                         status
                         (plist-get task :title)
                         current))))
      (goto-char (min old-point (point-max)))
      (when (bound-and-true-p evil-mode)
        (evil-normal-state)))))

;;; Public Interface

(defun tasks-show ()
  "Show the tasks buffer."
  (interactive)
  (unless (buffer-live-p tasks--buffer)
    (tasks--create-buffer))
  (tasks-refresh)
  (tasks--display-buffer))

(defun tasks-set-current ()
  "Set the current task to the task at point."
  (interactive)
  (let ((tasks (tasks--get-tasks))
        (pos (point)))
    (dolist (task tasks)
      (when (and (>= pos (plist-get task :position))
                 (<= pos (plist-get task :end-position)))  ; Use end position for better matching
        (tasks--set-current-task (plist-get task :position))
        (tasks-refresh)
        (message "Current task set to: %s" (plist-get task :title))
        (return)))))

(defun tasks-get-current-task ()
  "Return the current task title or nil if no current task."
  (when tasks--current-task
    (plist-get tasks--current-task :title)))

;; Add use-package support
(defun tasks-setup (org-file section)
  "Setup tasks package with ORG-FILE and SECTION.
This function is meant to be called from use-package :config."
  (setq tasks-org-file org-file
        tasks-section section))

(provide 'tasks)
;;; tasks.el ends here 