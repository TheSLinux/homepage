#!/usr/bin/bash
#
# Author : Anh K. Huynh
# License: Fair license
# Date   : 2013 July {3rd, 28th}
# Purpose: Start Guard, nanoc view for local development
#
# * Start `guard` to watch the source tree. If there is any
#   update on any files, `guard` will execute `nanoc watch`
#   to compile the source. All standard errors will be ignored,
#   so you may need to tune this script.
#
# * Start `nanoc view` to create local server http://localhost:3000/.
#   Because `nanoc view` doesn't support indexing, you need to use
#   an absolute URI if there isn't index file in the source. For example,
#   to view the compiled HTML version of the document
#       contents/my/article.html
#   you need to type on your browser's addressbar
#       http://localhost:3000/my/article/
#   (In production environment, accessing to http://theslinux/my/ lists
#   the page `/article/` in the `index` page.)
#
# Notes:
#
# * This script is only an example script. Use at your own risk
# * If you run this script multiple time you may launch many instances
#   of `guard` program. To avoid that, you may install `rolo` gem
#   which is detected automatically and used in this script
#

[[ -f "Guardfile" ]] \
|| {
  echo >&2 ":: Error: No Guardfile found"
  echo >&2 ":: You should start from a directory that has a 'Guardfile'"
  exit 1
}

[[ ! -f /etc/profile.d/rvm.sh ]] \
|| source /etc/profile.d/rvm.sh

{ ruby -v | grep -qE '(2\.0)|(1\.9)' ; } \
|| rvm use ruby-2.0 \
|| rvm use ruby-1.9 \
|| {
  echo >&2 ":: Unable to find Ruby (1.9|2.0) environment"
  exit 1
}

which rolo >/dev/null 2>&1 \
|| {
  echo 2>&1 ":: Warning: Optional gem 'rolo' (>= 1.1.1) not found"
  echo 2>&1 ":: Install 'rolo' gem to prevent 'guard' from running twice"
}

which guard >/dev/null \
&& which nanoc >/dev/null \
&& {
  rolo=" "
  which rolo >/dev/null 2>&1 && rolo="rolo --no-bind -a 127.0.0.1 -p 3000"
  echo ":: Starting Guard (on background) to watch files"
  $rolo guard start --no-interactions &
  echo ":: Starting Nanoc (on background) to view files at http://localhost:3000/"
  $rolo nanoc view &
} \
|| {
  echo >&2 ":: Error: 'guard'/'nanoc' not found. Please install these gems"
  exit 127
}
