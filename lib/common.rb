require 'oj'

Oj.default_options = {:mode => :compat }

class Common
  class << self
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

    def bucket_key(r)
      case r['type']
      when 'STRING'
        [r['type'], r['value']]
      else
        [r['type'], r['class'], r['file'], r['line']]
      end
    end

    def format_value(v, limit)
      s = v.to_s.gsub("\n", "\\n")
      elide(s, limit)
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

    def rmap(rs_map, io_out=$stdout)
      rs = rs_map.values
      m = Hash.new {|h, k| h[k] = []}
      rs.each do |r|
        addr = r['address'] || 'root'
        (r['references'] || []).each do |ref|
          m[ref] << addr
        end
      end
      m.each do |(k, v)|
        io_out.puts Oj.dump({address: k, referencers: v})
      end
    end
  end
end
