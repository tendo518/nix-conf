[[Category:Freedesktop.org]]
[[Category:Configuration files]]
[[Category:Development]]
[[de:XDG-Verzeichnisse#Base_Directorys]]
[[ja:XDG Base Directory]]
[[pt:XDG Base Directory]]
[[zh-hans:XDG 基本目录]]
{{Related articles start}}
{{Related|dotfiles}}
{{Related|XDG user directories}}
{{Related articles end}}

This article summarizes the [https://specifications.freedesktop.org/basedir-spec/latest/ XDG Base Directory specification] in [[#Specification]] and tracks software support in [[#Support]].

== Specification ==

Please read the [https://specifications.freedesktop.org/basedir-spec/latest/ full specification]. This section will attempt to break down the essence of what it tries to achieve.

Only {{ic|XDG_RUNTIME_DIR}} is set by default through {{man|8|pam_systemd}}. It is up to the user to explicitly define the other variables according to the specification. Changing it might cause issues with [[PipeWire#No sound devices show up in KDE Plasma|pipewire and screen sharing on chromium]].

See [[Environment variables#Globally]] for information on defining variables.

=== User directories ===

* {{ic|XDG_CONFIG_HOME}}
** Where user-specific configurations should be written (analogous to {{ic|/etc}}).
** Should default to {{ic|$HOME/.config}}.

* {{ic|XDG_CACHE_HOME}}
** Where user-specific non-essential (cached) data should be written (analogous to {{ic|/var/cache}}).
** Should default to {{ic|$HOME/.cache}}.

* {{ic|XDG_DATA_HOME}}
** Where user-specific data files should be written (analogous to {{ic|/usr/share}}).
** Should default to {{ic|$HOME/.local/share}}.

* {{ic|XDG_STATE_HOME}}
** Where user-specific state files should be written (analogous to {{ic|/var/lib}}).
** Should default to {{ic|$HOME/.local/state}}.

* {{ic|XDG_RUNTIME_DIR}}
** Used for non-essential, user-specific data files such as sockets, named pipes, etc.
** Not required to have a default value; warnings should be issued if not set or equivalents provided.
** Must be owned by the user with an access mode of {{ic|0700}}.
** Filesystem fully featured by standards of OS.
** Must be on the local filesystem.
** May be subject to periodic cleanup.
** Modified every 6 hours or set sticky bit if persistence is desired.
** Can only exist for the duration of the user's login.
** Should not store large files as it may be mounted as a tmpfs.
** pam_systemd sets this to {{ic|/run/user/$UID}}.

=== System directories ===

* {{ic|XDG_DATA_DIRS}}
** List of directories separated by {{ic|:}} (analogous to {{ic|PATH}}).
** Should default to {{ic|/usr/local/share:/usr/share}}.

* {{ic|XDG_CONFIG_DIRS}}
** List of directories separated by {{ic|:}} (analogous to {{ic|PATH}}).
** Should default to {{ic|/etc/xdg}}.

== Support ==

{{Out of date|some of these have gotten support now meaning that the ones in hardcoded/partial needs to be checked}}
{{Expansion|The current supported/partial/hardcoded split is not detailed enough and can be misleading. The tables could be merged into one (with more fields added on how the programs work with the specification) or differently named categories could be used.|section=Add description of support categories}}

This section exists to catalog the growing set of software using the [https://specifications.freedesktop.org/basedir-spec/latest/ XDG Base Directory Specification] introduced in 2003.
This is here to demonstrate the viability of this specification by listing commonly found dotfiles and their support status.
For those not currently supporting the Base Directory Specification, workarounds will be demonstrated to emulate it instead.

The workarounds will be limited to anything not involving patching the source, executing code stored in [[environment variables]] or compile-time options.
The rationale for this is that configurations should be portable across systems and having compile-time options prevent that.

Hopefully this will provide a source of information about exactly what certain kinds of dotfiles are and where they come from.

=== Contributing ===

When contributing make sure to use the correct section.

Nothing should require code evaluation, patches or compile-time options to gain support and anything which does must be deemed hardcoded.
Additionally, if the process is error prone or difficult, it should also be classified as hardcoded.

* The first column should be either a link to an internal article, a [[Template:Pkg]] or a [[Template:AUR]].
* The second column is for any legacy files and directories the project had (one per line), this is done so people can find them even if they are no longer read.
* In the third, try to find the commit or version a project switched to XDG Base Directory or any open discussions and include them in the next two columns (two per line).
* The last column should include any appropriate workarounds or solutions. Please verify that your solution is correct and functional.

=== Supported ===

{| class="wikitable sortable" style="width: 100%"
! Application
! Legacy Path
! Supported Since
! Discussion
! Notes
|-
| {{Pkg|act}}
| {{ic|~/.actrc}}
| [https://github.com/nektos/act/pull/1656 1656]
[https://github.com/nektos/act/pull/2195 2195]
| [https://github.com/nektos/act/issues/1678]
| {{ic|XDG_CONFIG_HOME/act/actrc}}
If present {{ic|~/.actrc}} will be merged with the XDG path config.
|-
| [[aerc]]
| 
| [https://git.sr.ht/~rjarry/aerc/commit/fff1664 fff1664]
|
| {{ic|XDG_CONFIG_HOME/aerc/aerc.conf}}
|-
| [[ALSA]]
| {{ic|~/.asoundrc}}
| [https://github.com/alsa-project/alsa-lib/commit/577df365f66ee09579864fc771136e690927b3bf 577df36]
[https://github.com/alsa-project/alsa-lib/releases/tag/v1.2.3 1.2.3]
| [https://github.com/alsa-project/alsa-lib/issues/49]
| {{ic|XDG_CONFIG_HOME/alsa/asoundrc}}
|-
| {{AUR|anaconda}}
| {{ic|~/.conda/.condarc}}, {{ic|~/.conda/condarc}}, {{ic|~/.conda/condarc.d/}}, {{ic|~/.condarc}}
| [https://github.com/conda/conda/blob/main/CHANGELOG.md#4110-2021-11-22 4.11.0]
| [https://conda.io/projects/conda/en/latest/user-guide/configuration/use-condarc.html#searching-for-condarc] [https://github.com/conda/conda/pull/10982]
|
|-
| [https://developer.android.com/studio/index.html Android Studio]
| {{ic|~/.AndroidStudioX.X}}
| [https://developer.android.com/studio/intro/studio-config#file_location Android Studio 4.1]
|
|
 XDG_CONFIG_HOME/Google/AndroidStudioX.X
 XDG_DATA_HOME/Google/AndroidStudioX.X
 XDG_CACHE_HOME/Google/AndroidStudioX.X
[https://developer.android.com/studio/intro/studio-config#file_location Location overview by Google] does not mention XDG - paths could be hardcoded instead of using the proper variable, though that is unlikely as Intellij IDEA, which Android Studio is based on, implements it properly as well
|-
| [[Anki]]
| {{ic|~/Anki}}, {{ic|~/Documents/Anki}}
|
| [https://github.com/dae/anki/pull/49] [https://github.com/dae/anki/pull/58] [https://docs.ankiweb.net/files.html]
| Uses {{ic|$XDG_DATA_HOME/Anki2}} as default if no older location exists, can be changed by using {{ic|1=anki -b <anki_dir>}}
|-
| {{Pkg|antimicrox}}
| {{ic|~/.antimicro}}, {{ic|~/.antimicrox}}
| [https://github.com/Antimicrox/antimicrox/commit/edba864 edba864]
| [https://github.com/Antimicro/antimicro/issues/5]
| 
|-
| {{AUR|apvlv}}
| {{ic|~/.apvlvrc}}
| [https://github.com/naihe2010/apvlv/commit/ed0e0112b05b0cafa13ca4e215ee559c82194caf]
| [https://github.com/naihe2010/apvlv/issues/70]
| Uses {{ic|XDG_CONFIG_HOME/apvlv/apvlvrc}} now if it exist.
|-
| [[aria2]]
| {{ic|~/.aria2}}
| [https://github.com/tatsuhiro-t/aria2/commit/8bc1d37 8bc1d37]
| [https://github.com/tatsuhiro-t/aria2/issues/27]
|
 XDG_CONFIG_HOME/aria2/
 XDG_CACHE_HOME/aria2/
|-
| {{AUR|asunder}}
| {{ic|~/.asunder}} {{ic|~/.asunder_album_artist}} {{ic|~/.asunder_album_genre}} {{ic|~/.asunder_album_title}}
| [https://littlesvr.ca/bugs/show_bug.cgi?id=31 2.9.0]{{Dead link|2021|05|17|status=SSL error}}
| [https://littlesvr.ca/bugs/show_bug.cgi?id=52]{{Dead link|2021|05|17|status=SSL error}}
| Uses {{ic|XDG_CONFIG_HOME/asunder/asunder}} for {{ic|~/.asunder}} and {{ic|XDG_CACHE_HOME/asunder/asunder_album_...}} for the other 3 files. Legacy paths are not removed after migration, they have to be deleted manually.
|-
| [https://dotnet.microsoft.com/en-us/apps/aspnet ASP.NET Core]
| {{ic|~/.aspnet}}
| [https://github.com/dotnet/aspnetcore/issues/43278]
|
|{{ic|~/.config/aspnet}}
|-
| {{Pkg|atuin}}
| {{ic|~/.config/atuin}} {{ic|~/.local/share/atuin}}
| [https://github.com/ellie/atuin/commit/156893d774b4da5b541fdbb08428f9ec392949a0 156893d]
|
|
 XDG_CONFIG_HOME/atuin/config.toml
 XDG_DATA_HOME/atuin/history.db
|-
| {{Pkg|audacity}}
| {{ic|~/.audacity-data/}}
| [https://github.com/audacity/audacity/releases/tag/Audacity-3.2.0 3.2.0]
| [https://bugzilla.audacityteam.org/show_bug.cgi?id=2201]
| Uses new locations if legacy do not exist:
 XDG_CONFIG_HOME/audacity
 XDG_DATA_HOME/audacity
|-
| {{Pkg|binwalk}}
| {{ic|~/.binwalk}}
| [https://github.com/ReFirmLabs/binwalk/commit/2051757 2051757]
| [https://github.com/ReFirmLabs/binwalk/issues/216]
| {{ic|XDG_CONFIG_HOME/binwalk}}
|-
| {{Pkg|bitwarden-cli}}
| {{ic|~/.config/Bitwarden CLI}}
| [https://github.com/bitwarden/cli/releases/tag/v1.7.1 1.7.1]
| [https://github.com/bitwarden/cli/pull/46]
|
 XDG_CONFIG_HOME/Bitwarden CLI

The {{ic|BITWARDENCLI_APPDATA_DIR}} environment variable takes precedence.

Currently contains a single {{ic|data.json}} file with all the vault data, so it ought to belong in {{ic|XDG_DATA_HOME}}
|-
| [[Blender]]
| {{ic|~/.blender}}
| [https://projects.blender.org/blender/blender/commit/4293f47 4293f47]
| [https://developer.blender.org/T28943]
|
|-
| [[borgmatic]]
| {{ic|~/.borgmatic/}}
| [https://projects.torsion.org/borgmatic-collective/borgmatic/releases/tag/1.9.0 1.9.0]
| [https://projects.torsion.org/borgmatic-collective/borgmatic/issues/562]
|
|-
| {{Pkg|btop}}
| 
| [https://github.com/aristocratos/btop/commit/b5e709d b5e709d]
| 
| {{ic|XDG_CONFIG_HOME/btop}}
|-
| {{AUR|byobu}}
| {{ic|~/.byobu}}
| [https://launchpad.net/byobu/+milestone/4.17 4.17]
| [https://bugs.launchpad.net/byobu/+bug/553105]
| 
{{ic|XDG_CONFIG_HOME/byobu}}

Legacy path takes precedence if present, or if {{ic|XDG_CONFIG_HOME}} is ''not'' set.
|-
| [https://www.haskell.org/cabal cabal]
| {{ic|~/.cabal/}}
| [https://github.com/haskell/cabal/commit/9f7dc55 9f7dc55] [https://github.com/haskell/cabal/releases/tag/cabal-install-v3.10.1.0 v3.10.1.0]
| [https://github.com/haskell/cabal/issues/680]
|
|-
| {{Pkg|calcurse}}
| {{ic|~/.calcurse}}
| [https://github.com/lfos/calcurse/commit/04162d 04162d]
| [https://github.com/lfos/calcurse/pull/254] [https://github.com/lfos/calcurse/issues/252]
|
 XDG_CONFIG_HOME/calcurse
 XDG_DATA_HOME/calcurse

If the legacy path {{ic|~/.calcurse}} is present, it will take precedence.
|-
| {{Pkg|calibre}}
|
|
|
|-
|{{AUR|celestia}}
| {{ic|~/.celestiarc}}
|
| [https://github.com/CelestiaProject/Celestia/pull/2133]
|
 XDG_CONFIG_HOME/celestia/celestiarc
|-
| {{Pkg|catfish}}
| {{ic|~/.config/catfish}}
| [https://gitlab.xfce.org/apps/catfish/-/commit/af65ed25c5d9bd96647664b5f7d4db50551fed8a af65ed25]
| [https://gitlab.xfce.org/apps/catfish/-/issues/102]
|
|-
| {{Pkg|ccache}}
| {{ic|~/.ccache}}
| [https://ccache.dev/releasenotes.html#_ccache_4_0 4.0]
| [https://github.com/ccache/ccache/issues/191]
|
 XDG_CACHE_HOME/ccache
 XDG_CONFIG_HOME/ccache/ccache.conf
|-
| [https://clangd.llvm.org/config.html clangd]
| {{ic|~/.clangd}}
| [https://github.com/llvm/llvm-project/commit/ad38f4b371bdca214e3a3cda9a76ec2213215c68 ad38f4b3] 11.0.0
| [https://github.com/clangd/clangd/issues/341]
| {{ic|XDG_CONFIG_HOME/clangd/config.yml}}

{{ic|XDG_CACHE_HOME/clangd}}

Project specific configuration can be specified in {{ic|proj/.clangd}}.
Configuration is combined when this is sensible. In case of conflicts, user config has the highest precedence, then inner project, then outer project.
|-
| {{AUR|clifm}}
| {{ic|~/.config/clifm/}}
| [https://github.com/leo-arch/clifm/commit/9d6e482a1d100306ea32fec0c088bce5d229f248 9d6e482]
|
| {{ic|XDG_CONFIG_HOME/clifm/}}
|-
| [[Composer]]
| {{ic|~/.composer}}
| [https://github.com/composer/composer/releases/tag/1.0.0-beta1 1.0.0-beta1]
| [https://github.com/composer/composer/pull/1407]
|
|-
| crossnote
| {{ic|~/.mume}}
| [https://github.com/shd101wyy/crossnote/commit/d714a8229c3a757d52a34eadabefb0795568e37d d714a82]
[https://github.com/shd101wyy/crossnote/archive/refs/tags/0.8.13.tar.gz 0.8.13]
| [https://github.com/shd101wyy/crossnote/pull/234]
| {{ic|$XDG_CONFIG_HOME/mume}}
If the legacy path is present, it will take precedence.
|-
| {{Pkg|ctags}} (universal-ctags)
| {{ic|~/.ctagsrc, .ctags.d}}
| [https://github.com/universal-ctags/ctags/commit/68da03a946cf532e51d014bc9b76265612da0189 68da03a]
[https://github.com/universal-ctags/ctags/commit/8fb0b0445c396a6a041106b752255e3ebe75533d 8fb0b04]
|[https://github.com/universal-ctags/ctags/issues/89 Issue 89]
[https://github.com/universal-ctags/ctags/pull/2384 Pull request 2384]

|At start-up time, Universal-ctags loads files having file`.ctags` as a file extension under: {{ic|$XDG_CONFIG_HOME/ctags}}

See [https://docs.ctags.io/en/latest/option-file.html Ctags Option files].
|-
| {{AUR|cryptomator}}
| {{ic|~/.Cryptomator}}
| [https://github.com/cryptomator/cryptomator/issues/710]
|
|{{ic|$XDG_CONFIG_HOME/Cryptomator}}
|-
| [[CUPS]]
| {{ic|~/.cups/}}
| [https://github.com/OpenPrinting/libcups/pull/45/commits/23b1be68803128ed701d374981c4583bcf9e7bf6 23b1be6]
| [https://github.com/OpenPrinting/cups/issues/10]
| libcups added XDG support in v3 (still in beta). The version in the official repositories is still hardcoded to {{ic|~/.cups}}.
|-
| [[cURL]]
| {{ic|~/.curlrc}}
| [https://curl.se/changes.html#7_73_0 7.73.0]
| [https://github.com/curl/curl/issues/5829]
| {{ic|XDG_CONFIG_HOME/curlrc}}
|-
| {{Pkg|dconf}}
|
|
|
|
|-
| [[Dolphin emulator]]
| {{ic|~/.dolphin-emu}}
| [https://github.com/dolphin-emu/dolphin/commit/a498c68 a498c68]
| [https://github.com/dolphin-emu/dolphin/pull/2304]
|
|-
| {{AUR|dr14_t.meter-git}}
|
| [https://github.com/simon-r/dr14_t.meter/commit/7e777ca 7e777ca]
| [https://github.com/simon-r/dr14_t.meter/pull/30]
| {{ic|XDG_CONFIG_HOME/dr14tmeter/}}
|-
| {{Pkg|dunst}}
|
| [https://github.com/dunst-project/dunst/commit/78b6e2b 78b6e2b]
| [https://github.com/dunst-project/dunst/issues/22]
| {{ic|XDG_CONFIG_HOME/dunst/}}
|-
| [[Emacs]]
| {{ic|~/.emacs}} {{ic|~/.emacs.d/init.el}}
| [https://git.savannah.gnu.org/cgit/emacs.git/commit/?id=4118297ae2fab4886b20d193ba511a229637aea3]
[https://www.gnu.org/savannah-checkouts/gnu/emacs/emacs.html#Releases 27.1]
|
| {{ic|XDG_CONFIG_HOME/emacs/init.el}}
Legacy paths have precedence over XDG paths.  Emacs will never create {{ic|XDG_CONFIG_HOME/emacs/}}.
Workaround for 26.3 or older: It's possible to set {{ic|HOME}}, but it has unexpected side effects.
|-
| [[Firefox]]
| {{ic|~/.mozilla/}}
| [https://www.firefox.com/en-US/firefox/147.0/releasenotes/ 147]
| [https://bugzilla.mozilla.org/show_bug.cgi?id=259356]
|
 XDG_CONFIG_HOME/mozilla/
The legacy path is used if {{ic|~/.mozilla/firefox}} is present. As of Firefox 147.0.2 there is a bug when using the XDG location:
* {{ic|native-messaging-hosts}} do not work [https://bugzilla.mozilla.org/show_bug.cgi?id=2005167].
|-
| [[fish]]
|
|
|
| {{ic|XDG_CONFIG_HOME/fish/}}
|-
| [https://github.com/rwestlund/freesweep freesweep]
| {{ic|~/.sweeprc}}
| [https://github.com/rwestlund/freesweep/pull/16]
|
|
|-
| {{Pkg|fltk}}
| {{ic|~/.fltk/}}
| [https://github.com/fltk/fltk/commit/7308bcdb74e34626c6459699cb57371afd7b343b 7308bcd]
| [https://www.fltk.org/str.php?L3370+P0+S0+C0+I0+E0+V%25+Qxdg]
| [https://www.fltk.org/doc-1.4/classFl__Preferences.html#af8418ff8af933d22dbb70a082525a74e]
|-
| [[fontconfig]]
| {{ic|~/.fontconfig}} {{ic|~/.fonts}}
| [https://gitlab.freedesktop.org/fontconfig/fontconfig/-/commit/8c255fb 8c255fb], [https://gitlab.freedesktop.org/fontconfig/fontconfig/-/commit/437f03299bd1adc9673cd576072f1657be8fd4e0]
|
| Config goes in {{ic|XDG_CONFIG_HOME/fontconfig/fonts.conf}} or {{ic|XDG_CONFIG_HOME/fontconfig/conf.d/}}, fonts are stored in {{ic|XDG_DATA_HOME/fonts/}}
|-
| {{Pkg|fontforge}}
| {{ic|~/.FontForge}} {{ic|~/.PfaEdit}}
| [https://github.com/fontforge/fontforge/commit/e4c2cc7 e4c2cc7]
|
[https://github.com/fontforge/fontforge/issues/847]
[https://github.com/fontforge/fontforge/issues/991]
|
|-
| {{Pkg|freecad}}
| {{ic|~/.FreeCAD}}
| [https://github.com/FreeCAD/FreeCAD/commit/e7e2994ba e7e2994ba]
[https://github.com/FreeCAD/FreeCAD/releases/tag/0.20 0.20.0]
| [https://forum.freecad.org/viewtopic.php?f=9&t=63648]
| Defaults to
 XDG_CONFIG_HOME/FreeCAD
 XDG_DATA_HOME/FreeCAD
 XDG_CACHE_HOME/FreeCAD
legacy path can be used with {{ic|FreeCAD --keep-deprecated-paths}}
|-
| {{Pkg|freerdp}}
| {{ic|~/.freerdp}}
| [https://github.com/FreeRDP/FreeRDP/commit/edf6e72 edf6e72]
|
|
|-
| [[Gajim]]
| {{ic|~/.gajim}}
| [https://dev.gajim.org/gajim/gajim/commit/3e777ea 3e777ea]
| [https://dev.gajim.org/gajim/gajim/issues/2149]
|
|-
| {{AUR|gconf}}
| {{ic|~/.gconf}}
| [https://gitlab.gnome.org/Archive/gconf/commit/fc28caa fc28caa]
| [https://bugzilla.gnome.org/show_bug.cgi?id=674803]
|
|-
| [[GDB]]
| {{ic|~/.gdbinit}}, {{ic|~/.gdb_history}}
| [https://lists.gnu.org/archive/html/info-gnu/2021-09/msg00007.html 11.1]
|
| {{ic|XDG_CONFIG_HOME/gdb/gdbinit}}, {{ic|1=export GDBHISTFILE="$XDG_DATA_HOME"/gdb/history}}
|-
| {{Pkg|ghc}}
| {{ic|~/.ghci}}
| [https://gitlab.haskell.org/ghc/ghc/-/commit/763d28551de32377a1dca8bdde02979e3686f400]
|
| Supported upstream from 9.4.1 [https://downloads.haskell.org/~ghc/9.4.1/docs/users_guide/9.4.1-notes.html?highlight=xdg].
|-
| {{Pkg|ghidra}}
| {{ic|~/.ghidra/}}
| [https://github.com/NationalSecurityAgency/ghidra/commit/3b0aac92d0730bb3eaa25d276d15beeef3f55c23 3b0aac9]
| [https://github.com/NationalSecurityAgency/ghidra/issues/908]
| 
|-
| [[GIMP]]
| {{ic|~/.gimp-x.y}} {{ic|~/.thumbnails}}
|
[https://gitlab.gnome.org/GNOME/gimp/commit/60e0cfe 60e0cfe]
[https://gitlab.gnome.org/GNOME/gimp/commit/483505f 483505f]
|
[https://bugzilla.gnome.org/show_bug.cgi?id=166643]
[https://bugzilla.gnome.org/show_bug.cgi?id=646644]
|
|-
| [[Git]]
| {{ic|~/.gitconfig}}, {{ic|~/.gitignore}}, {{ic|~/.gitattributes}}, {{ic|~/.git-credentials}}, {{ic|~/.gitk}}
| [https://github.com/git/git/commit/0d94427 0d94427], [https://github.com/git/git/commit/dc79687 dc79687], [https://github.com/git/git/commit/684e40f 684e40f]
| [https://git-scm.com/docs/git-config Git Config], [https://git-scm.com/docs/gitattributes Git Attributes], [https://git-scm.com/docs/git-credential-store Git Credentials], [https://git-scm.com/docs/gitk gitk] 
| {{ic|XDG_CONFIG_HOME/git/config}}, {{ic|XDG_CONFIG_HOME/git/ignore}}, {{ic|XDG_CONFIG_HOME/git/attributes}}, {{ic|XDG_CONFIG_HOME/git/credentials}}, {{ic|XDG_CONFIG_HOME/git/gitk}}
|-
| [[Wikipedia:gnuplot|gnuplot]]
| {{ic|~/.gnuplot_history}}
| [https://sourceforge.net/p/gnuplot/gnuplot-main/ci/a5562b1/ a5562b1]
[https://sourceforge.net/p/gnuplot/gnuplot-main/merge-requests/12/]
|
|
|-
| [[Godot Engine]]
| {{ic|~/.godot}}
| [https://github.com/godotengine/godot/pull/12988/commits/73049d115e190b8c356f0689a9079c3c73cc5765 73049d1]
[https://github.com/godotengine/godot/releases/tag/3.0-stable 3.0-stable]
| [https://github.com/godotengine/godot/issues/3513]
|
|-
| {{AUR|goobook}}
| {{ic|~/.goobookrc}}
| [https://gitlab.com/goobook/goobook/-/blob/master/CHANGES.rst 3.5]
| [https://gitlab.com/goobook/goobook/-/merge_requests/11]
| {{ic|XDG_CONFIG_HOME/goobookrc}}
|-
| [https://github.com/google/gops gops]
|
| [https://github.com/google/gops/commit/71c4255 71c4255]
|
|
|-
| [[GoldenDict]]
| {{ic|~/.goldendict/}}
| [https://github.com/goldendict/goldendict/pull/1411]	
|
|{{ic|$XDG_CONFIG_HOME/goldendict/.goldendict/}}
|-
| [[GStreamer]]
| {{ic|~/.gstreamer-0.10}}
| [https://gitlab.freedesktop.org/gstreamer/gstreamer/-/commit/4e36f93 4e36f93]
| [https://bugzilla.gnome.org/show_bug.cgi?id=518597]
|
|-
| [[GTK]] 3
|
|
|
|
|-
| [[Haskell#Stack]]
| {{ic|~/.stack}}
| [https://github.com/commercialhaskell/stack/releases/tag/v2.9.3 2.9.3]
| [https://github.com/commercialhaskell/stack/issues/4243]
| Defaults to legacy. Use {{ic|1=export STACK_XDG=1}} to make it compliant with the spec.
The old method of {{ic|1=export STACK_ROOT="$XDG_DATA_HOME"/stack}} still works and takes priority [https://docs.haskellstack.org/en/stable/environment_variables/#stack_xdg]{{Dead link|2024|07|30|status=404}}.
|-
| {{Pkg|helm}}
| {{ic|~/.helm}}
| [https://github.com/helm/helm/releases/tag/v3.0.0 3.0.0]
|
|
|-
| {{Pkg|htop}}
| {{ic|~/.htoprc}}
| [https://github.com/hishamhm/htop/commit/93233a6 93233a6]
|
| {{ic|XDG_CONFIG_HOME/htop/htoprc}}
|-
| {{Pkg|httpie}}
| {{ic|~/.httpie}}
| [https://github.com/httpie/httpie/commit/5af0874ed302e9ef79cec97836529ccf353e53f7 5af0874]
| [https://github.com/httpie/httpie/issues/145]
|
|-
| {{Pkg|hunspell}}
| {{ic|~/.hunspell_default.}}
| 
| [https://github.com/hunspell/hunspell/pull/637]
|
|-
| [[i3]]
| {{ic|~/.i3}}
| [http://code.stapelberg.de/git/i3/commit/?id=7c130fb 7c130fb]{{Dead link|2025|08|16|status=404}}
|
|
|-
| {{Pkg|i3blocks}}, {{AUR|i3blocks-git}}
|
| [https://github.com/vivien/i3blocks/commit/a1782404c7d933145b048d0d1872ea40d7a293b6]
|
|
|-
| {{Pkg|i3status}}
| {{ic|~/.i3status.conf}}
| [http://code.stapelberg.de/git/i3status/commit/?id=c3f7fc4 c3f7fc4]{{Dead link|2025|08|16|status=404}}
|
|
|-
| {{Pkg|i3status-rust}}
|
|
|
|
|-
| [https://github.com/JetBrains/ideavim IdeaVim]
| {{ic|~/.ideavimrc}}
| [https://github.com/JetBrains/ideavim/pull/212 0.54.1-EAP]
| [https://youtrack.jetbrains.com/issue/VIM-664]
| {{ic|XDG_CONFIG_HOME/ideavim/ideavimrc}}
|-
| {{Pkg|imagemagick}}
|
|
|
|
|-
| [[Inkscape]]
| {{ic|~/.inkscape}}
| [https://wiki.inkscape.org/wiki/index.php/Release_notes/0.47#Preferences 0.47]
| [https://bugs.launchpad.net/inkscape/+bug/199720]
|
|-
| {{Pkg|intellij-idea-community-edition}} /  {{AUR|intellij-idea-ultimate-edition}}
| {{ic|~/.IntelliJIdeaXXXX.X}}
| [https://confluence.jetbrains.com/display/IDEADEV/IntelliJ%2BIDEA%2B2020.1%2B%28201.6668.121%2Bbuild%29%2BRelease%2BNotes 2020.1]
| [https://youtrack.jetbrains.com/issue/IDEA-22407]
|
 XDG_CONFIG_HOME/JetBrains/IntelliJIdeaXXXX.X
 XDG_DATA_HOME/JetBrains/IntelliJIdeaXXXX.X
 XDG_CACHE_HOME/JetBrains/IntelliJIdeaXXXX.X
|-
| {{Pkg|iotop-c}}
| {{ic|~/.config/iotop}}
|[https://github.com/Tomas-M/iotop/commit/cea6d5c7a41f2e7a842d4f244532759142af98b0]
|[https://github.com/Tomas-M/iotop/issues/63]
|
|-
| [https://ipython.org ipython]
| {{ic|~/.ipython}}
| [https://ipython.readthedocs.io/en/stable/whatsnew/version8.html#re-added-support-for-xdg-config-directories 8.0.0]
| [https://github.com/ipython/ipython/pull/13224]
| Checks if {{ic|$XDG_CONFIG_HOME/ipython}} (or {{ic|~/.config/ipython}} if {{ic|XDG_CONFIG_HOME}} is unset) exists, otherwise it uses {{ic|~/.ipython}}.
|-
| [https://iwd.wiki.kernel.org/ iwd] / iwctl
| {{ic|~/.iwctl_history}}
| [https://git.kernel.org/pub/scm/network/wireless/iwd.git/commit/?id=d3e00d7f d3e00d7f]
|
|
|-
| {{Pkg|josm}}
| {{ic|~/.josm}}
| [https://josm.openstreetmap.de/changeset/11162/josm 11162]
| [https://josm.openstreetmap.de/ticket/6664]
|
|-
| [https://github.com/jupyter jupyter]
| {{ic|~/.jupyter}}
| opt-in in 5.0, opt-out in 6.0, compulsory in 7.0 ([https://github.com/jupyter/jupyter_core/blob/f5ab1ac19225c7925282e9c5ae466767b4086361/CHANGELOG.md#migrate-to-standard-platform-directories changelog])
| 
| {{ic|XDG_CONFIG_HOME/jupyter}}
|-
| [[Kakoune]]
|
|
|
|
|-
| {{AUR|keynav}}
| {{ic|~/.keynavrc}}
|
|
| {{ic|XDG_CONFIG_HOME/keynav/keynavrc}}
|-
| latexmk (in {{Pkg|texlive-binextra}})
| {{ic|~/.latexmkrc}}
|
|
|
{{ic|XDG_CONFIG_HOME/latexmk/latexmkrc}}
|-
| [[Core utilities|less]]
| {{ic|~/.lesskey}}, {{ic|~/.lesshst}}
| [https://www.greenwoodsoftware.com/less/news.590.html 590]
full support in [https://www.greenwoodsoftware.com/less/news.598.html 598]
| [https://github.com/gwsw/less/issues/153]
| The environment variables {{ic|XDG_CONFIG_HOME}} and {{ic|XDG_DATA_HOME}} '''must''' be set in version 590. In version 598 this is no longer necessary.  
{{ic|XDG_CONFIG_HOME/lesskey}}

{{ic|XDG_STATE_HOME/lesshst}} or {{ic|XDG_DATA_HOME/lesshst}}
|-
| {{Pkg|lftp}}
| {{ic|~/.lftp}}
| [https://github.com/lavv17/lftp/commit/21dc400 21dc400]
| [https://www.mail-archive.com/lftp@uniyar.ac.ru/msg04301.html]
|
|-
| {{AUR|lgogdownloader}}
| {{ic|~/.gogdownloader}}
| [https://github.com/Sude-/lgogdownloader/commit/d430af6 d430af6]
| [https://github.com/Sude-/lgogdownloader/issues/4]
|
|-
| {{AUR|librewolf}}
| {{ic|~/.librewolf}}
| [https://codeberg.org/librewolf/source/pulls/120/commits/587de521efe95755bee72246ffe6c7f94a95f49a 587de52]
| [https://codeberg.org/librewolf/issues/issues/2682]
| The legacy path is used if ~/.librewolf is present. As of Librewolf 147.0.2 there is a bug when using the XDG location (upstream Firefox issue listed):
* {{ic|native-messaging-hosts}} do not work [https://bugzilla.mozilla.org/show_bug.cgi?id=2005167].
[https://codeberg.org/librewolf/issues/issues/2682#issuecomment-9768230]
|-
| {{Pkg|luarocks}}
| {{ic|~/.luarocks}}
| [https://github.com/luarocks/luarocks/pull/1298/commits/cd16cdd5f889024f28cc384e3d721a4f4a3261d3 cd16cdd]
| [https://github.com/luarocks/luarocks/pull/1298]
|
 XDG_CONFIG_HOME/luarocks
 XDG_CACHE_HOME/luarocks

If the legacy path {{ic|~/.luarocks}} is present, it will take precedence.
|-
| {{Pkg|mangohud}}
|
| [https://github.com/flightlessmango/MangoHud/commit/65b90fc 65b90fc]
| [https://github.com/flightlessmango/MangoHud/issues/37]
| {{ic|XDG_CONFIG_HOME/MangoHud}}
|-
| [[mc]]
| {{ic|~/.mc}}
|
[https://github.com/MidnightCommander/mc/commit/1b99570 1b99570]
[https://github.com/MidnightCommander/mc/commit/0b71156 0b71156]
[https://github.com/MidnightCommander/mc/commit/ce401d7 ce401d7]
| [https://www.midnight-commander.org/ticket/1851]
|
|-
| [[Mercurial]]
| {{ic|~/.hgrc}}
|
[https://www.mercurial-scm.org/repo/hg/rev/3540200 3540200]
[https://www.mercurial-scm.org/wiki/Release4.2 4.2]
|
| {{ic|XDG_CONFIG_HOME/hg/hgrc}}.
|-
| {{Pkg|mesa}}
|
| [https://gitlab.freedesktop.org/mesa/mesa/-/commit/87ab26b 87ab26b]
|
| {{ic|XDG_CACHE_HOME/mesa}}
|-
| {{Pkg|milkytracker}}
| {{ic|~/.milkytracker_config}}
| [https://github.com/Deltafire/MilkyTracker/commit/eb487c5 eb487c5]
| [https://github.com/Deltafire/MilkyTracker/issues/12]
|
|-
| [[mlterm]]
| {{ic|~/.mlterm/}}
| [https://github.com/arakiken/mlterm/commit/71df0714edc7715524092213516790a24178615b 71df071]
| [https://github.com/arakiken/mlterm/issues/42]
| {{ic|XDG_CONFIG_HOME/mlterm/}}
|-
| [[mozc]]
| {{ic|~/.mozc}}
| [https://github.com/google/mozc/commit/91cc1e19ef34aeb12888b697fefa52907f1a834d 91cc1e1]
| [https://github.com/google/mozc/issues/474]
|
|-
| [[mpd]]
| {{ic|~/.mpdconf}}
| [https://github.com/MusicPlayerDaemon/MPD/commit/87b7328 87b7328]
|
|
|-
| [[mpv]]
| {{ic|~/.mpv}}
| [https://github.com/mpv-player/mpv/commit/cb250d4 cb250d4]
| [https://github.com/mpv-player/mpv/pull/864]
|
|-
| [[msmtp]]
| {{ic|~/.msmtprc}}
|
[https://github.com/marlam/msmtp-mirror/commit/af2f409 af2f409]
v1.6.7+
|
| {{ic| XDG_CONFIG_HOME/msmtp/config}}.
|-
| [[mutt]]
| {{ic|~/.mutt}}
| [https://gitlab.com/muttmua/mutt/commit/b17cd67 b17cd67]
| [https://gitlab.com/muttmua/trac-tickets/raw/master/tickets/closed/3207-Conform_to_XDG_Base_Directory_Specification.txt]
|
|-
| {{Pkg|mypaint}}
| {{ic|~/.mypaint}}
| [https://github.com/mypaint/mypaint/commit/cf723b7 cf723b7]
|
|
|-
| [[nano]]
| {{ic|~/.nano/}} {{ic|~/.nanorc}}
| [https://git.savannah.gnu.org/cgit/nano.git/commit/?id=c16e79b c16e79b]
| [https://savannah.gnu.org/patch/?8523]
|
|-
| [[ncmpcpp]]
| {{ic|~/.ncmpcpp}} {{ic|~/.lyrics}}
|
[https://github.com/arybczak/ncmpcpp/commit/38d9f81 38d9f81]
[https://github.com/arybczak/ncmpcpp/commit/27cd86e 27cd86e]
|
[https://github.com/arybczak/ncmpcpp/issues/79]
[https://github.com/arybczak/ncmpcpp/issues/110]
[https://github.com/ncmpcpp/ncmpcpp/issues/574]
| {{ic|ncmpcpp_directory}} should be set to avoid an {{ic|error.log}} file in {{ic|~/.ncmpcpp}}. And {{ic|lyrics_directory}} can be set to {{ic|~/.cache/ncmpcpp-lyrics}} to avoid {{ic|~/.lyrics}}.
|-
| [[Neovim]]
| {{ic|~/.nvim}} {{ic|~/.nvimlog}} {{ic|~/.nviminfo}}
| [https://github.com/neovim/neovim/commit/1ca5646bb 1ca5646bb]
|
[https://github.com/neovim/neovim/issues/78]
[https://github.com/neovim/neovim/pull/3198]
|
|-
| [http://0ldsk00l.ca/nestopia/ Nestopia UE]
| {{ic|~/.nestopia/}}
| [https://github.com/0ldsk00l/nestopia/commit/d78381198a26a10333128e9bf28bc530a610c008 610c008] [https://github.com/0ldsk00l/nestopia/releases/tag/1.51.0 1.51.0]
| [https://github.com/0ldsk00l/nestopia/issues/343]
|
|-
| [[Networkmanager-openvpn]]
| {{ic|~/.cert/nm-openvpn}}
| [https://gitlab.gnome.org/GNOME/NetworkManager-openvpn/-/tags/1.12.1 1.12.1]
| [https://gitlab.gnome.org/GNOME/NetworkManager-openvpn/-/merge_requests/95]
|
|-
| [[newsboat]]
| {{ic|~/.newsboat}}
| [https://github.com/akrennmair/newsbeuter/commit/3c57824 3c57824]
| [https://github.com/akrennmair/newsbeuter/pull/39]
| It is required to create both directories [https://man.archlinux.org/man/newsboat.1#FILES]:

{{ic|1=mkdir -p "$XDG_DATA_HOME"/newsboat "$XDG_CONFIG_HOME"/newsboat}}
|-
| [[Nix]]
| {{ic|~/.nix-channels}} {{ic|~/.nix-defexpr}} {{ic|~/.nix-profile}}
| [https://github.com/NixOS/nix/issues/1079]
| [https://github.com/NixOS/nix/pull/5588]
| Set {{ic|use-xdg-base-directories {{=}} true}} in your {{ic|/etc/nix/nix.conf}}
|-
| [[NetworkManager|nmcli]]
| {{ic|~/.nmcli-history}}
| [https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/blob/1.52.0/NEWS?ref_type=tags 1.52.0]
| [https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/64] [https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/merge_requests/2027] [https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/1615]
| {{ic|XDG_CACHE_HOME/nmcli-history}}
|-
| [https://github.com/nodejs/node-gyp node-gyp]
| {{ic|~/.node-gyp}}
| [https://github.com/nodejs/node-gyp/commit/2b5ce52a 2b5ce52a]
| [https://github.com/nodejs/node-gyp/pull/1570]
|
|-
| [[notmuch]]
| {{ic|~/.notmuch-config}}
|
| [https://notmuchmail.org/pipermail/notmuch/2011/007007.html]
| {{ic|mkdir -p $XDG_CONFIG_HOME/notmuch/default; mv ~/.notmuch-config $XDG_CONFIG_HOME/notmuch/default/config}}
|-
| {{AUR|np2kai-git}}
| {{ic|~/.config/np2kai}} {{ic|~/.config/xnp2kai}}
| [https://github.com/AZO234/NP2kai/commit/56a1cc2 56a1cc2]
| [https://github.com/AZO234/NP2kai/pull/50]
|
|-
| [https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS NSS]
| {{ic|~/.pki}}
| [https://hg.mozilla.org/projects/nss/rev/da45424cb9a0b4d8e45e5040e2e3b574d994e254 3.42 (da45424)]
| [https://bugzilla.mozilla.org/show_bug.cgi?id=818686]
| See Chromium for existing issue.
|-

| {{AUR|nteract-bin}}
|
| [https://github.com/nteract/nteract/commit/4593e72 4593e72]
| [https://github.com/nteract/nteract/issues/180] [https://github.com/nteract/nteract/pull/3870]
| [https://github.com/nteract/nteract/issues/4517 does not recognize workarounds for ipython/jupyter]
|-
| {{AUR|ocaml-utop}}
| {{ic|~/.utop-history}}
{{ic|~/.utoprc}}
| [https://github.com/ocaml-community/utop/releases/tag/2.13.0 2.13.0]
[https://github.com/ocaml-community/utop/commit/9729963 9729963]
| [https://github.com/ocaml-community/utop/pull/431]
| {{ic|XDG_STATE_HOME/utop/utop-history}}
{{ic|XDG_CONFIG_HOME/utop/utoprc}}
|-
| [[OfflineIMAP]]
| {{ic|~/.offlineimaprc}}
| [https://github.com/OfflineIMAP/offlineimap/commit/5150de5 5150de5]
| [https://github.com/OfflineIMAP/offlineimap/issues/32]
| {{ic|XDG_CONFIG_HOME/offlineimap/config}}
|-
| {{Pkg|openal}}
| {{ic|~/.alsoftrc}}
| [https://github.com/kcat/openal-soft/commit/3c90ed95afa1feed70e6c5655cfeec096c00c23b 3c90ed9]
| 
| {{ic|XDG_CONFIG_HOME/alsoft.conf}}
|-
| {{AUR|opentyrian}}
| {{ic|~/.opentyrian}}
| [https://github.com/opentyrian/opentyrian/commit/39559c3 39559c3]
| [https://web.archive.org/web/20140815181350/http://code.google.com/p/opentyrian/issues/detail?id=125]
|
|-
| {{AUR|osc}}
| {{ic|~/.oscrc}} {{ic|~/.osc_cookiejar}} 
| [https://github.com/openSUSE/osc/commit/6bc2d3f939c2518ae555fbf75e3a11cc16fc5302 6bc2d3f]
[https://github.com/openSUSE/osc/commit/ebcf3de6abe1ae142baa5bee4c9867cc1968bad1 ebcf3de]
|[https://github.com/openSUSE/osc/pull/940 github.com/openSUSE/osc/pull/940]
[https://github.com/openSUSE/osc/pull/940 github.com/osc/pull/940]
|
{{ic|XDG_CONFIG_HOME/osc/oscrc}}
{{ic|XDG_STATE_HOME/osc/cookiejar}}

Legacy path takes precedence if it exists
|-
| [[pacman]]
| {{ic|~/.makepkg.conf}}
| [https://gitlab.archlinux.org/pacman/pacman/commit/80eca94 80eca94]
| [https://lists.archlinux.org/archives/list/pacman-dev@lists.archlinux.org/thread/KTD2FW7YKY724UB7PT3GGP5L7TNWZYEP/]
|
|-
| {{Pkg|pam-u2f}}
| {{ic|~/.config/Yubico/u2f_keys}}
| [https://github.com/Yubico/pam-u2f/commit/ad52dd82dead525dab94ded1916dcf6334459106 ad52dd8]
| [https://github.com/Yubico/pam-u2f/issues/9]
| {{ic|XDG_CONFIG_HOME/Yubico/u2f_keys}}
|-
| {{AUR|panda3d}}
| {{ic|~/.panda3d}}
| [https://github.com/panda3d/panda3d/commit/2b537d2 2b537d2]
|
|
|-
| {{Pkg|pandoc-cli}}
| {{ic|~/.pandoc/}}
| [https://github.com/jgm/pandoc/commit/0bed0ab5a308f5e72a01fa9bee76488556288862 0bed0ab]
| [https://github.com/jgm/pandoc/issues/3582]
|
|-
| [[PCManFM]]
| {{ic|~/.thumbnails}}
| [https://github.com/lxde/libfm/issues/57 1.3.2]
|
|
|-
| {{AUR|pcsx2}}
| {{ic|~/.pcsx2}}
|
[https://github.com/PCSX2/pcsx2/commit/87f1e8f 87f1e8f]
[https://github.com/PCSX2/pcsx2/commit/a9020c6 a9020c6]
[https://github.com/PCSX2/pcsx2/commit/3b22f0f 3b22f0f]
[https://github.com/PCSX2/pcsx2/commit/0a012ae 0a012ae]
| [https://github.com/PCSX2/pcsx2/issues/352] [https://github.com/PCSX2/pcsx2/issues/381]
| 
|-
| {{AUR|pdfsam}}
| {{ic|~/.openjfx}}
|
|
| {{ic|1=export _JAVA_OPTIONS=-Djavafx.cachedir="$XDG_CACHE_HOME"/openjfx}}
|-
| {{Pkg|pnpm}}
| {{ic|~/.pnpm-store}}
| [https://github.com/pnpm/pnpm/pull/3873] [https://github.com/pnpm/pnpm/pull/4522]
| [https://github.com/pnpm/pnpm/issues/2574]
|
|-
| {{AUR|poezio}}
|
|
|
|
|-
| {{AUR|powershell}}
|
| [https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-core-60#filesystem 6.0]
|
|
|-
| {{Pkg|ppsspp}}
| {{ic|~/.ppsspp}}
| [https://github.com/hrydgard/ppsspp/commit/132fe47 132fe47]
| [https://github.com/hrydgard/ppsspp/issues/4623]
|
|-
| {{Pkg|procps-ng}}
| {{ic|~/.toprc}}
| [https://gitlab.com/procps-ng/procps/commit/af53e17 af53e17]
|
[https://gitlab.com/procps-ng/procps/merge_requests/38]
[https://bugzilla.redhat.com/show_bug.cgi?id=1155265]
|
|-
| [https://pry.github.io/ Pry]
| {{ic|~/.pryrc}} {{ic|~/.pry_history}}
|
[https://github.com/pry/pry/commit/a0be0cc7b2070edff61c0c7f10fa37fce9b730bd a0be0cc7]
[https://github.com/pry/pry/commit/15e1fc929ed84c161abc5afc9be73488a41df397 15e1fc92]
[https://github.com/pry/pry/commit/e9d1be0e17b294318dbb2f70f74a50486cfa044c e9d1be0e]
| [https://github.com/pry/pry/issues/1316]
|
|-
| [[PulseAudio]]
| {{ic|~/.pulse}} {{ic|~/.pulse-cookie}}
|
[https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/59a8618 59a8618]
[https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/87ae830 87ae830]
[https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/9ab510a 9ab510a]
[https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/4c195bc 4c195bc]
| [https://bugzilla.redhat.com/show_bug.cgi?id=845607]
| 
 XDG_CONFIG_DIR/pulse
 XDG_CONFIG_DIR/pulse/cookie
|-
| {{AUR|pyroom}}
|
|
|
|
|-
| {{AUR|python-autoimport}}
| {{ic|~/.config/autoimport/config.toml}}
| [https://github.com/lyz-code/autoimport/pull/206 1.2.0]
| [https://github.com/lyz-code/autoimport/pull/172]
| {{ic|XDG_CONFIG_HOME/autoimport/config.toml}}
|-
| {{Pkg|python-black}}
| {{ic|~/.config/black}}
| [https://github.com/psf/black/pull/1899 21.4b0]
| [https://github.com/psf/black/issues/1577]
| {{ic|XDG_CONFIG_HOME/black}}, {{ic|XDG_CACHE_HOME/black/<version>/}}
|-
| {{Pkg|python-pip}}
| {{ic|~/.pip}}
| [https://github.com/pypa/pip/blob/548a9136525815dff41acd845c558a0b36eb1c5f/NEWS.rst#60-2014-12-22 6.0]
| [https://github.com/pypa/pip/issues/1733]
|
|-
| {{Pkg|python-pipx}}
| {{ic|~/.local/pipx}}
| [https://github.com/pypa/pipx/pull/1001 c3d8de9]
| [https://github.com/pypa/pipx/issues/722]
| For compatibility, pipx will revert to {{ic|~/.local/pipx}} if it exists. Implemented using {{Pkg|python-platformdirs}}
|-
| {{Pkg|python-poetry}}
| {{ic|~/.poetry}}
| [https://github.com/python-poetry/poetry/pull/3706]
| [https://github.com/python-poetry/poetry/issues/2148]
|
|-
| {{Pkg|python-pylint}}
| {{ic|~/.pylint.d}}
| [https://github.com/PyCQA/pylint/pull/4661 2.10]
| [https://github.com/PyCQA/pylint/issues/1364]
| Formerly {{ic|1=export PYLINTHOME="$XDG_CACHE_HOME"/pylint}}, global config still needs: {{ic|1=export PYLINTRC="$XDG_CONFIG_HOME"/pylint/pylintrc}}
|-
| {{Pkg|quodlibet}}
| {{ic|~/.quodlibet}}
| 3.10.0
| [https://github.com/quodlibet/quodlibet/issues/138]
|
|-
| [[qutebrowser]]
|
|
|
|
|-
| [[qtile]]
|
|
[https://github.com/qtile/qtile/commit/fd8686e fd8686e]
[https://github.com/qtile/qtile/commit/66d704b 66d704b]
[https://github.com/qtile/qtile/commit/51cff01 51cff01]
| [https://github.com/qtile/qtile/pull/835]
| Some optional bar widgets can create files and directories in non-compliant paths, but most often these are still configurable.
|-
| {{Pkg|rclone}}
| {{ic|~/.rclone.conf}}
| [https://github.com/ncw/rclone/commit/9d36258 9d36258]
| [https://github.com/ncw/rclone/issues/868]
|
|-
| {{Pkg|retroarch}}
|
|
|
|
|-
| {{Pkg|ripgrep-all}}
| {{ic|~/.cache/rga}}
| [https://github.com/phiresky/ripgrep-all/commit/963524bbf5ec861cc1d9d2b57e119eb60125751a 963524b] [https://github.com/phiresky/ripgrep-all/releases/tag/v0.10.3 v0.10.3]
| [https://github.com/phiresky/ripgrep-all/issues/87] [https://github.com/phiresky/ripgrep-all/issues/102] [https://github.com/phiresky/ripgrep-all/issues/129]
|
|-
| {{AUR|rr}}
| {{ic|~/.rr}}
| [https://github.com/mozilla/rr/commit/02e7d41 02e7d41]
| [https://github.com/mozilla/rr/issues/1455]
|
|-
| [https://rspec.info RSpec]
| {{ic|~/.rspec}}
| [https://github.com/rspec/rspec-core/commit/5e395e2016f1da19475e6db2817eb26dae828c4c 5e395e2]
| [https://github.com/rspec/rspec-core/issues/1773]
|
|-
| [[rTorrent]]
| {{ic|~/.rtorrent.rc}}
| [https://github.com/rakshasa/rtorrent/commit/6a8d332 6a8d332]
|
|
|-
| [https://www.rubocop.org RuboCop]
| {{ic|~/.rubocop.yml}}
| [https://github.com/rubocop-hq/rubocop/commit/6fe5956c177ca369cfaa70bdf748b70020a56bf4 6fe5956]
| [https://github.com/rubocop-hq/rubocop/issues/6662]
|
|- 
| [[Ruby#RubyGems]]
| {{ic|~/.gem}}
| [https://github.com/ruby/ruby/commit/5c6269c 3.0.0 (5c6269c)]
| [https://github.com/ruby/ruby/pull/2174]
|
 XDG_CONFIG_HOME/gem/gemrc
 XDG_CONFIG_HOME/irb
 XDG_DATA_HOME/gem
 XDG_DATA_HOME/rdoc
|-
| [https://github.com/benvan/sandboxd sandboxd]
| {{ic|~/.sandboxrc}}
| [https://github.com/benvan/sandboxd/pull/14]
| [https://github.com/benvan/sandboxd/issues/11]
| {{ic|XDG_CONFIG_HOME/sandboxd/sandboxrc}}
|-
| {{Pkg|scribus}}
| {{ic|~/.scribus}}
| [https://wiki.scribus.net/canvas/Versione_1.5.3 1.5.3]
|
|
|-
| {{Pkg|scummvm}}
| {{ic|~/.scummvmrc}} {{ic|~/.scummvm/}}
| [https://github.com/scummvm/scummvm/commit/7d014be0a2b796175a7ce40a9315603f711b2a30 7d014be]
| [https://github.com/scummvm/scummvm/pull/656]
| It is required to migrate data by hand.
{{ic|mkdir "$XDG_CONFIG_HOME"/scummvm/ "$XDG_DATA_HOME"/scummvm}}
{{ic|mv ~/.scummvmrc "$XDG_CONFIG_HOME"/scummvm/scummvm.ini}}
{{ic|mv ~/.scummvm "$XDG_DATA_HOME"/scummvm/saves}}
|-
| {{Pkg|sdcv}}
| {{ic|~/.stardict/}} {{ic|~/.sdcv_history}}
| [https://github.com/Dushistov/sdcv/commit/958ec35 958ec35]
| [https://github.com/Dushistov/sdcv/issues/51]
|
|-
| {{Pkg|shellcheck}}
| {{ic|~/.shellcheckrc}}
|[https://github.com/koalaman/shellcheck/commit/581bcc3907ab98e919a7dd60566810a928c46b95 581bcc3]
| 
| {{ic|XDG_CONFIG_HOME/shellcheckrc}}
See [https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md#rc-files Shellcheck RC Files] for more info.
|-
| {{Pkg|snes9x}}
| {{ic|~/.snes9x}}
| [https://github.com/snes9xgit/snes9x/commit/93b5f11 93b5f11]
| [https://github.com/snes9xgit/snes9x/issues/194]
| By default, the configuration file is left blank with intention that the user will fill it at their will (through the gui or manually).
|-
| [[spectrwm]]
| {{ic|~/.spectrwm}}
| [https://github.com/conformal/spectrwm/commit/a30bbb a30bbb]
| [https://github.com/conformal/spectrwm/pull/153]
|
|-
| {{AUR|sublime-text-dev}}
|
| [https://www.sublimetext.com/dev build 4105]
|
| Prior to build 4105, the cache was placed in {{ic|XDG_CONFIG_HOME/sublime-text-3/Cache}}.
|-
| [[surfraw]]
| {{ic|~/.surfraw.conf}} {{ic|~/.surfraw.bookmarks}}
|
[https://gitlab.com/surfraw/Surfraw/commit/3e4591d 3e4591d]
[https://gitlab.com/surfraw/Surfraw/commit/bd8c427 bd8c427]
[https://gitlab.com/surfraw/Surfraw/commit/f57fc71 f57fc71]
|
|
|-
| [[sway]]
| {{ic|~/.sway/config}}
| [https://github.com/SirCmpwn/sway/commit/614393c 614393c]
| [https://github.com/SirCmpwn/sway/issues/5]
| {{ic|XDG_CONFIG_HOME/sway/config}}
|-
| [[sxhkd]]
|
|
|
|
|-
| [[systemd]]
|
|
|
|
|-
| {{Pkg|teeworlds}}
| {{ic|~/.teeworlds}}
| [https://github.com/teeworlds/teeworlds/commit/d2e39d2f50684151490da446156622e69dd84a48]
|
|
|-
| [[termite]]
|
|
|
|
|-
| Theming (desktop)
| {{ic|~/.icons/}}, {{ic|~/.themes/}}
| [https://specifications.freedesktop.org/icon-theme-spec/0.7/#directory_layout]
|
|{{ic|XDG_DATA_HOME/icons}}
{{ic|XDG_DATA_HOME/themes}}

For Qt programs, GTK or Qt programs on Wayland, to use cursors in {{ic|XDG_DATA_HOME/icons}}, the [[Cursor themes#Environment variable|XCURSOR_PATH]] environment variable needs to be configured.
|-
| {{Pkg|tig}}
| {{ic|~/.tigrc}}, {{ic|~/.tig_history}}
| [https://github.com/jonas/tig/blob/master/NEWS.adoc#tig-22 2.2]
| [https://github.com/jonas/tig/issues/513]
| {{ic|~/.local/share/tig}} directory must exist, writes to {{ic|~/.tig_history}} otherwise.
|-
| [[TigerVNC]]
| {{ic|~/.vnc}}
| [https://github.com/TigerVNC/tigervnc/releases/tag/v1.14.0 1.14.0]
| [https://github.com/TigerVNC/tigervnc/issues/1195]
|
|-
| [[tmux]]
| {{ic|~/.tmux.conf}}
| [https://raw.githubusercontent.com/tmux/tmux/3.1/CHANGES 3.1]
| [https://github.com/tmux/tmux/issues/142]
| 3.1 introduced {{ic|~/.config/tmux/tmux.conf}} and in [https://github.com/tmux/tmux/blob/a5f99e14c6f264e568b860692b89d11f5298a3f2/CHANGES#L145 3.2] {{ic|XDG_CONFIG_HOME/tmux/tmux.conf}} was added
|-
| {{AUR|tmuxinator}}
| {{ic|~/.tmuxinator}}
| [https://github.com/tmuxinator/tmuxinator/pull/511/commits/2636923 2636923]
| [https://github.com/tmuxinator/tmuxinator/pull/511]
|
|-
| [[tmuxp]]
| {{ic|~/.tmuxp}}
| [https://tmuxp.git-pull.com/history.html#tmuxp-1-5-0-2018-10-02 1.5.0]
| [https://github.com/tmux-python/tmuxp/pull/404]
| Fixed in [https://tmuxp.git-pull.com/history.html#tmuxp-1-5-2-2019-06-02 1.5.2]
|-
| [[Transmission]]
| {{ic|~/.transmission}}
| [https://github.com/transmission/transmission/commit/b71a298 b71a298]
|
|
|-
| {{Pkg|util-linux}}
|
| [https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git/commit/?id=570b321 570b321]
|
|
|-
| [[Uzbl]]
|
| [https://github.com/uzbl/uzbl/commit/c6fd63a c6fd63a]
| [https://github.com/uzbl/uzbl/pull/150]
|
|-
| {{Pkg|vale}}
| {{ic|~/.vale.ini}}
| [https://github.com/errata-ai/vale/releases/tag/v3.0.0 3.0.0]
| 
|
|-
| [[Vim]]
| {{ic|~/.vim}}, {{ic|~/.vimrc}}, {{ic|~/.viminfo}}
| [https://github.com/vim/vim/commit/c9df1fb c9df1fb]
| [https://github.com/vim/vim/pull/14182] [https://github.com/vim/vim/issues/19399]
|{{ic|XDG_CONFIG_HOME/vim/vimrc}}
See [https://vimhelp.org/starting.txt.html#xdg-base-dir :h xdg-base-dir] for more details.<br>
Full XDG support is pending:
[https://github.com/vim/vim/pull/19421]

|-
| {{Pkg|vimb}}
|
|
|
|
|-
| [[VirtualBox]]
| {{ic|~/.VirtualBox}}
| [https://www.virtualbox.org/ticket/5099?action=diff&version=7 4.3]
| [https://www.virtualbox.org/ticket/5099]
| Clobbers {{ic|~/.config}} by writing hundreds of kilobytes of {{ic|*.log}} and {{ic|*.dat}} files into it.
|-
| {{Pkg|vis}}
| {{ic|~/.vis}}
|
[https://github.com/martanne/vis/commit/68a25c7 68a25c7]
[https://github.com/martanne/vis/commit/d138908 d138908]
| [https://github.com/martanne/vis/pull/303]
|
|-
| [[VLC]]
| {{ic|~/.vlcrc}}
| [https://code.videolan.org/videolan/vlc/-/commit/16f32e1500887c0dcd33cb06ad71759a81a52878 16f32e1]
| [https://trac.videolan.org/vlc/ticket/1267]
|
|-
| {{Pkg|warsow}}
| {{ic|~/.warsow-2.x}}
| [https://github.com/Qfusion/qfusion/commit/98ece3f 98ece3f]
| [https://github.com/Qfusion/qfusion/issues/298]
|
|-
| [[WeeChat]]
| {{ic|~/.weechat}}
| [https://github.com/weechat/weechat/commit/70cdf21681d75090c3df9858c9e7ce5a85433856]
[https://github.com/weechat/weechat/releases/tag/v3.2 3.2]
| [https://github.com/weechat/weechat/issues/1285] [https://specs.weechat.org/specs/2021-001-follow-xdg-base-dir-spec.html]
|
 XDG_CONFIG_HOME/weechat
 XDG_DATA_HOME/weechat
 XDG_CACHE_HOME/weechat
 XDG_RUNTIME_DIR/weechat
|-
| [[Wireshark]]
| {{ic|~/.wireshark}}
| [https://gitlab.com/wireshark/wireshark/-/commit/b0b53fa5937aa7ba258427ca0f3581dba725230d b0b53fa] v2.1.0
|
|
|-
| [https://wxwidgets.org/ wxWidgets]
| 
| [https://trac.wxwidgets.org/ticket/17727]
|
|
|-
| [https://www.x.org/wiki/XKB/ XKB]
| {{ic|~/.xkb}}
|
|
|{{ic|XDG_CONFIG_HOME/xkb}} only supported on Wayland [https://xkbcommon.org/doc/current/user-configuration.html]
|-
| [[xmobar]]
| {{ic|~/.xmobarrc}}
| [https://github.com/jaor/xmobar/commit/7b0d6bf 7b0d6bf]{{Dead link|2024|07|30|status=404}}
[https://github.com/jaor/xmobar/commit/9fc6b37 9fc6b37]{{Dead link|2024|07|30|status=404}}
[https://github.com/jaor/xmobar/commit/eaccf70 eaccf70]{{Dead link|2024|07|30|status=404}}
| [https://github.com/jaor/xmobar/pull/99]{{Dead link|2024|07|30|status=404}}
[https://github.com/jaor/xmobar/pull/131]{{Dead link|2024|07|30|status=404}}
| {{ic|XDG_CONFIG_HOME/xmobar/xmobarrc}}
|-
| [[xmonad]]
| {{ic|~/.xmonad/}}
| [https://github.com/xmonad/xmonad/commit/40fc10b 40fc10b]
|
[https://github.com/xmonad/xmonad/issues/61]
[https://code.google.com/p/xmonad/issues/detail?id=484]
| All of these must exist, otherwise it gives up and falls back to {{ic|~/.xmonad/}} for each:
 XDG_CACHE_HOME/xmonad
 XDG_CONFIG_HOME/xmonad
 XDG_DATA_HOME/xmonad
Alternatively, it always respects {{ic|XMONAD_CACHE_DIR}}, {{ic|XMONAD_CONFIG_DIR}}, and {{ic|XMONAD_DATA_DIR}}.
|-
| {{Pkg|xonsh}}
| {{ic|~/.xonshrc}}
|
| [https://xon.sh/xonshrc.html]
| {{ic|$XDG_CONFIG_HOME/xonsh/rc.xsh}}
|-
| {{Pkg|xournalpp}}
| {{ic|~/.xournalpp}}
| [https://github.com/xournalpp/xournalpp/commit/20db937f 20db937f]
[https://github.com/xournalpp/xournalpp/releases/tag/1.1.0 1.1.0]
|[https://github.com/xournalpp/xournalpp/issues/1101]
[https://github.com/xournalpp/xournalpp/pull/1384]
|
|-
| {{Pkg|xsel}}
| {{ic|~/.xsel.log}}
| [https://github.com/kfish/xsel/commit/ee7b481 ee7b481]
| [https://github.com/kfish/xsel/issues/10]
|
|-
| [[Xsettingsd]]
| {{ic|~/.xsettingsd}}
| [https://github.com/derat/xsettingsd/commit/b4999f5 b4999f5]
|
|
|-
| {{Pkg|yapf}}
| 
| [https://github.com/google/yapf/pull/1067/commits/a0b51d2 a0b51d2]
| [https://github.com/google/yapf/pull/1067]
| {{ic|$XDG_CONFIG_HOME/yapf/style}}
|-
| [[Zim]]
|
| [https://github.com/zim-desktop-wiki/zim-desktop-wiki/commit/e42b8b0 e42b8b0]
|
|
  $XDG_CONFIG_HOME/zim/preferences.conf
  $XDG_CONFIG_HOME/zim/notebooks.list
|-
| {{Pkg|zoxide}}
| {{ic|~/.zo}}
| [https://github.com/ajeetdsouza/zoxide/releases/tag/v0.3.0 0.3.0]
| [https://github.com/ajeetdsouza/zoxide/pull/47]
|
|-
| [https://www.nongnu.org/zutils/zutils.html zutils]
| {{ic|~/.zutilsrc}}
| [https://lists.nongnu.org/archive/html/zutils-bug/2023-01/msg00000.html 1.12]
|
|
 $XDG_CONFIG_HOME/zutils.conf
|}

=== Partial ===

{| class="wikitable sortable" style="width: 100%"
! Application
! Legacy Path
! Supported Since
! Discussion
! Notes
|-
| {{AUR|abook}}
| {{ic|~/.abook}}
|
|
| {{ic|1=abook --config "$XDG_CONFIG_HOME"/abook/abookrc --datafile "$XDG_DATA_HOME"/abook/addressbook}}
|-
| {{AUR|ack}}
| {{ic|~/.ackrc}}
|
| [https://github.com/beyondgrep/ack2/issues/516]
| {{ic|1=export ACKRC="$XDG_CONFIG_HOME/ack/ackrc"}}
|-
| [[Ansible]]
| {{ic|~/.ansible}}, {{ic|~/.ansible_async}}
| [https://github.com/ansible/ansible/pull/76114 2.14]
| [https://github.com/ansible/ansible/issues/52354] [https://github.com/ansible/ansible/issues/68587] [https://github.com/ansible/ansible/issues/75788]
| {{bc|1=export ANSIBLE_HOME="${XDG_CONFIG_HOME}/ansible"
export ANSIBLE_CONFIG="${XDG_CONFIG_HOME}/ansible.cfg"
export ANSIBLE_GALAXY_CACHE_DIR="${XDG_CACHE_HOME}/ansible/galaxy_cache"
export ANSIBLE_LOCAL_TEMP="${XDG_CACHE_HOME}/ansible/tmp"
export ANSIBLE_SSH_CONTROL_PATH_DIR="${XDG_CACHE_HOME}/ansible/cp"
export ANSIBLE_ASYNC_DIR="${XDG_CACHE_HOME}/ansible_async"}}
|-
| {{AUR|asdf-vm}}
| {{ic|~/.asdfrc}}, {{ic|~/.asdf/}}
|
| [https://github.com/asdf-vm/asdf/issues/687]
| {{ic|1=export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}/asdf/asdfrc"}}, {{ic|1=export ASDF_DATA_DIR="${XDG_DATA_HOME}/asdf"}}
|-
| [[aspell]]
| {{ic|~/.aspell.conf}}
|
| [https://github.com/GNUAspell/aspell/issues/560]
| Very incomplete. The following re-locates the {{ic|en}} dictionaries, but additional possible dictionaries are not specificed here for brevity. {{ic|1=export ASPELL_CONF="per-conf $XDG_CONFIG_HOME/aspell/aspell.conf; personal $XDG_DATA_HOME/aspell/en.pws; repl $XDG_DATA_HOME/aspell/en.prepl"}}
|-
| {{Pkg|aws-cli}}
| {{ic|~/.aws}}
| [https://github.com/aws/aws-cli/commit/fc5961ea2cc0b5976ac9f777e20e4236fd7540f5 1.7.45]
| [https://github.com/aws/aws-cli/issues/2433]
| {{ic|1=export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials}}, {{ic|1=export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config}}
|-
| {{Pkg|azure-cli}}
| {{ic|~/.azure}}
|
|
| {{ic|1=export AZURE_CONFIG_DIR=$XDG_DATA_HOME/azure}}
|-
| {{Pkg|bash-completion}}
| {{ic|~/.bash_completion}}
|
|
| {{ic|1=export BASH_COMPLETION_USER_FILE="$XDG_CONFIG_HOME"/bash-completion/bash_completion}}
|-
| {{AUR|bashdb}}
| {{ic|~/.bashdbinit, ~/.bashdb_hist}}
|
|
| Like documented at [https://bashdb.sourceforge.net/bashdb.html#Command-Files], you can specify a file to run commands from. Thus, move the init file to {{ic|XDG_CONFIG_HOME/bashdb/bashdbinit}} and create an alias {{ic|1=alias bashdb='bashdb -x ${XDG_CONFIG_HOME:-$HOME/.config}/bashdb/bashdbinit'}}. Unfortunately the history file is hardcoded [https://sourceforge.net/p/bashdb/code/ci/bash-5.1/tree/lib/hist.sh#l28].
|-
| [[bazaar]]
| {{ic|~/.bazaar}}, {{ic|~/.bzr.log}}
| [https://bugs.launchpad.net/bzr/+bug/195397/comments/15 2.3.0]
| [https://bugs.launchpad.net/bzr/+bug/195397]
| Discussion in upstream bug states that bazaar will use {{ic|~/.config/bazaar}} if it exists. The logfile {{ic|~/.bzr.log}} might still be written.
|-
| {{Pkg|bitwarden}}
| {{ic|~/.bitwarden-ssh-agent.sock}}
| 
| [https://github.com/bitwarden/clients/issues/13099]
| {{ic|1=export BITWARDEN_SSH_AUTH_SOCK="$XDG_RUNTIME_DIR"}}
|-
| {{Pkg|bogofilter-db}}
| {{ic|~/.bogofilter}}
| [https://gitlab.com/bogofilter/bogofilter/-/blob/main/bogofilter/NEWS.0#L2760 0.7.5]
| [https://sourceforge.net/p/bogofilter/bugs/110/]
| {{ic|1=export BOGOFILTER_DIR="$XDG_DATA_HOME"/bogofilter}}
|-
| {{AUR|btpd-git}}
| {{ic|~/.btpd/}}
|
| [https://github.com/btpd/btpd/issues/55]
| {{ic|1=btpd -d "$XDG_DATA_HOME"/.btpd}}
{{ic|1=HOME="$XDG_DATA_HOME" btcli}}
|-
| {{Pkg|bun}}
| {{ic|~/.bun/}}
|
| [https://github.com/oven-sh/bun/issues/1678]
| Bun will prioritize using {{ic|$XDG_CONFIG_HOME}}, {{ic|$XDG_CACHE_HOME}}, and/or {{ic|$XDG_DATA_HOME}} when these have explicitly been set. As an alternative, {{ic|1=export BUN_INSTALL="$XDG_DATA_HOME"/bun}} can be used to set {{ic|bun}}'s main location for its directories.
|-
|  {{Pkg|calc}}
|  {{ic|~/.calc_history}}
|
|
|
 export CALCHISTFILE="$XDG_CACHE_HOME"/calc_history
|-
| [[Rust#Cargo]]
| {{ic|~/.cargo}}
|
| [https://github.com/rust-lang/cargo/issues/1734] [https://github.com/rust-lang/rfcs/pull/1615] [https://github.com/rust-lang/cargo/pull/5183]  [https://github.com/rust-lang/cargo/pull/148]
| {{ic|1=export CARGO_HOME="$XDG_DATA_HOME"/cargo}}
|-
| {{Pkg|cataclysm-dda}}
| {{ic|~/.cataclysm-dda}}
|[https://gitlab.archlinux.org/archlinux/packaging/packages/cataclysm-dda/-/commit/0947de440817c9c418cac615275edbf1cc0abdbb 0.D-1]
|[https://github.com/CleverRaven/Cataclysm-DDA/issues/12315]
| partial support due to required compile time option
|-
| [https://github.com/mollifier/cd-bookmark cd-bookmark]
| {{ic|~/.cdbookmark}}
|
| [https://github.com/mollifier/cd-bookmark/issues/3]
| {{ic|1=export CD_BOOKMARK_FILE=$XDG_CONFIG_HOME/cd-bookmark/bookmarks}}
or use the fork that has native XDG support: [https://github.com/erikw/cd-bookmark/]
|-
| {{Pkg|cgdb}}
| {{ic|~/.cgdb}}
| [https://github.com/cgdb/cgdb/blob/master/NEWS#L61 0.8.0]
| [https://github.com/cgdb/cgdb/issues/203] [https://github.com/cgdb/cgdb/blob/master/NEWS]
| Set {{ic|1=export CGDB_DIR=$XDG_CONFIG_HOME/cgdb}} and move the config file to {{ic|XDG_CONFIG_HOME/cgdb/cgdbrc}}
|-
| {{AUR|chez-scheme}}
| {{ic|~/.chezscheme_history}}
|
|
| {{ic|1=petite --eehistory "$XDG_DATA_HOME"/chezscheme/history}}
|-
| chktex in {{Pkg|texlive-binextra}}
| {{ic|~/.chktexrc}}
|
|
| Move the config file to {{ic|$XDG_CONFIG_HOME/chktex/.chktexrc}} (mind the leading dot) and {{ic|1=export CHKTEXRC=$XDG_CONFIG_HOME/chktex}}
|-
| [[Chromium]]
| {{ic|~/.chromium}}, {{ic|~/.pki}}
| [https://src.chromium.org/viewvc/chrome?revision=23057&view=revision 23057]{{Dead link|2026|03|12}} [https://chromium-review.googlesource.com/c/chromium/src/+/7551836 7551836]
| [https://groups.google.com/forum/#!topic/chromium-dev/QekVQxF3nho]{{Dead link|2026|03|12}} [https://code.google.com/p/chromium/issues/detail?id=16976] [https://bugs.chromium.org/p/chromium/issues/detail?id=1038587]
| Deliberately (according to these sources) clobbers {{ic|~/.config}} by writing hundreds of megabytes of '''cache''' data into it. Quite unsupported.<br/> Chromium <146 created .pki due to not setting up NSS properly even though NSS itself allowed using the XDG spec. This resulted in downstream from it not working as well (Qt WebEngine especially affecting many cases like KMail and etc.)
|-
| [https://www.cinelerra-gg.org/ cinelerra]
| {{ic|~/.bcast5}}
|
| [https://cinelerra-gg.org/download/CinelerraGG_Manual/Environment_Variables_Custo.html]{{Dead link|2025|08|16|status=404}}
| {{ic|1=export CIN_CONFIG="$XDG_CONFIG_HOME"/bcast5}}
|-
| {{Pkg|claws-mail}}
| {{ic|~/.claws-mail}}
|
| [https://lists.claws-mail.org/pipermail/users/2013-April/006087.html]
| {{ic|1=claws-mail --alternate-config-dir "$XDG_DATA_HOME"/claws-mail}}
|-
| {{AUR|clusterssh}}
| {{ic|~/.clusterssh/}}
|
|
| {{ic|1=alias cssh="cssh --config-file '$XDG_CONFIG_HOME/clusterssh/config'" }}
{{hc|$XDG_CONFIG_HOME/clusterssh/config|2=
extra_cluster_file=$HOME/.config/clusterssh/clusters
extra_tag_file=$HOME/.config/clusterssh/tags
}}
Despite this, clusterssh will still create {{ic|~/.clusterssh/}}.
|-
| [[conky]]
| {{ic|~/.conkyrc}}
| [https://github.com/brndnmtthws/conky/commit/00481ee9a97025e8e2acd7303d080af1948f7980 00481ee]
| [https://github.com/brndnmtthws/conky/issues/144]
| {{ic|1=conky --config="$XDG_CONFIG_HOME"/conky/conkyrc}}
|-
| [[coreutils]]
| {{ic|~/.dircolors}}
|
|
| {{ic|1=eval $(dircolors "$XDG_CONFIG_HOME"/dircolors)}}
|-
| [http://www.dungeoncrawl.org/ crawl]
| {{ic|~/.crawl}}
|
|
| The trailing slash is required:

{{ic|1=export CRAWL_DIR="$XDG_DATA_HOME"/crawl/}}
|-
| [[CUDA]]
| {{ic|~/.nv}}
|
|
| {{ic|1=export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv}}
|-
| [[dict]]
| {{ic|~/.dictrc}}
|
|
| {{ic|1=dict -c "$XDG_CONFIG_HOME"/dict/dictrc}}
|-
| [[discord]]
| {{ic|1=${XDG_CONFIG_HOME}/discord}}
|
| 
| As of version 0.0.27:
Undocumented, though actively used:
{{ic|1=export DISCORD_USER_DATA_DIR="${XDG_DATA_HOME}"}}

Source: {{ic|1=<discord_system_package_root>/resources/app.asar}}.
|-
| [[Docker]]
| {{ic|~/.docker}}
|
|
| {{ic|1=export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker}}
|-
| {{Pkg|docker-machine}}
| {{ic|~/.docker/machine}}
|
|
| {{ic|1=export MACHINE_STORAGE_PATH="$XDG_DATA_HOME"/docker-machine}}
|-
| [[DOSBox]]
| {{ic|~/.dosbox/dosbox-0.74-2.conf}}
|
| [https://www.vogons.org/viewtopic.php?t=29599]
| {{ic|1=dosbox -conf "$XDG_CONFIG_HOME"/dosbox/dosbox.conf}}
|-
| {{Pkg|dub}}
| {{ic|~/.dub}}
| [https://github.com/dlang/dub/pull/2281 v1.30.0-beta.1]
| 
| Dub uses the {{ic|~/.dub}} directory for both user settings and caching downloaded packages. The directory can only be moved as a whole, using {{ic|1=export DUB_HOME="path/to/new/dub"}}.
|-
| {{AUR|elan-lean}}
| {{ic|~/.elan}}
|
| [https://github.com/leanprover/elan/issues/75]
| {{ic|1=export ELAN_HOME="$XDG_DATA_HOME/elan"}}
|-
| [https://electrum.org Electrum Bitcoin Wallet]
| {{ic|~/.electrum}}
| [https://github.com/spesmilo/electrum/commit/c121230 c121230]
|
| {{ic|1=export ELECTRUMDIR="$XDG_DATA_HOME/electrum"}}
|-
| [[ELinks]]
| {{ic|~/.elinks}}
|
|
| {{ic|1=export ELINKS_CONFDIR="$XDG_CONFIG_HOME"/elinks}}
|-
| {{Pkg|elixir}}
| {{ic|~/.mix}}, {{ic|~/.hex}}
| [https://github.com/elixir-lang/elixir/commit/afaf889 afaf889]
| [https://github.com/elixir-lang/elixir/pull/10028] [https://github.com/hexpm/hex/pull/841]
| Elixir does not fully conform to XDG specs, it will use XDG only if the {{ic|1=MIX_XDG}} variable is set to a special value, otherwise it will by default use legacy path.
{{ic|1=export MIX_XDG="true"}}
|-
| [https://elm-lang.org/ Elm]
| {{ic|~/.elm}}
| 
| 
| {{ic|1=export ELM_HOME="$XDG_CONFIG_HOME"/elm}}
|-
| {{Pkg|emscripten}}
| {{ic|~/.emscripten}}, {{ic|~/.emscripten_sanity}}, {{ic|~/.emscripten_ports}}, {{ic|~/.emscripten_cache__last_clear}}
|
| [https://github.com/kripken/emscripten/issues/3624]
| {{ic|1=export EM_CONFIG="$XDG_CONFIG_HOME"/emscripten/config}}, {{ic|1=export EM_CACHE="$XDG_CACHE_HOME"/emscripten/cache}}, {{ic|1=export EM_PORTS="$XDG_DATA_HOME"/emscripten/cache}}, {{ic|emcc --em-config "$XDG_CONFIG_HOME"/emscripten/config --em-cache "$XDG_CACHE_HOME"/emscripten/cache}}
|-
| {{Pkg|erlang}}
| {{ic|~/.erlang.cookie}}
| [https://github.com/erlang/otp/pull/5408]
| [https://github.com/erlang/otp/issues/5016]
| Erlang does not fully conform to XDG specs, it looks for its files in {{ic|XDG_CONFIG_HOME}} last. 
{{ic|mkdir "$XDG_CONFIG_HOME"/erlang}}
{{ic|mv ~/.erlang.cookie "$XDG_CONFIG_HOME"/erlang}}
|-
| {{AUR|factorio}}
| {{ic|~/.factorio/}}
|
| [https://forums.factorio.com/viewtopic.php?t=30585] [https://forums.factorio.com/viewtopic.php?f=5&t=8294]
| Factorio supports manually specifying data paths with a config file: [https://wiki.factorio.com/Application_directory#Linux]
{{hc|__Game_Install_directory/config-path.cfg|2=
use-system-read-write-data-directories=true
}}

{{hc|__Game_Install_directory/config/config.ini|2=
[path]
read-data=__PATH__executable__/../../data
write-data=.local/share/factorio
}}
|-
| {{Pkg|fceux}}
| {{ic|~/.fceux/}}
|
| [https://github.com/TASEmulators/fceux/issues/412]
| {{ic|1=export FCEUX_HOME="$XDG_CONFIG_HOME"/fceux}}. Fceux will create {{ic|1=.fceux}} directory inside {{ic|1=$FCEUX_HOME}}.
|-
| [[FFmpeg]]
| {{ic|~/.ffmpeg}}
|
|
| {{ic|1=export FFMPEG_DATADIR="$XDG_CONFIG_HOME"/ffmpeg}}
|-
| {{AUR|flutter}}
| {{ic|~/.flutter}}, {{ic|~/.flutter_settings}}, {{ic|~/.flutter_tool_state}}, {{ic|~/.pub-cache}}
|
| [https://github.com/flutter/flutter/issues/59430]
|
|-
| {{AUR|fzf-git}}
| {{ic|~/.fzf.bash, ~/.fzf.zsh}}
| 
| [https://github.com/junegunn/fzf/pull/1282]
| The shell init files will be installed to {{ic|XDG_CONFIG_HOME/fzf}} if the installation script is called with {{ic|--xdg}} for example {{ic| /usr/local/opt/fzf/install --xdg}}.
|-
| {{AUR|get_iplayer}}
| {{ic|~/.get_iplayer}}
|
|
| {{ic|1=export GETIPLAYERUSERPREFS="$XDG_DATA_HOME"/get_iplayer}}
|-
| [[getmail]]
| {{ic|~/.getmail/getmailrc}}
|
|
| {{ic|1=getmail --rcfile="$XDG_CONFIG_HOME/getmail/getmailrc" --getmaildir="$XDG_DATA_HOME/getmail"}}
|-
| {{AUR|ghcup-hs-bin}}
| {{ic|~/.ghcup}}
| [https://gitlab.haskell.org/haskell/ghcup-hs/-/commit/80603662b4fcc42fd936f45608dc3bc924c7e498]
| [https://gitlab.haskell.org/haskell/ghcup-hs/issues/39]
| {{ic|1=export GHCUP_USE_XDG_DIRS=true}}
The environment variable {{ic|GHCUP_USE_XDG_DIRS}} can be set to any non-empty value. See [https://www.haskell.org/ghcup/guide/#xdg-support].
|-
| {{Pkg|gitsign}}
| {{ic|~/.sigstore/root}}
| [https://github.com/sigstore/cosign/commit/32a2d62a9992b1b990f3747e0bbb1533529d7e14]
|
| {{ic|1=export TUF_ROOT="$XDG_DATA_HOME"/sigstore/root}}
|-
| {{AUR|gliv}}
| {{ic|~/.glivrc}}
|
|
| {{ic|1=gliv --glivrc="$XDG_CONFIG_HOME"/gliv/glivrc}}
|-
| [[GNU Screen]]
| {{ic|~/.screenrc}}
{{ic|~/.screen/}}
|
|
| {{ic|1=export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc}}, {{ic|1=export SCREENDIR="${XDG_RUNTIME_DIR}/screen"}}
|-
| [[GnuPG]]
| {{ic|~/.gnupg}}
|
| [https://bugs.gnupg.org/gnupg/issue1456] [https://bugs.gnupg.org/gnupg/issue1018]
| {{ic|1=export GNUPGHOME="$XDG_DATA_HOME"/gnupg}}, {{ic|gpg2 --homedir "$XDG_DATA_HOME"/gnupg}}
Note that this currently does not work out-of-the-box using systemd user units and socket-based activation, since the socket directory changes based on the hash of {{ic|$GNUPGHOME}}. You can get the new socket directory using {{ic|gpgconf --list-dirs socketdir}} and have to modify the systemd user units to listen on the correct sockets accordingly. You also have to use the following {{ic|gpg-agent.service}} drop-in file (or otherwise pass the GNUPGHOME env var to the agent running in systemd), or you might experience issues with "missing" private keys:

 [Service]
 Environment="GNUPGHOME=%h/.local/share/gnupg"

If you [[GnuPG#SSH agent|use GPG as your SSH agent]], set {{ic|SSH_AUTH_SOCK}} to the output of {{ic|gpgconf --list-dirs agent-ssh-socket}} instead of some hardcoded value.
|-
| {{Pkg|gnuradio}}
| {{ic|~/.gnuradio}}
|
| [https://github.com/gnuradio/gnuradio/issues/3631]
| GNU Radio:
{{ic|1=export GR_PREFS_PATH="$XDG_CONFIG_HOME"/gnuradio}}

GNU Radio Companion:
{{ic|1=export GRC_PREFS_PATH="$XDG_CONFIG_HOME"/gnuradio/grc.conf}}
|-
| [[Go]]
| {{ic|~/go}}
| [https://github.com/golang/go/commit/ca8a055f5cc7c1dfa0eb542c60071c7a24350f76]
|
| {{ic|1=export GOPATH="$XDG_DATA_HOME"/go}}, {{ic|1=export GOMODCACHE="$XDG_CACHE_HOME"/go/mod}}
If {{ic|GOMODCACHE}} is not set, it defaults to {{ic|$GOPATH/pkg/mod}} (see [https://go.dev/ref/mod#environment-variables]).
{{ic|GOCACHE}} is supported and defaults to {{ic|$XDG_CACHE_HOME/go-build}} (see [https://pkg.go.dev/cmd/go#hdr-Build_and_test_caching]).
|-
| [[Google Earth]]
| {{ic|~/.googleearth}}
|
|
| Some paths can be changed with the {{ic|KMLPath}} and {{ic|CachePath}} options in {{ic|~/.config/Google/GoogleEarthPro.conf}}
|-
| {{Pkg|gopass}}
| {{ic|~/.password-store}}
|
|
| Override settings in {{ic|~/.config/gopass/config.yml}}:
{{hc|~/.config/gopass/config.yml|
root:
path: gpgcli-gitcli-fs+file:///home/<userid>/.config/password-store
}}

{{ic|PASSWORD_STORE_DIR}} is supported only during initialization.
|-
| {{Pkg|gpodder}}
| {{ic|~/gPodder}}
|
|
| {{ic|1=GPODDER_DOWNLOAD_DIR}} sets the download folder. {{ic|1=GPODDER_HOME}} - where config and database files are stored, downloads also if {{ic|1=GPODDER_DOWNLOAD_DIR}} is not set.
|-
| [https://sourceforge.net/projects/gqclient GQ LDAP client]
| {{ic|~/.gq}}, {{ic|~/.gq-state}}
| [https://sourceforge.net/p/gqclient/mailman/message/2053978 1.51]
|
| {{ic|1=export GQRC="$XDG_CONFIG_HOME"/gqrc}}, {{ic|1=export GQSTATE="$XDG_DATA_HOME"/gq/gq-state}}, {{ic|mkdir -p "$(dirname "$GQSTATE")"}}
|-
| [[Gradle]]
| {{ic|~/.gradle}}
|
| [https://discuss.gradle.org/t/be-a-nice-freedesktop-citizen-move-the-gradle-to-the-appropriate-location-in-linux/2199]
[https://github.com/gradle/gradle/issues/8262]
| {{ic|1=export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle}}
|-
| [[GTK]] 1
| {{ic|~/.gtkrc}}
|
|
| {{ic|1=export GTK_RC_FILES="$XDG_CONFIG_HOME"/gtk-1.0/gtkrc}}
|-
| [[GTK]] 2
| {{ic|~/.gtkrc-2.0}}
|
|
| {{ic|1=export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc":"$XDG_CONFIG_HOME/gtk-2.0/gtkrc.mine"}}
If '''Lxappearance''' is used, {{ic|~/.gtkrc-2.0}} may keep being created because it is where clicking "Apply" customizations writes to. The path is hardcoded in Lxappearance, but simply being an output file, the settings can be repeatedly moved to the location.

To prevent KDE Plasma from creating this file, disable the "GNOME/GTK Settings Synchronization" background service.
|-
| {{Pkg|hledger}}
| {{ic|~/.hledger.journal}}
|
| [https://github.com/simonmichael/hledger/issues/1081]
| {{ic|1=export LEDGER_FILE="$XDG_DATA_HOME"/hledger.journal}}
|-
| [https://www.sidefx.com/products/houdini/ Houdini]
| {{ic|~/houdini''MAJOR''.''MINOR'')}}
|
| [https://forums.odforce.net/topic/43138-changing-home-location/]
[https://www.sidefx.com/docs/houdini/ref/env.html]
| {{ic|1=export HOUDINI_USER_PREF_DIR="$XDG_CACHE_HOME"/houdini__HVER__}}
The value of this variable must include the substring {{ic|__HVER__}}, which will be replaced at run time with the current {{ic|''MAJOR''.''MINOR''}} version string.
|-
| {{AUR|imapfilter}}
| {{ic|~/.imapfilter}}
|
|
| {{ic|1=export IMAPFILTER_HOME="$XDG_CONFIG_HOME/imapfilter"}}
|-
| [[IPFS]]
| {{ic|~/.ipfs}}
|
|
| {{ic|1=export IPFS_PATH="$XDG_DATA_HOME"/ipfs}}
|-
| [https://ruby-doc.org/3.2.2/stdlibs/irb/IRB.html irb]
| {{ic|~/.irbrc}}
|
|
| {{hc|1=~/.profile|2=$ export IRBRC="$XDG_CONFIG_HOME"/irb/irbrc}}
{{hc|1="$XDG_CONFIG_HOME"/irb/irbrc|2=IRB.conf[:SAVE_HISTORY] {{!}}{{!}}= 1000
IRB.conf[:HISTORY_FILE] {{!}}{{!}}= File.join(ENV["XDG_DATA_HOME"], "irb", "history")}}
|-
| [[irssi]]
| {{ic|~/.irssi}}
|
| [https://github.com/irssi/irssi/pull/511]
| {{ic|1=irssi --config="$XDG_CONFIG_HOME"/irssi/config --home="$XDG_DATA_HOME"/irssi}}
|-
| [[isync]]
| {{ic|~/.mbsyncrc}}
|
| [https://sourceforge.net/p/isync/feature-requests/14/]
| {{ic|1=mbsync -c "$XDG_CONFIG_HOME"/isync/mbsyncrc}}
|-
| [[Java#OpenJDK]]
| {{ic|~/.java/.userPrefs}}
|
| [https://bugzilla.redhat.com/show_bug.cgi?id=1154277]
| {{ic|1=export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java}}
|-
| [[jupyter]]
| {{ic|~/.jupyter}}
| [https://github.com/jupyter/jupyter_core/releases/tag/5.0.0rc0 5.0.0rc0]
| [https://github.com/jupyter/jupyter_core/issues/185] [https://github.com/jupyter/jupyter_core/pull/292]
| {{Pkg|python-jupyter-core}} < v5.0.0:

{{ic|1=export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME"/jupyter}}

v5.0.0 <= {{Pkg|python-jupyter-core}} < v6.0.0:

{{ic|1=export JUPYTER_PLATFORM_DIRS="1"}} (see [https://github.com/jupyter/jupyter_core/blob/3efd00e5804424198285c63ebc6dc6c085d8c857/jupyter_core/paths.py#L176-L181])

{{Pkg|python-jupyter-core}} >= v6.0.0: full support (via {{Pkg|python-platformdirs}}) enabled by default
|-
| {{Pkg|k9s}}
| {{ic|~/.k9s}}
| [https://github.com/derailed/k9s/releases/tag/v0.20.4 0.20.4]
| [https://github.com/derailed/k9s/issues/743]
| {{ic|1=export K9SCONFIG="$XDG_CONFIG_HOME"/k9s}}
|-
| [[KDE4]]
| {{ic|~/.kde}}, {{ic|~/.kde4}}
|
| [https://userbase.kde.org/KDE_System_Administration/KDE_Filesystem_Hierarchy#KDEHOME]
| {{ic|1=export KDEHOME="$XDG_CONFIG_HOME"/kde}}

KDE4 uses {{ic|KDEHOME}}. It is [https://www.reddit.com/r/kde/comments/t4a2lm/changing_kdehome_gives_weird_result_on_applying/ not recommended] to set the variable for newer versions. 
|-
| {{Pkg|keychain}}
| {{ic|~/.keychain}}
| [https://github.com/funtoo/keychain/commit/d43099bcff315d24a2ca31ae83da85e115d22ef6]
| [https://github.com/funtoo/keychain/issues/8]
| {{ic|1=keychain --absolute --dir "$XDG_RUNTIME_DIR"/keychain}}
|-
| {{Pkg|kodi}}
| {{ic|~/.kodi}}
| [https://github.com/xbmc/xbmc/pull/14460]
| [https://github.com/xbmc/xbmc/pull/6142]
| {{ic|1=KODI_DATA=$XDG_DATA_HOME/kodi}}
|-
| {{AUR|kscript}}
| {{ic|~/.kscript}}
|
| [https://github.com/holgerbrandl/kscript/issues/323]
| {{ic|1=export KSCRIPT_CACHE_DIR="$XDG_CACHE_HOME"/kscript}}
|-
| [[ledger]]
| {{ic|~/.ledgerrc}}, {{ic|~/.pricedb}}
|
| [https://github.com/ledger/ledger/issues/1820]
| {{ic|1=ledger --init-file "$XDG_CONFIG_HOME"/ledgerrc}}
|-
| [[Leiningen]]
| {{ic|~/.lein}}, {{ic|~/.m2}}
|
| [https://github.com/technomancy/leiningen/issues/2087]
| {{ic|1=export LEIN_HOME="$XDG_DATA_HOME"/lein}}

to change the m2 repo location used by leiningen look here: [[Leiningen#m2_repo_location]]
|-
| {{Pkg|libdvdcss}}
| {{ic|~/.dvdcss}}
|
| [https://mailman.videolan.org/pipermail/libdvdcss-devel/2014-August/001022.html]
| {{ic|1=export DVDCSS_CACHE="$XDG_DATA_HOME"/dvdcss}}
|-
| {{Pkg|libice}}
| {{ic|~/.ICEauthority}}
|
| [https://gitlab.freedesktop.org/xorg/lib/libice/issues/2]
| {{ic|1=export ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority}}
Make sure {{ic|XDG_CACHE_HOME}} is set beforehand to directory user running [[Xorg]] has write access to.

'''Do not''' use {{ic|XDG_RUNTIME_DIR}} as it is available '''after''' login. Display managers that launch [[Xorg]] (like [[GDM]]) will repeatedly fail otherwise.
|-
| [[LibreOffice]]
| 
| 
| [https://bugs.documentfoundation.org/show_bug.cgi?id=140039]
| Libreoffice stores everything in {{ic|$XDG_CONFIG_HOME/libreoffice/4/user/}}, including runtime files, user data, cache and extensions. Some of these can be changed unter ''Tools > Options > LibreOffice > Paths''
|-
| [[Xorg|libx11]]
| {{ic|~/.XCompose}}, {{ic|~/.compose-cache}}
|
|
| {{ic|1=export XCOMPOSEFILE="$XDG_CONFIG_HOME"/X11/xcompose}}, {{ic|1=export XCOMPOSECACHE="$XDG_CACHE_HOME"/X11/xcompose}}
|-
| {{Pkg|ltrace}}
| {{ic|~/.ltrace.conf}}
|
|
| {{ic|1=ltrace -F "$XDG_CONFIG_HOME"/ltrace/ltrace.conf}}
|-
| [[Luanti]]
| {{ic|~/.minetest/}}
|
| [https://github.com/minetest/minetest/issues/15382]
| {{ic|1=export MINETEST_USER_PATH="$XDG_DATA_HOME"/luanti}}
|-
| {{Pkg|lynx}}
| {{ic|/etc/lynx.cfg}}
|
|
| {{ic|1=export LYNX_CFG="$XDG_CONFIG_HOME"/lynx.cfg}}
|-
| [https://git.savannah.nongnu.org/cgit/m17n/m17n-db.git m17n-db]
| {{ic|~/.m17n.d}}
|
| [https://savannah.nongnu.org/bugs/?63056]
| 
|-
| [https://www.mamedev.org/ MAME]
| {{ic|~/.mame}}
|
|
| If using Arch's {{pkg|mame}} package, {{ic|/usr/bin/mame}} will be a wrapper script that automatically creates and forces use of {{ic|~/.mame}}. Run {{ic|/usr/bin/mame}} once to populate this directory, then you can move it to {{ic|$XDG_DATA_HOME/mame}}. Edit {{ic|mame.ini}} to replace all instances of {{ic|$HOME/.mame}}, then you can launch MAME with {{ic|/usr/lib/mame/mame -inipath $XDG_DATA_HOME/mame}}.
|-
| {{AUR|maptool-bin}}
| {{ic|~/.maptool-rptools}}
|
| [https://github.com/RPTools/maptool/issues/2786]
| {{hc|1=/opt/maptool/lib/app/MapTool.cfg|2=[JavaOptions]
-DMAPTOOL_DATADIR=.local/share/maptool-rptools}}
However, no way to change the location of this configuration file.
|-
| {{Pkg|maven}}
| {{ic|~/.m2}}
|
| [https://issues.apache.org/jira/browse/MNG-6603]
| {{ic|1=export MAVEN_OPTS=-Dmaven.repo.local="$XDG_DATA_HOME"/maven/repository}}, {{ic|1=export MAVEN_ARGS="--settings $XDG_CONFIG_HOME/maven/settings.xml"}}
, {{ic|1=mvn -gs "$XDG_CONFIG_HOME"/maven/settings.xml}} and set {{ic|<localRepository>}} as appropriate in [https://maven.apache.org/settings.html#Simple_Values settings.xml]
|-
| [[Mathematica]]
| {{ic|~/.Wolfram}}
|
|
| {{ic|1=export WOLFRAM_USERBASE="$XDG_CONFIG_HOME"/Wolfram}}

Used to be {{ic|MATHEMATICA_USERBASE}}, see [https://reference.wolframcloud.com/language/tutorial/UpgradingFromMathematicaToWolfram.html.en Upgrading from Mathematica to Wolfram].
|-
| {{Pkg|maxima}}
| {{ic|~/.maxima}}
|
|
| {{ic|1=export MAXIMA_USERDIR="$XDG_CONFIG_HOME"/maxima}}
|-
| {{Pkg|mednafen}}
| {{ic|~/.mednafen}}
|
|
| {{ic|1=export MEDNAFEN_HOME="$XDG_CONFIG_HOME"/mednafen}}
|-
| {{Pkg|minikube}}
| {{ic|~/.minikube}}
|
| [https://github.com/kubernetes/minikube/issues/4109]
| {{ic|1=export MINIKUBE_HOME="$XDG_DATA_HOME"/minikube}}

Creates a further {{ic|.minikube}} directory in {{ic|MINIKUBE_HOME}} for whatever reason.
|-
| {{Pkg|minio-client}}
| {{ic|~/.mc}}
| [https://github.com/minio/mc/pull/4720]
|
| {{ic|1=export MC_CONFIG_DIR="$XDG_CONFIG_HOME"/minio-client}}
|-
| {{Pkg|mitmproxy}}
| {{ic|~/.mitmproxy}}
|
|
| {{ic|1=alias mitmproxy="mitmproxy --set confdir=$XDG_CONFIG_HOME/mitmproxy"}}, {{ic|1=alias mitmweb="mitmweb --set confdir=$XDG_CONFIG_HOME/mitmproxy"}}
|-
| [[MOC]]
| {{ic|~/.moc}}
|
|
| {{ic|1=mocp -M "$XDG_CONFIG_HOME"/moc}}, {{ic|1=mocp -O MOCDir="$XDG_CONFIG_HOME"/moc}}
|-
| {{Pkg|monero}}
| {{ic|~/.bitmonero}}
|
|
| {{ic|1=monerod --data-dir "$XDG_DATA_HOME"/bitmonero}}
|-
| {{Pkg|most}}
| {{ic|~/.mostrc}}
|
|
| {{ic|1=export MOST_INITFILE="$XDG_CONFIG_HOME"/mostrc}}
|-
| [[MPlayer]]
| {{ic|~/.mplayer}}
|
|
| {{ic|1=export MPLAYER_HOME="$XDG_CONFIG_HOME"/mplayer}}
|-
| {{Pkg|mtpaint}}
| {{ic|~/.mtpaint}}
|
| [https://github.com/wjaguar/mtPaint/issues/22]
| {{hc|1=/etc/mtpaint/mtpaintrc|2=userINI = ~/.config/mtpaint}}
|-
| {{Pkg|mypy}}
| {{ic|~/.config/mypy/config}}, {{ic|~/.mypy.ini}}, {{ic|~/.mypy_cache}}
| [https://github.com/python/mypy/pull/6304 v0.670]
| [https://github.com/python/mypy/issues/6065] [https://github.com/python/mypy/issues/8790]
| {{ic|1=XDG_CONFIG_HOME/mypy/config}}, {{ic|1=export MYPY_CACHE_DIR="$XDG_CACHE_HOME"/mypy}}
|-
| [[MySQL]]
| {{ic|~/.mysql_history}}, {{ic|~/.my.cnf }}, {{ic|~/.mylogin.cnf}}
|
|
| {{ic|1=export MYSQL_HISTFILE="$XDG_DATA_HOME"/mysql_history}}

{{ic|~/.my.cnf}} only supported for mysql-server, not mysql-client [https://dev.mysql.com/doc/refman/8.0/en/option-files.html]

{{ic|~/.mylogin.cnf}} unsupported
|-
| {{Pkg|mysql-workbench}}
| {{ic|~/.mysql/workbench}}
|
|
| You can run MySQL Workbench with the {{ic|1=---configdir}} flag, such as {{ic|1=mysql-workbench --configdir="$XDG_DATA_HOME/mysql/workbench"}}. The directory needs to be created manually, since MySQL Workbench default location is {{ic|1=$HOME/.mysql/workbench}} .
|-
|-
| [https://github.com/tj/n n]
| {{ic|/usr/local/n}}
|
|
| {{ic|1=export N_PREFIX=$XDG_DATA_HOME/n
}}
|-
| {{Pkg|ncmpc}}
| {{ic|~/.ncmpc}}
|
|
| {{ic|ncmpc -f "$XDG_CONFIG_HOME"/ncmpc/config}}
|-
| {{Pkg|ncurses}}
| {{ic|~/.terminfo}}
|
|
| Precludes system path searching:

{{ic|1=export TERMINFO="$XDG_DATA_HOME"/terminfo}}, {{ic|1=export TERMINFO_DIRS="$XDG_DATA_HOME"/terminfo:/usr/share/terminfo}}
|-
| [[Netbeans]]
| {{ic|~/.netbeans}}
|
| [https://bz.apache.org/netbeans/show_bug.cgi?id=215961]
| {{ic|1=netbeans --userdir "${XDG_CONFIG_HOME}"/netbeans}}
|-
| [[Node.js]]
| {{ic|~/.node_repl_history}}
|
| [https://nodejs.org/api/repl.html#repl_environment_variable_options]
| {{ic|1=export NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history}}
|-
| {{AUR|nodenv}}
| {{ic|~/.nodenv}}
|
|
| {{ic|1=export NODENV_ROOT="$XDG_DATA_HOME"/nodenv}}
|-
| {{Pkg|npm}}
| {{ic|~/.npm}}, {{ic|~/.npmrc}}
|
| [https://github.com/npm/cli/issues/654]
| {{ic|1=export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc}}
{{hc|npmrc|<nowiki>
prefix=${XDG_DATA_HOME}/npm
cache=${XDG_CACHE_HOME}/npm
init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js
logs-dir=${XDG_STATE_HOME}/npm/logs
</nowiki>}}
{{ic|prefix}} is unnecessary (and unsupported) if Node.js is installed by {{Pkg|nvm}}.
|-
| {{Pkg|nuget}}
| {{ic|~/.nuget/packages}}
|
| [https://docs.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders]
| {{ic|1=export NUGET_PACKAGES="$XDG_CACHE_HOME"/NuGetPackages}}
|-
| [[NVIDIA]]
| {{ic|~/.nv}}
|
|
| Uses {{ic|XDG_CACHE_HOME}} if set, otherwise improperly falls back to {{ic|~/.nv}} instead of {{ic|~/.cache}}.
|-
| {{Pkg|nvidia-settings}}
| {{ic|~/.nvidia-settings-rc}}
|
| [https://github.com/NVIDIA/nvidia-settings/issues/30]
| {{ic|1=nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings}}
|-
| {{Pkg|nvm}}
| {{ic|~/.nvm}}
|
|
| {{ic|1=export NVM_DIR="$XDG_DATA_HOME"/nvm}}
|-
| [[Octave]]
| {{ic|~/octave}}, {{ic|~/.octave_packages}}, {{ic|~/.octave_hist}}
|
|
| {{ic|1=export OCTAVE_HISTFILE="$XDG_CACHE_HOME/octave-hsts"}}, {{ic|1=export OCTAVE_SITE_INITFILE="$XDG_CONFIG_HOME/octave/octaverc"}}

{{hc|$XDG_CONFIG_HOME/octave/octaverc|<nowiki>
source /usr/share/octave/site/m/startup/octaverc;
pkg prefix ~/.local/share/octave/packages ~/.local/share/octave/packages;
pkg local_list /home/<your username>/.local/share/octave/octave_packages;
</nowiki>}}
The {{ic|local_list}} option must be given an absolute path.
|-
| {{AUR|omnisharp-roslyn-bin}}
| {{ic|~/.omnisharp/}}
| [https://github.com/OmniSharp/omnisharp-roslyn/commit/e1353fb8ded7070d6e126b0b6030dac5d3d707ea]
| [https://github.com/OmniSharp/omnisharp-roslyn/issues/953]
| {{ic|1=export OMNISHARPHOME="$XDG_CONFIG_HOME/omnisharp"}}
|-
| {{Pkg|opam}}
| {{ic|~/.opam}}
|
| [https://github.com/ocaml/opam/issues/3766]
| {{ic|1=export OPAMROOT="$XDG_DATA_HOME/opam"}}
Both configuration and state data are stored in {{ic|OPAMROOT}}, so this solution is not fully compliant.
|- 
| {{Pkg|openai-codex}}
| {{ic|~/.codex/}}
| [https://github.com/openai/codex/commit/5fc9fc3e3ee5561c0470d5b21fa9569a8107e078 5fc9fc3]
| [https://github.com/openai/codex/pull/941]
| {{ic|1=export CODEX_HOME="$XDG_CONFIG_HOME"/codex}}
|-
| {{Pkg|openscad}}
| {{ic|~/.OpenSCAD}}
| [https://github.com/openscad/openscad/commit/7c3077b0f 7c3077b0f]
| [https://github.com/openscad/openscad/issues/125]
| Does not fully honour XDG Base Directory Specification, see [https://github.com/openscad/openscad/issues/373]

Currently it [https://github.com/openscad/openscad/blob/master/src/platform/PlatformUtils-posix.cc#L105 hard-codes] {{ic|~/.local/share}}.
|-
| {{AUR|packettracer}}
| {{ic|~/.packettracer}}, {{ic|~/pt}}
|
|
| Has GUI config to change PT installation directory, {{ic|~/pt/}} (''Options > Preferences > Administrative > User Folder''). This path is written to the file {{ic|~/.packettracer}}.
Log files may still be written to {{ic|~/pt/logs}} regardless of this setting until the {{ic|.packettracer}} file is recreated manually.
|-
| {{Pkg|parallel}}
| {{ic|~/.parallel}}
| [https://git.savannah.gnu.org/cgit/parallel.git/commit/?id=685018f532f4e2d24b84eb28d5de3d759f0d1af1 20170422]
|
| {{ic|1=export PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel}}
|-
| [[pass]]
| {{ic|~/.password-store}}
|
|
| {{ic|1=export PASSWORD_STORE_DIR="$XDG_DATA_HOME"/pass}}
|-
| [https://phar.io Phive]
| {{ic|~/.phive}}
|
| [https://github.com/phar-io/phive/issues/297]
Also [https://github.com/phar-io/phive/issues/286] and [https://github.com/phar-io/phive/issues/233]
| Since 0.14.5, it is possible to move the whole data directory.
{{ic|1=export PHIVE_HOME="$XDG_DATA_HOME/phive"}}
|-
| [[PHP]]
| {{ic|~/.php_history}}
| [https://www.php.net/manual/en/migration84.new-features.php#migration84.new-features.readline PHP 8.4]
| [https://github.com/php/php-src/issues/8546]
| {{ic|1=export PHP_HISTFILE="$XDG_STATE_HOME"/php/history}}
|-
| [[Pidgin]]
| {{ic|~/.purple}}
|
| [https://developer.pidgin.im/ticket/4911]
| {{ic|1=pidgin --config="$XDG_DATA_HOME"/purple}}
|-
| {{Pkg|platformio-core}}
| {{ic|~/.platformio}}
|
| [https://github.com/platformio/platformio-core/issues/2872]
| {{ic|1=export PLATFORMIO_CORE_DIR="$XDG_DATA_HOME"/platformio}}
|-
| [[PostgreSQL]]
| {{ic|~/.psqlrc}}, {{ic|~/.psql_history}}, {{ic|~/.pgpass}}, {{ic|~/.pg_service.conf}}
| 9.2
| [https://www.postgresql.org/docs/current/static/app-psql.html] [https://www.postgresql.org/docs/current/static/libpq-envars.html]
| {{ic|1=export PSQLRC="$XDG_CONFIG_HOME/pg/psqlrc"}}, {{ic|1=export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"}}, {{ic|1=export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"}}, {{ic|1=export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"}}

It is required to create both directories: {{ic|1=mkdir "$XDG_CONFIG_HOME/pg" && mkdir "$XDG_STATE_HOME"}}
|-
| [https://store.steampowered.com/app/108600/Project_Zomboid/ Project Zomboid]
| {{ic|~/Zomboid}}
| 
| 
| You can use [https://pzwiki.net/wiki/Startup_parameters#Game_arguments -cachedir="${XDG_DATA_HOME}"/Zomboid/] to change where the game files are stored.

The {{ic|projectzomboid.sh}} script also defines its own game data location with {{ic|GAMEDIR{{=}}"${HOME}/Zomboid"}}. If you use Steam, the script will be reset when the game updates, so editing it manually is not an option. But you can make a custom script that will always patch the main script if it gets restored by Steam:

{{hc|start.sh|output=
#!/usr/bin/env bash

SCRIPT="$(dirname "$0")/projectzomboid.sh"
sed 's{{!}}GAMEDIR{{!}}"${HOME}/Zomboid"{{!}}GAMEDIR{{=}}"${XDG_DATA_HOME}/Zomboid"{{!}}' -i "$SCRIPT"

exec "$SCRIPT" -cachedir="${XDG_DATA_HOME}"/Zomboid/ "$@"
}}

Name it {{ic|start.sh}} and put it where {{ic|projectzomboid.sh}} is, then make Steam execute {{ic|./start.sh}} instead of the main script with {{ic|./start.sh # %command%"}}, note that this will also launch the game without Steam Linux Runtime.
|-
| [[PulseAudio]]
| {{ic|~/.esd_auth}}
|
|
| Very likely generated by the {{ic|module-esound-protocol-unix.so}} module.  It can be configured to use a different location but it makes much more sense to just comment out this module in {{ic|/etc/pulse/default.pa}} or {{ic|"$XDG_CONFIG_HOME"/pulse/default.pa}}.
|-
| [[PuTTY]]
| {{ic|~/.putty/}}
| [https://git.tartarus.org/?p=simon/putty.git;a=commit;h=9952b2d5bd5c8fbac4f5731a805bce10fe4ce47c 9952b2d]
|
| Will use {{ic|$XDG_CONFIG_HOME/putty}} if it already exists. Creates {{ic|~/.putty}} if not. Prioritises {{ic|$XDG_CONFIG_HOME/putty}} if both exist. Tested in 0.74
|-
| {{Pkg|pyenv}}
| {{ic|~/.pyenv}}
|
| [https://github.com/pyenv/pyenv/issues/139] [https://github.com/pyenv/pyenv/issues/1789]
| {{ic|1=export PYENV_ROOT=$XDG_DATA_HOME/pyenv}}
|-
| [[python]]
| {{ic|~/.python_history}}
| [https://github.com/python/cpython/pull/13208#issuecomment-1877159768 v3.13]
| [https://bugs.python.org/issue29779] [https://bugs.python.org/issue20886] [https://github.com/python/cpython/pull/13208]
| All history from interactive sessions is saved to {{ic|~/.python_history}} by default since [https://bugs.python.org/issue5845 version 3.4] and {{ic|PYTHON_HISTORY}} since 3.13. For the history file, Python will not create any missing directories and only writes to the file if its directory exists. This can still be customized the same way as in older versions (see [https://docs.python.org/3/library/readline.html?highlight=readline#example this example]), including to [https://bugs.python.org/msg318437 use a custom path] or [https://bugs.python.org/msg265568 disable history saving].

[https://docs.python.org/3.13/using/cmdline.html#envvar-PYTHON_HISTORY PYTHON_HISTORY]: {{ic|1=export PYTHON_HISTORY=$XDG_STATE_HOME/python_history}}
[https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPYCACHEPREFIX PYTHONPYCACHEPREFIX]: {{ic|1=export PYTHONPYCACHEPREFIX=$XDG_CACHE_HOME/python}}
[https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE PYTHONUSERBASE]: {{ic|1=export PYTHONUSERBASE=$XDG_DATA_HOME/python}}
|-
| {{AUR|python-easyocr}}
| {{ic|~/.EasyOCR}}
| 
|
| {{ic|1=export EASYOCR_MODULE_PATH="$XDG_CONFIG_HOME/EasyOCR"}}
|-
| {{AUR|python-grip}}
| {{ic|~/.grip}}
|
|
| {{ic|1=export GRIPHOME="$XDG_CONFIG_HOME/grip"}}
|-
| {{Pkg|python-kivy}}
| {{ic|~/.kivy}}
|
|
| {{ic|1=export KIVY_HOME="$XDG_DATA_HOME/kivy"}}
|-
| {{Pkg|python-setuptools}}
| {{ic|~/.python-eggs}}
|
|
| {{ic|1=export PYTHON_EGG_CACHE="$XDG_CACHE_HOME"/python-eggs}}
|-
| {{Pkg|racket}}
| {{ic|~/.racketrc}}, {{ic|~/.racket}}
|
| [https://github.com/racket/racket/issues/2740]
| {{ic|1=export PLTUSERHOME="$XDG_DATA_HOME"/racket}}
|-
| {{Pkg|rbenv}}
| {{ic|~/.rbenv}}
|
| [https://github.com/rbenv/rbenv/issues/811] [https://github.com/rbenv/rbenv/issues/1146]
| {{ic|1=export RBENV_ROOT="$XDG_DATA_HOME"/rbenv}}
|-
| [[readline]]
| {{ic|~/.inputrc}}
|
|
| {{ic|1=export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc}}
|-
| {{Pkg|recoll}}
| {{ic|~/.recoll}}
|
|
| {{ic|1=export RECOLL_CONFDIR="$XDG_CONFIG_HOME/recoll"}}
|-
| {{AUR|redis}}
| {{ic|~/.rediscli_history}}, {{ic|~/.redisclirc}}
|
|
|{{ic|1=export REDISCLI_HISTFILE="$XDG_DATA_HOME"/redis/rediscli_history}}, {{ic|1=export REDISCLI_RCFILE="$XDG_CONFIG_HOME"/redis/redisclirc}}
|-
| [https://www.renpy.org/ Ren'Py]
| {{ic|~/.renpy}}
| [https://www.renpy.org/doc/html/changelog.html#renpy-7-5-0 7.5]
| [https://github.com/renpy/renpy/issues/1377]
| Save games are stored in {{ic|RENPY_PATH_TO_SAVES}}. Data that is shared across multiple games (e.g. sequals that let you import saves from previous entries) is stored in {{ic|RENPY_MULTIPERSISTENT}}. {{bc|export RENPY_PATH_TO_SAVES{{=}}"$XDG_DATA_HOME/renpy"
export RENPY_MULTIPERSISTENT{{=}}"$XDG_DATA_HOME/renpy_shared"}}
|-
| {{Pkg|ripgrep}}
|
|
| [https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file]
|{{ic|1=export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config}}
|-
| {{Pkg|rlwrap}}
| {{ic|~/.*_history}}
|
| [https://github.com/hanslub42/rlwrap/issues/25]
| {{ic|1=export RLWRAP_HOME="$XDG_DATA_HOME"/rlwrap}}
|-
| {{Pkg|ruby-bundler}}
| {{ic|~/.bundle}}
|[https://github.com/rubygems/rubygems/commit/4a120d82a730c92c78571bf1819a841ca1ac94a2 4a120d8]
|[https://github.com/rubygems/rubygems/pull/3545 Pull request 3545]
| 
 export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
 export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle/config
 export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle
For more info see [https://bundler.io/v2.5/man/bundle-config.1.html#CONFIGURE-BUNDLER-DIRECTORIES Bundler: bundle config].
|-
| {{AUR|ruby-solargraph}}
| {{ic|~/.solargraph/cache/}}
|
| [https://github.com/castwide/solargraph/blob/master/README.md]
| {{ic|1=export SOLARGRAPH_CACHE=$XDG_CACHE_HOME/solargraph}}
|-
| {{AUR|ruby-travis}}
| {{ic|~/.travis/}}
|
| [https://github.com/travis-ci/travis.rb/issues/219]
| {{ic|1=export TRAVIS_CONFIG_PATH=$XDG_CONFIG_HOME/travis}}
|-
| {{Pkg|ruff}}
| {{ic|.ruff_cache}}
|
| [https://github.com/charliermarsh/ruff/issues/1292]
| {{ic|1=export RUFF_CACHE_DIR=$XDG_CACHE_HOME/ruff}}
|-
| [[Rust#rustup]]
| {{ic|~/.rustup}}
|
| [https://github.com/rust-lang-nursery/rustup.rs/issues/247]
| {{ic|1=export RUSTUP_HOME="$XDG_DATA_HOME"/rustup}}
|-
| [[SageMath]]
| {{ic|~/.sage}}
|
|
| {{ic|1=export DOT_SAGE="$XDG_CONFIG_HOME"/sage}}
|-
| {{Pkg|sbt}}
| {{ic|~/.sbt}}
{{ic|~/.ivy2}}
|
| [https://github.com/sbt/sbt/issues/3681]
| {{ic|1=sbt -ivy "$XDG_DATA_HOME"/ivy2 -sbt-dir "$XDG_DATA_HOME"/sbt}} (beware [https://github.com/sbt/sbt/issues/3598])
|-
| {{AUR|sdkman-bin}}
| {{ic|~/.sdkman/}}
|
| [https://github.com/sdkman/sdkman-cli/pull/1069]
| {{ic|1=export SDKMAN_DIR="$XDG_DATA_HOME/sdkman"}}
Both configuration and data files are stored in {{ic|SDKMAN_DIR}}, so this solution does not fully conform to the XDG Base Directory Specification.
|-
| {{AUR|simplescreenrecorder}}
| {{ic|~/.ssr/}}
| [https://github.com/MaartenBaert/ssr/releases/tag/0.4.3 0.4.3]
| [https://github.com/MaartenBaert/ssr/issues/407]
[https://github.com/MaartenBaert/ssr/issues/813]
| Will use {{ic|$XDG_CONFIG_HOME/simplescreenrecorder/}} ONLY if it already was created otherwise defaults to {{ic|~/.ssr}}

{{ic|1=mv ~/.ssr "$XDG_CONFIG_HOME"/simplescreenrecorder}}
|-
| {{AUR|singularity-ce}}
| {{ic|~/.singularity}}
| [https://github.com/sylabs/singularity/releases/tag/v3.11.4 3.11.4]
| 
| {{ic|1=export SINGULARITY_CONFIGDIR="$XDG_CONFIG_HOME/singularity"}}, {{ic|1=export SINGULARITY_CACHEDIR="$XDG_CACHE_HOME/singularity"}}
|-
| [https://www.spacemacs.org/ spacemacs]
| {{ic|~/.spacemacs}}, {{ic|~/.spacemacs.d}}
| [https://github.com/syl20bnr/spacemacs/commit/e1eed07c30ea395fb9cfebc8ec3376dcffbace11]
| [https://github.com/syl20bnr/spacemacs/issues/3589]
| Move the {{ic|~/.spacemacs}} file.

{{ic|1=export SPACEMACSDIR="$XDG_CONFIG_HOME"/spacemacs}}, {{ic|mv ~/.spacemacs "$SPACEMACSDIR"/init.el}}

Other files need to be configured like Emacs.
|-
| {{AUR|spotdl}}
| {{ic|~/.spotdl}}
| [https://github.com/spotDL/spotify-downloader/releases/tag/v4.0.6 v4.0.6] ([https://github.com/spotDL/spotify-downloader/commit/3929caed5a2e8c2858a1dc3898ad75be263fdb96 3929cae])
| [https://github.com/spotDL/spotify-downloader/issues/1651]
| {{ic|1=mkdir "$XDG_DATA_HOME"/spotdl}}
|-
| [[SQLite]]
| {{ic|~/.sqliterc}}, {{ic|~/.sqlite_history}}
| [https://github.com/sqlite/sqlite/commit/6e8a33 3.44.0] for the config;<br>history is still in the legacy place
| 
| {{ic|XDG_CONFIG_HOME/sqlite3/sqliterc}}, {{ic|1=export SQLITE_HISTORY=$XDG_STATE_HOME/sqlite_history}}
|-
| {{Pkg|starship}}
| {{ic|~/.config/starship}}, {{ic|~/.cache/starship}}
| [https://github.com/starship/starship/pull/86] ([https://github.com/starship/starship/releases/tag/v0.2.0 v0.2.0]), [https://github.com/starship/starship/pull/1576] ([https://github.com/starship/starship/releases/tag/v0.45.0 v0.45.0])
| [https://github.com/starship/starship/issues/896#issuecomment-952402978]
| {{ic|1=export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship.toml}}, {{ic|1=export STARSHIP_CACHE="$XDG_CACHE_HOME"/starship}}
|-
| [[subversion]]
| {{ic|~/.subversion}}
|
| [https://issues.apache.org/jira/browse/SVN-4599] [https://mail-archives.apache.org/mod_mbox/subversion-users/201204.mbox/%3c4F8FBCC6.4080205@ritsuka.org%3e][https://mail-archives.apache.org/mod_mbox/subversion-dev/201509.mbox/%3C20150917222954.GA20331@teapot%3E]
| {{ic|1=alias svn="svn --config-dir \"$XDG_CONFIG_HOME\"/subversion"}}
|-
| {{Pkg|sudo}}
| {{ic|~/.sudo_as_admin_successful}}
| [https://www.sudo.ws/stable.html#1.9.6 1.9.6]
| [https://github.com/sudo-project/sudo/issues/56] [https://www.sudo.ws/repos/sudo/rev/d77c3876fa95]{{Dead link|2025|08|16|status=410}}
| Only present when activated at compile-time (default none). An admin_flag parameter can be used in /etc/sudoers since 1.9.6.
|-
| {{Pkg|task}}
| {{ic|~/.task}}, {{ic|~/.taskrc}}
|
|
| {{ic|1=export TASKDATA="$XDG_DATA_HOME"/task}}, {{ic|1=export TASKRC="$XDG_CONFIG_HOME"/task/taskrc}}}}, {{ic|[https://github.com/GothenburgBitFactory/taskwarrior/pull/2316 Fully supported in version 2.6] (note $XDG_CONFIG_HOME/task/taskrc ''must'' exist, otherwise taskwarrior will offer to create sample config in legacy $HOME/.taskrc location, even if $XDG_CONFIG_HOME is set [https://github.com/GothenburgBitFactory/taskwarrior/pull/2316#issuecomment-732821437][https://github.com/GothenburgBitFactory/taskwarrior/blob/112ac54a57adfb3cc2e6e60dbbb1f5c7d9db3e18/doc/man/task.1.in#L1451])
|-
| Local [[TeX Live]] TeXmf tree, TeXmf caches and config
| {{ic|~/texmf}}, {{ic|~/.texlive/texmf-var}}, {{ic|~/.texlive/texmf-config}}
|
|
| {{ic|1=export TEXMFHOME=$XDG_DATA_HOME/texmf}}, {{ic|1=export TEXMFVAR=$XDG_CACHE_HOME/texlive/texmf-var}}, {{ic|1=export TEXMFCONFIG=$XDG_CONFIG_HOME/texlive/texmf-config}}
|-
| [https://www.texmacs.org/ TeXmacs]
| {{ic|~/.TeXmacs}}
|
|
| {{ic|1=export TEXMACS_HOME_PATH=$XDG_STATE_HOME/texmacs}}
|-
| [[Thunderbird]]
| {{ic|~/.thunderbird/}}
|
| [https://bugzil.la/735285]
| A directory {{ic|~/.cache/thunderbird}} is created, containing subdirectories with the profile names, then the subdirectories {{ic|cache2}}, {{ic|startupCache}} and possibly others. This cache directory may also be set in about:config key browser.cache.disk.parent_directory [https://askubuntu.com/questions/171322/how-to-change-default-location-of-thunderbird-cache-directory].
|-
| {{AUR|tiptop}}
| {{ic|~/.tiptoprc}}
|
|
| This will still expect the {{ic|.tiptoprc}} file.
{{ic|tiptop -W "$XDG_CONFIG_HOME"/tiptop}}
|-
| {{Pkg|uncrustify}}
| {{ic|~/.uncrustify.cfg}}
|
|
| {{ic|1=export UNCRUSTIFY_CONFIG="$XDG_CONFIG_HOME"/uncrustify/uncrustify.cfg}}
|-
| [[Unison]]
| {{ic|~/.unison}}
|
|
| {{ic|1=export UNISON="$XDG_DATA_HOME"/unison}}
|-
| {{AUR|units}}
| {{ic|~/.units_history}}
|
|
| {{ic|1=units --history "$XDG_CACHE_HOME"/units_history}}
|-
| [[rxvt-unicode/Tips and tricks#Daemon-client|urxvtd]]
| {{ic|~/.urxvt/urxvtd-hostname}}
|
|
| {{ic|1=export RXVT_SOCKET="$XDG_RUNTIME_DIR"/urxvtd}}
|-
| [[Vagrant]]
| {{ic|~/.vagrant.d}}, {{ic|~/.vagrant.d/aliases}}
|
| [https://www.vagrantup.com/docs/other/environmental-variables.html]
| {{ic|1=export VAGRANT_HOME="$XDG_DATA_HOME"/vagrant}}, {{ic|1=export VAGRANT_ALIAS_FILE="$XDG_DATA_HOME"/vagrant/aliases}}
|-
| {{Pkg|vint}}
| {{ic|~/.vintrc.yaml}}, {{ic|.vintrc.yml}}, {{ic|.vintrc}}
| [https://github.com/Vimjas/vint/pull/235/commits/0f741ac2c 0f741ac2c]
| [https://github.com/Vimjas/vint/pull/235]
| Undocumented, but the code says {{ic|$XDG_CONFIG_HOME/.vintrc.yaml}} should work
|-
| [[virtualenv]]
| {{ic|~/.virtualenvs}}
|
|
| {{ic|1=export WORKON_HOME="$XDG_DATA_HOME/virtualenvs"}}
|-
| [[Visual Studio Code]]
| {{ic|~/.vscode-oss/}}
|
| [https://github.com/Microsoft/vscode/issues/3884]
| You can use {{ic|1=export VSCODE_PORTABLE="$XDG_DATA_HOME"/vscode}}, which is not documented and might break unexpectedly.
Setting this makes the editor look for the contents of {{ic|1=.config/Code - OSS}} in {{ic|1=$VSCODE_PORTABLE/user-data}}.

You can also run Visual Studio with the {{ic|1=--extensions-dir}} flag, such as {{ic|1=code --extensions-dir "$XDG_DATA_HOME/vscode"}}. This is documented and probably will not break as unexpectedly, as it {{ic|[https://github.com/microsoft/vscode/issues/329 has other use cases]}}.

|-
| [[VMware]]
| {{ic|~/.vmware/}}
|
| 
| The key {{ic|refvmx.defaultVMPath}} in {{ic|~/.vmware/preferences}} can be used to set the default location of virtual machines.
|-
| {{AUR|VSCodium}}
| {{ic|~/.vscode-oss/}}
|
| [https://github.com/VSCodium/vscodium/issues/561] [https://github.com/VSCodium/vscodium/issues/671]
| You can run VSCodium with the {{ic|1=--extensions-dir}} flag, such as {{ic|1=vscodium --extensions-dir "$XDG_DATA_HOME/vscode"}}. This however will not prevent the creation of  {{ic|1=~/.vscode-oss/}} directory.
You can also edit the value of {{ic|1=dataFolderName}} in {{ic|1=product.json}} file to {{ic|1=.local/share/codium}} or the path you want. But this workaround will have to be applies after every update of the pacakge, so you can install {{AUR|vscodium-xdg-dir-patch}} that does it automatically.
|-
| {{Pkg|w3m}}
| {{ic|~/.w3m}}
| [https://github.com/tats/w3m/commit/26284ff62781cbc14ff18593a8251409ca730098 26284ff]
| [https://sourceforge.net/p/w3m/feature-requests/31/] [https://github.com/tats/w3m/issues/130]
| {{ic|1=export W3M_DIR="$XDG_STATE_HOME/w3m"}}
|-
| {{AUR|wakatime}}
| {{ic|~/.wakatime/}}, {{ic|~/.wakatime.cfg}}
|
|
| {{ic|1=export WAKATIME_HOME="$XDG_CONFIG_HOME/wakatime"}}

The directory needs to be created manually

{{ic|1=mkdir "$XDG_CONFIG_HOME/wakatime"}}

|-
| [[wget]]
| {{ic|~/.wgetrc}}, {{ic|~/.wget-hsts}}
|
|
| {{ic|1=export WGETRC="$XDG_CONFIG_HOME/wgetrc"}} and add the following as an alias for wget: {{ic|1=wget --hsts-file="$XDG_STATE_HOME/wget-hsts"}}, or set the {{ic|1=hsts-file}} variable with an absolute path as wgetrc does not support environment variables: {{ic|1=echo hsts-file \= "$XDG_STATE_HOME"/wget-hsts >> "$XDG_CONFIG_HOME/wgetrc"}}
|-
| [[wine]]
| {{ic|~/.wine}}
|
| [https://bugs.winehq.org/show_bug.cgi?id=20888]
| [[Wine#Winetricks|Winetricks]] uses XDG-alike location below for [[Wine#WINEPREFIX|WINEPREFIX]] management:
{{ic|1=mkdir -p "$XDG_DATA_HOME"/wineprefixes}}, {{ic|1=export WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default}}
|-
| {{AUR|x3270}}
| {{ic|~/.x3270pro}}, {{ic|~/.c3270pro}}
|
|
| {{ic|1=export X3270PRO="$XDG_CONFIG_HOME"/x3270/config}}, {{ic|1=export C3270PRO="$XDG_CONFIG_HOME"/c3270/config}}

App also creates {{ic|~/.x3270connect}} but this is currently unsupported.
|-
| [[xbindkeys]]
| {{ic|~/.xbindkeysrc}}
|
|
| {{ic|1=xbindkeys -f "$XDG_CONFIG_HOME"/xbindkeys/config}}
|-
| [[xinit]]
| {{ic|~/.xinitrc}}, {{ic|~/.xserverrc}}
|
| [https://gitlab.freedesktop.org/xorg/app/xinit/issues/14]
| {{ic|1=export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc}}, {{ic|1=export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc}}
|-
| [[Xorg]]
| {{ic|~/.xsession}}, {{ic|~/.xsessionrc}}, {{ic|~/.Xsession}}, {{ic|~/.xsession-errors}}
|
|
| These can be added as part of your Xorg init script ({{ic|~/.xinitrc}}) or Xsession start script (which will often be based on {{ic|/etc/X11/Xsession}}).
Depending on where you have configured your {{ic|$XDG_CACHE_HOME}}, you might need to expand the paths yourself.
{{hc|# xsession start script|<nowiki>
USERXSESSION="$XDG_CACHE_HOME/X11/xsession"
USERXSESSIONRC="$XDG_CACHE_HOME/X11/xsessionrc"
ALTUSERXSESSION="$XDG_CACHE_HOME/X11/Xsession"
ERRFILE="$XDG_CACHE_HOME/X11/xsession-errors"
</nowiki>}}
Unlike most other examples in this table, actual X11 init scripts will vary a lot between installations.
|-
| {{Pkg|xorg-xauth}}
| {{ic|~/.Xauthority}}
|
|
| {{ic|1=export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority}}

Note that [[LightDM]] does not allow you to change this variable. If you change it nonetheless, you will not be able to login. Use [[startx]] instead or [https://askubuntu.com/a/961459 configure LightDM]. According to [https://unix.stackexchange.com/a/175331] [[SLiM]] has {{ic|~/.Xauthority}} hardcoded.

The [[SDDM]] Xauthority path can be changed in its own configuration files as shown below. Unfortunately, it is relative to the home directory.
{{hc|1=/etc/sddm.conf.d/xauth-path.conf|2=[X11]
UserAuthFile=.Xauthority}}

On Wayland, overriding this may cause Xorg programs to fail to connect to the Xwayland server. For example, both {{Pkg|kwin}} and {{Pkg|mutter}} use a randomized name, so it cannot be set to a static value.
|-
| {{Pkg|xorg-xrdb}}
| {{ic|~/.Xresources}}, {{ic|~/.Xdefaults}}
|
|
| Ultimately you [https://superuser.com/questions/243914/xresources-or-xdefaults should be] using {{ic|Xresources}} and since these resources are loaded via {{ic|xrdb}} you can specify a path such as {{ic|1=xrdb -load ~/.config/X11/xresources}}.
|-
| {{Pkg|yarn}}
| {{ic|~/.yarnrc}}, {{ic|~/.yarn/}}, {{ic|~/.yarncache/}}, {{ic|~/.yarn-config/}}
| [https://github.com/yarnpkg/yarn/commit/2d454b5 2d454b5]
| [https://github.com/yarnpkg/yarn/pull/5336] [https://github.com/yarnpkg/yarn/issues/2334]
| {{ic|1=alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'}}
|-
| {{Pkg|z}}
| {{ic|~/.z}}
|
| [https://github.com/rupa/z/issues/267]
| {{ic|1=export _Z_DATA="$XDG_DATA_HOME/z"}}
|-
| [[zsh]]
| {{ic|~/.zshrc}}, {{ic|~/.zprofile}}, {{ic|~/.zshenv}}, {{ic|~/.zlogin}}, {{ic|~/.zlogout}}, {{ic|~/.histfile}}, {{ic|~/.zcompdump}}, {{ic|~/.zcompcache}}
| [https://www.zsh.org/mla/workers/2013/msg00692.html]
| [https://www.zsh.org/mla/workers/2024/msg00012.html]
| {{ic|1=export ZDOTDIR=$HOME/.config/zsh}} to avoid the need of most [[Zsh#Startup/Shutdown files|zsh dotfiles]] in your home.
{{hc|"$XDG_CONFIG_HOME"/zsh/.zshrc|output=
# Use XDG dirs for completion and history files
[ -d "$XDG_STATE_HOME"/zsh ] <nowiki>||</nowiki> mkdir -p "$XDG_STATE_HOME"/zsh
HISTFILE="$XDG_STATE_HOME"/zsh/history
[ -d "$XDG_CACHE_HOME"/zsh ] <nowiki>||</nowiki> mkdir -p "$XDG_CACHE_HOME"/zsh
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME"/zsh/zcompcache
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-$ZSH_VERSION 
}}

Finally, if you use zsh as a login shell and chose to rely on either of the startup files {{ic|~/.zshenv}} ''or'', {{ic|~/.zprofile}} ''or'', {{ic|~/.zlogin}} to set important environment variables such as {{ic|ZDOTDIR}}, to bootstrap, there is no way around having the one file that sets {{ic|ZDOTDIR}} be in the default location. For context, an exception is if your wider system configuration does set the {{ic|ZDOTDIR}} environment variable before that.

|}

=== Hardcoded ===

{| class="wikitable sortable" style="width: 100%"
! Application
! Legacy Path
! Discussion
! Notes
|-
| [[adb]] & [https://developer.android.com/studio/index.html Android Studio]
| {{ic|~/.android/}}
|
| Despite [https://android.googlesource.com/platform/system/core/+/d5fcafaf41f8ec90986c813f75ec78402096af2d%5E%21/ appearances otherwise], adb will ''always'' generate {{ic|~/.android/adbkeys}}, though it will try keys in {{ic|ADB_VENDOR_KEYS}} as well.
|-
| {{Pkg|aegisub}}
| {{ic|~/.aegisub/}}
| [https://github.com/Aegisub/Aegisub/issues/226]
|
|-
| [[alpine]]
| {{ic|~/.pinerc}}, {{ic|~/.addressbook}}, {{ic|~/.pine-debug[1-4]}}, {{ic|~/.newsrc}}, {{ic|~/.mailcap}}, {{ic|~/.mime.types}}, {{ic|~/.pine-interrupted-mail}}
| 
| {{ic|1=alias alpine="alpine -p $XDG_CONFIG_HOME/alpine/pinerc"}}
In the above config file, some locations can be customized using options like {{ic|1=newsrc-path=}} and {{ic|1=address-book=}}.
|-
| [[aMule]]
| {{ic|~/.aMule}}
| [https://bugs.amule.org/view.php?id=1308] [http://forum.amule.org/index.php?topic=18056] [https://github.com/amule-project/amule/issues/254]
|
|-
| [https://directory.apache.org/studio/ Apache Directory Studio]
| {{ic|~/.ApacheDirectoryStudio}}
|
|
|-
| [https://christian.amsuess.com/tools/arandr/ ARandR]
| {{ic|~/.screenlayout}}
| [https://gitlab.com/arandr/arandr/-/issues/45]
|
|-
| [[Arduino]]
| {{ic|~/.arduino15}}, {{ic|~/.jssc}}
| [https://github.com/arduino/Arduino/issues/3915 will not fix]
|
|-
| {{Pkg|arduino-cli}}
| {{ic|~/.arduino15/}}
| [https://github.com/arduino/arduino-cli/pull/140]
| {{ic|1=mv ~/.arduino15 $XDG_CONFIG_HOME/arduino15}}
Specify the new directories used by Arduino CLI in arduino-cli.yaml as mentioned in the documentation [https://arduino.github.io/arduino-cli/latest/configuration/ here].
{{ic|1=alias arduino-cli='arduino-cli --config-file $XDG_CONFIG_HOME/arduino15/arduino-cli.yaml'}}
|-
|-
| [http://fixounet.free.fr/avidemux/ Avidemux]
| {{ic|~/.avidemux6}}
| [https://avidemux.org/smif/index.php/topic,19596.0.html]
|
|-
| {{Pkg|azote}}
| {{ic|~/.azotebg}}
| [https://github.com/nwg-piotr/azote/issues/154]
|
|-
| [https://github.com/TurningWheel/Barony Barony]
| {{ic|~/.barony}}
| [https://github.com/TurningWheel/Barony/issues/884]
|
|-
| [[Bash]]
| {{ic|~/.bashrc}}, {{ic|~/.bash_history}}, {{ic|~/.bash_profile}}, {{ic|~/.bash_login}}, {{ic|~/.bash_logout}}
| [https://savannah.gnu.org/support/?108134] [https://savannah.gnu.org/patch/?10431]
| {{ic|1=mkdir -p "$XDG_STATE_HOME"/bash}}
{{ic|1=export HISTFILE="$XDG_STATE_HOME"/bash/history}}

{{ic|bashrc}} can be sourced from a different location in {{ic|/etc/bash.bashrc}}.
Specify {{ic|--init-file <file>}} as an alternative to {{ic|~/.bashrc}} for interactive shells.
|-
| [[Chef|Berkshelf]]
| {{ic|~/.berkshelf/}}
|-
| {{Pkg|chatty}}
| {{ic|~/.chatty/}}
| [https://github.com/chatty/chatty/issues/273]
|
|-
| {{AUR|chirp-next}}
| {{ic|~/.chirp/}}
| [https://chirpmyradio.com/issues/8175]
| Last developer response [https://web.archive.org/web/20210127040026/http://intrepid.danplanet.com/pipermail/chirp_devel/2020-July/005987.html here]
|-
| [[Cinnamon]]
| {{ic|~/.cinnamon/}}
| [https://github.com/linuxmint/Cinnamon/issues/7807]
|
|-
| {{Pkg|cmake}}
| {{ic|~/.cmake/}}
| [https://gitlab.kitware.com/cmake/cmake/-/issues/22480]
| Used for the user package registry {{ic|~/.cmake/packages/<package>}}, detailed in {{man|7|cmake-packages|User Package Registry}} and [https://gitlab.kitware.com/cmake/community/wikis/doc/tutorials/Package-Registry the Package registry wiki page]. Looks like it's hardcoded, for example in [https://gitlab.kitware.com/cmake/cmake/blob/v3.12.1/Source/cmFindPackageCommand.cxx#L1221 cmFindPackageCommand.cxx].
|-
| {{Pkg|cmus}}
| {{ic|~/.config/cmus}}
| [https://github.com/cmus/cmus/pull/69]
| [https://github.com/cmus/cmus/issues/1283]
|-
| {{AUR|conan}}
| {{ic|~/.conan/}}
| [https://github.com/conan-io/conan/issues/2526]
| {{ic|1=export CONAN_USER_HOME="$XDG_CONFIG_HOME"}} will set the directory in which {{ic|.conan/}} is created. It was [https://docs.conan.io/en/latest/reference/env_vars.html#conan-user-home designed to simplify CI], but can be used here too.
|-
| [https://marketplace.visualstudio.com/items?itemName=Continue.continue Continue]
| {{ic|~/.continue/}}
| [https://github.com/continuedev/continue/issues/5397] [https://github.com/continuedev/continue/issues/558] [https://github.com/continuedev/continue/pull/2251]
| 
|-
| [[darcs]]
| {{ic|~/.darcs/}}
| [https://bugs.darcs.net/issue2453]
|
|-
| {{Pkg|dart}}
| {{ic|~/.dart}}, {{ic|~/.dart-tool}}, {{ic|~/.dartServer}}
| [https://github.com/dart-lang/sdk/issues/41560]
|
|-
| [[dbus]]
| {{ic|~/.dbus/}}
| [https://gitlab.freedesktop.org/dbus/dbus/issues/46]
| Consider using {{Pkg|dbus-broker}}, as it does not create or use this directory.
|-
| {{Pkg|devede}}
| {{ic|~/.devedeng}}
|
| Hardcoded [https://gitlab.com/rastersoft/devedeng/blob/f0893b3ff7b14723bd148db35bdfe2d284156d19/src/devedeng/configuration_data.py#L111 here]
|-
| [https://wiki.gnome.org/Apps/Dia Dia]
| {{ic|~/.dia/}}
|
|
|-
| [https://man.archlinux.org/man/dig.1 dig]
| {{ic|~/.digrc}}
|
|
|-
| {{Pkg|dotnet-sdk}}
| {{ic|~/.dotnet/}}, {{ic|~/.templateengine}}
| [https://github.com/dotnet/cli/issues/7569]
|
|-
| [[dropbox]]
| {{ic|~/.dropbox/}}
| [https://github.com/dropbox/nautilus-dropbox/issues/5]
|
|-
| [[Eclipse]]
| {{ic|~/.eclipse/}}
| [https://bugs.eclipse.org/bugs/show_bug.cgi?id=200809]
| Option {{ic|1=-Dosgi.configuration.area=@user.home/.config/..}} overrides but must be added to {{ic|"$ECLIPSE_HOME"/eclipse.ini"}} rather than command line which means you must have write access to {{ic|$ECLIPSE_HOME}}. (Arch Linux hard-codes {{ic|$ECLIPSE_HOME}} in {{ic|/usr/bin/eclipse}})
|-
| {{Pkg|emacs-slime}}
| {{ic|~/.slime/}}
| [https://github.com/slime/slime/issues/610]
[https://github.com/slime/slime/pull/787]
|
|-
| {{AUR|equalx}}
| {{ic|~/.equalx/}}
| [https://bugs.launchpad.net/equalx/+bug/2014460]
|
|-
| [[feh]]
| {{ic|~/.fehbg}}
| [https://github.com/derf/feh/issues/627]
| 
|-
| [https://www.fetchmail.info/ Fetchmail]
| {{ic|~/.fetchmailrc}}
|
|
|-
| [[Flatpak]]
| {{ic|~/.var/}}
| [https://github.com/flatpak/flatpak/issues/46] [https://github.com/flatpak/flatpak.github.io/issues/191] [https://github.com/flatpak/flatpak/issues/1651 will not fix]
|
|-
| {{AUR|gitkraken}}
| {{ic|~/.gitkraken/}}
| [https://feedback.gitkraken.com/suggestions/197923/support-for-moving-the-config-directory-on-linux]
|-
| {{AUR|google-cloud-cli}}
| {{ic|~/.gsutil/}}
| [https://github.com/GoogleCloudPlatform/gsutil/issues/991]
|
|-
| {{Pkg|gphoto2}}
| {{ic|~/.gphoto}}
| [https://github.com/gphoto/gphoto2/issues/249]
|
|-
| {{Pkg|gramps}}
| {{ic|~/.gramps/}}
| [https://gramps-project.org/bugs/view.php?id=8025]
| 2022 Support XDG base directory specification (for next release Gramps 5.2 ) - Patch https://github.com/gramps-project/gramps/pull/1368
|-
| {{Pkg|groovy}}
| {{ic|~/.groovy/}}
|
|
|-
| {{Pkg|grsync}}
| {{ic|~/.grsync/}}
| [https://sourceforge.net/p/grsync/feature-requests/15/]
|
|-
| [https://recordmydesktop.sourceforge.net/about.php gtk-recordMyDesktop]
| {{ic|~/.gtk-recordmydesktop}}
|
|
|-
| {{Pkg|hplip}}
| {{ic|~/.hplip/}}
| [https://bugs.launchpad.net/hplip/+bug/307152]
|
|-
| {{AUR|hstr}}
| {{ic|~/.hstr_blacklist}}, {{ic|~/.hstr_favorites}}
| [https://github.com/dvorka/hstr/issues/461]
| [https://github.com/dvorka/hstr/pull/560 Recent pull request] to fix this
|-
| {{Pkg|hydrogen}}
| {{ic|~/.hydrogen/}}
| [https://github.com/hydrogen-music/hydrogen/issues/643]
|
|-
| [https://www.idris-lang.org/ idris]
| {{ic|~/.idris}}
| [https://github.com/idris-lang/Idris-dev/pull/3456]
|
|-
| {{AUR|itch-setup-bin}}
| {{ic|~/.itch}}
| [https://github.com/itchio/itch/issues/2356 will not fix]
| You can move the Game install location in the app settings.
|-
| [[Java]] OpenJDK
| {{ic|~/.java/fonts}}
| [https://bugzilla.redhat.com/show_bug.cgi?id=1154277]
| {{ic|1=export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java}}
|-
| [[Java]] OpenJFX
| {{ic|~/.java/webview}}
|
|
|-
| {{Pkg|jgmenu}}
| {{ic|~/.jgmenu-lockfile}}
| [https://github.com/johanmalm/jgmenu/blob/3e48121dc28d06efb23c7901b7e138c2de167a84/src/lockfile.c#L11] [https://github.com/johanmalm/jgmenu/blob/4e45d04502fc5f77392bef0ff33b7bada0cf07d1/src/jgmenu_run#L7]
|
|-
| {{AUR|jitsi-meet}}
| {{ic|~/Downloads}}
| [https://github.com/jitsi/libjitsi/issues/518 libjitsi#518]
| Download dir hardcoded to {{ic|~/Downloads}} rather than {{ic|XDG_DOWNLOAD_DIR}} (from [[XDG user directories]])
|-
| [https://sourceforge.net/projects/jmol/ Jmol]
| {{ic|~/.jmol/}}
| [https://sourceforge.net/p/jmol/feature-requests/261/]
|
|-
| {{AUR|jsignpdf}}
| {{ic|~/.JSignPdf}}
| [https://github.com/intoolswetrust/jsignpdf/issues/252]
|
|-
| [https://julialang.org/ julia]
| {{ic|~/.juliarc.jl}}, {{ic|~/.julia_history}}, {{ic|~/.julia}}
| [https://github.com/JuliaLang/julia/issues/4630] [https://github.com/JuliaLang/julia/issues/10016]
| The trailing {{ic|:$JULIA_DEPOT_PATH}} is necessary. See [https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_DEPOT_PATH]
 export JULIA_DEPOT_PATH="$XDG_DATA_HOME/julia:$JULIA_DEPOT_PATH"
 export JULIAUP_DEPOT_PATH="$XDG_DATA_HOME/julia"
|-
| {{Pkg|kotlin}}
| {{ic|~/.kotlinc_history}}
|
| Related Konan issue: [https://youtrack.jetbrains.com/issue/KT-40763]
|-
| [[Kubernetes]]
| {{ic|~/.kube/}}
| [https://github.com/kubernetes/kubectl/issues/942][https://github.com/kubernetes/kubernetes/issues/56402][https://github.com/kubernetes/kubernetes/issues/115522]
| 
 export KUBECONFIG="$XDG_CONFIG_HOME/kube" 
 export KUBECACHEDIR="$XDG_CACHE_HOME/kube"
|-
| {{AUR|lbdb}}
| {{ic|~/.lbdbrc, ~/.lbdb/}}
| [https://github.com/RolandRosenfeld/lbdb/blob/eb162aa9da36f699cf821c6487210c7979fcd8ee/TODO#L18]
|
|-
| [[LightDM]]
| {{ic|~/.dmrc}}
| [https://github.com/canonical/lightdm/issues/59]
| Usually made by the greeter when setting a session. If you use autologin, you can modify {{ic|lightdm.conf}} as explained in [[LightDM#Enabling autologin]]
|-
| [https://lldb.llvm.org/ lldb]
| {{ic|~/.lldb}}, {{ic|~/.lldbinit}}, {{ic|~/.lldb/lldb-widehistory}}
| [https://github.com/llvm/llvm-project/issues/71426]
|
|-
| [[llpp]]
| {{ic|~/.config/llpp.conf}}
| [https://github.com/moosotc/llpp/issues/180]{{Dead link|2022|09|23|status=404}} (repo was deleted)
| Added in [https://repo.or.cz/w/llpp.git/commit/3ab86f0 3ab86f0] but subsequently reverted in [https://repo.or.cz/w/llpp.git/commit/e253c9f1 old:e253c9f1]/[https://github.com/criticic/llpp/commit/e253c9f1ca971b4298cfee889820ad60bded54af new:e253c9f1]
|-
| [[LMMS]]
| {{ic|~/.lmmsrc.xml}}
| [https://github.com/LMMS/lmms/issues/5869]
|
|-
| {{AUR|maliit-keyboard}}
| {{ic|~/.presage}}
|
| Maliit Keyboard uses an old, unmaintained library called Presage that creates {{ic|~/.presage}}. In 2024, Maliit Keyboard [https://github.com/maliit/keyboard/pull/146 dropped their Presage dependency] but as of version 2.3.1, this has not yet been included in a release. In the meantime, compile the master branch of {{AUR|maliit-keyboard}}.
|-
| {{Pkg|man-db}}
| {{ic|~/.manpath}}
| [https://gitlab.com/man-db/man-db/-/issues/39]
| 
|-
| [https://www.mathomatic.org/ mathomatic]
| {{ic|~/.mathomaticrc}}, {{ic|~/.matho_history}}
|
| History can be moved by using {{ic|rlwrap mathomatic -r}} with the {{ic|RLWRAP_HOME}} environment set appropriately.
|-
| [[MediaWiki]]
| {{ic|~/.mweval_history}} and {{ic|~/.mwsql_history}} (if $HOME is defined)
|
| If $HOME is not defined: {{ic|[MediaWiki]/maintenance/.mweval_history}} and {{ic|[MediaWiki]/maintenance/.mwsql_history}}.

Generated by the maintenance scripts [https://github.com/wikimedia/mediawiki/blob/master/maintenance/eval.php#L99-L100 eval.php] and [https://github.com/wikimedia/mediawiki/blob/master/maintenance/sql.php#L124-L125 sql.php].
|-
| {{AUR|megacmd}}
| {{ic|~/.megaCmd/}}
| [https://github.com/meganz/MEGAcmd/issues/403]
|
|-
| [[Minecraft]]
| {{ic|~/.minecraft/}}
| [https://bugs.mojang.com/browse/MCL-2563 will not fix]
| Third-party launcher {{Pkg|prismlauncher}} does not use the legacy path. Others found in [[Minecraft#Minecraft_mod_launchers]] may also use different paths.
|-
| {{Pkg|minicom}}
| {{ic|~/.minirc.dfl}}
|
| Upstream has a TODO entry for supporting configuration files under {{ic|~/.config/minicom}}. [https://salsa.debian.org/minicom-team/minicom/-/blob/fe9ff103/TODO#L27]
|-
| [https://www.mongodb.org/ mongodb]
| {{ic|~/.mongorc.js}}, {{ic|~/.dbshell}}
| [https://jira.mongodb.org/browse/DOCS-5652?jql=text%20~%20%22.mongorc.js%22]
| [https://stackoverflow.com/questions/22348604/the-mongorc-js-is-not-found-but-there-is-one/22349050#22349050 This Stack Overflow thread] suggests a partial workaround using command-line switch {{ic|--norc}}.
|-
| [[Mono]]
| {{ic|~/.mono/}}
| [https://github.com/mono/mono/pull/12764]
|
|-
|
| {{ic|~/.netrc}}
|
| Like {{ic|~/.ssh}}, many programs expect this file to be here.  These include projects like curl ({{ic|CURLOPT_NETRC_FILE}}), [[ftp]] ({{ic|NETRC}}), [[s-nail]] ({{ic|NETRC}}), etc.  While some of them offer alternative configurable locations, many do not such as w3m, wget and lftp.
|-
| {{Pkg|nim}}
| {{ic|~/.nimble}}
| [https://github.com/nim-lang/nimble/issues/217]
[https://github.com/nim-lang/Nim/issues/11340]
| Nimble will [https://github.com/nim-lang/nimble/#configuration try to load] {{ic|~/.config/nimble/nimble.ini}} at startup, set {{ic|nimbleDir}} there. You will have to change {{ic|nimblepath}} in the Nim compiler [https://nim-lang.org/docs/nimc.html#compiler-usage-configuration-files configuration file] as well.
|-
| {{Pkg|nyx}}
| {{ic|~/.nyx}}
|
| The project is not currently maintained
|-
| {{AUR|oh-my-bash-git}}
| {{ic|~/.osh-update}}
|
|
|-
| [[Ollama]]
| {{ic|~/.ollama}}
| [https://github.com/jmorganca/ollama/issues/228]
| Model locations can be set with:
{{ic|1=export OLLAMA_MODELS=$XDG_DATA_HOME/ollama/models}}

Source: [https://github.com/jmorganca/ollama/pull/897]
|-
| {{AUR|openshot}}
| {{ic|~/.openshot_qt}}
| [https://github.com/OpenShot/openshot-qt/issues/2440] [https://github.com/OpenShot/openshot-qt/issues/4477]
|
|-
| [[OpenSSH]]
| {{ic|~/.ssh}}
| [https://web.archive.org/web/20190925004614/https://bugzilla.mindrot.org/show_bug.cgi?id=2050 won't fix]
| Assumed to be present by many ssh daemons and clients such as DropBear and OpenSSH.
|-
| [https://www.palemoon.org/ palemoon]
| {{ic|~/.moonchild productions}}
| [https://forum.palemoon.org/viewtopic.php?f=5&t=9639]
|
|-
| {{AUR|parsec-bin}}
| {{ic|~/.parsec}}
|
|
|-
| {{AUR|pcsxr}}
| {{ic|~/.pcsxr}}
|
| A {{ic|-cfg}} flag exists, but can only be set relative to {{ic|~/.pcsxr}}.
|-
| [https://perf.wiki.kernel.org/index.php/Main_Page perf]
| {{ic|~/.debug}}
|
| Hardcoded in [https://github.com/torvalds/linux/blob/7d42e98182586f57f376406d033f05fe135edb75/tools/perf/util/config.c#L35 tools/perf/util/config.c]. Commit: [https://github.com/torvalds/linux/commit/45de34bbe3e1b8f4c8bc8ecaf6c915b4b4c545f8]
|-
| [[perl]]
| {{ic|~/.cpan}}, {{ic|~/perl5}}
| [https://github.com/andk/cpanpm/issues/149]
| Perl5's [https://github.com/andk/cpanpm CPAN] expects {{ic|~/.cpan}}
|-
| {{AUR|phoronix-test-suite}}
| {{ic|~/.phoronix-test-suite}}
| [https://github.com/phoronix-test-suite/phoronix-test-suite/issues/453]
| Partial workaround: [https://github.com/phoronix-test-suite/phoronix-test-suite/blob/ebcde81fcd5cd63956e5f8db5664262b5fd4ceb9/pts-core/pts-core.php#L123]
|-
| {{AUR|portfolio-performance-bin}}
| {{ic|~/.PortfolioPerformance/}}
| [https://github.com/buchen/portfolio/issues/1922]
| 
|-
| various [[shell]]s and [[display manager]]s
| {{ic|~/.profile}}
|
|
|-
| {{Pkg|psensor}}
| {{ic|~/.psensor}}
| [https://gitlab.com/jeanfi/psensor/-/issues/38]
|
|-
| {{Pkg|pulumi}}
| {{ic|~/.pulumi}}
| [https://github.com/pulumi/pulumi/issues/2534]
|
|-
| {{Pkg|python-streamlit}}
| {{ic|~/.streamlit}}
| [https://github.com/streamlit/streamlit/issues/2068]
|
|-
| {{Pkg|python-sympy}}
| {{ic|~/.sympy-history}}
| [https://github.com/sympy/sympy/issues/26363]
|
|-
| {{Pkg|python-tensorflow}}
| {{ic|~/.keras}}
| [https://github.com/tensorflow/tensorflow/issues/38831]
| The issues is for {{ic|tf.keras}} module
|-
| {{Pkg|quilt}}
| {{ic|~/.quiltrc}}
| 
| Fallback to {{ic|/etc/quilt.quiltrc}} if {{ic|~/.quiltrc}} does not exist.
|-
| [https://doc.qt.io/qt-5/qtdesigner-manual.html Qt Designer]
| {{ic|~/.designer}}
| [https://bugreports.qt.io/browse/QTCREATORBUG-26093]
| Fixed in upstream, scheduled for release with QT 7 (see Discussion link)
|-
| [[R]]
| {{ic|~/.Rprofile, ~/.Rdata, ~/.Rhistory}}
| 
| 
 R_HOME_USER="$HOME/.config/R"
 R_PROFILE_USER="$HOME/.config/R/profile"
 R_HISTFILE="$HOME/.config/R/history"
|-
| [https://rednotebook.sourceforge.net/ RedNotebook]
| {{ic|~/.rednotebook}}
| [https://github.com/jendrikseipp/rednotebook/issues/404]
|
|-
| [https://remarkableapp.github.io/linux.html Remarkable]
| {{ic|~/.remarkable}}
|
|
|-
| {{Pkg|renderdoc}}
| {{ic|~/.renderdoc}}
| [https://github.com/baldurk/renderdoc/pull/1741 will not fix]
|
|-
| [https://gerrit.googlesource.com/git-repo/ repo]
| {{ic|~/.repoconfig}}
| [https://bugs.chromium.org/p/gerrit/issues/detail?id=13997]
|
|-
| [[rpm]]
| {{ic|~/.rpmrc}} {{ic|~/.rpmmacros}}
| [https://github.com/rpm-software-management/rpm/issues/2153 Backlog]
| Workaround is to use --rcfile and --macros however this come with sideeffects.
|-
| {{AUR|run-mailcap}}
| {{ic|~/.mailcap}}
|
| {{ic|1=export MAILCAPS="$XDG_CONFIG_HOME/mailcap"}}
|-
| [[SANE]]
| {{ic|~/.sane/}}
|
| {{ic|scanimage}} creates a {{ic|.cal}} file there
|-
| {{Pkg|sbcl}}
| {{ic|~/.sbclrc}}
|
| {{hc|/etc/sbclrc|
(require :asdf)
(setf sb-ext:*userinit-pathname-function*
      (lambda () (uiop:xdg-config-home #P"sbcl/sbclrc")))
}}

Note that this requires root privileges and will change the location of {{ic|~/.sbclrc}} for all users. This can be mitigated by checking for an existing {{ic|~/.sbclrc}} inside the {{ic|lambda}} form.
|-
| [https://www.seamonkey-project.org/ SeaMonkey]
| {{ic|~/.mozilla/seamonkey}}
| [https://bugzil.la/726939]
|
|-
| [https://signal.org/ Signal Desktop]
| 
| [https://github.com/signalapp/Signal-Desktop/issues/4975]
| Currently keeps messages in {{ic|~/.config/Signal}}
|-
| [[Snap]]
| {{ic|~/snap/}}
| [https://bugs.launchpad.net/ubuntu/+source/snapd/+bug/1575053]
|
|-
| [https://www.gnu.org/software/solfege/solfege.html Solfege]
| {{ic|~/.solfege}}, {{ic|~/.solfegerc}}, {{ic|~/lessonfiles}}
| [https://savannah.gnu.org/bugs/index.php?50251]
|
|-
| [https://spamassassin.apache.org/ SpamAssassin]
| {{ic|~/.spamassassin}}
|
|
|-
| [[Steam]]
| {{ic|~/.steam}}, {{ic|~/.steampath}}, {{ic|~/.steampid}}
| [https://github.com/ValveSoftware/steam-for-linux/issues/1890]
| Many game engines (Unity 3D, Unreal) follow the specification, but then individual game publishers hardcode the paths in [https://www.ctrl.blog/entry/flatpak-steamcloud-xdg Steam Auto-Cloud] causing game-saves to sync to the wrong directory.
|-
| {{Pkg|stellarium}}
| {{ic|~/.stellarium/}}
| [https://github.com/Stellarium/stellarium/issues/76]
|
|-
| [https://storybook.js.org Storybook]
| {{ic|~/.storybook/}}
| [https://github.com/storybookjs/storybook/discussions/34405]
|
|-
| {{AUR|stremio}}
| {{ic|~/.stremio-server/|}}
| [https://github.com/Stremio/stremio-features/issues/268]
|
|-
| [https://github.com/spring-projects/sts4 sts4]
| {{ic|~/.sts4}}
| [https://github.com/spring-projects/sts4/issues/601]
| Pass JVM arg {{ic|1=-Dlanguageserver.boot.symbolCacheDir=$XDG_CACHE_HOME/sts4/symbolCache}}
|-
| {{Pkg|sweethome3d}}
| {{ic|~/.eteks/sweethome3d}}
| [https://sourceforge.net/p/sweethome3d/bugs/1256/]
| 
|-
| [[TeamSpeak]]
| {{ic|~/.ts3client}}
|
| {{ic|1=export TS3_CONFIG_DIR="$XDG_CONFIG_HOME/ts3client"}}
|-
| {{Pkg|terraform}}
| {{ic|~/.terraform.d/}}
| [https://github.com/hashicorp/terraform/issues/15389]
|
|-
| {{Pkg|texinfo}}
| {{ic|~/.infokey}}
|
| {{ic|info --init-file "$XDG_CONFIG_HOME/infokey"}}
|-
| [https://gitlab.archlinux.org/remy/texlive-localmanager tllocalmgr]
| {{ic|~/.texlive}}
|
|
|-
| {{AUR|urlview}}
| {{ic|~/.urlview}}
|
| Use fork {{AUR|urlview-xdg-git}} instead. The fork will use {{ic|XDG_CONFIG_HOME/urlview/config}}
|-
| {{AUR|viber}}
| {{ic|~/.ViberPC}}
|
|
|-
| [http://www.vimperator.org/ vimperator]
| {{ic|~/.vimperatorrc}}
| [https://web.archive.org/web/20200514081339/http://www.mozdev.org/pipermail/vimperator/2009-October/004848.html]
| {{ic|1=export VIMPERATOR_INIT=":source $XDG_CONFIG_HOME/vimperator/vimperatorrc"}}

{{ic|1=export VIMPERATOR_RUNTIME="$XDG_CONFIG_HOME"/vimperator}}
|-
| {{Pkg|visidata}}
| {{ic|~/.visidata}}
| [https://github.com/saulpw/visidata/issues/487]
|
|-
| {{AUR|wego}}
| {{ic|~/.wegorc}}
| [https://github.com/schachmat/wego/issues/116]
|
|-
| [https://github.com/TibixDev/winboat winboat]
| {{ic|~/.winboat}}
| [https://github.com/TibixDev/winboat/issues/77]
|
|-
| [https://w1.fi/ wpa_cli]
| {{ic|~/.wpa_cli_history}}
|
| {{ic|1=alias wpa_cli='HOME=$XDG_STATE_HOME wpa_cli'}}
|-
| {{AUR|x2goclient}}
| {{ic|~/.x2goclient}}
|
| {{ic|1=alias x2goclient="x2goclient --home=$HOME/.config"}}
|-
| {{Pkg|xpdf}}
| {{ic|~/.xpdfrc}}
| [https://forum.xpdfreader.com/viewtopic.php?p=45060&sid=ef425114578015df4600847a5330a5ce]
|
|-
| {{AUR|xrdp}}
| {{ic|~/thinclient_drives}}
|
| For the directory {{ic|~/thinclient_drives}}, you may consider editing {{ic|/etc/xrdp/sesman.ini}} and modifying the section {{ic|[Chansrv]}} following the example config.
|-
| [https://github.com/XVimProject/XVim2 XVim2]
| {{ic|~/.xvimrc}}
| [https://github.com/XVimProject/XVim2/issues/389]
|
|-
| {{AUR|yabridge-bin}}
| {{ic|~/.vst/yabridge/}}, {{ic|~/.vst3/yabridge/}}, {{ic|~/.clap/yabridge/}}
| [https://github.com/robbert-vdh/yabridge/issues/191 will not fix]
|
|-
| [https://yardoc.org YARD]
| {{ic|~/.yard}}
| [https://github.com/lsegal/yard/issues/1230]
| Would accept Pull Request if anyone want to implement it.
|-
| [https://nmap.org/zenmap/ zenmap] {{Pkg|nmap}}
| {{ic|~/.zenmap}}
| [https://seclists.org/nmap-dev/2012/q2/163] [https://github.com/nmap/nmap/issues/590]
|
|-
| {{AUR|zoom}}
| {{ic|~/.zoom}}
|
| Unrecommended: setting the following variable moves the contents of .zoom but the directory itself always gets created. Moreover, it breaks some functionalities eg. being able to start a meeting. {{ic|1=export SSB_HOME="$XDG_DATA_HOME"/zoom}}
|-
| {{AUR|zotero-bin}}
| {{ic|~/.zotero}} {{ic|~/Zotero}}
| [https://github.com/zotero/zotero/issues/1203]
| {{ic|~/Zotero}} default location for data can be changed from GUI: Edit -> Preferences -> Advanced -> Data Directory Location -> Custom
|}

== Tools ==

The tool {{aur|xdg-ninja}} detects unwanted files/directories in {{ic|$HOME}} which can be moved to XDG base directories. See [https://github.com/b3nj5m1n/xdg-ninja#xdg-ninja README] for examples.

The tool {{pkg|boxxy}} can be used to wrap applications which do not respect the XDG base directories and redirect any unwanted files.

The tool [https://github.com/danisztls/ephemeral ephemeral] can be used to link chromium/electron caches that normally live in {{ic|XDG_CONFIG_HOME}} to locations in {{ic|XDG_CACHE_HOME}}.

== Libraries ==

; C
: [https://github.com/Jorengarenar/libXDGdirs libXDGdirs]
: [https://github.com/devnev/libxdg-basedir libxdg-basedir]
: [https://github.com/Cloudef/chck/tree/master/chck/xdg C99: Cloudef's simple implementation].

; C++
: [https://github.com/azubieta/xdg-utils-cxx xdg-utils-cxx]
: [https://sr.ht/~danyspin97/xdgpp xdgpp]

; Go
: [https://github.com/adrg/xdg adrg/xdg]
: [https://github.com/ProtonMail/go-appdir go-appdir] (deprecated, archived)
: [https://github.com/shibukawa/configdir configdir] (deprecated, abandoned)
: [https://github.com/kyoh86/xdg kyoh86/xdg] (deprecated, archived)

; Haskell
: Officially in [https://hackage.haskell.org/package/directory directory] since 1.2.3.0 [https://github.com/haskell/directory/commit/ab9d0810ce ab9d0810ce].
: [https://hackage.haskell.org/package/xdg-basedir xdg-basedir]

; JVM: Java, Kotlin, Clojure, Scala, ...
: [https://codeberg.org/dirs/directories-jvm directories-jvm]

; Perl
: [https://search.cpan.org/dist/File-BaseDir/lib/File/BaseDir.pm File-BaseDir] (old spec 0.6)
: [https://metacpan.org/pod/File::XDG File-XDG]

; Python
: [https://freedesktop.org/wiki/Software/pyxdg/ pyxdg]
: [https://github.com/ActiveState/appdirs appdirs] (abandoned)
: [https://github.com/platformdirs/platformdirs platformdirs]

; Ruby
: [https://github.com/bkuhlmann/xdg bkuhlmann/xdg]
: [https://github.com/rubyworks/xdg rubyworks/xdg] (deprecated, abandoned)

; Rust
: [https://codeberg.org/dirs/directories-rs directories-rs]
: [https://github.com/whitequark/rust-xdg rust-xdg]

; Swift
: [https://github.com/Frizlab/swift-xdg swift-xdg]

; Vala
: Builtin support via [https://valadoc.org/#!api=glib-2.0/GLib.Environment GLib.Environment].
: See {{ic|get_user_cache_dir}}, {{ic|get_user_data_dir}}, {{ic|get_user_config_dir}}, etc.

== Tips and tricks ==

=== Hiding unwanted directories ===

For directories which cannot be relocated, some desktop environments such as [[KDE]] allow you to hide them:

 $ echo ''path'' >> ~/.hidden

''path'' is the path of the file/directory, relative to the parent directory of {{ic|.hidden}}.

== See also ==

* [https://wiki.gnome.org/Initiatives/GnomeGoals/XDGConfigFolders GNOME Goal: XDG Base Directory Specification Usage]
* [https://web.archive.org/web/20180827160401/plus.google.com/+RobPikeTheHuman/posts/R58WgWwN9jp Rob Pike: "Dotfiles" being hidden is a UNIXv2 mistake].
* {{man|1|systemd-path}}
* {{man|7|file-hierarchy}}
* [https://github.com/grawity/dotfiles/blob/master/.dotfiles.notes Grawity's notes on dotfiles].
* [https://github.com/grawity/dotfiles/blob/master/.environ.notes Grawity's notes on environment variables].
* [https://ploum.net/207-modify-your-application-to-use-xdg-folders/ ploum.net: Modify Your Application to use XDG Folders].
* The [https://pcgamingwiki.com/wiki/Home PCGamingWiki] attempts to document whether or not Linux PC games follow the XDG Base Directory Specification.

