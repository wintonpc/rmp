require_relative './lib/rmp'

Oj.default_options = {:mode => :compat }

class Rmap
  def go(input_path)
    rs = Rmp.read_dump(input_path).values
    m = Hash.new {|h, k| h[k] = []}
    rs.each do |r|
      addr = r['address'] || 'root'
      (r['references'] || []).each do |ref|
        m[ref] << addr
      end
    end
    m.each do |(k, v)|
      puts Oj.dump({address: k, referencers: v})
    end
  end
end

input_path = ARGV[0]
Rmap.new.go(input_path)
