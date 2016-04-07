require 'oj'

Oj.default_options = {:mode => :compat }

class Worst
  def go
    rs = $stdin.readlines.map{|x| Oj.load(x)}
    gs = rs.group_by(&method(:key))
    bs = gs.map do |(k, rs)|
      case k[0]
      when 'STRING'
        type, value = k
        total_size = rs.map{|r| r['memsize']}.inject(:+)
        {
          type: type,
          class: 'String',
          class_address: '',
          site: '',
          total_size: total_size,
          average_size: total_size.to_f / rs.size,
          count: rs.size,
          value: value
        }
      else
        type, class_address, file, line = k

        if class_address =~ /^0x[a-f0-9]+$/
          class_name = `./class #{class_address}`.strip
        end

        total_size = rs.map{|r| r['memsize']}.inject(:+)

        {
          type: type,
          class: class_name,
          class_address: class_address,
          site: "#{file}:#{line}",
          total_size: total_size,
          average_size: total_size.to_f / rs.size,
          count: rs.size,
          value: nil
        }
      end
    end
    write_total_size_highlight; report_by(bs, :total_size)
    write_average_size_highlight; report_by(bs, :average_size)
    write_count_highlight; report_by(bs, :count)
  end

  def report_by(rs, key, limit=12)
    sorted = rs.sort_by{|b| b[key]}.reverse
    write_report_header
    sorted.take(limit).each do |b|
      write_report_row(b)
    end
    puts
  end

  VALUE_LIMIT = 45

  def write_count_highlight
    puts left('', 16, div: false) + ('⬇' * 'COUNT'.size)
  end

  def write_total_size_highlight
    puts left('', 16, div: false) + left('', 6, div: false) + ('⬇' * 'TOTAL BYTES'.size)
  end

  def write_average_size_highlight
    puts left('', 16, div: false) + left('', 6, div: false) + left('', 11, div: false) + ('⬇' * 'AVG BYTES'.size)
  end

  def write_report_header
    puts left('CLASS', 16) + left('COUNT', 6) + left('TOTAL BYTES', 11) + left('AVG BYTES', 11) + left('VALUE', VALUE_LIMIT) + normal('LOCATION')
    puts left('-' * 16, 16) + left('-' * 6, 6) + left('-' * 11, 11) + left('-' * 11, 11) + left('-' * VALUE_LIMIT, VALUE_LIMIT) + normal('-' * 'LOCATION'.size)
  end

  def write_report_row(r)
    puts left(r[:class], 16) + right(r[:count], 6) + right(r[:total_size], 11) + right(r[:average_size], 11) + left(elide(r[:value], VALUE_LIMIT), VALUE_LIMIT) + normal(r[:site])
  end

  def left(x, width, div: true)
    x.to_s.ljust(width) + (div ? ' | ' : '   ')
  end

  def right(x, width, div: true)
    x.to_s.rjust(width) + (div ? ' | ' : '   ')
  end

  def normal(x)
    x
  end

  # from https://docs.omniref.com/ruby/gems/rack-padlock/0.0.3/symbols/Rack::Padlock::StringUtil/elide
  def elide(string, max)
    string = string.to_s
    max = max - 3 # account for elipses

    length = string.length
    return string unless length > max
    return string if max <= 0
    amount_to_preserve_on_the_left = (max/2.0).ceil
    amount_to_preserve_on_the_right = max - amount_to_preserve_on_the_left
    left = string[0..(amount_to_preserve_on_the_left-1)]
    right = string[-amount_to_preserve_on_the_right..-1]
    "#{left}...#{right}"
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
