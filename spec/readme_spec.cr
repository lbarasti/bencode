require "./spec_helper.cr"

class Location
  include Bencode::Serializable

  property lat : Int64
  @[Bencode::Field(key: "long")]
  property lng : Int64

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

record ReadmeSpec::A, a : String, b : Int64 do
  def self._from_bencode(obj : Bencode::Type)
    a, b = obj.as(Array)
    new a.as(String), b.as(Int64)
  end
end

describe "README samples" do
  it "supports basic data types" do
    bencode_text = "li1ei2ei3ee"
    Array(Int64).from_bencode(bencode_text).should eq [1, 2, 3]

    bencode_text = "d1:xi1e1:yi2ee"
    Hash(String, Int64).from_bencode(bencode_text).should eq ({"x" => 1, "y" => 2})

    [1, 2, 3].to_bencode.should eq "li1ei2ei3ee"
    {"x" => 1, "y" => 2}.to_bencode.should eq "d1:xi1e1:yi2ee"
  end

  it "supports cast and traversal" do
    value = Bencode.parse("li1ei2ei3ee") # : Bencode::Type

    value.as(Array)[0].should eq 1
    typeof(value.as(Array)[0]).should eq Array(Bencode::Type) | Hash(String, Bencode::Type) | Int64 | String
    value.as(Array)[0].as(Int).should eq 1
    typeof(value.as(Array)[0].as(Int)).should eq Int64

    # value.as(Array)[0] + 1       # Error, because value[0] is Bencode::Type
    (value.as(Array)[0].as(Int) + 10).should eq 11
  end

  it "can add ser/de to custom types by including the Serialize module" do
    house_bencode = "d7:address17:Crystal Road 12348:locationd3:lati12e4:longi34eee"
    house_list_bencode = "l#{house_bencode}e"

    house = House.from_bencode(house_bencode)

    house.address.should eq "Crystal Road 1234"
    house.location.should be_a Location # => #<Location:0x10cd93d80 @lat=12, @lng=34>
    house.to_bencode.should eq house_bencode

    houses = Array(House).from_bencode(house_list_bencode)
    houses.size.should eq 1
    houses.to_bencode.should eq house_list_bencode
  end

  it "supports custom deserializers" do
    bencode = "l5:helloi-42ee"
    a = ReadmeSpec::A.from_bencode bencode
    a.should eq ReadmeSpec::A.new("hello", -42)
  end

  it "supports custom deserializers on nested types" do
    bencode = "d3:keyl5:helloi-42ee"
    a = Hash(String, ReadmeSpec::A).from_bencode bencode
    a["key"].should eq ReadmeSpec::A.new("hello", -42)
  end
end
