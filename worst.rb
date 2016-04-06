require 'oj'

Oj.default_options = {:mode => :compat }

class Worst
  def go
    rs = $stdin.readlines.map{|x| Oj.load(x)}
    gs = rs.group_by(&method(:key))
    bs = gs.map do |(k, rs)|
      class_address, file, line = k
      {
        class_address: class_address,
        site: "#{file}:#{line}",
        total_size: rs.map{|r| r['memsize']}.inject(:+),
        count: rs.size
      }
    end
    by_total_size = bs.sort_by{|b| b[:total_size]}.reverse
    by_total_size.each do |b|
      puts Oj.dump(b)
    end
  end

  def key(r)
    [r['class'], r['file'], r['line']]
  end
end

Worst.new.go
