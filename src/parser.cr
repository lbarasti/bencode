require "dataclass"

module Bencode
  extend self

  # record Any, raw : Type do
  #   def as_h : Hash(String, Any)
  #     @raw.as(Hash(String, Any))
  #   end

  #   def as_a : Array(Any)
  #     @raw.as(Array(Any))
  #   end

  #   def as_i : Int64
  #     @raw.as(Int64)
  #   end

  #   def as_s : String
  #     @raw.as(String)
  #   end
  # end

  alias Type = String | Int64 | Array(Type) | Hash(String, Type)

  def parse(io : String | IO)
    expected_length = 0
    context = Deque(Symbol).new
    buffer = [] of Char
    result = Deque(Type).new

    io.each_char { |c|
      # puts context, result
      case context.last?
      when :string_len
        case c
        when ':'
          expected_length = buffer.join.to_i
          buffer = [] of Char
          if expected_length == 0
            context.pop
            case context.last?
            when nil, :dict
              result << ""
            when :list
              result.last.as(Array(Type)) << ""
            else
              raise Exception.new("String out of context")
            end
          else
            context.pop
            context << :string
          end
        else # must be a digit
          buffer << c
        end
      when :string
        buffer << c
        expected_length -= 1
        if expected_length == 0
          str = buffer.join
          buffer = [] of Char
          context.pop
          case context.last?
          when nil
            result << str
          when :dict
            case result.last?
            when Hash
              result << str
            when String
              key = result.pop
              result.last.as(Hash(String, Type))[key.as(String)] = str
            else
              raise Exception.new("String out of context")
            end
          when :list
            result.last.as(Array(Type)) << str
          else
            raise Exception.new("String out of context")
          end
        end
      when :int
        if c == 'e'
          integer = buffer.join.to_i64
          buffer = [] of Char
          context.pop
          case context.last?
          when nil
            result << integer
          when :list
            result.last.as(Array(Type)) << integer
          when :dict
            key = result.pop
            result.last.as(Hash(String, Type))[key.as(String)] = integer
          else
            raise Exception.new("Int out of context")
          end
        else
          buffer << c
        end
      when nil, :list, :dict
        case c
        when '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' # start of string
          context << :string_len
          buffer << c
        when 'i' # start of integer
          context << :int
        when 'l' # start of list
          context << :list
          result << [] of Type
        when 'd' # start of dict
          context << :dict
          result << Hash(String, Type).new
        when 'e'
          context.pop
          obj = result.pop
          case result.last?
          when String
            key = result.pop.as(String)
            result.last.as(Hash(String, Type))[key] = obj
          when Array
            result.last.as(Array(Type)) << obj
          when nil
            result << obj
          end
        end
      end
    }
    result.first
  end
end

puts Bencode.parse("i32e")
puts Bencode.parse("i0e")
puts Bencode.parse("0:")
puts Bencode.parse("4:hell")
puts Bencode.parse("l4:hell5:trelle")
puts Bencode.parse("d3:onell4:hell5:trelleee")

class Array(T)
  def self.from_bencode(bencode : Bencode::Type)
    bencode.as(Array(Bencode::Type)).map { |element|
      T.from_bencode(element)
    }
  end
end

class Hash(K,V)
  def self.from_bencode(bencode : Bencode::Type)
    bencode.as(Hash(String, Bencode::Type)).map { |key, val|
      {key, V.from_bencode(val)}
    }.to_h
  end
end

struct Int64
  def self.from_bencode(bencode : Bencode::Type)
    bencode.as(Int64)
  end
end

class String
  def self.from_bencode(bencode : Bencode::Type)
    bencode.as(String)
  end
end

module Bencode::Serializable
  macro included
    def self.from_bencode(bin : Bencode::Type)
      dict = bin.as(Hash(String, Bencode::Type))
      
      \{% begin %}
        \{% for ivar in @type.instance_vars %}
        \%var{ivar.id} = \{{ivar.type}}.from_bencode(dict[\{{ivar.id.stringify}}])
        \{% end %}

        self.new(\{% for ivar in @type.instance_vars %}
          \{{ivar.id}}: \%var{ivar.id},
        \{% end %})
      \{% end %}
    end
  end
end

dataclass A{one : String, two : Int64} do
  include Bencode::Serializable
end

dataclass W{a : A, l : Array(Int64)} do
  include Bencode::Serializable
end

bin = Bencode.parse("d3:one4:hell3:twoi-23ee")
bin_list = Bencode.parse("ld3:one4:hell3:twoi-23eee")
bin_dict = Bencode.parse("d3:oned3:one4:hell3:twoi-23eee")
bin_w = Bencode.parse("d1:ad3:one4:hell3:twoi-23ee1:llee")

puts A.from_bencode(bin)
puts bin_w
puts W.from_bencode(bin_w)
puts Hash(String, A).from_bencode(bin_dict)
puts Array(A).from_bencode(bin_list)
puts Int64.from_bencode(64_i64)
puts String.from_bencode("hello")

