# frozen_string_literal: true

# Bussiness logic about registering a serach
module ReigsterSearchService
  class << self
    # Register a search.
    # Start a new search job unless same search exists.
    # Call back only if same search exists.
    def register search, callback_url
      dupulicate_search = Search.equals_in search

      return start_new_job_for search, callback_url unless dupulicate_search

      call_back_events_about dupulicate_search, callback_url
    end

    private

    # Start new job for new search.
    def start_new_job_for search, callback_url
      search_id = search.assign_id!

      SearchJob.perform_later search_id
      LateCallbacks.add_for search, callback_url

      search.search_id
    end

    # Call back events about an exiting search.
    def call_back_events_about search, callback_url
      CallbackEventsJob.perform_later search, callback_url
      search.search_id
    end
  end
end
