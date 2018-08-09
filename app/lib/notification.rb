# frozen_string_literal: true

# Send JSON message by HTTP POST mesthod.
module Notification
  def self.send url, data
    uri = URI url
    http = Net::HTTP.new uri.hostname, uri.port
    http.use_ssl = uri.instance_of? URI::HTTPS
    # http.set_debug_output $stderr

    req = Net::HTTP::Post.new uri.path, 'Content-Type' => 'application/json'
    req.body = data.to_json
    res = http.request req

    res.is_a? Net::HTTPSuccess
  end
end
