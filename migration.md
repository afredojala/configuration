# Arch Linux to Home Manager migration runbook

Last reviewed: 2026-09-12

This document is the migration plan for `~/my-home-manager`. It assumes Arch Linux remains the host operating system and standalone Home Manager manages the user environment.

Home Manager is **not** a replacement for Arch. Pacman must continue to manage the kernel, drivers, boot process, system services, desktop plumbing, and any package needed by another Arch package.

## Current baseline

- Home Manager configuration: `.#afredojala`
- Home directory: `/home/afredojala`
- Architecture: `x86_64-linux`
- Current `home.stateVersion`: `23.11`
- Current flake inputs: Nixpkgs/Home Manager `23.11`
- `pacman.txt`: 722 explicitly installed packages
  - 671 repository packages
  - 51 foreign/AUR packages
- Pacman currently reports 117 dependency orphans; these need review, not automatic removal.

The package list contains many libraries that should not be copied into `home.packages`, including KDE Frameworks, Qt libraries, Python libraries, Electron runtimes, GStreamer libraries, and `lib32-*` packages. Nix applications bring their own dependencies automatically.

---

## Safety rules

Follow these rules throughout the migration:

1. Change only one small package group at a time.
2. Commit the Home Manager configuration before every activation.
3. Add and test the Nix package before removing the Arch package.
4. Keep both copies temporarily while testing.
5. Never assume a Nix package satisfies an Arch dependency. Pacman cannot see Nix packages.
6. Before removing an Arch package, inspect `Required By` and its reverse dependency tree.
7. Review every Pacman removal transaction before confirming it.
8. Do not bulk-remove the current orphan list.
9. Keep at least one known-good Home Manager generation.
10. Never put passwords, tokens, SSH keys, or other secrets directly into the Nix repository.
11. Do not change `home.stateVersion` during a normal Home Manager upgrade.

### Package states used in this document

- **Arch-owned:** Pacman remains responsible for the package.
- **Dual-installed:** Both Pacman and Home Manager provide it temporarily.
- **HM-owned:** Home Manager provides the user-facing package.
- **Arch dependency:** Home Manager provides the user-facing command, but the Pacman copy remains because Arch packages require it.
- **Deferred:** Decide later after the core migration is stable.

---

# Phase 0: preserve the current state

## 0.1 Commit the starting configuration

From the repository:

```bash
cd ~/my-home-manager
git status --short
git add flake.nix flake.lock home.nix justfile pacman.txt migration.md
git commit -m "document Home Manager migration baseline"
```

Do not use `git add .` if the repository may contain generated files or secrets.

## 0.2 Refresh and preserve package inventories

Before each major migration wave, refresh the explicit package list:

```bash
cd ~/my-home-manager
pacman -Qqe | sort > pacman.txt
```

Useful read-only inventories:

```bash
pacman -Qqen | sort                 # Explicit official packages
pacman -Qqem | sort                 # Explicit foreign/AUR packages
pacman -Qdtq | sort                 # Potential dependency orphans
flatpak list --app                  # Flatpak applications
home-manager generations           # Home Manager rollback points
```

Store a dated copy of the complete package database outside the repository if desired:

```bash
mkdir -p ~/migration-backups
pacman -Q > ~/migration-backups/pacman-all-$(date +%F).txt
pacman -Qqe > ~/migration-backups/pacman-explicit-$(date +%F).txt
pacman -Qqem > ~/migration-backups/pacman-foreign-$(date +%F).txt
pacman -Qdtq > ~/migration-backups/pacman-orphans-$(date +%F).txt
```

## 0.3 Back up unmanaged configuration

Ensure files such as these are backed up before Home Manager starts managing them:

- `~/.bashrc`, `~/.zshrc`, and shell profile files
- `~/.gitconfig`
- Relevant directories under `~/.config`
- Editor configuration
- Hyprland, Waybar, terminal, and notification-daemon configuration

Do not commit secrets from `~/.ssh`, `~/.gnupg`, password stores, browser profiles, or application credentials.

## Completion gate

