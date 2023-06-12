# frozen_string_literal: true

require 'securerandom'

# The search accepted.
# rubocop:disable Metrics/ClassLength
class Search < ApplicationRecord
  include Subscribable

  belongs_to :pseudo_graph_pattern

  before_create { self.created_at = Time.zone.now }

  scope :expired?, lambda {
    deadline = Time.zone.now.ago Rails.configuration.lodqa_bs['cache_duration'].days

    where('referred_at <= ?', deadline)
  }
  scope :alive?, lambda {
    joins(:pseudo_graph_pattern)
      .where pseudo_graph_patterns: { aborted_at: nil }
  }

  class << self
    def queued_searches
      Search.includes(pseudo_graph_pattern: [:all_answers])
            .order created_at: :desc
    end

    def of search_id
      search = Search.includes(pseudo_graph_pattern: [:all_answers])
                     .find_by(search_id:)
      search.be_referred!
      search.to_hash_with_pgp
    end

    # Expert mode check does a same condition search exists?
    def expert_equals_in other
      Search.alive?
            .joins(pseudo_graph_pattern: :term_mappings)
            .where(pseudo_graph_patterns: { read_timeout: other.read_timeout })
            .where(pseudo_graph_patterns: { sparql_limit: other.sparql_limit })
            .where(pseudo_graph_patterns: { answer_limit: other.answer_limit })
            .where(pseudo_graph_patterns: { target: other.target })
            .where(pseudo_graph_patterns: { private: false })
            .where(pseudo_graph_patterns: { term_mappings: { dataset_name: other.target } })
            .where(pseudo_graph_patterns: { term_mappings: { mapping: other.mappings } })
            .order(created_at: :desc)
            .first
    end

    # Start to search and save the start time.
    def start! search_id
      search = preload(:pseudo_graph_pattern).find_by!(search_id:)
      search.pseudo_graph_pattern.update(started_at: Time.now.utc)
      search
    end
  end

  def to_hash_with_pgp
    {
      search_id:,
      query:,
      referred_at: referred_at.in_time_zone.strftime('%m/%d %H:%M')
    }.merge pseudo_graph_pattern.data_for_search_detail
  end

  def assign_id!
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
    update search_id: SecureRandom.uuid
    search_id
  end

  # Invoke received block if the search finished.
  def not_finished?
    # Subscriptions to search are managed in memory and deleted when the search ends.
    # If you subscribe to a finished search, the subscription will remain permanently in memory.
    # Use transactions to prevent the search from being terminated just before subscribing to it.
    transaction do
      yield if pseudo_graph_pattern.reload.finished_at.blank?
    end
  end

  def be_referred!
    update referred_at: Time.now.utc
  end

  # Finish to search and save the finish time.
  def finish!
    pseudo_graph_pattern.update finished_at: Time.now.utc
  end

  # Abort to search and save the abort time.
  def abort!
    update aborted_at: Time.now.utc
  end

  # Data to sent at the start event
  def data_for_start_event
    {
      event: :start,
      query:,
      search_id:,
      expiration_date:
    }.merge pseudo_graph_pattern.data_for_start_event
  end

  # Data to sent at the finish event
  def dafa_for_finish_event
    data_for_start_event.merge(event: :finish)
                        .merge pseudo_graph_pattern.data_for_finish_event
  end

  # Return answers of the search.
  def answers
    pseudo_graph_pattern.all_answers.map(&:to_answer).uniq
  end

  def expiration_date
    referred_at.since(Rails.configuration.lodqa_bs['cache_duration'].days).end_of_day
  end

  # Return elapsed time of the finished search.
  def elapsed_time
    return nil if started_at.blank? || aborted_at.present?

    (finished_at.presence || Time.zone.now) - started_at
  end

  def as_json option = nil
    super.merge answers:
  end

  # Events that occurred while searching for queries.
  # When the number of events is large,
  # the reading time from the DB is about several seconds to about 10 seconds.
  # In order to send the first event fast, read events from the DB piece by piece.
  def occurred_events offset_size
    Event.reader_by offset_size, pseudo_graph_pattern:
  end

  def register_callback url
    LateCallbacks.add_for self, url
  end

  def callback data
    LateCallbacks.publish_for self, data
  end
end
# rubocop:enable Metrics/ClassLength
