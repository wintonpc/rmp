require_relative './lib/common'

class Diff
  def go(a, b)
    as = Common.read_dump(a)
    bs = Common.read_dump(b)
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
