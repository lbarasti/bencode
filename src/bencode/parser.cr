module Bencode
  extend self

  alias Type = String | Int64 | Array(Type) | Hash(String, Type)

  def parse(input : String | IO)
    parse?(input).not_nil!
  end

  def parse?(input : String | IO)
    io = case input
    in String
      IO::Memory.new(input)
    in IO
      input
    end
    result = nil
    while c = io.read_char
      case c
      when 'l'
        list = [] of Bencode::Type
        while el = parse?(io)
          list << el unless el.nil?
        end
        result = list
      when 'd'
        hash = Hash(String, Bencode::Type).new
        while key = parse?(io)
          value = parse?(io).not_nil!
          hash[key.as(String)] = value
        end
        result = hash
      when 'i'
        result = io.gets('e', chomp: true).not_nil!.to_i64
      when 'e' # end of context
      else # string start
        str_size = c.to_i
        while (i = io.read_char) != ':'
          str_size = str_size * 10 + i.not_nil!.to_i
        end

        result = io.read_string(str_size)
      end
      return result
    end
  end
end
