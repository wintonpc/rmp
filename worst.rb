require 'oj'
require 'securerandom'
require_relative './lib/rmp'

Oj.default_options = {:mode => :compat }

class Worst
  def go
    rs = $stdin.readlines.map{|x| Oj.load(x)}
    gs = rs.group_by{|r| Rmp.bucket_key(r)}
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
          average_size: (total_size.to_f / rs.size).round,
          count: rs.size,
          value: value,
          records: rs
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
          average_size: (total_size.to_f / rs.size).round,
          count: rs.size,
          value: nil,
          records: rs
        }
      end
    end
    write_total_size_highlight; report_by(bs, :total_size)
    write_average_size_highlight; report_by(bs, :average_size)
    write_count_highlight; report_by(bs, :count)
  end

  def report_by(buckets, key, limit=12)
    sorted = buckets.sort_by{|b| b[key]}.reverse
    write_report_header
    sorted.take(limit).each do |b|
      bucket_id = SecureRandom.hex(4)
      b[:bucket_id] = bucket_id
      write_report_row(b)
      write_bucket_addresses(b)
    end
    puts
  end

  def write_bucket_addresses(b)
    File.open("#{b[:bucket_id]}.bucket", 'w') do |f|
      b[:records].each do |r|
        f.puts r['address']
      end
    end
  end

  VALUE_LIMIT = 45

  def write_count_highlight
    puts left('', 16, div: false) + ('⬇' * 'COUNT'.size)
  end

  def write_total_size_highlight
    puts left('', 16, div: false) + left('', 6, div: false) + ('⬇' * 'TOTAL'.size)
  end

  def write_average_size_highlight
    puts left('', 16, div: false) + left('', 6, div: false) + left('', 6, div: false) + ('⬇' * 'AVERAGE'.size)
  end

  def write_report_header
    puts left('CLASS', 16) + left('COUNT', 6) + left('TOTAL', 6) + left('AVERAGE', 7) + left('BUCKET ID', 9) + left('VALUE', VALUE_LIMIT) + normal('LOCATION')
    puts left('-' * 16, 16) + left('-' * 6, 6) + left('-' * 6, 6) + left('-' * 7, 7) + left('-' * 9, 9) + left('-' * VALUE_LIMIT, VALUE_LIMIT) + normal('-' * 'LOCATION'.size)
  end

  def write_report_row(r)
    puts left(r[:class], 16) + right(r[:count], 6) + right(human_bytes(r[:total_size]), 6) + right(human_bytes(r[:average_size]), 7) + left(r[:bucket_id], 9) + left(format_value(r[:value]), VALUE_LIMIT) + normal(r[:site])
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

  def format_value(v)
    s = v.to_s.gsub("\n", "\\n")
    elide(s, VALUE_LIMIT)
  end

  def human_bytes(n)
    m = 1024 * 1024
    k = 1024
    if n > m
      "#{(n / m).round}M"
    elsif n > k
      "#{(n / k).round}K"
    else
      "#{n}B"
    end
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

end

Worst.new.go
