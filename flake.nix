{
  description = "My version of dmenu. TODO: Remake it on nix way.";

  outputs = { self, nixpkgs }:
    let

      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {
      # A Nixpkgs overlay.
      overlay = final: prev: {

        dmenu = with final; stdenv.mkDerivation rec {
          pname = "ava-dmenu-5.2.0";
          inherit version;

          src = ./.;

          buildInputs = [ pkgs.xorg.libX11 pkgs.xorg.libXinerama pkgs.zlib pkgs.xorg.libXft ];

          postPatch = ''
            sed -ri -e 's!\<(dmenu|dmenu_path|stest)\>!'"$out/bin"'/&!g' dmenu_run
            sed -ri -e 's!\<stest\>!'"$out/bin"'/&!g' dmenu_path
          '';

          preConfigure = ''
            sed -i "s@PREFIX = /usr/local@PREFIX = $out@g" config.mk
          '';

          makeFlags = [ "CC:=$(CC)" ];
        };
      };

      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) dmenu;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.dmenu);
    };

}
