[![GitHub release](https://img.shields.io/github/release/lbarasti/bencode.svg)](https://github.com/lbarasti/bencode/releases)
![Build Status](https://github.com/lbarasti/bencode/workflows/Crystal%20CI/badge.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# bencode

A Crystal shard providing serialization and deserialization utilities to parse and generate [Bencode](https://en.wikipedia.org/wiki/Bencode)-encoded strings.

## Installation

* Add the dependency to your `shard.yml`:

```yaml
dependencies:
  bencode:
    github: lbarasti/bencode
```

* Run `shards install`

## Usage

The Bencode module allows parsing and generating `Bencode` documents.

### General type-safe interface
The general type-safe interface for parsing Bencode is to invoke `T.from_bencode` on a target type `T` and pass either a `String` or `IO` as an argument.

```crystal
require "bencode"

bencode_text = "li1ei2ei3ee"
Array(Int64).from_bencode(bencode_text) # => [1, 2, 3]

bencode_text = "d1:xi1e1:yi2ee"
Hash(String, Int64).from_bencode(bencode_text) # => {"x" => 1, "y" => 2}
```

Serializing is achieved by invoking `to_bencode`, which returns a `String`, or `to_bencode(io : IO)`, which will stream the Bencoding to an `IO`.

```crystal
require "bencode"

[1, 2, 3].to_bencode            # => "li1ei2ei3ee"
{"x" => 1, "y" => 2}.to_bencode # => "d1:xi1e1:yi2ee"
```

In line with the [Bencode specification](https://wiki.theory.org/index.php/BitTorrentSpecification), the following types in the standard library have been extended to implement these methods.
* String
* Int64
* Array(T)
* Hash(String, T)

provided that `T.from_bencode(String)` and `T#to_bencode(io)` methods are defined for the type `T`. For user-defined types you can define these yourself - `from_bencode` for parsing and `to_bencode` for serializing - or you can include Bencode::Serializable in your struct or class.

### Serializing custom types
The `Bencode::Serializable` module automatically generates methods for Bencode serialization when included.

To change how individual instance variables are parsed and serialized, the annotation `Bencode::Field` can be placed on the instance variable. Annotating property, getter and setter macros is also allowed.

```crystal
require "bencode"

class Location
  include Bencode::Serializable

  @[Bencode::Field(key: "long")]
  property lng : Int64
  property lat : Int64

  def initialize(@lat, @lng)
  end
end

class House
  include Bencode::Serializable

  property address : String
  property location : Location
  def initialize(@address, @location)
  end
end

house = House.from_bencode("d7:address17:Crystal Road 12348:locationd3:lati12e4:longi34eee")

house.address  # => "Crystal Road 1234"
house.location # => #<Location:0x10cd93d80 @lat=12, @lng=34>
house.to_bencode  # => "d7:address17:Crystal Road 12348:locationd3:lati12e4:longi34eee"

houses = Array(House).from_bencode("ld7:address17:Crystal Road 12348:locationd3:lati12e4:longi34eeee")
houses.size    # => 1
houses.to_bencode # => "ld7:address17:Crystal Road 12348:locationd3:lati12e4:longi34eeee"
```

### Parsing with Bencode.parse
`Bencode.parse` will return a `Bencode::Type`, which is an alias for the union of all possible Bencode types. This makes it necessary to cast the parsed object to the expected type, in order to traverse it.

```crystal
require "bencode"

value = Bencode.parse("li1ei2ei3ee") # : Bencode::Type

value.as(Array)[0]              # => 1
typeof(value.as(Array)[0])      # => Bencode::Type
value.as(Array)[0].as(Int)         # => 1
typeof(value.as(Array)[0].as(Int)) # => Int64

value.as_a[0] + 1       # Error, because value[0] is Bencode::Type
value.as_a[0].as(Int) + 10 # => 11
```

`Bencode.parse` can read from an IO directly (such as a file) which saves allocating a string:

```crystal
require "bencode"

bencode = File.open("path/to/file.torrent") do |file|
  Bencode.parse(file)
end
```

Parsing with `Bencode.parse` is useful for dealing with a dynamic Bencode structure.

### Custom parsing with _from_bencode
If Bencode::Serializable does not fit your needs, you can define a custom deserializer for an object of type `T` by defining a `_from_bencode(Bencode::Type) : T` class method on it. For example:

```crystal
record A, a : String, b : Int64 do
  def self._from_bencode(obj : Bencode::Type)
    a, b = obj.as(Array)
    new a.as(String), b.as(Int64)
  end
end

a = A.from_bencode "l5:helloi-42ee" # => A(@a="hello", @b=-42)
```

### Generating with to_bencode
`to_bencode` and `to_bencode(IO)` methods are provided for primitive types, but you need to define `to_bencode(IO)` for custom objects, either manually or using `Bencode::Serializable`.

## Credits
* [Hamdiakoguz's  bencoding.cr](https://github.com/Hamdiakoguz/bencoding.cr) has been a huge inspiration for the implementation of the parser. I would have used their shard directly, if it wasn't that `crystal` has evolved with some breaking API changes since the shard was last updated
* I also used [jackpal's bencode-go](https://github.com/jackpal/bencode-go) as a reference implementation
* This repo's readme, examples and API are inspired by Crystal's [JSON package](https://crystal-lang.org/api/0.35.1/JSON.html) - [JSON::Serializable](https://crystal-lang.org/api/0.35.1/JSON/Serializable.html), in particular.

## Development

Just check out the repository and run `crystal spec` to run the tests.

## Contributing

1. Fork it (<https://github.com/lbarasti/bencode/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [lbarasti](https://github.com/lbarasti) - creator and maintainer
