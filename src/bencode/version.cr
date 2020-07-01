module Bencode
  VERSION = File.read_lines(
    File.join(
      File.dirname(__DIR__), "../shard.yml"))
    .find(&.match(/^version: (.*)/)) && $1
end
