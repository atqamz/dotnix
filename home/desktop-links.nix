{ config, ... }:
let
  # Live-editable configs stay in the stow repo cloned at ~/dotfiles. HM symlinks
  # point AT those working copies (mkOutOfStoreSymlink) instead of freezing a
  # copy into the read-only store — quickshell + hypr are under active edit.
  dots = "${config.home.homeDirectory}/dotfiles";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.configFile."hypr".source = link "${dots}/hypr/.config/hypr";
  xdg.configFile."quickshell".source = link "${dots}/quickshell/.config/quickshell";
}
