#!/usr/bin/env sh
set -e

# @see https://gist.github.com/dhsrocha/ee88f54c2e913c59412817e210bd206b/edit

# ::: Global variables
readonly RC="$HOME/.bashrc"
readonly PROJ_NAME="${PWD##*/}"

readonly PROJ_VER="3.8.2"
readonly VENV_FILE=".python-version"
readonly GITHUB_RAW="https://raw.githubusercontent.com"

# ::: Parameter parsing
readonly IS_LOG="$(if [ "$1" != "-q" ]; then echo 1; else echo 0; fi)"

# ::: Public functions

# Set up python environment for the project. Main function.
setup() {

  # Pre-conditions for testing:
  # * .pyenv folder absent;
  # * .rc file with no export/eval code appended;
  # * local .python-version file absent; and
  # * Variables not exported (fresh terminal).

  # Execution scenarios:
  # - All pre-conditions are satisfied to run the dependency manager;
  # - One of the instruments has an inappropriate virtualization activated; or
  # - None of the instruments is installed or activated.

  readonly PY_CURR_VER="$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')"
  readonly VENV_NAME="$(python -c 'import sys;print(sys.prefix)' |
    sed 's|.*/||')"

  log "$FINE" "::: Starting python environment setup. :::" &&
    env_manager &&
    pyenv shell "$PROJ_NAME" &&
    log "✔ Updating pip and setuptools." &&
    pip install -q --upgrade pip setuptools &&
    dep_manager &&
    log "$FINE" "::: Setup concluded. :::"
}

# ::: Private functions :::

