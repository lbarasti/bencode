require "./spec_helper"
require "dataclass"

module SerializerSpec
  dataclass Torrent{publisher : String, url : String, location : String} do
    def self._from_bencode(bencode : Bencode::Type)
      p, u, l = bencode.as(Array).map(&.as(String))
      new p, u, l
    end

    def to_bencode(io : IO)
      io << 'l'
      publisher.to_bencode(io)
      url.to_bencode(io)
      location.to_bencode(io)
      io << 'e'
    end
  end
end

describe "Type T with custom serializer" do
  t = SerializerSpec::Torrent.new("a", "bb", "ccc")
  it "needs T#to_bencode(io) to be implemented in order to serialize an object" do
    t.to_bencode.should eq "l1:a2:bb3:ccce"
  end

  it "supports serialization on nested types" do
    ar = [t]
    ar.to_bencode.should eq "ll1:a2:bb3:cccee"
    h = {"key" => t}
    h.to_bencode.should eq "d3:keyl1:a2:bb3:cccee"
  end

  it "needs T._from_bencode(bencode) to be implemented in order to deserialize an object" do
    SerializerSpec::Torrent.from_bencode "l1:a2:bb3:ccce"
  end

  it "supports deserialization on nested types" do
    ar = Array(SerializerSpec::Torrent).from_bencode "ll1:a2:bb3:cccee"
    ar.first.should eq t
    h = Hash(String, SerializerSpec::Torrent).from_bencode "d3:keyl1:a2:bb3:cccee"
    h["key"].should eq t
  end
end
