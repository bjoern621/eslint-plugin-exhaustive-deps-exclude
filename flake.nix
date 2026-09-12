{
  description = "eslint-plugin-exhaustive-deps-exclude: dev shell for the plugin, its scripts and its workflows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # Dev shell:
        #   nodejs_24    the version the release job publishes from, and the matrix ceiling
        #   actionlint   linter for .github/workflows
        #   shellcheck   linter for scripts/
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_24
            actionlint
            shellcheck
          ];

          shellHook = ''
            echo "exhaustive-deps-exclude dev shell (node $(node --version))"
            echo "  npm test              build, then run the case suite"
            echo "  npm run patch         local delta against the pinned upstream"
            echo "  npm run sync          merge upstream over the pin"
            echo "  npm version major     bump, commit and tag a release"
          '';
        };
      });
}
