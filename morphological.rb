# -*- coding: utf-8 -*-
# morphological.rb

require 'MeCab'
require 'natto'

module Morphological
  def split(sentence)
    mecab = Natto::MeCab.new

    result = []
    node = mecab.parse(sentence) do |n|
      result << n.surface.force_encoding('UTF-8')  if pos_filter(n.posid)
    end
    result
  end
  module_function :split

  def pos_filter(posid, filters = "1|2|3|4|5|9|10")
    flist = filters.split(/\|/)
    case posid
      when 2  # 感動詞
        flist.include? "3"
      when 3..9  # 記号
        flist.include? "13"
      when 10..12 # 形容詞
        flist.include? "1"
      when 13..24 # 助詞
        flist.include? "11"
      when 25 # 助動詞
        flist.include? "12"
      when 26 # 接続詞
        flist.include? "6"
      when 27..30 # 接頭辞
        flist.include? "7"
      when 31..33 # 動詞
        flist.include?("10")
      when 34, 35 # 副詞
        flist.include? "4"
      when 36..67 # 名詞、一部形容動詞語幹
        flist.include?("9") || flist.include?("2") && [40, 52, 64].include?(posid)
      when 68 # 連体詞
        flist.include? "5"
      else
        false
    end
  end
  module_function :pos_filter
end