- [ ] The repository has a clean baseline commit.
- [ ] `pacman.txt` reflects the current explicit package set.
- [ ] Important dotfiles are backed up.
- [ ] `home-manager generations` shows at least one known-good generation.

---

# Phase 1: modernize Home Manager before migrating packages

The repository currently tracks unsupported `23.11` package inputs. Upgrade the inputs before adding real packages.

As of this document's review date, use matching `26.05` branches:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

If following this document after a newer stable release exists, update both inputs to the **same** release. Do not mix a stable Home Manager release with an unrelated Nixpkgs branch.

Keep this unchanged in `home.nix`:

```nix
home.stateVersion = "23.11";
```

`home.stateVersion` controls compatibility defaults. It is not the installed Home Manager version.

## 1.1 Update and validate

After editing `flake.nix`:

```bash
cd ~/my-home-manager
nix flake update
nix flake check
nix build --no-link .#homeConfigurations.afredojala.activationPackage
home-manager -n --flake .#afredojala switch
```

Review the dry-run output. Then activate:

```bash
home-manager --flake .#afredojala switch
home-manager news
```

If activation reports conflicting files, first inspect the conflict. For files that Home Manager should take over, use a unique backup suffix:

```bash
BACKUP_EXT="hm-backup-$(date +%Y%m%d-%H%M%S)"
home-manager -b "$BACKUP_EXT" --flake .#afredojala switch
```

Home Manager will rename conflicting files by appending that suffix. Compare the backups with the generated files before deleting anything.

## 1.2 Commit the successful upgrade

```bash
git add flake.nix flake.lock home.nix
git commit -m "upgrade Home Manager inputs"
```

## Rollback procedure

The preferred rollback is to restore the previous Git commit and activate it:

```bash
git log --oneline -5
git checkout <known-good-commit> -- flake.nix flake.lock home.nix
home-manager --flake .#afredojala switch
```

Alternatively, list generations and run the activation script from a known-good generation:

```bash
home-manager generations
/nix/store/<known-good-home-manager-generation>/activate
```

## Completion gate

- [ ] Nixpkgs and Home Manager use matching supported branches.
- [ ] `home.stateVersion` is still `23.11`.
- [ ] The activation package builds successfully.
- [ ] Home Manager activates without breaking the current shell.
- [ ] The successful state is committed.

---

# Phase 2: migrate the first low-risk CLI wave

These packages are portable and have little system integration:

```text
age
bat
btop
duf
eza
fastfetch
fd
glow
jq
just
lazygit
ncdu
ripgrep
sops
tldr
tree
yazi
zellij
zoxide
```

## 2.1 Install them through Home Manager

Replace the demonstration packages `hello`, `cowsay`, and `lolcat` in `home.nix` with:

```nix
home.packages = with pkgs; [
  age
  bat
  btop
  duf
  eza
  fastfetch
  fd
  glow
  jq
  just
  lazygit
  ncdu
  ripgrep
  sops
  tldr
  tree
  yazi
  zellij
  zoxide
];
```

Build and activate:

```bash
cd ~/my-home-manager
nix flake check
nix build --no-link .#homeConfigurations.afredojala.activationPackage
home-manager -n --flake .#afredojala switch
home-manager --flake .#afredojala switch
```

Commit the dual-installed state before touching Pacman:

```bash
git add home.nix flake.lock
git commit -m "migrate first CLI package wave to Home Manager"
```

## 2.2 Verify the Nix commands

Run basic smoke tests:

```bash
for cmd in age bat btop duf eza fastfetch fd glow jq just lazygit ncdu rg sops tldr tree yazi zellij zoxide; do
  printf '%-12s %s\n' "$cmd" "$(command -v "$cmd")"
done
```

For several commands, resolve the symlink and confirm it ends in `/nix/store`:

```bash
readlink -f "$(command -v bat)"
readlink -f "$(command -v rg)"
readlink -f "$(command -v yazi)"
```

Use the Nix versions normally for several days before removing anything from Arch.

## 2.3 Decide the Pacman action for each package

For every package, inspect it first:

```bash
pkg=bat
pacman -Qi "$pkg" | grep -E '^(Name|Install Reason|Required By)'
pactree -r "$pkg"
```

