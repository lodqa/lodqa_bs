# frozen_string_literal: true

require 'rest-client'

module EnjuAccess; end unless defined? EnjuAccess

module EnjuAccess
  class Client
    ENJU_URL = 'http://enju-gtrec.dbcls.jp'

    # It initializes an instance of RestClient::Resource to connect to an Enju cgi server
    def initialize
      @client = RestClient::Resource.new ENJU_URL
      raise EnjuAccess::EnjuError, 'The URL of a web service of enju has to be passed as the first argument.' unless @client.instance_of? RestClient::Resource
    end

    def fetch_parsed sentence
      sentence = sentence.strip
      response = @client.get params: { sentence:, format: 'conll' }

      raise EnjuAccess::EnjuError, 'Enju CGI server dose not respond.' unless response.code == 200
      raise EnjuAccess::EnjuError, 'Empty input.' if response.body =~ /^Empty line/
      raise EnjuAccess::EnjuError, 'Enju CGI server returns html instead of tsv' if response.headers[:content_type] == 'text/html'

      response
    rescue RestClient::ServiceUnavailable => e
      raise EnjuAccess::EnjuError, "#Enju CGI server is unavailable! response_message: #{e.message}"
    end
  end
end
