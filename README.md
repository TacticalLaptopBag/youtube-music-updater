# youtube-music-updater

This is part of a little experiment of mine where I rewrite some of my Python tools in Lua,
just to get a feel for the language and to see if I want to fully switch to Lua
for writing simple tools.

youtube-music-updater is a command line tool to keep the [YouTube Music](https://github.com/th-ch/youtube-music/) AppImage up-to-date.
It's always been a bother for me to manually download and move an AppImage whenever there's an update.
So, this script does it for me.

## Usage

Simply run `youtube-music-updater` and follow the prompts.

## Install

Note that because this is specifically for AppImages, this only supports Linux.

First, run `./depends.sh` to get dependencies.
If you are not running Debian/Ubuntu or any of its derivatives,
you will need to check `depends.txt` for required packages.

Finally, just run `sudo ./install.sh` to install to the system,
or just `./install.sh` to install to your user folder.
You can specify a custom install path by setting `INSTALL_DIR`.
