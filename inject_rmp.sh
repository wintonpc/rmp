#!/bin/sh

PID=$1
SCRIPT_DIR="$(dirname $(readlink -f $0))"
RMP_PATH="$SCRIPT_DIR/lib/rmp.rb"
bundle exec rbtrace -p "$PID" -e "require_relative \"$RMP_PATH\"; Rmp.new.send(:start_server, 9786)"
