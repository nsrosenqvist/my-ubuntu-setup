My-Ubuntu-Setup
===============

This utility was forked from Saw Hewitt's ["Ubuntu Post Install Script"](https://github.com/snwh/ubuntu-post-install) but has been completely redone to use a different workflow. It's licensed under GPLv3, see the "COPYING" file for more information.

The purpose of this script is to easily set up your personal environment on multiple computers and to easily restore it after a reinstallation of the OS.

#Usage:

Either download and install to your path and launch the script with `my-ubuntu-setup` or you can run it directly from the source folder with `bash my-ubuntu-setup`.

On first run the script creates a directory under `~/.config/` where all configuration steps will be stored. It also creates a config-file called `globals.conf` where you can edit variables which can be used by configuration steps, e.g. `emailaddress="your-name@example.com"`.

A configuration step is basically a BASH-script where you can add PPA's, install applications, edit files or whatever you wish.

You can either use your own editor to edit the scripts in the `~/.config/my-ubuntu-setup` directory or use the menu from the script which launches a nano instance whenever editing or creating steps. The latter is the preferred way since it will make sure that the files are correctly named and numbered. If you've been mucking around too much with the files outside of the script's editor, you can run "Reorder steps" from the "Cleanup" menu and it will rename them appropriately.

The way I myself am using this script is that I have a git repository, which I pull to `~/.config/my-ubuntu-setup`, where I store all my configurations and can simply clone the repository whenever I need to set up my development environment. Check out [my configuration](https://github.com/nsrosenqvist/env-setup) for an example.

Feel free to copy, improve and distribute.
