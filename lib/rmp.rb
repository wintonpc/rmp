require 'objspace'
require_relative './server'

class Rmp
  class << self
    def start_server(port)
      Thread.new do
        Server.start(port, {dump_count: 0}) do |req, state|
          handle_request(req) do |cmd, args|
            case cmd
            when 'snap'
              state[:dump_count] += 1
              file_path = args.first || state[:dump_count].to_s
              dump_all(file_path)
              respond("wrote #{file_path}")
            when 'echo'
              respond(req.sub(/^echo\s+/, ''))
            when 'halt'
              exit(0)
            else
              respond("error unknown command \"#{cmd}\"")
            end
          end
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

    def dump_all(file_path)
      GC.start
      File.open(file_path, 'w') do |f|
        ObjectSpace.dump_all(output: f)
      end
    end
  end
end