### If `Required By` is `None`

Remove one package at a time and review Pacman's proposed transaction:

```bash
sudo pacman -Rns bat
```

Cancel if Pacman proposes removing unrelated or important packages. Repeat only after the Nix command has been tested.

At the time this document was created, these first-wave packages had no installed reverse dependencies and were candidates for individual removal:

```text
age
bat
btop
duf
eza
fastfetch
glow
just
lazygit
ncdu
sops
tldr
tree
yazi
zellij
zoxide
```

Always check again because the dependency graph can change.

### If another Arch package requires it

Do not remove it. Change its Pacman install reason from explicit to dependency:

```bash
sudo pacman -D --asdeps <package>
```

At the time this document was created:

- `fd` was required by `hwdetect` and `pop-launcher`.
- `jq` was required by `grimblast-git`.
- `ripgrep` was required by `cursor-bin`, `hwdetect`, `opencode`, and `ripgrep-all`.

These should remain installed by Pacman as Arch dependencies even if the interactive shell normally finds the Home Manager versions first:

```bash
sudo pacman -D --asdeps fd jq ripgrep
```

## 2.4 Refresh the inventory

```bash
hash -r
pacman -Qqe | sort > pacman.txt
git add pacman.txt
git commit -m "record Pacman state after first CLI migration"
```

## Completion gate

- [ ] All first-wave commands resolve to Home Manager/Nix versions.
- [ ] They have been used successfully for several days.
- [ ] Pacman copies with no dependents were removed individually.
- [ ] Pacman copies needed by Arch were retained as dependencies.
- [ ] `pacman.txt` and the Home Manager configuration were committed.

---

# Phase 3: migrate shell, Git, terminal, and editor configuration

Do this one program at a time. Prefer a Home Manager `programs.<name>` module over a raw `home.packages` entry when a module exists. A program module normally installs the package, so do not also list the same package in `home.packages` unless the module documentation requires it.

## Recommended order

1. Git
2. `direnv`
3. `zoxide`
4. Shell prompt
5. Zsh configuration
6. Terminal configuration
7. Neovim or Helix
8. Yazi and Zellij configuration

## Program decisions

| Area | Current choices | Migration decision |
|---|---|---|
| Prompt | `starship`, `oh-my-posh-bin` | Choose one; Starship is the simpler default. |
| Shell | Bash and Zsh | Home Manager may configure Zsh, but retain Arch's login shell package. |
| Terminal | Alacritty, Ghostty, Konsole, WezTerm, XTerm | Pick one primary terminal before migrating configuration. |
| Editor | Cursor, Zed, Neovim, Helix, Vim, Nano, Kate, Mousepad | Pick primary graphical and terminal editors; retain emergency system editors as desired. |
| System fetch | `neofetch`, `fastfetch` | Keep Fastfetch and remove deprecated `neofetch`. |

## Important login-shell rule

Do not remove Arch's `bash` or `zsh` packages. `/etc/passwd` should refer to a stable distro path such as `/bin/zsh`, not a versioned Nix store path. Home Manager can still manage `~/.zshrc`, plugins, aliases, environment variables, and completions.

If changing the default shell, use the Arch-installed path:

```bash
command -v zsh
chsh -s /bin/zsh
```

Log out and back in after changing the login shell.

## Suggested Home Manager modules

Enable only the modules you are ready to configure:

```nix
programs.git.enable = true;

programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};

programs.zoxide.enable = true;
programs.starship.enable = true;
programs.zsh.enable = true;
```

Later candidates include:

```text
programs.alacritty
programs.bat
programs.btop
programs.eza
programs.fastfetch
programs.ghostty
programs.helix
programs.neovim
programs.wezterm
programs.yazi
programs.zellij
```

Confirm exact options against the Home Manager release in use before copying existing settings.

## Dotfile takeover procedure

For each program:

1. Identify the current file under `$HOME` or `~/.config`.
2. Back it up outside the repository.
3. Reproduce only the settings still wanted in the Home Manager module.
4. Build and dry-run the activation.
5. Activate with a unique `-b` backup suffix if there is a conflict.
6. Compare the old backup and generated configuration.
7. Run the program and verify plugins, themes, environment variables, and keybindings.
8. Commit before moving to the next program.

