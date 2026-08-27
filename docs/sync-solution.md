# Multi-machine sync: Syncthing vs S3+rclone

Deciding how to get a **Dropbox-like experience** (a directory that stays in sync
across several hosts, any of which may edit it, with a safety net for conflicts)
on our machines.

The three machines in scope: `server-lab-sardine`, `laptop-solar-modoka` (mac),
and the two desk stops (either/both). `server-lab-sardine` is an always-on
tailnet node, so it can play the "hub" that a real Dropbox cloud would.

---

## 1. Deciding questions

Answer these two and the tool almost picks itself:

1. **Real-time & automatic, or "sync when I'm done on this box"?**
   Dropbox is real-time; `rclone sync`/`bisync` is manual or cron.
2. **Is any machine a "source of truth", or truly symmetric multi-writer?**
   - Symmetric multi-writer → per-file conflicts are possible → need a tool that
     keeps *both* copies (`.sync-conflict` / `.conflict`), plus version history.
   - Single source → a one-way mirror (`rclone sync`) is simpler, and `bisync`
     is overkill.
3. **Must sync keep working if the one "cloud"/hub is unreachable?**

---

## 2. Comparison

| | **Syncthing** (current) | **Object storage + rclone** |
|---|---|---|
| Sync model | P2P, real-time, always on | Central copy (bucket), manual/cron |
| Latency | instant on change | cadence of the cron / manual run |
| Hub role | an always-on node is the hub | the S3/object bucket is the hub |
| Multi-writer | keeps `.sync-conflict-…` both copies | `bisync` keeps `.conflict` both copies |
| Version/rollback | `simple` versioning (keep N) built-in | object bucket versioning, or `--backup-dir` |
| Conflicts (auto-merge) | **no** (both are kept) | **no** (both are kept) |
| Daemon | runs a service on each host | nothing persistent; cron triggers rclone |
| Privacy | private (own nodes) | depends on bucket (Aliyun/volcengine S3 = cloud) |
| Data loss risk | low (N copies kept) | low if versioning on; **higher** if using plain `sync` (it deletes) |
| Offline edits | fine; merged later | fine; needs bucket reachable to push/pull |
| Nix footprint | a host module per node | a `rclone` remote + cron/systemd timer per node |

**Key trap:** plain `rclone sync` **makes target equal source and can delete the
other machine's recent edits.** With symmetric multi-writer you must use
`rclone bisync` (or `copy`+keep), not `sync`.

---

## 3. Option A — Syncthing (recommended for "exactly Dropbox")

Keeps the current architecture (which was already in the repo) — nothing to buy.

- Every host runs a syncthing service; all share folders with the **same ID**;
  the always-on `server` is a send/receive hub.
- Real-time, automatic, works offline between edits.
- Conflicts are never lossy: both copies kept with `.sync-conflict-<ts>-<id>`;
  add `simple` versioning on the hub (keep N) for a rollback "recycle bin".

### Nix file layout (declarative, per host)

```
modules/network/syncthing.nix          # shared: enable + tailnet firewall (22000)
modules/hosts/<h>/syncthing.nix        # per host: settings, folders, versioning
```

```nix
# modules/hosts/server-lab-sardine/syncthing.nix  (hub)
services.syncthing = {
  enable = true;
  # folder shared with all clients under the same ID:
  settings.folders.sync = {
    path = "/srv/sync";
    label = "Sync";
    # versioning = Dropbox "recycle bin": keep the last 5 deleted/conflicted
    versioning = { type = "simple"; params.keep = "5"; };
  };
};
# + firewall: allow the data port on tailscale0 only.
```

Client folder (same ID `sync`, local path e.g. `~/Sync`):

```nix
services.syncthing.settings.folders.sync = {
  path = "/home/<you>/Sync";
  type = "sendreceive";           # any client may write, like Dropbox
  # ignore rules to cut down needless conflicts:
  ignorePatterns = [ ".git/**" "node_modules/**" "*.DS_Store" ".cache/**" ];
};
```

Peers can be added in the GUI (Syncthing presents them automatically), so Nix
only declares the folder + versioning + ignore rules — enough for a
Dropbox-like experience with almost no per-machine manual setup.

---

## 4. Option B — Object storage + rclone `bisync`

Choose when you want a **cloud/off-site reference copy** instead of relying on a
self-hosted node, or when you only need periodic (not live) sync.

- One authoritative bucket (we already have Aliyun / Volcengine S3 keys).
- `rclone bisync` each host → bucket, triggered by `systemd.timer` (avoid two
  hosts bisyncing concurrently; bisync must not run twice at once).
- `--backup-dir` (or bucket versioning) for the rollback safety net.

### Nix scheme

```nix
# declare the rclone remote config (via secrets, not plaintext)
rclone.remotes."sync".type = "s3";
rclone.remotes."sync".provider = "Aliyun";
# ... access_key_id / secret_access_key injected from agenix secrets

# per host: a timer that runs bisync
systemd.timers.sync = { wantedBy = [ "timers.target" ]; timerConfig.OnCalendar = "*-*-* *:07/15"; };
systemd.services.sync = {
  serviceConfig.ExecStart = "${pkgs.rclone}/bin/rclone bisync"
    + " sync:workdir ~/Sync --conflict-loser newer"
    + " --backup-dir sync:backup/$(date +%F)";
  serviceConfig.User = "you";
};
```

Notes: `bisync` must not overlap two hosts at once (single editor at a time is
fine, but concurrent runs from two hosts are not). `--conflict-loser newer` +
`--backup-dir` keeps both sides recoverable.

---

## 5. Recommendation

Pick **A (Syncthing)** for an actual Dropbox feel — it already fits, is
real-time, needs no cloud, and handles conflicts without losing data (`.conflict`
copies + versioning). This is the default.

Pick **B (rclone bisync)** only if a real off-site/cloud copy matters (disaster
recovery away from the lab) or you accept periodic sync and want zero on-box
daemon. If you go B, remember **`bisync`, not `sync`**.

The repo currently has syncthing **removed**; re-add Option A's module if you
decide A. If you decide B, add the `rclone` remote + timer above.