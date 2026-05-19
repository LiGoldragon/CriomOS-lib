# CriomOS-lib Skills

- Keep the flake dependency-free. Do not add nixpkgs, blueprint, or
  system-specific inputs here.
- Keep exported names stable and fully spelled out; consumers pin this
  repo by revision.
- Do not put cluster-specific data here. Horizon carries cluster truth.
- Prefer small, pure Nix helpers over abstractions that hide evaluation
  cost or ownership.
