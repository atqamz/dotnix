{ config, lib, ... }:
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

  # hyprland.lua does `require("host")`; host.lua is the gitignored per-machine
  # symlink that picks hosts/<host>.lua, so a fresh clone has none and the require
  # fails. The hypr dir is symlinked out (above), so writing host.lua inside the
  # clone reaches ~/.config/hypr. Mirrors `make host-link` on the stow side.
  home.activation.hyprHostLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -sfn hosts/pavg15.lua "${dots}/hypr/.config/hypr/host.lua"
  '';
}
