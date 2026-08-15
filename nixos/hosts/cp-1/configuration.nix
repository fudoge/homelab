{
  config,
  pkgs,
  lib,
  ...
}: let
  tailnet = "tail274d3c.ts.net";
  apiName = "${config.networking.hostName}.${tailnet}";
in {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [
    "overlay"
    "br_netfilter"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;

    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;

    # Workaround for Cilium L7/FQDN proxy traffic when Tailscale enables
    # net.ipv4.conf.all.src_valid_mark=1.
    # Without accept_local=1 on Cilium host-side veths, proxy-marked traffic
    # can be dropped before LOCAL_IN.
    "net.ipv4.conf.default.accept_local" = 1;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  networking.hostName = "home-cp-1";
  networking.networkmanager.enable = true;

  networking.interfaces.ens18 = {
    ipv4.addresses = [
      {
        address = "192.168.0.37 ";
        prefixLength = 24;
      }
    ];
  };
  networking.interfaces.ens19 = {
    ipv4.addresses = [
      {
        address = "192.168.192.10 ";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "ens18";
  };

  networking.firewall = {
    enable = true;
    checkReversePath = false;
    allowPing = true;

    allowedTCPPorts = [
      22 # SSH

      # k3s HA
      # 2379
      # 2380

      4240 # Cilium Health
      4244 # Hubble server
      4245 # Hubble Relay
      6443 # API Server
      9962 # Prometheus metrics (cilium-agent)
      9963 # Prometheus metrics (cilium-operator)
      9964 # Prometheus metrics (cilium-envoy)
      10250 # Kubelet
    ];

    allowedTCPPortRanges = [
      {
        from = 10000;
        to = 20000;
      }
    ];

    allowedUDPPorts = [
      8472 # Cilium VXLAN

      41641 # Tailscale

      # Wireguard Enc
      # 51871
    ];

    allowedUDPPortRanges = [
      {
        from = 10000;
        to = 20000;
      }
    ];

    trustedInterfaces = [
      "cilium_host"
      "cilium_net"
      "cilim_vxlan"
      "lxc+"
      "tailscale0"
    ];
  };

  fileSystems."/var/lib/rancher/k3s/storage" = {
    device = "/dev/disk/by-label/LOCALPV";
    fsType = "ext4";
  };

  time.timeZone = "Asia/Seoul";
  i18n.defaultLocale = "en_US.UTF-8";

  services.qemuGuest.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["chaewoon"];
    };
  };
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--cluster-init"

      "--disable traefik"
      "--disable servicelb"
      "--disable local-storage"
      "--disable metrics-server"

      "--flannel-backend=none"
      "--disable-kube-proxy"
      "--disable-network-policy"

      "--secrets-encryption"
      "--secrets-encryption-provider=secretbox"
      "--tls-san ${apiName}"
    ];
  };
  services.tailscale = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    bash
    git
    github-cli
    vim
    wget
    tree
    kubectl
    kubernetes-helm
    cilium-cli
    istioctl
    kubeseal
    trivy
    jq
    yq-go
    fzf
    fd
    gnumake
    tcpdump
    sysdig
    util-linux
    btop
    parted
    python3
  ];

  environment.variables.EDITOR = "vim";

  system.stateVersion = "26.05";

  users.users.chaewoon = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBWhBJ+7YbdJYnNzvHEpkkS4j9bgVHJRFCSWDZXL6adH6Z9XZylsfe3BU2YeieJekst/Vo/WPCYZTGinEN3yvxYhsKK0mvoA0Lwbhp9ExdnkCmaPpIDECC1l1l9AlBdPneE5H5ZwOsoaS8DooG8K22WBLvhJapKkSP05aIxZn9A2JRzfguptfGoQeJsCWZhsoPZCrwcdNqWDDRQlUsz1b2HvirkVbnlmkggLo+NnWcFb6CybmrXwIpgvi0ptPvdzdeA8rF6flVuvD0ALn6ywOR9lKwVCkBEYETo/7bLqS3sfdHwB4pctDP6bdqlm2ZDz/Q0VIZoqE2j1mZnCh8x6oTSxiIurrstJdQRQeASF+LscvuHn0ypqhccESqrdASZmjDKANm/3NZf74HJ20xkQ80e6Gwv9HsQ0DaglPWk3W/lDMxdySE1Hq1dUm7nq8RgHt3k2UISuoTBkMA1WZIc0485ibPFxqM4jBNATfO4Qjp+92awSBkDC5eNXUP744/feSkt0eY6fbpWFiDeajxRd43IePEtjRWiW7FWgW9uXa8Xj6g2vhBsYoljWJ23cHUPYzOBGK+QGZyPiggj8vkPT12sWoznDqAbo8dNBKtaLxkcRAKlhAX566kdrjY+PDOqF5e5pqo9LZpKpLGUzluJG3GZ94PCgbpnQvKQBeYJvJnjQ== kchawoon@naver.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+XpFW8WRZcu3noIrPVidAyADg52sv/tjlV3OZ+zHHN chaewoon@spaceship"
    ];
  };
}
