Demo of some minor updates to https://github.com/simondotm/vgm-packer
and https://github.com/simondotm/vgm-player-bbc. Split a VGC file into
its streams, and arrange the streams in ROM bank-sized groups. The
music occupies none of main RAM, can be larger than main RAM, and on
the Master it won't have to possibly spill over into HAZEL.

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

You'll also get `build/vgcplayer_icepalace.ssd`, that plays Beyond The
Ice Palace (David Whittaker) using the modified VGC player. The music
data is 31 KB, occupying 2 sideways RAM banks and a bit of main RAM.

A Windows-friendlier build process may follow...
