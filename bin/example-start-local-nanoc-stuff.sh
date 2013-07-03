#!/usr/bin/bash

# Purpose: Start Guard, nanoc view for local development
# Author : Anh K. Huynh
# License: Fair license
# Date   : 2013 July 3rd
# Note   : This is only an example script. Use at your own risk

[[ -f "Guardfile" ]] || { echo >&2 ":: Error: No Guardfile found"; exit 1; }
rvm use ruby-2.0
{ ruby -v | grep -q 2.0 ; } || { echo >&2 ":: Error: Not Ruby-2 found"; exit 1; }

nohup guard start --no-interactions >/dev/null 2>&1 &
nohup nanoc view >/dev/null 2>&1 &