Do not migrate generated caches, application state, browser profiles, sockets, lock files, or secrets.

## Pacman cleanup for this phase

- Keep Arch `bash` and `zsh`.
- Remove `neofetch` after Fastfetch is verified.
- Remove either `starship` or `oh-my-posh-bin` after choosing one.
- Remove unused terminals and editors only after confirming they are genuinely unused.
- Use the reverse-dependency procedure from Phase 2 for every package.

## Completion gate

- [ ] Git configuration is declarative.
- [ ] Shell aliases, environment variables, prompt, and completion are declarative.
- [ ] The login shell still works from a fresh login and a TTY.
- [ ] At least one terminal and editor configuration is declarative.
- [ ] Existing dotfiles were backed up and reviewed.

---

# Phase 4: migrate development tools

Install only tools used regularly. Tools needed for one project are usually better placed in that project's Nix development shell rather than global `home.packages`.

## Arch-to-Nix package mapping

| Arch package | Nixpkgs attribute | Notes |
|---|---|---|
| `azure-cli-bin` | `azure-cli` | Large package; migrate separately. |
| `bazelisk` | `bazelisk` | |
| `deno` | `deno` | May alternatively be managed by Mise. |
| `fluxcd` | `fluxcd` | |
| `github-cli` | `gh` | Command remains `gh`. |
| `golangci-lint` | `golangci-lint` | |
| `golangci-lint-langserver-bin` | `golangci-lint-langserver` | |
| `gopls` | `gopls` | Prefer a project dev shell for pinned Go tooling. |
| `graphviz` | `graphviz` | |
| `helm` | `kubernetes-helm` | `pkgs.helm` is a different program. |
| `kubectl` | `kubectl` | |
| `mage` | `mage` | |
| `mise` | `mise` | Recommended general runtime manager. |
| `mkcert` | `mkcert` | Its local CA setup remains machine-specific. |
| `opencode` | `opencode` | |
| `pre-commit` | `pre-commit` | Project environments are preferable when pinned. |
| `pyright` | `pyright` | |
| `ruff` | `ruff` | |
| `typescript-language-server` | `typescript-language-server` | |
| `uv` | `uv` | Recommended for Python projects and tools. |
| `zig` | `zig` | Pin per project when version-sensitive. |

Add these in groups of three to five, not all at once. A reasonable order is:

1. `gh`, `kubectl`, `kubernetes-helm`, `fluxcd`
2. `golangci-lint`, `golangci-lint-langserver`, `gopls`, `mage`
3. `pyright`, `ruff`, `typescript-language-server`
4. `mise`, `uv`, `deno`, `zig`
5. `azure-cli`, `bazelisk`, `graphviz`, `mkcert`, `opencode`, `pre-commit`

For each group:

```bash
nix build --no-link .#homeConfigurations.afredojala.activationPackage
home-manager -n --flake .#afredojala switch
home-manager --flake .#afredojala switch
```

Verify versions and basic commands, commit, use them for several days, and then apply the Pacman removal procedure.

## Runtime-manager consolidation

The system currently has overlapping runtime-management approaches:

- `nvm`
- `pyenv`
- `mise`
- `uv`
- Global Pacman Python packages

Recommended target:

- Mise for user-selected language runtimes.
- `uv` for Python projects and Python command-line tools.
- Nix development shells for projects requiring fully pinned toolchains and native libraries.
- Retire NVM and Pyenv only after their installed versions and projects have been migrated.

Inventory existing runtimes first:

```bash
nvm ls
pyenv versions
mise ls
uv tool list
pipx list
```

Do not bulk-migrate or bulk-remove `python-*` packages. Arch itself and installed applications may require them. Do not remove the system `python` package merely because Home Manager provides a Python runtime.

## Completion gate

- [ ] Daily development CLIs are Home Manager-owned or project-owned.
- [ ] Project-specific dependencies are not unnecessarily global.
- [ ] Existing NVM/Pyenv runtimes were inventoried before cleanup.
- [ ] System Python and required Arch libraries remain Pacman-owned.

