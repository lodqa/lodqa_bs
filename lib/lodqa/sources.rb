# frozen_string_literal: true

require 'rest_client'
require 'lodqa/source_error'

module Lodqa
  module Sources
    DEFAULT_URL = 'http://targets.lodqa.org/targets.json'

    class << self
      def datasets target_url = DEFAULT_URL
        RestClient.get target_url do |response|
          case response.code
          when 200 then JSON.parse response, symbolize_names: true
          else
            raise SourceError, "Configuration Server retrun an error for #{target_url}. response_code: #{response.code}, response_body: #{response.body}"
          end
        end
      end
    end
  end
end
