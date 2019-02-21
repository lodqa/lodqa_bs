# frozen_string_literal: true

require 'securerandom'

# The search accepted.
class Search < ApplicationRecord
  include Subscribable

  has_many :all_answers, -> { where(event: 'answer') },
           primary_key: :search_id,
           class_name: :Event
  has_many :events, primary_key: :search_id, dependent: :destroy

  validates :read_timeout,
            :sparql_limit,
            :answer_limit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_create { self.created_at = Time.now }

  scope :is_valid, lambda {
    from = Time.now.ago 7.day
    to = Time.now.since 1.day

    where(created_at: (from..to))
      .or(where(finished_at: (from..to)))
  }
  scope :alive?, -> { where aborted_at: nil }

  class << self
    def queued_searches
      Search.is_valid
            .includes(:all_answers)
            .order created_at: :desc
    end

    # Check does a same condition search exists?
    def equals_in other
      Search.is_valid
            .alive?
            .where(query: other.query)
            .where(read_timeout: other.read_timeout)
            .where(sparql_limit: other.sparql_limit)
            .where(answer_limit: other.answer_limit)
            .where(target: other.target)
            .where(private: false)
            .order(created_at: :desc)
            .first
    end

    # Start to search and save the start time.
    def start! search_id
      search = find_by search_id: search_id
      search.started_at = Time.now.utc
      search.save!
      search
    end

    # Abort unfinished searches
    def abort_unfinished_searches!
      transaction do
        Search.where(finished_at: nil)
              .alive?
              .each(&:abort!)
              .any?
      end
    end
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
      yield unless reload.finished_at.present?
    end
  end

  # Finish to search and save the finish time.
  def finish!
    update finished_at: Time.now.utc
  end

  # Abort to search and save the abort time.
  def abort!
    update aborted_at: Time.now.utc
  end

  # Data to sent at the start event
  def data_for_start_event
    { event: :start,
      query: query,
      read_timeout: read_timeout,
      sparql_limit: sparql_limit,
      answer_limit: answer_limit,
      cache: private ? :no : :yes,
      search_id: search_id,
      start_at: started_at,
      expiration_date: created_at + 1.days }
  end

  # Data to sent at the finish event
  def dafa_for_finish_event
    data_for_start_event.merge event: :finish,
                               expiration_date: finished_at + 1.days,
                               finish_at: finished_at,
                               elapsed_time: elapsed_time,
                               answers: answers.as_json
  end

  # Return answers of the search.
  def answers
    all_answers.map(&:to_answer).uniq
  end

  # Return elapsed time of the finished search.
  def elapsed_time
    return nil if !started_at.present? || aborted_at.present?

    (finished_at.present? ? finished_at : Time.now) - started_at
  end

  # Return state of search to use in the index page of queries.
  def state
    return :aborted if aborted_at.present?
    return :finished if finished_at.present?
    return :running if started_at.present?

    :queued
  end

  def as_json option = nil
    super.merge answers: answers
  end
end
