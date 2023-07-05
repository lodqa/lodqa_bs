# frozen_string_literal: true

# Prototype of the controller for the chat-gpt-plugin
# This controller is called by chat gpt as chat gpt plugin.
# It returns the URL of the search result page.
class ChatGptPluginApiController < ActionController::API
  def create
    render plain: 'http://lodqa.org/answer?search_id=12345'
  end
end
