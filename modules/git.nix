{ ... }:
let
  user = {
    name = "Andreas Fred-Ojala";
    email = "Andreasfo@gmail.com";
  };
in
{
  programs.git = {
    enable = true;
    settings.user = user;
  };

  programs.jujutsu = {
    enable = true;
    settings.user = user;
  };
}
