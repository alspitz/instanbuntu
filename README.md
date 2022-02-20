# Instanbuntu

[instanbuntu.sh](instanbuntu.sh) can be used to quickly (~10 - 15 minutes with a fast internet connection) install an Ubuntu system inside an existing Linux system.
This is what I have used to run ROS inside a non Ubuntu machine for many years now and have had no issues.
This is also useful if you want to run a newer or older Ubuntu version than your host computer.
For example, if a server runs on Ubuntu 14.04, Ubuntu 16.04 can be setup in this way for continuous integration tests.
Additionally, this allows you to have N different Ubuntu installations of various versions, each with an isolated filesystem.

The only dependencies on the host system are the programs debootstrap and schroot.

This is known to work with Ubuntu 14.04 (ROS Indigo), Ubuntu 16.04 (ROS Kinetic), Ubuntu 18.04 (ROS Bionic), and Ubuntu 20.04 (ROS Noetic) (see below), but others flavors are supported by changing the appropriate names at the top of the script.
While running, you will need to provide your password for sudo access.
The script is designed so that it can be re-run upon failure, but some harmful edge cases may be possible.
When in doubt, you can consult the script to continue manual installation upon a failure.
If you do experience a failure, please feel free to file an issue or submit a pull request.

# Tested Configurations

| Ubuntu Flavor | ROS Flavor |
| -----         | -----  |
| Trusty (14.04) | Indigo |
| Xenial (16.04) | Kinetic |
| Zesty (17.04) | Lunar |
| Bionic (18.04) | Melodic |
| Focal (20.04) | Noetic |

# Known Limitations

The chosen Ubuntu flavor must have packages for the chosen ROS flavor. e.g. Ubuntu Artful will not work with ROS Lunar, because Lunar is not officially supported on Artful and thus does not have the packages by default.
A manual installation may still work however.

Using an End of Life Ubuntu flavor, such as Zesty, requires changing the deboostrap URL from archive.ubuntu.com to old-releases.ubuntu.com.

In order to run 3D accelerated programs such as rviz, additional graphics drivers such as nvidia-384 need to be installed manually.

# Troubleshooting

## chown: invalid group: 'root:staff' when using apt.

Run `sudo groupadd staff` from inside the chroot.

# Tips

For easy opening of a terminal, set up a keyboard shortcut to directly open a terminal inside the chroot.
For example, if using xterm, bind a keyboard shortcut to xterm -e "schroot -c xenial-insta" (change terminal program and chroot name appropriately).
