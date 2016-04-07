require_relative './lib/rmp'
Rmp.start_server(9786, create_leak: true)
sleep(99999999)