{
  # Sets up pyenv (https://github.com/pyenv/pyenv).
  env_manager() {
    if [ -z "$(command -v pyenv)" ]; then
      log "$WARN" "✔ Installing or replacing pyenv distribution."
      [ -d "$HOME/.pyenv" ] && rm -rf "$HOME/.pyenv"
      export PATH=$HOME/.pyenv/bin:$PATH && (curl https://pyenv.run | sh)
    else
      log "✔ Updating current pyenv distribution." &&
        pyenv update >/dev/null 2>&1
    fi

    {
      log "✔ Initializing pyenv."
      eval "$(pyenv init -)"
      eval "$(pyenv virtualenv-init -)"
    } && {
      grep -qE "(eval.+pyenv)" "$RC" || {
        log "$WARN" "✔ Appending pyenv initialization snippet to $RC." && {
          printf "\n# ::: Pyenv configuration :::\n"
          echo "# https://github.com/pyenv/pyenv-virtualenv/issues/36"
          echo "# https://github.com/python-poetry/poetry/issues/172"
          echo "export PATH=\"\$HOME/.pyenv/bin:\$PATH\""
          echo "if [ -z \"\$PYENV_INITIALIZED\" ]; then"
          echo "  eval \"\$(pyenv init -)\""
          echo "  eval \"\$(pyenv virtualenv-init -)\""
          echo "  export PYENV_INITIALIZED=1"
          echo "fi"
        } >>"$RC"
      }
    }

    readonly VERS_DIR="$(pyenv root)/versions"
    [ "$VENV_NAME" != "$PROJ_NAME" ] && {

      [ ! -d "$VERS_DIR/$PROJ_VER/envs/$PROJ_NAME" ] &&
        [ -h "$VERS_DIR/$PROJ_NAME" ] &&
        log "$WARN" "✔ Unlinking any environment linked to this project." &&
        unlink "$(pyenv root)/versions/$PROJ_NAME"

      [ -f "$VENV_FILE" ] && [ "$(cat "$VENV_FILE")" != "$PROJ_NAME" ] &&
        log "$WARN" "✔ Removing pre-existent .python-version file." &&
        rm "$VENV_FILE"

      [ -n "$(command -v source)" ] && [ -n "$(command -v deactivate)" ] && {
        log "$WARN" "✔ Deactivating other project's activated environment."
        # shellcheck disable=SC1091
        # shellcheck disable=SC2039
        source deactivate
      }
    }

    [ ! -d "$VERS_DIR/$PROJ_VER" ] &&
      log "$WARN" "✔ Installing python distribution managed by pyenv." &&
      pyenv install "$PROJ_VER"

    [ ! -d "$VERS_DIR/$PROJ_NAME" ] &&
      log "$WARN" "✔ Creating virtualenv provided by pyenv." &&
      pyenv virtualenv --clear -q -f "$PROJ_VER" "$PROJ_NAME" >/dev/null

    [ ! -f "$VENV_FILE" ] &&
      log "$WARN" "✔ Loading virtualenv provided by pyenv." &&
      pyenv local "$PROJ_NAME"

    return 0
  }

  # Sets up pypoetry (https://python-poetry.org).
  dep_manager() {
    [ "$PROJ_NAME" != "$PYENV_VERSION" ] && # (pyenv shell "$PROJ_NAME")
      throw "Environment not ready for dependency management."

    [ -z "$(command -v poetry)" ] && # then
      log "✔ Installing python poetry." &&
      pyenv shell system &&
      readonly POETRY_URL="/python-poetry/poetry/master/get-poetry.py" &&
      (curl -sSL "${GITHUB_RAW}${POETRY_URL}" | python) &&
      pyenv shell --unset
    [ -n "$(command -v poetry)" ] && # else
      log "✔ Updating pypoetry." && poetry self update

    # shellcheck disable=SC1091
    # shellcheck source=$HOME/.poetry/env
    . "$HOME/.poetry/env"
    grep -qE ".poetry/env" "$RC" || {
      log "$WARN" "✔ Appending pypoetry initialization snippet to $RC." && {
        printf "\n# ::: PyPoetry configuration :::\n"
        echo "# shellcheck source=\$HOME/.poetry/env"
        echo ". \$HOME/.poetry/env"
      } >>"$RC"
    }
    # https://github.com/python-poetry/poetry#enable-tab-completion-for-bash-fish-or-zsh
    # https://github.com/python-poetry/poetry/issues/1017
    readonly POETRY_FILE="/etc/bash_completion.d/poetry.bash-completion" &&
      [ ! -f "$POETRY_FILE" ] &&
      log "$WARN" "✔ Adding poetry completation to $RC." &&
      (poetry completions bash | sudo tee "$POETRY_FILE")

    poetry config -q virtualenvs.create false

    readonly LOCKFILE="./poetry.lock" &&
      [ -f "$LOCKFILE" ] && readonly HAS_LOCKFILE_BEFORE=1

    readonly PROJ_FILE="./pyproject.toml"
    [ -f "$PROJ_FILE" ] && { # then
      [ "$(poetry env list | grep -E "$PROJ_NAME")" != "" ] &&
        # https://python-poetry.org/docs/managing-environments/
        log "$WARN" "✔ Cleaning other dangling virtualenvs created by poetry." &&
        poetry env remove "$(command -v python)"

      log "✔ Checking and adding dependencies with pypoetry." &&
        poetry check --no-ansi && poetry update
    }
    [ ! -f "$PROJ_FILE" ] && # else
      log "$WARN" "✔ Initializing project with pypoetry." && poetry init -n

    readonly DEV_DEPS="ipdb click docker
      flake8 hacking black isort mypy pydocstyle sphinx xdoctest
      pytest pytest-cov pytest-flakes pytest-bdd pytest-instafail"

    readonly CURR_DEPS="$(poetry show | grep -Eo '^[a-z]([a-z0-9-])+')"
    for I in $DEV_DEPS; do
      [ "$(echo "$CURR_DEPS" | grep -o "$I")" != "" ] ||
        { log "✔ Adding $I as development dependency." && poetry add -D "$I"; }
    done

    [ -z "$HAS_LOCKFILE_BEFORE" ] &&
      log "$WARN" "✔ Removing $LOCKFILE due to the absence prior updating." &&
      rm "$LOCKFILE"

    return 0
  }

  # ::: Utility functions

  # Prints customized colored messages. can be set to be silent conditionally.
  readonly FINE=32 && readonly WARN=33 && readonly INFO=34
  log() {
    set -u
    [ "$IS_LOG" -eq 1 ] && { case "$1" in 31 | 32 | 33 | 34)
      [ -t 1 ] && printf "\033[%sm%s\033[0m\n" "$1" "$2" || echo "$2"
      ;;
    *) printf "\033[${INFO}m%s\033[0m\n" "$*" ;; esac }
    set +u
    return 0
  }

  # Prints red colored messages and then finishes the program with a error exit.
  throw() { log 31 "ERROR: $*" 1>&2 && exit 1; }

  # Set up self-checking logic for this script (https://www.shellcheck.net/).
  check() {
    [ -z "$(command -v shellcheck)" ] &&
      log "$WARN" "Install shellcheck into system." &&
      sudo apt update && sudo apt install shellcheck

    if [ "$(shellcheck -a -s sh "$0" 2>/dev/null)" ]; then
      shellcheck -a -s sh "$0"
    else
      shellcheck -s sh "$0"
    fi

    return "$?"
  }

  # ::: Supporting programs's installation functions

  # Set up docker (https://docs.docker.com/install/linux/docker-ce/debian/).
  middleware() {
    [ -z "$(command -v docker)" ] &&
      log "$WARN" "Install docker into system." &&
      (readonly REL="$(lsb_release -cs)" &&
        sudo apt remove docker docker-engine docker.io containerd runc &&
        sudo apt install curl apt-transport-https \
          ca-certificates gnupg2 software-properties-common &&
        curl -fsSL https://download.docker.com/linux/debian/gpg |
        sudo apt-key add - && sudo apt-key fingerprint 0EBFCD88 &&
        sudo add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/debian $REL stable" &&
        sudo apt-get update &&
        sudo apt-get install docker-ce docker-ce-cli containerd.io)

    readonly DOCKR_CMP_VER="1.25.4" &&
      readonly URL_DCKR="https://github.com/docker/compose/releases/download/$DOCKR_CMP_VER/docker-compose" &&
      [ -n "$(command -v docker)" ] && [ -z "$(command -v docker-compose)" ] &&
      log "$WARN" "Install docker-compose into system." &&
      (sudo curl -L "$URL_DCKR-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose &&
        sudo chmod +x /usr/local/bin/docker-compose &&
        docker-compose --version)
    return 0
  }

  # Set up terraform (https://www.terraform.io/).
  deploy() {
    [ -z "$(command -v terraform)" ] &&
      log "$WARN" "Install terraform into system." &&
      (DEST="$HOME/Downloads/" && readonly TF_VER="0.12.23" &&
        FILE="terraform_${TF_VER}_linux_amd64.zip" &&
        curl "https://releases.hashicorp.com/terraform/$TF_VER/$FILE" \
          -L -o "$DEST/$FILE" &&
        sudo apt install unzip &&
        unzip "$DEST/$FILE" -d "$DEST" &&
        sudo mv terraform "/bin" &&
        rm "$DEST")
    return 0
  }

  # Set up AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html).
  cloud() {
    [ -z "$(command -v aws)" ] &&
      log "$WARN" "Install AWS CLI into system." &&
      (sudo apt install zip unzip &&
        FILE="awscliv2.zip" &&
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$FILE" &&
        unzip "$FILE" && sudo "./aws/install" && rm "$FILE" "./aws")
    return 0
  }

  # Sets up a .editorconfig file to the project (https://editorconfig.org).
  formatting() {
    [ ! -f ".editorconfig" ] &&
      log "$WARN" "Create .editorconfig file for the python project." && {
      echo "# https://editorconfig.org"
      echo && echo "root = true"
      echo && echo "[*]"
      echo "charset = utf-8" && echo "max_line_length = 79"
      echo "indent_size = 2" && echo "tab_width = 2"
      echo "indent_style = space" && echo "trim_trailing_whitespace = true"
      echo "insert_final_newline = true" && echo "end_of_line = lf"
      echo && echo "[{*.pyw, *.py}]"
      echo "indent_size = 4" && echo "tab_width = 4"
    } >".editorconfig"
    return 0
  }

  # Sets up a .gitignore file to the project (https://git-scm.com/).
  ignore() {
    [ ! -f ".gitignore" ] &&
      log "$WARN" "Create .gitignore file for the python project." &&
      readonly URL_IG="https://www.gitignore.io/api/pydev,flask,django,python,terraform,pycharm+all,jupyternotebooks" &&
      curl "$URL_IG" >>".gitignore"
    return 0
  }

  # Sets up git bash prompt (https://github.com/magicmonty/bash-git-prompt).
  git_prompt() {
    [ "$GIT_PROMPT_ONLY_IN_REPO" = 1 ] || {
      log "Create git bash prompt into system." &&
        readonly PROMPT=".bash-git-prompt/gitprompt.sh" &&
        git clone "https://github.com/magicmonty/bash-git-prompt.git" \
          "$HOME/.bash-git-prompt" --depth=1

      grep -qE "($PROMPT)" "$RC" || {
        echo "# ::: https://github.com/magicmonty/bash-git-prompt#via-git-clone"
        echo "[ -f "\$HOME/$PROMPT" ] &&"
        echo "    export GIT_PROMPT_ONLY_IN_REPO=1 &&"
        echo "    . \$HOME/$PROMPT"
      } >>"$RC"
    }
    return 0
  }
}

# ::: Run block :::
main() {
  sudo -k &&
    check && ignore && formatting &&
    git_prompt && middleware && cloud && deploy &&
    setup "$1"
}
main "$1"
