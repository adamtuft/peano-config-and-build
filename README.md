# Peano Config and Build

## Purpose

This repository provides a script to simplify the configuration, building, and management of [Peano](https://gitlab.lrz.de/hpcsoftware/Peano) builds, including command-line tools and interactive shell completions to streamline working with various builds of Peano.

## Contents

- [Installation](#installation)
- [Usage Instructions](#usage-instructions)
- [Shell Completions](#shell-completions)
- [Installing fzf](#installing-fzf)

---

## Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/adamtuft/peano-config-and-build.git
   ```
2. **Create a symlink for easy access:**
    ```sh
    ln -s "./peano-config-and-build/main" "~/.local/bin/peano"
    ```
    Make sure `~/.local/bin` is in your `PATH`. Add the following to your `.bashrc` or `.zshrc` if needed:
    ```sh
    export PATH="$HOME/.local/bin:$PATH"
    ```

---

## Usage Instructions

The main entry point is the `peano` command, which provides the following subcommands:

- `clone <branch>`  
    Clone the given branch from the main Peano repository. Supports fuzzy find for branches with fzf.
    
    Options include:
    - `--name <name>`: Name for the cloned directory.
    - `--root <path>`: The root directory to clone into.

- `build --config <config-name> <build-dir>`.
    Build Peano with a given config. Supports fuzzy find for the config with fzf.
    
    Options include:
    - `--save`: Save the configuration in a script in the build dir for later re-use.
    - `--config <config-dir>`: Specify the configuration directory (supports interactive completion).
    - `--expect-branch <branch>`: Abort if the currently branch doesn't match `<branch>`.

- `modules --config <config> <build-dir>`  
    Print the path to the saved configure script. Use this to re-load the modules used to configure the build. Supports fuzzy find for the config with fzf.

- `init`
    Print the internal commands required for other scripts/commands. Used by the shell completions.

- `completions`  
    Output shell completion code for Bash or Zsh.

- `help`  
    Show help information for the `peano` command.

#### Example Usage

```sh
peano clone --root build/peano multigrid # clone multigrid branch into build/peano/multigrid
peano build --config cosma build/peano/p4 # build in the p4 directory with the cosma config
```

---

## Shell Completions

Interactive completions are provided for both Bash and Zsh using [fzf](https://github.com/junegunn/fzf).

#### Activation

When `peano` is on your path, add the following line to your shell configuration file to enable completions:

  ```sh
  eval $(peano completions)
  ```

#### Demo: Using Shell Completions

To use completions, type a partial command and press `**`<kbd>Tab</kbd>:

```sh
peano clone **<Tab>
```

This will show a list of available branches (using `fzf` for fuzzy search).


---

## Installing fzf

`fzf` is required for interactive completion. Install via your package manager or Spack:

  ```sh
  # Ubuntu/Debian
  sudo apt install fzf

  # macOS (Homebrew)
  brew install fzf

  # Spack
  spack install fzf
  ```

---
