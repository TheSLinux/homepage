#!/bin/bash

# Purpose: provides a `post-receive` hook to compile `nanoc source
#          to a static site.
# Date   : 2013  Mar 04th
# Author : Anh K. Huynh
# License: GPL v3

unset GIT_DIR
export HOME=/home/git
export LANG=en_US.UTF-8

_D_VAR="$HOME/var/theslinux-home/"
_F_LOCK="$HOME/var/theslinux-home.lock"
_D_WWW="$HOME/static/www/theslinux.org/"
_D_OUTPUT="$_D_VAR/output/"

msg() {
  echo ":: $*"
}

err() {
  echo >&2 ":: $*"
}

die() {
  err "$*"
  _lock_end
  exit 1
}

_setup() {
  if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    source "$HOME/.rvm/scripts/rvm"
    rvm use ruby1.9
  else
    die "rvm not found. We need ruby1.9"
  fi

  # source $HOME/bin/ssh-agent.sh >/dev/null 2>&1 \
  #   || die "Can't load ssh configuration"
  #
  # msg "Testing ssh connection (skipped)"
  # [[ $? -eq 0 ]] || die "Can't make connect to remote server ssh.tuxfamily.org"

  cd $_D_VAR || die "Can't switch to directory $_D_VAR"
}

_update() {
  msg "Updating the local source tree"
  git reset --hard
  git fetch --all
  git checkout master || die "Can't switch to the branch :master"
  git pull --rebase || die "Can't update local source tree. Please ask your sysadmin for details"

  msg "Removing erb files"
  rm -r lib/* layouts/* _i/*
  find .          -type f -iname "*.rb" -exec rm -f {} +
  find ./content/ -type f -iname "*.sh" -exec rm -f {} +

  msg "Removing some files that should not be cached"
  rm  -f output/changes/index.html
  rm -rf output/tags/* output/rss/*

  msg "Fetching Ruby files from the branch :core"
  git archive \
      --format=tar core \
      --remote=~/repositories/theslinux-home.git \
    | tar --wildcards -xf - \
        'Rules' \
        '*.rb' \
        'layouts/*' \
        'config.yaml'
}

_update_myself() {
  msg "Do nothing"
}

_build() {
  cd $_D_VAR/ || die "Couldn't switch to directory $_D_VAR/"

  msg "Cleaning up the old files"
  nanoc prune --yes
  msg "Rebuilding the static pages"
  nanoc \
    || {
         msg "Something wrong happened when building the pages."
         die "Please contact the system administrator for support."
       }
}

_fix_perm() {
  msg "Updating files permission"
  find $_D_OUTPUT/ -mindepth 1 -type d -exec chmod 755 {} +
  find $_D_OUTPUT/ -mindepth 1 -type f -exec chmod 644 {} +
}

# NOTE: all files `*.tgz` are ignored
_create_www() {
  msg "Transferring files to directory 'www' on l00s3r (m0)"
  rsync -rap --delete $_D_OUTPUT/ $_D_WWW/ --exclude="*.tgz"
}

# NOTE: Never use (die) in this method
_lock_start() {
  if [[ ! -f "$_F_LOCK" ]]; then
    touch "$_F_LOCK" || die "Can't create lock file"
    return 0
  fi

  t_lok="$(date -r $_F_LOCK +%s)"
  t_now="$(date +%s)"

  distance=$((t_now - t_lok))
  if [[ $distance -ge 300 ]]; then
    msg "Lock file is too old. Is this file obsolete?"
    touch "$_F_LOCK"
    return 0
  else
    msg "======================================================"
    msg "Lock file does exist. Another build process is running."
    msg "Your changes won't appear in the home page until next build."
    msg "Please wait in 10 minutes, or force new build by modifying"
    msg "the file .force.build. You can put anything in that file."
    msg " (However, if you see this message again and again,"
    msg " there may be a problem on the server 'viettug.org'."
    msg " Please contact the sysadmin to resolve it. THANK YOU.)"
    msg "======================================================"
    exit 0
  fi
}

_lock_end() {
  rm -f "$_F_LOCK"
}

_main() {
  _update_myself
  _setup
  _update || die "Something wrong happened during updating process"
  _build
  _fix_perm
  _create_www
}

_lock_start
_main
_lock_end
