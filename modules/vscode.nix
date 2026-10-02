{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = (
      pkgs.runCommand "vscode" {
        meta.mainProgram = "code";
      } "mkdir -p $out/bin; touch $out/bin/code; chmod +x $out/bin/code"
    );
    profiles.default.extensions = with pkgs.vscode-extensions; [
      leanprover.lean4
    ];
  };
}
