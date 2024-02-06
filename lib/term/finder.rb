# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'term/find_error'
require 'logger/loggable'

module Term
  # An instance of this class is initialized with a dictionary.
  class Finder
    include Logger::Loggable

    attr_reader :dictionary

    def initialize dictionary_url, endpoint_url, name_predicates
      raise ArgumentError, 'dictionary_url should be given.' if dictionary_url.blank? && endpoint_url.blank?

      @dictionary = (RestClient::Resource.new dictionary_url, headers: { content_type: :json, accept: :json }, timeout: 10 if dictionary_url)
      @endpoint_url = endpoint_url
      @name_predicates = name_predicates
    end

    def find terms
      return nil if terms.nil?
      return {} if terms.empty?

      terms = [terms] if terms.instance_of?(String)
      raise "Unexpected terms: #{terms.inspect}" unless terms.instance_of?(Array)

      mappings = if @dictionary
                   _dictionary_lookup(terms)
                 else
                   _endpoint_lookup(endpoint_url, name_predicates)
                 end

      # TODO: partition instead of interpolation
      # interpolation
      mappings.each_key do |k|
        next unless mappings[k].empty?

        ngram = k.to_s.split
        length = ngram.length
        (1...length).reverse_each do |m|
          subkeys = (0..length - m).collect { |b| ngram[b, m].join(' ') }
          submappings = _dictionary_lookup(subkeys).values.flatten.uniq
          unless submappings.empty?
            mappings[k] = [submappings.last]
            break
          end
        end
      end
    end

    private

    def _dictionary_lookup terms
      logger.debug 'Lookup Dictionary',
                   url: @dictionary.url,
                   method: 'POST',
                   request_body: terms.to_json
      @dictionary.post terms.to_json do |response, request|
        case response.code
        when 200
          JSON.parse(response, symbolize_names: true)
        when 302
          logger.debug 'Lookup Dictionary redirected',
                       url: request.uri,
                       method: request.method,
                       request_body: terms.to_json,
                       status: response.code,
                       location: response.headers[:location]
          raise Redirect, response.headers[:location]
        when 404
          {}
        else
          # request to dictionary is not success
          logger.debug 'Lookup Dictionary failed',
                       url: request.uri,
                       method: request.method,
                       request_body: terms.to_json,
                       status: response.code,
                       response_body: response
          raise FindError, "Term find error to #{request.uri}"
        end
      end
    rescue RestClient::Exceptions::ReadTimeout, RestClient::Exceptions::OpenTimeout
      logger.info 'A request to the dictionary was timeout', url: @dictionary.url, requet_body: terms.to_json
      raise FindError, "Term find timeout error to #{@dictionary.url}"
    end

    def class? term
      yield(false) unless /^http/ =~ term

      @endpoint.query_async(sparql_for(term)) do |err, result|
        yield([err, result ? !result.empty? : false])
      end
    end

    def sparql_for term
      sparql  = "SELECT ?p\n"
      sparql += "FROM <#{@graph_uri}>\n" if @graph_uri.present?
      sparql += "WHERE {?s ?p <#{term}> FILTER (str(?p) IN (#{@sortal_predicates.map { |s| "\"#{s}\"" }.join(', ')}))} LIMIT 1"
      sparql
    end
  end
end
