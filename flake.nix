{
  description = "Various fonts I've found online";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    with builtins;
    with nixpkgs.lib;
      flake-utils.lib.eachDefaultSystem (system: let
        pkgs = import nixpkgs {inherit system;};
        buildFont = {
          name,
          files,
          license,
          author,
        }: let
          pathEndsWith = suffix: path: let
            str = toString path;
            sufLen = stringLength suffix;
            sLen = stringLength str;
          in
            sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str;

          installType = extension: pathName: let
            filteredFiles = filter (pathEndsWith ("." + extension)) files;
            filename = file: lists.last (strings.splitString "/" (toString file));
          in
            (optionalString (filteredFiles != []) "mkdir -p $out/share/fonts/${pathName}\n")
            + concatStringsSep "\n" (map (file: "cp -v ${file} $out/share/fonts/${pathName}/${filename file}") filteredFiles);
        in
          pkgs.stdenvNoCC.mkDerivation {
            inherit name;

            dontUnpack = true;
            installPhase = ''
              ${installType "ttf" "truetype"}
              ${installType "otf" "opentype"}
            '';

            meta = {
              inherit license;
              platforms = platforms.all;
              description = "${name} font by ${author}";
            };
          };

        fonts = [
          {
            name = "OCR-B";
            files = [./OCR-B-Regular.otf];
            license = licenses.cc-by-40;
            author = "Matthew Anderson";
          }
        ];
      in {
        packages = listToAttrs (map (font: {
            name = toLower font.name;
            value = buildFont font;
          })
          fonts);

        formatter = pkgs.alejandra;
      });
}
