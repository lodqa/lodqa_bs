# frozen_string_literal: true

# Bussiness logic about registering a serach
module ReigsterSearchService
  class << self
    # Register a query.
    # return search_id if same query exists.
    def register attributes
      search = Search.new attributes
      dupulicate_query = Search.equals_in search

      return send_callback_about dupulicate_query if dupulicate_query

      start_new_job_for search
    end

    private

    # Call back events about an exiting search.
    def send_callback_about query
      case query.state
      when :finished
        EventSender.send_to query.finish_search_callback_url,
                            query.dafa_for_finish_event
      end

      query.search_id
    end

    # Start new job for new search.
    def start_new_job_for search
      job = SearchJob.perform_later
      search.search_id = job.job_id
      search.save!
      search.search_id
    end
  end
end
