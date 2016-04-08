require_relative './lib/common'
Addresses = Struct.new(:array)
Labels = Struct.new(:array)

class Dig
  def initialize(dump_file_path)
    @rs = Common.read_dump(dump_file_path)
    rmap_path = File.basename(dump_file_path, '.snap') + '.rmap'
    create_rmap_if_necessary(rmap_path, dump_file_path, @rs)
    @rmap = read_rmap(rmap_path)
    @seen = {}
  end

  def go(bucket_id)
    bucket_path = File.expand_path("~/.rmp/buckets/#{bucket_id}.bucket")
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
    dot_cmd = "dot -Tpng -o #{png_name} #{dot_name}"
    system(dot_cmd) or fail "dot failed. run manually: #{dot_cmd}"
    puts "Wrote #{png_name}"
    puts "Trying to open #{png_name} with xdg-open..."
    system("xdg-open #{png_name} && echo success.") or puts 'failed.'
  end

  private

  def create_rmap_if_necessary(rmap_path, dump_file_path, rs)
    if !File.exists?(rmap_path) || File.mtime(rmap_path) < File.mtime(dump_file_path)
      puts "(Re)creating #{rmap_path} from #{dump_file_path}..."
      File.open(rmap_path, 'w') do |f|
        Common.rmap(rs, f)
      end
      puts 'done'
    end
  end

  def group_addrs(addrs)
    rs = @rs.values_at(*addrs)
    bs = rs.group_by{|r| Common.bucket_key(r)}
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
      Common.format_value(value, VALUE_LIMIT)
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

bucket_id, dump_file_path = ARGV
Dig.new(dump_file_path).go(bucket_id)
