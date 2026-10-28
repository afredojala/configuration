{ ... }:
let
  # recursive links each file, so pi and `herdr integration install pi` can still
  # add their own files. settings.json and auth.json stay unmanaged: pi writes them.
  link = dir: { source = ../dotfiles/pi/${dir}; recursive = true; };
in
{
  home.file.".pi/agent/extensions" = link "extensions";
  home.file.".pi/agent/agents" = link "agents";
  home.file.".pi/agent/prompts" = link "prompts";
}
