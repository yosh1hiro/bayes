# -*- coding: utf-8 -*-
# naivebayes.rb
# original: naivebayes.py (http://gihyo.jp/dev/serial/01/machine-learning/0003)

require_relative 'morphological'
require 'set'
require_relative 'connect_database'
require 'logger'
# require 'csv'

def get_words(doc)
  Morphological.split(doc).map(&:downcase)
end

@@log = Logger.new(STDOUT)
@@log.level = Logger::INFO

class NaiveBayes

  def initialize
    @vocabularies = Set.new
    @wordcount = {}
    @catcount = Hash.new {|h, cat| h[cat] = 0}
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
    # p @log.info "カテゴリの中に単語が登場した回数: #{word} => #{@wordcount[cat][word]}"
    return @wordcount[cat][word] if @wordcount[cat].key? word
    0
  end

  def word_prob(word, cat)
    (in_category(word, cat) + 1.0) / (@wordcount[cat].values.inject(:+) + @vocabularies.size)
    # p @log.info "条件付き確率: #{word}と#{cat} => #{a}"
  end

  def score(words, cat)
    score = Math.log(prior_prob(cat))
    words.each do |w|
      score += Math.log(word_prob(w, cat))
    end
    # p @@log.info "score: #{words} => #{score}"
    score
  end

  def classifier(doc)
    best = nil
    max = -2147483648
    words = get_words(doc)
    score = 0
    @catcount.keys.each do |cat|
      prob = score(words, cat)
      if prob > max
        max = prob
        score = prob
        best = cat
      end
    end
    {best => score}
  end

  def get_libel(limit, offset)
    # p @@log.info "get_libel Done"
    ConnectDatabase.gets_libel_learning(limit, offset)
  end

  def libel_learn(limit, offset)
    p @@log.info "libel_learn Done"
    get_libel(limit, offset).flatten.each do |w|
      train(w, "libel")
    end
  end

  def get_approval(limit, offset)
    # p @log.info "get_approval Done"
    ConnectDatabase.gets_approval_learning(limit, offset)
  end

  def approval_learn(limit, offset)
    p @@log.info "approval_learn Done"
    get_approval(limit, offset).flatten.each do |w|
      train(w, "approval")
    end
  end
end

if $0 == __FILE__

  nb = NaiveBayes.new

  (1..2).each do |n|
    nb.libel_learn(200, (n*200 - 199))
    nb.approval_learn(200, (n*200 - 199))
  end

  nb.libel_learn(181, 3400)
  nb.approval_learn(181, 3400)

  @answer = 0
  @false_words = {}
  ConnectDatabase.gets_libel_test.each do |l|
    answer = nb.classifier(l.join(" "))
    p @@log.info "Done classifier"
    if  answer.keys == "libel"
      @answer += 1
    else
      @false_words.store(answer.values, l)
      puts "間違ってるお"
    end
  end

  puts @false_words unless @false_words.nil?
  puts @answer

end
