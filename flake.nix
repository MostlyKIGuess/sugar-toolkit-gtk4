{
  description = "Sugar Toolkit GTK4 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    sugar-artwork-src = {
      url = "github:MostlyKIGuess/sugar-artwork";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, sugar-artwork-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        sugar-artwork = pkgs.stdenv.mkDerivation {
          pname = "sugar-artwork";
          version = "0.121-local";

          src = sugar-artwork-src;

          nativeBuildInputs = with pkgs; [
            autoconf automake libtool pkg-config intltool
            gtk3 gdk-pixbuf librsvg xorg.xcursorgen
            python3 python3Packages.empy iconnamingutils
          ];

          buildInputs = with pkgs; [
            gtk3 gdk-pixbuf librsvg hicolor-icon-theme
            python3 gtk2
          ];

          preConfigure = ''
            autoreconf -fi
          '';

          configureFlags = [
            "--with-gtk3"
            "--without-gtk2"
            "--enable-icon-theme"
            "--enable-cursor-theme"
          ];
        };

        pythonEnv = pkgs.python311.buildEnv.override {
          extraLibs = with pkgs.python311Packages; [
            pygobject3 dbus-python pytest pytest-cov
            black flake8 mypy
            sphinx sphinx-rtd-theme sphinx-autoapi
            six decorator build twine setuptools wheel
          ];
        };
        gtkDeps = with pkgs; [
          gtk4 gobject-introspection gtk4.dev
          glib glib.dev gdk-pixbuf librsvg
          dconf gsettings-desktop-schemas
          hicolor-icon-theme adwaita-icon-theme
          dbus dbus-glib gtk3 gtk3.dev
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            sugar-artwork     
            pkgs.python3
            pythonEnv
          ] ++ gtkDeps ++ (with pkgs; [
            git gnumake pkg-config cairo pango atk
            gtk4.dev wrapGAppsHook4 jq ripgrep fd
          ]);

          nativeBuildInputs = with pkgs; [
            wrapGAppsHook4 gobject-introspection pkg-config dbus dbus-glib
          ];

          GI_TYPELIB_PATH = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
            "${pkgs.gtk4.dev}/lib/girepository-1.0"
            "${pkgs.glib.dev}/lib/girepository-1.0"
            "${pkgs.gdk-pixbuf.dev}/lib/girepository-1.0"
            "${pkgs.librsvg.dev}/lib/girepository-1.0"
            "${pkgs.dbus-glib.out}/lib/girepository-1.0"
          ];

          XDG_DATA_DIRS = pkgs.lib.makeSearchPath "share" [
            "${pkgs.gtk4.dev}"
            "${pkgs.gsettings-desktop-schemas}"
            "${pkgs.hicolor-icon-theme}"
            "${pkgs.adwaita-icon-theme}"
            "${sugar-artwork}"
          ];

          GIO_EXTRA_MODULES = "${pkgs.dconf.lib}/lib/gio/modules";
          PYTHONPATH = "${pythonEnv}/${pythonEnv.sitePackages}";
          DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/$UID/bus";

          CFLAGS = "-I${pkgs.gtk4.dev}/include/gtk-4.0 -I${pkgs.glib.dev}/include";
          LDFLAGS = "-L${pkgs.gtk4.out}/lib -L${pkgs.glib.out}/lib";

          shellHook = ''
            echo "Sugar Toolkit GTK4 dev environment"
            echo "Using sugar-artwork from: https://github.com/MostlyKIGuess/sugar-artwork"
            echo "Python $(python --version)"
          '';
        };

        packages.default = pkgs.python311Packages.buildPythonPackage {
          pname = "sugar-toolkit-gtk4";
          version = "1.1.3";
          src = ./.;

          buildInputs = gtkDeps;
          nativeBuildInputs = with pkgs; [
            wrapGAppsHook4 gobject-introspection pkg-config dbus dbus-glib
          ];
          propagatedBuildInputs = with pkgs.python311Packages; [
            pygobject3 dbus-python
          ];

          pythonNamespaces = [ "sugar4" ];
        };
      });
}
