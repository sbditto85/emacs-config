#!/usr/bin/env bash

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     emacs --chdir "$(pwd)" --init-dir "$(dirname "$0")" "$@";;
    Darwin*)    open -na Emacs --args --chdir "$(pwd)" --init-dir "$(dirname "$0")" "$@";;
    *)          exit 1
esac

