require 'objspace'
require_relative './server'

class Rmp
  def dump_all(file_path)
    GC.start
    File.open(file_path, 'w') do |f|
      ObjectSpace.dump_all(output: f)
    end
  end

  def start_server(port)
    Server.new.start(port)
  end
end
