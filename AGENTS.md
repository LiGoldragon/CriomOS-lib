# Agent Bootstrap — CriomOS-lib

## Scope

Shared helpers and data files consumed by both CriomOS and
CriomOS-home. Intentionally tiny: no Rust, no nixpkgs dependency, no
blueprint. Pure helpers + static data.

Today this is:

- `lib/default.nix` — `constants`, `importJSON`, and `mkJsonMerge`.
  Surface as `inputs.criomos-lib.lib`.

`data/largeAI/llm.json` was deleted in step 6 of the horizon
re-engineering arc — every server-side AI provisioning field
(serverPort, models[].source/sha256/ctxSize/loadOnStartup,
presetDefaults, router config) now lives in
`horizon.cluster.aiProviders[].models[].serving` and
`.servingConfig`. CriomOS modules (`llm.nix`) and CriomOS-home
modules (`pi-models.nix`) read horizon directly.

## What belongs here

- Helper functions used by **two or more** of: CriomOS, CriomOS-home,
  and any future criomos-* repo.
- Static data files referenced by two or more such repos.

## What does NOT belong here

- Anything used by only one repo — keep it local.
- Anything that needs nixpkgs to evaluate (this flake stays
  dependency-free so consumers don't pay for it).
- Long-form prose / architecture docs — those go in the consuming repo
  whose architecture is being described.

## Hard rules (inherited)

- Jujutsu only.
- Push before consumer rebuilds — consumers reference this flake by
  rev, so the rev must exist on the remote before they can build.
- Keep the helper API stable — every change ripples to all consumers.

## AGENTS.md / CLAUDE.md convention

`AGENTS.md` is the source of truth; `CLAUDE.md` is a one-line shim
reading `See [AGENTS.md](AGENTS.md).`.
