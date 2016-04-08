require 'socket'

class Server
  class << self
    def start(port, state, &block)
      log 'starting server'
      ss = TCPServer.new(port)
      log "listening on #{port}"
      loop {
        Thread.start(ss.accept) { |s|
          # log 'accepted client'
          begin
            while request = s.gets;  # Returns nil on EOF.
              response, new_state = block.call(request, state)
              state = new_state unless new_state == :__no_state_change__
              write(s, response)
            end
          rescue
            bt = $!.backtrace * "\n  "
            write(s, "error: #{$!.inspect}\n  #{bt}\n")
          ensure
            s.close
          end
        }
      }
    end

    def write(s, text)
      s << text
      s.flush
    end

    def log(s)
      # File.open('rmpserver.log', 'a') do |f|
        puts s
        # f.puts s
      # end
    end
  end
end
