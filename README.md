# Shared Home Manager configuration

Standalone Home Manager for EndeavourOS and macOS. The pinned inputs are shared;
host identity and platform-specific settings are separate. A separate nix-darwin
system target bootstraps Homebrew and declares the Mac desktop apps.

| Target | Platform | Account | Status |
| --- | --- | --- | --- |
| `afredojala` | `x86_64-linux` | `/home/afredojala` | Existing Linux host |
| `macbook` | `aarch64-darwin` | `/Users/afredojala` | Apple Silicon MacBook |

## Managed configuration

- Zsh with completion, autosuggestions, syntax highlighting, FZF, and Zoxide.
- Starship's default prompt. The previous Starship symlinks pointed to missing files.
- Helix as `EDITOR` and `VISUAL`, preserving the existing theme, keybindings,
  and editor settings in `dotfiles/helix/config.toml`.
- Python language servers Pyrefly and Ruff, and Rust Analyzer, supplied through
  Nix rather than fetched with `uvx` at editor startup.
- Existing Git identity, GitHub CLI (including `gh co`), and GitHub HTTPS
  authentication through `gh`. SSH host entries for `rbpi`, `datadriven`, and
  `hetzner` preserve the existing users and key paths.
- Shared CLI packages, including `rg` (ripgrep), `bat`, Zellij, Yazi, `rsync`,
  `wget`, `zip`, and `unzip`.
- `kubectl`, Helm, K9s with existing settings/aliases, and Google Cloud CLI with
  the GKE authentication plugin. K9s screen dumps use a host-relative state path.
- Chrome and 1Password on macOS through the separate nix-darwin target.
- Ghostty with the existing Shift+Enter binding and scroll speed, launching the
  managed Zsh. Linux uses `ghostty`; macOS uses the native `ghostty-bin` package.
- Zellij keybindings, Nord theme, floating Yazi/Lazygit shortcuts, and the existing
  Catppuccin status-bar layout. The zjstatus WASM is pinned to v0.25.0 with a hash.
  Clipboard copying uses Nix-provided `wl-copy` on Linux and `/usr/bin/pbcopy` on
  macOS. New panes use managed Zsh; scrollback editing uses Helix.

Project environments and Linux desktop configuration are not yet migrated. JSX retains its auto-format
setting, but its language server/formatter must currently come from the project.
Bash configuration is unchanged. Zsh replaces the old ML4W/Oh My Zsh/Oh My Posh
loader; desktop-specific aliases and startup effects are not imported. On Linux,
`~/.zshrc_custom` is still sourced if present and remains outside this repository.
Review that file before activation for overrides to the prompt or editor.

## Build without changing the running environment

Run from this directory:

```sh
just build                 # Linux
just build macbook         # Run on the Mac
```

The equivalent Linux command is:

```sh
nix build --no-link 'path:.#homeConfigurations.afredojala.activationPackage'
```

The `path:` reference includes new, untracked modules during local development.
When transferring through Git, include all module, host, and dotfile files.
The Nixpkgs and Home Manager pins are unchanged; nix-darwin and nix-homebrew
inputs have been added to the lock file. Linux keeps its original state version;
the new Mac home starts at 26.05.

## First Mac setup

1. Install Nix with flakes enabled and verify `nix --version` in a new terminal.
2. Once the configuration has been committed and pushed, clone it on the Mac
   (or transfer the complete directory, including `flake.lock` and all new files):

   ```sh
   git clone https://github.com/afredojala/configuration.git
   cd configuration
   ```
3. Confirm `id -un` reports `afredojala` and `uname -m` reports `arm64`.
   The Mac target is configured for this account and Apple Silicon.
4. Build the Mac configuration:

   ```sh
   nix build --out-link result-mac 'path:.#homeConfigurations.macbook.activationPackage'
   ```

5. Back up any existing shell, Git, SSH, GitHub CLI, K9s, Helix, Ghostty, and Zellij configuration, including targets
   of existing symlinks. Record `home-manager generations` if already installed.
6. When ready to activate, use the Home Manager executable from the built profile:

   ```sh
   ./result-mac/home-path/bin/home-manager switch      -b "hm-backup-$(date +%Y%m%d-%H%M%S)" --flake 'path:.#macbook'
   ```

7. Open a new Zsh terminal. Check `echo "$EDITOR"`, `command -v hx`, `hx --health`,
   `git config user.email`, the prompt, completions, and a real project.

This does not change the account's login shell. macOS's normal Zsh can read the
managed startup files; use the Nix-provided Zsh explicitly if required.
Credentials and application data must be migrated separately, outside this repo.

## Mac desktop apps

The Home Manager target installs terminal tools and Ghostty. The separate
`darwinConfigurations.macbook` target installs Homebrew, Chrome, and 1Password.
After the Home Manager setup, run on the Mac:

```sh
just mac-system-build    # Build and review first; does not install apps yet
just mac-system-update   # Uses sudo; activates the system layer and installs apps
```

