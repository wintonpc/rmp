require 'objspace'
require 'oj'
require_relative './server'

class Rmp
  class << self
    def start_server(port, create_leak: false)
      return if @server_started
      @server_started = true
      ObjectSpace.trace_object_allocations_start
      File.write('rmp.port', port.to_s)
      File.write('rmp/rmp.port', port.to_s) if Dir.exists?('rmp')
      Thread.new do
        dump_count = 0
        Server.start(port, nil) do |req|
          handle_request(req) do |cmd, args|
            case cmd
            when 'snap'
              dump_count += 1
              file_path = args[0] || "#{dump_count.to_s}.snap"
              dump_all(file_path)
              respond("wrote #{file_path}")
            when 'echo'
              respond(req.sub(/^echo\s+/, ''))
            when 'class'
              address = args[0]
              if address.nil?
                respond('Usage: class <address>')
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

      start_creating_objects if create_leak
    end

    def start_creating_objects
      stuff = []
      Thread.new do
        loop do
          sleep 0.004
          stuff << Object.new
          stuff << 'hello' * 100
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

    def read_dump(file_path)
      File.open(file_path, 'r') do |f|
        m = {}
        f.each_line do |line|
          j = Oj.load(line)
          m[j['address']] = j
        end
        m
      end
    end

    def bucket_key(r)
      case r['type']
      when 'STRING'
        [r['type'], r['value']]
      else
        [r['type'], r['class'], r['file'], r['line']]
      end
    end
  end
end
