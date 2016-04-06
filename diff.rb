require 'oj'
require_relative './lib/rmp'

Oj.default_options = {:mode => :compat }

class Diff
  def go(a, b)
    as = Rmp.read_dump(a)
    bs = Rmp.read_dump(b)
    as.keys.each do |address|
      bs.delete(address)
    end
    bs.values.each do |b|
      puts Oj.dump(b)
    end
  end
end

a, b = ARGV
Diff.new.go(a, b)
