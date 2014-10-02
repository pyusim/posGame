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
  attr_accessor :tag,:word,:odds,:total,:totalByTag,:frequencyByTag,:sentencesByTag

  def initialize
    @frequencyByTag = Hash.new("FrequencyByTag")
    @totalByTag = Hash.new("TotalByTag")
    @sentencesByTag = Hash.new("SentencesByTag")
  end
end

def findOdds(words, start, odds)

  index = start
  done = false

  if (odds < 0.01)
    odds = 0.01
  elsif (odds > 0.99)
    odds = 0.99
  end

  # binary search
  while (done == false)

    if (words[index].odds == odds) # what are the odds!
      done = true
    elsif ((index == 0) && (words[index].odds > odds))
      done = true
    elsif ((index == words.size-1) && (words[index].odds < odds))
      done = true
    elsif ((words[index].odds > odds) && (words[index-1].odds < odds))
      index -= 1
      done = true
    elsif ((words[index].odds < odds) && (words[index+1].odds > odds))
      index += 1
      done = true
    elsif (words[index].odds > odds)
      index -= 1
    elsif (words[index].odds < odds)
      index += 1
    end
  end

  return index
end

# START MAIN

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
        
        if (words[word].sentencesByTag.has_key?(tag))
          words[word].sentencesByTag[tag].push(sentenceIndex)
        else
          words[word].sentencesByTag[tag] = Array.new
          words[word].sentencesByTag[tag].push(sentenceIndex)
        end

      end
    end
  }
end

taggedFileObj.close

sentencesFileObj = File.new(sentencesFilename, "r")

sentences = Array.new

while (line = sentencesFileObj.gets)
    sentences.push(line.strip)
end

sentencesFileObj.close

words.each do |key, value|
#  print "#{key} #{value.total} tags=#{value.totalByTag.size} "
  value.totalByTag.each do |tag, total|
    value.frequencyByTag[tag] = total.to_f / value.total
#    print "#{tag} #{value.frequencyByTag[tag]} "
  end
  puts
end

# build new structure with only words spread over two categories, filter out all non-major parts of speech, sort on odds, double up
# insert a Frequency object into the array twice - once with the low odds, once with the high odds

ambiguousWords = Array.new

words.each do | key, value |

  if (value.totalByTag.size == 2) # only keep words that have two parts of speech

#    puts "#{value.frequencyByTag.values[0]} #{value.frequencyByTag.values[1]}"

    f1 = value.clone
    f1.word = key
    f1.odds = value.frequencyByTag.values[0]
    f1.tag = value.frequencyByTag.keys[0]

    ambiguousWords.push(f1)
   
    # if odds is 0.5, don't double it up!
 
    if (f1.odds != 0.5)

      f2 = value.clone
      f2.word = key
      f2.odds = value.frequencyByTag.values[1]
      f2.tag = value.frequencyByTag.keys[1]

      ambiguousWords.push(f2)
    end
      
#    puts "#{f1.odds} #{f2.odds}"

  end
end

ambiguousWords.sort! { |a,b| a.odds <=> b.odds }

wordsIndex = ambiguousWords.size / 2

# binary search to find a word with 50/50 odds.  Assumes there is one
while (ambiguousWords[wordsIndex].odds != 0.5)

    if (ambiguousWords[wordsIndex].odds > 0.5)
      wordsIndex -= 1
    else
      wordsIndex += 1
    end
end

user = User.new

puts "User level=#{user.level}"

numQuestions = 0
numCorrect = 0

# TODO
# parameters need to be configurable
# data should be arrays of words mapped to a single odds value.  This way searches are faster and randomization is easier
# do not reuse Frequency - create a leaner object

# parameters
oddsIncrement = 0.02       # vary this to affect convergence rate
targetRate = 0.8
rateEpsilon = 0.05
steps = 30

1.upto(steps) { |x|

  tag = ambiguousWords[wordsIndex].tag
  prange = Random.new
  whichSentence = prange.rand(ambiguousWords[wordsIndex].sentencesByTag[tag].size) 

  print "Sentence: #{sentences[ambiguousWords[wordsIndex].sentencesByTag[tag][whichSentence]-1]}"
  puts " ========> What part of speech is <#{ambiguousWords[wordsIndex].word}> #{ambiguousWords[wordsIndex].frequencyByTag.keys[0]} or #{ambiguousWords[wordsIndex].frequencyByTag.keys[1]}?"
  
  numQuestions += 1

  if (user.decide(ambiguousWords[wordsIndex].odds))
    numCorrect += 1
    puts " ========> User is right"
  else
    puts " ========> User is wrong"
  end
  
  rate = numCorrect.to_f / numQuestions.to_f

  if (rate < (targetRate - rateEpsilon)) # too hard, raise odds
    wordsIndex = findOdds(ambiguousWords, wordsIndex, ambiguousWords[wordsIndex].odds + oddsIncrement)
    print "too hard:   "
  elsif (rate > (targetRate + rateEpsilon)) # too easy, lower odds
    wordsIndex = findOdds(ambiguousWords, wordsIndex, ambiguousWords[wordsIndex].odds - oddsIncrement)
    print "too easy:   "
  else
    print "just right: "
    # if just right, do not repeat questions- shove up or down by 1
    prange = Random.new
    wordsIndex += (prange.rand(2)-1)
  end

  printf("rate=%.2f odds=%.2f\n", rate, ambiguousWords[wordsIndex].odds)
}

exit


