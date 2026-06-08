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

  # uwsm sources ~/.config/uwsm/env(-hyprland) into the systemd/dbus activation
  # environment at session start. Without these the graphical session inherits
  # greetd's minimal env (no profile XDG_DATA_DIRS => empty app launcher, no
  # cursor theme). Inert on the stow/Fedora host where uwsm never runs.
  xdg.configFile."uwsm".source = link "${dots}/uwsm/.config/uwsm";
}
