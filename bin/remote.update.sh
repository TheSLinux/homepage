#!/bin/bash

# Purpose: Update the page theslinux.berlios.de
# Author : Anh K. Huynh
# Date   : 2013 May 25th
#          2013 Jul 19th
# License: GPL v2

msg() {
  echo "[$(hostname -f)] $*"
}

err() {
  echo >&2 "[$(hostname -f)] $*"
}

die() {
  echo >&2 "[$(hostname -f)] $*"
  exit 1
}

berlios_theslinux() {
  local _D_DEST="/home/groups/theslinux/htdocs/"
  local _F_SRC="theslinux.org.tgz"
  local _D_TMP="$HOME/tmp/"

  mkdir -p "$_D_TMP"
  cd "$_D_DEST" || die "Can't switch to $_D_DEST"
  cd "$_D_TMP" || die "Can't switch to $_D_TMP"

  msg "Downloading $_F_SRC from theslinux.org"
  rm -rf $_D_TMP/$_F_SRC $_D_TMP/theslinux.org/ \
  || die "Can't clean up the old file $_F_SRC"

  wget \
      "http://theslinux.org/$_F_SRC?$(date +%s)" \
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

#
# Origin: https://github.com/archlinuxvn/home/blob/ \
#     14d2a580c77811f6855b0408188516030967b0e2/bin/tux-update
#
tuxfamily_archlinuxvn() {
  local _D_TMP="$HOME/archlinuxvn/archlinuxvn.tuxfamily.org-web/tmp/"
  local _D_DEST="$HOME/archlinuxvn/archlinuxvn.tuxfamily.org-web/htdocs/"
  local _F_SRC="archlinuxvn.org.tgz"

  cd "$_D_DEST" || die "Can't switch to $_D_DEST"
  cd "$_D_TMP" || die "Can't switch to $_D_TMP"

  msg "Downloading $_F_SRC from archlinuxvn.org"
  rm -rf $_D_TMP/$_F_SRC $_D_TMP/archlinuxvn.org/ \
    || die "Can't clean up the old file $_F_SRC"
  wget \
      "http://archlinuxvn.org/$_F_SRC?$(date +%s)" \
      -O $_F_SRC -o /dev/null \
    || die "Can't download source file from archlinuxvn.org"

  msg "Extracting $_F_SRC"
  tar -xzf $_F_SRC

  msg "Synchronizing files"
  rsync \
      -rap --delete "$_D_TMP/archlinuxvn.org/" \
      --exclude="irclog*" $_D_DEST/ \
    || die "Can't synchronize files from the variant directory to $_D_DEST"
}

tuxfamily_theslinux() {
  local _D_TMP="$HOME/theslinux/fr.theslinux.org-web/tmp/"
  local _D_DEST="$HOME/theslinux/fr.theslinux.org-web/htdocs/"
  local _F_SRC="theslinux.org.tgz"

  cd "$_D_DEST" || die "Can't switch to $_D_DEST"
  cd "$_D_TMP" || die "Can't switch to $_D_TMP"

  msg "Downloading $_F_SRC from theslinux.org"
  rm -rf "$_D_TMP/$_F_SRC" "$_D_TMP/theslinux.org/" \
    || die "Can't clean up the old file $_F_SRC"
  wget \
      "http://theslinux.org/$_F_SRC?$(date +%s)" \
      -O $_F_SRC -o /dev/null \
    || die "Can't download source file from theslinux.org"

  msg "Extracting $_F_SRC"
  tar -xzf $_F_SRC

  msg "Synchronizing files"
  rsync \
      -rap --delete "$_D_TMP/theslinux.org/" \
      $_D_DEST/ \
    || die "Can't synchronize files from the variant directory to $_D_DEST"
}

l00s5r.theslinux.org() {
  local _D_TMP="$HOME/tmp/"
  local _D_DEST="/home/theslinux.org/www/"
  local _F_SRC="theslinux.org.tgz"

  cd "$_D_DEST" || die "Can't switch to $_D_DEST"
  cd "$_D_TMP" || die "Can't switch to $_D_TMP"

  msg "Downloading $_F_SRC from theslinux.org"
  rm -rf "$_D_TMP/$_F_SRC" "$_D_TMP/theslinux.org/" \
    || die "Can't clean up the old file $_F_SRC"
  wget \
      "http://theslinux.org/$_F_SRC?$(date +%s)" \
      -O $_F_SRC -o /dev/null \
    || die "Can't download source file from theslinux.org"

  msg "Extracting $_F_SRC"
  tar -xzf $_F_SRC

  msg "Synchronizing files"
  rsync \
      -rap --delete "$_D_TMP/theslinux.org/" \
      $_D_DEST/ \
    || die "Can't synchronize files from the variant directory to $_D_DEST"
}

_update() {
  local _cmd="${SSH_ORIGINAL_COMMAND:-$1}"
  case "$_cmd" in
    "berlios_theslinux")      ;;
    "tuxfamily_archlinuxvn")  ;;
    "tuxfamily_theslinux")    ;;
    "l00s5r.theslinux.org")   ;;
    *) die "Unknown command '$_cmd'" ;;
  esac

  "$_cmd"
}

_update $*

: Nothing lasts forever
