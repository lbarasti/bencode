module Bencode
  extend self

  alias Type = String | Int64 | Array(Type) | Hash(String, Type)

  def parse(input : String | IO)
    parse?(input).not_nil!
  end

  def parse?(input : String | IO)
    io = input.is_a?(String) ? IO::Memory.new(input) : input

    case c = io.read_char
    when 'l'
      list = [] of Bencode::Type
      while el = parse?(io)
        list << el unless el.nil?
      end
      list
    when 'd'
      hash = Hash(String, Bencode::Type).new
      while key = parse?(io)
        value = parse?(io).not_nil!
        hash[key.as(String)] = value
      end
      hash
    when 'i'
      io.gets('e', chomp: true).not_nil!.to_i64
    when 'e', nil # end of context
    else          # string start
      io.pos = io.pos - 1
      str_size = io.gets(':', chomp: true).not_nil!.to_i

      io.read_string(str_size)
    end
  end
end
