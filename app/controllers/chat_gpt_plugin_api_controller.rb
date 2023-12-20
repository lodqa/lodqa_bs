# frozen_string_literal: true

# Prototype of the controller for the chat-gpt-plugin
# This controller is called by chat gpt as chat gpt plugin.
# It returns the URL of the search result page.
class ChatGptPluginApiController < ActionController::API
  def create
    permitted = params.permit(:query, :target)

    query = permitted.require(:query)
    target = permitted[:target]

    search_id = ChatGptSearch.new(query, target).run

    result_url = "#{ENV.fetch('LODQA', 'https://lodqa.org')}/answer?search_id=#{search_id}"
    render json: {lodqaLink:result_url}
  end
end
