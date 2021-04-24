#!/bin/bash

###############################################################################
# Usage:
#   ./instanbuntu.sh will generate a folder in the CWD named ${flavor} that
#   contains the Ubuntu system.
#
# Dependencies:
# - debootstrap
# - schroot
# - internet connection
# - a couple GB of disk space
###############################################################################

flavor=focal
ros_flavor=noetic
arch=amd64

set -e
set -u
set -o pipefail

chroot_name="${flavor}-insta"

chroot_dir="$(pwd)/${flavor}"

if [ -e "${chroot_dir}" ]; then
  echo "WARNING: \"${chroot_dir}\" already exists."
  echo "	Press enter to assume the debootstrap succeeded and proceed without it."
  echo "	The alternative is to"
	echo "		exit with Control C,"
	echo " 		delete \"${chroot_dir}\","
	echo "		and restart."
  read
else
  mkdir -p "${chroot_dir}"
  sudo debootstrap --arch="${arch}" "${flavor}" "${flavor}"/ http://archive.ubuntu.com/ubuntu
fi

schroot_conf_entry="
[${chroot_name}]
description=${flavor} instanbuntu
type=directory
directory=${chroot_dir}
users=${USER}
root-users=${USER}
root-groups=${USER}
aliases=default"

sources_add=" universe multiverse"

bashrc_check="
if [ \\\\\\\${SCHROOT_USER} ]; then
  source /opt/ros/${ros_flavor}/setup.bash
  export DISPLAY=${DISPLAY}
fi"

gsl_package="libgsl-dev"
if [ "${flavor}" == "trusty" ]; then
  gsl_package="libgsl0-dev"
fi

bunt_script="#!/bin/bash

set -e
set -u
set -o pipefail

sudo groupadd staff || true
sudo groupadd messagebus || true

# https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1325142/comments/38
if [ \\\"${flavor}\\\" == \\\"trusty\\\" ]; then
  sudo dpkg-divert --local --add /etc/init.d/systemd-logind
  sudo ln -sf /bin/true /etc/init.d/systemd-logind
fi

# Needed on 18.04 to add key.
sudo apt-get install gnupg -y || true

grep \\\"${sources_add}\\\" /etc/apt/sources.list > /dev/null || sudo sed -i '\\\$s/\\\$/${sources_add}/' /etc/apt/sources.list

sudo sh -c 'echo \\\"deb http://packages.ros.org/ros/ubuntu \\\$(lsb_release -sc) main\\\" > /etc/apt/sources.list.d/ros-latest.list'
sudo -E apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

sudo apt-get update
sudo apt-get install vim build-essential git -y
sudo apt-get install ros-${ros_flavor}-ros-base ros-${ros_flavor}-tf2-ros -y
if [[ "$ros_flavor" == "noetic" ]]; then
  sudo apt-get install python3-wstool -y
  sudo apt-get install python3-catkin-tools -y
  sudo apt-get install python3-osrf-pycommon -y
  sudo apt-get install python3-rosdep
else
  sudo apt-get install python-wstool -y
  sudo apt-get install python-catkin-tools -y
  sudo apt-get install python-rosdep
fi

sudo rosdep init || true
rosdep update

grep \\\"${ros_flavor}\\\" ~/.bashrc || echo \\\"${bashrc_check}\\\" >> ~/.bashrc

sudo apt-get install libarmadillo-dev libeigen3-dev libyaml-cpp-dev ${gsl_package} -y
sudo apt-get install ros-${ros_flavor}-rviz ros-${ros_flavor}-xacro -y || true"

schroot_conf="/etc/schroot/schroot.conf"

# Only add the schroot entry if it's not already present.
grep "\[${chroot_name}\]" "${schroot_conf}" > /dev/null || sudo sh -c "echo \"${schroot_conf_entry}\" >> ${schroot_conf}"

script_filename="/setup_${flavor}_chroot.sh"

# Copy Ubuntu install script into Ubuntu.
sudo sh -c "echo \"${bunt_script}\" > \"${chroot_dir}/${script_filename}\""
sudo chmod +x "${chroot_dir}/${script_filename}"

# Ensure we have sudo access inside.
sudo grep "${USER}" "${chroot_dir}/etc/sudoers" > /dev/null || sudo sh -c "echo \"${USER}	ALL=(ALL:ALL) ALL\" >> \"${chroot_dir}/etc/sudoers\""

# Sometimes this file references unknown users leading to apt-get errors.
sudo sh -c "sudo cat /dev/null > \"${chroot_dir}/var/lib/dpkg/statoverride\""

echo "Going into the new chroot..."
schroot --chroot=${chroot_name} "${script_filename}"
echo "Enter the new Ubuntu with \"schroot -c ${chroot_name}\""
