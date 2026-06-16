{
  flake.modules.home."apps/yazi" =
    {
      ...
    }:
    {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
      };
      programs.yazi.shellWrapperName = "y";

      # ycd: launch yazi then cd to the directory you navigated to.
      # Must be shell functions (not a script) because cd affects the current session.
      programs.fish.functions.ycd = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
      '';
    };
}
