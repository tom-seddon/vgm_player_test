Demo of some minor updates to https://github.com/simondotm/vgm-packer
and https://github.com/simondotm/vgm-player-bbc, making it easier to
play larger music files.

Rather than have one big VGC file, that's one big unit with all the
streams back to back, save out each stream individually, and allow the
caller to put each one where it wants, with a per-stream ROMSEL
setting. It's then possible to put different streams in different
sideways RAM banks.



# how to build

Prerequisites:

* [64tass](http://tass64.sourceforge.net/) on PATH
* [BeebAsm](https://github.com/stardot/beebasm) on PATH
* Python 2.x on PATH
* POSIX-type OS with the usual POSIX-type stuff (if on Windows, Git
  Bash might work)
* GNU Make

To build, type `make`.

You'll get `build/vgm_player_test.ssd`, that plays Ikari Union (Jeroen
Tel/Mad Max) using the standard VGC player. The music data is quite
small and fits entirely in main RAM.

You'll also get `build/vgcplayer_streams_icepalace.ssd`, that plays
Beyond The Ice Palace (David Whittaker) using the stream-oriented VGC
player. The music data is 31 KB, occupying 2 sideways RAM banks and a
bit of main RAM.

A Windows-friendlier build process may follow...
