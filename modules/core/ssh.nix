{
  flake.modules.home."core/ssh" =
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

        settings = {
          "*" = {
            ControlMaster = "auto";
            ControlPath = "~/.ssh/.control-%h-%p-%r";
            ControlPersist = "yes";
            ServerAliveInterval = 10;
          };
          "lab-server.local" = {
            Hostname = "192.168.40.1";
            User = "pengwy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "lab-desktop.local" = {
            Hostname = "192.168.40.244";
            User = "pengwy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "hpc1-login01.cluster" = {
            Hostname = "172.18.34.23";
            User = "30017301";
            Port = 10022;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "hpc1-login02.cluster" = {
            Hostname = "172.18.34.17";
            User = "30017301";
            Port = 10022;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "hpc2-login01.cluster" = {
            Hostname = "172.18.34.26";
            User = "cse30017301";
            Port = 10022;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "hpc2-login02.cluster" = {
            Hostname = "172.18.34.25";
            User = "cse30017301";
            Port = 10022;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          # this is a GPU server using hpc authentication
          "gpu-4l40s-37-114.cluster" = {
            Hostname = "172.18.37.114";
            User = "30017301";
            Port = 10022;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-8p100-36-44_old.cluster" = {
            Hostname = "172.18.36.44";
            User = "pengweiyuan";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-8p100-36-44.cluster" = {
            Hostname = "172.18.36.44";
            User = "pengwy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-8p100-36-44_gangroup.cluster" = {
            Hostname = "172.18.36.44";
            User = "gangroup";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-4v100s-36-182.cluster" = {
            Hostname = "172.18.36.182";
            User = "pengwy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-4v100s-36-182_zhangmy.cluster" = {
            Hostname = "172.18.36.182";
            User = "zhangmy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-4v100-36-33.cluster" = {
            Hostname = "172.18.36.33";
            User = "pengwy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-7v100-35-208.cluster" = {
            Hostname = "172.18.35.208";
            User = "pengwy";
            Port = 22;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-5titan-35-233.cluster" = {
            Hostname = "172.18.35.233";
            User = "pengwy";
            Port = 10022;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "gpu-6r2080ti-35-212.cluster" = {
            Hostname = "172.18.35.212";
            User = "pengwy";
            Port = 22;
            IdentityFile = "~/.ssh/id_ed25519";
          };
          # Tailscale devices
          "desktop-home-saki.tailscale" = {
            Hostname = "100.124.50.41";
            User = "tendo";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "desktop-lab-peace.tailscale" = {
            Hostname = "100.66.176.74";
            User = "pengwy";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "laptop-solar-chiyoko.tailscale" = {
            Hostname = "100.111.132.42";
            User = "tendo";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "laptop-solar-modoka.tailscale" = {
            Hostname = "100.112.217.3";
            User = "tendo";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "server-lab-sardine.tailscale" = {
            Hostname = "100.70.253.124";
            User = "tendo";
            IdentityFile = "~/.ssh/id_ed25519";
          };
        };
      };
    };
}
