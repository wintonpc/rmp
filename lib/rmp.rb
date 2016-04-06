require 'objspace'
require_relative './server'

class Rmp
  class << self
    def start_server(port)
      File.write('rmp.port', port.to_s)
      Thread.new do
        dump_count = 0
        tracing_allocations = false
        Server.start(port, nil) do |req|
          handle_request(req) do |cmd, args|
            case cmd
            when 'snap'
              ObjectSpace.trace_object_allocations_start unless tracing_allocations
              tracing_allocations = true
              dump_count += 1
              file_path = args[0] || "#{dump_count.to_s}.snap"
              dump_all(file_path)
              respond("wrote #{file_path}")
            when 'stop'
              ObjectSpace.trace_object_allocations_stop
              tracing_allocations = false
            when 'echo'
              respond(req.sub(/^echo\s+/, ''))
            when 'class'
              address = args[0]
              if address.nil?
                respond('Usage: site <address>')
              else
                obj = address_to_object(address)
                respond(obj.inspect)
              end
            when 'halt'
              exit(0)
            else
              respond("error unknown command \"#{cmd}\"")
            end
          end
        end
      end

      start_creating_objects
    end

    def start_creating_objects
      stuff = []
      Thread.new do
        loop do
          sleep 1
          stuff << Object.new
          stuff << 'hello'
        end
      end
    end

    def respond(str)
      str += "\n" unless str.end_with?("\n")
      ["#{str}\n", :__no_state_change__]
    end

    def handle_request(req)
      cmd, *args = req.split(/\s+/)
      yield(cmd, args)
    end

    def address_to_object(address)
      ObjectSpace._id2ref(address.to_i(16) >> 1)
    end

    def dump_all(file_path)
      GC.start
      File.open(file_path, 'w') do |f|
        ObjectSpace.dump_all(output: f)
      end
    end
  end
end
