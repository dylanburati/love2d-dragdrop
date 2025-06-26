{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-utils.url = "github:numtide/flake-utils";

    proccorder.url = "github:dylanburati/proccorder";
  };

  outputs = { self, nixpkgs, flake-utils, proccorder, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            curl
          ];
          # Pinned packages available in the environment
          packages = with pkgs; [
            #act
            #netcat-gnu
            luaformatter
            luajit
            lua-language-server
            #miniserve
            nodejs_20
            p7zip
            #steamos-devkit
            stylua
            #tree
            #unzip
            #xmlstarlet
            #zip
          ] ++ pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [
            love
          ];
          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.curl
            ]}:$LD_LIBRARY_PATH
            exec zsh || true
          '';
        };
      });
}
