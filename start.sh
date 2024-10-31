#!/usr/bin/env bash

open -na Emacs --args --chdir "$(pwd)" --init-dir "$(dirname "$0")" "$@"
