{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        true-color = true;
        line-number = "relative";
        bufferline = "multiple";
        cursorline = true;
        color-modes = true;
        whitespace = {
          render = "all";
          characters = {
            space = " ";
            tab = "→";
            newline = " ";
          };
        };
        indent-guides.render = true;
        file-picker.hidden = false;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        lsp.display-messages = true;
      };
      keys.normal = {
        q = ":quit";
      };
    };
    languages = {
      language = [
        {
          name = "just";
          auto-format = true;
          language-servers = [ "just-lsp" ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          language-servers = [ "nixd" ];
        }
      ];
      language-server = {
        just-lsp = {
          command = "just-lsp";
        };
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
        };
      };
    };
  };
}
