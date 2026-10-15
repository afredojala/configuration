{ ... }:
{
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
      rbpi = { HostName = "192.168.1.90"; User = "alarm"; };
      datadriven = {
        HostName = "108.143.140.155";
        User = "datadriven";
        IdentityFile = "~/.ssh/id_datadriven";
      };
      hetzner = {
        HostName = "204.168.250.91";
        User = "root";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
