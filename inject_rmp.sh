#!/bin/sh

#PID=$1
#SCRIPT_DIR="$(dirname $(readlink -f $0))"
#RMP_PATH="$SCRIPT_DIR/lib/rmp.rb"
#bundle exec rbtrace -p "$PID" -e "require_relative \"$RMP_PATH\"; Rmp.new.methods"

cp config/application.rb config/application.rb.orig
echo 'require_relative "../rmp/lib/rmp"; Rmp.start_server(9786)' | cat - config/application.rb.orig > config/application.rb
kill -HUP `cat tmp/unicorn.pid`
