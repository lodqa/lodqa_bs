# frozen_string_literal: true

# see https://stackoverflow.com/a/9047226/1276969
module UrlValidator
  extend ActiveSupport::Concern
  MESSAGE = 'Callback urls are not valid URL'

  def valid_url? value
    uri = URI.parse value
    uri.is_a? URI::HTTP
  rescue URI::InvalidURIError
    false
  end
end
