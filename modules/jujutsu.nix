{ pkgs, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Guangzong Chen";
        email = "guangzong@google.com";
      };
      ui = {
        default-command = "log";
        pager = "delta";
        diff-formatter = ":git";
      };
      core = {
        # Using Sequoia chameleon GPG
        signing-key = "20AE4BA8FF696FB5E21AE9D0636538D58AF1006D";
      };
    };
  };
}
