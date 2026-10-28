# AGENTS.md

Personal workstation configuration: one Nix flake with Home Manager for an
EndeavourOS laptop and an Apple Silicon MacBook, plus a nix-darwin layer on the
Mac for Homebrew casks and system settings. `README.md` is the user-facing
documentation. Read it before changing behaviour it describes.

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs (nixpkgs 26.05, unstable for OmniWM, herdr and pi, Home Manager, nix-darwin, nix-homebrew) and the three outputs |
| `home.nix` | Shared Home Manager entry point: module imports and `home.packages` |
| `modules/*.nix` | Shared Home Manager modules, one per area (shell, git, helix, terminal, cloud …) |
| `hosts/macbook.nix` | Mac-only Home Manager settings; imports `omniwm`, `sketchybar`, `raycast` |
| `hosts/linux.nix` | Linux-only Home Manager settings |
| `hosts/macbook-system.nix` | nix-darwin system layer: Homebrew casks, Mac App Store apps, keyboard mapping |
| `dotfiles/` | Raw config files read by modules (Helix, K9s, Zellij, herdr, pi, SSH, OmniWM, SketchyBar) |

Flake outputs:

- `homeConfigurations.macbook` (`aarch64-darwin`)
- `homeConfigurations.afredojala` (`x86_64-linux`, the default `just` target)
- `darwinConfigurations.macbook`

## Where changes go

- **CLI tool, available on both machines:** add to `home.packages` in `home.nix`.
  If Home Manager has a `programs.<name>` module, use that in the fitting
  `modules/*.nix` file instead.
- **Mac GUI app:** add the cask to `homebrew.casks` in `hosts/macbook-system.nix`.
  Never `brew install` it by hand: activation uninstalls undeclared casks.
- **Mac-only or Linux-only user config:** use `hosts/macbook.nix` or `hosts/linux.nix`.
- **New area:** create `modules/<area>.nix` and import it from `home.nix`, or from
  the host file if it is platform specific.
- **Larger config files:** put them in `dotfiles/<tool>/` and read them from the module
  (e.g. `builtins.fromTOML (builtins.readFile ../dotfiles/helix/config.toml)`).

## Commands

```sh
just build macbook          # build Mac user environment (no activation)
just mac-system-build       # build Mac system layer (no activation)
nix flake check --no-build  # evaluate all outputs, including Linux, from the Mac
```

Activation changes the live machine. `just update <target>` switches Home Manager.
`just mac-system-update` uses sudo. Leave both to the user unless they ask you
to run them, and tell them which one a change needs.

`just build` uses `--no-link`, so a `result-mac` link may be stale. To inspect
generated files, use
`nix build --no-link --print-out-paths '.#homeConfigurations.macbook.activationPackage'`
and look under `<out>/home-files` and `<out>/home-path/bin`.

## Conventions

- Flakes only see tracked files. Run `git add` on new modules and dotfiles before building.
- Keep `home.stateVersion` and `system.stateVersion` unchanged.
- Keep packages on stable nixpkgs. Use `nixpkgs-unstable` only when stable lacks
  the package or is a major version behind (currently OmniWM, herdr and pi), and
  explain why in a comment.
- Comments are short and explain *why*, not what.
- Update `README.md` when a change adds or alters something it lists, such as
  the "What's included" table or the shortcut tables.
- Do not commit secrets or private keys. Credentials come from 1Password and `gh`.
- Commit messages: short imperative subject in sentence case, no prefix, for
  example "Add Qobuz as a Homebrew cask". Use one commit per logical change.
- Work happens directly on `master`.

## Verifying a change

1. Run `just build macbook`. For system-layer changes, also run `just mac-system-build`.
2. Run `nix flake check --no-build` so the Linux target still evaluates.
3. If you changed generated config, inspect the built output (see above).
4. Give the user the activation command that the change needs.
