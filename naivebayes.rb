# -*- coding: utf-8 -*-
# naivebayes.rb
# original: naivebayes.py (http://gihyo.jp/dev/serial/01/machine-learning/0003)

require_relative 'morphological'
require 'set'
require_relative 'connect_database'
require 'logger'
require 'csv'

def get_words(doc)
  Morphological.split(doc).map(&:downcase)
end


class NaiveBayes

  def initialize
    @vocabularies = Set.new
    @wordcount = {}
    @catcount = Hash.new {|h, cat| h[cat] = 0}
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def word_count_up(word, cat)
    @wordcount[cat] ||= Hash.new {|h, word| h[word] = 0}
    @wordcount[cat][word] += 1
    @vocabularies << word
  end

  def cat_count_up(cat)
    @catcount[cat] += 1
  end

  def train(doc, cat)
    get_words(doc).each do |w|
      word_count_up w, cat
    end
    cat_count_up cat
  end

  def prior_prob(cat)
    return a = @catcount[cat].to_f / @catcount.values.inject(:+)
    # p @log.info "カテゴリの生起確率: #{cat} => #{a}"
  end

  def in_category(word, cat)
    p @log.info "カテゴリの中に単語が登場した回数: #{word} => #{@wordcount[cat][word]}"
    return @wordcount[cat][word] if @wordcount[cat].key? word
    0
  end

  def word_prob(word, cat)
    a = (in_category(word, cat) + 1.0) / (@wordcount[cat].values.inject(:+) + @vocabularies.size)
    CSV.open("libel.csv", "wb") do |csv|
      csv << ["単語", "確率"]
      csv << ["#{word}", "#{a}"]
    end
    # p @log.info "条件付き確率: #{word}と#{cat} => #{a}"
    a
  end

  def score(words, cat)
    score = Math.log(prior_prob(cat))
    words.each do |w|
      score += Math.log(word_prob(w, cat))
    end
    # p @log.info "score: #{words} => #{score}"
    score
  end

  def classifier(doc)
    @best = nil
    max = -2147483648
    words = get_words(doc)

    @catcount.keys.each do |cat|
      prob = score(words, cat)
      if prob > max
        max = prob
        @best = cat
      end
    end
    @best
  end

  def libel
    return @libels unless @libels.nil? || @libels.empty?
    @libels = File.read("llibel_test.txt", :encoding => Encoding::UTF_8)
  end

  def approval
    return @approvals unless @approvals.nil? || @aprrovals.empty?
    @approvals = File.read("approval_test.txt", :encoding => Encoding::UTF_8)
  end
end

if $0 == __FILE__
  nb = NaiveBayes.new

  nb.train(nb.libel, "libel")

  nb.train(nb.approval, "approval")

  words = get_words(nb.libel)
  words.each do |w|
    nb.word_prob(w, "libel")
  end
  words.each do |w|
    nb.word_prob(w, "approval")
  end
  # @libels ||= ConnectDatabase.gets_libel
  # @approvals ||= ConnectDatabase.gets_approval
  #
  # @libels.each do |l|
  #   puts "%s => 推定カテゴリ: %s" % [l ,nb.classifier(l)]
  #   if @best == "libel"
  #     @libel_true_count += 1
  #   end
  # end
  #
  # @approvals.each do |a|
  #   puts "%s => 推定カテゴリ: %s" % [a ,nb.classifier(a)]
  #   if @best == "approval"
  #     @approval_true_count += 1
  #   end
  # end
  #
  # puts @approval_true_count
  # puts @libel_true_count

end
