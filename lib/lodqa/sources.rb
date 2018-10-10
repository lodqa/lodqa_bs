# frozen_string_literal: true

require 'rest_client'
require 'lodqa/source_error'

module Lodqa
  module Sources
    TARGETS_URL = 'http://targets.lodqa.org/targets'

    class << self
      def datasets
        get "#{TARGETS_URL}.json"
      end

      def dataset_of_target target
        dataset = get "#{TARGETS_URL}/#{target}.json"
        dataset.delete_if { |_k, v| v.nil? }
        dataset
      end

      private

      def get url
        RestClient.get url do |response|
          case response.code
          when 200 then JSON.parse response, symbolize_names: true
          else
            raise SourceError, "Configuration Server retrun an error for #{url}. response_code: #{response.code}, response_body: #{response.body}"
          end
        end
      end
    end
  end
end
