let
  # Host SSH public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  laptop-solar-modoka = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHE26q8V4hSofUen59THqal9He1WSnJHIwBTIOXrdn9o";
  laptop-solar-chiyoko = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEU/wqeU6qTwbnFs+D7HVHxbZlPS53cTuuhvWDn9uXqA";
  desktop-home-saki = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQdSaqg4cgiYXrydHmkw636cKUshB0MxcpmEUTO8wVs";
  # desktop-lab-peace = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvSHQz/v6pmRwkrfutwevvH5awMzB+HDqh6geOSPvSG";
  desktop-lab-peace = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvB13iPkUSDaGornxY05I1KsHrYgXBqf3nKAuGC0I6I";
  host-ssh-pubkeys = [
    laptop-solar-modoka
    laptop-solar-chiyoko
    desktop-home-saki
    desktop-lab-peace
  ];
  # User SSH public keys (from ~/.ssh/id_ed25519.pub)
  tendo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR";
in
{
  # List all public keys that should be able to decrypt each secret.
  # Include: your user key (for editing) + host keys (for decryption at boot).
  "deepseek-api-key.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "aliyun-codingplan-api-key.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "volcengine-codingplan-api-key.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "tendo-password.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "pengwy-password.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "root-password.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "syncthing-key.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
}
