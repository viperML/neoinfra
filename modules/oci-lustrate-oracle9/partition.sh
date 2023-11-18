#!/usr/bin/env bash

sgdisk --delete 1 /dev/sda
sgdisk --delete 2 /dev/sda

partprobe

sgdisk --new 1:0:+500M /dev/sda
sgdisk --new 2:0:0 /dev/sda

partprobe

sgdisk --typecode 1:ef00 /dev/sda
sgdisk --change-name 1:esp /dev/sda
mkfs.vfat -F32 /dev/disk/by-partlabel/esp

sgdisk --typecode 2:8200 /dev/sda
sgdisk --change-name 2:swap /dev/sda
mkswap /dev/disk/by-partlabel/swap

partprobe