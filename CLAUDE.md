# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Emacs configuration using a literate programming approach with Org mode. The configuration is managed by Elpaca package manager and uses `use-package` for package declarations. The primary configuration is in `config.org`, which is tangled to `config.el` via the `literate-config` package.

## Architecture

### Configuration Loading Flow

1. `early-init.el` - Loads before package system initialization. Sets up fonts, disables UI elements (scroll bar, tool bar, menu bar), and configures frame defaults.
2. `init.el` - Bootstraps Elpaca package manager, sets up `use-package` integration, and initializes literate configuration from `config.org`.
3. `config.org` - Main literate configuration file that contains all package configurations and customizations. This is the **primary file to edit**.
4. `config.el` - Generated from `config.org` by literate-config, loaded automatically at startup.

### Key Configuration Principles

- **Literate Configuration**: All configuration is documented in `config.org` using Org mode's babel system. Code blocks with `:tangle yes` (default) are extracted to `config.el`.
- **No Customizations Persistence**: Custom file is set to a temporary file that's discarded between sessions to force intentional configuration.
- **No Littering**: Uses `no-littering` package to keep `user-emacs-directory` clean by moving state files to `var/` and `etc/` subdirectories.

### Project/Workspace Management

The configuration uses a sophisticated workspace system:
- **Tabs as Projects**: Tab-bar mode is enabled where each tab typically represents a project workspace.
- **Tabspaces**: Integrates with `project.el` to scope buffers to tabs/workspaces. Each tab/project has its own buffer list.
- **Project Discovery**: Projects are discovered from directories listed in the `PROJECTS_PATH` environment variable (colon-separated on Unix).
- **Leader Key Pattern**: Uses `SPC p` prefix for project commands (e.g., `SPC p p` to switch projects, `SPC p f f` to find file).

### Evil Mode Configuration

This configuration uses Evil mode (Vim keybindings):
- **Evil Collection**: Provides Evil bindings for many modes.
- **Evil Escape**: `jk` in insert mode returns to normal mode.
- **Evil MC**: Multiple cursors support with `M-I` (next match), `M-i` (next line), `M-g` (undo all).
- **Evil Surround**: Vim-surround functionality for manipulating surrounding delimiters.
- **Evil Goggles**: Visual feedback for Evil operations using diff faces.

### Completion System

Multi-layered completion setup:
- **Vertico**: Vertical completion UI in the minibuffer.
- **Orderless**: Flexible completion style (space-separated components can match in any order).
- **Consult**: Enhanced minibuffer commands (buffer switching, ripgrep, line search).
- **Corfu**: Inline completion-at-point UI with auto-completion enabled.
- **Cape**: Additional completion-at-point functions.
- **Embark**: Act on completion candidates with `C-c C-c` in vertico.

### Leader Key Bindings

Global leader key is `SPC` in normal/visual modes and `M-SPC` globally (including insert mode). Key prefixes:
- `SPC :` - M-x
- `SPC c` - Comments
- `SPC d` - Insert date/time
- `SPC f` - File operations
- `SPC g` - Git/Magit
- `SPC h` - Help/documentation
- `SPC p` - Project operations (primary workspace)
- `SPC s` - Search
- `SPC q` - Quit/session

## Common Development Tasks

### Editing Configuration

**Always edit `config.org`, never `config.el` directly.** The workflow:

1. Edit `config.org`
2. Save the file
3. Reload Emacs or evaluate the changed sections

To evaluate a code block in `config.org`: Place point in the block and use `C-c C-c` (or `SPC SPC org-babel-execute-src-block`).

### Package Management with Elpaca

```emacs-lisp
;; Install/update all packages
M-x elpaca-update-all

;; Rebuild a specific package (e.g., vterm)
M-x elpaca-rebuild
;; Then select the package

;; View package status
M-x elpaca-manager

;; Delete a package
M-x elpaca-delete
```

### Clean Rebuild

Use the provided script to remove package state:

```bash
./clean.sh  # Removes elpaca/ and eln-cache/ directories
```

Then restart Emacs to reinstall everything from scratch.

### Starting Emacs with this Configuration

```bash
# Start Emacs with this config directory
./start.sh

# The script handles platform differences (Linux uses emacs, macOS uses open)
# It sets --init-dir to this directory and --chdir to current working directory
```

### Project Workflow

Projects are managed through the tab-bar and tabspaces:

- `SPC p p` - Switch to or create project workspace (uses `PROJECTS_PATH` env var)
- `SPC p f f` - Find file in current project
- `SPC p b` - Switch to project buffer
- `SPC p s` - Search in project with ripgrep
- `SPC p t` - Toggle project terminal (vterm scoped to project)
- `SPC p c` - Close workspace
- `SPC p k` - Close workspace and kill all project buffers
- `SPC p 1-9` - Switch to tab/workspace 1-9
- `s-t` / `s-w` / `s-T` - New tab / Close tab / Undo close tab

### Terminal Usage

The configuration uses vterm with project-scoped toggling:

- `SPC p t` - Toggle vterm for current project
- Vterm compiles a native module on first use; if issues occur, try `M-x elpaca-rebuild` → select `vterm`

### Custom Functions and Environment Variables

Several custom functions rely on environment variables:

- `PROJECTS_PATH` - Colon-separated list of directories containing projects
- `AUTHOR` - Used in `custom/comment-attribution` for adding attributed comments
- `TIME_DAY_LEADING_ZERO` - Set to "off" to disable leading zeros in dates

Custom helper functions:
- `custom/comment-attribution` - Insert "- AUTHOR, DATE" comment attribution
- `custom/search-projects` - Search across all projects in PROJECTS_PATH
- `custom/find-projects-in-projects-path` - Scan and remember all projects in PROJECTS_PATH
- `presentation-mode` - Toggle large font size for presentations

## File Structure Notes

- `early-init.el` - Pre-package initialization
- `init.el` - Elpaca bootstrap and literate config loader
- `config.org` - **Main configuration (edit this)**
- `config.el` - Generated, do not edit
- `experimental.org` - Experimental config (not loaded by default)
- `notes.org` - Personal notes and TODOs
- `var/` - Runtime state files (gitignored)
- `etc/` - Configuration state files (gitignored)
- `elpaca/` - Package manager and packages (can be deleted and rebuilt)

## Important Notes

- **vterm compilation**: First time using vterm may require `M-x elpaca-rebuild` selecting vterm, then restart Emacs.
- **Font installation**: Run `M-x all-the-icons-install-fonts` on first setup for modeline icons.
- **Hardcoded PATH**: The PATH in `init.el` line 7 is hardcoded for macOS. On Linux or other systems, this should be updated or removed to use the system PATH.
- **Disabled sections**: Some sections in `config.org` are marked `:tangle no` - these are intentionally disabled (e.g., use-feature macro, recursive minibuffers, modern-tab-bar styling).
- **Backup file naming**: Uses SHA1 hashing for backup and auto-save filenames to avoid path length issues (borrowed from Doom Emacs).
