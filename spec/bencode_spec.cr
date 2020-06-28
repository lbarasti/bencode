require "./spec_helper"

describe Bencode do
  describe "Bencode.parse" do
    list = "l4:spam4:eggsi5ee"
    dict_1 = "d1:xi1e1:yi2ee"
    dict_2 = "d3:hit#{list}e"

    it "parses bencode strings into primitive types" do      
      Bencode.parse("4:spamh").should eq "spam"
      Bencode.parse("0:").should eq ""
      Bencode.parse("i-5e").as(Int64).should eq -5_i64
      Bencode.parse("i052e").as(Int64).should eq 52_i64
      Bencode.parse("le").as(Array(Bencode::Type)).should eq [] of Bencode::Type
      Bencode.parse(list).as(Array(Bencode::Type))[0].should eq "spam"
      Bencode.parse(list).as(Array(Bencode::Type))[2].should eq 5_i64
      Bencode.parse("de").as(Hash(String,Bencode::Type)).should eq Hash(String, Bencode::Type).new
      Bencode.parse(dict_1).as(Hash(String,Bencode::Type))["x"].should eq 1_i64
    end

    it "supports nested types" do
      Bencode.parse(dict_2).as(Hash(String,Bencode::Type))["hit"].as(Array(Bencode::Type))[1].should eq "eggs"
      Bencode.parse("l#{list}e").as(Array(Bencode::Type))[0].should eq Bencode.parse(list)
      Bencode.parse("d3:hit#{list}e").as(Hash(String,Bencode::Type))["hit"].should eq Bencode.parse(list)
      Bencode.parse("d4:hell#{dict_2}e").as(Hash(String,Bencode::Type))["hell"].as(Hash(String,Bencode::Type))["hit"].should eq Bencode.parse(list)
    end

    # it "supports reading from IO" do
    #   bencode = File.open("./data.torrent") do |file|
    #     Bencode.parse(file)
    #   end
    # end
  end
end
