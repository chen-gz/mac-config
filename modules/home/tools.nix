{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    config = {
      global = {
        log_format = "";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      # line_break.disabled = true;
    };
  };

  # iTerm2 配置文件管理 (仅 macOS)
  # 这将把仓库里的 plist 文件链接到 ~/.config/iterm2/，即使删除了仓库目录，配置依然在 Nix Store 中
  home.file =
    if pkgs.stdenv.isDarwin then
      {
        ".config/iterm2/com.googlecode.iterm2.plist".source = ../../iterm2/com.googlecode.iterm2.plist;
      }
    else
      { };
}
