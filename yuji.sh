#!/bin/sh
        "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"

ROOTFS_DIR=./Yuji
export PATH=$PATH:~/.local/usr/bin

max_retries=50
timeout=1

ARCH=$(uname -m)
case $ARCH in
  x86_64) ARCH_ALT=amd64 ;;
  aarch64) ARCH_ALT=arm64 ;;
  *)
    echo "Unsupported CPU architecture: $ARCH"
    exit 1
    ;;
esac

if [ ! -e $ROOTFS_DIR/.yuji ]; then
  echo "Choose OS:"
  echo "1) Debian"
  echo "2) Ubuntu(22.04)"
  echo "3) Ubuntu(20.04) - RDP"
  echo "4) Alpine"
  read -p "Enter OS (1-4): " input

  case $input in
    1)
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.xz \
        "https://github.com/HekenRyui/-.-/releases/download/rootfs/rootfs-debian-${ARCH_ALT}.tar.xz"
      apt download xz-utils
      deb_file=$(find $ROOTFS_DIR -name "*.deb" -type f)
      dpkg -x $deb_file ~/.local/
      rm "$deb_file"
      tar -xJf /tmp/rootfs.tar.xz -C $ROOTFS_DIR
      ;;
    2)
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "https://github.com/HekenRyui/-.-/releases/download/rootfs/rootfs-ubuntu-${ARCH_ALT}.tar.xz"
      tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
      ;;
    3)
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "https://github.com/HekenRyui/-.-/releases/download/rootfs/rootfs-ubuntu-${ARCH_ALT}.tar.xz"
      tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
      ;;
    4)
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "https://github.com/HekenRyui/-.-/releases/download/rootfs/rootfs-alpine-${ARCH_ALT}.tar.xz"
      tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
      ;;
    *)
      echo "Invalid selection. Exiting."
      exit 1
      ;;
  esac
fi

if [ ! -e $ROOTFS_DIR/.yuji ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://github.com/HekenRyui/-.-/raw/refs/heads/main/files/proot-${ARCH}-static"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://github.com/HekenRyui/-.-/raw/refs/heads/main/files/proot-${ARCH}-static"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot

  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch $ROOTFS_DIR/.yuji
fi

clear
echo "--------Done--------"

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
