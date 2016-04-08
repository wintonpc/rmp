require_relative './lib/common'

input_path = ARGV[0]
Common.rmap(Common.read_dump(input_path))
