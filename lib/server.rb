require 'socket'

class Server
  def start(port)
    ss = TCPServer.new(port)
    loop {
      Thread.start(ss.accept) { |s|
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
end
