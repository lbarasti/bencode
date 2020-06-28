require "./spec_helper"
require "dataclass"

dataclass A{one : String, two : Int64} do
  include Bencode::Serializable
end

dataclass W{a : A, l : Array(Int64)} do
  include Bencode::Serializable
end

describe Bencode do
  it "has a version" do
    Bencode::VERSION.should eq "0.1.0"
  end

  describe "Bencode.parse" do
    list = "l4:spam4:eggsi5ee"
    dict_1 = "d1:xi1e1:yi2ee"
    dict_2 = "d3:hit#{list}e"

    it "parses bencode strings into primitive types" do      
      Bencode.parse("4:spamh").should eq "spam"
      Bencode.parse("0:").should eq ""
      Bencode.parse("i-5e").as(Int64).should eq -5_i64
      Bencode.parse("i052e").as(Int64).should eq 52_i64
      Bencode.parse("le").as(Array).should eq [] of Bencode::Type
      Bencode.parse(list).as(Array)[0].should eq "spam"
      Bencode.parse(list).as(Array)[2].should eq 5_i64
      Bencode.parse("de").as(Hash).should eq Hash(String, Bencode::Type).new
      Bencode.parse(dict_1).as(Hash)["x"].should eq 1_i64
    end

    it "supports nested types" do
      Bencode.parse(dict_2).as(Hash)["hit"].as(Array(Bencode::Type))[1].should eq "eggs"
      Bencode.parse("l#{list}e").as(Array(Bencode::Type))[0].should eq Bencode.parse(list)
      Bencode.parse("d3:hit#{list}e").as(Hash)["hit"].should eq Bencode.parse(list)
      Bencode.parse("d4:hell#{dict_2}e").as(Hash)["hell"].as(Hash)["hit"].should eq Bencode.parse(list)
      Bencode.parse("d1:ad3:one4:hell3:twoi-23ee1:llee").as(Hash)["l"].should eq ([] of Bencode::Type)
    end

    it "supports reading from IO" do
      File.open(File.join(__DIR__, "./data.torrent")) do |file|
        dict = Bencode.parse(file).as(Hash)
        dict["publisher"].should eq "bob"
        dict["publisher.location"].should eq "home"
      end
    end
  end
  
  describe "Bencode deserialization" do
    a = "d3:one4:hell3:twoi-23ee"
    list_of_a = "ld3:one4:hell3:twoi-23eed3:one3:the3:twoi42eee"
    dict_of_a = "d3:oned3:one4:hell3:twoi-23eee"
    w = "d1:ad3:one4:hell3:twoi-23ee1:llee"

    expected_a = A.new("hell", -23)

    it "can deserialize bencode into primitive types" do
      Int64.from_bencode(64_i64).should eq(64)
      String.from_bencode("hello").should eq "hello"
    end

    it "can deserialize bencode into custom types" do
      A.from_bencode(a).should eq expected_a
      W.from_bencode(w).should eq W.new(a: expected_a, l: [] of Int64)
    end

    it "supports collecions of custom types" do
      Hash(String, A).from_bencode(dict_of_a)["one"].should eq expected_a
      Array(A).from_bencode(list_of_a).size.should eq 2
      Array(A).from_bencode(list_of_a).last.should eq A.new("the", 42)
    end
  end
end
