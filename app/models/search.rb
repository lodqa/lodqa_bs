# frozen_string_literal: true

# The search accepted.
class Search < ApplicationRecord
  include Subscribable

  has_many :events, primary_key: :search_id
  before_create { self.created_at = Time.now }

  scope :at_today, -> { where created_at: Date.today.all_day }
  scope :alive?, -> { where aborted_at: nil }

  class << self
    # Check does a same condition search exists?
    def equals_in other
      Search.at_today
            .alive?
            .where(query: other.query)
            .where(start_search_callback_url: other.start_search_callback_url)
            .where(finish_search_callback_url: other.finish_search_callback_url)
            .where(read_timeout: other.read_timeout)
            .where(sparql_limit: other.sparql_limit)
            .where(answer_limit: other.answer_limit)
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
              .each do |q|
          q.aborted_at = Time.now.utc
          q.save!
        end.any?
      end
    end
  end

  # Invoke received block if the search finished.
  def not_finished?
    transaction do
      yield unless reload.finished_at.present?
    end
  end

  # Finish to search and save the finish time.
  # And invoke received block. For example remove subscriptions of the search.
  def finish!
    transaction do
      self.finished_at = Time.now.utc
      save!

      yield

      self
    end
  end

  # Return answers of the search.
  def answers
    events.select(&:answer?).map(&:to_answer).uniq
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
