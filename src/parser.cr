require "pars3k"
require "dataclass"

include Pars3k

abstract class BencodeTerm; end
dataclass Str{s : String} < BencodeTerm
dataclass Integer{i : Int64} < BencodeTerm
dataclass List{l : Array(BencodeTerm)} < BencodeTerm
dataclass Dict{d : Array({Str, BencodeTerm})} < BencodeTerm

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

def str_parser
  do_parse({
    l <= Parse.int,
    _ <= Parse.char(':'),
    s <= Parse.n_of(Parse.any, l),
    Parse.constant(Str.new(s.join).as(BencodeTerm))
  })
end

def int_parser
  do_parse({
    _ <= Parse.char('i'),
    h <= Parse.char('-') | Parse.digit,
    s <= Parse.many_of(Parse.digit),
    _ <= Parse.char('e'),
    res = [h].concat(s).join.to_i64,
    Parse.constant(Integer.new(res).as(BencodeTerm))
  })
end

def list_parser
  do_parse({
    _ <= Parse.char('l'),
    values <= Parse.many_of(bencode_parser),
    _ <= Parse.char('e'),
    Parse.constant(List.new(values).as(BencodeTerm))
  })
end

def key_val_parse
  do_parse({
    key <= str_parser,
    val <= bencode_parser,
    Parse.constant({key.as(Str), val})
  })
end

def dict_parser
  do_parse({
    _ <= Parse.char('d'),
    pairs <= Parse.many_of(key_val_parse),
    _ <= Parse.char('e'),
    Parse.constant(Dict.new(pairs).as(BencodeTerm))
  })
end

def bencode_parser : Parser(BencodeTerm)
  str_parser | int_parser | list_parser | dict_parser
end

# list = "l4:spam4:eggsi5ee"
# dict = "d3:hit#{list}e"

# puts str_parser.parse("4:spamh")
# puts str_parser.parse("0:")
# puts int_parser.parse("i-5e")
# puts int_parser.parse("i052e")
# puts list_parser.parse("le")
# puts list_parser.parse(list)
# puts list_parser.parse("l#{list}e")
# puts dict_parser.parse("d3:hit#{list}e")
# puts dict_parser.parse("d4:hell#{dict}e")
# puts dict_parser.parse("de")

