<p align="center">
    <img
      alt="Python's logo"
      title="python-logo"
      src="https://www.python.org/static/community_logos/python-logo-generic.svg"
    />
</p>

<h1 align="center"> Python project template</h1>

<p align="center">
    <a
      href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=ET7CGUSGVJGWG&currency_code=USD&source=url">
      <img
        src="https://img.shields.io/badge/Donate-PayPal-green.svg"
        alt="Buy me a mug"
        title="donate-paypal"/>
    </a>
</p>

<p align="center">
  <a href="#objective">Objective</a>&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#contents">Contents</a>&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="#execution">Execution</a>
</p>

## Objective

This repository intends to stand a reliable and consistent procedure for
setting up a development environment for python projects.

Thus, the main dependencies for the project's structure organization are the
following:

* [`pyenv`][pyenv]; and
* [`pypoetry`][pypoetry].

## Contents

* [`setup.sh`](setup.sh): Sets up a proper and isolated python environment,
  designed for both development and production purposes;
* [`pyproject.toml`](pyproject.toml): Describes the project's build specification,
  according to its [specification][pep-518];
* [`.editorconfig`](.editorconfig): Applies formatting to whole repository
  content for any compatible editors, as depicted in its [site][editorconfig];
* [`.gitignore`](.gitignore): Usual [ignoring file][gitignore] against a python
  project's build, caching files and its corresponding editors.

There are other files in repository but not essential for a project
initialization. such this file, LICENSE, CI/CD configuration and any other ones.

## Execution

The [`setup.sh`](setup.sh) file is going to run the following:

* [`shellcheck`][shellcheck]'s check in order to verify its own content's
  syntax;
* For both:
  * Downloads each aforementioned project management tools and installs as the
    way its corresponding procedure recommends;
  * Initiates its corresponding program and exports them to `PATH` variable;
  * Appends to `~/.bashrc` the code snippet once in order to activate them
    automatically as a new shell is spawned.
* For [`pyenv`][pyenv]:
  * Creates a `virtualenv` activation using the repository's recipient folder
    name and according to the `PROJ_VER` variable:
    * Skips this step if a environment had already been activated as described
      above;
    * The current activation will be cleaned up if does not correspond to the
      way this script sets it.
* For [`pypoetry`][pypoetry]:
  * Verifies for poetry updates;
  * Instructs the program to not creating virtual environments for itself;
  * If `pyproject.toml` is present:
    * Checks if this file is valid;
    * Updates the activated virtualenv's dependencies.
        * (_Creates a new one with its default setting if the file absent_).
  * Adds some useful development dependencies to the activated virtualenv if
    absent.
    * (_If a `poetry.lock` file does not exist in the repository and a one is
      generated during the execution, it is going to be removed afterwards_).

In addition to that, it does:

* Install other complementary development tools such as [`docker`][docker],
  [`terraform`][terraform] and [`AWS client`][aws-cli];
* Create `.gitignore` and [`.editorconfig`][editorconfig] files as previously
  described if the corresponding one is absent.

[pyenv]: https://github.com/pyenv/pyenv
[pypoetry]: https://python-poetry.org
[shellcheck]: https://www.shellcheck.net
[docker]: https://www.docker.com
[terraform]: https://www.terraform.io
[aws-cli]: https://aws.amazon.com/pt/cli
[gitignore]: https://www.gitignore.io/api/pydev,flask,django,python,terraform,pycharm+all,jupyternotebooks
[editorconfig]: https://editorconfig.org
[pep-518]: https://www.python.org/dev/peps/pep-0518
