require "./spec_helper"

describe Bencode do
  describe "Bencode.parse" do
    list = "l4:spam4:eggsi5ee"
    dict_1 = "d1:xi1e1:yi2ee"
    dict_2 = "d3:hit#{list}e"

    it "parses bencode strings into primitive types" do      
      Bencode.parse("4:spamh").as_s.should eq "spam"
      Bencode.parse("0:").as_s.should eq ""
      Bencode.parse("i-5e").as_i.should eq -5_i64
      Bencode.parse("i052e").as_i.should eq 52_i64
      Bencode.parse("le").as_a.should eq [] of Bencode::Any
      Bencode.parse(list).as_a[0].as_s.should eq "spam"
      Bencode.parse(list).as_a[2].as_i.should eq 5_i64
      Bencode.parse("de").as_h.should eq Hash(String, Bencode::Any).new
      Bencode.parse(dict_1).as_h["x"].as_i.should eq 1_i64
    end

    it "supports nested types" do
      Bencode.parse(dict_2).as_h["hit"].as_a[1].as_s.should eq "eggs"
      Bencode.parse("l#{list}e").as_a[0].should eq Bencode.parse(list)
      Bencode.parse("d3:hit#{list}e").as_h["hit"].should eq Bencode.parse(list)
      Bencode.parse("d4:hell#{dict_2}e").as_h["hell"].as_h["hit"].should eq Bencode.parse(list)
    end

    # it "supports reading from IO" do
    #   bencode = File.open("./data.torrent") do |file|
    #     Bencode.parse(file)
    #   end
    # end
  end
end
