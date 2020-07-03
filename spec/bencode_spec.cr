require "./spec_helper"
require "dataclass"

dataclass A{one : String, two : Int64} do
  include Bencode::Serializable
end

dataclass W{a : A, l : Array(Int64)} do
  include Bencode::Serializable
end

dataclass Z{c : String, b : Int64, a : String} do
  include Bencode::Serializable
end

describe Bencode do
  it "has a version" do
    Bencode::VERSION.should eq "0.2.1"
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
      Bencode.parse("i42e").as(Int).should be_a Int64
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
      File.open(File.join(__DIR__, "./data/data.torrent")) do |file|
        dict = Bencode.parse(file).as(Hash)
        dict["publisher"].should eq "bob"
        dict["publisher.location"].should eq "home"
      end

      File.open(File.join(__DIR__, "./data/debian.torrent")) do |file|
        dict = Bencode.parse(file).as(Hash)
        dict.keys.should eq ["announce", "comment", "creation date", "httpseeds", "info"]
        dict.to_bencode.should eq file.rewind.gets_to_end
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
      Int64.from_bencode("i64e").should eq(64)
      String.from_bencode("5:hello").should eq "hello"
    end

    it "can deserialize bencode into custom types" do
      A.from_bencode(a).should eq expected_a
      W.from_bencode(w).should eq W.new(a: expected_a, l: [] of Int64)
    end

    it "supports collections of custom types" do
      Hash(String, A).from_bencode(dict_of_a)["one"].should eq expected_a
      Array(A).from_bencode(list_of_a).size.should eq 2
      Array(A).from_bencode(list_of_a).last.should eq A.new("the", 42)
    end
  end

  describe "Bencode serialization" do
    it "can serialize a String" do
      "".to_bencode.should eq "0:"

      uni = "☄\u0001\u0011”"
      uni.to_bencode.should eq "8:☄\u0001\u0011”"
      String.from_bencode(uni.to_bencode).should eq uni
    end

    it "can serialize a 64-bit integer" do
      0_i64.to_bencode.should eq "i0e"

      int = -24_i64
      int.to_bencode.should eq "i-24e"
      Int64.from_bencode(int.to_bencode).should eq int
    end

    it "can serialize an array" do
      ([] of String).to_bencode.should eq "le"

      lst = ["hello", "hey", "h\u1001i"]
      lst.to_bencode.should eq "l5:hello3:hey5:h\u1001ie"
      Array(String).from_bencode(lst.to_bencode).should eq lst
    end

    it "can serialize a Hash(String, *)" do
      ({} of String => Int64).to_bencode.should eq "de"

      dict = {"hello" => 6_i64, "\u1001\u1000" => 0_i64}
      dict.to_bencode.should eq "d5:helloi6e6:\u1001\u1000i0ee"
      Hash(String, Int64).from_bencode(dict.to_bencode).should eq dict
    end

    it "serializes Hash's keys in lexicographic order" do
      dict = {"b" => 6_i64, "a" => 0_i64}
      dict.to_bencode.should eq "d1:ai0e1:bi6ee"
      Hash(String, Int64).from_bencode(dict.to_bencode).should eq dict
    end

    it "can serialize custom types" do
      obj = A.new("hello", -23)
      obj.to_bencode.should eq "d3:one5:hello3:twoi-23ee"
      A.from_bencode(obj.to_bencode).should eq obj

      wrapper_obj = W.new(a: obj, l: [42_i64, 6_i64])
      wrapper_obj.to_bencode.should eq "d1:ad3:one5:hello3:twoi-23ee1:lli42ei6eee"
      W.from_bencode(wrapper_obj.to_bencode).should eq wrapper_obj
    end

    it "serializes custom types' fields in lexicographic order" do
      obj = Z.new("one", -23, "two")
      obj.to_bencode.should eq "d1:a3:two1:bi-23e1:c3:onee"
      Z.from_bencode(obj.to_bencode).should eq obj
    end
  end
end
