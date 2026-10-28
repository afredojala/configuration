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
| Terminal | Ghostty, Zellij, pinned zjstatus, Yazi, Lazygit, herdr (agent multiplexer) |
| Access | Git and Jujutsu (`jj`) identity, GitHub CLI and HTTPS credential helper, SSH host entries and 1Password SSH agent |
| Cloud | kubectl, Helm, k3d, K9s settings/aliases, Google Cloud CLI and GKE auth plugin |
| Utilities | See `home.packages` in `home.nix`, including `rg`, `bat`, and `rsync` |
| Dev runtimes | Node.js (with npm), uv and rustup (Rust toolchains), so project tests can run; direnv with nix-direnv for per-project `.envrc` |
| Mac apps | 1Password, Notion Calendar, OrbStack (Docker runtime for k3d), Steam, Qobuz and Obsidian through nix-darwin/Homebrew; Amphetamine from the Mac App Store; Safari provided by macOS |
| Launcher (Mac) | Raycast cask through nix-darwin; login agent, Spotlight shortcut and "Log to Daily Note" script command through Home Manager |
| Window manager (Mac) | OmniWM through Home Manager, Caps shortcuts, app routing, Quake terminal |

`modules/` contains shared configuration, `hosts/` contains host-specific settings,
and `dotfiles/` contains editor and terminal configuration. `flake.lock` pins Nix
inputs. Homebrew cask versions follow available releases rather than this lock file.
Project environments remain outside the current scope.

