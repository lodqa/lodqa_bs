# frozen_string_literal: true

# Send JSON message by HTTP POST mesthod.
module HTTP
  def self.post url, data
    uri = URI url
    http = Net::HTTP.new uri.hostname, uri.port
    http.use_ssl = uri.instance_of? URI::HTTPS
    # http.set_debug_output $stderr

    req = Net::HTTP::Post.new uri.path, 'Content-Type' => 'application/json'
    req.body = data.to_json
    res = http.request req

    return nil if res.is_a? Net::HTTPSuccess
    res.message
  end
end
