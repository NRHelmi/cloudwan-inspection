let
  pkgs = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/ccc0c2126893dd20963580b6478d1a10a4512185.tar.gz") {};
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    awscli2
    python3
    terraform
    terraform-docs
  ];
}
