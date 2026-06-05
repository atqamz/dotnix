{ ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";       # unbind C-b, send-prefix handled by HM
    mouse = true;
    baseIndex = 1;
  };
}
