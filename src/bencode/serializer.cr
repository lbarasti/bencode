require "./parser"

class Array(T)
  def self.from_bencode(bencode : String)
    from_bencode Bencode.parse(bencode)
  end
  def self.from_bencode(bencode : Bencode::Type)
    bencode.as(Array).map { |element|
      T.from_bencode(element)
    }
  end
end

class Hash(K,V)
  def self.from_bencode(bencode : String)
    from_bencode Bencode.parse(bencode)
  end
  def self.from_bencode(bencode : Bencode::Type)
    bencode.as(Hash).map { |key, val|
      {key, V.from_bencode(val)}
    }.to_h
  end
end

struct Int64
  def self.from_bencode(bencode : String)
    from_bencode Bencode.parse(bencode)
  end
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
    def self.from_bencode(bencode : String)
      from_bencode Bencode.parse(bencode)
    end

    def self.from_bencode(bencode : Bencode::Type)
      dict = bencode.as(Hash)
      
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
