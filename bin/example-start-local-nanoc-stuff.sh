#!/usr/bin/bash

# Purpose: Start Guard, nanoc view for local development
#
#   * Start `guard` to watch the source tree. If there is any
#     update on any files, `guard` will execute `nanoc watch`
#     to compile the source. All standard errors will be ignored,
#     so you may need to tune this script.
#
#   * Start `nanoc view` to create local server http://localhost:3000/.
#     Because `nanoc view` doesn't support indexing, you need to use
#     an absolute URI if there isn't index file in the source. E.g,
#     if you only have
#         contents/my/article.html
#     you need to access to
#         http://localhost:3000/my/article/
#     becuase accessing to http://localhost:3000/my/ will report error.
#
# Author : Anh K. Huynh
# License: Fair license
# Date   : 2013 July 3rd
# Note   : This is only an example script. Use at your own risk

[[ ! -f /etc/profile.d/rvm.sh ]] || source /etc/profile.d/rvm.sh
[[ -f "Guardfile" ]] || { echo >&2 ":: Error: No Guardfile found"; exit 1; }
rvm use ruby-2.0
{ ruby -v | grep -q 2.0 ; } || { echo >&2 ":: Error: Not Ruby-2 found"; exit 1; }

nohup guard start --no-interactions >/dev/null 2>&1 &
nohup nanoc view >/dev/null 2>&1 &
