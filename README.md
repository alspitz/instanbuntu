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

# Usage

* Make sure you have the dependencies: `debootstrap` and `schroot`.
* Run instanbuntu.sh from a folder where you wish to store the Ubuntu installation.
* If successful, you should be able to enter the chroot using `schroot` or `schroot -c <ubuntu flavor>-insta`.

Example:

```
git clone https://github.com/alspitz/instanbuntu ~/instanbuntu/
mkdir ~/chroots
cd ~/chroots
../instanbuntu/instanbuntu.sh
```

# How does this compare to Docker?

Docker is a widely used container system that is a bit heaver and provides more containerization than just the chroot used by `schroot`. Instanbuntu can be a good docker alternative if you want something a bit more lightweight and don't want all the bells and whistles that docker comes with, such as image versioning, image layers, the Dockerfile specification, etc.

Instanbuntu essentially just changes the root of the file system to a subfolder containing a separate Ubuntu installation.

See below for some discussions on chroot vs Docker:

* https://stackoverflow.com/questions/46450341/chroot-vs-docker
* https://devops.stackexchange.com/questions/2826/difference-between-chroot-and-docker

Docker is far more popular than chroot-based methods however, and there is a lot more documentation and help on the internet for Docker.
Please be warned that this script just sets up a chroot with Ubuntu and ROS and provides no further tools for managing the container.
You may have to run administrative commands inside the chroot to set up the system however you like.

Note that unlike Docker, there is no concept of "starting" or "stopping" the container, and any changes you make will persist.
This may be an advantage or disadvantage, depending on your needs.
Running `schroot` enters the chroot and commands run from that terminal will run inside that chroot's Ubuntu installation.
For example, if you run a command inside the chroot that "messes up" the chroot, you can't easily undo it (although you can certainly remove the entire container by `rm`ing the folder and then reinstall it without affecting the host system).

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

For example, to install the appropriate NVIDIA drivers in the Ubuntu 20.04 chroot, you will need to visit the [Cuda toolkit archives](https://developer.nvidia.com/cuda-toolkit-archive) and follow the instructions for the **Cuda version running on the host system**.
For example, if your host system is running nvidia driver version 520.61.05, cuda version 11.8, you will need to install that exact version in the chroot (for the Ubuntu version of the chroot).
You can obtain the version in use on the host system by running `nvidia-smi`.
Running `nvidia-smi` in the chroot should display the same information.
If you get an error message reading "Failed to initialize NVML: Driver/library version mismatch", then you likely have the wrong version of the drivers installed in the chroot.

# Troubleshooting

## chown: invalid group: 'root:staff' when using apt.

Run `sudo groupadd staff` from inside the chroot.

You may also need to create other groups as needed when installing certain packages.

## cannot stat /etc/networks: No such file or directory

Comment out "networks" in `/etc/schroot/default/nssdatabases` ([https://bbs.archlinux.org/viewtopic.php?id=100039](https://bbs.archlinux.org/viewtopic.php?id=100039))

## Bind mount /dev/shm

It's a good idea to uncomment the `/dev/shm` line in `/etc/schroot/default/fstab`, especially if you get any strange "Permission Denied" errors.
Many programs can subtly fail if they don't have access to `/dev/shm`.

# Tips

For easy opening of a terminal, set up a keyboard shortcut to directly open a terminal inside the chroot.
For example, if using xterm, bind a keyboard shortcut to xterm -e "schroot -c xenial-insta" (change terminal program and chroot name appropriately).
