{
  description = "Patch compile_commands.json with Nix's include flags from $NIX_CFLAGS_COMPILE";

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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.writeShellApplication {
          name = "patch-compile-commands";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            exec ${pkgs.python3}/bin/python ${self}/patch_cc.py "$@"
          '';
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      }
    );
}
