# bencode

A Crystal shard providing serialization and deserialization utilities to parse and produce Bencode-encoded strings.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  bencode:
    github: lbarasti/bencode
```

2. Run `shards install`

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

Serializing is achieved by invoking `to_bencode`, which returns a `String`, or `to_bencode(io : IO)`, which will stream the JSON to an `IO`.

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

### Parsing with Bencode.parse
`Bencode.parse` will return a `Any`, which is a convenient wrapper around all possible Bencode types, making it easy to traverse a complex Bencode structure by casting to the expected type, mostly via some method invocations.

```crystal
require "bencode"

value = Bencode.parse("li1ei2ei3ee") # : Bencode::Any

value.as_a[0]              # => 1
typeof(value.as_a[0])      # => Bencode::Any
value.as_a[0].as_i         # => 1
typeof(value.as_a[0].as_i) # => Int64

value.as_a[0] + 1       # Error, because value[0] is Bencode::Any
value.as_a[0].as_i + 10 # => 11
```

`Bencode.parse` can read from an IO directly (such as a file) which saves allocating a string:

```crystal
require "bencode"

bencode = File.open("path/to/file.torrent") do |file|
  Bencode.parse(file)
end
```

Parsing with `Bencode.parse` is useful for dealing with a dynamic Bencode structure.

### Generating with to_bencode
`to_bencode` and `to_bencode(IO)` methods are provided for primitive types, but you need to define `to_bencode(IO)` for custom objects, either manually or using JSON::Serializable.

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