OmniWM and herdr use a separate locked nixpkgs unstable input because they are
unavailable on 26.05. OmniWM's release is temporarily overridden to 0.7.6 to preserve
the installed version. Remove the override when the packaged version catches up. Home Manager
sets F18 as Hyper (Control+Option+Command) and migrates Option-prefixed
keyboard shortcuts to Hyper. Shift remains available for moving windows.
nix-darwin maps physical Caps Lock to F18, so a short tap no longer toggles
capital letters. Apply both the system and Home Manager configurations for this
setup; OmniWM must use F18 rather than its special Caps Lock trigger.
SketchyBar replaces OmniWM's built-in workspace bar. It shows clickable workspaces
1–9 on the left, with the focused workspace highlighted and empty workspaces dimmed.
The bar follows [wthrajat/dotfiles-mac](https://github.com/wthrajat/dotfiles-mac):
a transparent canvas with separate frosted Catppuccin Macchiato pills, a warm
yellow active-workspace chip and sky-blue status icons. The Apple logo and
workspace numbers share one pill. The right side shows memory (percent and GB in
use), CPU load, Wi-Fi and Bluetooth (sharing one pill), date, clock and battery.
Labels use SF Mono, which Home Manager copies from Terminal.app into
`~/Library/Fonts/SF Mono`; icons use Symbols Nerd Font Mono. The Wi-Fi icon is
bright when connected, dim when idle and crossed out when off. Bluetooth shows
the number of connected devices when there are any. Clicking either opens its
macOS settings. Battery uses a charge-level icon, a bolt on AC, and red below 20%.
Home Manager installs SketchyBar and starts it and an OmniWM IPC bridge through
launchd. Workspace events refresh the bar immediately; a 30-second refresh also
recovers after a bar reload. Clock and battery refresh every 10 and 60 seconds.
The former bar-on-switch agent is disabled.

A pill to the right of the workspaces shows the next meeting within 24 hours that has
a Google Meet, Zoom or Teams link, such as `om 12 min · Standup`, and clicking it
opens the link. It reads every account in macOS Calendar, so add your Google
account under System Settings → Internet Accounts. A meeting stays visible for
10 minutes after it starts. All-day and declined events are skipped, and the pill
hides when nothing is coming up. A small EventKit agent (`dotfiles/sketchybar/meeting.m`)
updates it every 30 seconds and when the calendar changes. Approve its Calendar
access prompt after the first activation. Until you do, the pill links to the
privacy settings. A rebuilt agent may ask for access again.

macOS's menu bar is set to auto-hide; moving to the top edge can still reveal it.
Both the legacy global preference and macOS 26's Control Center preference are
managed. SketchyBar uses the window level to remain visible over app windows.
Configuration lives in `modules/sketchybar.nix` and `dotfiles/sketchybar/bridge.py`.
Errors go to `/tmp/sketchybar.log`, `/tmp/omniwm-sketchybar.log` and
`/tmp/sketchybar-meeting.log`.
To restore the native bar, remove the SketchyBar module import, enable
`settings.workspaceBar.enabled` in OmniWM preferences, and set
`_HIHideMenuBar = false` before applying Home Manager.

A muted blue 1-point border indicates focus; gaps are zero except a 32-point top
margin that keeps windows below SketchyBar. OmniWM subtracts the menu bar inset, so
the notched MacBook gets no extra margin and external displays get the full 32 points.
OmniWM may reserve minimal clearance for the border. All workspaces use Dwindle to
divide the available screen between tiled windows. A single window, like Caps + F
fullscreen, fills the screen but keeps the top margin so it stays below SketchyBar.
Dwindle is also the default layout for new workspaces.
Managed workspace layouts are set in `[workspaceLayouts]` in preferences.toml.
Niri shows one full-width column at a time;
Caps + arrows moves focus along the scrolling layout, and Caps + F toggles
layout fullscreen for the focused window.
The activation preserves other settings, keeps the file writable in OmniWM, and
backs up changes as `settings.toml.before-preferences-<hash>`. Open OmniWM once before
the first activation so its complete settings file exists. Login behavior is
not managed by Home Manager yet.

Raycast is installed as a Homebrew cask by the system layer. Home Manager
starts it at login through launchd and disables Spotlight's Command+Space
shortcut without touching other symbolic hotkeys. Raycast 2.x keeps its own
hotkey, extensions and settings in an encrypted database, so set Command+Space
once in Raycast Settings → General → Raycast Hotkey, and use Export Settings &
Data to back the rest up. Configuration lives in `modules/raycast.nix`.

The Raycast command "Log to Daily Note" adds `- HH:MM - text` to the end of
the `## Logg` section of today's note in the `~/Documents/Foffe` Obsidian vault,
and creates the note from `Templates/Daily.md` if needed. Home Manager installs
it in `~/.config/raycast/scripts`. Add that folder once in Raycast Settings →
Extensions → Script Commands, then record a hotkey for the command. The helper
lives in `modules/obsidian.nix` and `dotfiles/obsidian/daily-log.py`.

To migrate an existing Homebrew installation, build with `just build macbook`,
quit OmniWM, then run `brew uninstall --cask omniwm` (without `--zap`) and
`just update macbook`. Launch `~/Applications/Home Manager Apps/OmniWM.app` and
verify Accessibility permission and any existing login item point to the new app.
Apply `just mac-system-update` to remove OmniWM from the system's cask declaration.
Homebrew cleanup on system activation uninstalls casks that are no longer declared.

## OmniWM shortcuts and workspaces

Caps Lock is the window-management modifier; Command retains normal Mac app
shortcuts (for example Command+C/V and Command+Q). Caps+Q closes only the focused
window. Quitting an app with Command+Q quits the app and all its windows.

| Shortcut | Action |
| --- | --- |
| Caps + arrows | Focus another window |
| Caps + Shift + arrows | Move the focused window |
| Caps + M | Focus the next physical monitor |
| Caps + Shift + M | Move the whole current workspace to the monitor on the left |
| Caps + Shift + N | Move the whole current workspace to the monitor on the right |
| Caps + H / L | Move the focused window to the monitor on the left / right |
| Caps + J / K | Move the focused window to the monitor below / above |
| Caps + 1–9 | Switch workspace |
| Caps + Shift + 1–9 | Move the focused window to that workspace |
| Caps + Tab | Focus the previous window |
| Caps + Shift + Tab | Return to the previous workspace |
| Caps + F | Toggle OmniWM fullscreen/maximize |
| Caps + V | Toggle floating/tiled |
| Caps + Q | Close the focused window |
| Caps + Space | Open the command palette (search windows, apps and commands) |
| Caps + Return | Show/hide the Quake terminal on the current workspace |
| Caps + T | Toggle tabs for the current Niri column |
| Caps + comma / period | Cycle column size backward / forward |
| Caps + Shift + O | Show/hide Overview |
| Caps + Shift + L | Switch the workspace between Niri and Dwindle |

Monitor directions follow the physical display arrangement in macOS System Settings.
For two side-by-side displays, use Caps+M to switch focus and Caps+H/L to move
the focused window left/right between them. These commands move one window.
Use Caps+Shift+M/N to move the entire workspace left/right instead. OmniWM's
workspace monitor actions are directional; they do not wrap at the screen edge.
The mouse cursor follows keyboard focus, so it jumps along when focus changes monitor.

Caps+Return replaces the previous maximize binding; use Caps+F for maximize.
Caps+Return also replaces the old Caps+backtick Quake binding.
The Quake terminal opens from the top at 90% width and 60% height and hides when
focus moves away. It uses the built-in Ghostty engine and your Ghostty settings;
it is separate from the normal Ghostty windows on workspace 2. A previously saved
custom Quake frame can override this geometry; use Reset to Default Position in
OmniWM's Quake settings if needed.

| Workspace | Apps |
| --- | --- |
| 1 | Safari |
| 2 | Ghostty |
| 3 | ChatGPT, Claude |
| 4 | Slack, Shortwave |
| 5 | Notion Calendar |
| 6–9 | Unassigned, available for ad hoc work |

App rules assign the first app window when the app has no tracked windows.
Additional windows can open on the current workspace, and restored windows may
retain their previous placement. Use Caps+Shift+number to move any window manually;
`omniwmctl rule apply --pid <pid>` explicitly reapplies rules to an open app.
The rules retain existing minimum sizes and UUIDs and do not override more
specific dialog/title rules.

The Mac imports `modules/omniwm.nix`; Linux does not. Edit the managed values,
key bindings and app assignments in `dotfiles/omniwm/preferences.toml`, then run
`just build macbook` and `just update macbook`. The small standard-library Python
patcher keeps unrelated app settings editable and rejects duplicate bindings before
writing. The physical Caps-to-F18 mapping remains in `hosts/macbook-system.nix`.

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
the managed Zsh; the account's login shell is unchanged. Both Option keys retain
macOS character input; Command sends Alt for Zellij's h/j/k/l, n, i, o, f, y, g, +
and - shortcuts, replacing Ghostty's own Command bindings for those keys. Zellij
starts manually.
Its status plugin may request permission to read session information and run the
configured `whoami` and `uname -n` commands.

Existing Ghostty files under `~/Library/Application Support/com.mitchellh.ghostty/`
can override the managed configuration; inspect them if settings differ. See
[Ghostty's loading order](https://ghostty.org/docs/config).

The system target leaves Nix under its installer's control, uninstalls undeclared
Homebrew packages (without `--zap`, so app data stays), and does not automatically
upgrade existing Homebrew packages. Add new apps to `hosts/macbook-system.nix`
rather than installing them with `brew install`, or the next activation removes them.
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