---

# Phase 5: migrate user-session and Hyprland tools

Keep the desktop session and system integration under Arch initially.

## Keep under Pacman

```text
hyprland
plasma-desktop
plasma-workspace
cosmic-session
xorg-server
xdg-desktop-portal-gtk
xdg-desktop-portal-hyprland
xdg-desktop-portal-kde
polkit-gnome
polkit-kde-agent
pipewire-alsa
pipewire-pulse
wireplumber
gnome-keyring
kwallet-pam
gvfs
networkmanager
```

Home Manager may configure Hyprland while the Arch package provides the compositor.

## User-session migration queue

Move these in small related groups:

### Screenshots and clipboard

```text
cliphist
grim
slurp
swappy
```

### Notifications and launchers

```text
dunst
rofi
wlogout
```

### Hyprland helpers

```text
hypridle
hyprlock
hyprpaper
hyprshade
grimblast-git
waypaper
```

### Bars, widgets, and appearance

```text
waybar
eww
nwg-dock-hyprland
nwg-look
```

### X11 utilities, only if still needed

```text
autorandr
polybar
xclip
xsel
xsettingsd
```

Package names may differ in Nixpkgs. Verify each attribute before adding it. Avoid migrating an entire group until one tool from that group has been tested through a full logout/login cycle.

## ML4W and AGS warning

`ml4w-hyprland` and `aylurs-gtk-shell` are opinionated systems that may own many of the same configuration files as Home Manager. Before migrating either:

1. Decide whether to keep the framework or replace it with your own configuration.
2. Inventory every file it creates or modifies.
3. Do not let two systems manage the same file.
4. Migrate one component at a time.

## Desktop recovery

Before changing the session configuration, note a known-good Home Manager generation. If the graphical session fails:

1. Switch to a TTY with `Ctrl+Alt+F3`.
2. Log in.
3. Run the activation script for a known-good generation, or restore the previous Git commit and run Home Manager again.

```bash
home-manager generations
/nix/store/<known-good-home-manager-generation>/activate
```

## Completion gate

- [ ] Arch still owns the compositor, portals, authentication agents, and audio stack.
- [ ] Home Manager owns only tested user-session tools and configuration.
- [ ] A full logout/login succeeds.
- [ ] Screenshot, clipboard, lock screen, notifications, and portals work.
- [ ] TTY recovery has been tested or documented.

---

# Phase 6: decide GUI application ownership

Migrating GUI applications is optional. Pacman or Flatpak may integrate better on Arch, especially for GPU-heavy, proprietary, sandboxed, or system-integrated applications.

## Reasonable Home Manager candidates

Test one application at a time:

```text
alacritty
ghostty
wezterm
firefox
libreoffice-fresh
obsidian
signal-desktop
element-desktop
qbittorrent
localsend-bin
zed
```

Nix package names may omit Arch suffixes such as `-bin`.

## Defer or keep under Arch/Flatpak initially

```text
1password
balena-etcher
beeper-v4-bin
bottles
cursor-bin
faugus-launcher
google-chrome
mullvad-vpn-bin
slack-desktop
steam
lutris
wine-staging
ollama
tuxedo-control-center-bin
```

Reasons include browser integration, privileged daemons, VPN services, GPU access, gaming libraries, desktop portals, keyrings, and vendor-specific hardware support.

## Unfree packages

If a selected Nix package is unfree, explicitly allow unfree packages in the imported package set in `flake.nix`:

```nix
pkgs = import nixpkgs {
  inherit system;
  config.allowUnfree = true;
};
```

Do this only when the first unfree Nix package is actually needed.

## Non-NixOS GUI and GPU warning

On Arch, Nix GUI applications may need additional generic-Linux or GPU integration. Do not change GPU integration during the CLI phases.

Home Manager `26.05` provides `targets.genericLinux`. To enable generic-Linux XDG integration without changing GPU integration initially:

```nix
targets.genericLinux = {
  enable = true;
  gpu.enable = false;
};
```

