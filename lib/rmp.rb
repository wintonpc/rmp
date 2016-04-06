require 'objspace'

class Rmp
  def dump_all(file_path)
    GC.start
    File.open(file_path, 'w') do |f|
      ObjectSpace.dump_all(output: f)
    end
  end
end
