#!/bin/sh

# immediately when a command fails and print each command
set -ex

sudo chown -R opam: _build
sudo chown -R opam: node_modules

opam init -a --shell=zsh

# install dev dependencies
opam install --yes --with-doc --with-test --with-dev-setup --deps-only --working-dir --update-invariant .

eval $(opam env)

# install opam packages used for vscode ocaml platform package
# e.g. when developing with emax, add also: utop merlin ocamlformat
make deps
