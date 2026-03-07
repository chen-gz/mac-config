{ pkgs, lib, ... }:
{
  # --- 系统层配置 (仅对 macOS 生效) ---
  system.defaults.dock.autohide = lib.mkForce true;

  # --- 用户层配置 (Home Manager) ---
  home-manager.users.connie = {
    imports = [
      ./modules/home/common.nix
    ];

    programs.git.settings.user = {
    name = "Connie";
    email = "connie@ggeta.com";
    # signingkey = "...";
  };
};
}
