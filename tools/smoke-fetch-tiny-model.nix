# Smoke-test for lib/fetchHfModel.nix — fetches a tiny public HF model
# and proves the derivation produces a content-hashed output matching
# what nix-prefetch-huggingface computed.
#
# Run:
#   nix --extra-experimental-features 'nix-command flakes' \
#     build --impure --no-link --print-out-paths \
#     --expr 'import ./tools/smoke-fetch-tiny-model.nix'
#
# The hash below was produced by running:
#   ./tools/nix-prefetch-huggingface hf-internal-testing/tiny-random-gpt2
# in a `nix shell nixpkgs#python3Packages.huggingface-hub`.

let
  pkgs = import <nixpkgs> { };
  fetchHfModel = import ../lib/fetchHfModel.nix { inherit pkgs; };
in
fetchHfModel {
  repo = "hf-internal-testing/tiny-random-gpt2";
  revision = "main";
  hash = "sha256-8K9B/C62GW5lXC0c8QQpQ9QAE1UMoG+kYqvGhnWIp64=";
}
