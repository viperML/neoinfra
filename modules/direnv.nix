{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.direnv
  ];
  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
  '';
}
