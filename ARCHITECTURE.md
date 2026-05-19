# CriomOS-lib Architecture

CriomOS-lib is the tiny shared Nix library for CriomOS repositories. It
exports pure helpers and constants through `inputs.criomos-lib.lib`.

The library is dependency-free by design: importing it must not evaluate
nixpkgs. Data here must be generic across clusters. Cluster, node, user,
network, and secret truth belongs in the projected horizon, not in this
repo.

Current surface:

- `lib/default.nix` — constants and pure helper functions.
- `data/largeAI/llm.json` — shared open model catalog consumed by
  system modules.

If a value is only used by one consumer, keep it in that consumer. Move a
value here only when sharing it removes real duplication without
encoding cluster policy.
