let
  pkgs = (import nix/packages.nix).pkgs;
in
pkgs.stdenv.mkDerivation {
  name = "voting";
  buildInputs =
    [
      # Elm ---------------------------------
      pkgs.elmPackages.elm
      pkgs.elmPackages.elm-format

      # Git ---------------------------------
      pkgs.git
      pkgs.git-lfs
    ];
    # ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.libnotify # For ExUnit Notifier on Linux.
    # ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.inotify-tools # For file_system on Linux.
    # ++ pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.terminal-notifier # For ExUnit Notifier on macOS.
    # ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
    #   # For file_system on macOS.
    #   CoreFoundation
    #   CoreServices
    # ]);
}