Because this machine uses NVIDIA packages, configure Home Manager's GPU integration separately and ensure any configured NVIDIA userspace version exactly matches the Arch driver. Until then, leave GPU-heavy applications under Arch or Flatpak if Nix versions fail.

Test each migrated GUI application for:

- OpenGL/Vulkan rendering
- File pickers and XDG portals
- Audio and screen sharing
- Browser and keyring integration
- Desktop entries and icons after logout/login
- Opening files from the file manager

Only remove the Pacman/Flatpak version after all required integration works.

## Completion gate

- [ ] Every migrated GUI application launches from both a shell and desktop entry.
- [ ] GPU, audio, portals, and keyring behavior work where required.
- [ ] Unfree packages are enabled only if needed.
- [ ] System-integrated applications remain under Arch/Flatpak when that is more reliable.

---

# Phase 7: reduce and migrate fonts and themes

The current inventory includes a very large Nerd Font collection. Do not reproduce every font automatically.

## Recommended approach

1. Keep core desktop fonts under Arch initially:
   - Noto families
   - Cantarell
   - Liberation fonts
   - Any fonts used by the display manager or system desktop
2. Identify fonts actually selected in the terminal, editor, browser, and desktop.
3. Choose one to three development fonts.
4. Install only those through Home Manager.
5. Enable user font discovery:

```nix
fonts.fontconfig.enable = true;
```

For modern Nixpkgs, a selected Nerd Font can be installed with an attribute such as:

```nix
home.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
];
```

Verify the exact attribute in the pinned Nixpkgs release.

Do not remove an Arch font if Plasma, SDDM, another user, or a system application depends on it. Log out and back in after changing font packages, then verify terminal glyphs, Waybar icons, and browser rendering.

---

# Phase 8: clean up Arch and Home Manager

Do this only after all active migration waves are stable.

## 8.1 Resolve overlapping applications

Review these groups and keep only intentional choices:

- AUR helpers: `paru`, `yay`, `trizen`
- Prompts: Starship, Oh My Posh
- Terminals: Alacritty, Ghostty, Konsole, WezTerm, XTerm
- File managers: Dolphin, Nautilus, Thunar
- Editors: Cursor, Zed, Neovim, Helix, Vim, Nano, Kate, Mousepad
- Desktop sessions: Plasma, Hyprland, COSMIC
- Virtualization: VirtualBox, QEMU/libvirt
- Containers: Docker, Podman, Buildah
- Fetch tools: Neofetch, Fastfetch
- Duplicate Nerd Fonts

Do not remove a desktop session until a known-good alternative can log in successfully.

## 8.2 Review Pacman orphans safely

List potential orphans:

```bash
pacman -Qdtq
```

For each candidate:

```bash
pkg=<candidate>
pacman -Qi "$pkg"
pactree -r "$pkg"
```

Remove it only when its purpose is understood:

```bash
sudo pacman -Rns "$pkg"
```

Do **not** run this blindly:

```bash
# Unsafe without reviewing every package:
# sudo pacman -Rns $(pacman -Qdtq)
```

The original orphan list contains compilers, Electron versions, Qt libraries, debug packages, multimedia libraries, and AGS/Hyprland components. Some may still be intentionally used even though Pacman classifies them as orphans.

## 8.3 Packages that should not be copied directly to Home Manager

Leave these as Pacman-managed dependencies, or allow Pacman to remove them when no longer required:

- `python-*`
- `lib32-*`
- Most standalone `lib*` packages
- `electron*-bin`
- `qt6-*`
- `gst-*`
- KDE Framework libraries such as `attica`, `karchive`, `kcodecs`, and `kcoreaddons`
- GTK/C++ libraries such as `cairomm-*`, `glibmm-*`, and `gtkmm-*`

Only install development libraries through a project-specific Nix development shell when a project explicitly needs them.

## 8.4 Refresh and commit the final inventory

```bash
cd ~/my-home-manager
pacman -Qqe | sort > pacman.txt
nix flake check
nix build --no-link .#homeConfigurations.afredojala.activationPackage
git add flake.nix flake.lock home.nix pacman.txt migration.md
git commit -m "record completed Home Manager migration wave"
```

