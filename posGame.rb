#!/Users/pyusim/.rvm/rubies/ruby-2.1.2/bin/ruby

class User
  attr_accessor :level

  def initialize
    prange = Random.new
    @level = prange.rand(0.9-0.1) + 0.1
    puts "new User level=#{level}"
  end

  def decide(odds)
    
    probOfError = (1 - odds) * level
    prange = Random.new
    decision = prange.rand(0.99)

    if (decision > probOfError)
      return true
    else
      return false
    end
  end

end

class Frequency
  attr_accessor :total,:totalByTag,:frequencyByTag,:sentences

  def initialize
    @frequencyByTag = Hash.new("FrequencyByTag")
    @totalByTag = Hash.new("TotalByTag")
    @sentences = Array.new
  end
end

if (ARGV.size < 2)
  exit
end

taggedFilename = ARGV[0]

sentencesFilename = ARGV[1]

partsOfSpeech = Hash.new("PartsOfSpeech")

partsOfSpeech["JJ"] = "Adjective"
partsOfSpeech["JJR"] = "Adjective"
partsOfSpeech["JJS"] = "Adjective"
partsOfSpeech["NN"] = "Noun"
partsOfSpeech["NNS"] = "Noun"
partsOfSpeech["NNP"] = "Noun"
partsOfSpeech["NNPS"] = "Noun"
partsOfSpeech["RB"] = "Adverb"
partsOfSpeech["RBR"] = "Adverb"
partsOfSpeech["RBS"] = "Adverb"
partsOfSpeech["VB"] = "Verb"
partsOfSpeech["VBD"] = "Verb"
partsOfSpeech["VBG"] = "Verb"
partsOfSpeech["VBN"] = "Verb"
partsOfSpeech["VBP"] = "Verb"
partsOfSpeech["VBZ"] = "Verb"

taggedFileObj = File.new(taggedFilename, "r")

words = Hash.new("Words")

sentenceIndex = 0

while (line = taggedFileObj.gets)

  sentenceIndex += 1

  splitLine = line.gsub(/\s+/m, ' ').strip.split(" ")
  
  splitLine.each { |x| 
  
    xProcessed = x.gsub(/[,.]/, '').split("_")

    if (xProcessed.size() == 2)

      word = xProcessed[0]
      tag = xProcessed[1]

      if (partsOfSpeech.has_key?(tag))
        tag = partsOfSpeech[tag]
      end

      if (words.has_key?(word))
      
        words[word].total += 1;

        if (words[word].totalByTag.has_key?(tag))

          words[word].totalByTag[tag] += 1
          
        else

          words[word].totalByTag[tag] = 1

        end
  
      else

        f = Frequency.new

        f.total=1

        f.totalByTag[tag] = 1

        words[word] = f

      end

      words[word].sentences.push(sentenceIndex)

    end
  }
end

taggedFileObj.close

sentencesFileObj = File.new(sentencesFilename, "r")

sentences = Array.new

while (line = sentencesFileObj.gets)

    sentences.push(line)

end

sentencesFileObj.close

words.each do |key, value|
#  print "#{key} #{value.total} tags=#{value.totalByTag.size} "
  value.totalByTag.each do |tag, total|
#    print "#{tag} #{total} "
    value.frequencyByTag[tag] = total.to_f / value.total
  end
  puts
end

user = User.new

# test code to see that user decision-making works

nTrue = 0

1.upto(100) { |x|

  if (user.decide(0.3))
    nTrue += 1
  end
}

puts "Test user with level=#{user.level} got #{nTrue}/100 questions of 0.3 odds correct"

# end test code to see that user decision-making works

# this is the algorithm for infering the user level and keeping the user at 20% probability of error
# the initial hypothesis is that the user is at level 0.5, and the odds for the initial question are generated accordingly.
# the user level estimate is updated at every iteration, and the odds are updated to keep probability of error at 20%

# initial hypothesis - user level = 0.5
userLevelEstimate = 0.5  # user level is reversed - 0.1 is smart, 0.9 not so much

# probOfError = (1 - odds) * level = 0.2
# odds = 1 - 0.2/level
odds = 1 - (0.2 / userLevelEstimate)

1.upto(50) { |x|

  # p(a|b) = p(b|a) * p(a) / p(b)
  # user level given they got the question right = p(getting it right | level) * level / p(getting the question right)
  # user level given they got the question right = 0.2 * 0.5 / odds
  # user level given they got the question wrong = 0.8 * 0.5 / (1-odds)

  print "level=#{userLevelEstimate} odds=#{odds} "

  if (user.decide(odds)) # too easy
    userLevelEstimate = 1.0 - (0.8 * (1.0-userLevelEstimate)) / odds
    puts " right!"

  else                  # too hard
    userLevelEstimate = 1.0 - (0.2 * (1.0-userLevelEstimate)) / (1-odds)
    puts " wrong!"
  end

  if (userLevelEstimate < 0.1)
    userLevelEstimate = 0.1
  end

  if (userLevelEstimate > 0.9)
    userLevelEstimate = 0.9
  end

  odds = 1 - (0.2 / userLevelEstimate) # set odds such that probability(error) = 20%
}

puts "level=#{user.level} estimate=#{userLevelEstimate}"

