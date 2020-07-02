require "./spec_helper"
require "dataclass"

dataclass Torrent{publisher : String, url : String, location : String} do
  include Bencode::Serializable

  @[Bencode::Field(key: "publisher-webpage")]
  getter url : String

  @[Bencode::Field(key: "publisher.location")]
  getter location : String
end

describe Bencode::Field do
  it "lets the user specify a different serialization key for a field" do
    File.open(File.join(__DIR__, "./data/data.torrent")) do |file|
      tr = Torrent.from_bencode(file)
      raw = Hash(String, String).from_bencode(file.rewind)

      tr.location.should eq raw["publisher.location"]
      tr.url.should eq raw["publisher-webpage"]

      tr.to_bencode.should contain "publisher.location"
      tr.to_bencode.should contain "publisher-webpage"
      tr.to_bencode.should eq raw.to_bencode
    end
  end
end
