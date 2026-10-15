{ config, lib, pkgs, ... }:
let
  agentSocket = if pkgs.stdenv.hostPlatform.isDarwin
    then "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else "${config.home.homeDirectory}/.1password/agent.sock";
in
{
  home.sessionVariables.SSH_AUTH_SOCK = agentSocket;
  home.file.".ssh/1password/id_ed25519.pub".source = ../dotfiles/ssh/id_ed25519.pub;

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      editor = "hx";
      aliases.co = "pr checkout";
    };
    gitCredentialHelper.enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = lib.hm.dag.entryAfter [ "rbpi" "datadriven" "hetzner" ] {
        IdentityAgent = "\"${agentSocket}\"";
      };
      rbpi = { HostName = "192.168.1.90"; User = "alarm"; };
      datadriven = {
        HostName = "108.143.140.155";
        User = "datadriven";
        IdentityFile = "~/.ssh/id_datadriven";
        # This separate key has not been migrated to 1Password.
        IdentityAgent = "none";
      };
      hetzner = {
        HostName = "204.168.250.91";
        User = "root";
        # A public key selects its matching private key from the agent.
        IdentityFile = "~/.ssh/1password/id_ed25519.pub";
        IdentitiesOnly = true;
      };
    };
  };
}
