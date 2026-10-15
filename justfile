# path: includes new module files before they have been added to Git.
build target="afredojala":
    nix build --no-link 'path:.#homeConfigurations.{{target}}.activationPackage'

# Activation is explicit and backs up conflicting files with a unique suffix.
update target="afredojala":
    home-manager switch -b "hm-backup-$(date +%Y%m%d-%H%M%S)" --flake 'path:.#{{target}}'

# macOS only: build the system layer (Homebrew, Chrome, and 1Password).
mac-system-build:
    nix build --out-link result-system 'path:.#darwinConfigurations.macbook.system'

# macOS only: explicitly activate the system layer with administrator privileges.
mac-system-update: mac-system-build
    sudo ./result-system/sw/bin/darwin-rebuild switch --flake 'path:.#macbook'
