{ lib, pkgs, ... }:
let
  python = pkgs.python3.withPackages (p: [ p.psutil ]);
  bridge = pkgs.writeShellScript "omniwm-sketchybar" ''
    exec ${python}/bin/python3 ${../dotfiles/sketchybar/bridge.py} \
      ${pkgs.sketchybar}/bin/sketchybar "$@"
  '';
  # Python has no EventKit bindings in nixpkgs. The embedded Info.plist lets
  # macOS prompt for Calendar access.
  meeting = pkgs.runCommandCC "sketchybar-meeting" { } ''
    mkdir -p $out/bin
    $CC -fobjc-arc -O2 -framework Foundation -framework EventKit \
      -sectcreate __TEXT __info_plist ${../dotfiles/sketchybar/meeting.plist} \
      ${../dotfiles/sketchybar/meeting.m} -o $out/bin/sketchybar-meeting
  '';
in {
  home.packages = [ pkgs.sketchybar pkgs.nerd-fonts.symbols-only ];
  # SF Mono ships inside Terminal.app but is not registered system-wide.
  home.activation.sfMonoFont = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src=/System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts
    dest="$HOME/Library/Fonts/SF Mono"
    if [ -d "$src" ]; then
      run mkdir -p "$dest"
      for font in "$src"/SF-Mono-*.otf; do
        [ -e "$dest/''${font##*/}" ] || run cp "$font" "$dest/"
      done
    fi
  '';
  xdg.configFile."sketchybar/sketchybarrc" = {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      export PATH="${pkgs.sketchybar}/bin:$HOME/.nix-profile/bin:/usr/bin:/bin"
      # Frosted Catppuccin Macchiato pills after wthrajat/dotfiles-mac.
      TEXT=0xffcad3f5
      SUBTEXT0=0xffa5adcb
      SURFACE1=0xff494d64
      SKY=0xff91d7e3
      PILL_BG=0xbf24273a
      PILL_BORDER=0x80494d64
      TRANSPARENT=0x00000000
      ICON_FONT="Symbols Nerd Font Mono:Regular:13.0"
      LABEL_FONT="SF Mono:Medium:11.5"

      # The bar itself is invisible; only the blurred pills show.
      sketchybar --bar position=top height=28 y_offset=3 margin=0 color=$TRANSPARENT \
        blur_radius=0 shadow=off sticky=on font_smoothing=on padding_left=12 padding_right=12 \
        topmost=window \
        --default updates=when_shown icon.font="$ICON_FONT" icon.color=$SUBTEXT0 \
        label.font="$LABEL_FONT" label.color=$TEXT padding_left=0 padding_right=0 \
        background.color=$TRANSPARENT background.drawing=off

      # Apple logo, separator and workspaces share one pill.
      sketchybar --add item apple left --set apple icon="" \
        icon.font="Symbols Nerd Font Mono:Regular:15.0" icon.color=$TEXT icon.align=center \
        icon.width=26 icon.padding_left=2 icon.padding_right=2 label.drawing=off \
        click_script="/usr/bin/open -a 'Activity Monitor'" \
        --add item workspace_separator left --set workspace_separator icon.drawing=off \
        label="|" label.color=$SURFACE1 label.padding_left=2 label.padding_right=6
      for n in 1 2 3 4 5 6 7 8 9; do
        sketchybar --add item workspace.$n left --set workspace.$n icon.drawing=off \
          label="$n" label.width=24 label.align=center label.padding_left=0 label.padding_right=0 \
          background.height=18 background.corner_radius=6 \
          click_script="$HOME/.nix-profile/bin/omniwmctl command switch-workspace $n"
      done
      sketchybar --add bracket workspace_panel apple workspace_separator '/workspace\.[1-9]$/' \
        --set workspace_panel background.drawing=on background.color=$PILL_BG \
        background.height=24 background.corner_radius=10 background.border_width=1 \
        background.border_color=$PILL_BORDER background.padding_left=8 \
        background.padding_right=8 blur_radius=30
      sketchybar --add item workspace_sync left --set workspace_sync drawing=off \
        update_freq=30 script="${bridge} update"

      # Each status item on the right is its own frosted pill.
      sketchybar --default background.drawing=on background.color=$PILL_BG \
        background.height=24 background.corner_radius=10 background.border_width=1 \
        background.border_color=$PILL_BORDER blur_radius=30 icon.color=$SKY \
        icon.padding_left=10 icon.padding_right=4 label.padding_left=4 label.padding_right=12 \
        padding_left=5 padding_right=5
      sketchybar --add item battery right --set battery update_freq=60 \
        script="${bridge} battery" \
        --subscribe battery power_source_change system_woke \
        --add item clock right --set clock icon="󰥔" update_freq=10 \
        script="${bridge} clock" \
        --add item date right --set date icon="󰃰" update_freq=60 padding_left=10 \
        script="${bridge} date"
      # Bluetooth and Wi-Fi share one pill; the bracket draws it, so the
      # gaps around it come from the neighbouring date and CPU pills.
      sketchybar --add item bluetooth right --set bluetooth icon="󰂯" \
        background.drawing=off padding_left=0 padding_right=0 \
        icon.padding_left=5 icon.padding_right=3 label.padding_left=2 label.padding_right=10 \
        update_freq=60 script="${bridge} bluetooth" \
        click_script="/usr/bin/open 'x-apple.systempreferences:com.apple.BluetoothSettings'" \
        --subscribe bluetooth system_woke \
        --add item wifi right --set wifi icon="󰖩" label.drawing=off \
        background.drawing=off padding_left=0 padding_right=0 \
        icon.padding_left=10 icon.padding_right=5 \
        update_freq=20 script="${bridge} wifi" \
        click_script="/usr/bin/open 'x-apple.systempreferences:com.apple.wifi-settings-extension'" \
        --subscribe wifi system_woke \
        --add bracket network wifi bluetooth --set network background.drawing=on \
        background.color=$PILL_BG background.height=24 background.corner_radius=10 \
        background.border_width=1 background.border_color=$PILL_BORDER blur_radius=30
      sketchybar --add item cpu right --set cpu icon="󰍛" update_freq=10 padding_right=10 \
        script="${bridge} cpu" click_script="/usr/bin/open -a 'Activity Monitor'" \
        --add item memory right --set memory icon="󰘚" update_freq=30 \
        script="${bridge} memory" click_script="/usr/bin/open -a 'Activity Monitor'"
      # The meeting agent fills this in and hides it when nothing is coming up.
      sketchybar --add item meeting right --set meeting icon="󰕧" drawing=off \
        --update
    '';
  };
  launchd.agents.sketchybar = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.sketchybar}/bin/sketchybar" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardErrorPath = "/tmp/sketchybar.log";
    };
  };
  launchd.agents.omniwm-sketchybar = {
    enable = true;
    config = {
      ProgramArguments = [ "${bridge}" "watch" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardErrorPath = "/tmp/omniwm-sketchybar.log";
    };
  };
  launchd.agents.sketchybar-meeting = {
    enable = true;
    config = {
      ProgramArguments = [ "${meeting}/bin/sketchybar-meeting" "${pkgs.sketchybar}/bin/sketchybar" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardErrorPath = "/tmp/sketchybar-meeting.log";
    };
  };
  targets.darwin.defaults.NSGlobalDomain._HIHideMenuBar = true;
  # macOS 26 uses this in addition to the legacy global preference.
  targets.darwin.defaults."com.apple.controlcenter".AutoHideMenuBarOption = 0;
}
