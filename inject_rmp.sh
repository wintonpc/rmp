#!/bin/sh

PID=$1
SCRIPT_DIR="$(dirname $(readlink -f $0))"
RMP_PATH="$SCRIPT_DIR/lib/rmp.rb"
bundle exec rbtrace -p "$PID" -e "puts Object.inspect; Thread.new{puts Object.inspect; require_relative \"$RMP_PATH\"; Rmp.start_server(9786)}"
