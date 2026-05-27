# fetchHfModel — fixed-output derivation that downloads a Hugging Face
# model snapshot via `huggingface-cli download` and pins it to a hash.
#
# Mirrors `nix-prefetch-url` + `fetchurl` in shape: caller pins
# `{ repo, revision, hash }`, derivation produces `$out/` with the
# snapshot files. The companion `tools/nix-prefetch-huggingface`
# script computes the hash from a live download so callers can
# populate the `hash` field without hand-computing it.
#
# Usage:
#   let
#     fetchHfModel = import ./fetchHfModel.nix { inherit pkgs; };
#   in
#   fetchHfModel {
#     repo = "hf-internal-testing/tiny-random-gpt2";
#     revision = "main";
#     hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
#   }
#
# Per CriomOS-lib AGENTS.md: this lives in lib/ as a workspace
# utility; consumers under CriomOS and CriomOS-home import it with
# their own pkgs. No type-suffixed names.

{ pkgs }:

{
  # Hugging Face repository identifier — owner/name form, e.g.
  # "google/gemma-4-E4B-it" or "unsloth/gemma-4-E4B-it-GGUF".
  repo,

  # Git revision in the HF repo: branch ("main"), tag, or commit
  # hash. Pin to a commit hash for reproducibility; "main" tracks
  # the moving tip.
  revision ? "main",

  # SRI-format hash (sha256-<base64>) of the snapshot tree. Produce
  # via `tools/nix-prefetch-huggingface <repo> [<revision>]`.
  hash,

  # Optional file filter — list of glob patterns to download. Empty
  # list means the whole snapshot. Use to fetch only the GGUF
  # variant from a multi-quant repo (e.g. only
  # "*Q4_K_M*.gguf").
  files ? [ ],

  # Optional Hugging Face token environment variable name. The
  # derivation reads its value at evaluation time, NOT from
  # in-derivation environment (FODs deliberately scrub env).
  # For gated models (Gemma 4 needs Google's acceptance click),
  # the token must be passed in via builtins.getEnv during a
  # `--impure` build, or the model must be mirrored to a public
  # location.
  tokenEnvironmentVariable ? null,
}:

let
  inherit (pkgs) stdenvNoCC python3Packages lib;

  pname = lib.replaceStrings [ "/" ] [ "__" ] repo;

  filesArg = lib.concatStringsSep " " (
    map (pattern: "--include ${lib.escapeShellArg pattern}") files
  );

  tokenSetup =
    if tokenEnvironmentVariable == null then
      ""
    else
      ''
        # Token presence is required for gated models; FODs run in a
        # sandbox so we read it from the builder's environment which
        # is populated by impureEnvVars below.
        if [ -n "''${HF_TOKEN:-}" ]; then
          echo "fetchHfModel: HF_TOKEN present" >&2
        fi
      '';
in
stdenvNoCC.mkDerivation {
  inherit pname;
  version = revision;

  dontUnpack = true;
  dontInstall = true;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = hash;

  nativeBuildInputs = [
    python3Packages.huggingface-hub
    pkgs.cacert
  ];

  # The huggingface-cli reads tokens from HF_TOKEN (or a
  # configured token file). When `tokenEnvironmentVariable` is
  # named, nix-build passes that variable through into the FOD
  # sandbox via impureEnvVars (only honored under --impure).
  impureEnvVars = lib.optional (tokenEnvironmentVariable != null) tokenEnvironmentVariable;

  buildPhase = ''
    runHook preBuild

    export HF_HOME=$TMPDIR/hf
    export HF_HUB_CACHE=$TMPDIR/hf/hub
    mkdir -p $out

    ${tokenSetup}

    # Prefer modern `hf`; fall back to `huggingface-cli` for older releases.
    if command -v hf >/dev/null 2>&1; then
      hf_command=hf
    else
      hf_command=huggingface-cli
    fi

    "$hf_command" download ${lib.escapeShellArg repo} \
      --revision ${lib.escapeShellArg revision} \
      --local-dir $out \
      ${filesArg}

    # huggingface-cli writes a .cache/ subdirectory for download
    # bookkeeping (resume state). Strip it so the hash reflects
    # the snapshot content only.
    rm -rf $out/.cache

    runHook postBuild
  '';

  meta = with lib; {
    description = "Hugging Face model snapshot ${repo} @ ${revision}";
    homepage = "https://huggingface.co/${repo}";
    platforms = platforms.all;
    # Deliberately no license — `fetchHfModel` is a content fetch
    # primitive, parallel to `fetchurl`. Callers wrap the snapshot in
    # a package derivation that sets the model-specific license.
  };
}
