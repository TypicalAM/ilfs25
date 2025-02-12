{ pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    programs.bash = {
      shellInit = ''
if [ $UID -ne 0 ]; then
  ${pkgs.gum}/bin/gum spin --spinner="dot" --title="Downloading" -- sh -c "docker pull typicalam/ubuntu:24.04 > /dev/null"
cat <<EOF
                            .       ..
         .::::.....   .::::::::::..
         ..:::::::::::::::-:...
    ...:::-::-::::...::...
     ......:.::::::.
             .. .-.
        ...     ::
   ...         ::.
 .            .::       ..
              .:-:     ::::
               :--:.  .-:::
                .:::::-:::.
                  ::-::-::.
                  :::::-::-:
                  .::::::-::.
                  .:::::::::..:
                  :::----:::-:
                  :::-::::...

Welcome to the over-engineered container, now get the flag!
EOF
  ${pkgs.docker}/bin/docker run -it --rm --privileged typicalam/ubuntu:24.04
  exit
fi
'';
    };

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    users.extraUsers.root.password = "jajko";
    virtualisation.docker.enable = true;
    users = {
      users.student = {
        shell = pkgs.bash;
        isNormalUser = true;
        description = "Student";
        extraGroups = [ "docker" ];
        password = "IfYouThinkAboutItThisIsAReallyStrongPassword";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZPSlFqP0cFnTcMPU4ALqBA8qJVEKTKXGs+ulkS4xbw student@jajco" ];
      };
    };

    systemd.tmpfiles.rules = [
      "f /FLAGA.txt 0644 root root - FLAG{1_10V3_0P3N_50UrC3}"
    ];

    system.stateVersion = "24.11";
  };
}
