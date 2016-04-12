require 'securerandom'
require 'fileutils'
require 'securerandom'
require_relative './lib/common'

class Inspect
  def go(type)
    addr = `#{File.dirname(__FILE__)}/address #{type}`.strip
    puts "addr = #{addr}"
    rs = $stdin.readlines.map{|x| Oj.load(x)}
    ms = rs.select{|r| r['class'].to_s.to_i(16) == addr.to_i(16)}
    bucket_id = SecureRandom.hex(4)
    FileUtils.mkdir_p(File.expand_path('~/.rmp/buckets'))
    File.open(Common.bucket_path(bucket_id), 'w') do |f|
      ms.each do |m|
        m['references'].each do |addr|
          f.puts addr
        end
      end
    end
    puts "Wrote bucket #{bucket_id}"
  end
end

type = ARGV[0]
Inspect.new.go(type)
