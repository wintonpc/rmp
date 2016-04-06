require 'socket'

class Server
  class << self
    def start(port)
      log "starting server"
      ss = TCPServer.new(port)
      log "listening on #{port}"
      loop {
        Thread.start(ss.accept) { |s|
          log "accepted client"
          begin
            while line = s.gets;  # Returns nil on EOF.
              (s << "You wrote: #{line.inspect}\r\n").flush
            end
          rescue
            bt = $!.backtrace * "\n  "
            ($stderr << "error: #{$!.inspect}\n  #{bt}\n").flush
          ensure
            s.close
          end
        }
      }
    end

    def log(s)
      File.open('/tmp/server.log', 'a') do |f|
        f.puts s
      end
    end
  end
end
