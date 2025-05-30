#! /usr/bin/env bash

eval "$(peano init)"

__list_remote_branches() {
    git ls-remote --heads "${1:?no repo given}" | sed -nr 's,^.*refs/heads/(.*)$,\1,p'
}

_fzf_complete_peano_remote_branches() {
    _fzf_complete --multi --reverse --height=8 --prompt="choose a branch> " -- "$@" < <(
        __list_remote_branches "$__peano_repo"
    )
}

_fzf_complete_peano_get_build_options() {
    local name="$1"
    _fzf_complete --multi --reverse --height=8 --prompt="$name> " -- "$@" < <(        
        case "$name" in
            --config)
                __peano_list_leaf_dirs_of "${__peano_confroot}"
                ;;
            --branch)
                __list_remote_branches "$__peano_repo"
                ;;
        esac
    )
}

_fzf_complete_peano_bash() {
    local verb="${COMP_WORDS[1]}"
    [[ -z "$verb" ]] && return 0
    case "$verb" in
        clone)
            _fzf_complete_peano_remote_branches
            ;;
        build|modules)
            _fzf_complete_peano_get_build_options "${COMP_WORDS[-2]}"
            ;;
        *)
            return 0
            ;;
    esac
}

_fzf_complete_peano_zsh() {
    local -a words
    words=("${(@f)$(echo $words)}")
    local verb="${words[2]}"
    [[ -z "$verb" ]] && return 0
    case "$verb" in
        clone)
            _fzf_complete_peano_remote_branches
            ;;
        build|modules)
            _fzf_complete_peano_get_build_options "${words[-2]}"
            ;;
        *)
            return 0
            ;;
    esac
}

if [[ -n "$ZSH_VERSION" ]]; then
    compdef _fzf_complete_peano_zsh peano
elif [[ -n "$BASH_VERSION" ]]; then
    complete -F _fzf_complete_peano_bash -o default -o bashdefault peano
fi
