{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = builtins.fromTOML (builtins.readFile ../dotfiles/helix/config.toml);
    languages = {
      language-server.rust-analyzer.command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      language-server.pyrefly = { command = "${pkgs.pyrefly}/bin/pyrefly"; args = [ "lsp" ]; };
      language-server.ruff = { command = "${pkgs.ruff}/bin/ruff"; args = [ "server" "--preview" ]; };
      language = [
        { name = "python"; language-servers = [ "pyrefly" "ruff" ]; auto-format = true; }
        { name = "jsx"; auto-format = true; }
        { name = "rust"; language-servers = [ "rust-analyzer" ]; auto-format = true; }
      ];
    };
  };
}
