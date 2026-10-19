{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k3d
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
  ];

  programs.k9s = {
    enable = true;
    settings = lib.recursiveUpdate
      (builtins.fromJSON (builtins.readFile ../dotfiles/k9s/config.json))
      { k9s.screenDumpDir = "${config.xdg.stateHome}/k9s/screen-dumps"; };
    aliases = builtins.fromJSON (builtins.readFile ../dotfiles/k9s/aliases.json);
  };
}
