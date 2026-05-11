{ pkgs, ... }:
{
  # 修正警告：将 delta 配置移动到独立模块
  programs.git = {
    enable = true;
    settings = {
      core = {
      };
      commit = {
        signoff = true;
        gpgsign = true;
      };
      pull = {
        rebase = true;
      };
      color = {
        ui = "auto";
      };
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
      theme = "TwoDark";
    };
  };

  # --- Lazygit 配置 ---
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showIcons = true;
        skipDiscardChangeWarning = true;
      };
      git = {
        commit = {
          signOff = true;
        };
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
