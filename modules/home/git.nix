{ pkgs, ... }:
{
  # 修正警告：将 delta 配置移动到独立模块
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Guangzong Chen";
        email = "guangzong@google.com";
        signingkey = "20AE4BA8FF696FB5E21AE9D0636538D58AF1006D";
      };
      core = {
        sshCommand = "/usr/bin/ssh";
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
