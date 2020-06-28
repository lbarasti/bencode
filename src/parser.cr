require "pars3k"
require "dataclass"

class Pars3k::Parse
  def self.any : Parser(Char)
    Parser(Char).new do |context|
      if context.position >= context.parsing.size
        ParseResult(Char).error "expected char, input ended", context
      else
        ParseResult(Char).new context.parsing[context.position], context.next
      end
    end
  end

  def self.n_of(parser : Parser(T), n : Int) : Parser(Array(T)) forall T
      Parser(Array(T)).new do |ctx|
        result = parser.block.call ctx
        results = Array(T).new(n)
        context = ctx
        count = 1
        n.times {
          context = result.context
          results << result.definite_value
          result = parser.block.call context
          break if result.errored
        }
        ParseResult(Array(T)).new results, context
      end
    end
end

include Pars3k

module Bencode
  extend self

  abstract class Any
    def as_h : Hash(String, Any)
      self.as(Dict).d.to_h
    end

    def as_a : Array(Any)
      self.as(List).l
    end

    def as_i : Int64
      self.as(Integer).i
    end

    def as_s : String
      self.as(Str).s
    end
  end

  dataclass Str{s : String} < Any
  dataclass Integer{i : Int64} < Any
  dataclass List{l : Array(Any)} < Any
  dataclass Dict{d : Hash(String, Any)} < Any

  def str_parser
    do_parse({
      l <= Parse.int,
      _ <= Parse.char(':'),
      s <= Parse.n_of(Parse.any, l),
      Parse.constant(Str.new(s.join).as(Any))
    })
  end

  def int_parser
    do_parse({
      _ <= Parse.char('i'),
      h <= Parse.char('-') | Parse.digit,
      s <= Parse.many_of(Parse.digit),
      _ <= Parse.char('e'),
      res = [h].concat(s).join.to_i64,
      Parse.constant(Integer.new(res).as(Any))
    })
  end

  def list_parser
    do_parse({
      _ <= Parse.char('l'),
      values <= Parse.many_of(bencode_parser),
      _ <= Parse.char('e'),
      Parse.constant(List.new(values).as(Any))
    })
  end

  def key_val_parse
    do_parse({
      key <= str_parser,
      val <= bencode_parser,
      Parse.constant({key.as(Str).s, val})
    })
  end

  def dict_parser
    do_parse({
      _ <= Parse.char('d'),
      pairs <= Parse.many_of(key_val_parse),
      _ <= Parse.char('e'),
      Parse.constant(Dict.new(pairs.to_h).as(Any))
    })
  end

  def bencode_parser : Parser(Any)
    str_parser | int_parser | list_parser | dict_parser
  end

  def parse(io : String | IO) : Any
    bencode_parser.parse(io).as(Any)
  end
end

class Array(T)
  def self.from_bencode(term : Any)
    term.as_a.map { |element|
      T.from_bencode(element)
    }
  end
end

class Hash(K,V)
  def self.from_bencode(term : Any)
    term.as_h.map { |key, val|
      {key, V.from_bencode(val)}
    }.to_h
  end
end

struct Int64
  def self.from_bencode(term : Any)
    term.as_i
  end
end

class String
  def self.from_bencode(term : Any)
    term.as_s
  end
end

module Bencode::Serializable
  macro included
    def self.from_bencode(bin : Any)
      dict = bin.as_h
      
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

# bin = bencode_parser.parse("d3:one4:hell3:twoi-23ee").as(Any)
# bin_list = bencode_parser.parse("ld3:one4:hell3:twoi-23eee").as(Any)
# bin_dict = bencode_parser.parse("d3:oned3:one4:hell3:twoi-23eee").as(Any)
# bin_w = bencode_parser.parse("d1:ad3:one4:hell3:twoi-23ee1:llee").as(Any)

# puts A.from_bencode(bin)
# puts W.from_bencode(bin_w)
# puts Hash(String, A).from_bencode(bin_dict)
# puts Array(A).from_bencode(bin_list)
# puts Int64.from_bencode(Integer.new(1))
# puts String.from_bencode(Str.new("hello"))

