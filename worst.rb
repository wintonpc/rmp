require 'oj'

Oj.default_options = {:mode => :compat }

class Worst
  def go
    rs = $stdin.readlines.map{|x| Oj.load(x)}
    gs = rs.group_by(&method(:key))
    bs = gs.map do |(k, rs)|
      case k[0]
      when 'STRING'
        _type, value = k
        {
          class: "String<#{value}>",
          class_address: '',
          site: '',
          total_size: rs.map{|r| r['memsize']}.inject(:+),
          count: rs.size
        }
      else
        _type, class_address, file, line = k

        if class_address =~ /^0x[a-f0-9]+$/
          class_name = `./class #{class_address}`.strip
        end

        {
          class: class_name,
          class_address: class_address,
          site: "#{file}:#{line}",
          total_size: rs.map{|r| r['memsize']}.inject(:+),
          count: rs.size
        }
      end
    end
    by_total_size = bs.sort_by{|b| b[:total_size]}.reverse
    by_total_size.each do |b|
      puts Oj.dump(b)
    end
  end

  def key(r)
    case r['type']
    when 'STRING'
      [r['type'], r['value']]
    else
      [r['type'], r['class'], r['file'], r['line']]
    end
  end
end

Worst.new.go
