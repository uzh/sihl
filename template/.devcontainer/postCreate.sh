# ocaml/opam post create script

sudo chown -R opam: _build
sudo chown -R opam: node_modules

# initialize project and update environmemnt
opam init -a --shell=zsh
eval $(opam env)

# ensure all system dependencies are installed
opam install --yes --with-doc --with-test --with-dev-setup --deps-only --working-dir --update-invariant .

# install opam packages used for vscode ocaml platform package
# e.g. when developing with emax, add also: utop merlin ocamlformat
make deps

yarn install
