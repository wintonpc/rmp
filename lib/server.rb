require 'socket'

class Server
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
    File.write('server.log', "#{s}\n")
  end
end
