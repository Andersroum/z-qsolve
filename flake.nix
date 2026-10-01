{
  description = "Zig flake for building stuff";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.zig
        pkgs.zls          # Zig Language Server (like rust-analyzer)
      ];
      shellHook = ''
        echo "================================================================================"
        echo "zig version: $(zig version)"
        echo "zls version: $(zls --version)"
        echo "================================================================================"
      '';
    };
  };
}
