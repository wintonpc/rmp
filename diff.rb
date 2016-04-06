require 'oj'

Oj.default_options = {:mode => :compat }

class Diff
  def go(a, b)
    as = read_dump(a)
    bs = read_dump(b)
    as.keys.each do |address|
      bs.delete(address)
    end
    bs.values.each do |b|
      puts Oj.dump(b)
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
end

a, b = ARGV
Diff.new.go(a, b)
