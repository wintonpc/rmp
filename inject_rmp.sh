#!/bin/sh

PID=$1
SCRIPT_DIR="$(dirname $(readlink -f $0))"
RMP_PATH="$SCRIPT_DIR/lib/rmp.rb"
bundle exec rbtrace -p "$PID" -e "Thread.new{require_relative \"$RMP_PATH\"; File.write('inject.log', 'required rmp'); Rmp.start_server(9786)}"