## 8.5 Clean old Home Manager generations conservatively

First inspect generations:

```bash
home-manager generations
```

After the configuration has been stable, remove only generations that are no longer needed:

```bash
home-manager remove-generations <id>
```

Run ordinary Nix garbage collection only after unwanted generations are removed:

```bash
nix-collect-garbage
```

Avoid `nix-collect-garbage -d` during the migration because it removes old profile generations and can eliminate rollback options.

---

# Phase 9: optional future migration to NixOS

This phase is optional and is separate from Home Manager.

When the user environment is stable under Home Manager, decide whether Arch should remain the host. If moving to NixOS:

1. Keep the Home Manager modules portable and avoid Arch-specific paths where practical.
2. Inventory boot, filesystems, encryption, NVIDIA configuration, networking, audio, Bluetooth, printing, virtualization, containers, and system services.
3. Build a NixOS configuration in a VM or on a spare partition first.
4. Integrate the existing Home Manager configuration into the NixOS flake.
5. Confirm hardware, networking, graphics, and recovery boot before replacing Arch.
6. Do not remove Arch system packages as part of this process; they disappear when Arch itself is replaced.

Packages from the “keep under Pacman” categories would move into the NixOS system configuration, not into `home.packages`.

---

# Repeatable workflow for every package wave

Use this checklist for all future packages:

1. **Classify**
   - Is it a user application, a system component, or merely a dependency?
   - Does it need root privileges, a daemon, kernel integration, PAM, a portal, or a driver?
2. **Find the Nix representation**
   - Prefer a Home Manager module.
   - Otherwise find the correct Nixpkgs attribute.
   - Do not assume the Arch and Nix names match.
3. **Add**
   - Add only a small related group.
4. **Build**

   ```bash
   nix flake check
   nix build --no-link .#homeConfigurations.afredojala.activationPackage
   home-manager -n --flake .#afredojala switch
   ```

5. **Activate**

   ```bash
   home-manager --flake .#afredojala switch
   ```

6. **Verify**
   - Confirm executable paths resolve into `/nix/store`.
   - Run version and smoke tests.
   - For desktop software, log out and back in.
7. **Commit**
   - Commit the working dual-installed state.
8. **Use normally**
   - Wait several days before removing the old package.
9. **Inspect Pacman dependencies**

   ```bash
   pacman -Qi <package> | grep -E '^(Name|Install Reason|Required By)'
   pactree -r <package>
   ```

10. **Remove or reclassify**
    - No reverse dependencies: remove individually with `sudo pacman -Rns <package>`.
    - Required by Arch: keep it and use `sudo pacman -D --asdeps <package>`.
11. **Refresh inventory**

    ```bash
    pacman -Qqe | sort > pacman.txt
    ```

12. **Commit again**
    - Record the Pacman cleanup separately from the Home Manager installation.

---

# Migration log

Update this table after each wave.

| Wave | Status | Home Manager generation | Git commit | Notes |
|---|---|---:|---|---|
| Baseline and backups | Not started | | | |
| Upgrade inputs | Not started | | | Keep `home.stateVersion = "23.11"`. |
| First CLI wave | Not started | | | |
| Shell and Git | Not started | | | |
| Terminal and editors | Not started | | | |
| Development tools | Not started | | | |
| Hyprland user tools | Not started | | | |
| GUI applications | Not started | | | Optional. |
| Fonts and themes | Not started | | | |
| Pacman cleanup | Not started | | | Never bulk-remove orphans. |
| Optional NixOS migration | Deferred | | | Separate project. |

## Definition of done

The Arch-to-Home-Manager migration is complete when:

- Arch owns the operating system, hardware integration, system services, and required dependencies.
- Home Manager owns the desired shell, dotfiles, editor configuration, portable CLI tools, and selected user applications.
- No file is unintentionally managed by two configuration systems.
- Duplicate packages are either removed or intentionally retained as Arch dependencies.
- `pacman.txt`, `flake.lock`, and the Home Manager configuration are current and committed.
- A documented, tested rollback path exists.
