{
  description = "Add $NIX_CFLAGS_COMPILE include flags to compile_commands.json";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      shellHookText = ''
        _patch_cc() {
          [[ -z "$NIX_CFLAGS_COMPILE" ]] && return

          # If the user set PATCH_CC_DB, forward it as argv[1]; otherwise no arg (python script handles this fallback)
          if [[ -n "''${PATCH_CC_DB:-}" ]]; then
            patch-compile-commands "''${PATCH_CC_DB}"
          else
            patch-compile-commands
          fi
        }

            _patch_cc
            if [[ -n "$PROMPT_COMMAND" ]]; then
              export PROMPT_COMMAND="_patch_cc;$PROMPT_COMMAND"
            else
              export PROMPT_COMMAND="_patch_cc"
            fi
      '';

      perSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          patchBin = pkgs.writeShellApplication {
            name = "patch-compile-commands";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              exec ${pkgs.python3}/bin/python ${self}/patch_cc.py "$@"
            '';
          };
        in
        {
          packages.default = patchBin;
          apps.default = flake-utils.lib.mkApp {
            drv = patchBin;
          };
        }
      );
    in
    perSystem
    // {
      lib.shellHook = shellHookText;
    };
}
