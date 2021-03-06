require 'sastrawi/stemmer/context/context'
require 'sastrawi/stemmer/context/visitor/visitor_provider'
require 'sastrawi/stemmer/filter/text_normalizer'

module Sastrawi
  module Stemmer
    class Stemmer
      attr_accessor :dictionary, :visitor_provider

      def initialize(dictionary)
        @dictionary = dictionary
        @visitor_provider = Sastrawi::Stemmer::Context::Visitor::VisitorProvider.new
      end

      def stem(text)
        normalized_text = Sastrawi::Stemmer::Filter::TextNormalizer.normalize_text(text)

        words = normalized_text.split(' ')
        stems = []

        words.each do |word|
          stems.push(stem_word(word))
        end

        stems.join(' ')
      end

      def stem_word(word)
        if plural?(word)
          stem_plural_word(word)
        else
          stem_singular_word(word)
        end
      end

      def plural?(word)
        matches = /^(.*)-(ku|mu|nya|lah|kah|tah|pun)$/.match(word)

        if matches
          true
        else
          false
        end
      end

      def stem_plural_word(word)
        first_match = /^(.*)-(.*)$/.match(word)

        unless first_match
          return word
        end

        words = [first_match.captures[0], first_match.captures[1]]

        suffix = words[1]
        suffixes = ['ku', 'mu', 'nya', 'lah', 'kah', 'tah', 'pun']
        second_match = /^(.*)-(.*)$/.match(words[0])

        if suffixes.include?(suffix) && second_match
          words[1] = words[1] + '-' + suffix
        end

        root_first_word = stem_singular_word(words[0])
        root_second_word = stem_singular_word(words[1])

        unless @dictionary.contains?(words[1]) && root_second_word == words[1]
          root_second_word = stem_singular_word('me' + words[1])
        end

        if root_first_word == root_second_word
          root_first_word
        else
          word
        end
      end

      def stem_singular_word(word)
        context = Sastrawi::Stemmer::Context::Context.new(word, @dictionary, @visitor_provider)
        context.execute

        context.result
      end
    end
  end
end
