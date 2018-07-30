# frozen_string_literal: true

require 'rest_client'
require 'lodqa/source_error'

module Lodqa
  module Sources
    DEFAULT_URL = 'http://targets.lodqa.org/targets.json'

    class << self
      def datasets(target_url = DEFAULT_URL)
        RestClient.get target_url do |response, _request, _result|
          case response.code
          when 200 then JSON.parse response, symbolize_names: true
          else
            Logger.error nil, message: "Configuration Server retrun an error for #{target_url}", response_code: response.code, response_body: response.body
            raise IOError, "Response Error for url: #{target_url}"
          end
        end
      rescue StandardError => e
        Logger.error e, message: "Cannot connect the Configuration Server for #{target_url}"
        raise SourceError, "invalid url #{target_url}"
      end
    end
  end
end
