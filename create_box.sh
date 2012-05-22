#!/bin/bash

rm -f package.box Vagrantfile
vagrant package --base vagrant-fedora16-gnome-32bit
vagrant box remove vagrant-fedora16-gnome-32bit
vagrant box add vagrant-fedora16-gnome-32bit package.box
vagrant init vagrant-fedora16-gnome-32bit
vagrant up
vagrant halt
vagrant up
