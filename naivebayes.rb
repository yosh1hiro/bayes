# -*- coding: utf-8 -*-
# naivebayes.rb
# original: naivebayes.py (http://gihyo.jp/dev/serial/01/machine-learning/0003)

require_relative 'morphological'
require 'set'
require_relative 'connect_database'
require 'logger'

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
      word_count_up(w, cat)
    end
    cat_count_up(cat)
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
    (in_category(word, cat) + 1.0) / (@wordcount[cat].values.inject(:+))
    # p @log.info "条件付き確率: #{word}と#{cat} => #{a}"
  end

  def score(words, cat)
    score = Math.log(prior_prob(cat))
    words.each do |w|
      probability = Math.log(word_prob(w, cat))
      if probability > -3.0
        probability = probability * 0.5
      elsif probability < -4.6
        probability = probability * 0.8
      else
        probability
      end
      score += probability
    end
    # p @@log.info "score: #{words} => #{score}"
    score
  end

  def classifier(doc)
    best = nil
    max = -2147483648
    words = get_words(doc)
    app_score = 0
    libel_score = 0
    diff = 0
    @catcount.keys.each do |cat|
      prob = score(words, cat)
      if prob > max
        max = prob
        best = cat
      end
      case cat
        when "libel"
          app_score = prob
        when "approval"
          libel_score = prob
        else
          false
      end
    end
    diff = app_score - libel_score
    if diff >= -20  # -25
      best = "libel"
    else
      best = "approval"
    end
    [best, diff]
  end

  def libel_learn(limit, offset)
    p @@log.info "libel_learn Done"
    ConnectDatabase.gets_libel_learning(limit, offset).flatten.each do |w|
      train(w, "libel")
    end
  end

  def approval_learn(limit, offset)
    p @@log.info "approval_learn Done"
    ConnectDatabase.gets_approval_learning(limit, offset).flatten.each do |w|
      train(w, "approval")
    end
  end
end

if $0 == __FILE__

  nb = NaiveBayes.new

  (1..17).each do |n|
    nb.libel_learn(200, (n*200 - 199))
  end
  (1..44).each do |n|
    nb.approval_learn(200, (n*200 - 199)) #  10200
  end
  nb.libel_learn(181, 3400)
  # nb.approval_learn(181, 3400)

  @answer = 0
  @false_words = {}
  ConnectDatabase.gets_libel_test.each do |l|
    answer = nb.classifier(l.join(" "))
    p @@log.info "key: #{answer[0]} #{answer[1]}"
    if answer[0] == "libel"
      @answer += 1
      puts "合ってるお"
    else
      @false_words.store(answer[1], l)
      puts "間違ってるお"
    end
  end

  puts @false_words unless @false_words.nil?
  puts @answer

end
