require 'oj'
require_relative './lib/rmp'
require 'securerandom'

Addresses = Struct.new(:array)
Labels = Struct.new(:array)

class Dig
  def initialize(dump_file_path, rmap_path)
    @rs = Rmp.read_dump(dump_file_path)
    @rmap = read_rmap(rmap_path)
    @seen = {}
  end

  def go(bucket_path)
    unless bucket_path.end_with?('.bucket')
      bucket_path += '.bucket'
    end
    addrs = read_bucket(bucket_path)
    @seen.merge!(group_addrs(addrs))
    while @seen.values.any?{|v| v.is_a?(Addresses)}
      @seen.dup.each do |(k, v)|
        # puts @seen.inspect
        if v.is_a?(Addresses)
          new_stuff = group_addrs(v.array)
          @seen.merge!(new_stuff)
          @seen[k] = Labels.new(new_stuff.keys)
        end
      end
    end
    # puts @seen.inspect
    bucket_id = File.basename(bucket_path, '.bucket')
    dot_name = bucket_id + '.dot'
    File.open(dot_name, 'w') do |f|
      f.puts 'digraph G {'
      f.puts 'node [fontname="monospace", fontsize=9, shape=rect]'
      @seen.each do |(k, labels)|
        labels.array.each do |v|
          f.puts "\"#{v}\" -> \"#{k}\""
        end
      end
      f.puts '}'
    end
    puts "Wrote #{dot_name}"
    png_name = "#{bucket_id}.png"
    system("dot -Tpng -o #{png_name} #{dot_name} && echo Wrote #{png_name} && xdg-open #{png_name} &")
  end

  private

  def group_addrs(addrs)
    rs = @rs.values_at(*addrs)
    bs = rs.group_by{|r| Rmp.bucket_key(r)}
    newly_seen = {}
    bs.each do |(k, rs)|
      label = format_bucket_key(k)
      unless @seen.include?(label)
        addresses = rs.map{|r| r['address']}
        referencers = @rmap.values_at(*addresses).flatten.uniq
        newly_seen[label] = Addresses.new(referencers)
      end
    end
    newly_seen
  end

  def read_bucket(bucket_path)
    File.open(bucket_path, 'r') do |f|
      addrs = []
      f.each_line do |line|
        addrs << line.chomp
      end
      addrs
    end
  end

  def read_rmap(rmap_path)
    m = {}
    File.open(rmap_path, 'r') do |f|
      f.each_line do |line|
        x = Oj.load(line)
        m[x['address']] = x['referencers']
      end
    end
    m
  end

  VALUE_LIMIT = 45

  def format_bucket_key(k)
    case k[0]
    when 'STRING'
      _, value = k
      Rmp.format_value(value, VALUE_LIMIT)
    else
      _, class_address, file, line = k
      if class_address.nil?
        'unknown'
      else
        "#{`./class #{class_address}`.strip}@#{file}:#{line}"
      end
    end
  end
end

bucket_path, dump_file_path, rmap_path = ARGV
Dig.new(dump_file_path, rmap_path).go(bucket_path)
