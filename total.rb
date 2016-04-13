require 'securerandom'
require 'fileutils'
require_relative './lib/common'

class Total
  def go
    rs = $stdin.readlines.map{|x| Oj.load(x)}
    total = rs.reject{|r| r['type'] == 'ROOT'}.map{|r|
      begin
        size = r.fetch('memsize').to_i
      rescue => e
        puts "exception on #{r.inspect}"
        raise e
      end
    }.inject(:+)
    puts "Total live object size: #{human_count(total)} bytes"
  end

  def human_count(n, kilo: 1024)
    k = kilo
    m = k * k
    g = k * k * k
    if n > g
      "#{(n / g).round}G"
    elsif n > m
      "#{(n / m).round}M"
    elsif n > k
      "#{(n / k).round}K"
    else
      "#{n}"
    end
  end

end

Total.new.go
