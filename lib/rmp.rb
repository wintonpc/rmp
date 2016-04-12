require 'objspace'
require 'oj'
require 'pp'
require 'fileutils'
require_relative './server'

class Rmp
  class << self
    def start_server(port, create_leak: false)
      return if @server_started
      @server_started = true
      ObjectSpace.trace_object_allocations_start
      FileUtils.mkdir_p(File.expand_path('~/.rmp'))
      File.write(File.expand_path('~/.rmp/rmp.port'), port.to_s)
      Thread.new do
        dump_count = 0
        Server.start(port, nil) do |req|
          handle_request(req) do |cmd, args|
            case cmd
            when 'snap'
              dump_count = snap(args, dump_count, force_gc_first: true)
            when 'snap_nogc'
              dump_count = snap(args, dump_count, force_gc_first: false)
            when 'stat'
              respond(GC.stat.pretty_inspect)
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
            when 'address'
              klass = args[0]
              respond("0x#{(Object.const_get(klass).object_id << 1).to_s(16).rjust(8, '0')}")
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

    def snap(args, dump_count, force_gc_first:)
      dump_count += 1
      file_path  = args[0] || "#{dump_count.to_s}.snap"
      dump_all(file_path, force_gc_first: force_gc_first)
      respond("wrote #{file_path}")
      dump_count
    end

    def start_creating_objects
      stuff = []
      Thread.new do
        loop do
          sleep 0.01
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
    rescue RangeError
      nil
    end

    def dump_all(file_path, force_gc_first:)
      GC.start if force_gc_first
      File.open(file_path, 'w') do |f|
        ObjectSpace.dump_all(output: f)
      end
    end
  end
end
