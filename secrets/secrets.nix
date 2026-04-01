let
  # Host SSH public keys (from /etc/ssh/ssh_host_ed25519_key.pub)
  laptop-solar-modoka = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHE26q8V4hSofUen59THqal9He1WSnJHIwBTIOXrdn9o";
  laptop-solar-chiyoko = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0VYqQdRKzWdaiBpwhRHGNi727AxtbaHw5KZ6VB5gKUZQLBDVeOq9V3Au7AOFNa7d/UufeKzs5eqDBiChe237zaJPmuELLiJXFYnzzILKP3OXyzO1JABapnv1k+V3BaLcrxvAFcjs/3gCzAwQ4cQvI4uSLDO6kV7EOG3SdVmEv/+3EQTKacyYA8bWdwY7khubSLyYuH1uvLRjmjJ3xbONIjwX6j6EhRV5ydIYtD0sLZ0GhUc0ZCyI1xDZWrq1A/NsKtyvgPApitxwqCjC/gQ9SppPjdPFPoSLhic9yqv6RlmV+FZgSqHQpAKeAeq4zodsa71lR/av5C4md9e7J8nfbyJ6agNnOPD/AVKAQQAK/V9fxIFCnTiH4Kpj7yYb1dAyfc98zhl6U0cw0ZWDD27v+HEfNO8LTf200AsUnvhefBGFtzHQyrX05nAy1DgFHc8ux2V6uj4BqjUAfvP2gLU2eY+jHbjyvV1IlgbzsT+5sShg4chyX6SCzj8Zo7Tw4QB1JL09S96ZBOnGWWx/SUn94DE46BuSA5kw7Ky85gyuFhmtHFQrhrNQZ7lM6k2KX+o3xDbpM51oDZh+n4a9+hqFMyACz0r3YAdngKQ8IOOhkfLYEmZW1fNPqoDr8sIYsPEhvU8sZJa+aS9+gymOj8r7UanzIMfDAcLgx+bd4Wp8skw==";
  desktop-home-saki = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQdSaqg4cgiYXrydHmkw636cKUshB0MxcpmEUTO8wVs";
  desktop-lab-peace = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsJdnSh7sd2qaNBs0iFagcjDaLDNpI5do7yo3t0FAZB";
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
  "tendo-password.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "pengwy-password.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "root-password.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
  "syncthing-key.age".publicKeys = [ tendo ] ++ host-ssh-pubkeys;
}
