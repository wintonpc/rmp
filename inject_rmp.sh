#!/bin/sh

cp config/application.rb config/application.rb.orig
echo 'require_relative "../rmp/lib/rmp"; Rmp.start_server(9786)' | cat - config/application.rb.orig > config/application.rb
kill -HUP `cat tmp/unicorn.pid`
