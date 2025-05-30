#! /usr/bin/env bash

__peano_repo='https://gitlab.lrz.de/hpcsoftware/Peano.git/'
__peano_confroot="${__peano_root}/config"

__peano_print_help() {
    echo "Helper script for setting up and building Peano/ExaHyPE with various options."
    echo
    echo "Usage:"
    echo "  $0 <command> [options] [arguments]"
    echo "    Commands:"
    echo "      init"
    echo "          Print the internal commands required for other scripts/commands. Used by the shell completions."
    echo "      completions"
    echo "          Print fzf shell completions."
    echo "      clone [--name <name>] [--root <path>] <branch>"
    echo "          Clone the given branch from the main Peano repository."
    echo "      build [-t|--threads <n>] [-o|--otter <otter>] [--no-make] [--clean] [-s|--save] [--expect-branch <branch>] -c|--config <config> <build-dir>"
    echo "          Configure and build Peano in the specified directory with given options."
    echo "      modules -c|--config <config> <build-dir>"
    echo "          Show the saved modules configuration for a build directory."
    echo "      help"
    echo "          Show this help message."
    echo
    echo "Options:"
    echo "  -c, --config <config>    Specify configuration name or file."
    echo "  -t, --threads <n>        Number of threads for building."
    echo "  -o, --otter <otter>      Use otter configuration."
    echo "      --no-make            Only configure, do not build."
    echo "      --clean              Clean build directory before building."
    echo "  -s, --save               Save the configuration to a file."
    echo "  --expect-branch <branch> Specify expected git branch."
    echo "      --root <path>        Root directory to clone into."
    echo "      --name <name>        Name for the cloned directory."
}

__peano_list_leaf_dirs_of() {
    (
        cd "$1"
        find . -mindepth 1 -type d -exec sh -c 'printf "%s/\n" "${0#./}"' {} \; \
            | sort -r \
            | awk 'a!~"^"$0{a=$0;print}' \
            | xargs -I {} sh -c 'printf "%s\n" "${0%/}"' {} \
            | sort
    )
}

__peano_print_known_configs() {
    local root="$1"; shift
    configs=("$@")
    echo known configs in "${root}:"
    printf "  %s\n" "${configs[@]}"
}

__peano_parse_args() {
    action="${1:-help}"; shift;
    if [[ "$action" == clone ]]; then
        while [[ $1 == -*  ]]; do
            case $1 in
                --root) shift; root=$1;
                ;;
                --name) shift; name=$1;
                ;;
                *) echo "Unknown option $1 (skipping)";
                ;;
            esac
            shift
        done
        branch="${1:-p4}"
    elif [[ "$action" == build ]]; then
        # Get keyword args
        while [[ $1 == -*  ]]; do
            case $1 in
                -c|--config) shift; config=$1;
                ;;
                -t|--threads) shift; threads=$1;
                ;;
                -o|--otter) shift; otter=$1;
                ;;
                --no-make) no_make=1;
                ;;
                --clean) clean=1;
                ;;
                -s|--save) save=1;
                ;;
                --expect-branch) shift; expect_branch=$1;
                ;;
                *) echo "Unknown option $1 (skipping)";
                ;;
            esac
            shift
        done

        # Require a config arg
        known_configs=($(__peano_list_leaf_dirs_of "$__peano_confroot"))
        if [[ -z "$config" ]]; then
            echo please choose a config or provide a config file with --config >&2
            __peano_print_known_configs "$__peano_confroot" "${known_configs[@]}" >&2
            return 1
        fi

        # Check whether config is a file, or a known config name
        if [[ -f "$config" ]]; then
            echo use config file: "$config"
        else
            local match=""
            for name in "${known_configs[@]}"; do
                if [[ "$name" == "$config" ]]; then
                    match=1 && break
                fi
            done
            if [[ -z "$match" ]]; then
                echo unknown config: "$config" >&2
                __peano_print_known_configs "$__peano_confroot" "${known_configs[@]}" >&2
                return 1
            fi
        fi

        # Get positional args
        [[ -z "$1" ]] && echo peano dir not provided >&2 && return 1
        peanodir="$1"
        shift

        [[ "$#" -gt 0 ]] && echo $# remaining args ignored: "$@"

    elif [[ "$action" == modules ]]; then
        # Get keyword args
        while [[ $1 == -*  ]]; do
            case $1 in
                -c|--config) shift; config=$1;
                ;;
                *) echo "Unknown option $1 (skipping)";
                ;;
            esac
            shift
        done

        # Require a config arg
        known_configs=($(__peano_list_leaf_dirs_of "$__peano_confroot"))
        if [[ -z "$config" ]]; then
            echo please choose a config or provide a config file with --config >&2
            __peano_print_known_configs "$__peano_confroot" "${known_configs[@]}" >&2
            return 1
        fi

        # Get positional args
        [[ -z "$1" ]] && echo Peano dir not provided >&2 && return 1
        peanodir=$(realpath "$1")
        shift

    fi
    return 0
}

