#!/bin/bash

# Purpose: Update the page theslinux.berlios.d
# Author : Anh K. Huynh
# Date   : 2013 May 25th
# License: GPL v2

_D_TMP="$HOME/tmp/"
_D_DEST="/home/groups/theslinux/htdocs/"
_F_SRC="theslinux.org.tgz"

msg() {
  echo "(berlios) $*"
}

err() {
  echo >&2 "(berlios) $*"
}

die() {
  err "$*"
  exit 1
}

_main() {
  cd $_D_TMP || die "Can't switch to $_TMP_DIR"

  msg "Downloading $_F_SRC from theslinux.org"
  rm -rf $_D_TMP/$_F_SRC $_D_TMP/theslinux.org/ \
  || die "Can't clean up the old file $_F_SRC"

  wget \
      http://m0.theslinux.org/$_F_SRC?$(date +%s) \
      -O $_F_SRC -o /dev/null \
  || die "Can't download source file from theslinux.org"

  msg "Extracting $_F_SRC"
  tar -xzf $_F_SRC

  msg "Synchronizing files"
  rsync \
      -ra --delete \
      "$_D_TMP/theslinux.org/" \
      --exclude="usage*" \
      $_D_DEST/ \
    2>&1 1>/dev/null \
  | grep -v 'failed to set times on' \
  | grep -v '/attrs were not transferred'

  msg "Please report to the team if you see any error before this line"
}

_main