The system activation is separate because nix-darwin manages system-level files.
This configuration leaves the Nix installation under its existing installer's
control, preserves undeclared Homebrew packages, and does not upgrade existing
Homebrew packages automatically. Homebrew cask versions are not pinned by
`flake.lock`; the declared list is reproducible, but available application versions
may change. Ghostty remains managed by Home Manager, not Homebrew.

If Chrome or 1Password was installed manually before activation, Homebrew may
report an existing-app conflict. Review that conflict rather than deleting the
existing application or its data automatically. Chrome is declared because it
is the current Linux default; choosing the default browser on macOS is separate.

## Account access and navigation

After activation, sign in to 1Password and Chrome, then authenticate GitHub:

```sh
gh auth login --hostname github.com --git-protocol https
gh auth status
```

SSH configuration is managed, but private keys are not. Securely transfer the
required `id_datadriven` and `id_ed25519` keys or configure a replacement key/agent
before using those SSH hosts. No Git signing key or 1Password SSH-agent integration
has been invented; those require choosing your key and authentication approach.
Tokens, SSH private keys, kubeconfigs, and Google Cloud credentials stay outside
this repository. Run `gcloud auth login` on the Mac and restore only the Kubernetes
contexts you need; application-default credentials are a separate project decision.

Zoxide is already enabled: `z name` jumps to a frequently used directory, and
`zi` provides interactive selection. `cd` retains its normal shell behavior.
The Mac learns its own directory paths, so Linux's jump history is not copied.
`rg` and `bat` are already installed explicitly.

Useful offline checks after activation:

```sh
kubectl version --client
helm version --short
k9s version
gcloud version
gke-gcloud-auth-plugin --version
ssh -G datadriven
```

These do not verify live cluster or account access. Use read-only access checks
against the intended accounts and clusters after signing in.

## Terminal and Zellij verification

On macOS, Home Manager copies Ghostty to
`~/Applications/Home Manager Apps/Ghostty.app`. Launch that app after activation.
It is managed through Nix; Ghostty's own updater is disabled on macOS.
Left Option sends Alt for Zellij shortcuts; right Option remains available for
normal macOS character input. This follows Ghostty's
[Option-key setting](https://ghostty.org/docs/config/reference#macos-option-as-alt).

Ghostty reads the managed `~/.config/ghostty/config`. If an old
`~/Library/Application Support/com.mitchellh.ghostty/config` or `config.ghostty`
exists, inspect it before removing or backing it up: macOS-specific files load
later and can override the managed settings. A pre-existing XDG `config.ghostty`
can also affect the result. See [Ghostty's configuration loading order](https://ghostty.org/docs/config).

Zellij starts manually with `zellij`; opening a shell does not auto-start it.
The first use of zjstatus can request permission to display session information
and run the existing `whoami` and `uname -n` status commands. Its version is now
fixed in `modules/zellij.nix`, with no runtime download from a `latest` URL.

After activation, verify:

```sh
ghostty +validate-config
zellij setup --check
zellij
```

In the new session, check the status bar, Alt+Y (Yazi), Alt+G (Lazygit), copying
text to another application, and scrollback editing with Helix. On macOS use
left Option for those Alt shortcuts. Ghostty's bundled font includes Nerd Font
symbols; verify the status-bar glyphs on the Mac.

## Linux activation and recovery

After reviewing the generated configuration and backing up existing dotfiles:

```sh
just update
```

This is an explicit activation; `just build` alone never activates. The backup
suffix preserves conflicting files but is not a backup of their symlink targets.
Keep the old dotfiles repository and a known-good Home Manager generation.

To recover, run the `activate` script of the previous generation shown by
`home-manager generations`. Files that Home Manager did not previously manage
may require restoring the saved originals or symlinks manually. Keep an existing
terminal open while verifying the new shell.

## Verification completed on Linux

- Linux Home Manager generation builds; both Apple Silicon Home Manager and
  nix-darwin system targets evaluate.
- GitHub CLI, kubectl, Helm, K9s, Google Cloud CLI, and the GKE authentication
  plugin pass offline executable checks. `rg`, `bat`, and Zoxide run successfully.
- OpenSSH resolves the same hostname, user, and identity files for all three
  migrated hosts; K9s preferences match apart from the portable screen-dump path.
- Ghostty validates the generated config, and the existing two settings are preserved.
- Zellij validates the generated config and starts with the migrated default
  layout in an isolated terminal. The pinned status plugin reaches its permission
  prompt, and Ctrl+Q exits the session cleanly.
- Generated Zsh startup syntax passes validation.

The macOS build, GUI rendering, clipboard integration, and keyboard behavior on
actual hardware still need verification. No configuration has been activated.

## Next migration batches

1. Build on the Mac and test the shell and editor.
2. Test Ghostty, Zellij, clipboard integration, and keyboard shortcuts on the Mac.
3. Discuss project environments separately before adding project tooling.
4. Extend the existing nix-darwin app list or macOS settings only as needed.

The older `migration.md` is an Arch package-cleanup runbook, not a prerequisite
for setting up the Mac. Do not remove Linux packages as part of these initial migration batches.
