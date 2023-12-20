# frozen_string_literal: true

require 'rest_client'
require 'lodqa/source_error'

module Lodqa
  module Sources
    TARGETS_URL = ENV.fetch('LODQA_TARGETS', 'https://targets.lodqa.org/targets')

    class << self
      def targets
        all.pluck(:name)
      end

      def dataset_of_target target
        dataset = get "#{TARGETS_URL}/#{target.strip}.json"
        dataset.compact
        dataset
      end

      private

      def all
        get "#{TARGETS_URL}.json"
      end

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