__peano_check_branch() {
    local expected="$1"
    local current_branch=$(git branch --no-color --show-current)
    echo "on branch:" $current_branch
    if [[ "$expected" != "$current_branch" ]]; then
        echo "the current branch '$current_branch' doesn't match the expected branch '$expected'" >&2
        return 1
    fi
}

__peano_format_config_file() {
    cat << EOF
#! /usr/bin/env bash

# peanodir: $4
# branch:   $5 ($6)

action="\$1"

if [[ "\$action" == "load" || "\$action" == "" ]]; then
$1
$2
fi

if [[ "\$action" == "configure" || "\$action" == "" ]]; then
$3
fi
EOF
}

__peano_configure_build() {
    local config="$1"
    local otter="$2"
    local save="$3"

    if [[ -f "$config" ]]; then
        echo source config: "$config"
        source "$config"
        return
    fi

    echo use config: "$config"

    config_dir="$__peano_confroot"/"$config"

    if [[ ! -d "$config_dir" ]]; then
        echo config dir not found: "$config_dir"
        return 1
    fi

    modules_file="$config_dir"/modules.sh
    config_file="$config_dir"/configure.sh
    otter_file="$config_dir"/../otter.sh

    source "$modules_file"

    if [[ -n "$otter" ]]; then
        echo use otter
        source "$otter_file"
    fi

    module list -l

    libtoolize
    aclocal
    autoconf
    autoheader
    cp src/config.h.in .;
    automake --add-missing

    source "$config_file"

    if [[ -f config.status ]]; then
        echo ===
        echo configure call:
        echo ./configure $(./config.status --config)
        echo ===
    else
        echo WARNING: config.status not found >&2
    fi

    if [[ -n "$save" ]]; then
        save_file=./config-"${config//\//.}".sh # Replace any slashes with '.'
        module_commands=$(<"$modules_file")
        configure_commands=$(<"$config_file")
        [[ -n "$otter" ]] && otter_commands=$(otter=$otter envsubst < "$otter_file")
        echo "### configuration file:"
        __peano_format_config_file "$module_commands" "$otter_commands" "$configure_commands" "$peanodir" $(git branch --show-current) $(git rev-parse HEAD) | tee $save_file
        echo "### config saved to:" $(realpath "$save_file") \($(wc -l "$save_file" | cut -d " " -f 1) lines\)
    fi
}

peano_main() {
    __peano_parse_args $@

    if [[ "$action" == help ]]; then
        __peano_print_help
    elif [[ "$action" == ls ]]; then
        known_configs=($(__peano_list_leaf_dirs_of "$__peano_confroot"))
        __peano_print_known_configs "$__peano_confroot" "${known_configs[@]}"
    elif [[ "$action" == clone ]]; then
        dest="${root}${root:+/}${branch}${name:+-}${name}"
        git clone git@gitlab.lrz.de:hpcsoftware/Peano.git -b "$branch" "$dest"
    elif [[ "$action" == build ]]; then
        cd $peanodir
        echo working in: $(pwd)
        if [[ -n "$expect_branch" ]]; then
            __peano_check_branch "$expect_branch" || return $?
        fi
        __peano_configure_build "$config" "$otter" "$save"
        [[ -n "$no_make" ]] && return 0
        [[ "$clean" == "1" ]] && echo cleaning build dir && make clean
        make -j ${threads:-1}
    elif [[ "$action" == modules ]]; then
        saved_modules="$peanodir"/config-"$config".sh
        [[ -f "$saved_modules" ]] && echo "$saved_modules" || echo "not found:" "$saved_modules"
    else
        echo invalid command: $action
        __peano_print_help
        return 1
    fi
}
