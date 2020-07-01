require "./parser"

class Array(T)
  def self.from_bencode(bencode : String)
    _from_bencode Bencode.parse(bencode)
  end
  def self._from_bencode(bencode : Bencode::Type)
    bencode.as(Array).map { |element|
      T._from_bencode(element)
    }
  end
  def to_bencode : String
    String.build { |str|
      to_bencode str
    }
  end
  def to_bencode(io : IO)
    io << 'l'
    self.each { |el|
      el.to_bencode io
    }
    io << 'e'
  end
end

class Hash(K,V)
  def self.from_bencode(bencode : String)
    _from_bencode Bencode.parse(bencode)
  end
  def self._from_bencode(bencode : Bencode::Type)
    bencode.as(Hash).map { |key, val|
      {key, V._from_bencode(val)}
    }.to_h
  end
  def to_bencode : String
    String.build { |str|
      to_bencode str
    }
  end
  def to_bencode(io : IO)
    io << 'd'
    self.each { |k, v|
      k.to_bencode io
      v.to_bencode io
    }
    io << 'e'
  end
end

struct Int
  def self.from_bencode(bencode : String)
    _from_bencode Bencode.parse(bencode)
  end
  def self._from_bencode(bencode : Bencode::Type)
    bencode.as(Int64)
  end

  def to_bencode : String
    String.build { |str|
      to_bencode str
    }
  end
  def to_bencode(io : IO)
    io << 'i'
    self.to_s io
    io << 'e'
  end
end

class String
  def self.from_bencode(bencode : String)
    _from_bencode Bencode.parse(bencode)
  end
  def self._from_bencode(bencode : Bencode::Type)
    bencode.as(String)
  end
  def to_bencode : String
    String.build { |str|
      to_bencode str
    }
  end
  def to_bencode(io : IO)
    io << self.bytesize
    io << ':'
    self.to_s io
  end
end

module Bencode::Serializable
  macro included
    def to_bencode : String
      String.build { |str|
        to_bencode str
      }
    end
    def to_bencode(io : IO)
      io << 'd'
      \{% begin %}
        \{% for ivar in @type.instance_vars %}
        \{{ivar.id.stringify}}.to_bencode(io)
        \{{ivar.id}}.to_bencode(io)
        \{% end %}
      \{% end %}
      io << 'e'
    end

    def self.from_bencode(bencode : String)
      _from_bencode Bencode.parse(bencode)
    end

    def self._from_bencode(bencode : Bencode::Type)
      dict = bencode.as(Hash)
      
      \{% begin %}
        \{% for ivar in @type.instance_vars %}
        \%var{ivar.id} = \{{ivar.type}}._from_bencode(dict[\{{ivar.id.stringify}}])
        \{% end %}

        self.new(\{% for ivar in @type.instance_vars %}
          \{{ivar.id}}: \%var{ivar.id},
        \{% end %})
      \{% end %}
    end
  end
end
