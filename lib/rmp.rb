require 'objspace'
require_relative './server'

class Rmp
  class << self
    # def dump_all(file_path)
    #   GC.start
    #   File.open(file_path, 'w') do |f|
    #     ObjectSpace.dump_all(output: f)
    #   end
    # end

    def start_server(port)
      Thread.new { Server.start(port) }
    end
  end
end
