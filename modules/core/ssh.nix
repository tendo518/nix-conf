{
  flake.modules.homeManager."core/ssh" =
    { pkgs, ... }:
    {
      # services.ssh-agent.enable = true;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        # Force to use xterm-256color
        # This break some functionality on ghostty and kitty, but ensure stability when ssh to remote
        extraConfig = ''
          SetEnv TERM=xterm-256color
        '';

        matchBlocks = {
          "*" = {
            controlMaster = "auto";
            controlPath = "~/.ssh/.control-%h-%p-%r";
            controlPersist = "yes";
            serverAliveInterval = 10;
          };
          "lab-server.local" = {
            hostname = "192.168.40.1";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "lab-desktop.local" = {
            hostname = "192.168.40.244";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "hpc1-login01.cluster" = {
            hostname = "172.18.34.23";
            user = "30017301";
            port = 10022;
            identityFile = "~/.ssh/id_ed25519";
          };
          "hpc1-login02.cluster" = {
            hostname = "172.18.34.17";
            user = "30017301";
            port = 10022;
            identityFile = "~/.ssh/id_ed25519";
          };
          "hpc2-login01.cluster" = {
            hostname = "172.18.34.26";
            user = "cse30017301";
            port = 10022;
            identityFile = "~/.ssh/id_ed25519";
          };
          "hpc2-login02.cluster" = {
            hostname = "172.18.34.25";
            user = "cse30017301";
            port = 10022;
            identityFile = "~/.ssh/id_ed25519";
          };
          # this is a GPU server using hpc authentication
          "gpu-4l40s-37-114.cluster" = {
            hostname = "172.18.37.114";
            user = "30017301";
            port = 10022;
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-8p100-36-44_old.cluster" = {
            hostname = "172.18.36.44";
            user = "pengweiyuan";
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-8p100-36-44.cluster" = {
            hostname = "172.18.36.44";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-8p100-36-44_gangroup.cluster" = {
            hostname = "172.18.36.44";
            user = "gangroup";
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-4v100s-36-182.cluster" = {
            hostname = "172.18.36.182";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-4v100s-36-182_zhangmy.cluster" = {
            hostname = "172.18.36.182";
            user = "zhangmy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-4v100-36-33.cluster" = {
            hostname = "172.18.36.33";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-7v100-35-208.cluster" = {
            hostname = "172.18.35.208";
            user = "pengwy";
            port = 22;
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-5titan-35-233.cluster" = {
            hostname = "172.18.35.233";
            user = "pengwy";
            port = 10022;
            identityFile = "~/.ssh/id_ed25519";
          };
          "gpu-6r2080ti-35-212.cluster" = {
            hostname = "172.18.35.212";
            user = "pengwy";
            port = 22;
            identityFile = "~/.ssh/id_ed25519";
          };
          "lab-desktop.tailscale" = {
            hostname = "100.116.76.115";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          "home-desktop.tailscale" = {
            hostname = "100.77.154.86";
            user = "tendo";
            identityFile = "~/.ssh/id_ed25519";
          };
          "lab-server.tailscale" = {
            hostname = "100.102.138.37";
            user = "pengwy";
            identityFile = "~/.ssh/id_ed25519";
          };
          # "home-nas.tailscale" = {
          #   hostname = "100.77.154.86";
          #   user = "tendo";
          #   identityFile = "~/.ssh/id_ed25519";
          # };
          # "solar-laptop.tailscale" = {
          #   hostname = "100.101.177.110";
          #   user = "tendo";
          #   identityFile = "~/.ssh/id_ed25519";
          # };
        };
      };
    };
}
