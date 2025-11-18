{
  description = "Static site package for pschmitt.dev";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      inherit (lib) maintainers;
      systems = lib.systems.flakeExposed;
      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          f pkgs
        );
      version = self.shortRev or "dirty";
      src = lib.cleanSourceWith {
        src = self;
        filter =
          path: type:
          let
            base = builtins.baseNameOf path;
          in
          !builtins.elem base [
            ".git"
            ".gitignore"
            ".github"
            "flake.nix"
            "flake.lock"
          ];
      };
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "pschmitt.dev";
          inherit version;
          inherit src;
          dontConfigure = true;
          dontBuild = true;
          installPhase = ''
            mkdir -p "$out"
            cp -R ./. "$out"/
          '';
          meta = with lib; {
            description = "Static assets for pschmitt.dev";
            homepage = "https://pschmitt.dev";
            license = licenses.gpl3Only;
            maintainers = with maintainers; [ pschmitt ];
            platforms = platforms.all;
          };
        };
      });
    };
}
