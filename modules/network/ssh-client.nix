{
  flake.modules.home."network/ssh-client" = { config, pkgs, ... }: {
    # services.ssh-agent.enable = true;

    # Generic client behavior stays declarative; host-specific entries are
    # loaded from the agenix-managed fragment below.
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraConfig = ''
        SetEnv TERM=xterm-256color
      '';
      includes = [ "${config.home.homeDirectory}/.ssh/ssh-hosts.conf" ];
      settings."*" = {
        ControlMaster = "auto";
        ControlPath = "~/.ssh/.control-%h-%p-%r";
        ControlPersist = "yes";
        ServerAliveInterval = 10;
      };
    };

    # Complete the tailnet aliases from the live peer list, so a newly joined
    # machine shows up before its Host entry is added above.
    programs.fish.functions.__fish_tailscale_ssh_hosts = ''
      if not set -q __tailscale_ssh_hosts
          set -g __tailscale_ssh_hosts (tailscale status --json | ${pkgs.jq}/bin/jq -r '.Peer[]? | "\(.HostName).tailnet"')
      end
      printf '%s\n' $__tailscale_ssh_hosts
    '';
    programs.fish.interactiveShellInit = ''
      complete -c ssh -k -f -a '(__fish_tailscale_ssh_hosts)'
    '';

    # Host-specific SSH entries are agenix-managed so addresses never enter
    # the Nix store. programs.ssh includes this fragment from ~/.ssh/config.
    age.secrets.ssh-hosts = {
      file = ../../secrets/ssh-hosts.age;
      path = "${config.home.homeDirectory}/.ssh/ssh-hosts.conf";
      mode = "0400";
    };
  };
}
