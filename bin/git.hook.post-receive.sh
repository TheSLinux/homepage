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
_F_ARCHIVE="$_D_WWW/theslinux.org.tgz"
_S_BERLIOS="kyanh@shell.berlios.de"

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
        'config.yaml' \
        'content/stylesheet.css' \
        'etc/apache.rewrite.conf'

  [[ "$(date +%Y)" == "2013" ]] || rm -f "contents/news/index.html"
}

_fetch_apache_configuration() {
  msg "Updating Apache configuration. Nginx requires manual edit"
  mv "etc/apache.rewrite.conf" "$_D_OUTPUT/.htaccess"
}

_update_myself() {
  msg "Do nothing"
}

_build() {
  cd $_D_VAR/ || die "Couldn't switch to directory $_D_VAR/"

  msg "Cleaning up the old files"
  nanoc prune --yes
  msg "Rebuilding the static pages"
  nanoc | grep -v "output/tags/"
  if [[ ${PIPESTATUS[0]} -ge 1 ]]; then
    msg "Something wrong happened when building the pages."
    die "Please contact the system administrator for support."
  fi
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

# NOTE: Should be invoked after (create_www)
_create_archive() {
  cd $_D_VAR/ || die "Couldn't switch to $_D_VAR/"

  msg "Creating local archive for Berlios.de"
  tar --transform="s,^output,theslinux.org," -czf $_F_ARCHIVE output/
  chmod 644 $_F_ARCHIVE
}

# See also https://github.com/TheSLinux/homepage/commit/ \
#   27372a4e26d67bd63c0d4e25fd2ebc1ddb791112
_fix_news_page() {
  msg "'news' page: Add a trick to have per-year support"
  msg "See also https://github.com/TheSLinux/homepage/commit/"
  msg "   .... 27372a4e26d67bd63c0d4e25fd2ebc1ddb791112"

  # In the year 2013 we are still using the `news/index.hml` for items
  if [[ "$(date +%Y)" == "2013" ]]; then
    mkdir -p "$_D_OUTPUT/news/2013/"
    pushd "$_D_OUTPUT/news/2013/"
    ln -s "../index.html" "index.html"
    popd
  else # we now use contents/news/<year>.html to save items
    pushd "$_D_OUTPUT/news/"
    ln -s "$(date +%Y)/index.html" "index.html"
    popd
  fi
}

_sync() {
  msg "Updating home page theslinux.tuxfamily.org (m4.theslinux.org)"
  ssh -o ConnectTimeout=3 "tuxfamily_theslinux" "tuxfamily_theslinux"

  msg "Updating home page theslinux.berlios.de"
  ssh -o ConnectTimeout=3 "$_S_BERLIOS" "berlios_theslinux"

  msg "All pages have been updated."
  msg "Thank you for your contribution. You make TheSLinux live!"
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
  _fix_news_page
  _fetch_apache_configuration
  _fix_perm
  _create_www
  _create_archive
  _sync
}

_lock_start
_main
_lock_end
