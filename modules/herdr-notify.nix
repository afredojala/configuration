{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
  # The topic works like a password and this repo is public, so it lives in an
  # untracked file instead of the agent's environment.
  topicFile = "${config.xdg.configHome}/herdr-notify/topic";
  start = pkgs.writeShellScript "herdr-notify-start" ''
    if [ ! -r "${topicFile}" ]; then
      echo "herdr-notify: missing ${topicFile}" >&2
      exit 1
    fi
    HERDR_NOTIFY_TOPIC=$(cat "${topicFile}")
    export HERDR_NOTIFY_TOPIC
    exec ${pkgs.python3}/bin/python3 "${home}/repos/herdriOS/scripts/herdr-notify" \
      --hc "${home}/.local/bin/hc" --notify blocked,error
  '';
in
{
  # Pushes Herdr agents that are blocked or erroring to ntfy, for the iPhone app.
  launchd.agents.herdr-notify = {
    enable = true;
    config = {
      ProgramArguments = [ "${start}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardErrorPath = "${home}/Library/Logs/herdr-notify.log";
    };
  };
}
