#!/bin/sh

# immediately when a command fails and print each command
set -ex

sudo chown -R opam: _build
sudo chown -R opam: node_modules

# initialize project and update environmemnt
opam init -a --shell=zsh
eval $(opam env)

make deps

yarn install
