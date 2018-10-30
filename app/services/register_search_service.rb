# frozen_string_literal: true

require 'securerandom'

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

    # Call back events about an exiting search.
    def call_back_events_about search, callback_url
      CallbackEventsJob.perform_later search, callback_url
      search.search_id
    end

    # Start new job for new search.
    def start_new_job_for search, callback_url
      # Now I will generate search_id myself.
      # Previously, in order to use the id of the job as the search_id of the search,
      # we set the search_id of the search after starting the job and update it like blew:
      # ```rb
      # job = SearchJob.perform_later
      # search.search_id = job.job_id
      # ```
      # When using AsyncAdapter, the job may be executed before saving the search_id of the search.
      # In that case, even if you search for a search with search_id in the job,
      # it can not be found. And Job fails.
      # Failure to set the start time or stop time for the search
      # and the search will remain in the queued state.
      search_id = SecureRandom.uuid
      search.search_id = search_id
      search.save!

      SearchJob.perform_later search_id
      LateCallbacks.add_for search, callback_url

      search.search_id
    end
  end
end
