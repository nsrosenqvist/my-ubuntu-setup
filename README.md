Step-runner
===============

This utility is meant to execute larger jobs in steps. It enables automatic execution of scripts in numbered order and also provides methods of managing and rearranging scripts. Very convenient to use for system configuration steps after a reinstall. The way I myself am using this script is that I have a git repository where I store all my configurations and can simply clone the repository whenever I need to set up my development environment. Check out [my configuration](https://github.com/nsrosenqvist/dev-setup) for an example, which you are free to fork and do whatever with.

Originally this project was fork of Saw Hewitt's ["Ubuntu Post Install Script"](https://github.com/snwh/ubuntu-post-install) but has been completely redone to use a different workflow. It's licensed under GPLv3, see the "LICENSE" file for more information.

## Installation

Install the utility with this one-liner below:

```bash
git clone https://github.com/nsrosenqvist/step-runner.git && cd step-runner && sudo make install
```

## Usage:

You can either pass the path to a directory where the job is located or if no arguments are set it will work out of the current working directory. If a file called "globals.conf" is found in the directory it's automatically loaded so that it's content is accessible to every other step of the job.

A configuration step is basically a BASH-script where you can add PPA's, install applications, edit files or whatever you wish. The file name should end in `.step` instead of `.sh` to be picked up by the step-runner.

You can either use your own editor to edit the scripts or use the menu from the script which launches an editor instance whenever editing or creating steps. The latter is the preferred way since it will make sure that the files are correctly named and numbered. If you've been mucking around too much with the files outside of the script's editor, you can run "Reorder steps" from the "Cleanup" menu and it will rename them appropriately.
