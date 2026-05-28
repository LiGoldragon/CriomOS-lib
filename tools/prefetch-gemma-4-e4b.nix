# Prefetch Gemma 4 E4B GGUF via the fetchHfModel fake-hash trick.
# Builds the FOD with a placeholder hash; nix downloads on prometheus
# (workspace's remote builder), then errors with "hash mismatch, got
# <real>". Take the real hash and plug it back in.
#
# Run:
#   nix --extra-experimental-features 'nix-command flakes' \
#     build --impure --no-link \
#     --expr 'import ./tools/prefetch-gemma-4-e4b.nix'
#
# First run: errors with the real SRI hash. Update `hash` below,
# re-run, and the build completes for real.

let
  pkgs = import <nixpkgs> { };
  fetchHfModel = import ../lib/fetchHfModel.nix { inherit pkgs; };
in
fetchHfModel {
  repo = "unsloth/gemma-4-E4B-it-GGUF";
  revision = "main";
  # Weights-only hash from 2026-05-27; STALE now that the mmproj file is
  # included below, so nix reports the real combined hash via the
  # fake-hash trick. Update once the prometheus prefetch returns it.
  hash = "sha256-5uGLLTbFgT0CEoBAUsaiy3DhgokOYFk3pH2T48cm5bc=";
  # Q4_K_M weights + the F16 vision projector. llama-server consumes the
  # weights with -m and the projector with --mmproj for image input.
  files = [ "*Q4_K_M*.gguf" "mmproj-F16.gguf" ];
}
