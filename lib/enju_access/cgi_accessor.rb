# frozen_string_literal: true

#
# It takes a plain-English sentence as input and returns parsing results by accessing an Enju cgi server.
#
require 'enju_access/enju_error'
require 'enju_access/client'
require 'enju_access/token'

module EnjuAccess
  # An instance of this class connects to an Enju CGI server to parse a sentence.
  module CGIAccessor
    class << self
      # It takes a plain-English sentence as input, and
      # returns a hash that represent various aspects
      # of the PAS and syntactic structure of the sentence.
      def parse english_sentence
        raise ArgumentError, 'english_sentence must not be empty' if english_sentence.nil? || english_sentence.strip.empty?

        response         = Client.new.fetch_parsed english_sentence
        token            = Token.new(response, english_sentence.strip)

        {
          'tokens' => token.tokens,
          'root' => token.root,
          'focus' => token.focus,
          'base_noun_chunks' => token.base_noun_chunks,
          'relations' => token.relations
        }
      end
    end
  end
end
