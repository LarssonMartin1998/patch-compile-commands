# patch-compile-commands

Make your **`compile_commands.json`** tell the *whole* truth when you build
C/C++ projects inside a Nix development shell.

 **TLDR**  
- Nix compiler-wrappers silently inject  
- `-isystem /nix/store/…/include` flags.  
- The build succeeds, but those flags never reach *clangd*, *ccls*, *cpp-tools*
- … so your editor shows *false* “cannot find header” errors.  
- This tool adds the same flags back into the compile database **after the
- build** so every LSP sees the correct include paths.

---

## How it works

1.  Every dev package in your `buildInputs` contributes its include path to the
    environment variable **`NIX_CFLAGS_COMPILE`** via Nix setup-hooks.

2.  The Python script:
    ```text
    • reads $NIX_CFLAGS_COMPILE
    • reads compile_commands.json
    • prepends the missing -isystem flags (idempotently)
    ```
    You can run it directly:

    ```console
    $ patch-compile-commands          # ← fixes build/compile_commands.json
    $ PATCH_CC_DB=out/compile_commands.json patch-compile-commands
    ```

3.  A ready-made **shell hook** (`patch_cc.lib.shellHook`) calls the tool
    automatically every time you regenerate the build inside `nix develop`.

---

## Quick start (as a flake input)

```nix
{
  description = "example-cpp";

  inputs = {
    nixpkgs.url     = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    patch_cc.url    = "github:LarssonMartin1998/patch-compile-commands";
  };

  outputs = { self, nixpkgs, flake-utils, patch_cc }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.example = pkgs.stdenv.mkDerivation {
          pname = "example";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [
            pkgs.cmake
            patch_cc.packages.${system}.default
          ];

          # ← add *one* line and every interactive build shell gets patched
          shellHook = ''
            ${patch_cc.lib.shellHook}
          '';
        };

        packages.default = self.packages.${system}.example;
      });
}
```
