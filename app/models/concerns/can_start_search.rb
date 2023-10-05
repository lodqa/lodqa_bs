# frozen_string_literal: true

# Start a new search job.
module CanStartSearch
  extend ActiveSupport::Concern

  # Call back events about an exiting search.
  def start_callback_job_with search, callback_url
    CallbackEventsJob.perform_later search, callback_url
    search.search_id
  end

  # Start new job for new search.
  def start_search_job pseudo_graph_pattern, callback_url
    search = create_search pseudo_graph_pattern

    SearchJob.perform_later search.search_id
    search.register_callback callback_url

    search.search_id
  end

  def create_search pseudo_graph_pattern
    search = Search.create! pseudo_graph_pattern:,
                            search_id: SecureRandom.uuid
    search.be_referred!
    search
  end

  private

  # Return target string for PseudoGraphPattern.
  def target
    @targets.join(', ')
  end
end
