# Workstation configuration

Shared Home Manager configuration for EndeavourOS and an Apple Silicon MacBook.
A separate nix-darwin configuration installs Homebrew and 1Password. Safari is provided by macOS.

| Target | Platform | Home directory |
| --- | --- | --- |
| `afredojala` | `x86_64-linux` | `/home/afredojala` |
| `macbook` | `aarch64-darwin` | `/Users/afredojala` |

## What's included

| Area | Configuration |
| --- | --- |
| Shell | Zsh, Starship, FZF, Zoxide (`z` and `zi`), existing aliases |
| Editor | Helix, Pyrefly, Ruff, Rust Analyzer |
| Terminal | Ghostty, Zellij, pinned zjstatus, Yazi, Lazygit |
| Access | Git identity, GitHub CLI and HTTPS credential helper, SSH host entries and 1Password SSH agent |
| Cloud | kubectl, Helm, K9s settings/aliases, Google Cloud CLI and GKE auth plugin |
| Utilities | See `home.packages` in `home.nix`, including `rg`, `bat`, and `rsync` |
| Mac apps | 1Password through nix-darwin/Homebrew; Safari provided by macOS |

`modules/` contains shared configuration, `hosts/` contains host-specific settings,
and `dotfiles/` contains editor and terminal configuration. `flake.lock` pins Nix
inputs. Homebrew cask versions follow available releases rather than this lock file.
Project environments remain outside the current scope.

## First Mac setup

1. Install Nix with flakes enabled. Verify `nix --version` in a fresh terminal.
2. Clone the repository:

   ```sh
   git clone https://github.com/afredojala/configuration.git
   cd configuration
   ```

3. Verify `id -un` reports `afredojala` and `uname -m` reports `arm64`.
4. Build the user environment:

   ```sh
   nix build --out-link result-mac '.#homeConfigurations.macbook.activationPackage'
   ```

5. Back up existing shell, Git, SSH, GitHub CLI, K9s, Helix, Ghostty, and Zellij
   configuration, including any symlink targets. Then activate:

   ```sh
   ./result-mac/home-path/bin/home-manager switch \
     -b "hm-backup-$(date +%Y%m%d-%H%M%S)" --flake '.#macbook'
   ```

6. Open a new terminal. Install the Mac desktop apps separately:

   ```sh
   just mac-system-build     # Build without activation
   just mac-system-update    # Activate with sudo and install the apps
   ```

Ghostty is available at `~/Applications/Home Manager Apps/Ghostty.app`. It launches
the managed Zsh; the account's login shell is unchanged. Left Option sends Alt for
Zellij shortcuts; right Option retains macOS character input. Zellij starts manually.
Its status plugin may request permission to read session information and run the
configured `whoami` and `uname -n` commands.

Existing Ghostty files under `~/Library/Application Support/com.mitchellh.ghostty/`
can override the managed configuration; inspect them if settings differ. See
[Ghostty's loading order](https://ghostty.org/docs/config).

The system target leaves Nix under its installer's control, preserves undeclared
Homebrew packages, and does not automatically upgrade existing Homebrew packages.
Review any existing-app conflicts before replacing manually installed apps.

## Accounts and credentials

Sign in to 1Password, then authenticate the command-line tools:

```sh
gh auth login --hostname github.com --git-protocol https
gh auth status
gcloud auth login
```

### SSH through 1Password

1. On Linux, import the existing `~/.ssh/id_ed25519` into a private vault using
   **New Item > SSH Key > Add Private Key > Import a Key File** in 1Password.
2. On the Mac, sign in to the same account and confirm the imported SSH Key appears.
3. Enable **Settings > Developer > Use the SSH Agent**. Under General, enable
   keeping 1Password in the menu bar and starting it at login.
4. Apply Home Manager with `just update macbook` and open a fresh terminal.
   The SSH configuration and `SSH_AUTH_SOCK` are managed here; no manual config
   editing or private-key export is needed.
5. Verify the agent and the configured host:

   ```sh
   ssh-add -l
   ssh-keygen -lf ~/.ssh/1password/id_ed25519.pub
   ssh -G hetzner
   ssh hetzner
   ```

The fingerprint listed by the agent should match the public-key fingerprint.
Approve the connection in 1Password when prompted. If the agent cannot be reached,
check that 1Password is running and its SSH agent is enabled.

The repository contains only the Ed25519 public key. `hetzner` uses that key to
select the matching private key from 1Password (`IdentitiesOnly yes`). Other hosts
use the 1Password agent by default. `datadriven` explicitly retains its separate
local `~/.ssh/id_datadriven` key and bypasses the agent until migrated. GitHub HTTPS
access continues to use `gh`; Git signing is not configured.

Linux uses the installed native 1Password app and `~/.1password/agent.sock`; enable
its SSH agent before activating the Linux configuration. On macOS the native
1Password agent socket is selected automatically. Keep existing private-key files
until agent access is verified; this configuration does not delete them.

See [1Password setup](https://developer.1password.com/docs/ssh/get-started/) and
[public-key selection](https://developer.1password.com/docs/ssh/agent/advanced/).
Kubernetes contexts and other application credentials remain outside this repository.

## Updates and recovery

Run from the repository:

| Action | Linux | Mac |
| --- | --- | --- |
| Build user environment | `just build` | `just build macbook` |
| Activate user environment | `just update` | `just update macbook` |
| Build system configuration | — | `just mac-system-build` |
| Activate system configuration | — | `just mac-system-update` |

Build commands do not activate changes. User activation backs up conflicting files
with a timestamped suffix; this does not back up symlink targets. Keep a working
terminal and the original dotfiles until the new environment is verified.

For Home Manager recovery, use `home-manager generations` and run the previous
generation's `activate` script. Restore saved originals manually for files that
were previously unmanaged. Keep the existing state versions when updating inputs.

Flakes use tracked files: run `git add <file>` before building newly created modules
or dotfiles. Generated `result*` links are ignored. On Linux, `~/.zshrc_custom` is
still sourced if present; review it for overrides to the managed prompt or editor.

## Verification

```sh
ghostty +validate-config
zellij setup --check
hx --health
kubectl version --client
helm version --short
k9s version
gcloud version
gke-gcloud-auth-plugin --version
```

Linux builds and offline CLI checks have passed; the Mac Home Manager and
nix-darwin targets have been evaluated. Native Mac builds, GUI rendering,
clipboard behavior, keyboard shortcuts, and authenticated access still need testing.
JSX's language server/formatter must currently come from the project.
